//
//  StockDetailUSCommonStockPage.swift
//  SuperPreview
//

import SwiftUI

/// The top-level sections available for a US common-stock detail page.
///
/// Only quote is populated in this prototype. The other tabs still take part
/// in the real paging interaction so their eventual pages can be added
/// without changing the surrounding navigation shell.
enum StockDetailUSPageTab: CaseIterable, Hashable, Identifiable {
    case quote
    case options
    case etf
    case analysis
    case news
    case financials
    case overview

    var id: Self { self }

    fileprivate func title(for language: DemoLanguage) -> String {
        switch (self, language) {
        case (.quote, .simplifiedChinese):
            "报价"
        case (.quote, .traditionalChinese):
            "報價"
        case (.quote, .english):
            "Quote"
        case (.options, .simplifiedChinese):
            "期权"
        case (.options, .traditionalChinese):
            "期權"
        case (.options, .english):
            "Options"
        case (.etf, _):
            "ETF"
        case (.analysis, .simplifiedChinese):
            "分析"
        case (.analysis, .traditionalChinese):
            "分析"
        case (.analysis, .english):
            "Analysis"
        case (.news, .simplifiedChinese):
            "资讯"
        case (.news, .traditionalChinese):
            "資訊"
        case (.news, .english):
            "News"
        case (.financials, .simplifiedChinese):
            "财务"
        case (.financials, .traditionalChinese):
            "財務"
        case (.financials, .english):
            "Financials"
        case (.overview, .simplifiedChinese):
            "简况"
        case (.overview, .traditionalChinese):
            "簡況"
        case (.overview, .english):
            "Overview"
        }
    }

    fileprivate var accessibilityIdentifier: String {
        switch self {
        case .quote:
            "quote"
        case .options:
            "options"
        case .etf:
            "etf"
        case .analysis:
            "analysis"
        case .news:
            "news"
        case .financials:
            "financials"
        case .overview:
            "overview"
        }
    }
}

/// Compatibility wrapper for the original US common-stock detail entry point.
///
/// The page shell now lives in `StockDetailPage`; this type remains so the
/// existing Compare entry point and component previews do not need to change.
struct StockDetailUSCommonStockPage: View {
    let initialTab: StockDetailUSPageTab

    init(initialTab: StockDetailUSPageTab = .quote) {
        self.initialTab = initialTab
    }

    var body: some View {
        StockDetailPage(
            instrument: .nvidiaPreview,
            initialTab: initialTab.stockDetailPageTab
        )
        .accessibilityIdentifier("stockDetail.usCommonStockPage")
    }
}

private extension StockDetailUSPageTab {
    var stockDetailPageTab: StockDetailPageTab {
        switch self {
        case .quote:
            .quote
        case .options:
            .options
        case .etf:
            .etf
        case .analysis:
            .analysis
        case .news:
            .news
        case .financials:
            .financials
        case .overview:
            .overview
        }
    }
}

