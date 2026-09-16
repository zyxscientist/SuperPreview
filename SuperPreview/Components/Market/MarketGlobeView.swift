//
//  MarketGlobeView.swift
//  SuperPreview
//
//  组件名称：市场页地球仪
//  简介：使用 COBE Metal renderer 在市场页复用完整世界城市地球仪。
//  用于：市场页港股 tab 的首屏装饰与后续行情入口扩展。
//

import Foundation
import SwiftUI
import UIKit
import simd

struct MarketGlobeOrientation: Codable, Equatable {
    // Captured on device in market-globe-parameters-2026-09-16T06-13-31Z.json.
    static let unitedStates = Self(phi: 0.10242424242424335, theta: -0.012121212121212368)
    static let initialPhi = 2.56
    static let initialTheta = -0.25

    var phi: Double
    var theta: Double

    init(phi: Double = Self.initialPhi, theta: Double = Self.initialTheta) {
        self.phi = phi
        self.theta = theta
    }
}

/// Sampled by the existing Metal frame clock so the sphere and its labels
/// use the same orientation, including when a transition is interrupted.
struct MarketGlobeRotation {
    let from: MarketGlobeOrientation
    let to: MarketGlobeOrientation
    var startedAt = Date()
    let duration: Double = 0.5
    var angularVelocity: Double = 0

    /// Roughly two minutes per revolution, shared by tab entry and drag release.
    static func spinning(from orientation: MarketGlobeOrientation) -> Self {
        Self(from: orientation, to: orientation, angularVelocity: 0.05)
    }

    func value(at date: Date) -> MarketGlobeOrientation {
        if angularVelocity != 0 {
            return MarketGlobeOrientation(
                phi: from.phi + max(date.timeIntervalSince(startedAt), 0) * angularVelocity,
                theta: from.theta
            )
        }
        let progress = min(max(date.timeIntervalSince(startedAt) / duration, 0), 1)
        // Cubic ease-out: starts promptly and decelerates into the target.
        let remaining = 1 - progress
        let eased = 1 - remaining * remaining * remaining
        let delta = atan2(sin(to.phi - from.phi), cos(to.phi - from.phi))
        return MarketGlobeOrientation(
            phi: from.phi + delta * eased,
            theta: from.theta + (to.theta - from.theta) * eased
        )
    }
}

