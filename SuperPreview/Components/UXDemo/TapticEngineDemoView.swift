//
//  TapticEngineDemoView.swift
//  SuperPreview
//
//  Created by Codex on 2026/07/15.
//

import CoreHaptics
import SwiftUI
import UIKit

struct TapticEngineDemoView: View {
    @StateObject private var haptics = TapticEngineDemoController()
    @State private var impactIntensity = 0.75
    @State private var customIntensity = 0.7
    @State private var customSharpness = 0.5
    @State private var continuousDuration = 1.0

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Form {
            supportSection
            semanticFeedbackSection
            impactSection
            notificationSection
            customHapticSection
            patternSection
        }
        .navigationTitle("Taptic Engine")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("停止") {
                    haptics.stop()
                }
                .accessibilityHint("停止正在播放的 Core Haptics 触感")
            }
        }
        .onDisappear {
            haptics.stop()
        }
    }

    private var supportSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: haptics.supportsCoreHaptics ? "iphone.radiowaves.left.and.right" : "iphone.slash")
                    .font(.title2)
                    .foregroundStyle(haptics.supportsCoreHaptics ? .green : .orange)

                VStack(alignment: .leading, spacing: 3) {
                    Text(haptics.supportsCoreHaptics ? "支持 Core Haptics" : "当前环境不支持 Core Haptics")
                        .font(.headline)
                    Text(haptics.statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } footer: {
            Text("模拟器不会产生触感。请在支持 Taptic Engine 的 iPhone 真机上体验。")
        }
    }

    private var semanticFeedbackSection: some View {
        Section("基础反馈") {
            TapticDemoButton(title: "Selection", subtitle: "选择项切换时的轻触", systemImage: "checkmark.circle") {
                haptics.playSelection()
            }
        }
    }

    private var impactSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("强度")
                    Spacer()
                    Text(impactIntensity.formatted(.number.precision(.fractionLength(2))))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $impactIntensity, in: 0...1, step: 0.05)
                    .accessibilityLabel("Impact 强度")
            }

            LazyVGrid(columns: columns, spacing: 12) {
                impactButton("Light", style: .light, icon: "leaf")
                impactButton("Medium", style: .medium, icon: "circle.fill")
                impactButton("Heavy", style: .heavy, icon: "shippingbox.fill")
                impactButton("Soft", style: .soft, icon: "cloud.fill")
                impactButton("Rigid", style: .rigid, icon: "diamond.fill")
            }
            .padding(.vertical, 4)
        } header: {
            Text("Impact · 撞击")
        } footer: {
            Text("Style 决定重量或材质感，Intensity 用来比较同一 Style 下的强弱。")
        }
    }

    private var notificationSection: some View {
        Section("Notification · 结果") {
            TapticDemoButton(title: "Success", subtitle: "操作成功", systemImage: "checkmark.circle.fill", tint: .green) {
                haptics.playNotification(.success)
            }
            TapticDemoButton(title: "Warning", subtitle: "需要注意", systemImage: "exclamationmark.triangle.fill", tint: .orange) {
                haptics.playNotification(.warning)
            }
            TapticDemoButton(title: "Error", subtitle: "操作失败", systemImage: "xmark.octagon.fill", tint: .red) {
                haptics.playNotification(.error)
            }
        }
    }

    private var customHapticSection: some View {
        Section {
            parameterSlider(title: "强度", value: $customIntensity)
            parameterSlider(title: "锐度", value: $customSharpness)

            HStack(spacing: 12) {
                TapticDemoButton(title: "瞬时", subtitle: "Transient", systemImage: "sparkle", compact: true) {
                    haptics.playCustomTransient(
                        intensity: Float(customIntensity),
                        sharpness: Float(customSharpness)
                    )
                }

                TapticDemoButton(title: "持续", subtitle: "Continuous", systemImage: "waveform", compact: true) {
                    haptics.playCustomContinuous(
                        intensity: Float(customIntensity),
                        sharpness: Float(customSharpness),
                        duration: continuousDuration
                    )
                }
            }
            .disabled(!haptics.supportsCoreHaptics)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("持续时间")
                    Spacer()
                    Text("\(continuousDuration.formatted(.number.precision(.fractionLength(1)))) 秒")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $continuousDuration, in: 0.1...3, step: 0.1)
                    .accessibilityLabel("持续震动时间")
            }
        } header: {
            Text("Core Haptics · 自定义")
        } footer: {
            Text("强度控制力量；锐度从圆润柔和变化到清脆利落。")
        }
    }

    private var patternSection: some View {
        Section {
            ForEach(TapticPatternPreset.allCases) { preset in
                TapticDemoButton(
                    title: preset.title,
                    subtitle: preset.subtitle,
                    systemImage: preset.systemImage
                ) {
                    haptics.playPattern(preset)
                }
                .disabled(!haptics.supportsCoreHaptics)
            }
        } header: {
            Text("组合节奏")
        } footer: {
            Text("这些示例由多个瞬时或持续事件按时间编排而成。")
        }
    }

    private func impactButton(
        _ title: String,
        style: UIImpactFeedbackGenerator.FeedbackStyle,
        icon: String
    ) -> some View {
        TapticDemoButton(title: title, subtitle: "Impact", systemImage: icon, compact: true) {
            haptics.playImpact(style, intensity: CGFloat(impactIntensity))
        }
    }

    private func parameterSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(value.wrappedValue.formatted(.number.precision(.fractionLength(2))))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: 0...1, step: 0.05)
                .accessibilityLabel(title)
        }
    }
}

