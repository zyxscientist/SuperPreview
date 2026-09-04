//
//  SwiftBackToPreviousPage.swift
//  SuperPreview
//
//  Page-scoped support for UIKit's native interactive navigation pop.
//  SwiftUI continues to own NavigationView and NavigationLink state.
//

import ObjectiveC
import SwiftUI
import UIKit

/// Controls the native back gestures made available by a page.
enum NavigationBackSwipePolicy: String, Equatable {
    /// Disables all navigation-controller back gestures for the page.
    case disabled
    /// Enables only the leading-edge interactive pop gesture.
    case edge
    /// Enables edge pop and, where UIKit's navigation affordance is visible,
    /// iOS 26+ content-area pop.
    case system
}

private var navigationBackSwipeCoordinatorKey: UInt8 = 0
private var navigationBackSwipePolicyKey: UInt8 = 0
private var navigationBackSwipePrioritizesEdgeKey: UInt8 = 0

private extension UIViewController {
    var navigationBackSwipePolicy: NavigationBackSwipePolicy? {
        get {
            guard let rawValue = objc_getAssociatedObject(
                self,
                &navigationBackSwipePolicyKey
            ) as? String else {
                return nil
            }
            return NavigationBackSwipePolicy(rawValue: rawValue)
        }
        set {
            objc_setAssociatedObject(
                self,
                &navigationBackSwipePolicyKey,
                newValue?.rawValue,
                .OBJC_ASSOCIATION_COPY_NONATOMIC
            )
        }
    }

