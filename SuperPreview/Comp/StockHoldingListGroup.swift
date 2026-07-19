//
//  StockHoldingListGroup.swift
//  SuperPreview
//

import SwiftUI

enum StockHoldingMarket: String, CaseIterable, Identifiable {
    case hongKong
    case chinaA
    case unitedStates

    var id: Self { self }

    var title: String {
        switch self {
        case .hongKong:
            return "港股· HKD"
        case .chinaA:
            return "A股·CNY"
        case .unitedStates:
            return "美股·USD"
        }
    }

    var flagImageName: String {
        switch self {
        case .hongKong:
            return "subasset_flag_hkd"
        case .chinaA:
            return "subasset_flag_cny"
        case .unitedStates:
            return "subasset_flag_usd"
        }
    }
}

enum StockHoldingValueTone {
    case gain
    case loss
    case neutral

    var color: Color {
        switch self {
        case .gain:
            return Color("color-utility2-red")
        case .loss:
            return Color("color-utility3-green")
        case .neutral:
            return Color("color-text-30")
        }
    }
}

struct StockHoldingItem: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let marketValue: String
    let quantity: String
    let currentPrice: String
    let costPrice: String
    let todayProfitLoss: String
    let todayProfitLossRate: String
    let holdingProfitLoss: String
    let holdingProfitLossRate: String
    let holdingRatio: String
    let todayTone: StockHoldingValueTone
    let holdingTone: StockHoldingValueTone
}

struct StockHoldingMarketSection: Identifiable {
    let market: StockHoldingMarket
    let holdings: [StockHoldingItem]

    var id: StockHoldingMarket { market }
}

