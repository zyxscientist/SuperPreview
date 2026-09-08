//
//  StockDetailShuffleView.swift
//  SuperPreview
//

import Foundation
import SwiftUI
import UIKit

enum StockDetailPagePresentationMode: Equatable {
    case standard
    case advancedTrading
    case shuffleCard
}

private enum StockDetailShuffleOrderTransitionPhase: Equatable {
    case idle
    case dragging
    case finishing
    case presented
    case returnDragging
}

struct StockDetailShuffleSession: Identifiable {
    let id = UUID()
    let instruments: [StockDetailInstrument]

    init(instruments: [StockDetailInstrument]) {
        self.instruments = instruments
    }
}

enum StockDetailShuffleStorageKey {
    static let quoteDataIsExpanded = "stockDetail.shuffle.quoteData.isExpanded"
}

/// A full-screen, vertically paged presentation of the current watchlist
/// context. The pager keeps a small resident card window around the current
/// instrument, while exposing only the current card and its immediate
/// neighbors for interaction.
struct StockDetailShuffleView: View {
    let instruments: [StockDetailInstrument]
    @Binding private var selection: StockDetailInstrument
    let onExit: (StockDetailInstrument) -> Void

    @AppStorage(StockDetailShuffleStorageKey.quoteDataIsExpanded)
    private var isQuoteDataExpanded = true
    @State private var symbolSelectionRequest: Int?
    @StateObject private var orderTransitionController: StockDetailShuffleOrderTransitionController

    @EnvironmentObject private var demoLanguageStore: DemoLanguageStore
    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        instruments: [StockDetailInstrument],
        selection: Binding<StockDetailInstrument>,
        onExit: @escaping (StockDetailInstrument) -> Void = { _ in }
    ) {
        let normalizedInstruments = Self.uniqueInstruments(instruments)

        self.instruments = normalizedInstruments
        self._selection = selection
        self.onExit = onExit
        _orderTransitionController = StateObject(
            wrappedValue: StockDetailShuffleOrderTransitionController()
        )
    }

    var body: some View {
        GeometryReader { geometry in
            let canvasSize = geometry.size
            ZStack(alignment: .topLeading) {
                Color.black

                pagerWithScrollSurface(canvasSize: canvasSize)

                topFrost
            }
            .overlay(alignment: .bottomLeading) {
                StockDetailShuffleSymbolBar(
                    instruments: instruments,
                    currentIndex: selectedIndex,
                    totalWidth: max(canvasSize.width - ShuffleLayout.symbolBarHorizontalInset * 2, 0),
                    onClose: exitToCurrentInstrument,
                    onSelect: { targetIndex in
                        symbolSelectionRequest = targetIndex
                    }
                )
                .padding(.leading, ShuffleLayout.symbolBarHorizontalInset)
                .padding(
                    .bottom,
                    ShuffleLayout.verticalPeek
                        + ShuffleLayout.cardGap
                        + ShuffleLayout.symbolBarBottomInset
                )
            }
            .overlay(alignment: .topLeading) {
                if PreviewRuntime.isUITesting {
                    Text(selection.id)
                        .frame(width: 1, height: 1)
                        .accessibilityIdentifier("stockDetail.shuffle.committedInstrument")
                        .allowsHitTesting(false)
                }
            }
            .frame(width: canvasSize.width, height: canvasSize.height)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("stockDetail.shuffle.root")
        }
        .background(Color.black.ignoresSafeArea())
        .ignoresSafeArea()
        .overlay {
            StockDetailShuffleOrderTransitionLayer(
                controller: orderTransitionController,
                language: language,
                languageStore: demoLanguageStore,
                reduceMotion: reduceMotion
            )
            .ignoresSafeArea()
        }
        .onAppear {
            prepareOrderTransition()
        }
        .onChange(of: selection.id) { _, _ in
            prepareOrderTransition()
        }
    }

    private func updateOrderSwipe(
        for instrument: StockDetailInstrument,
        translation: CGFloat,
        velocity: CGFloat,
        ended: Bool,
        containerWidth: CGFloat
    ) {
        guard instrument.kind != .fund,
              instrument.market.stockOrderMarket != nil else {
            return
        }

        orderTransitionController.handleEntryDrag(
            for: instrument,
            translation: translation,
            velocity: velocity,
            ended: ended,
            containerWidth: containerWidth
        )
    }

    private func prepareOrderTransition() {
        guard instruments.indices.contains(selectedIndex) else {
            orderTransitionController.prepare(symbol: nil)
            return
        }
        let instrument = instruments[selectedIndex]
        guard instrument.kind != .fund,
              instrument.market.stockOrderMarket != nil else {
            orderTransitionController.prepare(symbol: nil)
            return
        }

        orderTransitionController.prepare(
            symbol: StockDetailPageConfigurationFactory.orderSymbolSnapshot(
                for: instrument
            )
        )
    }

    private func pagerWithScrollSurface(canvasSize: CGSize) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            pager(canvasSize: canvasSize)
                .background {
                    StockDetailShuffleScrollPositionProbe()
                }
        }
        // The pager owns the vertical gesture. This gesture-disabled system
        // ScrollView is only the scrollable surface accessibility relies on to
        // bring off-screen card content (such as the quote expansion control)
        // into view when a UI test or VoiceOver asks for it.
        .scrollDisabled(true)
    }

    private func pager(canvasSize: CGSize) -> some View {
        StockDetailShufflePager(
            instruments: instruments,
            currentIndex: selectedIndexBinding,
            symbolSelectionRequest: $symbolSelectionRequest,
            quoteDataIsExpanded: $isQuoteDataExpanded,
            canvasSize: canvasSize,
            onExit: onExit,
            canBeginDrag: { orderTransitionController.canBeginPagerDrag },
            onOrderSwipe: { instrument, translation, velocity, ended in
                updateOrderSwipe(
                    for: instrument,
                    translation: translation,
                    velocity: velocity,
                    ended: ended,
                    containerWidth: canvasSize.width
                )
            }
        )
    }

    /// A soft, screen-wide frost across the top edge. The gradient mask keeps
    /// it strongest at the very top and fades it out just past the card's top
    /// edge, so the card only catches a faint veil instead of a hard band.
    @ViewBuilder
    private var topFrost: some View {
        if selectedIndex > 0 {
            BlurView(style: .systemUltraThinMaterial)
                .opacity(ShuffleLayout.topFrostBlurOpacity)
                .frame(height: ShuffleLayout.topFrostHeight)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private func exitToCurrentInstrument() {
        guard instruments.indices.contains(selectedIndex) else { return }
        onExit(instruments[selectedIndex])
    }

    private var selectedIndex: Int {
        instruments.firstIndex(where: { $0.id == selection.id }) ?? 0
    }

    private var selectedIndexBinding: Binding<Int> {
        Binding(
            get: { selectedIndex },
            set: { newIndex in
                guard instruments.indices.contains(newIndex) else { return }
                selection = instruments[newIndex]
            }
        )
    }

    private static func uniqueInstruments(_ instruments: [StockDetailInstrument]) -> [StockDetailInstrument] {
        var seen = Set<String>()

        return instruments.filter { instrument in
            guard instrument.kind != .fund, instrument.market != .fund else { return false }
            return seen.insert(instrument.id).inserted
        }
    }
}

/// The scroll surface rests at `-adjustedContentInset.top` (its safe-area
/// inset), which would push the fixed pager down. Pin the offset to zero so
/// the card geometry stays unchanged while accessibility scrolling works.
private struct StockDetailShuffleScrollPositionProbe: UIViewRepresentable {
    func makeUIView(context: Context) -> StockDetailShuffleScrollPositionProbeView {
        StockDetailShuffleScrollPositionProbeView()
    }

    func updateUIView(
        _ uiView: StockDetailShuffleScrollPositionProbeView,
        context: Context
    ) {
        uiView.scheduleUpdate()
    }
}

private final class StockDetailShuffleScrollPositionProbeView: UIView {
    private var isUpdateScheduled = false

    override func didMoveToWindow() {
        super.didMoveToWindow()
        scheduleUpdate()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scheduleUpdate()
    }

    func scheduleUpdate() {
        guard !isUpdateScheduled else { return }
        isUpdateScheduled = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            isUpdateScheduled = false
            configureContainingScrollView()
        }
    }

    private func configureContainingScrollView() {
        var ancestor = superview

        while let view = ancestor {
            if let scrollView = view as? UIScrollView {
                if scrollView.contentOffset != .zero {
                    scrollView.setContentOffset(.zero, animated: false)
                }
                return
            }

            ancestor = view.superview
        }
    }
}