    var navigationBackSwipePrioritizesEdge: Bool {
        get {
            let value = objc_getAssociatedObject(
                self,
                &navigationBackSwipePrioritizesEdgeKey
            ) as? NSNumber
            return value?.boolValue ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &navigationBackSwipePrioritizesEdgeKey,
                NSNumber(value: newValue),
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

private extension UINavigationController {
    var navigationBackSwipeCoordinator: NavigationBackSwipeCoordinator? {
        get {
            objc_getAssociatedObject(self, &navigationBackSwipeCoordinatorKey)
                as? NavigationBackSwipeCoordinator
        }
        set {
            objc_setAssociatedObject(
                self,
                &navigationBackSwipeCoordinatorKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

/// One coordinator is retained by each navigation controller. It never owns
/// SwiftUI routing and only configures UIKit's existing recognizers once the
/// navigation transition has settled.
private final class NavigationBackSwipeCoordinator: NSObject {
    weak var navigationController: UINavigationController?
    var defaultPolicy: NavigationBackSwipePolicy = .edge

    private var refreshIsScheduled = false
    // UIGestureRecognizer keeps its delegate weakly. Preserve UIKit's
    // original delegate so a later `.system` page can restore it after a
    // custom-navbar page temporarily clears it for edge pop.
    private var originalEdgeGestureDelegate: (any UIGestureRecognizerDelegate)?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        originalEdgeGestureDelegate = navigationController.interactivePopGestureRecognizer?.delegate
        super.init()
    }

    static func install(on navigationController: UINavigationController) -> NavigationBackSwipeCoordinator {
        if let coordinator = navigationController.navigationBackSwipeCoordinator {
            return coordinator
        }

        let coordinator = NavigationBackSwipeCoordinator(navigationController: navigationController)
        navigationController.navigationBackSwipeCoordinator = coordinator
        return coordinator
    }

    func register(
        _ policy: NavigationBackSwipePolicy,
        prioritizesEdgeOverHorizontalContent: Bool,
        for navigationChild: UIViewController
    ) {
        navigationChild.navigationBackSwipePolicy = policy
        navigationChild.navigationBackSwipePrioritizesEdge = prioritizesEdgeOverHorizontalContent
        refreshWhenStable()
    }

    func refreshWhenStable() {
        guard let navigationController else { return }

        if let transitionCoordinator = navigationController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
                DispatchQueue.main.async {
                    self?.refreshWhenStable()
                }
            }
            return
        }

        guard !refreshIsScheduled else { return }
        refreshIsScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.refreshIsScheduled = false
            self.refreshNowIfStable()
        }
    }

    private var currentPolicy: NavigationBackSwipePolicy {
        guard let topViewController = navigationController?.topViewController else {
            return defaultPolicy
        }
        return topViewController.navigationBackSwipePolicy ?? defaultPolicy
    }

    private var isEligibleForPop: Bool {
        guard let navigationController,
              navigationController.viewControllers.count > 1,
              navigationController.transitionCoordinator == nil,
              !navigationController.isBeingDismissed,
              !navigationController.isMovingFromParent,
              !hasBlockingPresentation else {
            return false
        }

        let topViewController = navigationController.topViewController
        return topViewController?.isBeingPresented != true
            && topViewController?.isBeingDismissed != true
            && topViewController?.isMovingFromParent != true
    }

    private var hasBlockingPresentation: Bool {
        guard let navigationController else { return true }
        return navigationController.presentedViewController != nil
            || navigationController.topViewController?.presentedViewController != nil
    }

    private func enableHiddenNavigationBarEdgePop() {
        guard let edgeRecognizer = navigationController?.interactivePopGestureRecognizer else {
            return
        }

        if originalEdgeGestureDelegate == nil {
            originalEdgeGestureDelegate = edgeRecognizer.delegate
        }

        // SwiftUI records a hidden toolbar/back button in the original edge
        // delegate. Removing only that delegate leaves UIKit's own transition
        // target intact, so interactive progress, velocity, cancellation, and
        // stack updates stay fully native.
        edgeRecognizer.delegate = nil
    }

    private func restoreSystemEdgePopDelegate() {
        guard let edgeRecognizer = navigationController?.interactivePopGestureRecognizer,
              let originalEdgeGestureDelegate else {
            return
        }

        edgeRecognizer.delegate = originalEdgeGestureDelegate
    }

    private var canUseSystemContentPop: Bool {
        guard #available(iOS 26.0, *),
              let navigationController,
              navigationController.interactiveContentPopGestureRecognizer != nil,
              !navigationController.isNavigationBarHidden,
              navigationController.topViewController?.navigationItem.hidesBackButton != true else {
            return false
        }

        return true
    }

    private func prioritizeEdgePopOverHorizontalContentIfNeeded() {
        guard let navigationController,
              navigationController.topViewController?.navigationBackSwipePrioritizesEdge == true,
              let edgeRecognizer = navigationController.interactivePopGestureRecognizer else {
            return
        }

        for scrollView in horizontalScrollViews(in: navigationController.topViewController?.view) {
            let horizontalPan = scrollView.panGestureRecognizer
            guard horizontalPan !== edgeRecognizer else { continue }

            // At the leading edge, let UIKit decide first whether this is a
            // navigation pop. Away from the edge it fails immediately, so the
            // page's own horizontal pager keeps its normal behavior.
            horizontalPan.require(toFail: edgeRecognizer)
        }
    }

    private func horizontalScrollViews(in view: UIView?) -> [UIScrollView] {
        guard let view else { return [] }

        var result: [UIScrollView] = []
        if let scrollView = view as? UIScrollView,
           scrollView.alwaysBounceHorizontal || scrollView.contentSize.width > scrollView.bounds.width {
            result.append(scrollView)
        }

        for subview in view.subviews {
            result.append(contentsOf: horizontalScrollViews(in: subview))
        }
        return result
    }

    private func refreshNowIfStable() {
        guard let navigationController else { return }
        guard navigationController.transitionCoordinator == nil else {
            refreshWhenStable()
            return
        }

        let canAttemptPop = isEligibleForPop
        switch currentPolicy {
        case .disabled:
            restoreSystemEdgePopDelegate()
            navigationController.interactivePopGestureRecognizer?.isEnabled = false
            setContentPopEnabled(false)

        case .edge:
            enableHiddenNavigationBarEdgePop()
            navigationController.interactivePopGestureRecognizer?.isEnabled = canAttemptPop
            setContentPopEnabled(false)
            prioritizeEdgePopOverHorizontalContentIfNeeded()

        case .system:
            if canUseSystemContentPop {
                // UIKit owns the iOS 26+ content recognizer and its conflict
                // arbitration. Its original edge delegate must remain in
                // place while the two system recognizers cooperate.
                restoreSystemEdgePopDelegate()
                navigationController.interactivePopGestureRecognizer?.isEnabled = canAttemptPop
                setContentPopEnabled(canAttemptPop)
            } else {
                // iOS 27 suppresses content-area pop when a page hides the
                // system navigation bar or back affordance. Do not re-show it
                // (that would alter the custom navbar); preserve native edge
                // pop instead.
                enableHiddenNavigationBarEdgePop()
                navigationController.interactivePopGestureRecognizer?.isEnabled = canAttemptPop
                setContentPopEnabled(false)
            }
        }
    }

    private func setContentPopEnabled(_ isEnabled: Bool) {
        guard #available(iOS 26.0, *),
              let navigationController else {
            return
        }

        // UIKit owns this recognizer's delegate and interaction arbitration.
        navigationController.interactiveContentPopGestureRecognizer?.isEnabled = isEnabled
    }
}

private final class NavigationBackSwipePageHostViewController: UIViewController {
    var policy: NavigationBackSwipePolicy
    var prioritizesEdgeOverHorizontalContent: Bool

    init(
        policy: NavigationBackSwipePolicy,
        prioritizesEdgeOverHorizontalContent: Bool
    ) {
        self.policy = policy
        self.prioritizesEdgeOverHorizontalContent = prioritizesEdgeOverHorizontalContent
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        applyPolicy()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyPolicy()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyPolicy()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBackSwipeCoordinator?.refreshWhenStable()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.navigationBackSwipeCoordinator?.refreshWhenStable()
    }

    func applyPolicy() {
        guard let navigationController,
              let navigationChild = owningNavigationChild(in: navigationController) else {
            return
        }

        let coordinator = NavigationBackSwipeCoordinator.install(on: navigationController)
        coordinator.register(
            policy,
            prioritizesEdgeOverHorizontalContent: prioritizesEdgeOverHorizontalContent,
            for: navigationChild
        )
    }

    private func owningNavigationChild(
        in navigationController: UINavigationController
    ) -> UIViewController? {
        var candidate: UIViewController? = self

        while let current = candidate, current.parent !== navigationController {
            candidate = current.parent
        }

        return candidate?.parent === navigationController ? candidate : nil
    }
}

private final class NavigationBackSwipeRootHostViewController: UIViewController {
    var defaultPolicy: NavigationBackSwipePolicy

    init(defaultPolicy: NavigationBackSwipePolicy) {
        self.defaultPolicy = defaultPolicy
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        applyDefaultPolicy()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyDefaultPolicy()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        applyDefaultPolicy()
    }

    func applyDefaultPolicy() {
        guard let navigationController else { return }
        let coordinator = NavigationBackSwipeCoordinator.install(on: navigationController)
        coordinator.defaultPolicy = defaultPolicy
        coordinator.refreshWhenStable()
    }
}

private struct NavigationBackSwipePageModifier: UIViewControllerRepresentable {
    let policy: NavigationBackSwipePolicy
    let prioritizesEdgeOverHorizontalContent: Bool

    func makeUIViewController(context: Context) -> NavigationBackSwipePageHostViewController {
        NavigationBackSwipePageHostViewController(
            policy: policy,
            prioritizesEdgeOverHorizontalContent: prioritizesEdgeOverHorizontalContent
        )
    }

    func updateUIViewController(
        _ uiViewController: NavigationBackSwipePageHostViewController,
        context: Context
    ) {
        uiViewController.policy = policy
        uiViewController.prioritizesEdgeOverHorizontalContent = prioritizesEdgeOverHorizontalContent
        uiViewController.applyPolicy()
    }

    static func dismantleUIViewController(
        _ uiViewController: NavigationBackSwipePageHostViewController,
        coordinator: ()
    ) {
        uiViewController.navigationController?.navigationBackSwipeCoordinator?.refreshWhenStable()
    }
}

private struct NavigationBackSwipeRootInstaller: UIViewControllerRepresentable {
    let defaultPolicy: NavigationBackSwipePolicy

    func makeUIViewController(context: Context) -> NavigationBackSwipeRootHostViewController {
        NavigationBackSwipeRootHostViewController(defaultPolicy: defaultPolicy)
    }

    func updateUIViewController(
        _ uiViewController: NavigationBackSwipeRootHostViewController,
        context: Context
    ) {
        uiViewController.defaultPolicy = defaultPolicy
        uiViewController.applyDefaultPolicy()
    }
}

extension View {
    /// Associates a native back-swipe policy with this page's owning
    /// navigation-controller child without changing the SwiftUI route.
    func navigationBackSwipe(
        _ policy: NavigationBackSwipePolicy,
        prioritizesEdgeOverHorizontalContent: Bool = false
    ) -> some View {
        background(
            NavigationBackSwipePageModifier(
                policy: policy,
                prioritizesEdgeOverHorizontalContent: prioritizesEdgeOverHorizontalContent
            )
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        )
    }
}

/// Installs the default policy for a SwiftUI NavigationView. Destinations can
/// override the default with `navigationBackSwipe(_:)`.
struct NavigationBackSwipeInstaller: View {
    let defaultPolicy: NavigationBackSwipePolicy

    var body: some View {
        NavigationBackSwipeRootInstaller(defaultPolicy: defaultPolicy)
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

#if DEBUG
/// A UI-test-only reproduction surface. Production never routes here; it lets
/// the native recognizers be verified before complex paged screens are tested.
struct NavigationBackSwipeHarnessView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Back swipe harness")
                    .font(.headline)

                NavigationLink(
                    destination: NavigationBackSwipeHarnessDestination(
                        policy: .edge,
                        hidesSystemNavigationBar: true,
                        identifier: "edge"
                    )
                ) {
                    Text("Edge")
                }
                .accessibilityIdentifier("backSwipeHarness.link.edge")

                NavigationLink(
                    destination: NavigationBackSwipeHarnessDestination(
                        policy: .system,
                        hidesSystemNavigationBar: false,
                        identifier: "system"
                    )
                ) {
                    Text("System")
                }
                .accessibilityIdentifier("backSwipeHarness.link.system")

                NavigationLink(
                    destination: NavigationBackSwipeHarnessDestination(
                        policy: .system,
                        hidesSystemNavigationBar: true,
                        identifier: "systemHidden"
                    )
                ) {
                    Text("System custom")
                }
                .accessibilityIdentifier("backSwipeHarness.link.systemHidden")

                NavigationLink(
                    destination: NavigationBackSwipeHarnessDestination(
                        policy: .disabled,
                        hidesSystemNavigationBar: true,
                        identifier: "disabled"
                    )
                ) {
                    Text("Disabled")
                }
                .accessibilityIdentifier("backSwipeHarness.link.disabled")

                NavigationLink(destination: NavigationBackSwipeHarnessNativeDestination()) {
                    Text("Native")
                }
                .accessibilityIdentifier("backSwipeHarness.link.native")

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("color-base-1"))
            .accessibilityIdentifier("backSwipeHarness.root")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

private struct NavigationBackSwipeHarnessNativeDestination: View {
    var body: some View {
        Text("UIKit baseline")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityIdentifier("backSwipeHarness.destination.native")
    }
}

private struct NavigationBackSwipeHarnessDestination: View {
    let policy: NavigationBackSwipePolicy
    let hidesSystemNavigationBar: Bool
    let identifier: String

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if hidesSystemNavigationBar {
                pageContent.toolbar(.hidden, for: .navigationBar)
            } else {
                pageContent
            }
        }
        .navigationBackSwipe(policy)
        .accessibilityIdentifier("backSwipeHarness.destination.\(identifier)")
    }

    private var pageContent: some View {
        VStack(spacing: 24) {
            if hidesSystemNavigationBar {
                HStack {
                    Button("Back") {
                        dismiss()
                    }
                    .accessibilityIdentifier("backSwipeHarness.customBack")

                    Spacer()
                }
            }

            Text(policy.rawValue)
                .font(.title)
            Text("Native interactive pop test page")
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color("color-base-1"))
    }
}
#endif
