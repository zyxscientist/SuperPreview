//
//  StockDetailPage.swift
//  SuperPreview
//

import SwiftUI

/// Keeps the relatively expensive mock-page assembly out of SwiftUI's body
/// recomputation path. The cache is scoped to one detail-page lifetime so a
/// changed instrument value still gets a fresh configuration key.
final class StockDetailPageConfigurationCache: ObservableObject {
    private struct CacheKey: Hashable {
        let instrument: StockDetailInstrument
        let includesBelowChartComponents: Bool
    }

    private var storage: [CacheKey: StockDetailPageConfiguration] = [:]

    func configuration(
        for instrument: StockDetailInstrument,
        includesBelowChartComponents: Bool = true
    ) -> StockDetailPageConfiguration {
        let key = CacheKey(
            instrument: instrument,
            includesBelowChartComponents: includesBelowChartComponents
        )

        if let cachedConfiguration = storage[key] {
            return cachedConfiguration
        }

        let configuration = StockDetailPageConfigurationFactory.make(
            for: instrument,
            includesBelowChartComponents: includesBelowChartComponents
        )
        storage[key] = configuration
        return configuration
    }
}

/// The shared detail-page shell. The active instrument supplies the page
/// configuration, while the shell owns only navigation, paging, scroll reveal,
/// debug switching, and the fixed bottom action bar.
struct StockDetailPage: View {
    let onBack: (() -> Void)?
    let onRefresh: () -> Void
    let onOrderConfirmed: (StockOrderConfirmationSide) -> Void
    let onOrderAction: (StockOrderTodayOrderItem, StockOrderTodayOrderAction) -> Void
    let onLoadMore: () -> Void
    let onTrade: () -> Void
    let onWatchlist: () -> Void
    let onReminder: () -> Void
    let shuffleInstruments: [StockDetailInstrument]?
    let presentationMode: StockDetailPagePresentationMode
    let configurationOverride: StockDetailPageConfiguration?
    let quoteDetailsExpansion: Binding<Bool>?
    let onShuffleCardInteraction: (() -> Void)?

    @State private var activeInstrument: StockDetailInstrument
    @State private var selectedTab: StockDetailPageTab
    @State private var isQuoteDetailsExpanded = false
    @State private var relatedInfoInteraction = StockDetailRelatedInfoInteractionState()
    @State private var quoteScrollOffset: CGFloat = 0
    @State private var isShowingDebugSheet = false
    @State private var shuffleSession: StockDetailShuffleSession?
    @State private var pendingShuffleExitInstrumentID: String?
    @StateObject private var configurationCache: StockDetailPageConfigurationCache

    @EnvironmentObject private var demoLanguageStore: DemoLanguageStore
    @Environment(\.dismiss) private var dismiss

    init(
        instrument: StockDetailInstrument,
        initialTab: StockDetailPageTab = .quote,
        shuffleInstruments: [StockDetailInstrument]? = nil,
        presentationMode: StockDetailPagePresentationMode = .standard,
        configuration: StockDetailPageConfiguration? = nil,
        quoteDetailsExpansion: Binding<Bool>? = nil,
        onShuffleCardInteraction: (() -> Void)? = nil,
        onBack: (() -> Void)? = nil,
        onRefresh: @escaping () -> Void = {},
        onOrderConfirmed: @escaping (StockOrderConfirmationSide) -> Void = { _ in },
        onOrderAction: @escaping (
            StockOrderTodayOrderItem,
            StockOrderTodayOrderAction
        ) -> Void = { _, _ in },
        onLoadMore: @escaping () -> Void = {},
        onTrade: @escaping () -> Void = {},
        onWatchlist: @escaping () -> Void = {},
        onReminder: @escaping () -> Void = {}
    ) {
        let initialTabs = configuration?.tabs ?? StockDetailPageVariant(instrument: instrument).tabs

        self.onBack = onBack
        self.onRefresh = onRefresh
        self.onOrderConfirmed = onOrderConfirmed
        self.onOrderAction = onOrderAction
        self.onLoadMore = onLoadMore
        self.onTrade = onTrade
        self.onWatchlist = onWatchlist
        self.onReminder = onReminder
        self.shuffleInstruments = shuffleInstruments
        self.presentationMode = presentationMode
        self.configurationOverride = configuration
        self.quoteDetailsExpansion = quoteDetailsExpansion
        self.onShuffleCardInteraction = onShuffleCardInteraction
        _activeInstrument = State(initialValue: instrument)
        _selectedTab = State(
            initialValue: initialTabs.contains(initialTab) ? initialTab : .quote
        )
        _configurationCache = StateObject(wrappedValue: StockDetailPageConfigurationCache())
    }

