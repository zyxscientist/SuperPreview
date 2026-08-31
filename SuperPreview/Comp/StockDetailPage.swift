//
//  StockDetailPage.swift
//  SuperPreview
//

import SwiftUI

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

    @State private var activeInstrument: StockDetailInstrument
    @State private var selectedTab: StockDetailPageTab
    @State private var isQuoteDetailsExpanded = false
    @State private var relatedInfoInteraction = StockDetailRelatedInfoInteractionState()
    @State private var quoteScrollOffset: CGFloat = 0
    @State private var isShowingDebugSheet = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.demoLanguage) private var language

    init(
        instrument: StockDetailInstrument,
        initialTab: StockDetailPageTab = .quote,
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
        let initialConfiguration = StockDetailPageConfigurationFactory.make(for: instrument)

        self.onBack = onBack
        self.onRefresh = onRefresh
        self.onOrderConfirmed = onOrderConfirmed
        self.onOrderAction = onOrderAction
        self.onLoadMore = onLoadMore
        self.onTrade = onTrade
        self.onWatchlist = onWatchlist
        self.onReminder = onReminder
        _activeInstrument = State(initialValue: instrument)
        _selectedTab = State(
            initialValue: initialConfiguration.tabs.contains(initialTab) ? initialTab : .quote
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    StockDetailNavbar(
                        symbol: activeInstrument.symbol,
                        name: activeInstrument.fallbackName,
                        quote: navbarQuote,
                        quoteRevealProgress: navbarRevealProgress,
                        onBack: handleBack,
                        onShare: { isShowingDebugSheet = true },
                        trailingAction: .debug,
                        shareAccessibilityLabel: language.text(.debug)
                    )

                    StockDetailPageHeaderTabs(
                        tabs: configuration.tabs,
                        selection: $selectedTab
                    )

                    TabView(selection: $selectedTab) {
                        ForEach(configuration.tabs) { tab in
                            page(for: tab, viewportWidth: geometry.size.width)
                                .tag(tab)
                        }
                    }
                    .id(activeInstrument.id)
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }

                fixedBottomActionBar
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .background(Color("color-base-1"))
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $isShowingDebugSheet) {
            StockDetailDebugSheet(selection: $activeInstrument)
        }
        .onChange(of: activeInstrument) { _, _ in
            resetPageState()
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.page")
    }

    private var configuration: StockDetailPageConfiguration {
        StockDetailPageConfigurationFactory.make(for: activeInstrument)
    }

    private func page(
        for tab: StockDetailPageTab,
        viewportWidth: CGFloat
    ) -> some View {
        Group {
            if tab == .quote {
                quotePage(viewportWidth: viewportWidth)
            } else {
                StockDetailPageEmptyView(tab: tab)
            }
        }
    }

    private func quotePage(viewportWidth: CGFloat) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                StockDetailQuoteData(
                    data: configuration.quoteData,
                    isExpanded: $isQuoteDetailsExpanded
                )

                if !configuration.relatedItems.isEmpty {
                    StockDetailRelatedInfo(
                        items: configuration.relatedItems,
                        interactionState: $relatedInfoInteraction
                    )
                }

                StockDetailChart()

                if configuration.variant.showsTransactionModule {
                    StockDetailTransactionModule(
                        symbol: configuration.symbol,
                        positionState: configuration.positionState,
                        orders: configuration.transactionOrders,
                        historyOrders: configuration.historyOrders,
                        onRefresh: onRefresh,
                        onOrderConfirmed: onOrderConfirmed,
                        onOrderAction: onOrderAction,
                        onLoadMore: onLoadMore
                    )
                }

                if let orderBookData = configuration.orderBookData {
                    StockDetailOrderBook(data: orderBookData)
                }

                if let brokerOrderBookData = configuration.brokerOrderBookData {
                    StockDetailBrokerOrderBook(data: brokerOrderBookData)
                }

                if configuration.variant.showsCapitalDistribution {
                    StockDetailCapitalDistribution(data: configuration.capitalDistributionData)
                }

                if configuration.variant.showsMoneyFlow {
                    moneyFlowCard
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

    private var navbarQuote: StockDetailNavbarQuote {
        StockDetailNavbarQuote(
            session: configuration.quoteData.timestamp.session,
            price: configuration.quoteData.price,
            change: configuration.quoteData.change,
            changePercent: configuration.quoteData.changePercent,
            trend: configuration.quoteData.trend.navbarTrend
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

    private func resetPageState() {
        selectedTab = .quote
        isQuoteDetailsExpanded = false
        relatedInfoInteraction = .init()
        quoteScrollOffset = 0
    }

    private var moneyFlowCard: some View {
        StockDetailMoneyFlowTrend(data: configuration.moneyFlowData)
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
        switch language {
        case .simplifiedChinese:
            "提示:本页面仅供阁下参考，并非有鱼智能科技有限公司(以下简称「有鱼」)的官方立场，亦不构成任何投资决策的招揽、邀约和建议。由于资料或数据可能得自第三方，有鱼将尽可能确认资料来源之可靠性，但有鱼并不对第三方所提供数据或资料之准确性负责，且有鱼不会就本页面所载任何资料、预测及/或意见的公平性、准确性、时限性、完整性或正确性，以及任何该等预测及/或意见所依据的基准作出任何明文或暗示的保证、陈述、担保或承诺而负责或承担法律责任。务请阁下注意，投资涉及风险，证券及投资的价值可升亦可跌，过往的表现不一定可以预示日后的表现。如有疑问，请咨询阁下的专业顾问。"
        case .traditionalChinese:
            "提示:本頁面僅供閣下參考，並非有魚智能科技有限公司(以下簡稱「有魚」)的官方立場，亦不構成任何投資決策的招攬、邀約和建議。由於資料或數據可能得自第三方，有魚將盡可能確認資料來源之可靠性，但有魚並不對第三方所提供數據或資料之準確性負責，且有魚不會就本頁面所載任何資料、預測及/或意見的公平性、準確性、時限性、完整性或正確性，以及任何該等預測及/或意見所依據的基準作出任何明文或暗示的保證、陳述、擔保或承諾而負責或承擔法律責任。務請閣下注意，投資涉及風險，證券及投資的價值可升亦可跌，過往的表現不一定可以預示日後的表現。如有疑問，請諮詢閣下的專業顧問。"
        case .english:
            "Notice: This page is for reference only and does not represent the official position of Yuu Smart Technology Limited (\"Yuu\"), nor does it constitute a solicitation, invitation, or recommendation to make any investment decision. Information may come from third parties. Yuu makes no express or implied representation or warranty as to its fairness, accuracy, timeliness, completeness, or correctness. Investment involves risk, and the value of securities and investments may rise or fall. Past performance is not indicative of future results. Please consult your professional adviser if you have any questions."
        }
    }

    private var fixedBottomActionBar: some View {
        VStack(spacing: 0) {
            StockDetailBottomActionBar(
                onTrade: onTrade,
                onWatchlist: onWatchlist,
                onReminder: onReminder
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

    @Environment(\.dismiss) private var dismiss
    @Environment(\.demoLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(language.text(.debug))
                    .modifier(CustomFontModifier(size: 20, font: .bold, lineHeight: 28))
                    .foregroundColor(Color("color-text-30"))

                Spacer()

                Button(language.text(.done)) {
                    dismiss()
                }
                .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                .foregroundColor(Color("color-brand-blue"))
                .accessibilityIdentifier("stockDetail.debug.done")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

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

        return switch (variant, language) {
        case (.hongKongStock, .simplifiedChinese):
            "港股正股"
        case (.hongKongStock, .traditionalChinese):
            "港股正股"
        case (.hongKongStock, .english):
            "HK Stock"
        case (.hongKongETF, .simplifiedChinese):
            "港股 ETF"
        case (.hongKongETF, .traditionalChinese):
            "港股 ETF"
        case (.hongKongETF, .english):
            "HK ETF"
        case (.usStock, .simplifiedChinese):
            "美股正股"
        case (.usStock, .traditionalChinese):
            "美股正股"
        case (.usStock, .english):
            "US Stock"
        case (.usETF, .simplifiedChinese):
            "美股 ETF"
        case (.usETF, .traditionalChinese):
            "美股 ETF"
        case (.usETF, .english):
            "US ETF"
        case (.aShareStock, .simplifiedChinese):
            "沪深正股"
        case (.aShareStock, .traditionalChinese):
            "滬深正股"
        case (.aShareStock, .english):
            "A-Share Stock"
        case (.aShareETF, .simplifiedChinese):
            "沪深 ETF"
        case (.aShareETF, .traditionalChinese):
            "滬深 ETF"
        case (.aShareETF, .english):
            "A-Share ETF"
        case (.crypto, .simplifiedChinese):
            "加密货币"
        case (.crypto, .traditionalChinese):
            "加密貨幣"
        case (.crypto, .english):
            "Crypto"
        case (.fallback, .simplifiedChinese):
            "其他"
        case (.fallback, .traditionalChinese):
            "其他"
        case (.fallback, .english):
            "Other"
        }
    }

    private func displayName(for instrument: StockDetailInstrument) -> String {
        instrument.localizationID.map {
            language.securityName(id: $0, fallback: instrument.fallbackName)
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
                .previewDisplayName("港股正股 · 可交互")

            StockDetailPage(instrument: StockDetailDebugSamples.all[1])
                .environment(\.demoLanguage, .english)
                .preferredColorScheme(.dark)
                .previewDisplayName("HK ETF · English · Dark")

            StockDetailPage(instrument: StockDetailDebugSamples.all[2])
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("美股正股 · Debug 可切换")

            StockDetailPage(instrument: StockDetailDebugSamples.all[3])
                .environment(\.demoLanguage, .english)
                .previewDisplayName("US ETF · English")

            StockDetailPage(instrument: StockDetailDebugSamples.all[4])
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("沪深正股")

            StockDetailPage(instrument: StockDetailDebugSamples.all[5])
                .environment(\.demoLanguage, .english)
                .previewDisplayName("A-Share ETF · English")

            StockDetailPage(instrument: StockDetailDebugSamples.all[6])
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("加密货币")
        }
        .previewLayout(.fixed(width: 402, height: 874))
    }
}