extension Array where Element == StockHoldingMarketSection {
    static var preview: [StockHoldingMarketSection] {
        [
        StockHoldingMarketSection(
            market: .hongKong,
            holdings: [
                StockHoldingItem(
                    id: "hk-tencent",
                    name: "腾讯控股",
                    symbol: "00700",
                    marketValue: "420,010.12",
                    quantity: "2,000",
                    currentPrice: "473.120",
                    costPrice: "367.121",
                    todayProfitLoss: "2,473.120",
                    todayProfitLossRate: "+8.12%",
                    holdingProfitLoss: "2,473.120",
                    holdingProfitLossRate: "+8.12%",
                    holdingRatio: "100.00%",
                    todayTone: .gain,
                    holdingTone: .gain
                ),
                StockHoldingItem(
                    id: "hk-hstech",
                    name: "南方恒生科技",
                    symbol: "03033",
                    marketValue: "420,010.12",
                    quantity: "2,000",
                    currentPrice: "473.120",
                    costPrice: "367.121",
                    todayProfitLoss: "2,473.120",
                    todayProfitLossRate: "+8.12%",
                    holdingProfitLoss: "2,473.120",
                    holdingProfitLossRate: "+8.12%",
                    holdingRatio: "100.00%",
                    todayTone: .gain,
                    holdingTone: .gain
                ),
                StockHoldingItem(
                    id: "hk-zhipu",
                    name: "智谱",
                    symbol: "00700",
                    marketValue: "500.00",
                    quantity: "2,000",
                    currentPrice: "398.200",
                    costPrice: "385.600",
                    todayProfitLoss: "96,400.00",
                    todayProfitLossRate: "-3.27%",
                    holdingProfitLoss: "96,400.00",
                    holdingProfitLossRate: "+3.27%",
                    holdingRatio: "100.00%",
                    todayTone: .loss,
                    holdingTone: .loss
                )
            ]
        ),
        StockHoldingMarketSection(
            market: .chinaA,
            holdings: [
                StockHoldingItem(
                    id: "cn-tcl",
                    name: "TCL 科技",
                    symbol: "000100",
                    marketValue: "420,010.12",
                    quantity: "2,000",
                    currentPrice: "473.120",
                    costPrice: "367.121",
                    todayProfitLoss: "2,473.120",
                    todayProfitLossRate: "+8.12%",
                    holdingProfitLoss: "2,473.120",
                    holdingProfitLossRate: "+8.12%",
                    holdingRatio: "100.00%",
                    todayTone: .gain,
                    holdingTone: .gain
                ),
                StockHoldingItem(
                    id: "cn-powerchina",
                    name: "中国电建",
                    symbol: "601669",
                    marketValue: "50,300.50",
                    quantity: "3,500",
                    currentPrice: "85.600",
                    costPrice: "72.450",
                    todayProfitLoss: "1,285.600",
                    todayProfitLossRate: "-5.23%",
                    holdingProfitLoss: "1,285.600",
                    holdingProfitLossRate: "-5.23%",
                    holdingRatio: "100.00%",
                    todayTone: .loss,
                    holdingTone: .loss
                ),
                StockHoldingItem(
                    id: "cn-moutai",
                    name: "贵州茅台",
                    symbol: "600519",
                    marketValue: "89,650.00",
                    quantity: "1,200",
                    currentPrice: "158.540",
                    costPrice: "152.320",
                    todayProfitLoss: "762.080",
                    todayProfitLossRate: "+2.35%",
                    holdingProfitLoss: "808.000",
                    holdingProfitLossRate: "+3.76%",
                    holdingRatio: "100.00%",
                    todayTone: .loss,
                    holdingTone: .loss
                )
            ]
        ),
        StockHoldingMarketSection(
            market: .unitedStates,
            holdings: [
                StockHoldingItem(
                    id: "us-apple",
                    name: "苹果",
                    symbol: "AAPL",
                    marketValue: "52,800",
                    quantity: "1,600",
                    currentPrice: "220.50",
                    costPrice: "185.32",
                    todayProfitLoss: "5,624",
                    todayProfitLossRate: "+1.59%",
                    holdingProfitLoss: "56,288",
                    holdingProfitLossRate: "+18.97%",
                    holdingRatio: "45.20%",
                    todayTone: .gain,
                    holdingTone: .gain
                ),
                StockHoldingItem(
                    id: "us-nvidia",
                    name: "英伟达",
                    symbol: "NVDA",
                    marketValue: "268,500",
                    quantity: "2,000",
                    currentPrice: "134.25",
                    costPrice: "112.68",
                    todayProfitLoss: "3,760",
                    todayProfitLossRate: "+2.86%",
                    holdingProfitLoss: "43,140",
                    holdingProfitLossRate: "+19.13%",
                    holdingRatio: "34.40%",
                    todayTone: .loss,
                    holdingTone: .loss
                ),
                StockHoldingItem(
                    id: "us-tesla",
                    name: "特斯拉",
                    symbol: "TSLA",
                    marketValue: "159,120",
                    quantity: "480",
                    currentPrice: "331.50",
                    costPrice: "289.75",
                    todayProfitLoss: "-4,320",
                    todayProfitLossRate: "-2.64%",
                    holdingProfitLoss: "20,040",
                    holdingProfitLossRate: "+14.40%",
                    holdingRatio: "20.40%",
                    todayTone: .loss,
                    holdingTone: .loss
                )
            ]
        )
        ]
    }
}

struct StockHoldingListGroup: View {
    let sections: [StockHoldingMarketSection]
    let isNumberHidden: Bool
    let onQuote: (StockHoldingItem) -> Void
    let onOrder: (StockHoldingItem) -> Void
    let onDetails: (StockHoldingItem) -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var collapsedMarkets: Set<StockHoldingMarket>
    @State private var expandedHoldingID: StockHoldingItem.ID?

    init(
        sections: [StockHoldingMarketSection] = .preview,
        isNumberHidden: Bool = false,
        initiallyCollapsedMarkets: Set<StockHoldingMarket> = [],
        initiallyExpandedHoldingID: StockHoldingItem.ID? = nil,
        onQuote: @escaping (StockHoldingItem) -> Void = { _ in },
        onOrder: @escaping (StockHoldingItem) -> Void = { _ in },
        onDetails: @escaping (StockHoldingItem) -> Void = { _ in }
    ) {
        self.sections = sections
        self.isNumberHidden = isNumberHidden
        self.onQuote = onQuote
        self.onOrder = onOrder
        self.onDetails = onDetails
        _collapsedMarkets = State(
            initialValue: TradeAggregationExpansionState.restoredCollapsed(
                for: TradeAggregationExpansionStorageKey.stockHoldingGroups,
                fallback: initiallyCollapsedMarkets
            )
        )
        _expandedHoldingID = State(initialValue: initiallyExpandedHoldingID)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView(.horizontal, showsIndicators: false) {
                scrollableContent
            }
            .frame(width: StockHoldingLayout.viewportWidth, height: contentHeight)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)