    var body: some View {
        GeometryReader { geometry in
            let pageConfiguration = configuration

            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    StockDetailNavbar(
                        symbol: activeInstrument.symbol,
                        name: activeInstrument.fallbackName,
                        quote: navbarQuote,
                        quoteRevealProgress: navbarRevealProgress,
                        onBack: handleBack,
                        onShare: handleDebugAction,
                        trailingAction: presentationMode == .standard ? .debug : .none,
                        presentation: presentationMode == .shuffleCard ? .shuffle : .standard,
                        shareAccessibilityLabel: activeLanguage.text(.debug)
                    )

                    if presentationMode == .standard {
                        StockDetailPageHeaderTabs(
                            tabs: pageConfiguration.tabs,
                            selection: $selectedTab,
                            onInteraction: onShuffleCardInteraction
                        )
                    }

                    if presentationMode == .shuffleCard {
                        shuffleQuotePage(
                            configuration: pageConfiguration,
                            viewportWidth: geometry.size.width
                        )
                    } else {
                        TabView(selection: $selectedTab) {
                            ForEach(pageConfiguration.tabs) { tab in
                                page(
                                    for: tab,
                                    configuration: pageConfiguration,
                                    viewportWidth: geometry.size.width
                                )
                                    .tag(tab)
                            }
                        }
                        .id(activeInstrument.id)
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    }
                }

                if presentationMode == .standard {
                    fixedBottomActionBar
                }
            }
            // Keep the navbar, tab container, and quote content in one
            // identity boundary. Otherwise a cover dismissal can reveal a
            // newly-updated navbar while the cached TabView is still drawing
            // the instrument that was active when the cover opened.
            .id(activeInstrument.id)
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .background(Color("color-base-1"))
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .overlay(alignment: .topLeading) {
            if PreviewRuntime.isUITesting, presentationMode == .standard {
                Text(activeInstrument.id)
                    .frame(width: 1, height: 1)
                    .accessibilityIdentifier("stockDetail.committedInstrument")
                    .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: debugSheetIsPresented) {
            StockDetailDebugSheet(
                selection: $activeInstrument,
                language: debugLanguageBinding
            )
            .environment(\.demoLanguage, activeLanguage)
        }
        .fullScreenCover(
            item: shuffleSessionBinding,
            onDismiss: {
                pendingShuffleExitInstrumentID = nil
            }
        ) { session in
            StockDetailShuffleView(
                instruments: session.instruments,
                selection: $activeInstrument,
                onExit: exitShuffle(to:)
            )
            .environmentObject(demoLanguageStore)
            .environment(\.demoLanguage, activeLanguage)
        }
        .onChange(of: activeInstrument) { _, newInstrument in
            resetPageState()
            completePendingShuffleExitIfNeeded(for: newInstrument)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.page")
        .environment(\.demoLanguage, activeLanguage)
    }

    private var configuration: StockDetailPageConfiguration {
        configurationOverride ?? configurationCache.configuration(for: activeInstrument)
    }

    private func page(
        for tab: StockDetailPageTab,
        configuration: StockDetailPageConfiguration,
        viewportWidth: CGFloat
    ) -> some View {
        Group {
            if tab == .quote {
                quotePage(configuration: configuration, viewportWidth: viewportWidth)
            } else {
                StockDetailPageEmptyView(tab: tab)
            }
        }
    }

    private func quotePage(
        configuration: StockDetailPageConfiguration,
        viewportWidth: CGFloat
    ) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                StockDetailQuoteData(
                    data: configuration.quoteData,
                    isExpanded: quoteDetailsExpansionBinding
                )

                if !configuration.relatedItems.isEmpty {
                    StockDetailRelatedInfo(
                        items: configuration.relatedItems,
                        interactionState: $relatedInfoInteraction
                    )
                }

                StockDetailChart()

                if configuration.variant.showsTransactionModule {
                    if let positionState = configuration.positionState,
                       let transactionOrders = configuration.transactionOrders,
                       let historyOrders = configuration.historyOrders {
                        StockDetailTransactionModule(
                            symbol: configuration.symbol,
                            positionState: positionState,
                            orders: transactionOrders,
                            historyOrders: historyOrders,
                            onRefresh: onRefresh,
                            onOrderConfirmed: onOrderConfirmed,
                            onOrderAction: onOrderAction,
                            onLoadMore: onLoadMore
                        )
                    }
                }

                if let orderBookData = configuration.orderBookData {
                    StockDetailOrderBook(data: orderBookData)
                }

                if let brokerOrderBookData = configuration.brokerOrderBookData {
                    StockDetailBrokerOrderBook(data: brokerOrderBookData)
                }

                if configuration.variant.showsCapitalDistribution,
                   let capitalDistributionData = configuration.capitalDistributionData {
                    StockDetailCapitalDistribution(data: capitalDistributionData)
                }

                if configuration.variant.showsMoneyFlow,
                   let moneyFlowData = configuration.moneyFlowData {
                    moneyFlowCard(data: moneyFlowData)
                }

                disclaimer
            }
            .frame(width: viewportWidth, alignment: .topLeading)
            .padding(.bottom, StockDetailPageLayout.bottomClearance)
        }
        .scrollBounceBehavior(.basedOnSize)
        .onScrollGeometryChange(for: CGFloat.self, of: { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        }) { _, offset in
            quoteScrollOffset = -offset
        }
        .background(Color("color-base-1"))
        .accessibilityIdentifier("stockDetail.page.quotePage")
    }

    private func shuffleQuotePage(
        configuration: StockDetailPageConfiguration,
        viewportWidth: CGFloat
    ) -> some View {
        let chartHeight = viewportWidth / StockDetailChart.snapshotAspectRatio

        return VStack(spacing: 0) {
            StockDetailQuoteData(
                data: configuration.quoteData,
                isExpanded: quoteDetailsExpansionBinding,
                onBadgesTap: onShuffleCardInteraction
            )

            if !configuration.relatedItems.isEmpty {
                StockDetailRelatedInfo(
                    items: configuration.relatedItems,
                    interactionState: $relatedInfoInteraction,
                    onInteraction: onShuffleCardInteraction
                )
            }

            StockDetailChart()
                // Keep the chart at its source aspect ratio. When the
                // expanded quote content is taller than the Shuffle card,
                // the page clips the overflow instead of offering the chart
                // a smaller vertical proposal.
                .frame(
                    width: viewportWidth,
                    height: chartHeight,
                    alignment: .topLeading
                )
        }
        .frame(width: viewportWidth, alignment: .topLeading)
        // Shuffle omits everything below the chart. Keep the remaining page
        // height flexible and pin the content to the same top edge instead of
        // letting the outer bottom-aligned stack turn the difference into a
        // blank area above the navbar.
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .clipped()
        .background(Color("color-base-1"))
        .accessibilityIdentifier("stockDetail.page.quotePage")
    }

    private var quoteDetailsExpansionBinding: Binding<Bool> {
        quoteDetailsExpansion ?? $isQuoteDetailsExpanded
    }

    private var navbarQuote: StockDetailNavbarQuote {
        let pageConfiguration = configuration

        return StockDetailNavbarQuote(
            session: pageConfiguration.quoteData.timestamp.session,
            price: pageConfiguration.quoteData.price,
            change: pageConfiguration.quoteData.change,
            changePercent: pageConfiguration.quoteData.changePercent,
            trend: pageConfiguration.quoteData.trend.navbarTrend
        )
    }

    private var navbarRevealProgress: CGFloat {
        guard selectedTab == .quote else { return 1 }

        let revealStart: CGFloat = 100
        let revealDistance: CGFloat = 24
        let progress = (-quoteScrollOffset - revealStart) / revealDistance
        return min(max(progress, 0), 1)
    }

    private func handleBack() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }

    private func handleDebugAction() {
        guard presentationMode == .standard else { return }
        isShowingDebugSheet = true
    }

    private func presentShuffle() {
        guard presentationMode == .standard else { return }

        let snapshot = normalizedShuffleInstruments
        guard !snapshot.isEmpty else { return }

        shuffleSession = StockDetailShuffleSession(
            instruments: snapshot
        )
    }

    private func exitShuffle(to instrument: StockDetailInstrument) {
        guard presentationMode == .standard, shuffleSession != nil else { return }

        pendingShuffleExitInstrumentID = instrument.id

        if activeInstrument.id != instrument.id {
            commitActiveInstrumentWithoutAnimation(instrument)
        } else {
            // The current card has already committed the selection, but its
            // presenting page may still be waiting for SwiftUI to render the
            // corresponding content tree. Use the same next-run-loop exit
            // path as a newly selected card instead of dismissing inline.
            completePendingShuffleExitIfNeeded(for: instrument)
        }
    }

    private func completePendingShuffleExitIfNeeded(for instrument: StockDetailInstrument) {
        guard presentationMode == .standard,
              pendingShuffleExitInstrumentID == instrument.id else {
            return
        }

        // Task.yield() can resume before SwiftUI commits the presenting page's
        // new layout. Queue dismissal on the next main-run-loop turn so the
        // fullScreenCover's exit animation can only reveal the new instrument.
        DispatchQueue.main.async {
            guard pendingShuffleExitInstrumentID == instrument.id,
                  shuffleSession != nil,
                  activeInstrument.id == instrument.id else {
                return
            }

            pendingShuffleExitInstrumentID = nil
            shuffleSession = nil
        }
    }

    private func commitActiveInstrumentWithoutAnimation(_ instrument: StockDetailInstrument) {
        var transaction = Transaction()
        transaction.animation = nil
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            activeInstrument = instrument
        }
    }

    private var normalizedShuffleInstruments: [StockDetailInstrument] {
        guard activeInstrument.kind != .fund, activeInstrument.market != .fund else {
            return []
        }

        guard let shuffleInstruments, !shuffleInstruments.isEmpty else {
            return [activeInstrument]
        }

        var seen = Set<String>()
        let filtered = shuffleInstruments.filter { instrument in
            guard instrument.kind != .fund, instrument.market != .fund else { return false }
            return seen.insert(instrument.id).inserted
        }

        guard filtered.contains(where: { $0.id == activeInstrument.id }) else {
            return [activeInstrument]
        }

        return filtered
    }

    private func resetPageState() {
        selectedTab = .quote
        isQuoteDetailsExpanded = false
        relatedInfoInteraction = .init()
        quoteScrollOffset = 0
    }

    private func moneyFlowCard(data: StockDetailMoneyFlowTrendData) -> some View {
        StockDetailMoneyFlowTrend(data: data)
            .padding(.vertical, StockDetailPageLayout.moneyFlowCardPadding)
            .frame(maxWidth: .infinity)
            .background(Color("color-base-1"))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: StockDetailPageLayout.cardCornerRadius,
                    style: .continuous
                )
            )
            .accessibilityIdentifier("stockDetail.page.moneyFlowCard")
    }

    private var disclaimer: some View {
        Text(disclaimerText)
            .modifier(
                CustomFontModifier(
                    size: StockDetailPageLayout.disclaimerFontSize,
                    font: .regular,
                    lineHeight: StockDetailPageLayout.disclaimerLineHeight
                )
            )
            .foregroundColor(Color("color-text-90"))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(StockDetailPageLayout.disclaimerPadding)
            .frame(
                maxWidth: .infinity,
                minHeight: StockDetailPageLayout.disclaimerMinimumHeight,
                alignment: .center
            )
            .background(Color("color-base-1"))
            .clipShape(
                RoundedRectangle(
                    cornerRadius: StockDetailPageLayout.cardCornerRadius,
                    style: .continuous
                )
            )
            .accessibilityIdentifier("stockDetail.page.disclaimer")
    }

    private var disclaimerText: String {
        activeLanguage.text(.stockDetailDisclaimer)
    }

    private var activeLanguage: DemoLanguage {
        demoLanguageStore.language
    }

    private var debugSheetIsPresented: Binding<Bool> {
        presentationMode == .standard ? $isShowingDebugSheet : .constant(false)
    }

    private var shuffleSessionBinding: Binding<StockDetailShuffleSession?> {
        presentationMode == .standard ? $shuffleSession : .constant(nil)
    }

    private var debugLanguageBinding: Binding<DemoLanguage> {
        Binding(
            get: { demoLanguageStore.language },
            set: { demoLanguageStore.language = $0 }
        )
    }

    private var fixedBottomActionBar: some View {
        VStack(spacing: 0) {
            StockDetailBottomActionBar(
                onTrade: onTrade,
                onWatchlist: onWatchlist,
                onReminder: onReminder,
                onShuffle: presentShuffle
            )
            .frame(height: StockDetailPageLayout.bottomBarHeight)

            Color.clear
                .frame(height: StockDetailPageLayout.homeIndicatorAreaHeight)
        }
        .frame(height: StockDetailPageLayout.bottomBarContainerHeight)
        .background(Color.clear)
        .accessibilityIdentifier("stockDetail.page.fixedBottomActionBar")
    }
}

