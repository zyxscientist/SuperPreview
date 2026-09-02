//
//  StockDetailShuffleView.swift
//  SuperPreview
//

import Foundation
import SwiftUI
import UIKit

enum StockDetailPagePresentationMode: Equatable {
    case standard
    case shuffleCard
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
/// context. Each visible card is the existing detail page rendered into a
/// smaller, clipped surface; the pager owns the only active gesture.
struct StockDetailShuffleView: View {
    let instruments: [StockDetailInstrument]
    @Binding private var selection: StockDetailInstrument
    let onExit: (StockDetailInstrument) -> Void

    @AppStorage(StockDetailShuffleStorageKey.quoteDataIsExpanded)
    private var isQuoteDataExpanded = true
    @State private var symbolSelectionRequest: Int?

    init(
        instruments: [StockDetailInstrument],
        selection: Binding<StockDetailInstrument>,
        onExit: @escaping (StockDetailInstrument) -> Void = { _ in }
    ) {
        let normalizedInstruments = Self.uniqueInstruments(instruments)

        self.instruments = normalizedInstruments
        self._selection = selection
        self.onExit = onExit
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
            onExit: onExit
        )
    }

    /// A soft, screen-wide frost across the top edge. The gradient mask keeps
    /// it strongest at the very top and fades it out just past the card's top
    /// edge, so the card only catches a faint veil instead of a hard band.
    private var topFrost: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
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
        onExit: @escaping (StockDetailInstrument) -> Void
    ) {
        self.instruments = instruments
        self._currentIndex = currentIndex
        self._symbolSelectionRequest = symbolSelectionRequest
        self._quoteDataIsExpanded = quoteDataIsExpanded
        self.canvasSize = canvasSize
        self.onExit = onExit
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
        // card's offset independently made all three detail-page subtrees
        // participate in every drag frame.
        .offset(y: dragOffset)
        .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
        // The previous card intentionally lives above the viewport. Clip the
        // pager to its own bounds so the system fullScreenCover dismissal
        // cannot move that off-screen card into view while the cover slides
        // away.
        .clipped()
        .contentShape(Rectangle())
        .simultaneousGesture(
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

                guard gestureAxis == .vertical else { return }
                dragOffset = adjustedDragOffset(value.translation.height)
            }
            .onEnded { value in
                guard !isSettling else {
                    gestureAxis = nil
                    return
                }

                let axis = gestureAxis
                gestureAxis = nil

                guard axis == .vertical else {
                    dragOffset = 0
                    return
                }

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

        let token = beginTransition()
        let finalOffset = targetIndex > currentIndex ? -stride : stride

        if reduceMotion {
            withAnimation(.easeOut(duration: ShuffleLayout.reduceMotionDuration)) {
                transitionOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + ShuffleLayout.reduceMotionDuration) {
                guard transitionToken == token else { return }
                updateIndexWithoutAnimation(to: targetIndex)
                withAnimation(.easeOut(duration: ShuffleLayout.reduceMotionDuration)) {
                    transitionOpacity = 1
                }
                isSettling = false
            }
            return
        }

        withAnimation(pageTransitionAnimation) {
            dragOffset = finalOffset
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + ShuffleLayout.transitionDuration) {
            guard transitionToken == token else { return }
            updateIndexWithoutAnimation(to: targetIndex)
            isSettling = false
        }
    }

    private func settleBack() {
        guard abs(dragOffset) > ShuffleLayout.offsetEpsilon else {
            dragOffset = 0
            return
        }

        let token = beginTransition()

        withAnimation(pageTransitionAnimation) {
            dragOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + ShuffleLayout.transitionDuration) {
            guard transitionToken == token else { return }
            dragOffset = 0
            isSettling = false
        }
    }

    private func handleSymbolSelection(_ targetIndex: Int, stride: CGFloat) {
        guard !isSettling,
              instruments.indices.contains(targetIndex),
              targetIndex != currentIndex else {
            return
        }

        let token = beginTransition()
        stagedTargetIndex = targetIndex
        let directionOffset = targetIndex > currentIndex ? -1 : 1

        if reduceMotion {
            withAnimation(.easeOut(duration: ShuffleLayout.reduceMotionDuration)) {
                transitionOpacity = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + ShuffleLayout.reduceMotionDuration) {
                guard transitionToken == token else { return }
                updateIndexWithoutAnimation(to: targetIndex)
                withAnimation(.easeOut(duration: ShuffleLayout.reduceMotionDuration)) {
                    transitionOpacity = 1
                }
                isSettling = false
            }
            return
        }

        withAnimation(pageTransitionAnimation) {
            dragOffset = CGFloat(directionOffset) * stride
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + ShuffleLayout.transitionDuration) {
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
            && lhs.visibleInstrument(for: -1) == rhs.visibleInstrument(for: -1)
            && lhs.visibleInstrument(for: 0) == rhs.visibleInstrument(for: 0)
            && lhs.visibleInstrument(for: 1) == rhs.visibleInstrument(for: 1)
            && lhs.canvasSize == rhs.canvasSize
            && lhs.cardWidth == rhs.cardWidth
            && lhs.cardHeight == rhs.cardHeight
            && lhs.scale == rhs.scale
            && lhs.stride == rhs.stride
            && lhs.language.rawValue == rhs.language.rawValue
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let previousIndex = displayedIndex(for: -1) {
                card(
                    instrument: instruments[previousIndex],
                    relativePosition: -1
                )
            }

            if let nextIndex = displayedIndex(for: 1) {
                card(
                    instrument: instruments[nextIndex],
                    relativePosition: 1
                )
            }

            if instruments.indices.contains(currentIndex) {
                card(
                    instrument: instruments[currentIndex],
                    relativePosition: 0
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func card(
        instrument: StockDetailInstrument,
        relativePosition: Int
    ) -> some View {
        let slotName: String
        switch relativePosition {
        case -1:
            slotName = "previous"
        case 1:
            slotName = "next"
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
        .accessibilityElement(children: .contain)
        .accessibilityLabel(cardAccessibilityLabel(for: instrument))
        .accessibilityHint(language == .english ? "Opens the full detail page" : "打开完整详情页")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("stockDetail.shuffle.card.\(slotName)")
    }

    private func displayedIndex(for relativePosition: Int) -> Int? {
        guard !instruments.isEmpty else { return nil }

        if let stagedTargetIndex {
            let stagedRelativePosition = stagedTargetIndex > currentIndex ? 1 : -1
            if relativePosition == stagedRelativePosition {
                return stagedTargetIndex
            }
        }

        let candidate = currentIndex + relativePosition
        return instruments.indices.contains(candidate) ? candidate : nil
    }

    private func visibleInstrument(for relativePosition: Int) -> StockDetailInstrument? {
        guard let index = displayedIndex(for: relativePosition) else { return nil }
        return instruments[index]
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

                Image("virtual_holding_close")
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
    static let horizontalInset: CGFloat = 8
    // Keep the current card below the iPhone 17 Pro Dynamic Island safe area.
    // With an 874-point canvas and an 8-point card gap this yields a
    // 750-point current card: 874 - (54 * 2) - (8 * 2).
    static let verticalPeek: CGFloat = 54
    // The frost fades to nothing just past the card's top edge
    // (verticalPeek + cardGap = 62), so the card only catches its faint tail.
    static let topFrostHeight: CGFloat = verticalPeek + cardGap + 22
    static let cardGap: CGFloat = 8
    static let cardCornerRadius: CGFloat = 20

    static let symbolBarHorizontalInset: CGFloat = 16
    static let symbolBarBottomInset: CGFloat = 16
    static let symbolBarHeight: CGFloat = 38
    static let symbolBarGap: CGFloat = 8
    static let closeIconSize: CGFloat = 16
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
        .previewLayout(.fixed(width: 402, height: 874))

        StockDetailShufflePreviewHost(
            instruments: StockDetailDebugSamples.all,
            initialInstrumentID: StockDetailDebugSamples.all[2].id
        )
        .environment(\.demoLanguage, .english)
        .environmentObject(DemoLanguageStore(initialLanguage: .english))
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
