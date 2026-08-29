//
//  InteractiveBottomCard.swift
//  SuperPreview
//

import SwiftUI
import UIKit
import Transmission

/// Configuration for a content-sized bottom card whose presentation and
/// dismissal are driven by UIKit.
struct InteractiveBottomCardConfiguration: Equatable, Sendable {
    var dimmingOpacity: CGFloat = 0.3
    var cornerRadius: CGFloat = 10
    var dismissalDistance: CGFloat = 120
    var projectedDismissalDistance: CGFloat = 220
    var transitionDuration: TimeInterval = 0.3

    static let `default` = Self()
}

extension View {
    /// Presents a reusable interactive bottom card from a Boolean binding.
    func interactiveBottomCard<Destination: View>(
        isPresented: Binding<Bool>,
        configuration: InteractiveBottomCardConfiguration = .default,
        @ViewBuilder content: @escaping () -> Destination
    ) -> some View {
        modifier(
            InteractiveBottomCardModifier(
                isPresented: isPresented,
                configuration: configuration,
                destination: content
            )
        )
    }

    /// Presents a reusable interactive bottom card from an optional item.
    func interactiveBottomCard<Item, Destination: View>(
        item: Binding<Item?>,
        configuration: InteractiveBottomCardConfiguration = .default,
        @ViewBuilder content: @escaping (Item) -> Destination
    ) -> some View {
        modifier(
            InteractiveBottomCardItemModifier(
                item: item,
                configuration: configuration,
                destination: content
            )
        )
    }
}

private struct InteractiveBottomCardModifier<Destination: View>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isPresented: Binding<Bool>
    let configuration: InteractiveBottomCardConfiguration
    let destination: () -> Destination

    func body(content: Content) -> some View {
        content
            .presentation(
                transition: InteractiveBottomCardTransition(configuration: configuration).presentationTransition,
                isPresented: isPresented,
                destination: destination
            )
            .modifier(
                OptionalAnimationModifier(
                    animation: presentationAnimation,
                    value: isPresented.wrappedValue
                )
            )
    }

    private var presentationAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: configuration.transitionDuration)
    }
}

private struct InteractiveBottomCardItemModifier<Item, Destination: View>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let item: Binding<Item?>
    let configuration: InteractiveBottomCardConfiguration
    let destination: (Item) -> Destination

    func body(content: Content) -> some View {
        content
            .presentation(
                item,
                transition: InteractiveBottomCardTransition(configuration: configuration).presentationTransition
            ) { item in
                destination(item.wrappedValue)
            }
            .modifier(
                OptionalAnimationModifier(
                    animation: presentationAnimation,
                    value: item.wrappedValue != nil
                )
            )
    }

    private var presentationAnimation: Animation? {
        reduceMotion ? nil : .easeOut(duration: configuration.transitionDuration)
    }
}

@available(iOS 14.0, *)
private struct InteractiveBottomCardTransition: PresentationLinkTransitionRepresentable {
    typealias UIPresentationControllerType = InteractiveBottomCardPresentationController

    let configuration: InteractiveBottomCardConfiguration

    var presentationTransition: PresentationLinkTransition {
        let options = PresentationLinkTransition.Options(
            isInteractive: true,
            modalPresentationCapturesStatusBarAppearance: true,
            preferredPresentationSafeAreaInsets: .zero,
            preferredPresentationBackgroundColor: .clear
        )
        return .custom(
            options: options,
            self
        )
    }

    @MainActor @preconcurrency
    func makeUIPresentationController(
        presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController,
        context: Context
    ) -> InteractiveBottomCardPresentationController {
        InteractiveBottomCardPresentationController(
            configuration: configuration,
            presentedViewController: presented,
            presenting: presenting
        )
    }

    @MainActor @preconcurrency
    func updateUIPresentationController(
        presentationController: InteractiveBottomCardPresentationController,
        context: Context
    ) {
        presentationController.dimmingView.backgroundColor = UIColor.black.withAlphaComponent(
            configuration.dimmingOpacity
        )
        presentationController.dimmingView.isHidden = false
        presentationController.dimmingView.accessibilityIdentifier = "interactiveBottomCard.dimming"
        presentationController.isInteractive = context.options.isInteractive
        presentationController.prefersInteractiveDismissal = true
        presentationController.edges = .bottom
        presentationController.preferredEdgeInset = 0
        presentationController.preferredCornerRadius = .rounded(
            cornerRadius: configuration.cornerRadius,
            mask: .top,
            style: .continuous
        )
        presentationController.insetSafeAreaByCornerRadius = false
        presentationController.preferredAspectRatio = nil
        presentationController.preferredSafeAreaInsets = .zero
        presentationController.presentedViewShadow = .clear
    }

    @MainActor @preconcurrency
    func updateHostingController<Content: View>(
        presenting: PresentationHostingController<Content>,
        context: Context
    ) {
        presenting.view.clipsToBounds = false
        presenting.tracksContentSize = true
        presenting.disableSafeArea = true
    }
}

@available(iOS 14.0, *)
private final class InteractiveBottomCardPresentationController: CardPresentationController {
    private let configuration: InteractiveBottomCardConfiguration

    init(
        configuration: InteractiveBottomCardConfiguration,
        presentedViewController: UIViewController,
        presenting presentingViewController: UIViewController?
    ) {
        self.configuration = configuration
        super.init(
            preferredEdgeInset: 0,
            preferredCornerRadius: .rounded(
                cornerRadius: configuration.cornerRadius,
                mask: .top,
                style: .continuous
            ),
            insetSafeAreaByCornerRadius: false,
            preferredAspectRatio: nil,
            presentedViewController: presentedViewController,
            presenting: presentingViewController
        )
    }

    override func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard super.gestureRecognizerShouldBegin(gestureRecognizer) else { return false }
        guard gestureRecognizer === panGesture else { return true }

        let velocity = panGesture.velocity(in: panGesture.view)
        return velocity.y > 0 && abs(velocity.y) >= abs(velocity.x)
    }

    override func presentedViewTransform(
        for translation: CGPoint
    ) -> CGAffineTransform {
        CGAffineTransform(
            translationX: 0,
            y: max(0, translation.y)
        )
    }

    override func transformPresentedView(transform: CGAffineTransform) {
        super.transformPresentedView(transform: transform)

        guard let containerView else { return }
        let progress = min(
            max(max(0, transform.ty) / max(containerView.bounds.height, 1), 0),
            1
        )
        dimmingView.alpha = 1 - progress
    }

    override func dismissalTransitionShouldBegin(
        translation: CGPoint,
        delta: CGPoint,
        velocity: CGPoint
    ) -> Bool {
        let isVertical = abs(translation.y) >= abs(translation.x)
        guard isVertical, translation.y >= 0 else { return false }

        let projectedTranslation = projectedTranslation(
            translation: translation.y,
            velocity: velocity.y
        )
        return translation.y >= configuration.dismissalDistance
            || projectedTranslation >= configuration.projectedDismissalDistance
    }

    private func projectedTranslation(
        translation: CGFloat,
        velocity: CGFloat
    ) -> CGFloat {
        guard velocity > 0 else { return max(0, translation) }

        let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
        let projectedDistance = velocity / 1000
            * decelerationRate
            / max(1 - decelerationRate, .leastNonzeroMagnitude)
        return max(0, translation + projectedDistance)
    }
}