private struct StockDetailPageHeaderTabs: View {
    let tabs: [StockDetailPageTab]
    @Binding var selection: StockDetailPageTab
    let onInteraction: (() -> Void)?

    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var selectionAnimation: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.32, extraBounce: 0)
    }

    var body: some View {
        HStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                tabButtons
                    .padding(.leading, 10)
                    .padding(.trailing, 48)
                    .padding(.vertical, 8)
                    .animation(selectionAnimation, value: selection)
            }
        }
        .frame(height: StockDetailPageHeaderTabsLayout.height)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.page.headerTabs")
    }

    private var tabButtons: some View {
        HStack(spacing: StockDetailPageHeaderTabsLayout.tabSpacing) {
            ForEach(tabs) { tab in
                let isSelected = selection == tab

                Button {
                    if let onInteraction {
                        onInteraction()
                        return
                    }

                    guard selection != tab else { return }
                    selection = tab
                } label: {
                    Text(tab.title(for: language))
                        .modifier(
                            CustomFontModifier(
                                size: StockDetailPageHeaderTabsLayout.fontSize,
                                font: isSelected ? .bold : .regular,
                                lineHeight: StockDetailPageHeaderTabsLayout.lineHeight
                            )
                        )
                        .foregroundColor(
                            isSelected
                                ? Color("color-text-30")
                                : Color("color-text-60")
                        )
                        .padding(.horizontal, StockDetailPageHeaderTabsLayout.itemHorizontalPadding)
                        .frame(height: StockDetailPageHeaderTabsLayout.itemHeight)
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                        .anchorPreference(
                            key: StockDetailPageTabFramePreferenceKey.self,
                            value: .bounds
                        ) { anchor in
                            [tab: anchor]
                        }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityLabel(tab.title(for: language))
                .accessibilityIdentifier("stockDetail.page.headerTab.\(tab.rawValue)")
            }
        }
        .backgroundPreferenceValue(StockDetailPageTabFramePreferenceKey.self) { anchors in
            GeometryReader { proxy in
                if let selectedAnchor = anchors[selection] {
                    let selectedFrame = proxy[selectedAnchor]

                    selectionGlassBackground
                        .frame(width: selectedFrame.width, height: selectedFrame.height)
                        .position(x: selectedFrame.midX, y: selectedFrame.midY)
                }
            }
        }
    }

    @ViewBuilder
    private var selectionGlassBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: Capsule())
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        } else {
            Capsule()
                .fill(Color("color-base-r"))
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}

