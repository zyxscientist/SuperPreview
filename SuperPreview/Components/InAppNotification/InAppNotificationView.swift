//
//  InAppNotificationView.swift
//  SuperPreview
//
//  Created by admin on 2025/1/7.
//  Copyright © 2025 PeterZ. All rights reserved.
//

import SwiftUI
import UIKit

struct InAppNotificationView: View {
    @State private var isSimulationEnabled = false
    @State private var isMultipleMessageSimulationEnabled = false

    var body: some View {
        ZStack {
            Color("color-base-1")
                .ignoresSafeArea()

            Image("fake_page_bg")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()

            VStack(spacing: 12) {
                Toggle(isOn: $isSimulationEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("模拟成交站内信")
                            .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                            .foregroundColor(Color("color-text-30"))

                        Text("每次显示 5 秒，退场 1 秒后再次推送")
                            .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                            .foregroundColor(Color("color-text-60"))
                    }
                }
                .padding(16)
                .background(Color("color-base-1"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Toggle(isOn: $isMultipleMessageSimulationEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("模拟多条成交站内信")
                            .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                            .foregroundColor(Color("color-text-30"))

                        Text(
                            isMultipleMessageSimulationEnabled
                                ? "每 2 秒推入一条新信息，当前通知将原地淡出"
                                : "开启后模拟当前通知被新的成交信息打断"
                        )
                        .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 16))
                        .foregroundColor(Color("color-text-60"))
                    }
                }
                .disabled(!isSimulationEnabled)
                .padding(16)
                .background(Color("color-base-1"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 20)
        }
        .inAppNotificationSimulation(
            isEnabled: isSimulationEnabled,
            isMultipleMessages: isMultipleMessageSimulationEnabled
        )
        .navigationBarTitle("站内通知", displayMode: .inline)
    }
}

struct InAppNotificationBannerView: View {
    static let defaultMessage = "【成交提醒】 您以9.950港币每股的价格成功买入云锋金融（00376.HK）300股，此笔订单已全部成交，2026/07/28 10:10:41（香港）"
    static let multipleMessages = [
        defaultMessage,
        "【成交提醒】 您以62.400港币每股的价格成功卖出比亚迪电子（00285.HK）200股，此笔订单已全部成交，2026/07/28 10:10:43（香港）",
        "【成交提醒】 您以184.600港币每股的价格成功买入腾讯控股（00700.HK）100股，此笔订单已全部成交，2026/07/28 10:10:45（香港）"
    ]

    @Environment(\.colorScheme) private var colorScheme
    let message: String

    init(message: String = Self.defaultMessage) {
        self.message = message
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image("inapp_transaction_message")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .accessibilityHidden(true)

                    Image("inapp_trade_label")
                        .resizable()
                        .frame(width: 56, height: 14)
                        .frame(width: 66, height: 16, alignment: .leading)
                        .accessibilityHidden(true)
                }

                Spacer(minLength: 8)

