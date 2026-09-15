//
//  CobeMetalRenderer.swift
//  SuperPreview
//
//  A native Metal port of the rendering core used by shuding/cobe.
//

import Foundation
import Combine
import Metal
import MetalKit

struct CobeMetalMarker: Identifiable, Equatable {
    let id: String
    let location: SIMD2<Float>
    let size: Float
    let color: SIMD3<Float>?
    let label: String?

    init(
        id: String,
        location: SIMD2<Float>,
        size: Float,
        color: SIMD3<Float>? = nil,
        label: String? = nil
    ) {
        self.id = id
        self.location = location
        self.size = size
        self.color = color
        self.label = label
    }
}

struct CobeMetalArc: Identifiable, Equatable {
    let id: String
    let from: SIMD2<Float>
    let to: SIMD2<Float>
    let color: SIMD3<Float>?
    let label: String?

    init(
        id: String,
        from: SIMD2<Float>,
        to: SIMD2<Float>,
        color: SIMD3<Float>? = nil,
        label: String? = nil
    ) {
        self.id = id
        self.from = from
        self.to = to
        self.color = color
        self.label = label
    }
}

struct CobeMetalConfiguration: Equatable {
    var phi: Float = 0
    /// Zero tilt keeps the geographic north pole exactly at the top of the
    /// initial view; the user can still adjust theta from the demo controls.
    var theta: Float = 0
    var dark: Float = 0
    var diffuse: Float = 1.2
    var mapSamples: Float = 16_000
    var mapBrightness: Float = 6
    var mapBaseBrightness: Float = 0
    var baseColor = SIMD3<Float>(1, 1, 1)
    var markerColor = SIMD3<Float>(0.15, 0.45, 1)
    var glowColor = SIMD3<Float>(0.35, 0.65, 1)
    var arcColor = SIMD3<Float>(0.25, 0.55, 1)
    var arcWidth: Float = 0.5
    var arcHeight: Float = 0.3
    var markerElevation: Float = 0.02
    var scale: Float = 1
    var offset = SIMD2<Float>(0, 0)
    var opacity: Float = 1
    var markers: [CobeMetalMarker] = []
    var arcs: [CobeMetalArc] = []
}

struct CobeProjectedPoint: Equatable {
    /// The same normalized coordinates that COBE writes to CSS anchor offsets.
    /// Keeping this as a percentage makes the overlay independent from the
    /// drawable's Retina pixel size.
    let normalizedPoint: CGPoint
    let visible: Bool

    func point(in size: CGSize) -> CGPoint {
        CGPoint(
            x: normalizedPoint.x * size.width,
            y: normalizedPoint.y * size.height
        )
    }
}

enum CobeProjection {
    static let globeRadius: Float = 0.8
    private static let pi = Float.pi

    static func latLonTo3D(_ location: SIMD2<Float>) -> SIMD3<Float> {
        let lat = location.x * pi / 180
        let lon = location.y * pi / 180 - pi
        let cosLat = cos(lat)
        return SIMD3(
            -cosLat * cos(lon),
            sin(lat),
            cosLat * sin(lon)
        )
    }

    static func rotate(_ point: SIMD3<Float>, phi: Float, theta: Float) -> SIMD3<Float> {
        let cx = cos(theta)
        let cy = cos(phi)
        let sx = sin(theta)
        let sy = sin(phi)

        return SIMD3(
            cy * point.x + sy * point.z,
            sy * sx * point.x + cx * point.y - cy * sx * point.z,
            -sy * cx * point.x + sx * point.y + cy * cx * point.z
        )
    }

    static func project(
        marker: CobeMetalMarker,
        configuration: CobeMetalConfiguration,
        in size: CGSize
    ) -> CobeProjectedPoint {
        let direction = latLonTo3D(marker.location)
        let radius = globeRadius + configuration.markerElevation
        return project(
            point: direction * radius,
            configuration: configuration,
            in: size
        )
    }

    static func project(
        arc: CobeMetalArc,
        configuration: CobeMetalConfiguration,
        in size: CGSize
    ) -> CobeProjectedPoint? {
        let from = latLonTo3D(arc.from)
        let to = latLonTo3D(arc.to)
        let midpoint = from + to
        let length = simd_length(midpoint)
        guard length > 0.001 else { return nil }

        let scalar = 0.25 * (globeRadius + configuration.markerElevation)
            + (0.5 * (globeRadius + configuration.arcHeight + configuration.markerElevation)) / length
        return project(
            point: midpoint * scalar,
            configuration: configuration,
            in: size
        )
    }