private struct StockDetailPageEmptyView: View {
    let tab: StockDetailPageTab

    @Environment(\.demoLanguage) private var language

    var body: some View {
        Color("color-base-1")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(tab.title(for: language))
            .accessibilityIdentifier("stockDetail.page.empty.\(tab.rawValue)")
    }
}

private struct StockDetailDebugSheet: View {
    @Binding var selection: StockDetailInstrument
    @Binding var language: DemoLanguage

    @Environment(\.dismiss) private var dismiss
    @Environment(\.demoLanguage) private var interfaceLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(interfaceLanguage.text(.debug))
                    .modifier(CustomFontModifier(size: 20, font: .bold, lineHeight: 28))
                    .foregroundColor(Color("color-text-30"))

                Spacer()

                Button(interfaceLanguage.text(.done)) {
                    dismiss()
                }
                .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                .foregroundColor(Color("color-brand-blue"))
                .accessibilityIdentifier("stockDetail.debug.done")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            DemoLanguagePicker(language: $language)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
                .accessibilityIdentifier("stockDetail.debug.language")

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(StockDetailDebugSamples.all) { instrument in
                        debugRow(instrument)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(Color("color-base-1").ignoresSafeArea())
        .presentationDragIndicator(.visible)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.debug.sheet")
    }

