//
//  SwiftBackToPreviousPage.swift
//  SuperPreview
//
//  Page-scoped support for UIKit's native interactive navigation pop.
//  SwiftUI continues to own NavigationView and NavigationLink state.
//

import Foundation
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
private var navigationBackSwipePolicyOwnerKey: UInt8 = 0

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

    var navigationBackSwipePolicyOwner: AnyObject? {
        get {
            objc_getAssociatedObject(self, &navigationBackSwipePolicyOwnerKey) as AnyObject?
        }
        set {
            objc_setAssociatedObject(
                self,
                &navigationBackSwipePolicyOwnerKey,
                newValue,
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
    private var transitionWaitID: ObjectIdentifier?
    private var transitionRetryID: ObjectIdentifier?
    private var needsHorizontalContentScan = true
    private let configuredHorizontalScrollViews = NSHashTable<UIScrollView>.weakObjects()
    private weak var configuredEdgeGesture: UIGestureRecognizer?
    private var lastHorizontalScrollViewScanCount = 0
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
        rescanHorizontalContent: Bool,
        owner: AnyObject,
        for navigationChild: UIViewController,
        source: String
    ) {
        navigationChild.navigationBackSwipePolicy = policy
        navigationChild.navigationBackSwipePrioritizesEdge = prioritizesEdgeOverHorizontalContent
        navigationChild.navigationBackSwipePolicyOwner = owner

        if rescanHorizontalContent, prioritizesEdgeOverHorizontalContent {
            needsHorizontalContentScan = true
        }

        refreshWhenStable(source: source)
    }

    func unregister(
        owner: AnyObject,
        from navigationChild: UIViewController,
        source: String
    ) {
        guard navigationChild.navigationBackSwipePolicyOwner === owner else { return }

        navigationChild.navigationBackSwipePolicy = nil
        navigationChild.navigationBackSwipePrioritizesEdge = false
        navigationChild.navigationBackSwipePolicyOwner = nil
        refreshWhenStable(source: source)
    }

    func requestHorizontalContentScan(source: String) {
        needsHorizontalContentScan = true
        refreshWhenStable(source: source)
    }

    func refreshWhenStable(source: String = "unspecified") {
        guard navigationController != nil else { return }

        if let transitionCoordinator = activeTransitionCoordinator {
            waitForTransition(transitionCoordinator, source: source)
            return
        }

        // A direct refresh signal is also a recovery path if the transition
        // completion was delivered before UIKit stopped vending its
        // coordinator. The next main-queue turn re-reads all state.
        transitionWaitID = nil
        scheduleRefresh(source: source)
    }

    private func scheduleRefresh(source: String) {
        guard !refreshIsScheduled else { return }
        refreshIsScheduled = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.refreshIsScheduled = false
            self.refreshNowIfStable(source: source)
        }
    }

    private func waitForTransition(
        _ transitionCoordinator: any UIViewControllerTransitionCoordinator,
        source: String
    ) {
        let transitionID = ObjectIdentifier(transitionCoordinator as AnyObject)
        guard transitionWaitID != transitionID else { return }

        transitionWaitID = transitionID
        #if DEBUG
        debugLog(
            "source=\(source) waitingForTransition=\(String(describing: type(of: transitionCoordinator))) "
                + "id=\(transitionID)"
        )
        #endif

        let registered = transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                guard let self, self.transitionWaitID == transitionID else { return }

                self.transitionWaitID = nil
                self.scheduleRefresh(source: "\(source).transitionCompletion")
            }
        }

        if !registered {
            // UIKit may still invoke the completion when registration returns
            // false. Keep the same transition token until this retry runs so
            // either path is harmless and the transition is only registered
            // once per coordinator at a time.
            scheduleTransitionRetry(for: transitionID, source: source)
        }
    }

    private func scheduleTransitionRetry(for transitionID: ObjectIdentifier, source: String) {
        guard transitionRetryID != transitionID else { return }
        transitionRetryID = transitionID

        DispatchQueue.main.async { [weak self] in
            guard let self, self.transitionRetryID == transitionID else { return }
            self.transitionRetryID = nil

            guard self.transitionWaitID == transitionID else { return }
            self.transitionWaitID = nil
            self.refreshWhenStable(source: "\(source).registrationRetry")
        }
    }

    private var activeTransitionCoordinator: (any UIViewControllerTransitionCoordinator)? {
        guard let navigationController else { return nil }

        var candidates: [UIViewController] = []
        var seen = Set<ObjectIdentifier>()

        func append(_ viewController: UIViewController?) {
            guard let viewController,
                  seen.insert(ObjectIdentifier(viewController)).inserted else {
                return
            }
            candidates.append(viewController)
        }

        func appendPresentedChain(from viewController: UIViewController?) {
            var current = viewController?.presentedViewController
            while let presented = current {
                append(presented)
                current = presented.presentedViewController
            }
        }

        func appendPresentingChain(from viewController: UIViewController?) {
            var current = viewController?.presentingViewController
            while let presenting = current {
                append(presenting)
                current = presenting.presentingViewController
            }
        }

        append(navigationController)
        append(navigationController.topViewController)
        appendPresentedChain(from: navigationController)
        appendPresentedChain(from: navigationController.topViewController)
        appendPresentingChain(from: navigationController)
        appendPresentingChain(from: navigationController.topViewController)

        for viewController in candidates {
            if let transitionCoordinator = viewController.transitionCoordinator {
                return transitionCoordinator
            }
        }

        return nil
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
              activeTransitionCoordinator == nil,
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

    @discardableResult
    private func prioritizeEdgePopOverHorizontalContentIfNeeded() -> Int? {
        guard let navigationController,
              navigationController.topViewController?.navigationBackSwipePrioritizesEdge == true,
              let edgeRecognizer = navigationController.interactivePopGestureRecognizer else {
            return nil
        }

        guard needsHorizontalContentScan else {
            return lastHorizontalScrollViewScanCount
        }

        if configuredEdgeGesture !== edgeRecognizer {
            configuredEdgeGesture = edgeRecognizer
            configuredHorizontalScrollViews.removeAllObjects()
        }

        let scrollViews = horizontalScrollViews(in: navigationController.topViewController?.view)
        for scrollView in scrollViews {
            let horizontalPan = scrollView.panGestureRecognizer
            guard horizontalPan !== edgeRecognizer else { continue }

            // At the leading edge, let UIKit decide first whether this is a
            // navigation pop. Away from the edge it fails immediately, so the
            // page's own horizontal pager keeps its normal behavior.
            if !configuredHorizontalScrollViews.contains(scrollView) {
                horizontalPan.require(toFail: edgeRecognizer)
                configuredHorizontalScrollViews.add(scrollView)
            }
        }

        lastHorizontalScrollViewScanCount = scrollViews.count
        needsHorizontalContentScan = false
        return scrollViews.count
    }

    private func horizontalScrollViews(in view: UIView?) -> [UIScrollView] {
        guard let view else { return [] }

        var result: [UIScrollView] = []
        if let scrollView = view as? UIScrollView,
           scrollView.alwaysBounceHorizontal
            || scrollView.isPagingEnabled
            || scrollView.contentSize.width > scrollView.bounds.width {
            result.append(scrollView)
        }

        for subview in view.subviews {
            result.append(contentsOf: horizontalScrollViews(in: subview))
        }
        return result
    }

    private func refreshNowIfStable(source: String) {
        guard let navigationController else { return }
        guard activeTransitionCoordinator == nil else {
            refreshWhenStable(source: source)
            return
        }

        let canAttemptPop = isEligibleForPop
        let policy = currentPolicy
        let horizontalScrollViewScanCount: Int?

        switch policy {
        case .disabled:
            restoreSystemEdgePopDelegate()
            navigationController.interactivePopGestureRecognizer?.isEnabled = false
            setContentPopEnabled(false)
            horizontalScrollViewScanCount = nil

        case .edge:
            enableHiddenNavigationBarEdgePop()
            navigationController.interactivePopGestureRecognizer?.isEnabled = canAttemptPop
            setContentPopEnabled(false)
            horizontalScrollViewScanCount = prioritizeEdgePopOverHorizontalContentIfNeeded()

        case .system:
            if canUseSystemContentPop {
                // UIKit owns the iOS 26+ content recognizer and its conflict
                // arbitration. Its original edge delegate must remain in
                // place while the two system recognizers cooperate.
                restoreSystemEdgePopDelegate()
                navigationController.interactivePopGestureRecognizer?.isEnabled = canAttemptPop
                setContentPopEnabled(canAttemptPop)
                horizontalScrollViewScanCount = nil
            } else {
                // iOS 27 suppresses content-area pop when a page hides the
                // system navigation bar or back affordance. Do not re-show it
                // (that would alter the custom navbar); preserve native edge
                // pop instead.
                enableHiddenNavigationBarEdgePop()
                navigationController.interactivePopGestureRecognizer?.isEnabled = canAttemptPop
                setContentPopEnabled(false)
                horizontalScrollViewScanCount = prioritizeEdgePopOverHorizontalContentIfNeeded()
            }
        }

        #if DEBUG
        let edgeRecognizer = navigationController.interactivePopGestureRecognizer
        let contentRecognizer: UIGestureRecognizer?
        if #available(iOS 26.0, *) {
            contentRecognizer = navigationController.interactiveContentPopGestureRecognizer
        } else {
            contentRecognizer = nil
        }

        debugLog(
            "source=\(source) top=\(viewControllerName(navigationController.topViewController)) "
                + "stack=\(navigationController.viewControllers.count) "
                + "navPresented=\(viewControllerName(navigationController.presentedViewController)) "
                + "topPresented=\(viewControllerName(navigationController.topViewController?.presentedViewController)) "
                + "transition=none policy=\(policy.rawValue) eligible=\(canAttemptPop) "
                + "edgeEnabled=\(gestureState(edgeRecognizer)) "
                + "contentEnabled=\(gestureState(contentRecognizer)) "
                + "edgeDelegate=\(delegateName(edgeRecognizer?.delegate)) "
                + "horizontalScrollViews=\(horizontalScrollViewScanCount.map(String.init) ?? "not-scanned")"
        )
        #endif
    }

    private func setContentPopEnabled(_ isEnabled: Bool) {
        guard #available(iOS 26.0, *),
              let navigationController else {
            return
        }

        // UIKit owns this recognizer's delegate and interaction arbitration.
        navigationController.interactiveContentPopGestureRecognizer?.isEnabled = isEnabled
    }

    #if DEBUG
    private func debugLog(_ message: String) {
        print("[NavigationBackSwipe] \(message)")
    }

    private func viewControllerName(_ viewController: UIViewController?) -> String {
        guard let viewController else { return "nil" }
        return String(describing: type(of: viewController))
    }

    private func gestureState(_ gestureRecognizer: UIGestureRecognizer?) -> String {
        gestureRecognizer.map { $0.isEnabled ? "enabled" : "disabled" } ?? "nil"
    }

    private func delegateName(_ delegate: UIGestureRecognizerDelegate?) -> String {
        guard let delegate else { return "nil" }
        return String(describing: type(of: delegate))
    }
    #endif
}

