//
//  CobeMetalDemoView.swift
//  SuperPreview
//

import Foundation
import SwiftUI

private struct CobeRotationTransition: Equatable {
    let id: UUID
    let startPhi: Double
    let endPhi: Double
    let startTheta: Double
    let endTheta: Double
    let startedAt: Date
    let duration: TimeInterval

    init(
        startPhi: Double,
        endPhi: Double,
        startTheta: Double,
        endTheta: Double,
        startedAt: Date,
        duration: TimeInterval = 0.65
    ) {
        self.id = UUID()
        self.startPhi = startPhi
        self.endPhi = endPhi
        self.startTheta = startTheta
        self.endTheta = endTheta
        self.startedAt = startedAt
        self.duration = duration
    }

    func rotation(at date: Date) -> SIMD2<Double> {
        let progress = min(max(date.timeIntervalSince(startedAt) / duration, 0), 1)
        let easedProgress = progress * progress * (3 - 2 * progress)

        return SIMD2(
            startPhi + (endPhi - startPhi) * easedProgress,
            startTheta + (endTheta - startTheta) * easedProgress
        )
    }
}

struct CobeMetalDemoView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var phi = 0.0
    @State private var theta = 0.0
    @State private var dark = 0.0
    @State private var diffuse = 1.2
    @State private var mapSamples = 16_000.0
    @State private var mapBrightness = 6.0
    @State private var mapBaseBrightness = 0.0
    @State private var scale = 1.90
    @State private var offsetX = 0.0
    @State private var offsetY = 0.0
    @State private var opacity = 1.0
    @State private var markerElevation = 0.02
    @State private var arcHeight = 0.3
    @State private var arcWidth = 0.5
    @State private var showArcs = true
    @State private var showLabels = true
    @State private var autoRotate = true
    @State private var markerPreset: CobeMarkerPreset = .worldCities
    private let theme: CobeMetalTheme = .monochrome
    @State private var autoRotationBase = 0.0
    @State private var autoRotationStartedAt = Date()
    @State private var focusedMarkerID: String?
    @State private var focusTransition: CobeRotationTransition?

    var body: some View {
        let initialConfiguration = makeConfiguration(phi: phi)

        ScrollView {
            VStack(spacing: 16) {
                CobeMetalGlobePanel(
                    initialConfiguration: initialConfiguration,
                    showLabels: showLabels,
                    markerColor: theme.markerColor(for: colorScheme),
                    phi: $phi,
                    theta: $theta,
                    autoRotate: $autoRotate,
                    autoRotationBase: $autoRotationBase,
                    autoRotationStartedAt: $autoRotationStartedAt,
                    focusTransition: $focusTransition,
                    configurationProvider: { date, _ in
                        let rotation = rotation(at: date)
                        return makeConfiguration(phi: rotation.x, theta: rotation.y)
                    }
                )
                CobeRotationAnglePanel(
                    isAnimating: autoRotate || focusTransition != nil,
                    rotationProvider: { date in rotation(at: date) }
                )
                .padding(.horizontal, 16)
                CobeLocationFocusPanel(
                    markers: markerPreset.markers,
                    focusedMarkerID: focusedMarkerID,
                    onSelect: focus(on:)
                )
                .padding(.horizontal, 16)
                configurationPanel
                    .padding(.horizontal, 16)
                implementationPanel
                    .padding(.horizontal, 16)
            }
            .padding(.vertical, 12)
        }
        .background(Color("color-base-1"))
        .navigationTitle("COBE Metal")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("cobe.metal.page")
        .onAppear {
            autoRotationStartedAt = Date()
            autoRotationBase = phi
        }
        .onChange(of: markerPreset) { _, _ in
            focusedMarkerID = nil
            focusTransition = nil
        }
    }

    private func focus(on marker: CobeMetalMarker) {
        let now = Date()
        let currentRotation = rotation(at: now)
        let targetRotation = CobeProjection.rotationToFace(marker.location)
        let targetPhi = currentRotation.x + shortestAngleDelta(
            from: currentRotation.x,
            to: Double(targetRotation.x)
        )
        let targetTheta = Double(targetRotation.y)
        let transition = CobeRotationTransition(
            startPhi: currentRotation.x,
            endPhi: targetPhi,
            startTheta: currentRotation.y,
            endTheta: targetTheta,
            startedAt: now
        )

        // Store the final values immediately, while the display-link provider
        // renders the explicit start-to-end transition for every frame.
        phi = targetPhi
        theta = targetTheta
        autoRotationBase = targetPhi
        autoRotationStartedAt = now
        focusTransition = transition
        if autoRotate {
            autoRotate = false
        }
        focusedMarkerID = marker.id

        let transitionID = transition.id
        DispatchQueue.main.asyncAfter(deadline: .now() + transition.duration) {
            guard focusTransition?.id == transitionID else { return }
            focusTransition = nil
        }
    }

    private func rotation(at date: Date) -> SIMD2<Double> {
        if let focusTransition {
            return focusTransition.rotation(at: date)
        }
        return SIMD2(animatedPhi(at: date), theta)
    }

    private func shortestAngleDelta(from current: Double, to target: Double) -> Double {
        let tau = Double.pi * 2
        return (target - current + Double.pi)
            .truncatingRemainder(dividingBy: tau)
            - Double.pi
    }