    private func debugRow(_ instrument: StockDetailInstrument) -> some View {
        let isSelected = selection.id == instrument.id

        return Button {
            selection = instrument
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName(for: instrument))
                        .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 22))
                        .foregroundColor(Color("color-text-30"))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("\(instrument.symbol) · \(variantTitle(for: instrument))")
                        .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 18))
                        .foregroundColor(Color("color-text-60"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("color-brand-blue"))
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 64)
            .background(
                isSelected
                    ? Color("color-brand-blue").opacity(0.08)
                    : Color("color-scale-1"),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(displayName(for: instrument)), \(instrument.symbol)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("stockDetail.debug.instrument.\(instrument.id)")
    }

    private func variantTitle(for instrument: StockDetailInstrument) -> String {
        let variant = StockDetailPageVariant(instrument: instrument)
        return interfaceLanguage.text(variant.debugTitleKey)
    }

    private func displayName(for instrument: StockDetailInstrument) -> String {
        instrument.localizationID.map {
            interfaceLanguage.securityName(id: $0, fallback: instrument.fallbackName)
        } ?? instrument.fallbackName
    }
}

private enum StockDetailPageLayout {
    static let bottomBarHeight: CGFloat = 60
    static let homeIndicatorAreaHeight: CGFloat = 34
    static let bottomBarContainerHeight: CGFloat = bottomBarHeight + homeIndicatorAreaHeight
    static let bottomClearance: CGFloat = bottomBarContainerHeight + 16
    static let moneyFlowCardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 16
    static let disclaimerFontSize: CGFloat = 11
    static let disclaimerLineHeight: CGFloat = 12
    static let disclaimerPadding: CGFloat = 16
    static let disclaimerMinimumHeight: CGFloat = 140
}