/// Owns the high-frequency gesture state. The parent only receives an index
/// update after a page settles, so the symbol bar and the surrounding cover do
/// not invalidate on every drag sample.
private struct StockDetailShufflePager: View {
    let instruments: [StockDetailInstrument]
    @Binding var currentIndex: Int
    @Binding var symbolSelectionRequest: Int?
    @Binding var quoteDataIsExpanded: Bool
    let canvasSize: CGSize
    let onExit: (StockDetailInstrument) -> Void
    let canBeginDrag: () -> Bool
    let onOrderSwipe: (StockDetailInstrument, CGFloat, CGFloat, Bool) -> Void

    @State private var dragOffset: CGFloat = 0
    @State private var gestureAxis: GestureAxis?
    @State private var isSettling = false
    @State private var stagedTargetIndex: Int?
    @State private var transitionOpacity: Double = 1
    @State private var transitionToken = 0
    @StateObject private var configurationCache: StockDetailPageConfigurationCache

    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        instruments: [StockDetailInstrument],
        currentIndex: Binding<Int>,
        symbolSelectionRequest: Binding<Int?>,
        quoteDataIsExpanded: Binding<Bool>,
        canvasSize: CGSize,
        onExit: @escaping (StockDetailInstrument) -> Void,
        canBeginDrag: @escaping () -> Bool,
        onOrderSwipe: @escaping (StockDetailInstrument, CGFloat, CGFloat, Bool) -> Void
    ) {
        self.instruments = instruments
        self._currentIndex = currentIndex
        self._symbolSelectionRequest = symbolSelectionRequest
        self._quoteDataIsExpanded = quoteDataIsExpanded
        self.canvasSize = canvasSize
        self.onExit = onExit
        self.canBeginDrag = canBeginDrag
        self.onOrderSwipe = onOrderSwipe
        _configurationCache = StateObject(wrappedValue: StockDetailPageConfigurationCache())
    }

    var body: some View {
        let cardWidth = max(canvasSize.width - ShuffleLayout.horizontalInset * 2, 0)
        let cardHeight = max(canvasSize.height - ShuffleLayout.verticalPeek * 2 - ShuffleLayout.cardGap * 2, 0)
        let scale = canvasSize.width > 0 ? cardWidth / canvasSize.width : 1
        let stride = cardHeight + ShuffleLayout.cardGap

        StockDetailShuffleCardDeck(
            instruments: instruments,
            currentIndex: currentIndex,
            stagedTargetIndex: stagedTargetIndex,
            quoteDataIsExpanded: $quoteDataIsExpanded,
            canvasSize: canvasSize,
            cardWidth: cardWidth,
            cardHeight: cardHeight,
            scale: scale,
            stride: stride,
            language: language,
            configurationCache: configurationCache,
            onExit: onExit
        )
        .equatable()
        .opacity(transitionOpacity)
        // Move the already-composed deck with one transform. Updating every
        // resident card's offset independently would make every detail-page
        // subtree participate in every drag frame.
        .offset(y: dragOffset)
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
        // The previous card intentionally lives above the viewport. Clip the
        // pager to its own bounds so any page-layer transition cannot move
        // that off-screen card into view.
        .clipped()
        .contentShape(Rectangle())
        // Observe touches at the window level, scoped to this page's bounds.
        // Nested chart/scroll recognizers and overlaid controls must not leave
        // only the card's uncovered edge available for order entry.
        .background(
            pagerGesture(cardHeight: cardHeight, stride: stride)
        )
        .onChange(of: symbolSelectionRequest) { _, targetIndex in
            guard let targetIndex else { return }
            handleSymbolSelection(targetIndex, stride: stride)
            symbolSelectionRequest = nil
        }
    }

    private func pagerGesture(cardHeight: CGFloat, stride: CGFloat) -> StockDetailShufflePagerPanGesture {
        StockDetailShufflePagerPanGesture(canBegin: canBeginDrag) { state, translation, velocity in
            switch state {
            case .began, .changed:
                guard !isSettling else { return }
                if gestureAxis == nil {
                    let direction = translation == .zero ? velocity : translation
                    guard direction != .zero else { return }
                    gestureAxis = abs(direction.height) >= abs(direction.width) ? .vertical : .horizontal
                }
                switch gestureAxis {
                case .vertical:
                    dragOffset = adjustedDragOffset(translation.height)
                case .horizontal:
                    if instruments.indices.contains(currentIndex) {
                        onOrderSwipe(instruments[currentIndex], translation.width, velocity.width, false)
                    }
                case nil:
                    break
                }
            case .ended, .cancelled, .failed:
                let axis = gestureAxis
                gestureAxis = nil
                guard !isSettling else { return }
                let cancelled = state != .ended
                switch axis {
                case .vertical:
                    guard !cancelled else {
                        settleBack()
                        return
                    }
                    let threshold = min(
                        cardHeight * ShuffleLayout.commitThresholdRatio,
                        ShuffleLayout.maximumCommitDistance
                    )
                    let projected = translation.height + velocity.height * 0.2
                    let travel = abs(projected) > abs(translation.height) ? projected : translation.height
                    if travel < -threshold, currentIndex < instruments.count - 1 {
                        settle(to: currentIndex + 1, stride: stride)
                    } else if travel > threshold, currentIndex > 0 {
                        settle(to: currentIndex - 1, stride: stride)
                    } else {
                        settleBack()
                    }
                case .horizontal:
                    if instruments.indices.contains(currentIndex) {
                        // Cancellation (including system interruptions) must
                        // resolve the UIKit transition instead of leaving a
                        // partially presented page attached.
                        onOrderSwipe(
                            instruments[currentIndex],
                            cancelled ? 0 : translation.width,
                            cancelled ? 0 : velocity.width,
                            true
                        )
                    }
                case nil:
                    break
                }
            default:
                break
            }
        }
    }

    private func adjustedDragOffset(_ translation: CGFloat) -> CGFloat {
        let isDraggingPastFirst = translation > 0 && currentIndex == 0
        let isDraggingPastLast = translation < 0 && currentIndex == instruments.count - 1

        if isDraggingPastFirst || isDraggingPastLast {
            return translation * ShuffleLayout.edgeRubberBandFactor
        }

        return translation
    }

    private func settle(to targetIndex: Int, stride: CGFloat) {
        guard instruments.indices.contains(targetIndex), targetIndex != currentIndex else {
            settleBack()
            return
        }

        prewarmConfigurationsForTransition(to: targetIndex)
        let token = beginTransition()
        let finalOffset = targetIndex > currentIndex ? -stride : stride

        if reduceMotion {
            withAnimation(
                .easeOut(duration: ShuffleLayout.reduceMotionDuration),
                completionCriteria: .logicallyComplete
            ) {
                transitionOpacity = 0
            } completion: {
                guard transitionToken == token else { return }

                DispatchQueue.main.async {
                    guard transitionToken == token else { return }
                    updateIndexWithoutAnimation(to: targetIndex)

                    withAnimation(
                        .easeOut(duration: ShuffleLayout.reduceMotionDuration),
                        completionCriteria: .logicallyComplete
                    ) {
                        transitionOpacity = 1
                    } completion: {
                        guard transitionToken == token else { return }
                        isSettling = false
                    }
                }
            }
            return
        }

        withAnimation(
            pageTransitionAnimation,
            completionCriteria: .logicallyComplete
        ) {
            dragOffset = finalOffset
        } completion: {
            guard transitionToken == token else { return }
            enqueueIndexCommit(to: targetIndex, token: token)
        }
    }

    private func settleBack() {
        guard abs(dragOffset) > ShuffleLayout.offsetEpsilon else {
            dragOffset = 0
            return
        }

        let token = beginTransition()

        withAnimation(
            pageTransitionAnimation,
            completionCriteria: .logicallyComplete
        ) {
            dragOffset = 0
        } completion: {
            guard transitionToken == token else { return }

            DispatchQueue.main.async {
                guard transitionToken == token else { return }
                dragOffset = 0
                isSettling = false
            }
        }
    }

    private func handleSymbolSelection(_ targetIndex: Int, stride: CGFloat) {
        guard !isSettling,
              instruments.indices.contains(targetIndex),
              targetIndex != currentIndex else {
            return
        }

        prewarmConfigurationsForTransition(to: targetIndex)
        let token = beginTransition()
        stagedTargetIndex = targetIndex
        let directionOffset = targetIndex > currentIndex ? -1 : 1

        if reduceMotion {
            withAnimation(
                .easeOut(duration: ShuffleLayout.reduceMotionDuration),
                completionCriteria: .logicallyComplete
            ) {
                transitionOpacity = 0
            } completion: {
                guard transitionToken == token else { return }

                DispatchQueue.main.async {
                    guard transitionToken == token else { return }
                    updateIndexWithoutAnimation(to: targetIndex)

                    withAnimation(
                        .easeOut(duration: ShuffleLayout.reduceMotionDuration),
                        completionCriteria: .logicallyComplete
                    ) {
                        transitionOpacity = 1
                    } completion: {
                        guard transitionToken == token else { return }
                        isSettling = false
                    }
                }
            }
            return
        }

        withAnimation(
            pageTransitionAnimation,
            completionCriteria: .logicallyComplete
        ) {
            dragOffset = CGFloat(directionOffset) * stride
        } completion: {
            guard transitionToken == token else { return }
            enqueueIndexCommit(to: targetIndex, token: token)
        }
    }

    private func prewarmConfigurationsForTransition(to targetIndex: Int) {
        // Warm the complete post-commit resident window. These are lightweight
        // configurations only; the deck below owns the five actual card views.
        let indices = Array(
            (-ShuffleLayout.residentCardRadius)...ShuffleLayout.residentCardRadius
        )
            .map { targetIndex + $0 }
            .filter { instruments.indices.contains($0) }

        for index in indices {
            configurationCache.prewarm(
                for: instruments[index],
                includesBelowChartComponents: false
            )
        }
    }

    private func enqueueIndexCommit(to targetIndex: Int, token: Int) {
        DispatchQueue.main.async {
            guard transitionToken == token else { return }
            updateIndexWithoutAnimation(to: targetIndex)
            isSettling = false
        }
    }

    private func beginTransition() -> Int {
        transitionToken += 1
        isSettling = true
        return transitionToken
    }

    private func updateIndexWithoutAnimation(to targetIndex: Int) {
        var transaction = Transaction()
        transaction.animation = nil

        withTransaction(transaction) {
            currentIndex = targetIndex
            dragOffset = 0
            stagedTargetIndex = nil
        }
    }

    private var pageTransitionAnimation: Animation {
        .easeOut(duration: ShuffleLayout.transitionDuration)
    }

    private enum GestureAxis {
        case horizontal
        case vertical
    }
}