private struct CobeMetalGlobePanel: View {
    let initialConfiguration: CobeMetalConfiguration
    let showLabels: Bool
    let markerColor: SIMD3<Float>

    @Binding var phi: Double
    @Binding var theta: Double
    @Binding var autoRotate: Bool
    @Binding var autoRotationBase: Double
    @Binding var autoRotationStartedAt: Date
    @Binding var focusTransition: CobeRotationTransition?

    let configurationProvider: (Date, CGSize) -> CobeMetalConfiguration

    @StateObject private var frameStore = CobeMetalFrameStore()
    @State private var dragStartPhi = 0.0
    @State private var dragStartTheta = 0.0
    @State private var isDragging = false

    var body: some View {
        let frame = frameStore.frame
        let configuration = frame?.configuration ?? initialConfiguration

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("COBE / NATIVE PORT")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color("color-text-60"))
                    Text("Metal 点阵地球")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(Color("color-text-30"))
                }

                Spacer()

                Text("MSL 4.1")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color("color-brand-blue"))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color("color-brand-blue").opacity(0.12))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 10)

            GeometryReader { geometry in
                let anchors = frame?.anchors
                    ?? CobeMetalAnchorManager().update(
                        configuration: configuration,
                        in: geometry.size
                    )

                ZStack {
                    CobeMetalView(
                        configuration: configuration,
                        frameStore: frameStore,
                        configurationProvider: configurationProvider
                    )

                    if showLabels {
                        ForEach(configuration.markers) { marker in
                            if let projected = anchors.markers[marker.id],
                               let label = marker.label {
                                CobeMarkerAnchorLabel(
                                    text: label,
                                    anchor: projected,
                                    in: geometry.size,
                                    labelAlignment: marker.labelAlignment,
                                    labelOffset: marker.labelOffset
                                )
                            }
                        }

                    }

                    VStack {
                        HStack {
                            Text("3 PASS RENDER")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(Color("color-text-60"))
                            Spacer()
                            Text("\(configuration.markers.count) MARKERS · \(configuration.arcs.count) ARCS")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(Color("color-text-60"))
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "hand.draw")
                            Text("拖动旋转 · 调整下方参数")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color("color-text-60"))
                    }
                    .padding(16)
                    .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { gesture in
                            if !isDragging {
                                focusTransition = nil
                                dragStartPhi = Double(configuration.phi)
                                dragStartTheta = Double(configuration.theta)
                                isDragging = true
                                if autoRotate {
                                    autoRotationBase = Double(configuration.phi)
                                    autoRotationStartedAt = Date()
                                    autoRotate = false
                                }
                            }

                            phi = dragStartPhi + Double(gesture.translation.width) / 220
                            theta = min(
                                max(dragStartTheta - Double(gesture.translation.height) / 220, -1.45),
                                1.45
                            )
                        }
                        .onEnded { _ in
                            isDragging = false
                            autoRotationBase = phi
                            autoRotationStartedAt = Date()
                        }
                )
            }
            .frame(height: 355)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("COBE Metal 点阵地球，可拖动旋转")

            HStack(spacing: 10) {
                Circle()
                    .fill(Color(red: Double(markerColor.x), green: Double(markerColor.y), blue: Double(markerColor.z)))
                    .frame(width: 7, height: 7)
                Text("球面 Fibonacci 点阵 · 片元 Shader · 实例化标记与弧线")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("color-text-60"))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }
}