private struct TapticDemoButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var tint: Color = .accentColor
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 11) {
                Image(systemName: systemImage)
                    .font(.system(size: compact ? 17 : 20, weight: .semibold))
                    .frame(width: compact ? 24 : 28)
                    .foregroundStyle(tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: compact ? 14 : 16, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !compact {
                    Spacer(minLength: 8)
                    Image(systemName: "play.fill")
                        .font(.caption)
                        .foregroundStyle(tint)
                }
            }
            .frame(maxWidth: .infinity, minHeight: compact ? 42 : 46, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("播放 \(title) 触感")
    }
}

private enum TapticPatternPreset: String, CaseIterable, Identifiable {
    case doubleTap
    case heartbeat
    case crescendo
    case rumble

    var id: String { rawValue }

    var title: String {
        switch self {
        case .doubleTap: return "双击"
        case .heartbeat: return "心跳"
        case .crescendo: return "渐强"
        case .rumble: return "机械轰鸣"
        }
    }

    var subtitle: String {
        switch self {
        case .doubleTap: return "两个紧凑的清脆瞬时事件"
        case .heartbeat: return "模拟两组强弱心跳节奏"
        case .crescendo: return "持续触感沿参数曲线逐渐增强"
        case .rumble: return "低锐度持续震动叠加细碎脉冲"
        }
    }

    var systemImage: String {
        switch self {
        case .doubleTap: return "hand.tap.fill"
        case .heartbeat: return "heart.fill"
        case .crescendo: return "chart.line.uptrend.xyaxis"
        case .rumble: return "gearshape.2.fill"
        }
    }
}

private final class TapticEngineDemoController: ObservableObject {
    @Published private(set) var statusMessage: String

    let supportsCoreHaptics: Bool

    private var engine: CHHapticEngine?
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    init() {
        supportsCoreHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        statusMessage = supportsCoreHaptics ? "可以体验预设和可编程触感" : "UIKit 按钮仍可点击，但当前环境不会产生真实触感"
        selectionGenerator.prepare()
    }