            fixedContent
        }
        .frame(
            width: StockHoldingLayout.viewportWidth,
            height: contentHeight,
            alignment: .topLeading
        )
        .background(Color("color-base-1"))
        .clipped()
    }

    private var scrollableContent: some View {
        VStack(alignment: .leading, spacing: StockHoldingLayout.sectionSpacing) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: StockHoldingLayout.sectionSpacing) {
                    Color.clear
                        .frame(
                            width: StockHoldingLayout.contentWidth,
                            height: StockHoldingLayout.marketHeaderHeight
                        )

                    if isMarketExpanded(section.market) {
                        StockHoldingScrollableMarketTable(
                            holdings: section.holdings,
                            isNumberHidden: isNumberHidden,
                            expandedHoldingID: expandedHoldingID,
                            onHoldingTap: toggleHolding
                        )
                    }

                    Color.clear
                        .frame(
                            width: StockHoldingLayout.contentWidth,
                            height: StockHoldingLayout.separatorAreaHeight
                        )
                }
            }
        }
        .frame(width: StockHoldingLayout.contentWidth, alignment: .topLeading)
    }

    private var fixedContent: some View {
        VStack(alignment: .leading, spacing: StockHoldingLayout.sectionSpacing) {
            ForEach(sections) { section in
                StockHoldingFixedMarketSection(
                    section: section,
                    isMarketExpanded: isMarketExpanded(section.market),
                    isNumberHidden: isNumberHidden,
                    expandedHoldingID: expandedHoldingID,
                    toggleMarket: { toggleMarket(section.market) },
                    onQuote: onQuote,
                    onOrder: onOrder,
                    onDetails: onDetails
                )
            }
        }
        .frame(width: StockHoldingLayout.viewportWidth, alignment: .topLeading)
    }

    private var contentHeight: CGFloat {
        var height = CGFloat(max(sections.count - 1, 0))
            * StockHoldingLayout.sectionSpacing

        for section in sections {
            height += StockHoldingLayout.collapsedSectionHeight

            if isMarketExpanded(section.market) {
                height += StockHoldingLayout.sectionSpacing
                    + tableHeight(for: section)
            }
        }

        return height
    }

    private func tableHeight(for section: StockHoldingMarketSection) -> CGFloat {
        StockHoldingLayout.headerHeight
            + section.holdings.reduce(CGFloat.zero) {
                $0 + rowHeight(for: $1)
            }
    }

    private func rowHeight(for holding: StockHoldingItem) -> CGFloat {
        expandedHoldingID == holding.id
            ? StockHoldingLayout.expandedRowHeight
            : StockHoldingLayout.rowHeight
    }

    private func isMarketExpanded(_ market: StockHoldingMarket) -> Bool {
        !collapsedMarkets.contains(market)
    }

    private func toggleMarket(_ market: StockHoldingMarket) {
        if collapsedMarkets.contains(market) {
            collapsedMarkets.remove(market)
        } else {
            collapsedMarkets.insert(market)

            if let section = sections.first(where: { $0.market == market }),
               section.holdings.contains(where: { $0.id == expandedHoldingID }) {
                expandedHoldingID = nil
            }
        }

        TradeAggregationExpansionState.saveCollapsed(
            collapsedMarkets,
            for: TradeAggregationExpansionStorageKey.stockHoldingGroups
        )
    }

    private func toggleHolding(_ holding: StockHoldingItem) {
        withAnimation(
            SubAssetCardMotion.expansion(
                reduceMotion: accessibilityReduceMotion
            )
        ) {
            expandedHoldingID = expandedHoldingID == holding.id ? nil : holding.id
        }
    }
}

private enum StockHoldingLayout {
    static let viewportWidth: CGFloat = 402
    static let contentWidth: CGFloat = 622
    static let sectionSpacing: CGFloat = 10
    static let marketHeaderHeight: CGFloat = 20
    static let separatorAreaHeight: CGFloat = 1
    static let collapsedSectionHeight: CGFloat = marketHeaderHeight
        + sectionSpacing
        + separatorAreaHeight
    static let nameWidth: CGFloat = 126
    static let metricsLeadingInset: CGFloat = 134
    static let metricWidth: CGFloat = 88
    static let metricSpacing: CGFloat = 8
    static let trailingInset: CGFloat = 16
    static let headerHeight: CGFloat = 32
    static let rowHeight: CGFloat = 62
    static let actionHeight: CGFloat = 64
    static let actionAreaHeight: CGFloat = actionHeight + 16
    static let expandedRowHeight: CGFloat = rowHeight + actionAreaHeight
}