/// The deck is equatable so a drag-state change at the pager level updates
/// only the outer transform. Its body is rebuilt when the visible instrument
/// window, language, or staged jump actually changes.
private struct StockDetailShuffleCardItem: Identifiable, Equatable {
    let instrument: StockDetailInstrument
    let relativePosition: Int

    var id: String { instrument.id }
}

private struct StockDetailShuffleCardDeck: View, Equatable {
    let instruments: [StockDetailInstrument]
    let currentIndex: Int
    let stagedTargetIndex: Int?
    @Binding var quoteDataIsExpanded: Bool
    let canvasSize: CGSize
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    let scale: CGFloat
    let stride: CGFloat
    let language: DemoLanguage
    let configurationCache: StockDetailPageConfigurationCache
    let onExit: (StockDetailInstrument) -> Void

    static func == (lhs: StockDetailShuffleCardDeck, rhs: StockDetailShuffleCardDeck) -> Bool {
        lhs.currentIndex == rhs.currentIndex
            && lhs.stagedTargetIndex == rhs.stagedTargetIndex
            && lhs.quoteDataIsExpanded == rhs.quoteDataIsExpanded
            && lhs.instruments.count == rhs.instruments.count
            && lhs.visibleCards == rhs.visibleCards
            && lhs.canvasSize == rhs.canvasSize
            && lhs.cardWidth == rhs.cardWidth
            && lhs.cardHeight == rhs.cardHeight
            && lhs.scale == rhs.scale
            && lhs.stride == rhs.stride
            && lhs.language.rawValue == rhs.language.rawValue
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(visibleCards) { cardItem in
                card(
                    instrument: cardItem.instrument,
                    relativePosition: cardItem.relativePosition
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var visibleCards: [StockDetailShuffleCardItem] {
        Array(
            (-ShuffleLayout.residentCardRadius)...ShuffleLayout.residentCardRadius
        )
        .compactMap { relativePosition in
            guard let index = displayedIndex(for: relativePosition) else { return nil }
            return StockDetailShuffleCardItem(
                instrument: instruments[index],
                relativePosition: relativePosition
            )
        }
    }

    private func card(
        instrument: StockDetailInstrument,
        relativePosition: Int
    ) -> some View {
        let isInteractive = abs(relativePosition) <= ShuffleLayout.interactiveCardRadius
        let slotName: String
        switch relativePosition {
        case -2:
            slotName = "preload.previous"
        case -1:
            slotName = "previous"
        case 1:
            slotName = "next"
        case 2:
            slotName = "preload.next"
        default:
            slotName = "current"
        }

        let pageConfiguration = configurationCache.configuration(
            for: instrument,
            includesBelowChartComponents: false
        )

        return ZStack(alignment: .topLeading) {
            StockDetailPage(
                instrument: instrument,
                presentationMode: .shuffleCard,
                configuration: pageConfiguration,
                quoteDetailsExpansion: $quoteDataIsExpanded,
                onShuffleCardInteraction: { onExit(instrument) }
            )
            .id(instrument.id)
            .frame(width: canvasSize.width, height: canvasSize.height)
            .scaleEffect(scale, anchor: .topLeading)
        }
        .frame(width: cardWidth, height: cardHeight, alignment: .topLeading)
        .background(Color("color-base-1"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: ShuffleLayout.cardCornerRadius,
                style: .continuous
            )
        )
        .contentShape(
            RoundedRectangle(
                cornerRadius: ShuffleLayout.cardCornerRadius,
                style: .continuous
            )
        )
        .onTapGesture {
            onExit(instrument)
        }
        .offset(
            x: ShuffleLayout.horizontalInset,
            y: ShuffleLayout.verticalPeek + ShuffleLayout.cardGap
                + CGFloat(relativePosition) * stride
        )
        .zIndex(relativePosition == 0 ? 2 : 1)
        .allowsHitTesting(isInteractive)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(cardAccessibilityLabel(for: instrument))
        .accessibilityHint(language == .english ? "Opens the full detail page" : "打开完整详情页")
        .accessibilityAddTraits(.isButton)
        .accessibilityHidden(!isInteractive)
        .accessibilityIdentifier("stockDetail.shuffle.card.\(slotName)")
    }

    private func displayedIndex(for relativePosition: Int) -> Int? {
        guard !instruments.isEmpty else { return nil }

        if let stagedTargetIndex {
            let stagedRelativePosition = stagedTargetIndex > currentIndex ? 1 : -1
            if relativePosition == stagedRelativePosition {
                return stagedTargetIndex
            }

            // A two-step code-bar jump can otherwise place the staged target
            // both at its transition slot and at the outer preloaded slot.
            // Keep its identity unique for ForEach diffing.
            if currentIndex + relativePosition == stagedTargetIndex {
                return nil
            }
        }

        let candidate = currentIndex + relativePosition
        return instruments.indices.contains(candidate) ? candidate : nil
    }

    private func cardAccessibilityLabel(for instrument: StockDetailInstrument) -> String {
        language == .english
            ? "Open \(instrument.symbol) detail"
            : "打开 \(instrument.symbol) 详情"
    }
}

private struct StockDetailShuffleSymbolBar: View {
    let instruments: [StockDetailInstrument]
    let currentIndex: Int
    let totalWidth: CGFloat
    let onClose: () -> Void
    let onSelect: (Int) -> Void

    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: ShuffleLayout.symbolBarGap) {
            closeButton

            symbolCapsule
        }
        .frame(width: totalWidth, height: ShuffleLayout.symbolBarHeight, alignment: .leading)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            ZStack {
                glassBackground(shape: Circle())

                Image("stock_detail_shuffle_close")
                    .resizable()
                    .scaledToFit()
                    .frame(width: ShuffleLayout.closeIconSize, height: ShuffleLayout.closeIconSize)
            }
            .frame(width: ShuffleLayout.symbolBarHeight, height: ShuffleLayout.symbolBarHeight)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(language == .english ? "Close" : "关闭")
        .accessibilityIdentifier("stockDetail.shuffle.close")
    }

    private var symbolCapsule: some View {
        let availableWidth = max(totalWidth - ShuffleLayout.symbolBarHeight - ShuffleLayout.symbolBarGap, 0)

        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ShuffleLayout.symbolSpacing) {
                    ForEach(Array(instruments.enumerated()), id: \.element.id) { index, instrument in
                        Button {
                            onSelect(index)
                        } label: {
                            Text(instrument.symbol)
                                .modifier(
                                    CustomFontModifier(
                                        size: ShuffleLayout.symbolFontSize,
                                        font: index == currentIndex ? .bold : .medium,
                                        lineHeight: ShuffleLayout.symbolLineHeight
                                    )
                                )
                                .foregroundColor(
                                    index == currentIndex
                                        ? Color("color-brand-blue")
                                        : Color("color-text-60")
                                )
                                .fixedSize()
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(index == currentIndex ? .isSelected : [])
                        .accessibilityLabel(instrument.symbol)
                        .accessibilityIdentifier("stockDetail.shuffle.symbol.\(instrument.id)")
                        .id(instrument.id)
                    }
                }
                .padding(.horizontal, ShuffleLayout.symbolCapsuleHorizontalPadding)
            }
            .frame(width: capsuleWidth(availableWidth: availableWidth), height: ShuffleLayout.symbolBarHeight)
            .background(glassBackground(shape: Capsule()))
            .clipShape(Capsule())
            .onAppear {
                scrollToCurrent(using: proxy)
            }
            .onChange(of: currentIndex) { _, _ in
                if reduceMotion {
                    scrollToCurrent(using: proxy)
                } else {
                    withAnimation(.easeOut(duration: ShuffleLayout.transitionDuration)) {
                        scrollToCurrent(using: proxy)
                    }
                }
            }
        }
    }

    private func capsuleWidth(availableWidth: CGFloat) -> CGFloat {
        min(availableWidth, max(ShuffleLayout.minimumSymbolCapsuleWidth, estimatedContentWidth + ShuffleLayout.symbolCapsuleHorizontalPadding * 2))
    }

    private var estimatedContentWidth: CGFloat {
        let textWidth = instruments.reduce(CGFloat.zero) { partialResult, instrument in
            partialResult + max(24, CGFloat(instrument.symbol.count) * ShuffleLayout.estimatedCharacterWidth)
        }
        let spacingWidth = CGFloat(max(instruments.count - 1, 0)) * ShuffleLayout.symbolSpacing
        return textWidth + spacingWidth
    }

    private func scrollToCurrent(using proxy: ScrollViewProxy) {
        guard instruments.indices.contains(currentIndex) else { return }
        proxy.scrollTo(instruments[currentIndex].id, anchor: .center)
    }

    @ViewBuilder
    private func glassBackground<S: Shape>(shape: S) -> some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: shape)
                .accessibilityHidden(true)
        } else {
            Color("color-scale-1")
                .opacity(0.92)
                .background(.ultraThinMaterial)
                .clipShape(shape)
                .accessibilityHidden(true)
        }
    }
}