private struct CobeRotationAnglePanel: View {
    let isAnimating: Bool
    let rotationProvider: (Date) -> SIMD2<Double>

    var body: some View {
        TimelineView(
            .animation(
                minimumInterval: 1.0 / 30.0,
                paused: !isAnimating
            )
        ) { timeline in
            let rotation = rotationProvider(timeline.date)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("当前转动角度")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("color-text-30"))
                        Text("实时读取当前渲染中的 phi / theta")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(Color("color-text-60"))
                    }

                    Spacer(minLength: 0)

                    Text(isAnimating ? "LIVE" : "PAUSED")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isAnimating ? Color("color-brand-blue") : Color("color-text-60"))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            (isAnimating ? Color("color-brand-blue") : Color("color-text-60"))
                                .opacity(0.12)
                        )
                        .clipShape(Capsule())
                }

                HStack(spacing: 10) {
                    rotationValue(title: "phi / 水平旋转", radians: rotation.x)
                    rotationValue(title: "theta / 垂直旋转", radians: rotation.y)
                }
            }
            .padding(16)
            .background(Color("color-base-1"))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color("color-text-90").opacity(0.45), lineWidth: 0.5)
            )
        }
        .accessibilityIdentifier("cobe.rotationAnglePanel")
    }

    private func rotationValue(title: String, radians: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(Color("color-text-60"))
            Text(String(format: "%+.3f rad", radians))
                .font(.system(size: 16, weight: .semibold, design: .monospaced))
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(String(format: "%+.1f°", radians * 180.0 / Double.pi))
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color("color-text-60"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color("color-base-0").opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct CobeLocationFocusPanel: View {
    let markers: [CobeMetalMarker]
    let focusedMarkerID: String?
    let onSelect: (CobeMetalMarker) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 8)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("快速定位")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                Text("点击城市，观看地球平滑转到正面")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("color-text-60"))
            }

            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(markers) { marker in
                    if let label = marker.label {
                        let isFocused = focusedMarkerID == marker.id

                        Button {
                            onSelect(marker)
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color("color-brand-blue"))
                                    .frame(width: 6, height: 6)
                                Text(label)
                                    .font(.system(size: 10, weight: isFocused ? .bold : .medium, design: .monospaced))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.72)
                                    .foregroundColor(isFocused ? Color("color-text-30") : Color("color-text-60"))
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                isFocused
                                    ? Color("color-brand-blue").opacity(0.14)
                                    : Color("color-base-0").opacity(0.55)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .stroke(
                                        isFocused
                                            ? Color("color-brand-blue").opacity(0.35)
                                            : Color("color-text-90").opacity(0.35),
                                        lineWidth: 0.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("cobe.focus.\(marker.id)")
                        .accessibilityLabel("定位到 \(label)")
                    }
                }
            }
        }
        .padding(16)
        .background(Color("color-base-1"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color("color-text-90").opacity(0.45), lineWidth: 0.5)
        )
        .accessibilityIdentifier("cobe.locationFocusPanel")
    }
}

/// A SwiftUI equivalent of COBE's invisible CSS anchor element.
///
/// The 1x1 clear view is positioned at the projected marker center. The label
/// is overlaid with its bottom edge aligned to that view's bottom edge, which
/// is the native equivalent of `bottom: anchor(top); left: anchor(center)`.
private struct CobeMarkerAnchorLabel: View {
    let text: String
    let anchor: CobeProjectedPoint
    let size: CGSize
    let labelAlignment: CobeMetalMarkerLabelAlignment
    let labelOffset: SIMD2<Float>