private struct StockHoldingMarketHeader: View {
    let market: StockHoldingMarket
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(market.flagImageName)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)

                Text(market.title)
                    .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                    .foregroundColor(Color("color-text-30"))
                    .frame(height: 20)

                Spacer(minLength: 0)

                Image("holding_market_chevron")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(isExpanded ? 0 : 180))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .frame(
                width: StockHoldingLayout.viewportWidth,
                height: StockHoldingLayout.marketHeaderHeight
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(market.title)
        .accessibilityValue(isExpanded ? "已展开" : "已收起")
        .accessibilityHint(isExpanded ? "双击收起持仓" : "双击展开持仓")
    }
}

private struct StockHoldingScrollableMarketTable: View {
    let holdings: [StockHoldingItem]
    let isNumberHidden: Bool
    let expandedHoldingID: StockHoldingItem.ID?
    let onHoldingTap: (StockHoldingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StockHoldingScrollableHeader()

            ForEach(holdings) { holding in
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        onHoldingTap(holding)
                    } label: {
                        StockHoldingMetricsRow(
                            holding: holding,
                            isNumberHidden: isNumberHidden
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("\(holding.name)，\(holding.symbol)")
                    .accessibilityValue(isNumberHidden ? "数值已隐藏" : "持仓数据已显示")
                    .accessibilityHint(
                        expandedHoldingID == holding.id
                            ? "双击收起快捷操作"
                            : "双击展开快捷操作"
                    )

                    Color.clear
                        .frame(
                            width: StockHoldingLayout.contentWidth,
                            height: StockHoldingLayout.actionAreaHeight
                        )
                        .subAssetExpansion(
                            isExpanded: expandedHoldingID == holding.id,
                            blurRadius: 0
                        )
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(width: StockHoldingLayout.contentWidth, alignment: .topLeading)
        .background(Color("color-base-1"))
    }
}

private struct StockHoldingFixedMarketSection: View {
    let section: StockHoldingMarketSection
    let isMarketExpanded: Bool
    let isNumberHidden: Bool
    let expandedHoldingID: StockHoldingItem.ID?
    let toggleMarket: () -> Void
    let onQuote: (StockHoldingItem) -> Void
    let onOrder: (StockHoldingItem) -> Void
    let onDetails: (StockHoldingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: StockHoldingLayout.sectionSpacing) {
            StockHoldingMarketHeader(
                market: section.market,
                isExpanded: isMarketExpanded,
                action: toggleMarket
            )

            if isMarketExpanded {
                StockHoldingFixedMarketTable(
                    holdings: section.holdings,
                    isNumberHidden: isNumberHidden,
                    expandedHoldingID: expandedHoldingID,
                    onQuote: onQuote,
                    onOrder: onOrder,
                    onDetails: onDetails
                )
            }

            StockHoldingSeparator()
                .allowsHitTesting(false)
        }
    }
}

private struct StockHoldingFixedMarketTable: View {
    let holdings: [StockHoldingItem]
    let isNumberHidden: Bool
    let expandedHoldingID: StockHoldingItem.ID?
    let onQuote: (StockHoldingItem) -> Void
    let onOrder: (StockHoldingItem) -> Void
    let onDetails: (StockHoldingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StockHoldingNameHeader()
                .allowsHitTesting(false)

            ForEach(holdings) { holding in
                VStack(alignment: .leading, spacing: 0) {
                    StockHoldingNameCell(
                        holding: holding,
                        isNumberHidden: isNumberHidden
                    )
                    .allowsHitTesting(false)

                    StockHoldingActionBar(
                        holding: holding,
                        onQuote: onQuote,
                        onOrder: onOrder,
                        onDetails: onDetails
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .frame(
                        width: StockHoldingLayout.viewportWidth,
                        height: StockHoldingLayout.actionAreaHeight,
                        alignment: .topLeading
                    )
                    .subAssetExpansion(
                        isExpanded: expandedHoldingID == holding.id,
                        blurRadius: expandedHoldingID == holding.id ? 0 : 5
                    )
                }
                .frame(width: StockHoldingLayout.viewportWidth, alignment: .topLeading)
            }
        }
        .frame(width: StockHoldingLayout.viewportWidth, alignment: .topLeading)
    }
}

private struct StockHoldingScrollableHeader: View {
    private let columns: [(title: String, imageName: String)] = [
        ("市值/持有", "holding_sort_descending"),
        ("现价/成本", "holding_sort_default"),
        ("今日盈亏", "holding_sort_default"),
        ("持仓盈亏", "holding_sort_default"),
        ("持仓占比", "holding_sort_default")
    ]