    private static func project(
        point: SIMD3<Float>,
        configuration: CobeMetalConfiguration,
        in size: CGSize
    ) -> CobeProjectedPoint {
        let rotated = rotate(point, phi: configuration.phi, theta: configuration.theta)
        let width = max(Float(size.width), 1)
        let height = max(Float(size.height), 1)
        let aspect = width / height

        let x = ((rotated.x / aspect) * configuration.scale
            + configuration.offset.x * configuration.scale / width + 1) * 0.5
        let y = ((-rotated.y) * configuration.scale
            + configuration.offset.y * configuration.scale / height + 1) * 0.5
        let visible = rotated.z >= 0
            || rotated.x * rotated.x + rotated.y * rotated.y >= globeRadius * globeRadius

        return CobeProjectedPoint(
            normalizedPoint: CGPoint(x: CGFloat(x), y: CGFloat(y)),
            visible: visible
        )
    }
}

/// Native counterpart of COBE's `anchor.js` manager.
///
/// COBE updates marker and arc anchors from the same `project()` call that
/// receives the current rotation.  The native renderer keeps the same stable
/// id -> projection mapping, including the front/back visibility state, and
/// publishes one immutable snapshot for SwiftUI to consume.
struct CobeAnchorSnapshot: Equatable {
    let markers: [String: CobeProjectedPoint]
    let arcs: [String: CobeProjectedPoint]

    static let empty = CobeAnchorSnapshot(markers: [:], arcs: [:])
}

final class CobeMetalAnchorManager {
    private(set) var snapshot = CobeAnchorSnapshot.empty

    @discardableResult
    func update(
        configuration: CobeMetalConfiguration,
        in size: CGSize
    ) -> CobeAnchorSnapshot {
        var markerAnchors: [String: CobeProjectedPoint] = [:]
        markerAnchors.reserveCapacity(configuration.markers.count)

        for marker in configuration.markers {
            markerAnchors[marker.id] = CobeProjection.project(
                marker: marker,
                configuration: configuration,
                in: size
            )
        }

        var arcAnchors: [String: CobeProjectedPoint] = [:]
        arcAnchors.reserveCapacity(configuration.arcs.count)

        for arc in configuration.arcs {
            if let projection = CobeProjection.project(
                arc: arc,
                configuration: configuration,
                in: size
            ) {
                arcAnchors[arc.id] = projection
            }
        }

        snapshot = CobeAnchorSnapshot(markers: markerAnchors, arcs: arcAnchors)
        return snapshot
    }
}

struct CobeMetalFrame: Equatable {
    let configuration: CobeMetalConfiguration
    let anchors: CobeAnchorSnapshot
}

final class CobeMetalFrameStore: ObservableObject {
    @Published private(set) var frame: CobeMetalFrame?

    func publish(_ frame: CobeMetalFrame) {
        guard self.frame != frame else { return }
        self.frame = frame
    }
}

private struct CobeGlobeUniforms {
    var resolution: SIMD2<Float>
    var offset: SIMD2<Float>
    var rotation: SIMD2<Float>
    var dots: Float
    var scale: Float
    var baseColor: SIMD4<Float>
    var glowColor: SIMD4<Float>
    var renderParams: SIMD4<Float>
    var mapSettings: SIMD4<Float>
}

private struct CobeMarkerUniforms {
    var resolution: SIMD2<Float>
    var offset: SIMD2<Float>
    var rotation: SIMD2<Float>
    var scale: Float
    var markerElevation: Float
    var markerColor: SIMD4<Float>
}

private struct CobeArcUniforms {
    var resolution: SIMD2<Float>
    var offset: SIMD2<Float>
    var rotation: SIMD2<Float>
    var scale: Float
    var markerElevation: Float
    var arcColor: SIMD4<Float>
}

private struct CobeMarkerInstance {
    var positionAndSize: SIMD4<Float>
    var colorAndHasColor: SIMD4<Float>
}

private struct CobeArcInstance {
    var from: SIMD4<Float>
    var to: SIMD4<Float>
    var heightAndWidth: SIMD4<Float>
    var colorAndHasColor: SIMD4<Float>
}

