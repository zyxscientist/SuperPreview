//  组件名称：市场页前后台循环测试
//  简介：保持同一 App 会话，循环切前后台并验证实际交互，异常时保留现场。
//  用于：真机市场页地球渲染的偶发卡死、崩溃与 watchdog 排查。

import XCTest

final class MarketLifecycleStressUITests: XCTestCase {
    private var app: XCUIApplication!
    private var timeline: [[String: String]] = []

    func testContinuousMarketBackgroundForeground() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        let environment = ProcessInfo.processInfo.environment
        let cycles = Int(environment["MARKET_STRESS_CYCLES"] ?? "100") ?? 100
        let durations = (environment["MARKET_STRESS_BACKGROUNDS"] ?? "0.5,2,10,30")
            .split(separator: ",").compactMap { Double($0) }
        guard cycles > 0, !durations.isEmpty, durations.allSatisfy({ $0 >= 0 && $0 <= 300 }) else {
            throw StressFailure(message: "Invalid cycle count or background durations")
        }

        app = XCUIApplication()
        // Preserve ordinary app behavior; do not enable the general -UITesting path.
        if environment["MARKET_STRESS_DIAGNOSTICS"] != "0" {
            app.launchArguments.append("-MarketLifecycleDiagnostics")
        }
        app.launch()
        record("app-launched")

        do {
            try tap("mainTab.tab3")
            try require(element("market.root").waitForExistence(timeout: 15), "Market page did not appear")
            let tabs = ["港股", "美股", "沪深港通", "加密货币"]
            for cycle in 1...cycles {
                do {
                    let tab = tabs[(cycle - 1) % tabs.count]
                    let backgroundDuration = durations[(cycle - 1) % durations.count]
                    record("cycle-begin", ["cycle": String(cycle), "tab": tab, "backgroundSeconds": String(backgroundDuration)])
                    try require(app.state == .runningForeground, "App left foreground before cycle \(cycle)")
                    try tap("market.tab.\(tab)")
                    try selected(tab)

                    if cycle % 2 == 0 {
                        let globe = element("market.globe")
                        try require(globe.waitForExistence(timeout: 5), "Missing globe")
                        let start = globe.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.25))
                        let end = globe.coordinate(withNormalizedOffset: CGVector(dx: 0.65, dy: 0.35))
                        start.press(forDuration: 0.05, thenDragTo: end)
                    }

                    // Also exercise background entry with a sheet covering the globe.
                    let sheetOpen = cycle % 7 == 0
                    if sheetOpen {
                        try tap("market.debug.open")
                        try require(element("market.debug.close").waitForExistence(timeout: 5), "Debug sheet did not open")
                    }
                    record("home-pressed", ["cycle": String(cycle)])
                    XCUIDevice.shared.press(.home)
                    try require(app.wait(for: .runningBackground, timeout: 5)
                                || app.state == .runningBackgroundSuspended,
                                "App did not enter background")

                    let deadline = Date().addingTimeInterval(backgroundDuration)
                    repeat {
                        try require(app.state != .notRunning, "App terminated while in background")
                        Thread.sleep(forTimeInterval: min(0.5, max(deadline.timeIntervalSinceNow, 0)))
                    } while Date() < deadline

                    // activate() can launch a dead app. Detect exit before calling it.
                    try require(app.state == .runningBackground || app.state == .runningBackgroundSuspended,
                                "App is no longer alive; refusing to relaunch it")
                    record("foreground-requested", ["cycle": String(cycle)])
                    app.activate()
                    try require(app.wait(for: .runningForeground, timeout: 10), "App failed to return to foreground")
                    if sheetOpen { try tap("market.debug.close") }

                    // Verify actual input handling, rather than only process state/existence.
                    let probeTab = tabs[cycle % tabs.count]
                    try tap("market.tab.\(probeTab)")
                    try selected(probeTab)
                    try tap("market.tab.\(tab)")
                    try selected(tab)
                    try tap("market.debug.open")
                    try require(element("market.debug.close").waitForExistence(timeout: 5), "UI is unresponsive: debug sheet did not open")
                    try tap("market.debug.close")
                    record("cycle-passed", ["cycle": String(cycle), "tab": tab])
                    if cycle == 1 || cycle % 10 == 0 { screenshot("cycle-\(cycle)-foreground") }
                }
            }
            record("stress-passed", ["cycles": String(cycles)])
            attachTimeline()
        } catch {
            record("failure-candidate", ["error": String(describing: error)])
            screenshot("failure-first-observation")
            attachTimeline()
            // Give the OS a chance to create a watchdog report before XCTest cleans up.
            // Never terminate or relaunch the target in this interval.
            record("evidence-grace-period", ["seconds": "30"])
            Thread.sleep(forTimeInterval: 30)
            screenshot("failure-after-grace-period")
            throw error
        }
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func tap(_ identifier: String) throws {
        let target = element(identifier)
        try require(target.waitForExistence(timeout: 15), "Missing element: \(identifier)")
        try require(target.isHittable, "Element is not hittable: \(identifier)")
        target.tap()
    }

    private func selected(_ tab: String) throws {
        let target = element("market.tab.\(tab)")
        let predicate = NSPredicate { _, _ in target.isSelected }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: target)
        try require(XCTWaiter.wait(for: [expectation], timeout: 5) == .completed,
                    "Tab did not respond to input: \(tab)")
    }

    private func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw StressFailure(message: message) }
    }

    private func record(_ phase: String, _ details: [String: String] = [:]) {
        var entry = details
        entry["phase"] = phase
        entry["timestamp"] = ISO8601DateFormatter().string(from: Date())
        timeline.append(entry)
        if let data = try? JSONSerialization.data(withJSONObject: entry, options: .sortedKeys) {
            FileHandle.standardOutput.write(Data("MARKET_STRESS ".utf8) + data + Data("\n".utf8))
        }
    }

    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func attachTimeline() {
        guard let data = try? JSONSerialization.data(withJSONObject: timeline, options: [.prettyPrinted, .sortedKeys]) else { return }
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
        attachment.name = "market-lifecycle-timeline"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private struct StressFailure: Error, CustomStringConvertible {
        let message: String
        var description: String { message }
    }
}