/// The market page deliberately keeps the Metal surface separate from the
/// full COBE demo. This gives the production-shaped page a small, stable
/// surface while keeping the renderer, map texture, markers, arcs, and anchor
/// projection shared with the debug demo.
struct MarketGlobeView: View {
    let isActive: Bool
    let isCrypto: Bool
    @Binding var orientation: MarketGlobeOrientation
    @Binding var rotation: MarketGlobeRotation?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.demoLanguage) private var language
    @StateObject private var frameStore = CobeMetalFrameStore()
    @State private var dragStartPhi = MarketGlobeOrientation.initialPhi
    @State private var dragStartTheta = MarketGlobeOrientation.initialTheta
    @State private var isDragging = false
    @State private var cryptoArcSeed = UInt64.random(in: 1...UInt64.max)

    private let theme: CobeMetalTheme = .monochrome

    init(
        isActive: Bool = true,
        isCrypto: Bool = false,
        orientation: Binding<MarketGlobeOrientation>,
        rotation: Binding<MarketGlobeRotation?>
    ) {
        self.isActive = isActive
        self.isCrypto = isCrypto
        self._orientation = orientation
        self._rotation = rotation
    }

    var body: some View {
        let frame = frameStore.frame
        let currentOrientation = rotation?.value(at: Date()) ?? orientation

        GeometryReader { geometry in
            let sourceCanvasSize = MarketGlobeLayout.sourceCanvasSize(for: geometry.size.width)
            let configuration = makeConfiguration(
                phi: currentOrientation.phi,
                theta: currentOrientation.theta,
                canvasSize: sourceCanvasSize
            )
            let anchors = frame?.anchors
                ?? CobeMetalAnchorManager().update(
                    configuration: configuration,
                    in: sourceCanvasSize
                )
            let displayScale = MarketGlobeLayout.displayScale(for: geometry.size.width)
            let displayOffset = MarketGlobeLayout.displayOffset(
                for: geometry.size.width,
                sourceCanvasSize: sourceCanvasSize
            )

            ZStack(alignment: .topLeading) {
                CobeMetalView(
                    configuration: configuration,
                    frameStore: frameStore,
                    configurationProvider: { date, size in
                        let current = rotation?.value(at: date) ?? orientation
                        return makeConfiguration(
                            phi: current.phi,
                            theta: current.theta,
                            canvasSize: size
                        )
                    },
                    isActive: isActive
                )
                .frame(width: sourceCanvasSize.width, height: sourceCanvasSize.height)
                .scaleEffect(displayScale, anchor: .center)
                .offset(y: displayOffset.height)

                ForEach(configuration.markers) { marker in
                    if let projected = anchors.markers[marker.id],
                       let label = marker.label {
                        let transformedAnchor = MarketGlobeLayout.transform(
                            projected,
                            in: sourceCanvasSize,
                            scale: displayScale,
                            offset: displayOffset
                        )
                        CobeMarkerAnchorLabel(
                            text: label,
                            anchor: transformedAnchor,
                            in: sourceCanvasSize,
                            labelAlignment: marker.labelAlignment,
                            labelOffset: marker.labelOffset
                        )
                    }
                }
            }
            // Metal renders on the same 355pt source canvas as the Demo. The
            // market-specific transform happens inside this clipped viewport,
            // so the 143pt height does not alter the land-dot sampling.
            .frame(width: sourceCanvasSize.width, height: sourceCanvasSize.height, alignment: .topLeading)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .overlay(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color("color-base-1").opacity(0),
                        Color("color-base-1")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: MarketGlobeLayout.bottomFadeHeight)
                .allowsHitTesting(false)
            }
        }
        .frame(height: MarketGlobeLayout.visibleHeight)
        .background(Color("color-base-1"))
        .clipped()
        .contentShape(Rectangle())
        .gesture(rotationGesture)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(language.text(.marketGlobeAccessibility))
        .accessibilityIdentifier("market.globe")
    }

    private var rotationGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                if !isDragging {
                    orientation = rotation?.value(at: Date()) ?? orientation
                    rotation = nil
                    dragStartPhi = orientation.phi
                    dragStartTheta = orientation.theta
                    isDragging = true
                }

                orientation.phi = dragStartPhi + Double(value.translation.width) / 220
                orientation.theta = min(
                    max(dragStartTheta - Double(value.translation.height) / 220, -1.45),
                    1.45
                )
            }
            .onEnded { _ in
                isDragging = false
                if isCrypto {
                    rotation = .spinning(from: orientation)
                }
            }
    }

    private var markers: [CobeMetalMarker] {
        CobeMarkerPreset.worldCities.markers.map { marker in
            CobeMetalMarker(
                id: marker.id,
                location: marker.location,
                size: marker.size,
                color: marker.color,
                label: isCrypto || marker.id == "london" ? nil : language.text(markerCopyKey(for: marker.id)),
                screenOffset: marker.screenOffset,
                labelAlignment: marker.labelAlignment,
                labelOffset: marker.labelOffset
            )
        }
    }

    private func makeConfiguration(phi: Double, theta: Double, canvasSize: CGSize) -> CobeMetalConfiguration {
        var configuration = CobeMetalConfiguration()
        configuration.phi = Float(phi)
        configuration.theta = Float(theta)
        configuration.dark = CobeMetalConfiguration.demoDark
        configuration.diffuse = CobeMetalConfiguration.demoDiffuse
        configuration.mapSamples = CobeMetalConfiguration.demoMapSamples
        configuration.mapBrightness = CobeMetalConfiguration.demoMapBrightness
        configuration.mapBaseBrightness = CobeMetalConfiguration.demoMapBaseBrightness
        configuration.baseColor = theme.baseColor(for: colorScheme)
        configuration.landColor = theme.landColor(for: colorScheme)
        configuration.markerColor = theme.markerColor(for: colorScheme)
        configuration.glowColor = theme.glowColor(for: colorScheme)
        configuration.arcColor = theme.arcColor(for: colorScheme)
        configuration.arcWidth = CobeMetalConfiguration.demoArcWidth
        configuration.arcHeight = CobeMetalConfiguration.demoArcHeight
        // Crypto markers and arc endpoints sit directly on the globe surface.
        configuration.markerElevation = isCrypto ? 0 : CobeMetalConfiguration.demoMarkerElevation
        // The market surface is a crop of the same COBE scene, not a scaled
        // crop of the Demo's oversized debug viewport.  Keep the renderer's
        // map/marker/arc parameters shared with the Demo, while using the
        // camera scale required by the 143pt production viewport.
        configuration.scale = MarketGlobeLayout.renderScale
        configuration.offset = SIMD2(0, MarketGlobeLayout.sourceOffsetY)
        configuration.opacity = CobeMetalConfiguration.demoOpacity
        if isCrypto {
            // Sample once so markers and arcs share exactly the same endpoints,
            // including frames on a route's cycle boundary.
            let routes = MarketCryptoArcAnimation.arcs(at: CobeMetalAnimationClock.time, seed: cryptoArcSeed)
            configuration.arcs = routes
            configuration.markers = routes.flatMap { route in
                [
                    CobeMetalMarker(
                        id: "\(route.id)-from", location: route.from, size: 0.015,
                        animation: SIMD4(route.startTime, route.duration, 0, 0.06)
                    ),
                    CobeMetalMarker(
                        id: "\(route.id)-to", location: route.to, size: 0.015,
                        animation: SIMD4(route.startTime, route.duration, 0.8, 1)
                    )
                ]
            }
        } else {
            configuration.markers = markers
            configuration.arcs = CobeMarkerPreset.worldCities.arcs
        }
        return configuration
    }

    private func markerCopyKey(for id: String) -> DemoCopyKey {
        switch id {
        case "sf": return .marketSanFrancisco
        case "nyc": return .marketNewYork
        case "toronto": return .marketToronto
        case "london": return .marketLondon
        case "tokyo": return .marketTokyo
        case "shanghai": return .marketShanghai
        case "shenzhen": return .marketShenzhen
        case "hongkong": return .marketHongKong
        case "singapore": return .marketSingapore
        case "sydney": return .marketSydney
        case "saopaulo": return .marketSaoPaulo
        case "capetown": return .marketCapeTown
        default: return .marketGlobeAccessibility
        }
    }
}

