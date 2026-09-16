//
//  组件名称：市场页生命周期诊断
//  简介：按需记录前后台、主线程心跳和 GPU 命令状态，保留有限大小的日志。
//  用于：真机市场页偶发卡死与 watchdog 退出的自动化排查。
//

import Foundation
import Metal
import os
import UIKit

final class MarketLifecycleDiagnostics {
    static let shared = MarketLifecycleDiagnostics()
    static let isEnabled = ProcessInfo.processInfo.arguments.contains("-MarketLifecycleDiagnostics")

    private let queue = DispatchQueue(label: "com.peterz.SuperPreview.marketDiagnostics", qos: .utility)
    private let logger = Logger(subsystem: "com.peterz.SuperPreview", category: "MarketLifecycle")
    private var writer: FileHandle?
    private var directory: URL?
    private var byteCount = 0
    private var installed = false
    private var observers: [NSObjectProtocol] = []
    private var timer: DispatchSourceTimer?
    private var active = false
    private var heartbeatSentAt: TimeInterval?
    private var heartbeatReported = false
    private var submitted = 0
    private var scheduled = 0
    private var completed = 0
    private var gpuErrors = 0
    // Accessed only from the main-thread drawing path.
    private var lastFrameSample: TimeInterval = 0
    private var nextCommandID = 0

    private init() {}

