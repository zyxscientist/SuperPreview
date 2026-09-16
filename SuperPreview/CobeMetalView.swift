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
        MarketLifecycleDiagnostics.shared.install()
        MarketLifecycleDiagnostics.shared.event("metal-view-created")
        view.accessibilityIdentifier = "cobe.metal.canvas"
        context.coordinator.metalView = view
        context.coordinator.frameStore = frameStore
        context.coordinator.configurationProvider = configurationProvider
        context.coordinator.isActive = isActive
        context.coordinator.startObservingApplicationLifecycle()

        if let renderer = CobeMetalRenderer(metalView: view) {
            context.coordinator.renderer = renderer
            // COBE updates anchors and draws from one animation update. The
            // native view uses one CADisplayLink as that shared frame clock.
            view.enableSetNeedsDisplay = true
            view.isPaused = true
            if context.coordinator.canRender {
                context.coordinator.render(configuration: configuration, in: view.bounds.size)
                context.coordinator.startDisplayLink()
            }
        }

        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        let wasRenderingAllowed = context.coordinator.canRender
        context.coordinator.frameStore = frameStore
        context.coordinator.configurationProvider = configurationProvider
        context.coordinator.isActive = isActive

        if context.coordinator.canRender {
            if !wasRenderingAllowed {
                context.coordinator.render(configuration: configuration, in: view.bounds.size)
            }
            context.coordinator.startDisplayLink()
        } else {
            context.coordinator.stopDisplayLink()
        }
    }

    static func dismantleUIView(_ view: MTKView, coordinator: Coordinator) {
        MarketLifecycleDiagnostics.shared.event("metal-view-dismantled")
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
        private var isSceneActive = UIApplication.shared.applicationState == .active
        private var isObservingApplicationLifecycle = false

        var canRender: Bool {
            isActive
                && isSceneActive
                && UIApplication.shared.applicationState == .active
        }

        func startObservingApplicationLifecycle() {
            guard !isObservingApplicationLifecycle else { return }

            let notificationCenter = NotificationCenter.default
            notificationCenter.addObserver(
                self,
                selector: #selector(applicationWillResignActive(_:)),
                name: UIApplication.willResignActiveNotification,
                object: nil
            )
            notificationCenter.addObserver(
                self,
                selector: #selector(applicationDidEnterBackground(_:)),
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
            notificationCenter.addObserver(
                self,
                selector: #selector(applicationDidBecomeActive(_:)),
                name: UIApplication.didBecomeActiveNotification,
                object: nil
            )
            isObservingApplicationLifecycle = true
        }

        func startDisplayLink() {
            guard displayLink == nil, canRender else { return }
            MarketLifecycleDiagnostics.shared.event("display-link-start")

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
            if displayLink != nil { MarketLifecycleDiagnostics.shared.event("display-link-stop") }
            displayLink?.invalidate()
            displayLink = nil
        }

        func render(configuration: CobeMetalConfiguration, in size: CGSize, sampleStart: TimeInterval? = nil) {
            guard canRender else { return }

            let anchors = anchorManager.update(
                configuration: configuration,
                in: size
            )
            let frame = CobeMetalFrame(
                configuration: configuration,
                anchors: anchors
            )
            MarketLifecycleDiagnostics.shared.stage("frame-anchors-ready", since: sampleStart)

            renderer?.update(configuration)
            MarketLifecycleDiagnostics.shared.stage("frame-resources-ready", since: sampleStart)
            frameStore?.publish(frame)
            MarketLifecycleDiagnostics.shared.stage("frame-published", since: sampleStart)
            metalView?.draw()
            MarketLifecycleDiagnostics.shared.stage("frame-draw-returned", since: sampleStart)
        }

        @objc private func displayLinkDidFire(_ displayLink: CADisplayLink) {
            guard canRender,
                  let metalView,
                  let configurationProvider
            else {
                return
            }

            let sampleStart = MarketLifecycleDiagnostics.shared.beginFrameSample()
            let configuration = configurationProvider(
                Date(),
                metalView.bounds.size
            )
            MarketLifecycleDiagnostics.shared.stage("frame-configuration-ready", since: sampleStart)
            render(configuration: configuration, in: metalView.bounds.size, sampleStart: sampleStart)
        }

        @objc private func applicationWillResignActive(_ notification: Notification) {
            pauseRenderingForInactiveApplication()
        }

        @objc private func applicationDidEnterBackground(_ notification: Notification) {
            // Keep this as a backstop in case the scene is backgrounded without
            // a display-link turn occurring between the two lifecycle events.
            pauseRenderingForInactiveApplication()
        }

        @objc private func applicationDidBecomeActive(_ notification: Notification) {
            isSceneActive = true
            guard isActive else { return }
            startDisplayLink()
        }

        private func pauseRenderingForInactiveApplication() {
            isSceneActive = false
            stopDisplayLink()
            // CobeMetalView uses explicit draw() calls from the display link.
            // Keep MTKView paused as an additional guard during lifecycle
            // transitions and while the app is suspended.
            metalView?.isPaused = true
        }

        deinit {
            stopDisplayLink()
            NotificationCenter.default.removeObserver(self)
        }
    }
}
