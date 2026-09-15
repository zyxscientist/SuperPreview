//
//  CobeMetalView.swift
//  SuperPreview
//

import MetalKit
import SwiftUI

struct CobeMetalView: UIViewRepresentable {
    let configuration: CobeMetalConfiguration
    let frameStore: CobeMetalFrameStore
    let configurationProvider: (Date, CGSize) -> CobeMetalConfiguration

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero)
        view.accessibilityIdentifier = "cobe.metal.canvas"
        context.coordinator.metalView = view
        context.coordinator.frameStore = frameStore
        context.coordinator.configurationProvider = configurationProvider

        if let renderer = CobeMetalRenderer(metalView: view) {
            context.coordinator.renderer = renderer
            // COBE updates anchors and draws from one animation update. The
            // native view uses one CADisplayLink as that shared frame clock.
            view.enableSetNeedsDisplay = true
            view.isPaused = true
            context.coordinator.render(configuration: configuration, in: view.bounds.size)
            context.coordinator.startDisplayLink()
        }

        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.frameStore = frameStore
        context.coordinator.configurationProvider = configurationProvider
    }

    static func dismantleUIView(_ view: MTKView, coordinator: Coordinator) {
        coordinator.stopDisplayLink()
        coordinator.renderer = nil
    }

    final class Coordinator: NSObject {
        weak var metalView: MTKView?
        var renderer: CobeMetalRenderer?
        var frameStore: CobeMetalFrameStore?
        var configurationProvider: ((Date, CGSize) -> CobeMetalConfiguration)?

        private let anchorManager = CobeMetalAnchorManager()
        private var displayLink: CADisplayLink?

        func startDisplayLink() {
            guard displayLink == nil else { return }

            let displayLink = CADisplayLink(
                target: self,
                selector: #selector(displayLinkDidFire(_:))
            )
            displayLink.add(to: .main, forMode: .common)
            self.displayLink = displayLink
        }

        func stopDisplayLink() {
            displayLink?.invalidate()
            displayLink = nil
        }

        func render(configuration: CobeMetalConfiguration, in size: CGSize) {
            let anchors = anchorManager.update(
                configuration: configuration,
                in: size
            )
            let frame = CobeMetalFrame(
                configuration: configuration,
                anchors: anchors
            )

            renderer?.update(configuration)
            frameStore?.publish(frame)
            metalView?.draw()
        }

        @objc private func displayLinkDidFire(_ displayLink: CADisplayLink) {
            guard let metalView,
                  let configurationProvider
            else {
                return
            }

            let configuration = configurationProvider(
                Date(),
                metalView.bounds.size
            )
            render(configuration: configuration, in: metalView.bounds.size)
        }

        deinit {
            stopDisplayLink()
        }
    }
}