/// Stable routes within each staggered four-second slot. Only the GPU advances
/// their reveal/fade; routes and buffers change when a new journey starts.
private enum MarketCryptoArcAnimation {
    static func arcs(at time: Float, seed: UInt64) -> [CobeMetalArc] {
        let duration: Float = 4
        return (0..<5).map { slot in
            let offset = Float(slot) * duration / 5
            let cycle = UInt64(floor((time + offset) / duration))
            var random = seed &+ (cycle &* 0x9E3779B97F4A7C15) &+ UInt64(slot) &* 0xBF58476D1CE4E5B9
            func next() -> Float {
                random = random &* 6364136223846793005 &+ 1442695040888963407
                return Float(random >> 40) / Float(1 << 24)
            }
            func location() -> SIMD2<Float> {
                // Uniform surface sampling, rather than selecting preset cities.
                SIMD2(asin(next() * 2 - 1) * 180 / .pi, next() * 360 - 180)
            }
            // Anchor one end in the northern band exposed by the market crop.
            // Longitude stays unrestricted; the globe's rotation reveals all sides.
            let minimumY = sin(Float(25) * .pi / 180)
            let maximumY = sin(Float(65) * .pi / 180)
            let northernLatitude = asin(minimumY + next() * (maximumY - minimumY)) * 180 / .pi
            let from = SIMD2(northernLatitude, next() * 360 - 180)
            var to = location()
            // Avoid almost coincident endpoints and near-antipodal Bezier arcs.
            for _ in 0..<24 {
                let separation = simd_dot(CobeProjection.latLonTo3D(from), CobeProjection.latLonTo3D(to))
                if separation > -0.65 && separation < 0.9 { break }
                to = location()
            }
            // The northern endpoint can be either the source or destination.
            let reversed = next() < 0.5
            return CobeMetalArc(
                id: "crypto-\(slot)-\(cycle)",
                from: reversed ? to : from,
                to: reversed ? from : to,
                startTime: Float(cycle) * duration - offset,
                duration: duration
            )
        }
    }
}