private enum StockDetailPageHeaderTabsLayout {
    static let height: CGFloat = 48
    static let tabSpacing: CGFloat = 2
    static let itemHorizontalPadding: CGFloat = 14
    static let itemHeight: CGFloat = 32
    static let fontSize: CGFloat = 14
    static let lineHeight: CGFloat = 24
}

private struct StockDetailPageTabFramePreferenceKey: PreferenceKey {
    static var defaultValue: [StockDetailPageTab: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [StockDetailPageTab: Anchor<CGRect>],
        nextValue: () -> [StockDetailPageTab: Anchor<CGRect>]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, newValue in newValue })
    }
}

private extension StockDetailQuoteTrend {
    var navbarTrend: StockDetailNavbarQuote.Trend {
        switch self {
        case .up:
            .up
        case .down:
            .down
        case .flat:
            .flat
        }
    }
}

struct StockDetailPage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailPage(instrument: StockDetailDebugSamples.all[0])
                .environment(\.demoLanguage, .simplifiedChinese)
                .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
                .previewDisplayName("港股正股 · 可交互")

            StockDetailPage(instrument: StockDetailDebugSamples.all[1])
                .environment(\.demoLanguage, .english)
                .environmentObject(DemoLanguageStore(initialLanguage: .english))
                .preferredColorScheme(.dark)
                .previewDisplayName("HK ETF · English · Dark")

            StockDetailPage(instrument: StockDetailDebugSamples.all[2])
                .environment(\.demoLanguage, .simplifiedChinese)
                .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
                .previewDisplayName("美股正股 · Debug 可切换")

            StockDetailPage(instrument: StockDetailDebugSamples.all[3])
                .environment(\.demoLanguage, .english)
                .environmentObject(DemoLanguageStore(initialLanguage: .english))
                .previewDisplayName("US ETF · English")

            StockDetailPage(instrument: StockDetailDebugSamples.all[4])
                .environment(\.demoLanguage, .simplifiedChinese)
                .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
                .previewDisplayName("沪深正股")

            StockDetailPage(instrument: StockDetailDebugSamples.all[5])
                .environment(\.demoLanguage, .english)
                .environmentObject(DemoLanguageStore(initialLanguage: .english))
                .previewDisplayName("A-Share ETF · English")

            StockDetailPage(instrument: StockDetailDebugSamples.all[6])
                .environment(\.demoLanguage, .simplifiedChinese)
                .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
                .previewDisplayName("加密货币")
        }
        .previewLayout(.fixed(width: 402, height: 874))
    }
}