final class CobeMetalRenderer: NSObject, MTKViewDelegate {
    private weak var metalView: MTKView?
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var globePipeline: MTLRenderPipelineState?
    private var markerPipeline: MTLRenderPipelineState?
    private var arcPipeline: MTLRenderPipelineState?
    private var mapTexture: MTLTexture?
    private var samplerState: MTLSamplerState?

    private var configuration = CobeMetalConfiguration()
    private var markerBuffer: MTLBuffer?
    private var arcBuffer: MTLBuffer?
    private var markerCount = 0
    private var arcCount = 0

    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue(),
              let library = device.makeDefaultLibrary()
        else {
            return nil
        }

        self.device = device
        self.commandQueue = commandQueue
        self.metalView = metalView
        super.init()

        metalView.device = device
        metalView.delegate = self
        metalView.isOpaque = false
        metalView.backgroundColor = .clear
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.framebufferOnly = true
        metalView.enableSetNeedsDisplay = false
        metalView.isPaused = false
        metalView.preferredFramesPerSecond = 60

        globePipeline = Self.makePipeline(
            device: device,
            library: library,
            vertexName: "cobeGlobeVertex",
            fragmentName: "cobeGlobeFragment"
        )
        markerPipeline = Self.makePipeline(
            device: device,
            library: library,
            vertexName: "cobeMarkerVertex",
            fragmentName: "cobeMarkerFragment"
        )
        arcPipeline = Self.makePipeline(
            device: device,
            library: library,
            vertexName: "cobeArcVertex",
            fragmentName: "cobeArcFragment"
        )