    var body: some View {
        HStack(spacing: StockHoldingLayout.metricSpacing) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                HStack(spacing: 2) {
                    Text(column.title)
                        .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
                        .foregroundColor(Color("color-text-60"))
                        .lineLimit(1)

                    Image(column.imageName)
                        .resizable()
                        .frame(width: 8, height: 16)
                        .accessibilityHidden(true)
                }
                .frame(width: StockHoldingLayout.metricWidth, height: 16, alignment: .trailing)
            }
        }
        .padding(.leading, StockHoldingLayout.metricsLeadingInset)
        .padding(.trailing, StockHoldingLayout.trailingInset)
        .padding(.top, 8)
        .frame(
            width: StockHoldingLayout.contentWidth,
            height: StockHoldingLayout.headerHeight,
            alignment: .top
        )
        .background(Color("color-base-1"))
    }
}

private struct StockHoldingNameHeader: View {
    var body: some View {
        Text("名称")
            .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
            .foregroundColor(Color("color-text-60"))
            .frame(width: 110, height: 16, alignment: .leading)
            .padding(.leading, 16)
            .padding(.top, 8)
            .frame(
                width: StockHoldingLayout.nameWidth,
                height: StockHoldingLayout.headerHeight,
                alignment: .topLeading
            )
            .background(Color("color-base-1"))
    }
}

private struct StockHoldingNameCell: View {
    let holding: StockHoldingItem
    let isNumberHidden: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(display(holding.name))
                .font(.custom("PlusJakartaSans-Regular", size: 16, relativeTo: .body))
                .foregroundColor(Color("color-text-30"))
                .frame(width: 110, height: 24, alignment: .leading)

            Text(display(holding.symbol))
                .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                .foregroundColor(Color(isNumberHidden ? "color-text-30" : "color-text-60"))
                .frame(width: 110, height: 20, alignment: .leading)
        }
        .padding(.leading, 16)
        .frame(
            width: StockHoldingLayout.nameWidth,
            height: StockHoldingLayout.rowHeight,
            alignment: .leading
        )
        .background(Color("color-base-1"))
    }

    private func display(_ value: String) -> String {
        isNumberHidden ? "***" : value
    }
}

private struct StockHoldingMetricsRow: View {
    let holding: StockHoldingItem
    let isNumberHidden: Bool

    var body: some View {
        HStack(spacing: StockHoldingLayout.metricSpacing) {
            valuePair(
                primary: holding.marketValue,
                secondary: holding.quantity,
                primaryColor: Color("color-text-30"),
                secondaryColor: Color("color-text-60")
            )

            valuePair(
                primary: holding.currentPrice,
                secondary: holding.costPrice,
                primaryColor: Color("color-text-30"),
                secondaryColor: Color("color-text-60")
            )

            valuePair(
                primary: holding.todayProfitLoss,
                secondary: holding.todayProfitLossRate,
                primaryColor: holding.todayTone.color,
                secondaryColor: holding.todayTone.color
            )

            valuePair(
                primary: holding.holdingProfitLoss,
                secondary: holding.holdingProfitLossRate,
                primaryColor: holding.holdingTone.color,
                secondaryColor: holding.holdingTone.color
            )

            valuePair(
                primary: holding.holdingRatio,
                secondary: nil,
                primaryColor: Color("color-text-30"),
                secondaryColor: Color("color-text-30")
            )
        }
        .padding(.leading, StockHoldingLayout.metricsLeadingInset)
        .padding(.trailing, StockHoldingLayout.trailingInset)
        .padding(.top, 8)
        .frame(
            width: StockHoldingLayout.contentWidth,
            height: StockHoldingLayout.rowHeight,
            alignment: .top
        )
        .background(Color("color-base-1"))
    }