private enum ShuffleLayout {
    // Keep current ±2 resident so the next visible card has already been
    // constructed and laid out before it reaches the one-card preview slot.
    static let residentCardRadius = 2
    static let interactiveCardRadius = 1

    static let horizontalInset: CGFloat = 8
    // Keep the current card below the iPhone 17 Pro Dynamic Island safe area.
    // With an 874-point canvas and an 8-point card gap this yields a
    // 750-point current card: 874 - (54 * 2) - (8 * 2).
    static let verticalPeek: CGFloat = 54
    // The frost fades to nothing just past the card's top edge
    // (verticalPeek + cardGap = 62), so the card only catches its faint tail.
    static let topFrostHeight: CGFloat = verticalPeek + cardGap + 22
    static let topFrostBlurOpacity: CGFloat = 0.15
    static let cardGap: CGFloat = 8
    static let cardCornerRadius: CGFloat = 20

    static let symbolBarHorizontalInset: CGFloat = 16
    static let symbolBarBottomInset: CGFloat = 16
    static let symbolBarHeight: CGFloat = 38
    static let symbolBarGap: CGFloat = 8
    static let closeIconSize: CGFloat = 24
    static let symbolSpacing: CGFloat = 14
    static let symbolCapsuleHorizontalPadding: CGFloat = 14
    static let minimumSymbolCapsuleWidth: CGFloat = 63
    static let symbolFontSize: CGFloat = 14
    static let symbolLineHeight: CGFloat = 20
    static let estimatedCharacterWidth: CGFloat = 8.2