        guard globePipeline != nil, markerPipeline != nil, arcPipeline != nil else {
            return nil
        }

        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .nearest
        samplerDescriptor.magFilter = .nearest
        samplerDescriptor.sAddressMode = .repeat
        samplerDescriptor.tAddressMode = .repeat
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
        mapTexture = Self.loadMapTexture(device: device)
    }

    func update(_ newConfiguration: CobeMetalConfiguration) {
        let markersChanged = newConfiguration.markers != configuration.markers
        let arcsChanged = newConfiguration.arcs != configuration.arcs
            || newConfiguration.arcHeight != configuration.arcHeight
            || newConfiguration.arcWidth != configuration.arcWidth
            || newConfiguration.markerElevation != configuration.markerElevation
        configuration = newConfiguration

        if markersChanged {
            uploadMarkers(newConfiguration.markers)
        }
        if arcsChanged {
            uploadArcs(newConfiguration.arcs)
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // The drawable size is read on every frame so Retina and rotation changes
        // immediately use the same coordinate system as the SwiftUI overlay.
    }

    func draw(in view: MTKView) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let globePipeline,
              let mapTexture,
              let samplerState
        else {
            return
        }

        let drawableSize = view.drawableSize
        let resolution = SIMD2<Float>(
            max(Float(drawableSize.width), 1),
            max(Float(drawableSize.height), 1)
        )
        let pointScale = max(
            Float(drawableSize.width) / max(Float(view.bounds.width), 1),
            1
        )
        let pixelOffset = configuration.offset * pointScale

        encoder.setRenderPipelineState(globePipeline)
        var globeUniforms = CobeGlobeUniforms(
            resolution: resolution,
            offset: pixelOffset,
            rotation: SIMD2(configuration.phi, configuration.theta),
            dots: max(configuration.mapSamples, 2),
            scale: configuration.scale,
            baseColor: SIMD4(configuration.baseColor, 1),
            glowColor: SIMD4(configuration.glowColor, 1),
            renderParams: SIMD4(
                configuration.mapBrightness,
                configuration.diffuse,
                configuration.dark,
                configuration.opacity
            ),
            mapSettings: SIMD4(configuration.mapBaseBrightness, 0, 0, 0)
        )
        encoder.setFragmentBytes(
            &globeUniforms,
            length: MemoryLayout<CobeGlobeUniforms>.stride,
            index: 0
        )
        encoder.setFragmentTexture(mapTexture, index: 0)
        encoder.setFragmentSamplerState(samplerState, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)

        if arcCount > 0, let arcPipeline, let arcBuffer {
            encoder.setRenderPipelineState(arcPipeline)
            var arcUniforms = CobeArcUniforms(
                resolution: resolution,
                offset: pixelOffset,
                rotation: SIMD2(configuration.phi, configuration.theta),
                scale: configuration.scale,
                markerElevation: configuration.markerElevation,
                arcColor: SIMD4(configuration.arcColor, 1)
            )
            encoder.setVertexBytes(
                &arcUniforms,
                length: MemoryLayout<CobeArcUniforms>.stride,
                index: 0
            )
            encoder.setFragmentBytes(
                &arcUniforms,
                length: MemoryLayout<CobeArcUniforms>.stride,
                index: 0
            )
            encoder.setVertexBuffer(arcBuffer, offset: 0, index: 1)
            encoder.drawPrimitives(
                type: .triangleStrip,
                vertexStart: 0,
                vertexCount: 66,
                instanceCount: arcCount
            )
        }

        if markerCount > 0, let markerPipeline, let markerBuffer {
            encoder.setRenderPipelineState(markerPipeline)
            var markerUniforms = CobeMarkerUniforms(
                resolution: resolution,
                offset: pixelOffset,
                rotation: SIMD2(configuration.phi, configuration.theta),
                scale: configuration.scale,
                markerElevation: configuration.markerElevation,
                markerColor: SIMD4(configuration.markerColor, 1)
            )
            encoder.setVertexBytes(
                &markerUniforms,
                length: MemoryLayout<CobeMarkerUniforms>.stride,
                index: 0
            )
            encoder.setFragmentBytes(
                &markerUniforms,
                length: MemoryLayout<CobeMarkerUniforms>.stride,
                index: 0
            )
            encoder.setVertexBuffer(markerBuffer, offset: 0, index: 1)
            encoder.drawPrimitives(
                type: .triangle,
                vertexStart: 0,
                vertexCount: 6,
                instanceCount: markerCount
            )
        }

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    deinit {
        metalView?.delegate = nil
    }

    private func uploadMarkers(_ markers: [CobeMetalMarker]) {
        markerCount = markers.count
        guard !markers.isEmpty else {
            markerBuffer = nil
            return
        }

        let instances = markers.map { marker in
            let color = marker.color ?? SIMD3<Float>(0, 0, 0)
            return CobeMarkerInstance(
                positionAndSize: SIMD4(
                    CobeProjection.latLonTo3D(marker.location),
                    marker.size
                ),
                colorAndHasColor: SIMD4(color, marker.color == nil ? 0 : 1)
            )
        }
        markerBuffer = makeBuffer(from: instances)
    }

    private func uploadArcs(_ arcs: [CobeMetalArc]) {
        arcCount = arcs.count
        guard !arcs.isEmpty else {
            arcBuffer = nil
            return
        }

        let instances = arcs.map { arc in
            let color = arc.color ?? SIMD3<Float>(0, 0, 0)
            return CobeArcInstance(
                from: SIMD4(CobeProjection.latLonTo3D(arc.from), 0),
                to: SIMD4(CobeProjection.latLonTo3D(arc.to), 0),
                heightAndWidth: SIMD4(
                    configuration.arcHeight + configuration.markerElevation,
                    configuration.arcWidth * 0.005,
                    0,
                    0
                ),
                colorAndHasColor: SIMD4(color, arc.color == nil ? 0 : 1)
            )
        }
        arcBuffer = makeBuffer(from: instances)
    }

    private func makeBuffer<T>(from values: [T]) -> MTLBuffer? {
        values.withUnsafeBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else { return nil }
            return device.makeBuffer(
                bytes: baseAddress,
                length: rawBuffer.count,
                options: .storageModeShared
            )
        }
    }

    private static func makePipeline(
        device: MTLDevice,
        library: MTLLibrary,
        vertexName: String,
        fragmentName: String
    ) -> MTLRenderPipelineState? {
        guard let vertexFunction = library.makeFunction(name: vertexName),
              let fragmentFunction = library.makeFunction(name: fragmentName)
        else {
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.colorAttachments[0].isBlendingEnabled = true
        descriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        descriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha

        return try? device.makeRenderPipelineState(descriptor: descriptor)
    }

    private static func loadMapTexture(device: MTLDevice) -> MTLTexture? {
        guard let url = Bundle.main.url(forResource: "cobe-map", withExtension: "png") else {
            return nil
        }

        let loader = MTKTextureLoader(device: device)
        let options: [MTKTextureLoader.Option: Any] = [
            .SRGB: false,
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            // cobe-map.png is a conventional equirectangular map whose first
            // row is the northern hemisphere. The COBE UV formula samples
            // that row as the top of the texture, so do not flip it on load.
            .origin: MTKTextureLoader.Origin.topLeft
        ]
        return try? loader.newTexture(URL: url, options: options)
    }
}
