//
//  CobeMetalDemoView.swift
//  SuperPreview
//

import Foundation
import SwiftUI

struct CobeMetalDemoView: View {
    @State private var phi = 0.0
    @State private var theta = 0.0
    @State private var dark = 0.0
    @State private var diffuse = 1.2
    @State private var mapSamples = 16_000.0
    @State private var mapBrightness = 6.0
    @State private var mapBaseBrightness = 0.0
    @State private var scale = 1.0
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
    @State private var theme: CobeMetalTheme = .blue
    @State private var autoRotationBase = 0.0
    @State private var autoRotationStartedAt = Date()

    var body: some View {
        let initialConfiguration = makeConfiguration(phi: phi)

        ScrollView {
            VStack(spacing: 16) {
                CobeMetalGlobePanel(
                    initialConfiguration: initialConfiguration,
                    showLabels: showLabels,
                    markerColor: theme.markerColor,
                    phi: $phi,
                    theta: $theta,
                    autoRotate: $autoRotate,
                    autoRotationBase: $autoRotationBase,
                    autoRotationStartedAt: $autoRotationStartedAt,
                    configurationProvider: { date, _ in
                        makeConfiguration(phi: animatedPhi(at: date))
                    }
                )
                configurationPanel
                implementationPanel
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color("color-base-0"))
        .navigationTitle("COBE Metal")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("cobe.metal.page")
        .onAppear {
            autoRotationStartedAt = Date()
            autoRotationBase = phi
        }
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
                                    in: geometry.size
                                )
                            }
                        }

                        ForEach(configuration.arcs) { arc in
                            if let projected = anchors.arcs[arc.id],
                               let label = arc.label {
                                CobeArcAnchorLabel(
                                    text: label,
                                    anchor: projected,
                                    in: geometry.size
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
                                dragStartPhi = Double(configuration.phi)
                                dragStartTheta = theta
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
        .background(Color("color-base-1"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color("color-text-90").opacity(0.45), lineWidth: 0.5)
        )
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

    init(text: String, anchor: CobeProjectedPoint, in size: CGSize) {
        self.text = text
        self.anchor = anchor
        self.size = size
    }

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .overlay(alignment: .bottom) {
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
            .opacity(anchor.visible ? 1 : 0)
            .zIndex(2)
            .allowsHitTesting(false)
    }
}

private struct CobeArcAnchorLabel: View {
    let text: String
    let anchor: CobeProjectedPoint
    let size: CGSize

    init(text: String, anchor: CobeProjectedPoint, in size: CGSize) {
        self.text = text
        self.anchor = anchor
        self.size = size
    }

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .overlay(alignment: .bottom) {
                Text(text)
                    .fixedSize()
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color("color-brand-blue"))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 3)
                    .background(Color("color-base-1").opacity(0.84))
                    .clipShape(Capsule())
            }
            .position(anchor.point(in: size))
            .opacity(anchor.visible ? 1 : 0)
            .zIndex(2)
            .allowsHitTesting(false)
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
                ForEach(CobeMetalTheme.allCases) { item in
                    Button {
                        theme = item
                    } label: {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color(red: Double(item.markerColor.x), green: Double(item.markerColor.y), blue: Double(item.markerColor.z)))
                                .frame(width: 9, height: 9)
                            Text(item.title)
                                .font(.system(size: 11, weight: theme == item ? .bold : .medium, design: .monospaced))
                        }
                        .foregroundColor(theme == item ? Color("color-text-30") : Color("color-text-60"))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .background(theme == item ? Color("color-brand-blue").opacity(0.13) : Color.clear)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
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
                range: 0.75...1.3,
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
                range: -100...100,
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

    private func makeConfiguration(phi: Double) -> CobeMetalConfiguration {
        var configuration = CobeMetalConfiguration()
        configuration.phi = Float(phi)
        configuration.theta = Float(theta)
        configuration.dark = Float(dark)
        configuration.diffuse = Float(diffuse)
        configuration.mapSamples = Float(mapSamples)
        configuration.mapBrightness = Float(mapBrightness)
        configuration.mapBaseBrightness = Float(mapBaseBrightness)
        configuration.baseColor = theme.baseColor
        configuration.markerColor = theme.markerColor
        configuration.glowColor = theme.glowColor
        configuration.arcColor = theme.arcColor
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

private enum CobeMetalTheme: String, CaseIterable, Identifiable, Hashable {
    case blue
    case neon
    case monochrome

    var id: String { rawValue }

    var title: String {
        switch self {
        case .blue: return "Blue"
        case .neon: return "Neon"
        case .monochrome: return "Mono"
        }
    }

    var baseColor: SIMD3<Float> {
        switch self {
        case .blue: return SIMD3(0.72, 0.84, 1.0)
        case .neon: return SIMD3(0.7, 1.0, 0.86)
        case .monochrome: return SIMD3(0.92, 0.94, 0.98)
        }
    }

    var markerColor: SIMD3<Float> {
        switch self {
        case .blue: return SIMD3(0.12, 0.48, 1.0)
        case .neon: return SIMD3(0.12, 1.0, 0.62)
        case .monochrome: return SIMD3(0.96, 0.96, 1.0)
        }
    }

    var glowColor: SIMD3<Float> {
        switch self {
        case .blue: return SIMD3(0.22, 0.55, 1.0)
        case .neon: return SIMD3(0.12, 0.92, 0.58)
        case .monochrome: return SIMD3(0.72, 0.8, 1.0)
        }
    }

    var arcColor: SIMD3<Float> {
        switch self {
        case .blue: return SIMD3(0.24, 0.58, 1.0)
        case .neon: return SIMD3(0.2, 1.0, 0.72)
        case .monochrome: return SIMD3(0.78, 0.84, 1.0)
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
                marker("sf", "San Francisco", 37.78, -122.44, 0.035),
                marker("nyc", "New York", 40.71, -74.01, 0.035),
                marker("london", "London", 51.51, -0.13, 0.03),
                marker("tokyo", "Tokyo", 35.68, 139.65, 0.04),
                marker("singapore", "Singapore", 1.35, 103.82, 0.03),
                marker("sydney", "Sydney", -33.87, 151.21, 0.03),
                marker("dubai", "Dubai", 25.2, 55.27, 0.03),
                marker("saopaulo", "São Paulo", -23.55, -46.63, 0.03),
                marker("capetown", "Cape Town", -33.92, 18.42, 0.03)
            ]
        case .usOffices:
            return [
                marker("seattle", "Seattle", 47.61, -122.33, 0.04),
                marker("sf", "San Francisco", 37.78, -122.44, 0.04),
                marker("austin", "Austin", 30.27, -97.74, 0.04),
                marker("nyc", "New York", 40.71, -74.01, 0.04),
                marker("boston", "Boston", 42.36, -71.06, 0.04),
                marker("chicago", "Chicago", 41.88, -87.63, 0.04)
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
                marker("oregon", "Oregon", 45.52, -122.68, 0.04),
                marker("virginia", "Virginia", 37.43, -78.66, 0.04),
                marker("frankfurt", "Frankfurt", 50.11, 8.68, 0.04),
                marker("mumbai", "Mumbai", 19.08, 72.88, 0.04),
                marker("tokyo", "Tokyo", 35.68, 139.65, 0.04),
                marker("sydney", "Sydney", -33.87, 151.21, 0.04)
            ]
        }
    }

    var arcs: [CobeMetalArc] {
        switch self {
        case .worldCities:
            return [
                arc("sf-nyc", "SFO → JFK", 37.78, -122.44, 40.71, -74.01),
                arc("nyc-london", "JFK → LHR", 40.71, -74.01, 51.51, -0.13),
                arc("london-tokyo", "LHR → HND", 51.51, -0.13, 35.68, 139.65)
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
        _ size: Float
    ) -> CobeMetalMarker {
        CobeMetalMarker(
            id: id,
            location: SIMD2(latitude, longitude),
            size: size,
            label: label
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