    private func valuePair(
        primary: String,
        secondary: String?,
        primaryColor: Color,
        secondaryColor: Color
    ) -> some View {
        StockHoldingValuePairCell(
            primary: isNumberHidden ? "***" : primary,
            secondary: secondary.map { isNumberHidden ? "***" : $0 },
            primaryColor: isNumberHidden ? Color("color-text-30") : primaryColor,
            secondaryColor: isNumberHidden ? Color("color-text-30") : secondaryColor
        )
    }
}

private struct StockHoldingValuePairCell: View {
    let primary: String
    let secondary: String?
    let primaryColor: Color
    let secondaryColor: Color

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(primary)
                .font(.custom("PlusJakartaSans-Regular", size: 16, relativeTo: .body))
                .foregroundColor(primaryColor)
                .frame(width: StockHoldingLayout.metricWidth, height: 24, alignment: .trailing)
                .lineLimit(1)

            if let secondary {
                Text(secondary)
                    .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                    .foregroundColor(secondaryColor)
                    .frame(width: StockHoldingLayout.metricWidth, height: 20, alignment: .trailing)
                    .lineLimit(1)
            }
        }
        .frame(width: StockHoldingLayout.metricWidth, height: 46, alignment: .topTrailing)
    }
}

private struct StockHoldingActionBar: View {
    let holding: StockHoldingItem
    let onQuote: (StockHoldingItem) -> Void
    let onOrder: (StockHoldingItem) -> Void
    let onDetails: (StockHoldingItem) -> Void

    var body: some View {
        HStack(spacing: 2) {
            actionButton("行情", position: .leading) {
                onQuote(holding)
            }

            actionButton("下单", position: .middle) {
                onOrder(holding)
            }

            actionButton("详情", position: .trailing) {
                onDetails(holding)
            }
        }
        .frame(width: 370, height: StockHoldingLayout.actionHeight)
    }

    private func actionButton(
        _ title: String,
        position: StockHoldingActionPosition,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                .foregroundColor(Color("color-text-30"))
                .frame(width: 122, height: StockHoldingLayout.actionHeight)
                .background(Color("color-scale-2"))
                .clipShape(
                    UnevenRoundedRectangle(
                        cornerRadii: position.cornerRadii,
                        style: .continuous
                    )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(holding.name)\(title)")
    }
}

private enum StockHoldingActionPosition {
    case leading
    case middle
    case trailing

    var cornerRadii: RectangleCornerRadii {
        switch self {
        case .leading:
            return RectangleCornerRadii(
                topLeading: 12,
                bottomLeading: 12,
                bottomTrailing: 4,
                topTrailing: 4
            )
        case .middle:
            return RectangleCornerRadii(
                topLeading: 4,
                bottomLeading: 4,
                bottomTrailing: 4,
                topTrailing: 4
            )
        case .trailing:
            return RectangleCornerRadii(
                topLeading: 4,
                bottomLeading: 4,
                bottomTrailing: 12,
                topTrailing: 12
            )
        }
    }
}

private struct StockHoldingSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color("color-separator-10"))
            .frame(width: 370, height: 0.5)
            .frame(
                width: StockHoldingLayout.viewportWidth,
                height: StockHoldingLayout.separatorAreaHeight
            )
    }
}

struct StockHoldingListGroup_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockHoldingListGroupPreviewContainer {
                StockHoldingListGroup()
            }
                .previewDisplayName("Default")

            StockHoldingListGroupPreviewContainer {
                StockHoldingListGroup(isNumberHidden: true)
            }
                .previewDisplayName("Numbers Hidden")

            StockHoldingListGroupPreviewContainer {
                StockHoldingListGroup(
                    initiallyCollapsedMarkets: Set(StockHoldingMarket.allCases)
                )
            }
            .previewDisplayName("Markets Collapsed")

            StockHoldingListGroupPreviewContainer {
                StockHoldingListGroup(
                    initiallyCollapsedMarkets: [.chinaA]
                )
            }
            .previewDisplayName("Mixed Market States")
        }
        .previewLayout(.fixed(width: 402, height: 880))
    }
}

private struct StockHoldingListGroupPreviewContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
            Spacer(minLength: 0)
        }
        .frame(
            width: StockHoldingLayout.viewportWidth,
            height: 880,
            alignment: .top
        )
        .background(Color("color-base-1"))
    }
}
