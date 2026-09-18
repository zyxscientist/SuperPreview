import SwiftUI
import UIKit

/// An independently implemented, rotating highlight around a stationary card.
struct RotateBeamDemoView: View {
    @State private var beamOpacity = 1.0
    @State private var glowStrength = 1.0
    @State private var beamWidth = 1.0
    @State private var glowSpread = 1.0
    @State private var trailLength = 0.40
    @State private var rotationDuration = 4.0

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 10) {
                        Text("Rotate Beam")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color("color-text-30"))
                        Text("沿着边缘，流动的光。")
                            .font(.system(size: 15))
                            .foregroundStyle(Color("color-text-60"))
                    }

                    card
                        .frame(maxWidth: 330)
                        .padding(.vertical, 24)

                    Text(String(format: "ROTATE · %.1fs / LOOP", rotationDuration))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .tracking(2)
                        .foregroundStyle(Color("color-text-90"))

                    controls
                        .frame(maxWidth: 330)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
            }
        }
        .background(Color("color-base-0").ignoresSafeArea())
        .navigationTitle("Rotate Beam")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("compare.rotateBeam.demo")
    }

    private var card: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color("color-card"))
            .frame(maxWidth: .infinity)
            .frame(height: 210)
            .overlay {
                RotateBeamBorder(
                    cornerRadius: 24,
                    duration: rotationDuration,
                    beamOpacity: beamOpacity,
                    glowStrength: glowStrength,
                    beamWidth: beamWidth,
                    glowSpread: glowSpread,
                    trailLength: trailLength
                )
            }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("实时参数")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color("color-text-30"))
                    Text("拖动滑块，立即观察 Beam 变化")
                        .font(.system(size: 12))
                        .foregroundStyle(Color("color-text-60"))
                }

                Spacer()

                Button("恢复默认") {
                    beamOpacity = 1
                    glowStrength = 1
                    beamWidth = 1
                    glowSpread = 1
                    trailLength = 0.40
                    rotationDuration = 4
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color("color-brand-blue"))
                .buttonStyle(.plain)
                .accessibilityIdentifier("compare.rotateBeam.reset")
            }

            beamSlider(
                title: "透明度",
                value: $beamOpacity,
                range: 0...1,
                step: 0.05,
                valueText: String(format: "%.0f%%", beamOpacity * 100),
                identifier: "compare.rotateBeam.opacity"
            )
            beamSlider(
                title: "发光强度",
                value: $glowStrength,
                range: 0...1.8,
                step: 0.05,
                valueText: String(format: "%.2f×", glowStrength),
                identifier: "compare.rotateBeam.glowStrength"
            )
            beamSlider(
                title: "光束宽度",
                value: $beamWidth,
                range: 0.5...2,
                step: 0.05,
                valueText: String(format: "%.2f×", beamWidth),
                identifier: "compare.rotateBeam.width"
            )
            beamSlider(
                title: "光晕扩散",
                value: $glowSpread,
                range: 0.25...10,
                step: 0.05,
                valueText: String(format: "%.2f×", glowSpread),
                identifier: "compare.rotateBeam.spread"
            )
            beamSlider(
                title: "拖尾长度",
                value: $trailLength,
                range: 0.20...0.55,
                step: 0.01,
                valueText: String(format: "%.0f%%", trailLength * 100),
                identifier: "compare.rotateBeam.trailLength"
            )
            beamSlider(
                title: "旋转周期",
                value: $rotationDuration,
                range: 1...10,
                step: 0.5,
                valueText: String(format: "%.1fs", rotationDuration),
                identifier: "compare.rotateBeam.duration"
            )
        }
        .padding(18)
        .background(Color("color-card"), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func beamSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        valueText: String,
        identifier: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("color-text-30"))
                Spacer()
                Text(valueText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(Color("color-text-60"))
            }

            Slider(value: value, in: range, step: step)
                .tint(Color("color-brand-blue"))
                .accessibilityIdentifier(identifier)
        }
    }
}