                Image("inapp_chevron_right")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
            }
            .frame(height: 20)

            Text(message)
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                .foregroundColor(Color("color-text-30"))
                .lineLimit(2)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40, alignment: .topLeading)
                .clipped()
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 90, maxHeight: 90, alignment: .topLeading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(
            color: Color.black.opacity(colorScheme == .dark ? 0.6 : 0.06),
            radius: 4,
            x: 0,
            y: 4
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
        .accessibilityIdentifier("inAppNotification.tradeBanner")
    }

    private var background: some View {
        ZStack {
            Color("color-base-1")

            LinearGradient(
                colors: [
                    Color(red: 254 / 255, green: 74 / 255, blue: 74 / 255)
                        .opacity(colorScheme == .dark ? 0.06 : 0.03),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private struct InAppNotificationSimulationModifier: ViewModifier {
    let isEnabled: Bool
    let isMultipleMessages: Bool

    func body(content: Content) -> some View {
        content
            .background(
                InAppNotificationWindowPresenter(
                    isEnabled: isEnabled,
                    isMultipleMessages: isMultipleMessages
                )
                    .allowsHitTesting(false)
            )
    }
}

private enum InAppNotificationTiming {
    static let animationDuration: TimeInterval = 0.2
    static let displayDuration: TimeInterval = 5
    static let repeatDelay: TimeInterval = 1
    static let multipleMessageInterval: TimeInterval = 2
    static let replacementExitDuration: TimeInterval = 0.1
}

private enum InAppNotificationLayout {
    static let horizontalInset: CGFloat = 10
    static let height: CGFloat = 90
    static let shadowOverflow: CGFloat = 8
    static let dismissDistance: CGFloat = 36
    static let dismissVelocity: CGFloat = 700
}

/// Presents the banner at the window root so it sits above app navigation chrome,
/// while the system status bar remains in front of it.
private struct InAppNotificationWindowPresenter: UIViewRepresentable {
    let isEnabled: Bool
    let isMultipleMessages: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WindowAttachmentView {
        let view = WindowAttachmentView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.windowDidChange = { [weak coordinator = context.coordinator] window in
            coordinator?.move(to: window)
        }
        return view
    }

    func updateUIView(_ uiView: WindowAttachmentView, context: Context) {
        context.coordinator.update(
            isEnabled: isEnabled,
            isMultipleMessages: isMultipleMessages,
            in: uiView.window
        )
    }

    static func dismantleUIView(
        _ uiView: WindowAttachmentView,
        coordinator: Coordinator
    ) {
        uiView.windowDidChange = nil
        coordinator.stop()
    }

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var presentationWindow: UIWindow?
        private var hostedView: UIView?
        private var panGestureRecognizer: UIPanGestureRecognizer?
        private var touchGestureRecognizer: UILongPressGestureRecognizer?
        private var scheduledTask: Task<Void, Never>?
        private var scheduleGeneration = 0
        private var isSimulationEnabled = false
        private var isMultipleMessages = false
        private var isTrackingTouch = false
        private var messageIndex = 0
        private var shouldPresentAfterExit = false
        private var state: PresentationState = .hidden

        func update(
            isEnabled: Bool,
            isMultipleMessages: Bool,
            in window: UIWindow?
        ) {
            move(to: window)

            let modeChanged = self.isMultipleMessages != isMultipleMessages
            guard isSimulationEnabled != isEnabled || modeChanged else { return }
            isSimulationEnabled = isEnabled
            self.isMultipleMessages = isMultipleMessages
            messageIndex = modeChanged && isMultipleMessages && state != .hidden ? 1 : 0
            cancelScheduledAction()

            if isEnabled {
                if state == .hidden {
                    presentNextNotification()
                } else if state == .exiting {
                    shouldPresentAfterExit = true
                } else {
                    replaceWithNextNotification()
                }
            } else {
                shouldPresentAfterExit = false
                dismissNotification(
                    scheduleNext: false,
                    animated: true,
                    isReplacement: false
                )
            }
        }

        func move(to window: UIWindow?) {
            guard let window else {
                cancelScheduledAction()
                removeHostedView()
                presentationWindow = nil
                shouldPresentAfterExit = false
                state = .hidden
                return
            }

            guard presentationWindow !== window else { return }

            cancelScheduledAction()
            removeHostedView()
            presentationWindow = window

            if isSimulationEnabled {
                presentNextNotification()
            }
        }

        func stop() {
            isSimulationEnabled = false
            isMultipleMessages = false
            isTrackingTouch = false
            messageIndex = 0
            shouldPresentAfterExit = false
            cancelScheduledAction()
            hostedView?.layer.removeAllAnimations()
            removeHostedView()
            presentationWindow = nil
            state = .hidden
        }

        private func attachIfNeeded(
            to window: UIWindow?,
            message: String
        ) {
            guard let window, hostedView == nil else { return }

            let configuration = UIHostingConfiguration {
                InAppNotificationBannerView(message: message)
            }
            .margins(.all, 0)
            let hostedView = configuration.makeContentView()
            hostedView.translatesAutoresizingMaskIntoConstraints = false
            hostedView.backgroundColor = .clear
            hostedView.isUserInteractionEnabled = true
            hostedView.accessibilityElementsHidden = true
            hostedView.isHidden = true

            let panGestureRecognizer = UIPanGestureRecognizer(
                target: self,
                action: #selector(handlePan(_:))
            )
            panGestureRecognizer.delegate = self
            panGestureRecognizer.maximumNumberOfTouches = 1
            hostedView.addGestureRecognizer(panGestureRecognizer)

            let touchGestureRecognizer = UILongPressGestureRecognizer(
                target: self,
                action: #selector(handleTouch(_:))
            )
            touchGestureRecognizer.delegate = self
            touchGestureRecognizer.minimumPressDuration = 0
            touchGestureRecognizer.allowableMovement = .greatestFiniteMagnitude
            touchGestureRecognizer.cancelsTouchesInView = false
            hostedView.addGestureRecognizer(touchGestureRecognizer)

            window.addSubview(hostedView)
            NSLayoutConstraint.activate([
                hostedView.topAnchor.constraint(
                    equalTo: window.safeAreaLayoutGuide.topAnchor
                ),
                hostedView.leadingAnchor.constraint(
                    equalTo: window.leadingAnchor,
                    constant: InAppNotificationLayout.horizontalInset
                ),
                hostedView.trailingAnchor.constraint(
                    equalTo: window.trailingAnchor,
                    constant: -InAppNotificationLayout.horizontalInset
                ),
                hostedView.heightAnchor.constraint(
                    equalToConstant: InAppNotificationLayout.height
                )
            ])

            self.hostedView = hostedView
            self.panGestureRecognizer = panGestureRecognizer
            self.touchGestureRecognizer = touchGestureRecognizer

            window.layoutIfNeeded()
            hostedView.transform = hiddenTransform(in: window)
        }

        private func presentNextNotification() {
            guard isSimulationEnabled,
                  state == .hidden,
                  let window = presentationWindow else {
                return
            }

            shouldPresentAfterExit = false
            attachIfNeeded(to: window, message: nextMessage())
            guard let hostedView else { return }

            window.bringSubviewToFront(hostedView)
            hostedView.layer.removeAllAnimations()
            hostedView.isHidden = false
            hostedView.accessibilityElementsHidden = false
            hostedView.alpha = 1
            window.layoutIfNeeded()
            hostedView.transform = hiddenTransform(in: window)
            state = .entering

            UIView.animate(
                withDuration: InAppNotificationTiming.animationDuration,
                delay: 0,
                options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
                animations: {
                    hostedView.transform = .identity
                }
            ) { [weak self, weak hostedView] _ in
                guard let self,
                      let hostedView,
                      self.hostedView === hostedView,
                      self.isSimulationEnabled,
                      self.state == .entering else {
                    return
                }

                self.state = .visible
                self.scheduleCurrentNotificationTransition()
            }
        }

        private func dismissNotification(
            scheduleNext: Bool,
            animated: Bool,
            isReplacement: Bool
        ) {
            guard let hostedView,
                  let window = presentationWindow else {
                state = .hidden
                if scheduleNext, isSimulationEnabled {
                    scheduleNextNotification()
                }
                return
            }

            cancelScheduledAction()
            isTrackingTouch = false
            state = .exiting
            hostedView.layer.removeAllAnimations()

            let animations = {
                if isReplacement {
                    hostedView.alpha = 0
                } else {
                    hostedView.transform = self.hiddenTransform(in: window)
                }
            }

            guard animated else {
                UIView.performWithoutAnimation(animations)
                removeHostedView()
                state = .hidden
                if scheduleNext, isSimulationEnabled {
                    scheduleNextNotification()
                }
                return
            }

            UIView.animate(
                withDuration: isReplacement
                    ? InAppNotificationTiming.replacementExitDuration
                    : InAppNotificationTiming.animationDuration,
                delay: 0,
                options: [.curveEaseIn, .beginFromCurrentState, .allowUserInteraction],
                animations: animations
            ) { [weak self, weak hostedView] _ in
                guard let self,
                      let hostedView,
                      self.hostedView === hostedView,
                      self.state == .exiting else {
                    return
                }

                self.removeHostedView()
                self.state = .hidden
                if self.shouldPresentAfterExit, self.isSimulationEnabled {
                    self.shouldPresentAfterExit = false
                    self.presentNextNotification()
                } else if isReplacement, self.isSimulationEnabled {
                    self.presentNextNotification()
                } else if scheduleNext, self.isSimulationEnabled {
                    self.scheduleNextNotification()
                }
            }
        }

        private func replaceWithNextNotification() {
            guard state == .visible else { return }

            dismissNotification(
                scheduleNext: false,
                animated: true,
                isReplacement: true
            )
        }

        private func scheduleCurrentNotificationTransition() {
            if isMultipleMessages {
                schedule(after: InAppNotificationTiming.multipleMessageInterval) {
                    [weak self] in
                    self?.replaceWithNextNotification()
                }
            } else {
                scheduleAutoDismiss()
            }
        }

        private func scheduleAutoDismiss() {
            schedule(after: InAppNotificationTiming.displayDuration) { [weak self] in
                self?.dismissNotification(
                    scheduleNext: true,
                    animated: true,
                    isReplacement: false
                )
            }
        }

        private func scheduleNextNotification() {
            schedule(after: InAppNotificationTiming.repeatDelay) { [weak self] in
                self?.presentNextNotification()
            }
        }

        private func schedule(
            after duration: TimeInterval,
            action: @escaping @MainActor () -> Void
        ) {
            cancelScheduledAction()
            let generation = scheduleGeneration

            scheduledTask = Task { @MainActor [weak self] in
                do {
                    try await Task.sleep(
                        nanoseconds: UInt64(duration * 1_000_000_000)
                    )
                } catch {
                    return
                }

                guard let self,
                      self.scheduleGeneration == generation else {
                    return
                }

                self.scheduledTask = nil
                action()
            }
        }

        private func cancelScheduledAction() {
            scheduledTask?.cancel()
            scheduledTask = nil
            scheduleGeneration &+= 1
        }

        private func removeHostedView() {
            hostedView?.removeFromSuperview()
            hostedView = nil
            panGestureRecognizer = nil
            touchGestureRecognizer = nil
        }

        @objc
        private func handleTouch(_ gestureRecognizer: UILongPressGestureRecognizer) {
            switch gestureRecognizer.state {
            case .began:
                beginTouch()
            case .ended, .cancelled, .failed:
                endTouch()
            default:
                break
            }
        }

        @objc
        private func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
            guard isTrackingTouch,
                  let hostedView else {
                return
            }

            switch gestureRecognizer.state {
            case .changed:
                let translation = gestureRecognizer.translation(in: hostedView)
                hostedView.transform = CGAffineTransform(
                    translationX: 0,
                    y: min(0, translation.y)
                )
            case .ended, .cancelled, .failed:
                endTouch()
            default:
                break
            }
        }

        private func beginTouch() {
            guard state == .entering || state == .visible,
                  let hostedView else {
                return
            }

            // Freeze the active countdown at zero until the user's finger lifts.
            cancelScheduledAction()
            isTrackingTouch = true
            state = .dragging
            hostedView.layer.removeAllAnimations()
        }

        private func endTouch() {
            guard isTrackingTouch,
                  let hostedView else {
                return
            }

            isTrackingTouch = false
            let translation = panGestureRecognizer?.translation(in: hostedView).y ?? 0
            let velocity = panGestureRecognizer?.velocity(in: hostedView).y ?? 0

            if translation <= -InAppNotificationLayout.dismissDistance
                || velocity <= -InAppNotificationLayout.dismissVelocity {
                dismissNotification(
                    scheduleNext: true,
                    animated: true,
                    isReplacement: false
                )
            } else {
                state = .visible
                UIView.animate(
                    withDuration: InAppNotificationTiming.animationDuration,
                    delay: 0,
                    options: [.curveEaseOut, .beginFromCurrentState, .allowUserInteraction],
                    animations: {
                        hostedView.transform = .identity
                    }
                ) { [weak self, weak hostedView] _ in
                    guard let self,
                          let hostedView,
                          self.hostedView === hostedView,
                          self.isSimulationEnabled,
                          self.state == .visible else {
                        return
                    }

                    self.scheduleCurrentNotificationTransition()
                }
            }
        }

        private func nextMessage() -> String {
            guard isMultipleMessages else {
                return InAppNotificationBannerView.defaultMessage
            }

            let messages = InAppNotificationBannerView.multipleMessages
            let message = messages[messageIndex % messages.count]
            messageIndex += 1
            return message
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        private func hiddenTransform(in window: UIWindow) -> CGAffineTransform {
            let distance = window.safeAreaInsets.top
                + InAppNotificationLayout.height
                + InAppNotificationLayout.shadowOverflow
            return CGAffineTransform(translationX: 0, y: -distance)
        }

        private enum PresentationState {
            case hidden
            case entering
            case visible
            case dragging
            case exiting
        }
    }

    final class WindowAttachmentView: UIView {
        var windowDidChange: ((UIWindow?) -> Void)?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            windowDidChange?(window)
        }
    }
}

extension View {
    func inAppNotificationSimulation(
        isEnabled: Bool,
        isMultipleMessages: Bool = false
    ) -> some View {
        modifier(
            InAppNotificationSimulationModifier(
                isEnabled: isEnabled,
                isMultipleMessages: isMultipleMessages
            )
        )
    }
}

#Preview("In-App Notification") {
    NavigationView {
        InAppNotificationView()
    }
    .navigationViewStyle(StackNavigationViewStyle())
}

#Preview("Banner Light") {
    InAppNotificationBannerView()
        .padding(10)
        .background(Color("color-base-1"))
        .preferredColorScheme(.light)
}

#Preview("Banner Dark") {
    InAppNotificationBannerView()
        .padding(10)
        .background(Color("color-base-1"))
        .preferredColorScheme(.dark)
}
