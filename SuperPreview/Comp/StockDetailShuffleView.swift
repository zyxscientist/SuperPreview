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
            .allowsHitTesting(orderTransitionController.isInteractiveLayerActive)
        }
        .overlay(alignment: .topLeading) {
            if PreviewRuntime.isUITesting, orderTransitionController.isActive {
                VStack(spacing: 0) {
                    Text(String(format: "%.3f", orderTransitionController.debugProgress))
                        .accessibilityIdentifier("stockDetail.shuffle.orderTransition.progress")
                    Text(String(format: "%.3f", orderTransitionController.debugDuration ?? -1))
                        .accessibilityIdentifier("stockDetail.shuffle.orderTransition.duration")
                }
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .allowsHitTesting(false)
            }
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
        guard instruments.indices.contains(selectedIndex) else { return }
        let instrument = instruments[selectedIndex]
        guard instrument.kind != .fund,
              instrument.market.stockOrderMarket != nil else {
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
        onOrderSwipe: @escaping (StockDetailInstrument, CGFloat, CGFloat, Bool) -> Void
    ) {
        self.instruments = instruments
        self._currentIndex = currentIndex
        self._symbolSelectionRequest = symbolSelectionRequest
        self._quoteDataIsExpanded = quoteDataIsExpanded
        self.canvasSize = canvasSize
        self.onExit = onExit
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
        // Capture the pager drag before the card's tap gesture. This keeps a
        // horizontal order transition from being mistaken for the card tap
        // that exits Shuffle, while taps still fall through when the drag
        // gesture does not begin.
        .highPriorityGesture(
            pagerGesture(cardHeight: cardHeight, stride: stride)
        )
        .onChange(of: symbolSelectionRequest) { _, targetIndex in
            guard let targetIndex else { return }
            handleSymbolSelection(targetIndex, stride: stride)
            symbolSelectionRequest = nil
        }
    }

    private func pagerGesture(cardHeight: CGFloat, stride: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: ShuffleLayout.gestureMinimumDistance)
            .onChanged { value in
                guard !isSettling else { return }

                if gestureAxis == nil {
                    let horizontalDistance = abs(value.translation.width)
                    let verticalDistance = abs(value.translation.height)

                    guard max(horizontalDistance, verticalDistance) >= ShuffleLayout.gestureLockDistance else {
                        return
                    }

                    gestureAxis = verticalDistance >= horizontalDistance ? .vertical : .horizontal
                }

                guard let gestureAxis else { return }

                switch gestureAxis {
                case .vertical:
                    dragOffset = adjustedDragOffset(value.translation.height)
                case .horizontal:
                    if instruments.indices.contains(currentIndex) {
                        onOrderSwipe(
                            instruments[currentIndex],
                            value.translation.width,
                            value.velocity.width,
                            false
                        )
                    }
                }
            }
            .onEnded { value in
                guard !isSettling else {
                    gestureAxis = nil
                    return
                }

                let axis = gestureAxis
                gestureAxis = nil

                guard let axis else {
                    dragOffset = 0
                    return
                }

                switch axis {
                case .vertical:
                    let threshold = min(
                        cardHeight * ShuffleLayout.commitThresholdRatio,
                        ShuffleLayout.maximumCommitDistance
                    )
                    let translation = value.translation.height
                    let predictedTranslation = value.predictedEndTranslation.height
                    let projectedTranslation = abs(predictedTranslation) > abs(translation)
                        ? predictedTranslation
                        : translation

                    if projectedTranslation < -threshold, currentIndex < instruments.count - 1 {
                        settle(to: currentIndex + 1, stride: stride)
                    } else if projectedTranslation > threshold, currentIndex > 0 {
                        settle(to: currentIndex - 1, stride: stride)
                    } else {
                        settleBack()
                    }
                case .horizontal:
                    if instruments.indices.contains(currentIndex) {
                        onOrderSwipe(
                            instruments[currentIndex],
                            value.translation.width,
                            value.velocity.width,
                            true
                        )
                    }
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

    static let gestureMinimumDistance: CGFloat = 4
    static let gestureLockDistance: CGFloat = 6
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

/// The order page is hosted in UIKit so its outer transform can be updated
/// without invalidating the Shuffle SwiftUI tree on every drag sample.
@MainActor
private final class StockDetailShuffleOrderTransitionController: ObservableObject {
    @Published private(set) var phase: StockDetailShuffleOrderTransitionPhase = .idle
    @Published private(set) var debugProgress: CGFloat = 0
    @Published private(set) var debugDuration: TimeInterval?

    private weak var container: StockDetailShuffleOrderTransitionViewController?
    private var preparedSymbol: StockOrderSymbol?
    private var activeSymbol: StockOrderSymbol?
    private var pendingSymbol: StockOrderSymbol?
    private var currentOffset: CGFloat = 0
    private var currentWidth: CGFloat = 0
    private var transitionStartUptime: TimeInterval?
    private var transitionToken = 0
    private var isReduceMotionEnabled = false
    private var language: DemoLanguage = .simplifiedChinese
    private var languageStore: DemoLanguageStore?
    private let diagnostics = StockDetailShuffleOrderTransitionDiagnostics()

    var isActive: Bool {
        phase != .idle
    }

    /// The overlay must not steal the original Shuffle drag while the order
    /// page is still entering. It becomes interactive only after the page is
    /// fully presented, or while its own return gesture is in progress.
    var isInteractiveLayerActive: Bool {
        phase == .presented || phase == .returnDragging
    }

    func updateEnvironment(
        language: DemoLanguage,
        languageStore: DemoLanguageStore,
        reduceMotion: Bool
    ) {
        let languageChanged = self.language != language
        self.language = language
        self.languageStore = languageStore
        isReduceMotionEnabled = reduceMotion

        if languageChanged {
            container?.updateHostEnvironment(language: language, languageStore: languageStore)
        }
    }

    func attach(to container: StockDetailShuffleOrderTransitionViewController) {
        self.container = container
        container.onRequestDismiss = { [weak self] in
            self?.dismissFromOrder()
        }

        if let pendingSymbol {
            container.prepare(
                symbol: pendingSymbol,
                language: language,
                languageStore: languageStore,
                onExternalReturnDrag: { [weak self] translation, velocity, projected, ended in
                    self?.handleReturnDrag(
                        translation: translation,
                        velocity: velocity,
                        projectedTranslation: projected,
                        ended: ended
                    )
                }
            )
            preparedSymbol = pendingSymbol
        }

        if phase != .idle, let activeSymbol {
            container.prepare(
                symbol: activeSymbol,
                language: language,
                languageStore: languageStore,
                onExternalReturnDrag: { [weak self] translation, velocity, projected, ended in
                    self?.handleReturnDrag(
                        translation: translation,
                        velocity: velocity,
                        projectedTranslation: projected,
                        ended: ended
                    )
                }
            )
            container.setOffset(currentOffset)
            container.setInteractive(isInteractiveLayerActive)
        }
    }

    func prepare(symbol: StockOrderSymbol) {
        pendingSymbol = symbol

        guard phase == .idle else { return }
        guard preparedSymbol != symbol || container?.hasOrderHost != true else { return }

        preparedSymbol = symbol
        container?.prepare(
            symbol: symbol,
            language: language,
            languageStore: languageStore,
            onExternalReturnDrag: { [weak self] translation, velocity, projected, ended in
                self?.handleReturnDrag(
                    translation: translation,
                    velocity: velocity,
                    projectedTranslation: projected,
                    ended: ended
                )
            }
        )
    }

    func handleEntryDrag(
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

        guard translation < 0 || phase == .dragging else { return }

        if phase == .idle {
            let symbol: StockOrderSymbol
            if let preparedSymbol,
               preparedSymbol.id == instrument.symbol {
                symbol = preparedSymbol
            } else {
                symbol = StockDetailPageConfigurationFactory.orderSymbolSnapshot(for: instrument)
            }
            beginEntry(with: symbol, containerWidth: containerWidth)
        }

        guard phase == .dragging else { return }

        currentWidth = max(containerWidth, 0)
        currentOffset = offset(for: translation, width: currentWidth)
        container?.setOffset(currentOffset)

        guard ended else { return }

        if translation < 0 {
            finishEntry(velocity: velocity)
        } else {
            cancelEntry()
        }
    }

    func handleReturnDrag(
        translation: CGFloat,
        velocity: CGFloat,
        projectedTranslation: CGFloat,
        ended: Bool
    ) {
        guard phase == .presented || phase == .returnDragging else { return }

        if phase == .presented {
            stopAnimationPreservingPresentation()
            phase = .returnDragging
            container?.setInteractive(true)
        }

        guard phase == .returnDragging else { return }

        currentWidth = max(container?.view.bounds.width ?? currentWidth, 0)
        currentOffset = min(currentWidth, max(0, translation))
        container?.setOffset(currentOffset)

        guard ended else { return }

        let shouldDismiss = max(translation, projectedTranslation) >= 120
        if shouldDismiss {
            finishReturn(velocity: max(velocity, 0))
        } else {
            animateBackToPresented()
        }
    }

    func dismissFromOrder() {
        guard phase == .presented || phase == .returnDragging else { return }
        stopAnimationPreservingPresentation()
        phase = .finishing
        container?.setInteractive(false)

        guard !isReduceMotionEnabled else {
            removeOrderHost()
            return
        }

        animateToEnd(
            width: max(container?.view.bounds.width ?? currentWidth, 0),
            velocity: 0
        ) { [weak self] in
            self?.removeOrderHost()
        }
    }

    private func beginEntry(with symbol: StockOrderSymbol, containerWidth: CGFloat) {
        stopAnimationPreservingPresentation()
        transitionToken &+= 1
        activeSymbol = symbol
        pendingSymbol = symbol
        preparedSymbol = symbol
        currentWidth = max(containerWidth, 0)
        currentOffset = currentWidth
        debugProgress = 0
        debugDuration = nil
        transitionStartUptime = ProcessInfo.processInfo.systemUptime
        phase = .dragging

        container?.prepare(
            symbol: symbol,
            language: language,
            languageStore: languageStore,
            onExternalReturnDrag: { [weak self] translation, velocity, projected, ended in
                self?.handleReturnDrag(
                    translation: translation,
                    velocity: velocity,
                    projectedTranslation: projected,
                    ended: ended
                )
            }
        )
        container?.setInteractive(false)
        container?.setOffset(currentOffset)
        diagnostics.start(with: container)
    }

    private func finishEntry(velocity: CGFloat) {
        guard phase == .dragging else { return }
        phase = .finishing
        container?.setInteractive(false)

        guard !isReduceMotionEnabled else {
            container?.setOffset(0)
            completeEntry()
            return
        }

        animateToEnd(width: 0, velocity: velocity) { [weak self] in
            self?.completeEntry()
        }
    }

    private func cancelEntry() {
        guard phase == .dragging else { return }
        phase = .finishing
        container?.setInteractive(false)

        guard !isReduceMotionEnabled else {
            removeOrderHost()
            return
        }

        animateToEnd(width: max(container?.view.bounds.width ?? currentWidth, 0), velocity: 0) { [weak self] in
            self?.removeOrderHost()
        }
    }

    private func finishReturn(velocity: CGFloat) {
        guard phase == .returnDragging else { return }
        phase = .finishing
        container?.setInteractive(false)

        guard !isReduceMotionEnabled else {
            removeOrderHost()
            return
        }

        animateToEnd(
            width: max(container?.view.bounds.width ?? currentWidth, 0),
            velocity: velocity
        ) { [weak self] in
            self?.removeOrderHost()
        }
    }

    private func animateBackToPresented() {
        phase = .finishing
        container?.setInteractive(false)

        guard !isReduceMotionEnabled else {
            container?.setOffset(0)
            phase = .presented
            container?.setInteractive(true)
            return
        }

        animateToEnd(width: 0, velocity: 0) { [weak self] in
            guard let self else { return }
            self.phase = .presented
            self.container?.setInteractive(true)
        }
    }

    private func animateToEnd(
        width targetWidth: CGFloat,
        velocity: CGFloat,
        completion: @escaping () -> Void
    ) {
        let target = max(targetWidth, 0)
        transitionToken &+= 1
        let token = transitionToken

        container?.animate(
            to: target,
            velocity: velocity,
            reduceMotion: isReduceMotionEnabled
        ) { [weak self] in
            guard let self, self.transitionToken == token else { return }
            self.currentOffset = target
            completion()
        }
    }

    private func completeEntry() {
        currentOffset = 0
        phase = .presented
        container?.setOffset(0)
        container?.setInteractive(true)
        debugProgress = 1
        debugDuration = transitionStartUptime.map {
            ProcessInfo.processInfo.systemUptime - $0
        }
        diagnostics.stop()
    }

    private func removeOrderHost() {
        transitionToken &+= 1
        diagnostics.stop()
        container?.stopAnimationPreservingPresentation()
        container?.removeOrderHost()
        activeSymbol = nil
        currentOffset = 0
        phase = .idle
        debugProgress = 0
        debugDuration = nil
        transitionStartUptime = nil
    }

    @discardableResult
    private func stopAnimationPreservingPresentation() -> CGFloat {
        let position = container?.stopAnimationPreservingPresentation() ?? currentOffset
        currentOffset = position
        return position
    }

    private func offset(for translation: CGFloat, width: CGFloat) -> CGFloat {
        min(width, max(0, width + translation))
    }
}

private struct StockDetailShuffleOrderTransitionLayer: UIViewControllerRepresentable {
    let controller: StockDetailShuffleOrderTransitionController
    let language: DemoLanguage
    let languageStore: DemoLanguageStore
    let reduceMotion: Bool

    func makeUIViewController(context: Context) -> StockDetailShuffleOrderTransitionViewController {
        let viewController = StockDetailShuffleOrderTransitionViewController()
        controller.updateEnvironment(
            language: language,
            languageStore: languageStore,
            reduceMotion: reduceMotion
        )
        controller.attach(to: viewController)
        return viewController
    }

    func updateUIViewController(
        _ viewController: StockDetailShuffleOrderTransitionViewController,
        context: Context
    ) {
        controller.updateEnvironment(
            language: language,
            languageStore: languageStore,
            reduceMotion: reduceMotion
        )
    }

    static func dismantleUIViewController(
        _ viewController: StockDetailShuffleOrderTransitionViewController,
        coordinator: ()
    ) {
        viewController.removeOrderHost()
    }
}

@MainActor
private final class StockDetailShuffleOrderTransitionViewController: UIViewController {
    var onRequestDismiss: (() -> Void)?

    private(set) var hasOrderHost = false
    private var hostingController: UIHostingController<StockDetailShuffleOrderHostView>?
    private var hostedSymbol: StockOrderSymbol?
    private var hostedLanguage: DemoLanguage = .simplifiedChinese
    private weak var hostedLanguageStore: DemoLanguageStore?
    private var hostedExternalReturnDrag: ((CGFloat, CGFloat, CGFloat, Bool) -> Void)?
    private var storedOffset: CGFloat = 0
    private var isPreparedOnly = false
    private var activeAnimator: UIViewPropertyAnimator?
    private var isLayerInteractive = false

    var isInteractiveForHitTesting: Bool {
        isLayerInteractive
    }

    override func loadView() {
        let containerView = StockDetailShuffleOrderContainerView()
        containerView.owner = self
        view = containerView
        view.backgroundColor = .clear
        view.isOpaque = false
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let hostedView = hostingController?.view else { return }
        hostedView.frame = view.bounds

        guard activeAnimator == nil else { return }
        applyStoredOffset()
    }

    override func accessibilityPerformEscape() -> Bool {
        guard isLayerInteractive else { return false }
        onRequestDismiss?()
        return true
    }

    func prepare(
        symbol: StockOrderSymbol,
        language: DemoLanguage,
        languageStore: DemoLanguageStore?,
        onExternalReturnDrag: @escaping (CGFloat, CGFloat, CGFloat, Bool) -> Void
    ) {
        loadViewIfNeeded()
        hostedExternalReturnDrag = onExternalReturnDrag

        if hostedSymbol == symbol,
           let languageStore,
           hostedLanguageStore === languageStore {
            updateHostEnvironment(language: language, languageStore: languageStore)
            return
        }

        stopAnimationPreservingPresentation()
        removeHostedController()
        hostedSymbol = symbol
        hostedLanguage = language
        hostedLanguageStore = languageStore
        isPreparedOnly = true
        storedOffset = view.bounds.width

        guard let languageStore else { return }

        let host = UIHostingController(
            rootView: StockDetailShuffleOrderHostView(
                symbol: symbol,
                language: language,
                languageStore: languageStore,
                onExit: { [weak self] in
                    self?.onRequestDismiss?()
                },
                onExternalReturnDrag: onExternalReturnDrag
            )
        )
        host.view.backgroundColor = .clear
        host.view.isOpaque = false
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.view.accessibilityElementsHidden = true
        host.view.isUserInteractionEnabled = false

        addChild(host)
        view.addSubview(host.view)
        host.didMove(toParent: self)
        hostingController = host
        hasOrderHost = true
        view.setNeedsLayout()
    }

    func updateHostEnvironment(language: DemoLanguage, languageStore: DemoLanguageStore) {
        guard let hostedSymbol,
              let hostedExternalReturnDrag,
              let host = hostingController else {
            return
        }

        hostedLanguage = language
        hostedLanguageStore = languageStore
        host.rootView = StockDetailShuffleOrderHostView(
            symbol: hostedSymbol,
            language: language,
            languageStore: languageStore,
            onExit: { [weak self] in
                self?.onRequestDismiss?()
            },
            onExternalReturnDrag: hostedExternalReturnDrag
        )
    }

    func setOffset(_ offset: CGFloat) {
        storedOffset = max(0, offset)
        isPreparedOnly = false
        applyStoredOffset()
    }

    func setInteractive(_ interactive: Bool) {
        isLayerInteractive = interactive
        hostingController?.view.isUserInteractionEnabled = interactive
        hostingController?.view.accessibilityElementsHidden = !interactive
    }

    func animate(
        to targetOffset: CGFloat,
        velocity: CGFloat,
        reduceMotion: Bool,
        completion: @escaping () -> Void
    ) {
        loadViewIfNeeded()
        let current = stopAnimationPreservingPresentation()
        let target = max(0, targetOffset)

        guard !reduceMotion, abs(target - current) > 0.5 else {
            setOffset(target)
            completion()
            return
        }

        let distance = target - current
        let normalizedVelocity = max(-4, min(4, velocity / distance))
        let timingParameters = UISpringTimingParameters(
            duration: 0.35,
            bounce: 0,
            initialVelocity: CGVector(dx: normalizedVelocity, dy: 0)
        )
        let animator = UIViewPropertyAnimator(
            duration: 0.35,
            timingParameters: timingParameters
        )
        animator.isInterruptible = true
        animator.addAnimations { [weak self] in
            self?.storedOffset = target
            self?.isPreparedOnly = false
            self?.applyStoredOffset()
        }
        animator.addCompletion { [weak self] _ in
            guard let self else { return }
            self.activeAnimator = nil
            self.setOffset(target)
            completion()
        }
        activeAnimator = animator
        animator.startAnimation()
    }

    @discardableResult
    func stopAnimationPreservingPresentation() -> CGFloat {
        let presentationOffset = renderedOffset
        activeAnimator?.stopAnimation(true)
        activeAnimator = nil
        storedOffset = presentationOffset
        isPreparedOnly = false
        applyStoredOffset()
        return presentationOffset
    }

    func removeOrderHost() {
        activeAnimator?.stopAnimation(true)
        activeAnimator = nil
        removeHostedController()
        hostedSymbol = nil
        hostedLanguageStore = nil
        hostedExternalReturnDrag = nil
        storedOffset = 0
        isPreparedOnly = false
        isLayerInteractive = false
    }

    private var renderedOffset: CGFloat {
        guard let hostedView = hostingController?.view else { return storedOffset }
        return hostedView.layer.presentation()?.affineTransform().tx ?? hostedView.transform.tx
    }

    private func applyStoredOffset() {
        guard let hostedView = hostingController?.view else { return }
        let offset = isPreparedOnly ? view.bounds.width : storedOffset
        hostedView.frame = view.bounds
        hostedView.transform = CGAffineTransform(translationX: offset, y: 0)
    }

    private func removeHostedController() {
        guard let hostingController else {
            hasOrderHost = false
            return
        }

        hostingController.willMove(toParent: nil)
        hostingController.view.removeFromSuperview()
        hostingController.removeFromParent()
        self.hostingController = nil
        hasOrderHost = false
    }
}

private final class StockDetailShuffleOrderContainerView: UIView {
    weak var owner: StockDetailShuffleOrderTransitionViewController?

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        owner?.isInteractiveForHitTesting == true && super.point(inside: point, with: event)
    }
}

private struct StockDetailShuffleOrderHostView: View {
    let symbol: StockOrderSymbol
    let language: DemoLanguage
    let languageStore: DemoLanguageStore
    let onExit: () -> Void
    let onExternalReturnDrag: (CGFloat, CGFloat, CGFloat, Bool) -> Void

    var body: some View {
        StockOrderDemoView(
            initialSelection: symbol,
            onExit: onExit,
            onExternalReturnDrag: onExternalReturnDrag
        )
        .environmentObject(languageStore)
        .environment(\.demoLanguage, language)
    }
}

private final class StockDetailShuffleOrderTransitionDiagnostics {
    private var displayLink: CADisplayLink?
    private weak var container: StockDetailShuffleOrderTransitionViewController?
    private var lastTimestamp: CFTimeInterval?
    private(set) var sampleCount = 0
    private(set) var maximumFrameInterval: CFTimeInterval = 0

    func start(with container: StockDetailShuffleOrderTransitionViewController?) {
        stop()
        self.container = container
        lastTimestamp = nil
        sampleCount = 0
        maximumFrameInterval = 0

        #if DEBUG
        let displayLink = CADisplayLink(
            target: self,
            selector: #selector(sample(_:))
        )
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
        #endif
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        container = nil
    }

    #if DEBUG
    @objc private func sample(_ displayLink: CADisplayLink) {
        guard container != nil else {
            stop()
            return
        }

        if let lastTimestamp {
            maximumFrameInterval = max(
                maximumFrameInterval,
                displayLink.timestamp - lastTimestamp
            )
        }
        lastTimestamp = displayLink.timestamp
        sampleCount += 1
        _ = container?.view.layer.presentation()
    }
    #endif
}