/// Only the angular light field rotates; the rounded rectangle stays fixed.
/// Keep this overlay unclipped so the outer halo can extend beyond the card.
struct RotateBeamBorder: View {
    var cornerRadius: CGFloat = 24
    var duration: TimeInterval = 4
    var beamOpacity: Double = 1
    var glowStrength: Double = 1
    var beamWidth: Double = 1
    var glowSpread: Double = 1
    var trailLength: Double = 0.40

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = false
    @State private var isApplicationActive = false
    @State private var elapsed: TimeInterval = 0
    @State private var startedAt: Date?

    private var shouldAnimate: Bool {
        isVisible && isApplicationActive && !reduceMotion
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !shouldAnimate)) { context in
            let time = elapsed + (startedAt.map { context.date.timeIntervalSince($0) } ?? 0)
            let progress = time.truncatingRemainder(dividingBy: max(duration, 0.1)) / max(duration, 0.1)
            let trail = CGFloat(min(max(trailLength, 0.05), 0.8))
            let colorStart = max(CGFloat(0.20), CGFloat(0.985) - trail)
            let fadeStart = max(CGFloat(0.05), colorStart - min(CGFloat(0.06), trail * 0.2))
            let colorSpan = CGFloat(0.985) - colorStart
            let light = AngularGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .clear, location: fadeStart),
                    .init(color: Color("color-futu-red").opacity(0.25), location: colorStart),
                    .init(color: Color("color-futu-red"), location: colorStart + colorSpan * 0.16),
                    .init(color: Color("color-fund-orange"), location: colorStart + colorSpan * 0.32),
                    .init(color: Color("color-emoney-gold"), location: colorStart + colorSpan * 0.48),
                    .init(color: Color("color-futu-green"), location: colorStart + colorSpan * 0.64),
                    .init(color: Color("color-brand-blue"), location: colorStart + colorSpan * 0.79),
                    .init(color: Color("color-cash-purple"), location: colorStart + colorSpan * 0.92),
                    .init(color: .white, location: 0.985),
                    .init(color: .clear, location: 1)
                ],
                center: .center,
                angle: .degrees(reduceMotion ? 35 : progress * 360)
            )
            let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            let beamAlpha = min(max(beamOpacity, 0), 1)
            let glowAlpha = min(max(glowStrength, 0), 1.8)
            let width = max(beamWidth, 0.1)
            let spread = min(max(glowSpread, 0.1), 10)

            ZStack {
                shape.strokeBorder(Color("color-text-90").opacity(0.35), lineWidth: 1)
                Group {
                    shape.strokeBorder(light, lineWidth: 7 * width)
                        .blur(radius: 12 * spread)
                        .opacity(0.65 * glowAlpha)
                    shape.strokeBorder(light, lineWidth: 3 * width)
                        .blur(radius: 3 * spread)
                        .opacity(0.85 * glowAlpha)
                    shape.strokeBorder(light, lineWidth: 1.3 * width)
                }
                .opacity(beamAlpha)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear {
            isVisible = true
            let active = UIApplication.shared.applicationState == .active
            isApplicationActive = active
            updateClock(running: active && !reduceMotion)
        }
        .onDisappear {
            isVisible = false
            updateClock(running: false)
        }
        // This app is hosted by UIKit's SceneDelegate, so use its lifecycle
        // notifications instead of relying on a SwiftUI App scene environment.
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            isApplicationActive = true
            updateClock(running: isVisible && !reduceMotion)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            isApplicationActive = false
            updateClock(running: false)
        }
        .onChange(of: reduceMotion) { _, reduced in
            updateClock(running: isVisible && isApplicationActive && !reduced)
        }
    }

    private func updateClock(running: Bool) {
        if running {
            if startedAt == nil { startedAt = Date() }
        } else if let start = startedAt {
            elapsed += Date().timeIntervalSince(start)
            startedAt = nil
        }
    }
}

#Preview {
    NavigationStack { RotateBeamDemoView() }
}