    init(
        text: String,
        anchor: CobeProjectedPoint,
        in size: CGSize,
        labelAlignment: CobeMetalMarkerLabelAlignment,
        labelOffset: SIMD2<Float>
    ) {
        self.text = text
        self.anchor = anchor
        self.size = size
        self.labelAlignment = labelAlignment
        self.labelOffset = labelOffset
    }

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .overlay(alignment: overlayAlignment) {
                Text(text)
                    .fixedSize()
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color("color-text-30"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color("color-base-1").opacity(0.9))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color("color-text-90").opacity(0.5), lineWidth: 0.5)
                    )
            }
            .position(anchor.point(in: size))
            .offset(x: CGFloat(labelOffset.x), y: CGFloat(labelOffset.y))
            .opacity(anchor.visible ? 1 : 0)
            .zIndex(2)
            .allowsHitTesting(false)
    }

    private var overlayAlignment: Alignment {
        switch labelAlignment {
        case .center:
            return .bottom
        case .leading:
            return .bottomLeading
        case .trailing:
            return .bottomTrailing
        }
    }
}

    private var configurationPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            panelHeader(title: "配置面板", subtitle: "对应 COBE 的公开 options")

            HStack {
                Text("数据预设")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                Spacer()
                Picker("数据预设", selection: $markerPreset) {
                    ForEach(CobeMarkerPreset.allCases) { preset in
                        Text(preset.title).tag(preset)
                    }
                }
                .pickerStyle(.menu)
                .tint(Color("color-brand-blue"))
                .accessibilityIdentifier("cobe.markerPreset")
            }

            HStack(spacing: 8) {
                Text("主题")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                Spacer()
                Text(theme.title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(Color("color-text-30"))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .background(Color("color-text-60").opacity(0.12))
                    .clipShape(Capsule())
            }

            Toggle("自动旋转", isOn: $autoRotate)
                .tint(Color("color-brand-blue"))
                .accessibilityIdentifier("cobe.autoRotate")
                .onChange(of: autoRotate) { _, newValue in
                    let now = Date()
                    phi = animatedPhi(at: now)
                    autoRotationBase = phi
                    autoRotationStartedAt = now
                }

            Toggle("显示 Arcs", isOn: $showArcs)
                .tint(Color("color-brand-blue"))
                .accessibilityIdentifier("cobe.showArcs")

            Toggle("显示原生标签", isOn: $showLabels)
                .tint(Color("color-brand-blue"))
                .accessibilityIdentifier("cobe.showLabels")

            controlSlider(
                title: "phi / 水平旋转",
                value: $phi,
                range: -Double.pi...Double.pi,
                formatter: { String(format: "%.2f", $0) }
            )
            .accessibilityIdentifier("cobe.phi")

            controlSlider(
                title: "theta / 垂直倾角",
                value: $theta,
                range: -Double.pi / 2...Double.pi / 2,
                formatter: { String(format: "%.2f", $0) }
            )
            .accessibilityIdentifier("cobe.theta")

            controlSlider(
                title: "mapSamples / 点数量",
                value: $mapSamples,
                range: 2_000...40_000,
                step: 1_000,
                formatter: { String(format: "%.0f", $0) }
            )
            .accessibilityIdentifier("cobe.mapSamples")

            controlSlider(
                title: "mapBrightness / 地图亮度",
                value: $mapBrightness,
                range: 1...12,
                step: 0.5,
                formatter: { String(format: "%.1f", $0) }
            )

            controlSlider(
                title: "mapBaseBrightness / 海洋底亮度",
                value: $mapBaseBrightness,
                range: 0...1,
                step: 0.05,
                formatter: { String(format: "%.2f", $0) }
            )

            controlSlider(
                title: "diffuse / 漫反射",
                value: $diffuse,
                range: 0.5...3,
                step: 0.1,
                formatter: { String(format: "%.1f", $0) }
            )

            controlSlider(
                title: "dark / 暗部",
                value: $dark,
                range: 0...1,
                step: 0.05,
                formatter: { String(format: "%.2f", $0) }
            )

            controlSlider(
                title: "scale / 缩放",
                value: $scale,
                range: 0.75...4.0,
                step: 0.01,
                formatter: { String(format: "%.2f", $0) }
            )

            controlSlider(
                title: "opacity / 透明度",
                value: $opacity,
                range: 0.25...1,
                step: 0.05,
                formatter: { String(format: "%.2f", $0) }
            )

            controlSlider(
                title: "markerElevation / 标记高度",
                value: $markerElevation,
                range: 0...0.2,
                step: 0.01,
                formatter: { String(format: "%.2f", $0) }
            )

            controlSlider(
                title: "arcHeight / 弧线高度",
                value: $arcHeight,
                range: 0.1...0.5,
                step: 0.01,
                formatter: { String(format: "%.2f", $0) }
            )

            controlSlider(
                title: "arcWidth / 弧线宽度",
                value: $arcWidth,
                range: 0.1...2,
                step: 0.05,
                formatter: { String(format: "%.2f", $0) }
            )

            controlSlider(
                title: "offset.x / 水平偏移",
                value: $offsetX,
                range: -100...100,
                step: 1,
                formatter: { String(format: "%.0f", $0) }
            )

            controlSlider(
                title: "offset.y / 垂直偏移",
                value: $offsetY,
                range: -200...200,
                step: 1,
                formatter: { String(format: "%.0f", $0) }
            )
        }
        .padding(16)
        .background(Color("color-base-1"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color("color-text-90").opacity(0.45), lineWidth: 0.5)
        )
    }

    private var implementationPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            panelHeader(title: "原生实现", subtitle: "与 WebGL 版本的对应关系")

            implementationRow(
                title: "Globe pass",
                detail: "全屏 Quad + MSL 片元求交球面 / Fibonacci 点阵"
            )
            implementationRow(
                title: "Arc pass",
                detail: "实例化 66 点 Triangle Strip + 二次 Bézier"
            )
            implementationRow(
                title: "Marker pass",
                detail: "实例化 Quad + vertex_id / instance_id"
            )
            implementationRow(
                title: "Anchor manager",
                detail: "稳定 ID 快照 + 同一显示时钟驱动位置与 front/back 可见性"
            )
        }
        .padding(16)
        .background(Color("color-base-1"))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color("color-text-80").opacity(0.45), lineWidth: 0.5)
        )
    }

    private func panelHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color("color-text-30"))
            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Color("color-text-60"))
        }
    }

    private func implementationRow(title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color("color-brand-blue"))
                .frame(width: 4, height: 30)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color("color-text-30"))
                Text(detail)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private func controlSlider(
        title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double? = nil,
        formatter: @escaping (Double) -> String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("color-text-60"))
                Spacer()
                Text(formatter(value.wrappedValue))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color("color-text-30"))
            }

            if let step {
                Slider(value: value, in: range, step: step)
            } else {
                Slider(value: value, in: range)
            }
        }
    }

    private func animatedPhi(at date: Date) -> Double {
        guard autoRotate else { return phi }
        return autoRotationBase + date.timeIntervalSince(autoRotationStartedAt) * 0.18
    }

    private func makeConfiguration(
        phi: Double,
        theta thetaValue: Double? = nil
    ) -> CobeMetalConfiguration {
        var configuration = CobeMetalConfiguration()
        configuration.phi = Float(phi)
        configuration.theta = Float(thetaValue ?? theta)
        configuration.dark = Float(dark)
        configuration.diffuse = Float(diffuse)
        configuration.mapSamples = Float(mapSamples)
        configuration.mapBrightness = Float(mapBrightness)
        configuration.mapBaseBrightness = Float(mapBaseBrightness)
        configuration.baseColor = theme.baseColor(for: colorScheme)
        configuration.landColor = theme.landColor(for: colorScheme)
        configuration.markerColor = theme.markerColor(for: colorScheme)
        configuration.glowColor = theme.glowColor(for: colorScheme)
        configuration.arcColor = theme.arcColor(for: colorScheme)
        configuration.arcWidth = Float(arcWidth)
        configuration.arcHeight = Float(arcHeight)
        configuration.markerElevation = Float(markerElevation)
        configuration.scale = Float(scale)
        configuration.offset = SIMD2(Float(offsetX), Float(offsetY))
        configuration.opacity = Float(opacity)
        configuration.markers = markerPreset.markers
        configuration.arcs = showArcs ? markerPreset.arcs : []
        return configuration
    }
}

