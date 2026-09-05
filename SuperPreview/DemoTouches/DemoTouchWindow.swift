import UIKit
import Combine

#if DEBUG || DEMO_TOUCHES
/// Observes the app window's touches without joining gesture recognition.
final class DemoTouchWindow: UIWindow {
    private var overlayWindow: DemoTouchOverlayWindow?
    private var indicators: [ObjectIdentifier: UIView] = [:]
    private var settingsSubscription: AnyCancellable?

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        settingsSubscription = DemoTouchSettings.shared.$isEnabled.sink { [weak self] enabled in
            if !enabled {
                self?.clearTouchIndicators()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("Create DemoTouchWindow with a UIWindowScene")
    }

    override func sendEvent(_ event: UIEvent) {
        // Forward exactly once, including events received while visualization is off.
        defer { super.sendEvent(event) }
        guard DemoTouchSettings.isAvailable,
              DemoTouchSettings.shared.isEnabled,
              let scene = windowScene,
              scene.activationState == .foregroundActive,
              event.type == .touches,
              let touches = event.touches(for: self) else { return }

        for touch in touches where touch.type == .direct {
            let identifier = ObjectIdentifier(touch)
            switch touch.phase {
            case .began, .moved, .stationary:
                let canvas = touchCanvas(in: scene)
                let indicator: UIView
                if let existing = indicators[identifier] {
                    indicator = existing
                } else {
                    indicator = makeIndicator()
                    indicators[identifier] = indicator
                    canvas.addSubview(indicator)
                }
                // Keep only copied coordinates and an identifier, never retain UITouch.
                indicator.center = touch.location(in: canvas)
            case .ended, .cancelled:
                guard let indicator = indicators.removeValue(forKey: identifier) else { continue }
                UIView.animate(withDuration: 0.3, animations: {
                    indicator.alpha = 0
                    if !UIAccessibility.isReduceMotionEnabled {
                        indicator.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                    }
                }, completion: { _ in
                    indicator.removeFromSuperview()
                })
            default:
                break
            }
        }
    }

    func clearTouchIndicators() {
        indicators.removeAll()
        overlayWindow?.rootViewController?.view.subviews.forEach {
            $0.layer.removeAllAnimations()
            $0.removeFromSuperview()
        }
        overlayWindow?.isHidden = true
        overlayWindow = nil
    }

    private func touchCanvas(in scene: UIWindowScene) -> UIView {
        if let controller = overlayWindow?.rootViewController {
            return controller.view
        }

        // A separate non-key window stays above sheets and fullScreenCover content.
        let overlay = DemoTouchOverlayWindow(windowScene: scene)
        overlay.frame = bounds
        overlay.backgroundColor = .clear
        overlay.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.alert.rawValue + 1)
        overlay.isUserInteractionEnabled = false
        overlay.accessibilityElementsHidden = true
        let controller = DemoTouchOverlayController()
        controller.view.backgroundColor = .clear
        controller.view.isUserInteractionEnabled = false
        controller.view.accessibilityElementsHidden = true
        overlay.rootViewController = controller
        overlay.isHidden = false
        overlayWindow = overlay
        return controller.view
    }

    private func makeIndicator() -> UIView {
        let indicator = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 48))
        indicator.backgroundColor = UIColor.white.withAlphaComponent(0.28)
        indicator.layer.cornerRadius = 24
        indicator.layer.borderWidth = 2.5
        indicator.layer.borderColor = UIColor.systemBlue.cgColor
        indicator.layer.shadowColor = UIColor.black.cgColor
        indicator.layer.shadowOpacity = 0.55
        indicator.layer.shadowRadius = 1.5
        indicator.layer.shadowOffset = .zero
        indicator.layer.shadowPath = UIBezierPath(ovalIn: indicator.bounds).cgPath
        indicator.isUserInteractionEnabled = false
        indicator.accessibilityElementsHidden = true
        return indicator
    }
}

private final class DemoTouchOverlayWindow: UIWindow {
    override var canBecomeKey: Bool { false }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }
}

private final class DemoTouchOverlayController: UIViewController {
    override var shouldAutorotate: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
}
#endif