    static let commitThresholdRatio: CGFloat = 0.18
    static let maximumCommitDistance: CGFloat = 140
    static let edgeRubberBandFactor: CGFloat = 0.25
    static let offsetEpsilon: CGFloat = 0.5

    static let transitionDuration: TimeInterval = 0.2
    static let reduceMotionDuration: TimeInterval = 0.15

}

struct StockDetailShuffleView_Previews: PreviewProvider {
    static var previews: some View {
        let sixInstrumentPreview = Array(StockDetailDebugSamples.all.prefix(6))

        Group {
            StockDetailShufflePreviewHost(
                instruments: StockDetailDebugSamples.all,
                initialInstrumentID: StockDetailDebugSamples.all[2].id
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
            .previewDisplayName("Both neighbors")

            StockDetailShufflePreviewHost(
                instruments: StockDetailDebugSamples.all,
                initialInstrumentID: StockDetailDebugSamples.all[0].id
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
            .previewDisplayName("No previous")

            StockDetailShufflePreviewHost(
                instruments: StockDetailDebugSamples.all,
                initialInstrumentID: StockDetailDebugSamples.all[6].id
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
            .previewDisplayName("No next")

            StockDetailShufflePreviewHost(
                instruments: [StockDetailDebugSamples.all[2]],
                initialInstrumentID: StockDetailDebugSamples.all[2].id
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
            .previewDisplayName("Single instrument")

            StockDetailShufflePreviewHost(
                instruments: sixInstrumentPreview,
                initialInstrumentID: sixInstrumentPreview[3].id
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
            .previewDisplayName("Six instruments · middle")

            StockDetailShufflePreviewHost(
                instruments: StockDetailDebugSamples.all,
                initialInstrumentID: StockDetailDebugSamples.all[3].id
            )
            .environment(\.demoLanguage, .english)
            .environmentObject(DemoLanguageStore(initialLanguage: .english))
            .preferredColorScheme(.dark)
            .previewDisplayName("English · Dark")
        }
        .environmentObject(DemoAppearanceStore())
        .previewLayout(.fixed(width: 402, height: 874))

        StockDetailShufflePreviewHost(
            instruments: StockDetailDebugSamples.all,
            initialInstrumentID: StockDetailDebugSamples.all[2].id
        )
        .environment(\.demoLanguage, .english)
        .environmentObject(DemoLanguageStore(initialLanguage: .english))
        .environmentObject(DemoAppearanceStore())
        .preferredColorScheme(.dark)
        .previewLayout(.fixed(width: 440, height: 956))
        .previewDisplayName("iPhone Pro Max · English · Dark")
    }
}

private struct StockDetailShufflePreviewHost: View {
    let instruments: [StockDetailInstrument]

    @State private var selection: StockDetailInstrument

    init(instruments: [StockDetailInstrument], initialInstrumentID: String) {
        self.instruments = instruments
        _selection = State(
            initialValue: instruments.first(where: { $0.id == initialInstrumentID }) ?? instruments[0]
        )
    }

    var body: some View {
        StockDetailShuffleView(
            instruments: instruments,
            selection: $selection
        )
    }
}

// MARK: - Shuffle order transition

/// The recognizer sees touches before nested SwiftUI/UIScrollView gesture
/// arbitration. Its hit region and lifecycle remain owned by Shuffle.
private struct StockDetailShufflePagerPanGesture: UIViewRepresentable {
    let canBegin: () -> Bool
    let onPan: (UIGestureRecognizer.State, CGSize, CGSize) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(canBegin: canBegin, onPan: onPan)
    }

    func makeUIView(context: Context) -> StockDetailShufflePanRegion {
        let region = StockDetailShufflePanRegion()
        let coordinator = context.coordinator
        coordinator.region = region
        region.onWindowChanged = { [weak coordinator] window in
            coordinator?.attach(to: window)
        }
        return region
    }

    func updateUIView(_ uiView: StockDetailShufflePanRegion, context: Context) {
        context.coordinator.canBegin = canBegin
        context.coordinator.onPan = onPan
        context.coordinator.attach(to: uiView.window)
    }

    static func dismantleUIView(_ uiView: StockDetailShufflePanRegion, coordinator: Coordinator) {
        uiView.onWindowChanged = nil
        coordinator.attach(to: nil)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var region: StockDetailShufflePanRegion?
        var canBegin: () -> Bool
        var onPan: (UIGestureRecognizer.State, CGSize, CGSize) -> Void
        private lazy var pan: StockDetailShufflePagePanRecognizer = {
            let recognizer = StockDetailShufflePagePanRecognizer(target: self, action: #selector(drag(_:)))
            recognizer.maximumNumberOfTouches = 1
            recognizer.delegate = self
            return recognizer
        }()

        init(
            canBegin: @escaping () -> Bool,
            onPan: @escaping (UIGestureRecognizer.State, CGSize, CGSize) -> Void
        ) {
            self.canBegin = canBegin
            self.onPan = onPan
        }

        func attach(to window: UIWindow?) {
            guard pan.view !== window else { return }
            pan.view?.removeGestureRecognizer(pan)
            window?.addGestureRecognizer(pan)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard canBegin(), let region, region.window != nil else { return false }
            return region.bounds.contains(touch.location(in: region))
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            return canBegin()
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            // A chart's or scroll view's pan must not prevent the page pan.
            // Taps remain exclusive, so a drag cannot also exit Shuffle.
            otherGestureRecognizer is UIPanGestureRecognizer
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            otherGestureRecognizer is UITapGestureRecognizer
        }

        @objc private func drag(_ recognizer: StockDetailShufflePagePanRecognizer) {
            let translation = recognizer.translationFromTouchDown
            let velocity = recognizer.velocity(in: recognizer.view)
            onPan(
                recognizer.state,
                CGSize(width: translation.x, height: translation.y),
                CGSize(width: velocity.x, height: velocity.y)
            )
        }
    }
}

/// UIPan can begin with zero translation after consuming its recognition
/// distance. Preserve touch-down displacement so a short horizontal drag
/// neither loses that distance nor gets locked to the vertical pager.
private final class StockDetailShufflePagePanRecognizer: UIPanGestureRecognizer {
    private var touchOrigin: CGPoint?
    private var touchPosition: CGPoint?

    var translationFromTouchDown: CGPoint {
        guard let touchOrigin, let touchPosition else { return translation(in: view) }
        return CGPoint(x: touchPosition.x - touchOrigin.x, y: touchPosition.y - touchOrigin.y)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if touchOrigin == nil, let touch = touches.first {
            touchOrigin = touch.location(in: view)
            touchPosition = touchOrigin
        }
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        touchPosition = touches.first?.location(in: view)
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        touchPosition = touches.first?.location(in: view)
        super.touchesEnded(touches, with: event)
    }

    override func reset() {
        super.reset()
        touchOrigin = nil
        touchPosition = nil
    }
}

private final class StockDetailShufflePanRegion: UIView {
    var onWindowChanged: ((UIWindow?) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChanged?(window)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { false }
}

/// A real UIKit presentation owns the complete route, including interactive
/// cancellation and appearance callbacks. Shuffle is never translated or
/// removed from the presenting hierarchy.
@MainActor
private final class StockDetailShuffleOrderTransitionController: NSObject, ObservableObject,
    UIViewControllerTransitioningDelegate {
    @Published private(set) var debugProgress: CGFloat = 0
    @Published private(set) var debugDuration: TimeInterval?
    private(set) var debugRenderedDragSamples = 0
    private(set) var debugRenderedDragSpan: CGFloat = 0
    private var firstRenderedDragProgress: CGFloat?

    private var phase: StockDetailShuffleOrderTransitionPhase = .idle
    private weak var container: StockDetailShuffleOrderTransitionViewController?
    private var pendingSymbol: StockOrderSymbol?
    private var activeHost: StockDetailShuffleOrderPageController?
    private var interaction: StockDetailShuffleRouteInteraction?
    private var preparationTask: Task<Void, Never>?
    private var releaseUptime: TimeInterval?
    private var language: DemoLanguage = .simplifiedChinese
    private var languageStore: DemoLanguageStore?
    private var reduceMotion = false

    func updateEnvironment(
        language: DemoLanguage,
        languageStore: DemoLanguageStore,
        reduceMotion: Bool
    ) {
        let changed = self.language != language || self.languageStore !== languageStore
        self.language = language
        self.languageStore = languageStore
        self.reduceMotion = reduceMotion
        if changed {
            container?.preparedHost?.updateLanguage(language)
            activeHost?.updateLanguage(language)
        }
    }

    func attach(to container: StockDetailShuffleOrderTransitionViewController) {
        self.container = container
        container.onReady = { [weak self] in self?.schedulePreparation() }
        schedulePreparation()
    }

    func prepare(symbol: StockOrderSymbol?) {
        pendingSymbol = symbol
        schedulePreparation()
    }

    private func schedulePreparation() {
        preparationTask?.cancel()
        guard phase == .idle else { return }
        preparationTask = Task { @MainActor [weak self] in
            // Let the Shuffle card's layout finish before warming the order
            // form. No page construction is scheduled for individual pan samples.
            await Task.yield()
            guard !Task.isCancelled, let self, self.phase == .idle,
                  let container = self.container, container.viewIfLoaded?.window != nil,
                  container.view.bounds.width > 0 else { return }
            guard let symbol = self.pendingSymbol else {
                container.clearPreparedHost()
                return
            }
            if container.preparedHost?.symbol == symbol { return }
            guard let host = self.makeHost(symbol: symbol) else { return }
            container.stage(host)
        }
    }

    private func makeHost(symbol: StockOrderSymbol) -> StockDetailShuffleOrderPageController? {
        guard let languageStore else { return nil }
        let host = StockDetailShuffleOrderPageController(
            symbol: symbol, language: language, languageStore: languageStore, route: self
        )
        host.modalPresentationStyle = .custom
        host.transitioningDelegate = self
        return host
    }

    func handleEntryDrag(
        for instrument: StockDetailInstrument,
        translation: CGFloat,
        velocity: CGFloat,
        ended: Bool,
        containerWidth: CGFloat
    ) {
        guard instrument.kind != .fund, instrument.market.stockOrderMarket != nil,
              let container, container.viewIfLoaded?.window != nil else { return }

        if phase == .idle {
            guard translation < 0, container.presentedViewController == nil else { return }
            preparationTask?.cancel()
            let symbol: StockOrderSymbol
            if let pendingSymbol, pendingSymbol.id == instrument.symbol {
                symbol = pendingSymbol
            } else {
                symbol = StockDetailPageConfigurationFactory.orderSymbolSnapshot(for: instrument)
            }
            let host: StockDetailShuffleOrderPageController
            if let prepared = container.takePreparedHost(matching: symbol) {
                host = prepared
            } else if let fresh = makeHost(symbol: symbol) {
                host = fresh
            } else {
                return
            }
            activeHost = host
            interaction = StockDetailShuffleRouteInteraction()
            phase = .dragging
            if PreviewRuntime.isUITesting {
                debugProgress = 0
                debugDuration = nil
                debugRenderedDragSamples = 0
                debugRenderedDragSpan = 0
                firstRenderedDragProgress = nil
            }
            host.view.isUserInteractionEnabled = false
            container.present(host, animated: true)
        }

        guard phase == .dragging else { return }
        let width = max(container.view.bounds.width, containerWidth, 1)
        interaction?.setProgress(min(1, max(0, -translation / width)))
        if PreviewRuntime.isUITesting,
           let renderedX = activeHost?.view.layer.presentation()?.affineTransform().tx {
            let renderedProgress = 1 - renderedX / width
            if renderedProgress > 0.01 && renderedProgress < 0.99 {
                debugRenderedDragSamples += 1
                if let firstRenderedDragProgress {
                    debugRenderedDragSpan = max(debugRenderedDragSpan, abs(renderedProgress - firstRenderedDragProgress))
                } else {
                    firstRenderedDragProgress = renderedProgress
                }
            }
        }
        guard ended else { return }
        settleInteraction(commit: translation < 0, velocity: -velocity, width: width)
    }

    func handleReturnPan(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        guard let host = activeHost else { return }
        let width = max(host.view.bounds.width, 1)
        // Window coordinates stay fixed while the page itself moves.
        let translation = recognizer.translation(in: host.view.window).x
        let velocity = recognizer.velocity(in: host.view.window).x
        switch recognizer.state {
        case .began:
            guard phase == .presented, host.allowsReturn,
                  host.presentedViewController == nil else { return }
            host.view.endEditing(true)
            phase = .returnDragging
            interaction = StockDetailShuffleRouteInteraction()
            host.dismiss(animated: true)
            interaction?.setProgress(min(1, max(0, translation / width)))
        case .changed:
            guard phase == .returnDragging else { return }
            interaction?.setProgress(min(1, max(0, translation / width)))
        case .ended:
            guard phase == .returnDragging else { return }
            interaction?.setProgress(min(1, max(0, translation / width)))
            let projected = translation + velocity * 0.2
            settleInteraction(
                commit: max(translation, projected) >= 120,
                velocity: velocity,
                width: width
            )
        case .cancelled, .failed:
            guard phase == .returnDragging else { return }
            settleInteraction(commit: false, velocity: 0, width: width)
        default:
            break
        }
    }

    var canBeginPagerDrag: Bool {
        phase == .idle && container?.viewIfLoaded?.window != nil
            && container?.presentedViewController == nil
    }

    var canBeginReturn: Bool { phase == .presented }

    func dismissFromOrder() {
        guard phase == .presented, let activeHost, activeHost.allowsReturn,
              activeHost.presentedViewController == nil else { return }
        activeHost.view.endEditing(true)
        phase = .finishing
        interaction = nil
        activeHost.dismiss(animated: true)
    }

    private func settleInteraction(commit: Bool, velocity: CGFloat, width: CGFloat) {
        phase = .finishing
        releaseUptime = ProcessInfo.processInfo.systemUptime
        interaction?.settle(commit: commit, velocity: velocity, width: width, reduceMotion: reduceMotion)
    }

    private func transitionEnded(presenting: Bool, completed: Bool) {
        interaction = nil
        let remainsPresented = presenting == completed
        phase = remainsPresented ? .presented : .idle
        if remainsPresented {
            activeHost?.view.isUserInteractionEnabled = true
            if PreviewRuntime.isUITesting {
                debugProgress = 1
                if presenting {
                    debugDuration = releaseUptime.map { ProcessInfo.processInfo.systemUptime - $0 }
                }
            }
        } else {
            activeHost = nil
            releaseUptime = nil
            // A fresh order page is prepared from Shuffle's symbol, never
            // from edits made inside the previous order session.
            schedulePreparation()
        }
    }

    func detach() {
        preparationTask?.cancel()
        preparationTask = nil
        interaction?.cancel()
        interaction = nil
        activeHost?.dismiss(animated: false)
        activeHost = nil
        container?.clearPreparedHost()
        container?.onReady = nil
        container = nil
        phase = .idle
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        makeAnimator(presenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        makeAnimator(presenting: false)
    }

    private func makeAnimator(presenting: Bool) -> StockDetailShuffleRouteAnimator {
        StockDetailShuffleRouteAnimator(presenting: presenting, reduceMotion: reduceMotion) { [weak self] completed in
            self?.transitionEnded(presenting: presenting, completed: completed)
        }
    }

    func interactionControllerForPresentation(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        interaction
    }

    func interactionControllerForDismissal(
        using animator: UIViewControllerAnimatedTransitioning
    ) -> UIViewControllerInteractiveTransitioning? {
        interaction
    }

    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        StockDetailShuffleOrderPresentationController(
            presentedViewController: presented, presenting: presenting
        )
    }
}

/// Buffers the first pan sample (and even a very short completed gesture)
/// until UIKit has installed its transition context.
@MainActor
private final class StockDetailShuffleRouteInteraction: UIPercentDrivenInteractiveTransition {
    private var isReady = false
    private var pendingProgress: CGFloat = 0
    private var pendingCommit: Bool?

    func setProgress(_ progress: CGFloat) {
        pendingProgress = progress
        if isReady { update(progress) }
    }

    override func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        super.startInteractiveTransition(transitionContext)
        isReady = true
        update(pendingProgress)
        if let pendingCommit { completeInteraction(commit: pendingCommit) }
    }

    func settle(commit: Bool, velocity: CGFloat, width: CGFloat, reduceMotion: Bool) {
        // UIKit continues the same animation from its current fraction.
        // Speed follows the release velocity; there is no second offset jump
        // or fixed-duration animation for a tiny remaining distance.
        completionCurve = .easeOut
        completionSpeed = reduceMotion ? 1 : min(1.8, max(0.8, abs(velocity) / width * 0.38))
        pendingCommit = commit
        if isReady { completeInteraction(commit: commit) }
    }

    private func completeInteraction(commit: Bool) {
        if commit { finish() } else { cancel() }
    }
}

@MainActor
private final class StockDetailShuffleRouteAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let presenting: Bool
    private let reduceMotion: Bool
    private let completion: (Bool) -> Void
    private var animator: UIViewPropertyAnimator?

    init(presenting: Bool, reduceMotion: Bool, completion: @escaping (Bool) -> Void) {
        self.presenting = presenting
        self.reduceMotion = reduceMotion
        self.completion = completion
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        reduceMotion ? 0.15 : 0.38
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        interruptibleAnimator(using: transitionContext).startAnimation()
    }

    func interruptibleAnimator(
        using context: UIViewControllerContextTransitioning
    ) -> UIViewImplicitlyAnimating {
        if let animator { return animator }
        let key: UITransitionContextViewControllerKey = presenting ? .to : .from
        guard let page = context.viewController(forKey: key) else {
            preconditionFailure("Order route requires its presented page")
        }
        let pageView = page.view!
        let canvas = context.containerView
        // Establish geometry once, before applying any transform. Never set
        // frame while a translated view is being dragged or animated.
        pageView.transform = .identity
        if presenting {
            pageView.frame = context.finalFrame(for: page)
            canvas.addSubview(pageView)
            pageView.layoutIfNeeded()
        }
        let offscreen = CGAffineTransform(translationX: canvas.bounds.width, y: 0)
        if reduceMotion {
            pageView.alpha = presenting ? 0 : 1
        } else {
            pageView.transform = presenting ? offscreen : .identity
        }
        let animation = UIViewPropertyAnimator(
            duration: transitionDuration(using: context),
            dampingRatio: 1
        ) {
            if self.reduceMotion {
                pageView.alpha = self.presenting ? 1 : 0
            } else {
                pageView.transform = self.presenting ? .identity : offscreen
            }
        }
        animation.scrubsLinearly = true
        animation.addCompletion { [weak self] _ in
            guard let self else { return }
            let completed = !context.transitionWasCancelled
            pageView.transform = .identity
            pageView.alpha = 1
            if self.presenting && !completed { pageView.removeFromSuperview() }
            context.completeTransition(completed)
            self.animator = nil
            self.completion(completed)
        }
        animator = animation
        return animation
    }
}

private final class StockDetailShuffleOrderPresentationController: UIPresentationController {
    override var shouldRemovePresentersView: Bool { false }
    override var shouldPresentInFullscreen: Bool { true }
    override var frameOfPresentedViewInContainerView: CGRect { containerView?.bounds ?? .zero }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        // The host root is the single moving surface. Updating bounds and
        // center is safe with a transform; updating frame would change layout
        // in response to the in-flight animation.
        guard let presentedView, let containerView else { return }
        let bounds = containerView.bounds
        if presentedView.bounds.size != bounds.size {
            presentedView.bounds = CGRect(origin: .zero, size: bounds.size)
            presentedView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        }
    }
}

private struct StockDetailShuffleOrderTransitionLayer: UIViewControllerRepresentable {
    let controller: StockDetailShuffleOrderTransitionController
    let language: DemoLanguage
    let languageStore: DemoLanguageStore
    let reduceMotion: Bool

    func makeCoordinator() -> StockDetailShuffleOrderTransitionController { controller }

    func makeUIViewController(context: Context) -> StockDetailShuffleOrderTransitionViewController {
        let viewController = StockDetailShuffleOrderTransitionViewController()
        controller.updateEnvironment(language: language, languageStore: languageStore, reduceMotion: reduceMotion)
        controller.attach(to: viewController)
        return viewController
    }

    func updateUIViewController(
        _ viewController: StockDetailShuffleOrderTransitionViewController, context: Context
    ) {
        controller.updateEnvironment(language: language, languageStore: languageStore, reduceMotion: reduceMotion)
    }

    static func dismantleUIViewController(
        _ viewController: StockDetailShuffleOrderTransitionViewController,
        coordinator: StockDetailShuffleOrderTransitionController
    ) {
        coordinator.detach()
    }
}

@MainActor
private final class StockDetailShuffleOrderTransitionViewController: UIViewController {
    var onReady: (() -> Void)?
    private(set) var preparedHost: StockDetailShuffleOrderPageController?
    private let stagingView = UIView()

    override func loadView() {
        view = StockDetailShuffleOrderContainerView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        stagingView.isHidden = true
        stagingView.isUserInteractionEnabled = false
        stagingView.accessibilityElementsHidden = true
        view.addSubview(stagingView)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onReady?()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let size = view.bounds.size
        // A hidden, full-size staging surface preserves the real safe area.
        // Offscreen staging would give SwiftUI a different safe-area geometry
        // and force it to lay out again at the first visible pan sample.
        stagingView.frame = view.bounds
        if let preparedHost, preparedHost.view.bounds.size != size {
            preparedHost.view.frame = stagingView.bounds
        }
    }

    func stage(_ host: StockDetailShuffleOrderPageController) {
        clearPreparedHost()
        preparedHost = host
        addChild(host)
        stagingView.addSubview(host.view)
        host.view.frame = CGRect(origin: .zero, size: view.bounds.size)
        host.didMove(toParent: self)
        view.setNeedsLayout()
        view.layoutIfNeeded()
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
    }

    func takePreparedHost(matching symbol: StockOrderSymbol) -> StockDetailShuffleOrderPageController? {
        guard let host = preparedHost, host.symbol == symbol else {
            clearPreparedHost()
            return nil
        }
        clearPreparedHost()
        return host
    }

    func clearPreparedHost() {
        guard let host = preparedHost else { return }
        host.willMove(toParent: nil)
        host.view.removeFromSuperview()
        host.removeFromParent()
        preparedHost = nil
    }
}

private final class StockDetailShuffleOrderContainerView: UIView {
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { false }
}

@MainActor
private final class StockDetailShuffleOrderPageController:
    UIHostingController<StockDetailShuffleOrderHostView>, UIGestureRecognizerDelegate {
    let symbol: StockOrderSymbol
    var allowsReturn = true
    private weak var route: StockDetailShuffleOrderTransitionController?
    private let languageStore: DemoLanguageStore

    init(
        symbol: StockOrderSymbol,
        language: DemoLanguage,
        languageStore: DemoLanguageStore,
        route: StockDetailShuffleOrderTransitionController
    ) {
        self.symbol = symbol
        self.languageStore = languageStore
        self.route = route
        super.init(rootView: StockDetailShuffleOrderHostView(
            symbol: symbol, language: language, languageStore: languageStore,
            route: route, onReturnAvailabilityChanged: { _ in }
        ))
        rootView.onReturnAvailabilityChanged = { [weak self] allowed in
            self?.allowsReturn = allowed
        }
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) { fatalError("init(coder:) is unsupported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "color-base-1")
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(returnPan(_:)))
        edgePan.edges = .left
        edgePan.delegate = self
        view.addGestureRecognizer(edgePan)
    }

    func updateLanguage(_ language: DemoLanguage) {
        guard rootView.language != language else { return }
        rootView.language = language
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard allowsReturn, presentedViewController == nil, route?.canBeginReturn == true,
              let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = pan.velocity(in: view.window)
        return velocity.x > abs(velocity.y)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        // Give the screen edge the same priority over nested horizontal
        // content as a navigation controller's interactive pop gesture.
        otherGestureRecognizer is UIPanGestureRecognizer
    }

    @objc private func returnPan(_ recognizer: UIScreenEdgePanGestureRecognizer) {
        route?.handleReturnPan(recognizer)
    }

    override func accessibilityPerformEscape() -> Bool {
        guard allowsReturn, presentedViewController == nil, route?.canBeginReturn == true else { return false }
        route?.dismissFromOrder()
        return true
    }
}

private struct StockDetailShuffleOrderHostView: View {
    let symbol: StockOrderSymbol
    var language: DemoLanguage
    let languageStore: DemoLanguageStore
    let route: StockDetailShuffleOrderTransitionController
    var onReturnAvailabilityChanged: (Bool) -> Void

    var body: some View {
        StockOrderDemoView(
            initialSelection: symbol,
            onExit: { [weak route] in route?.dismissFromOrder() },
            onExternalReturnAvailabilityChanged: onReturnAvailabilityChanged
        )
        .environmentObject(languageStore)
        .environment(\.demoLanguage, language)
        .overlay(alignment: .topLeading) {
            if PreviewRuntime.isUITesting {
                StockDetailShuffleOrderRouteDiagnostics(route: route)
            }
        }
    }
}

private struct StockDetailShuffleOrderRouteDiagnostics: View {
    @ObservedObject var route: StockDetailShuffleOrderTransitionController

    var body: some View {
        VStack(spacing: 0) {
            Text(String(format: "%.3f", route.debugProgress))
                .accessibilityIdentifier("stockDetail.shuffle.orderTransition.progress")
            Text(String(format: "%.3f", route.debugDuration ?? -1))
                .accessibilityIdentifier("stockDetail.shuffle.orderTransition.duration")
            Text("\(route.debugRenderedDragSamples)")
                .accessibilityIdentifier("stockDetail.shuffle.orderTransition.renderedDragSamples")
            Text(String(format: "%.3f", route.debugRenderedDragSpan))
                .accessibilityIdentifier("stockDetail.shuffle.orderTransition.renderedDragSpan")
        }
        .frame(width: 1, height: 1)
        .opacity(0.01)
        .allowsHitTesting(false)
    }
}