private enum CobeMetalTheme {
    case monochrome

    var title: String { "Mono" }

    func baseColor(for colorScheme: ColorScheme) -> SIMD3<Float> {
        switch colorScheme {
        case .dark:
            return SIMD3(repeating: 0.14)
        default:
            return SIMD3(repeating: 0.92)
        }
    }

    func markerColor(for _: ColorScheme) -> SIMD3<Float> {
        // color-brand-blue: #196EFF in both appearances.
        return SIMD3(
            Float(0x19) / 255.0,
            Float(0x6E) / 255.0,
            1.0
        )
    }

    func landColor(for colorScheme: ColorScheme) -> SIMD3<Float> {
        switch colorScheme {
        case .dark:
            // color-text-60 (text2) dark appearance: #C2C2C2.
            return SIMD3(repeating: Float(0xC2) / 255.0)
        default:
            // color-text-60 (text2) light appearance: #6D6D6D.
            return SIMD3(repeating: Float(0x6D) / 255.0)
        }
    }

    func glowColor(for colorScheme: ColorScheme) -> SIMD3<Float> {
        switch colorScheme {
        case .dark:
            return SIMD3(repeating: 0.42)
        default:
            return SIMD3(repeating: 0.72)
        }
    }

    func arcColor(for colorScheme: ColorScheme) -> SIMD3<Float> {
        switch colorScheme {
        case .dark:
            // color-text-30 dark appearance: #FFFFFF.
            return SIMD3(repeating: 1.0)
        default:
            // color-text-30 light appearance: #333333.
            return SIMD3(repeating: Float(0x33) / 255.0)
        }
    }
}