private final class NavigationBackSwipePageHostViewController: UIViewController {
    var policy: NavigationBackSwipePolicy
    var prioritizesEdgeOverHorizontalContent: Bool
    var refreshID: Int
    var participatesInNavigationBackSwipe: Bool

    private var hasRegisteredPolicy = false
    private var lastAppliedPolicy: NavigationBackSwipePolicy?
    private var lastAppliedPriority: Bool?
    private var lastAppliedRefreshID: Int?

    init(
        policy: NavigationBackSwipePolicy,
        prioritizesEdgeOverHorizontalContent: Bool,
        refreshID: Int,
        participatesInNavigationBackSwipe: Bool
    ) {
        self.policy = policy
        self.prioritizesEdgeOverHorizontalContent = prioritizesEdgeOverHorizontalContent
        self.refreshID = refreshID
        self.participatesInNavigationBackSwipe = participatesInNavigationBackSwipe
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
        applyPolicy(source: "page.viewDidAppear")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard participatesInNavigationBackSwipe else { return }
        navigationController?.navigationBackSwipeCoordinator?.refreshWhenStable(source: "page.layout")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBackSwipeCoordinator?.refreshWhenStable(source: "page.viewWillDisappear")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.navigationBackSwipeCoordinator?.refreshWhenStable(source: "page.viewDidDisappear")
    }