private struct StockDetailUSPageHeaderTabs: View {
    @Binding var selection: StockDetailUSPageTab

    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var selectionAnimation: Animation? {
        reduceMotion ? nil : .smooth(duration: 0.32, extraBounce: 0)
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            tabButtonRow
            .padding(.horizontal, StockDetailUSPageHeaderTabsLayout.horizontalPadding)
            .padding(.vertical, StockDetailUSPageHeaderTabsLayout.verticalPadding)
            .animation(selectionAnimation, value: selection)
        }
        .frame(height: StockDetailUSPageHeaderTabsLayout.height)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.usCommonStockPage.headerTabs")
    }

    private var tabButtonRow: some View {
        HStack(spacing: StockDetailUSPageHeaderTabsLayout.tabSpacing) {
            ForEach(StockDetailUSPageTab.allCases) { tab in
                let isSelected = selection == tab
                let title = tab.title(for: language)

                Button {
                    guard selection != tab else { return }
                    selection = tab
                } label: {
                    Text(title)
                        .modifier(
                            CustomFontModifier(
                                size: StockDetailUSPageHeaderTabsLayout.fontSize,
                                font: isSelected ? .bold : .regular,
                                lineHeight: StockDetailUSPageHeaderTabsLayout.lineHeight
                            )
                        )
                        .foregroundColor(isSelected ? Color("color-text-30") : Color("color-text-60"))
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.horizontal, StockDetailUSPageHeaderTabsLayout.itemHorizontalPadding)
                        .padding(.vertical, StockDetailUSPageHeaderTabsLayout.itemVerticalPadding)
                        .frame(height: StockDetailUSPageHeaderTabsLayout.itemHeight)
                        .transaction { transaction in
                            transaction.animation = nil
                        }
                        .anchorPreference(
                            key: StockDetailUSPageTabFramePreferenceKey.self,
                            value: .bounds
                        ) { anchor in
                            [tab: anchor]
                        }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .accessibilityLabel(title)
                .accessibilityIdentifier("stockDetail.usCommonStockPage.headerTab.\(tab.accessibilityIdentifier)")
            }
        }
        .backgroundPreferenceValue(StockDetailUSPageTabFramePreferenceKey.self) { anchors in
            GeometryReader { proxy in
                if let anchor = anchors[selection] {
                    let frame = proxy[anchor]

                    selectionBackground
                        .frame(width: frame.width, height: frame.height)
                        .position(x: frame.midX, y: frame.midY)
                }
            }
        }
    }

    @ViewBuilder
    private var selectionBackground: some View {
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

private struct StockDetailUSPageEmptyView: View {
    let tab: StockDetailUSPageTab

    var body: some View {
        Color("color-base-1")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityLabel(tab.title(for: .simplifiedChinese))
            .accessibilityIdentifier("stockDetail.usCommonStockPage.empty.\(tab.accessibilityIdentifier)")
    }
}

/// The compact one-level order tape used below the transaction module.
///
/// The detail page does not expose the order-form disclosure behavior. The
/// US page therefore supplies one best bid and one best ask directly.
struct StockDetailTapeData: Equatable {
    let distribution: StockOrderBookDistribution
    let bid: StockOrderBookLevel
    let ask: StockOrderBookLevel

    init(
        distribution: StockOrderBookDistribution,
        bid: StockOrderBookLevel,
        ask: StockOrderBookLevel
    ) {
        self.distribution = distribution
        self.bid = bid
        self.ask = ask
    }
}

struct StockDetailTape: View {
    let data: StockDetailTapeData

    @Environment(\.demoLanguage) private var language

    init(data: StockDetailTapeData) {
        self.data = data
    }

    var body: some View {
        VStack(spacing: StockDetailTapeLayout.headerToLevelsSpacing) {
            header
            levels
        }
        .padding(.top, StockDetailTapeLayout.topPadding)
        .padding(.bottom, StockDetailTapeLayout.bottomPadding)
        .padding(.horizontal, StockDetailTapeLayout.horizontalPadding)
        .frame(maxWidth: .infinity)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.tape")
    }

    private var header: some View {
        VStack(spacing: StockDetailTapeLayout.titleToBarSpacing) {
            HStack(spacing: 0) {
                HStack(spacing: StockDetailTapeLayout.titlePercentageSpacing) {
                    Text(language.text(.buyOrderBook))
                        .foregroundColor(Color("color-text-30"))

                    Text(data.distribution.bidPercentage)
                        .foregroundColor(Color("color-utility3-red"))
                        .modifier(
                            CustomFontModifier(
                                size: StockDetailTapeLayout.percentageFontSize,
                                font: .regular,
                                lineHeight: StockDetailTapeLayout.percentageLineHeight
                            )
                        )
                        .monospacedDigit()
                }
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTapeLayout.titleFontSize,
                        font: .regular,
                        lineHeight: StockDetailTapeLayout.titleLineHeight
                    )
                )

                Spacer(minLength: 0)

                HStack(spacing: StockDetailTapeLayout.titlePercentageSpacing) {
                    Text(language.text(.sellOrderBook))
                        .foregroundColor(Color("color-text-30"))

                    Text(data.distribution.askPercentage)
                        .foregroundColor(Color("color-utility3-green"))
                        .modifier(
                            CustomFontModifier(
                                size: StockDetailTapeLayout.percentageFontSize,
                                font: .regular,
                                lineHeight: StockDetailTapeLayout.percentageLineHeight
                            )
                        )
                        .monospacedDigit()
                }
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTapeLayout.titleFontSize,
                        font: .regular,
                        lineHeight: StockDetailTapeLayout.titleLineHeight
                    )
                )
            }
            .frame(height: StockDetailTapeLayout.titleLineHeight)

            GeometryReader { proxy in
                HStack(spacing: 0) {
                    Color("color-utility3-red")
                        .frame(width: proxy.size.width * data.distribution.bidFraction)

                    Color("color-utility3-green")
                }
                .clipShape(Capsule())
            }
            .frame(height: StockDetailTapeLayout.barHeight)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(language.text(.buyOrderBook)) \(data.distribution.bidPercentage), \(language.text(.sellOrderBook)) \(data.distribution.askPercentage)"
        )
        .accessibilityIdentifier("stockDetail.tape.summary")
    }

    private var levels: some View {
        HStack(spacing: 0) {
            levelCell(data.bid, side: .bid)
            levelCell(data.ask, side: .ask)
        }
        .frame(height: StockDetailTapeLayout.levelHeight)
        .clipShape(
            RoundedRectangle(
                cornerRadius: StockDetailTapeLayout.levelCornerRadius,
                style: .continuous
            )
        )
        .accessibilityIdentifier("stockDetail.tape.levels")
    }

    private func levelCell(
        _ level: StockOrderBookLevel,
        side: StockDetailTapeSide
    ) -> some View {
        HStack(spacing: 0) {
            Text(level.price)
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTapeLayout.levelFontSize,
                        font: .regular,
                        lineHeight: StockDetailTapeLayout.levelLineHeight
                    )
                )
                .foregroundColor(side.color)
                .monospacedDigit()
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(level.quantity)
                .modifier(
                    CustomFontModifier(
                        size: StockDetailTapeLayout.levelFontSize,
                        font: .regular,
                        lineHeight: StockDetailTapeLayout.levelLineHeight
                    )
                )
                .foregroundColor(Color("color-text-30"))
                .monospacedDigit()
                .lineLimit(1)
        }
        .padding(.horizontal, StockDetailTapeLayout.levelHorizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(side.color.opacity(StockDetailTapeLayout.levelBackgroundOpacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(level.price), \(level.quantity)")
        .accessibilityIdentifier("stockDetail.tape.\(side.accessibilityIdentifier)")
    }
}

private enum StockDetailTapeSide {
    case bid
    case ask

    var color: Color {
        switch self {
        case .bid:
            Color("color-utility3-red")
        case .ask:
            Color("color-utility3-green")
        }
    }

    var accessibilityIdentifier: String {
        switch self {
        case .bid:
            "bid"
        case .ask:
            "ask"
        }
    }
}

private enum StockDetailUSCommonStockPageLayout {
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

private enum StockDetailUSPageHeaderTabsLayout {
    static let height: CGFloat = 48
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 10
    static let tabSpacing: CGFloat = 2
    static let itemHorizontalPadding: CGFloat = 14
    static let itemVerticalPadding: CGFloat = 4
    static let itemHeight: CGFloat = 28
    static let fontSize: CGFloat = 14
    static let lineHeight: CGFloat = 20
}

private enum StockDetailTapeLayout {
    static let horizontalPadding: CGFloat = 16
    static let topPadding: CGFloat = 10
    static let bottomPadding: CGFloat = 12
    static let headerToLevelsSpacing: CGFloat = 12
    static let titleToBarSpacing: CGFloat = 4
    static let titlePercentageSpacing: CGFloat = 8
    static let titleFontSize: CGFloat = 14
    static let titleLineHeight: CGFloat = 20
    static let percentageFontSize: CGFloat = 12
    static let percentageLineHeight: CGFloat = 16
    static let barHeight: CGFloat = 6
    static let levelHeight: CGFloat = 40
    static let levelHorizontalPadding: CGFloat = 8
    static let levelFontSize: CGFloat = 16
    static let levelLineHeight: CGFloat = 24
    static let levelCornerRadius: CGFloat = 6
    static let levelBackgroundOpacity: CGFloat = 0.1
}

private struct StockDetailUSPageTabFramePreferenceKey: PreferenceKey {
    static var defaultValue: [StockDetailUSPageTab: Anchor<CGRect>] = [:]

    static func reduce(
        value: inout [StockDetailUSPageTab: Anchor<CGRect>],
        nextValue: () -> [StockDetailUSPageTab: Anchor<CGRect>]
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

private enum StockDetailUSCommonStockPageMockData {
    static let symbol: StockOrderSymbol = {
        guard let symbol = StockOrderDemoViewModel.searchableSymbols.first(where: { $0.id == "NVDA" }) else {
            preconditionFailure("Missing NVDA preview symbol")
        }

        return symbol
    }()

    static let quote = StockDetailQuoteDataModel(
        market: .us,
        timestamp: StockDetailQuoteTimestamp(
            session: .preMarketTrading,
            date: "04/03",
            time: "14:44:01",
            timeZone: "(美东)",
            localizedTimeZone: .init(
                simplifiedChinese: "(美东)",
                traditionalChinese: "(美東)",
                english: "(ET)"
            )
        ),
        price: "1,776.740",
        change: "+1.09",
        changePercent: "+0.25%",
        trend: .up,
        summaryItems: [
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "最高", english: "High"),
                value: "16.000",
                tone: .positive
            ),
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "最低", english: "Low"),
                value: "399.000",
                tone: .negative
            ),
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(
                    simplifiedChinese: "成交额",
                    traditionalChinese: "成交額",
                    english: "Turnover"
                ),
                value: "105.12亿",
                localizedValue: .init(
                    simplifiedChinese: "105.12亿",
                    traditionalChinese: "105.12億",
                    english: "10.512B"
                )
            )
        ],
        details: .stockHongKongOrUS
    )

    static let relatedItems: [StockDetailRelatedInfoItem] = [
        StockDetailRelatedInfoItem(
            id: "us-financial-report",
            content: .financialReport(
                StockDetailRelatedInfoFinancialReport(
                    date: "2026/08/10(香港)",
                    event: "公布业绩",
                    localizedDate: .init(
                        simplifiedChinese: "2026/08/10(香港)",
                        traditionalChinese: "2026/08/10(香港)",
                        english: "2026/08/10 (HK)"
                    ),
                    localizedEvent: .init(
                        simplifiedChinese: "公布业绩",
                        traditionalChinese: "公布業績",
                        english: "Earning Release"
                    )
                )
            )
        ),
        StockDetailRelatedInfoItem(
            id: "us-cash-dividend",
            content: .cashDividend(
                StockDetailRelatedInfoCashDividend(
                    summary: "除权除息日:2026/06/13  每股派息3.40001 USD 超过截断",
                    details: [
                        .init(
                            label: "除权除息日",
                            value: "2026/06/13",
                            localizedLabel: .init(
                                simplifiedChinese: "除权除息日",
                                traditionalChinese: "除權除息日",
                                english: "Ex-Date"
                            )
                        ),
                        .init(
                            label: "股权登记日",
                            value: "2026/06/12",
                            localizedLabel: .init(
                                simplifiedChinese: "股权登记日",
                                traditionalChinese: "股權登記日",
                                english: "Record date"
                            )
                        ),
                        .init(
                            label: "派息日",
                            value: "2026/06/20",
                            localizedLabel: .init(
                                simplifiedChinese: "派息日",
                                traditionalChinese: "派息日",
                                english: "Payment date"
                            )
                        )
                    ],
                    localizedSummary: .init(
                        simplifiedChinese: "除权除息日:2026/06/13  每股派息3.40001 USD 超过截断",
                        traditionalChinese: "除權除息日:2026/06/13  每股派息3.40001 USD 超過截斷",
                        english: "Ex-Date 2026/06/13  Dividend per share 3.40001 USD exceeds truncation"
                    )
                )
            )
        ),
        StockDetailRelatedInfoItem(
            id: "us-extended-hours",
            content: .extendedHours(
                StockDetailRelatedInfoExtendedHours(
                    state: .trading,
                    sessionTitle: "盘前",
                    price: "12.300",
                    change: "+2.220",
                    changePercent: "+1.23%",
                    timestamp: "8:01 美东",
                    metrics: [
                        .init(
                            label: "最高价",
                            value: "12.65",
                            tone: .positive,
                            localizedLabel: .init(
                                simplifiedChinese: "最高价",
                                traditionalChinese: "最高價",
                                english: "High"
                            )
                        ),
                        .init(
                            label: "成交额",
                            value: "4001.22万",
                            localizedLabel: .init(
                                simplifiedChinese: "成交额",
                                traditionalChinese: "成交額",
                                english: "Turnover"
                            ),
                            localizedValue: .init(
                                simplifiedChinese: "4001.22万",
                                traditionalChinese: "4001.22萬",
                                english: "40.0122M"
                            )
                        ),
                        .init(
                            label: "最低价",
                            value: "12.45",
                            tone: .negative,
                            localizedLabel: .init(
                                simplifiedChinese: "最低价",
                                traditionalChinese: "最低價",
                                english: "Low"
                            )
                        ),
                        .init(
                            label: "成交量",
                            value: "44.99万股",
                            localizedLabel: .init(
                                simplifiedChinese: "成交量",
                                traditionalChinese: "成交量",
                                english: "Volume"
                            ),
                            localizedValue: .init(
                                simplifiedChinese: "44.99万股",
                                traditionalChinese: "44.99萬股",
                                english: "449.9K shares"
                            )
                        )
                    ],
                    localizedSessionTitle: .init(
                        simplifiedChinese: "盘前",
                        traditionalChinese: "盤前",
                        english: "Pre-market"
                    ),
                    localizedTimestamp: .init(
                        simplifiedChinese: "8:01 美东",
                        traditionalChinese: "8:01 美東",
                        english: "8:01 ET"
                    )
                )
            )
        )
    ]

    static let tape = StockDetailTapeData(
        distribution: StockOrderBookDistribution(
            bidPercentage: "84.22%",
            askPercentage: "15.78%",
            bidFraction: 283.0 / 370.0
        ),
        bid: StockOrderBookLevel(
            price: "16.400",
            quantity: "15K",
            volumeFraction: 0.9
        ),
        ask: StockOrderBookLevel(
            price: "16.500",
            quantity: "10K",
            volumeFraction: 0.29
        )
    )

    static let positionState: StockDetailTransactionPositionState = .position(
        StockDetailTransactionPositionData(
            positionProfitLoss: "+6,100.00",
            positionProfitLossRate: "+9.53%",
            todayProfitLoss: "+1,123.01",
            quantity: "1,500",
            marketValue: "70,100.00",
            costPrice: "293.320",
            portfolioWeight: "8.38%",
            positionProfitLossTone: .gain,
            todayProfitLossTone: .gain
        )
    )

    static let transactionOrders: [StockOrderTodayOrderItem] = [
        StockOrderTodayOrderItem(
            id: "page-nvda-submitted",
            side: .buy,
            status: .submitted,
            productName: "NVIDIA",
            symbol: symbol.id,
            price: "131.700",
            quantity: "500",
            filledQuantity: "0"
        ),
        StockOrderTodayOrderItem(
            id: "page-nvda-partial",
            side: .sell,
            status: .partiallyFilled,
            productName: "NVIDIA",
            symbol: symbol.id,
            price: "132.100",
            quantity: "1,000",
            filledQuantity: "500"
        )
    ]

    static let historyOrders: [StockDetailTransactionHistoryOrderData] = [
        StockDetailTransactionHistoryOrderData(
            id: "page-history-nvda-filled",
            side: .buy,
            status: .filled,
            productName: "NVIDIA",
            symbol: symbol.id,
            price: "128.500",
            quantity: "500",
            orderDate: "26/08/28",
            orderTime: "14:37:06"
        ),
        StockDetailTransactionHistoryOrderData(
            id: "page-history-nvda-cancelled",
            side: .sell,
            status: .cancelled,
            productName: "NVIDIA",
            symbol: symbol.id,
            price: "130.200",
            quantity: "200",
            orderDate: "26/08/27",
            orderTime: "09:42:18"
        )
    ]
}

struct StockDetailUSCommonStockPage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailUSCommonStockPage()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("可交互 · 美股正股 · 报价")

            StockDetailUSCommonStockPage()
                .environment(\.demoLanguage, .english)
                .preferredColorScheme(.dark)
                .previewDisplayName("Swipe tabs · English · Dark")

            StockDetailUSCommonStockPage(initialTab: .options)
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("期权 · 空白页 · 底部操作栏固定")
        }
        .previewLayout(.fixed(width: 402, height: 874))
    }
}
