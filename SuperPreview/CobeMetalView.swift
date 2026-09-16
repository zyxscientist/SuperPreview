//
//  CobeMetalView.swift
//  SuperPreview
//

import MetalKit
import SwiftUI
import UIKit

struct CobeMetalView: UIViewRepresentable {
    let configuration: CobeMetalConfiguration
    let frameStore: CobeMetalFrameStore
    let configurationProvider: (Date, CGSize) -> CobeMetalConfiguration
    let isActive: Bool

    init(
        configuration: CobeMetalConfiguration,
        frameStore: CobeMetalFrameStore,
        configurationProvider: @escaping (Date, CGSize) -> CobeMetalConfiguration,
        isActive: Bool = true
    ) {
        self.configuration = configuration
        self.frameStore = frameStore
        self.configurationProvider = configurationProvider
        self.isActive = isActive
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero)
        view.accessibilityIdentifier = "cobe.metal.canvas"
        context.coordinator.metalView = view
        context.coordinator.frameStore = frameStore
        context.coordinator.configurationProvider = configurationProvider
        context.coordinator.isActive = isActive

        if let renderer = CobeMetalRenderer(metalView: view) {
            context.coordinator.renderer = renderer
            // COBE updates anchors and draws from one animation update. The
            // native view uses one CADisplayLink as that shared frame clock.
            view.enableSetNeedsDisplay = true
            view.isPaused = true
            if isActive {
                context.coordinator.render(configuration: configuration, in: view.bounds.size)
                context.coordinator.startDisplayLink()
            }
        }

        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        let wasActive = context.coordinator.isActive
        context.coordinator.frameStore = frameStore
        context.coordinator.configurationProvider = configurationProvider
        context.coordinator.isActive = isActive

        if isActive {
            if !wasActive {
                context.coordinator.render(configuration: configuration, in: view.bounds.size)
            }
            context.coordinator.startDisplayLink()
        } else {
            context.coordinator.stopDisplayLink()
        }
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
        var isActive = true

        private let anchorManager = CobeMetalAnchorManager()
        private var displayLink: CADisplayLink?

        func startDisplayLink() {
            guard displayLink == nil else { return }

            let displayLink = CADisplayLink(
                target: self,
                selector: #selector(displayLinkDidFire(_:))
            )
            let availableFramesPerSecond = max(UIScreen.main.maximumFramesPerSecond, 60)
            let preferredFramesPerSecond = min(
                CobeMetalFrameRate.preferredFramesPerSecond,
                availableFramesPerSecond
            )
            displayLink.preferredFramesPerSecond = preferredFramesPerSecond
            if #available(iOS 15.0, *) {
                let preferredRate = Float(preferredFramesPerSecond)
                displayLink.preferredFrameRateRange = CAFrameRateRange(
                    minimum: preferredRate,
                    maximum: preferredRate,
                    preferred: preferredRate
                )
            }
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
            guard isActive,
                  let metalView,
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