private enum CobeMarkerPreset: String, CaseIterable, Identifiable, Hashable {
    case worldCities
    case usOffices
    case flightRoutes
    case dataCenters

    var id: String { rawValue }

    var title: String {
        switch self {
        case .worldCities: return "World Cities"
        case .usOffices: return "US Offices"
        case .flightRoutes: return "Flight Routes"
        case .dataCenters: return "Data Centers"
        }
    }

    var markers: [CobeMetalMarker] {
        switch self {
        case .worldCities:
            return [
                marker("sf", "三藩市", 37.78, -122.44, 0.0175),
                marker(
                    "nyc",
                    "纽约",
                    40.71,
                    -74.01,
                    0.0175,
                    labelAlignment: .leading,
                    labelOffset: SIMD2(8, 0)
                ),
                marker("toronto", "多伦多", 43.6532, -79.3832, 0.0175),
                marker("london", "伦敦", 51.51, -0.13, 0.015),
                marker("tokyo", "东京", 35.68, 139.65, 0.02),
                marker(
                    "shanghai",
                    "上海",
                    31.2304,
                    121.4737,
                    0.0175,
                    labelAlignment: .leading,
                    labelOffset: SIMD2(8, 0)
                ),
                marker(
                    "shenzhen",
                    "深圳",
                    22.5431,
                    114.0579,
                    0.0175,
                    screenOffset: SIMD2(-0.012, -0.025),
                    labelAlignment: .trailing,
                    labelOffset: SIMD2(-8, 0)
                ),
                marker(
                    "hongkong",
                    "香港",
                    22.3193,
                    114.1694,
                    0.0175,
                    labelAlignment: .leading,
                    labelOffset: SIMD2(8, 0)
                ),
                marker("singapore", "新加坡", 1.35, 103.82, 0.015),
                marker("sydney", "悉尼", -33.87, 151.21, 0.015),
                marker("saopaulo", "圣保罗", -23.55, -46.63, 0.015),
                marker("capetown", "开普敦", -33.92, 18.42, 0.015)
            ]
        case .usOffices:
            return [
                marker("seattle", "西雅图", 47.61, -122.33, 0.04),
                marker("sf", "三藩市", 37.78, -122.44, 0.04),
                marker("austin", "奥斯汀", 30.27, -97.74, 0.04),
                marker("nyc", "纽约", 40.71, -74.01, 0.04),
                marker("boston", "波士顿", 42.36, -71.06, 0.04),
                marker("chicago", "芝加哥", 41.88, -87.63, 0.04)
            ]
        case .flightRoutes:
            return [
                marker("sf", "SFO", 37.62, -122.38, 0.04),
                marker("nyc", "JFK", 40.64, -73.78, 0.04),
                marker("london", "LHR", 51.47, -0.45, 0.04),
                marker("tokyo", "HND", 35.55, 139.78, 0.04),
                marker("singapore", "SIN", 1.36, 103.99, 0.04),
                marker("sydney", "SYD", -33.94, 151.18, 0.04)
            ]
        case .dataCenters:
            return [
                marker("oregon", "俄勒冈", 45.52, -122.68, 0.04),
                marker("virginia", "弗吉尼亚", 37.43, -78.66, 0.04),
                marker("frankfurt", "法兰克福", 50.11, 8.68, 0.04),
                marker("mumbai", "孟买", 19.08, 72.88, 0.04),
                marker("tokyo", "东京", 35.68, 139.65, 0.04),
                marker("sydney", "悉尼", -33.87, 151.21, 0.04)
            ]
        }
    }

