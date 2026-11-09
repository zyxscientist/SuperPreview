import SwiftUI
import UIKit

/// Presents one toast at a time above the app's navigation and sheets.
@MainActor
final class ToastPresenter: NSObject {
    private enum Phase {
        case hidden, entering, visible, exiting
    }

    private struct Request {
        let message: String
        let repeats: Bool
    }

    private weak var scene: UIWindowScene?
    private var overlay: ToastWindow?
    private var request: Request?
    private var phase: Phase = .hidden
    private var isSceneActive = false
    private var touchStartY: CGFloat?
    // Only one wait can be pending: the visible timeout or the gap between demos.
    private var scheduledTask: Task<Void, Never>?

    init(scene: UIWindowScene) {
        self.scene = scene
    }

    func show(_ message: String, repeats: Bool = false) {
        resetOverlay()
        request = Request(message: message, repeats: repeats)
        presentIfPossible()
    }

    func dismiss() {
        request = nil
        cancelWait()
        if phase == .hidden {
            resetOverlay()
        } else {
            dismissCurrent()
        }
    }

    func setSceneActive(_ isActive: Bool) {
        guard isSceneActive != isActive else { return }
        isSceneActive = isActive
        if isActive {
            presentIfPossible()
        } else {
            resetOverlay()
        }
    }

    private func presentIfPossible() {
        guard isSceneActive, phase == .hidden, let scene, let request else { return }
        let window = overlay ?? makeOverlay(in: scene, message: request.message)
        guard let card = window.card else { return }
        overlay = window
        if !request.repeats { self.request = nil }

        phase = .entering
        card.alpha = 0
        window.isHidden = false
        window.layoutIfNeeded()
        window.rootViewController?.view.layoutIfNeeded()
        card.transform = UIAccessibility.isReduceMotionEnabled ? .identity : offscreenTransform(in: window)
        card.alpha = 1

        let didEnter = { [weak self, weak window] in
            guard let self, let window, self.overlay === window, self.phase == .entering else { return }
            self.phase = .visible
            window.card?.isUserInteractionEnabled = true
            window.card?.accessibilityElementsHidden = false
            self.scheduleDismissal()
        }

        if UIAccessibility.isReduceMotionEnabled {
            didEnter()
        } else {
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                usingSpringWithDamping: 0.67,
                initialSpringVelocity: 0,
                options: [.beginFromCurrentState, .allowUserInteraction],
                animations: { card.transform = .identity },
                completion: { _ in didEnter() }
            )
        }
    }

    private func dismissCurrent() {
        guard phase == .entering || phase == .visible, let window = overlay, let card = window.card else { return }
        cancelWait()
        phase = .exiting
        touchStartY = nil
        card.isUserInteractionEnabled = false
        card.accessibilityElementsHidden = true

        let didExit = { [weak self, weak window] in
            guard let self, let window, self.overlay === window, self.phase == .exiting else { return }
            window.isHidden = true
            self.phase = .hidden
            if self.request?.repeats == true {
                self.schedule(after: .seconds(1)) { $0.presentIfPossible() }
            } else {
                self.resetOverlay()
            }
        }

        if UIAccessibility.isReduceMotionEnabled {
            didExit()
        } else {
            let transform = offscreenTransform(in: window)
            UIView.animate(
                withDuration: 0.22,
                delay: 0,
                options: [.curveLinear, .beginFromCurrentState, .allowUserInteraction],
                animations: { card.transform = transform },
                completion: { _ in didExit() }
            )
        }
    }

    private func makeOverlay(in scene: UIWindowScene, message: String) -> ToastWindow {
        let window = ToastWindow(windowScene: scene)
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue + 1)
        window.backgroundColor = .clear

        let container = UIViewController()
        container.view.backgroundColor = .clear
        window.rootViewController = container

        let host = UIHostingController(rootView: ToastView(message: message)
            .accessibilityAction(.escape) { [weak self] in self?.dismissCurrent() })
        host.safeAreaRegions = []
        host.sizingOptions = .intrinsicContentSize
        container.addChild(host)

        let card = host.view!
        card.backgroundColor = .clear
        card.translatesAutoresizingMaskIntoConstraints = false
        card.isUserInteractionEnabled = false
        card.accessibilityElementsHidden = true
        container.view.addSubview(card)
        host.didMove(toParent: container)

        let safeArea = container.view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: safeArea.topAnchor),
            card.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
            card.leadingAnchor.constraint(greaterThanOrEqualTo: safeArea.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(lessThanOrEqualTo: safeArea.trailingAnchor, constant: -16)
        ])

        let press = UILongPressGestureRecognizer(target: self, action: #selector(trackTouch(_:)))
        press.minimumPressDuration = 0
        press.allowableMovement = .greatestFiniteMagnitude
        card.addGestureRecognizer(press)
        window.card = card
        return window
    }

    @objc private func trackTouch(_ press: UILongPressGestureRecognizer) {
        guard phase == .visible, let window = overlay, let card = window.card else { return }
        // Window coordinates stay fixed even as the card moves with the finger.
        let y = press.location(in: window).y
        switch press.state {
        case .began:
            touchStartY = y
            cancelWait()
        case .changed:
            guard let touchStartY, !UIAccessibility.isReduceMotionEnabled else { return }
            card.transform = CGAffineTransform(translationX: 0, y: min(0, y - touchStartY))
        case .ended, .cancelled, .failed:
            guard let startY = touchStartY else { return }
            touchStartY = nil
            if press.state == .ended, y - startY <= -24 {
                dismissCurrent()
            } else {
                UIView.animate(
                    withDuration: 0.18,
                    delay: 0,
                    options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
                    animations: { card.transform = .identity }
                )
                scheduleDismissal()
            }
        default:
            break
        }
    }

    private func offscreenTransform(in window: ToastWindow) -> CGAffineTransform {
        let height = window.card?.bounds.height ?? 0
        let topInset = window.rootViewController?.view.safeAreaInsets.top ?? 0
        return CGAffineTransform(translationX: 0, y: -(topInset + height))
    }

    private func scheduleDismissal() {
        schedule(after: .seconds(3)) { $0.dismissCurrent() }
    }

    private func schedule(after delay: Duration, action: @escaping (ToastPresenter) -> Void) {
        cancelWait()
        scheduledTask = Task { [weak self] in
            do {
                try await Task.sleep(for: delay)
            } catch {
                return
            }
            guard let self, !Task.isCancelled else { return }
            self.scheduledTask = nil
            action(self)
        }
    }

    private func cancelWait() {
        scheduledTask?.cancel()
        scheduledTask = nil
    }

    private func resetOverlay() {
        cancelWait()
        phase = .hidden
        touchStartY = nil
        overlay?.isHidden = true
        overlay = nil
    }
}

private final class ToastWindow: UIWindow {
    weak var card: UIView?

    override var canBecomeKey: Bool { false }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let card, card.isUserInteractionEnabled else { return nil }
        return card.hitTest(card.convert(point, from: self), with: event)
    }
}