    func install() {
        guard Self.isEnabled, !installed else { return }
        installed = true
        let initialState = UIApplication.shared.applicationState.rawValue
        let osVersion = UIDevice.current.systemVersion
        queue.async {
            self.prepareFile()
            self.active = initialState == UIApplication.State.active.rawValue
            self.write("session-start", [
                "pid": String(ProcessInfo.processInfo.processIdentifier),
                "session": self.directory?.lastPathComponent ?? "unavailable",
                "os": osVersion,
                "version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "",
                "build": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
            ])
            self.startHeartbeat()
        }
        for name in [UIApplication.willResignActiveNotification,
                     UIApplication.didEnterBackgroundNotification,
                     UIApplication.willEnterForegroundNotification,
                     UIApplication.didBecomeActiveNotification,
                     UIApplication.didReceiveMemoryWarningNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
                let state = UIApplication.shared.applicationState.rawValue
                self.queue.async {
                    if name == UIApplication.willResignActiveNotification || name == UIApplication.didEnterBackgroundNotification {
                        self.active = false
                        self.heartbeatSentAt = nil
                    } else if name == UIApplication.didBecomeActiveNotification {
                        self.active = true
                        self.heartbeatSentAt = nil
                    }
                    self.write("application-lifecycle", ["notification": name.rawValue, "state": String(state)])
                    try? self.writer?.synchronize()
                }
            })
        }
    }

    func event(_ name: String, _ details: [String: String] = [:]) {
        guard Self.isEnabled else { return }
        var entry = details
        entry["timestamp"] = String(Date().timeIntervalSince1970)
        entry["uptime"] = String(ProcessInfo.processInfo.systemUptime)
        queue.async { self.write(name, entry) }
    }

    func beginFrameSample() -> TimeInterval? {
        guard Self.isEnabled else { return nil }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastFrameSample >= 1 else { return nil }
        lastFrameSample = now
        event("frame-begin")
        return now
    }

    func stage(_ name: String, since start: TimeInterval?) {
        guard let start else { return }
        event(name, ["elapsedMS": String((ProcessInfo.processInfo.systemUptime - start) * 1_000)])
    }

    func track(_ commandBuffer: MTLCommandBuffer) {
        guard Self.isEnabled else { return }
        nextCommandID += 1
        let id = nextCommandID
        let start = ProcessInfo.processInfo.systemUptime
        commandBuffer.label = "Market frame \(id)"
        queue.async { self.submitted += 1 }
        commandBuffer.addScheduledHandler { _ in
            let elapsed = ProcessInfo.processInfo.systemUptime - start
            self.queue.async {
                self.scheduled += 1
                if elapsed > 0.1 {
                    self.write("gpu-scheduling-delay", ["frame": String(id), "elapsedMS": String(elapsed * 1_000)])
                }
            }
        }
        commandBuffer.addCompletedHandler { buffer in
            let elapsed = ProcessInfo.processInfo.systemUptime - start
            let status = buffer.status.rawValue
            let error = buffer.error.map { $0 as NSError }
            let errorDescription = error.map { String(describing: $0) }
            let errorDomain = error?.domain
            let errorCode = error.map { String($0.code) }
            let errorInfo = error.map { String(describing: $0.userInfo) }
            self.queue.async {
                self.completed += 1
                if let errorDescription {
                    self.gpuErrors += 1
                    self.write("gpu-error", ["frame": String(id), "status": String(status),
                                             "error": errorDescription, "domain": errorDomain ?? "",
                                             "code": errorCode ?? "", "userInfo": errorInfo ?? ""])
                } else if elapsed > 0.25 {
                    self.write("gpu-completion-delay", ["frame": String(id), "elapsedMS": String(elapsed * 1_000)])
                }
            }
        }
    }

    private func startHeartbeat() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 1, repeating: 1, leeway: .milliseconds(100))
        timer.setEventHandler { [weak self] in
            guard let self, self.active else { return }
            self.write("gpu-summary", [
                "submitted": String(self.submitted), "scheduled": String(self.scheduled),
                "completed": String(self.completed), "inFlight": String(self.submitted - self.completed),
                "errors": String(self.gpuErrors)
            ])
            let now = ProcessInfo.processInfo.systemUptime
            if let sent = self.heartbeatSentAt {
                if now - sent > 2, !self.heartbeatReported {
                    self.heartbeatReported = true
                    self.write("main-heartbeat-delayed", ["elapsedMS": String((now - sent) * 1_000)])
                }
                return
            }
            self.heartbeatSentAt = now
            self.heartbeatReported = false
            DispatchQueue.main.async {
                let delay = ProcessInfo.processInfo.systemUptime - now
                self.queue.async {
                    guard self.heartbeatSentAt == now else { return }
                    self.heartbeatSentAt = nil
                    self.write("main-heartbeat", ["elapsedMS": String(delay * 1_000)])
                }
            }
        }
        self.timer = timer
        timer.resume()
    }

    private func prepareFile() {
        do {
            let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask,
                                                       appropriateFor: nil, create: true)
            let session = "\(Int(Date().timeIntervalSince1970))-\(UUID().uuidString)"
            let directory = documents.appendingPathComponent("MarketLifecycleDiagnostics").appendingPathComponent(session)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            self.directory = directory
            openWriter()
        } catch {
            logger.error("Unable to create market diagnostic log: \(String(describing: error), privacy: .public)")
        }
    }

    private func openWriter() {
        guard let directory else { return }
        let file = directory.appendingPathComponent("events.jsonl")
        FileManager.default.createFile(atPath: file.path, contents: nil)
        writer = try? FileHandle(forWritingTo: file)
        byteCount = 0
    }

    private func write(_ name: String, _ details: [String: String]) {
        var entry = details
        entry["event"] = name
        if entry["timestamp"] == nil { entry["timestamp"] = String(Date().timeIntervalSince1970) }
        if entry["uptime"] == nil { entry["uptime"] = String(ProcessInfo.processInfo.systemUptime) }
        guard var data = try? JSONSerialization.data(withJSONObject: entry, options: .sortedKeys) else { return }
        data.append(0x0A)
        if byteCount + data.count > 4 * 1_024 * 1_024, let directory {
            try? writer?.close()
            let previous = directory.appendingPathComponent("events.previous.jsonl")
            if FileManager.default.fileExists(atPath: previous.path) { try? FileManager.default.removeItem(at: previous) }
            try? FileManager.default.moveItem(at: directory.appendingPathComponent("events.jsonl"), to: previous)
            openWriter()
        }
        try? writer?.write(contentsOf: data)
        byteCount += data.count
        if name != "gpu-summary" && name != "main-heartbeat" && !name.hasPrefix("frame-") {
            logger.info("\(String(decoding: data, as: UTF8.self), privacy: .public)")
        }
    }
}