    var arcs: [CobeMetalArc] {
        switch self {
        case .worldCities:
            return [
                arc("sf-nyc", "SFO → JFK", 37.78, -122.44, 40.71, -74.01),
                arc("nyc-london", "JFK → LHR", 40.71, -74.01, 51.51, -0.13),
                arc("london-tokyo", "LHR → HND", 51.51, -0.13, 35.68, 139.65),
                arc("london-hongkong", "London → Hong Kong", 51.51, -0.13, 22.3193, 114.1694),
                arc("hongkong-singapore", "Hong Kong → Singapore", 22.3193, 114.1694, 1.35, 103.82)
            ]
        case .usOffices:
            return [
                arc("sf-nyc", "SF → NYC", 37.78, -122.44, 40.71, -74.01),
                arc("seattle-austin", "SEA → AUS", 47.61, -122.33, 30.27, -97.74),
                arc("austin-nyc", "AUS → NYC", 30.27, -97.74, 40.71, -74.01)
            ]
        case .flightRoutes:
            return [
                arc("sfo-jfk", "SFO · JFK", 37.62, -122.38, 40.64, -73.78),
                arc("jfk-lhr", "JFK · LHR", 40.64, -73.78, 51.47, -0.45),
                arc("lhr-hnd", "LHR · HND", 51.47, -0.45, 35.55, 139.78),
                arc("hnd-sin", "HND · SIN", 35.55, 139.78, 1.36, 103.99)
            ]
        case .dataCenters:
            return [
                arc("oregon-frankfurt", "PDX → FRA", 45.52, -122.68, 50.11, 8.68),
                arc("frankfurt-mumbai", "FRA → BOM", 50.11, 8.68, 19.08, 72.88),
                arc("mumbai-tokyo", "BOM → TYO", 19.08, 72.88, 35.68, 139.65)
            ]
        }
    }

    private func marker(
        _ id: String,
        _ label: String,
        _ latitude: Float,
        _ longitude: Float,
        _ size: Float,
        screenOffset: SIMD2<Float> = .zero,
        labelAlignment: CobeMetalMarkerLabelAlignment = .center,
        labelOffset: SIMD2<Float> = .zero
    ) -> CobeMetalMarker {
        CobeMetalMarker(
            id: id,
            location: SIMD2(latitude, longitude),
            size: size,
            label: label,
            screenOffset: screenOffset,
            labelAlignment: labelAlignment,
            labelOffset: labelOffset
        )
    }

    private func arc(
        _ id: String,
        _ label: String,
        _ fromLatitude: Float,
        _ fromLongitude: Float,
        _ toLatitude: Float,
        _ toLongitude: Float
    ) -> CobeMetalArc {
        CobeMetalArc(
            id: id,
            from: SIMD2(fromLatitude, fromLongitude),
            to: SIMD2(toLatitude, toLongitude),
            label: label
        )
    }
}

struct CobeMetalDemoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CobeMetalDemoView()
        }
        .preferredColorScheme(.dark)
    }
}