    func playSelection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
        statusMessage = "已触发 Selection"
    }

    func playImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
        statusMessage = "已触发 Impact，强度 \(String(format: "%.2f", intensity))"
    }

    func playNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(type)

        switch type {
        case .success:
            statusMessage = "已触发 Success"
        case .warning:
            statusMessage = "已触发 Warning"
        case .error:
            statusMessage = "已触发 Error"
        @unknown default:
            statusMessage = "已触发 Notification"
        }
    }

    func playCustomTransient(intensity: Float, sharpness: Float) {
        let event = makeTransient(time: 0, intensity: intensity, sharpness: sharpness)
        play(events: [event], named: "自定义瞬时触感")
    }

    func playCustomContinuous(intensity: Float, sharpness: Float, duration: TimeInterval) {
        let event = makeContinuous(
            time: 0,
            duration: duration,
            intensity: intensity,
            sharpness: sharpness
        )
        play(events: [event], named: "自定义持续触感")
    }

    func playPattern(_ preset: TapticPatternPreset) {
        switch preset {
        case .doubleTap:
            play(
                events: [
                    makeTransient(time: 0, intensity: 0.62, sharpness: 0.9),
                    makeTransient(time: 0.14, intensity: 1, sharpness: 0.9)
                ],
                named: preset.title
            )

        case .heartbeat:
            play(
                events: [
                    makeTransient(time: 0, intensity: 1, sharpness: 0.25),
                    makeTransient(time: 0.18, intensity: 0.55, sharpness: 0.18),
                    makeTransient(time: 0.82, intensity: 0.9, sharpness: 0.25),
                    makeTransient(time: 1, intensity: 0.45, sharpness: 0.18)
                ],
                named: preset.title
            )

        case .crescendo:
            let event = makeContinuous(time: 0, duration: 1.8, intensity: 1, sharpness: 0.55)
            let curve = CHHapticParameterCurve(
                parameterID: .hapticIntensityControl,
                controlPoints: [
                    .init(relativeTime: 0, value: 0.08),
                    .init(relativeTime: 0.7, value: 0.32),
                    .init(relativeTime: 1.35, value: 0.68),
                    .init(relativeTime: 1.8, value: 1)
                ],
                relativeTime: 0
            )
            play(events: [event], curves: [curve], named: preset.title)

        case .rumble:
            var events = [
                makeContinuous(time: 0, duration: 1.8, intensity: 0.38, sharpness: 0.12)
            ]
            for index in 0..<12 {
                let intensity: Float = index.isMultiple(of: 3) ? 0.7 : 0.32
                events.append(
                    makeTransient(
                        time: Double(index) * 0.15,
                        intensity: intensity,
                        sharpness: 0.42
                    )
                )
            }
            play(events: events, named: preset.title)
        }
    }

    func stop() {
        engine?.stop(completionHandler: nil)
        engine = nil
        statusMessage = supportsCoreHaptics ? "已停止 Core Haptics" : statusMessage
    }

    private func play(
        events: [CHHapticEvent],
        curves: [CHHapticParameterCurve] = [],
        named name: String
    ) {
        guard supportsCoreHaptics else {
            statusMessage = "当前环境不支持 Core Haptics，请使用 iPhone 真机"
            return
        }

        do {
            let engine = try prepareEngine()
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            statusMessage = "正在播放：\(name)"
        } catch {
            statusMessage = "播放失败：\(error.localizedDescription)"
        }
    }

    private func prepareEngine() throws -> CHHapticEngine {
        if let engine {
            try engine.start()
            return engine
        }

        let newEngine = try CHHapticEngine()
        newEngine.isAutoShutdownEnabled = true
        try newEngine.start()
        engine = newEngine
        return newEngine
    }

    private func makeTransient(
        time: TimeInterval,
        intensity: Float,
        sharpness: Float
    ) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time
        )
    }

    private func makeContinuous(
        time: TimeInterval,
        duration: TimeInterval,
        intensity: Float,
        sharpness: Float
    ) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: time,
            duration: duration
        )
    }
}

struct TapticEngineDemoViewPreviews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TapticEngineDemoView()
        }
    }
}