    func applyPolicy(source: String = "page.apply") {
        guard participatesInNavigationBackSwipe else {
            removePolicy(source: "\(source).inactive")
            return
        }

        guard let navigationController,
              let navigationChild = owningNavigationChild(in: navigationController) else {
            return
        }

        let coordinator = NavigationBackSwipeCoordinator.install(on: navigationController)
        let shouldRescanHorizontalContent = !hasRegisteredPolicy
            || lastAppliedPolicy != policy
            || lastAppliedPriority != prioritizesEdgeOverHorizontalContent
            || lastAppliedRefreshID != refreshID

        coordinator.register(
            policy,
            prioritizesEdgeOverHorizontalContent: prioritizesEdgeOverHorizontalContent,
            rescanHorizontalContent: shouldRescanHorizontalContent,
            owner: self,
            for: navigationChild,
            source: source
        )

        hasRegisteredPolicy = true
        lastAppliedPolicy = policy
        lastAppliedPriority = prioritizesEdgeOverHorizontalContent
        lastAppliedRefreshID = refreshID
    }

    fileprivate func removePolicy(source: String) {
        guard let navigationController,
              let navigationChild = owningNavigationChild(in: navigationController) else {
            return
        }

        navigationController.navigationBackSwipeCoordinator?.unregister(
            owner: self,
            from: navigationChild,
            source: source
        )

        hasRegisteredPolicy = false
        lastAppliedPolicy = nil
        lastAppliedPriority = nil
        lastAppliedRefreshID = nil
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
    let refreshID: Int
    let participatesInNavigationBackSwipe: Bool

    func makeUIViewController(context: Context) -> NavigationBackSwipePageHostViewController {
        NavigationBackSwipePageHostViewController(
            policy: policy,
            prioritizesEdgeOverHorizontalContent: prioritizesEdgeOverHorizontalContent,
            refreshID: refreshID,
            participatesInNavigationBackSwipe: participatesInNavigationBackSwipe
        )
    }

    func updateUIViewController(
        _ uiViewController: NavigationBackSwipePageHostViewController,
        context: Context
    ) {
        uiViewController.policy = policy
        uiViewController.prioritizesEdgeOverHorizontalContent = prioritizesEdgeOverHorizontalContent
        uiViewController.refreshID = refreshID
        uiViewController.participatesInNavigationBackSwipe = participatesInNavigationBackSwipe
        uiViewController.applyPolicy(source: "page.update")
    }

    static func dismantleUIViewController(
        _ uiViewController: NavigationBackSwipePageHostViewController,
        coordinator: ()
    ) {
        uiViewController.removePolicy(source: "page.dismantle")
        uiViewController.navigationController?.navigationBackSwipeCoordinator?.refreshWhenStable(source: "page.dismantle")
    }
}

private struct NavigationBackSwipeContentLayoutProbe: UIViewRepresentable {
    func makeUIView(context: Context) -> NavigationBackSwipeContentLayoutProbeView {
        NavigationBackSwipeContentLayoutProbeView()
    }