enum MarketGlobeParameterExporter {
    static func makeFile(
        orientation: MarketGlobeOrientation,
        language: DemoLanguage,
        colorScheme: ColorScheme,
        selectedTab: String
    ) throws -> URL {
        let screen = UIScreen.main
        let referenceWidth = MarketGlobeLayout.referenceDeviceWidth
        let referenceCanvas = MarketGlobeLayout.sourceCanvasSize(for: referenceWidth)
        let theme = CobeMetalTheme.monochrome
        let formatter = ISO8601DateFormatter()

        let payload = Payload(
            schemaVersion: 1,
            exportedAt: formatter.string(from: Date()),
            page: Page(
                surface: "market",
                tab: selectedTab,
                language: language.rawValue
            ),
            device: Device(
                model: UIDevice.current.model,
                systemVersion: UIDevice.current.systemVersion,
                screenWidth: Double(screen.bounds.width),
                screenHeight: Double(screen.bounds.height),
                screenScale: Double(screen.scale)
            ),
            orientation: orientation,
            layout: Layout(
                visibleHeight: Double(MarketGlobeLayout.visibleHeight),
                bottomFadeHeight: Double(MarketGlobeLayout.bottomFadeHeight),
                horizontalInset: Double(MarketGlobeLayout.horizontalInset),
                globeTopInset: Double(MarketGlobeLayout.globeTopInset),
                sourceCanvasHeight: Double(MarketGlobeLayout.sourceCanvasHeight),
                referenceDeviceWidth: Double(referenceWidth),
                referenceMetalEarthWidth: Double(MarketGlobeLayout.referenceMetalEarthWidth),
                referenceDisplayScale: Double(MarketGlobeLayout.displayScale(for: referenceWidth)),
                referenceDisplayOffsetY: Double(
                    MarketGlobeLayout.displayOffset(
                        for: referenceWidth,
                        sourceCanvasSize: referenceCanvas
                    ).height
                )
            ),
            renderer: Renderer(
                dark: Double(CobeMetalConfiguration.demoDark),
                diffuse: Double(CobeMetalConfiguration.demoDiffuse),
                mapSamples: Double(CobeMetalConfiguration.demoMapSamples),
                mapBrightness: Double(CobeMetalConfiguration.demoMapBrightness),
                mapBaseBrightness: Double(CobeMetalConfiguration.demoMapBaseBrightness),
                arcWidth: Double(CobeMetalConfiguration.demoArcWidth),
                arcHeight: Double(CobeMetalConfiguration.demoArcHeight),
                markerElevation: Double(CobeMetalConfiguration.demoMarkerElevation),
                scale: Double(MarketGlobeLayout.renderScale),
                offset: Vector2(
                    x: 0,
                    y: Double(MarketGlobeLayout.sourceOffsetY)
                ),
                opacity: Double(CobeMetalConfiguration.demoOpacity)
            ),
            colors: Colors(
                colorScheme: colorScheme == .dark ? "dark" : "light",
                base: RGB(theme.baseColor(for: colorScheme)),
                land: RGB(theme.landColor(for: colorScheme)),
                marker: RGB(theme.markerColor(for: colorScheme)),
                glow: RGB(theme.glowColor(for: colorScheme)),
                arc: RGB(theme.arcColor(for: colorScheme))
            ),
            data: Content(
                markerPreset: CobeMarkerPreset.worldCities.rawValue,
                markers: CobeMarkerPreset.worldCities.markers.map { marker in
                    Marker(
                        id: marker.id,
                        label: marker.label ?? marker.id,
                        latitude: Double(marker.location.x),
                        longitude: Double(marker.location.y),
                        size: Double(marker.size),
                        screenOffset: Vector2(
                            x: Double(marker.screenOffset.x),
                            y: Double(marker.screenOffset.y)
                        ),
                        labelAlignment: labelAlignmentName(marker.labelAlignment),
                        labelOffset: Vector2(
                            x: Double(marker.labelOffset.x),
                            y: Double(marker.labelOffset.y)
                        )
                    )
                },
                arcs: CobeMarkerPreset.worldCities.arcs.map { arc in
                    Arc(
                        id: arc.id,
                        label: arc.label ?? arc.id,
                        from: Vector2(
                            x: Double(arc.from.x),
                            y: Double(arc.from.y)
                        ),
                        to: Vector2(
                            x: Double(arc.to.x),
                            y: Double(arc.to.y)
                        )
                    )
                }
            ),
            interaction: Interaction(
                dragMinimumDistance: 8,
                pointsPerRadian: 220,
                thetaMinimum: -1.45,
                thetaMaximum: 1.45
            )
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(payload)
        let timestamp = formatter
            .string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("market-globe-parameters-\(timestamp).json")
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func labelAlignmentName(_ alignment: CobeMetalMarkerLabelAlignment) -> String {
        switch alignment {
        case .center: return "center"
        case .leading: return "leading"
        case .trailing: return "trailing"
        }
    }

    private struct Payload: Encodable {
        let schemaVersion: Int
        let exportedAt: String
        let page: Page
        let device: Device
        let orientation: MarketGlobeOrientation
        let layout: Layout
        let renderer: Renderer
        let colors: Colors
        let data: Content
        let interaction: Interaction
    }

    private struct Page: Encodable {
        let surface: String
        let tab: String
        let language: String
    }

    private struct Device: Encodable {
        let model: String
        let systemVersion: String
        let screenWidth: Double
        let screenHeight: Double
        let screenScale: Double
    }

    private struct Layout: Encodable {
        let visibleHeight: Double
        let bottomFadeHeight: Double
        let horizontalInset: Double
        let globeTopInset: Double
        let sourceCanvasHeight: Double
        let referenceDeviceWidth: Double
        let referenceMetalEarthWidth: Double
        let referenceDisplayScale: Double
        let referenceDisplayOffsetY: Double
    }

    private struct Renderer: Encodable {
        let dark: Double
        let diffuse: Double
        let mapSamples: Double
        let mapBrightness: Double
        let mapBaseBrightness: Double
        let arcWidth: Double
        let arcHeight: Double
        let markerElevation: Double
        let scale: Double
        let offset: Vector2
        let opacity: Double
    }

    private struct Colors: Encodable {
        let colorScheme: String
        let base: RGB
        let land: RGB
        let marker: RGB
        let glow: RGB
        let arc: RGB
    }

    private struct RGB: Encodable {
        let red: Double
        let green: Double
        let blue: Double

        init(_ color: SIMD3<Float>) {
            red = Double(color.x)
            green = Double(color.y)
            blue = Double(color.z)
        }
    }

    private struct Content: Encodable {
        let markerPreset: String
        let markers: [Marker]
        let arcs: [Arc]
    }

    private struct Marker: Encodable {
        let id: String
        let label: String
        let latitude: Double
        let longitude: Double
        let size: Double
        let screenOffset: Vector2
        let labelAlignment: String
        let labelOffset: Vector2
    }

    private struct Arc: Encodable {
        let id: String
        let label: String
        let from: Vector2
        let to: Vector2
    }

    private struct Interaction: Encodable {
        let dragMinimumDistance: Double
        let pointsPerRadian: Double
        let thetaMinimum: Double
        let thetaMaximum: Double
    }

    private struct Vector2: Encodable {
        let x: Double
        let y: Double
    }
}

private enum MarketGlobeLayout {
    // The Figma hero is a 143pt viewport with a 24pt white bottom mask.
    static let visibleHeight: CGFloat = 140
    static let bottomFadeHeight: CGFloat = 32

    static let horizontalInset: CGFloat = 16
    static let globeTopInset: CGFloat = 8
    static let sourceCanvasHeight: CGFloat = 355
    static let referenceDeviceWidth: CGFloat = 402
    static let referenceMetalEarthWidth: CGFloat = 441

    // The Hong Kong / East Asia view is intentional: it matches the design
    // reference instead of the demo's initial Pacific-facing orientation.
    static let initialPhi = MarketGlobeOrientation.initialPhi
    static let initialTheta = MarketGlobeOrientation.initialTheta
    static let renderScale: Float = 1.27
    // Keep the full sphere inside the source MTKView before applying the
    // production crop.  The matching display compensation below cancels this
    // translation after the source raster has been transformed.
    static let sourceOffsetY: Float = 50

    static func sourceCanvasSize(for containerWidth: CGFloat) -> CGSize {
        CGSize(
            width: max(containerWidth, 1),
            height: sourceCanvasHeight
        )
    }

    static func displayScale(for containerWidth: CGFloat) -> CGFloat {
        // Figma places the Demo-sized Metal image in a 441pt frame and lets
        // 20pt overflow past the 402pt market viewport. Scale proportionally
        // with the device width instead of fitting the globe to the viewport.
        let widthScale = max(containerWidth, 1) / referenceDeviceWidth
        return widthScale * referenceMetalEarthWidth / referenceDeviceWidth
    }

    static func displayOffset(
        for containerWidth: CGFloat,
        sourceCanvasSize: CGSize
    ) -> CGSize {
        let targetDiameter = max(containerWidth - horizontalInset * 2, 1)
        let targetCenterY = targetDiameter / 2 + globeTopInset
        let sourceCenterY = sourceCanvasSize.height / 2
        // The design's globe centre sits lower than the source canvas centre;
        // this is what exposes the apex/outline while retaining the 16pt side
        // clearance in the visible part of the sphere.
        let sourceTranslation = CGFloat(sourceOffsetY * renderScale / 2)
        let displayCompensation = sourceTranslation * displayScale(for: containerWidth)
        return CGSize(
            width: 0,
            height: targetCenterY - sourceCenterY + 18 - displayCompensation
        )
    }

    static func transform(
        _ anchor: CobeProjectedPoint,
        in sourceCanvasSize: CGSize,
        scale: CGFloat,
        offset: CGSize
    ) -> CobeProjectedPoint {
        let sourcePoint = anchor.point(in: sourceCanvasSize)
        let sourceCenter = CGPoint(
            x: sourceCanvasSize.width / 2,
            y: sourceCanvasSize.height / 2
        )
        let transformedPoint = CGPoint(
            x: sourceCenter.x + (sourcePoint.x - sourceCenter.x) * scale + offset.width,
            y: sourceCenter.y + (sourcePoint.y - sourceCenter.y) * scale + offset.height
        )
        return CobeProjectedPoint(
            normalizedPoint: CGPoint(
                x: transformedPoint.x / max(sourceCanvasSize.width, 1),
                y: transformedPoint.y / max(sourceCanvasSize.height, 1)
            ),
            visible: anchor.visible
        )
    }

}