    func updateUIView(
        _ uiView: NavigationBackSwipeContentLayoutProbeView,
        context: Context
    ) {
        uiView.requestScanIfPossible()
    }
}

private final class NavigationBackSwipeContentLayoutProbeView: UIView {
    private var didRequestLayoutScan = false

    override func didMoveToWindow() {
        super.didMoveToWindow()

        if window == nil {
            didRequestLayoutScan = false
        } else {
            requestScanIfPossible()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard !didRequestLayoutScan else { return }
        if requestScanIfPossible() {
            didRequestLayoutScan = true
        }
    }

    @discardableResult
    func requestScanIfPossible() -> Bool {
        guard window != nil,
              let navigationController = owningNavigationController,
              let coordinator = navigationController.navigationBackSwipeCoordinator else {
            return false
        }

        coordinator.requestHorizontalContentScan(source: "content.layoutProbe")
        return true
    }

    private var owningNavigationController: UINavigationController? {
        var responder: UIResponder? = self

        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController.navigationController
            }
            responder = current.next
        }

        return nil
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
        prioritizesEdgeOverHorizontalContent: Bool = false,
        refreshID: Int = 0,
        participatesInNavigationBackSwipe: Bool = true
    ) -> some View {
        background(
            NavigationBackSwipePageModifier(
                policy: policy,
                prioritizesEdgeOverHorizontalContent: prioritizesEdgeOverHorizontalContent,
                refreshID: refreshID,
                participatesInNavigationBackSwipe: participatesInNavigationBackSwipe
            )
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        )
    }

    /// Gives a rebuilt horizontal pager one layout-boundary hook. The probe is
    /// zero-sized and only asks the page coordinator to scan when its view is
    /// attached or laid out, so ordinary content updates do not rescan the
    /// entire controller tree.
    func navigationBackSwipeContentLayoutProbe() -> some View {
        background(
            NavigationBackSwipeContentLayoutProbe()
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
