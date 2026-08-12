//
//  VirtualAssetHoldingListGroup.swift
//  SuperPreview
//

import SwiftUI

enum VirtualAssetHoldingCategory: String, CaseIterable, Identifiable {
    case cryptocurrency
    case rwa

    var id: Self { self }

    func title(language: DemoLanguage) -> String {
        switch self {
        case .cryptocurrency:
            return language.text(.cryptoGroup)
        case .rwa:
            return language.text(.rwaGroup)
        }
    }

    var flagImageName: String {
        "subasset_flag_usd"
    }
}

enum VirtualAssetHoldingValueTone {
    case red
    case green
    case neutral

    var color: Color {
        switch self {
        case .red:
            return Color("color-utility2-red")
        case .green:
            return Color("color-utility3-green")
        case .neutral:
            return Color("color-text-30")
        }
    }
}

enum VirtualAssetHoldingAction: String, Identifiable {
    case quote
    case order
    case details
    case subscribe
    case redeem

    var id: Self { self }

    func title(language: DemoLanguage) -> String {
        switch self {
        case .quote:
            return language.text(.quote)
        case .order:
            return language.text(.order)
        case .details:
            return language.text(.details)
        case .subscribe:
            return language.text(.subscribe)
        case .redeem:
            return language.text(.redeem)
        }
    }
}

enum VirtualAssetHoldingInfoPlacement {
    case head
    case footer
}

struct VirtualAssetHoldingItem: Identifiable {
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
    let todayTone: VirtualAssetHoldingValueTone
    let holdingTone: VirtualAssetHoldingValueTone
}

struct VirtualAssetHoldingSection: Identifiable {
    let category: VirtualAssetHoldingCategory
    let holdings: [VirtualAssetHoldingItem]

    var id: VirtualAssetHoldingCategory { category }

    var actions: [VirtualAssetHoldingAction] {
        switch category {
        case .cryptocurrency:
            return [.quote, .order, .details]
        case .rwa:
            return [.subscribe, .redeem, .quote]
        }
    }
}

extension Array where Element == VirtualAssetHoldingSection {
    static var virtualAssetHoldingPreview: [VirtualAssetHoldingSection] {
        [
            VirtualAssetHoldingSection(
                category: .cryptocurrency,
                holdings: [
                    VirtualAssetHoldingItem(
                        id: "crypto-btc",
                        name: "比特币",
                        symbol: "BTC",
                        marketValue: "52,800",
                        quantity: "1,600",
                        currentPrice: "220.50",
                        costPrice: "185.32",
                        todayProfitLoss: "5,624",
                        todayProfitLossRate: "+1.59%",
                        holdingProfitLoss: "56,288",
                        holdingProfitLossRate: "+18.97%",
                        holdingRatio: "45.20%",
                        todayTone: .red,
                        holdingTone: .red
                    ),
                    VirtualAssetHoldingItem(
                        id: "crypto-eth",
                        name: "以太币",
                        symbol: "ETH",
                        marketValue: "420,010.12",
                        quantity: "2,000",
                        currentPrice: "473.120",
                        costPrice: "367.121",
                        todayProfitLoss: "2,473.120",
                        todayProfitLossRate: "+8.12%",
                        holdingProfitLoss: "2,473.120",
                        holdingProfitLossRate: "+8.12%",
                        holdingRatio: "34.40%",
                        todayTone: .red,
                        holdingTone: .red
                    ),
                    VirtualAssetHoldingItem(
                        id: "crypto-sol",
                        name: "Solana",
                        symbol: "SOL",
                        marketValue: "268,500",
                        quantity: "2,000",
                        currentPrice: "134.25",
                        costPrice: "112.68",
                        todayProfitLoss: "3,760",
                        todayProfitLossRate: "+2.86%",
                        holdingProfitLoss: "43,140",
                        holdingProfitLossRate: "+19.13%",
                        holdingRatio: "34.40%",
                        todayTone: .green,
                        holdingTone: .green
                    )
                ]
            ),
            VirtualAssetHoldingSection(
                category: .rwa,
                holdings: [
                    VirtualAssetHoldingItem(
                        id: "rwa-xaua",
                        name: "黄金代币",
                        symbol: "XAUa",
                        marketValue: "420,010.12",
                        quantity: "2,000",
                        currentPrice: "473.120",
                        costPrice: "367.121",
                        todayProfitLoss: "2,473.120",
                        todayProfitLossRate: "+8.12%",
                        holdingProfitLoss: "2,473.120",
                        holdingProfitLossRate: "+8.12%",
                        holdingRatio: "34.40%",
                        todayTone: .red,
                        holdingTone: .red
                    )
                ]
            )
        ]
    }
}

struct VirtualAssetHoldingListGroup: View {
    let viewportWidth: CGFloat
    let sections: [VirtualAssetHoldingSection]
    let isNumberHidden: Bool
    let onAction: (VirtualAssetHoldingAction, VirtualAssetHoldingItem) -> Void

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var collapsedCategories: Set<VirtualAssetHoldingCategory>
    @State private var expandedHoldingID: VirtualAssetHoldingItem.ID?
    @State private var infoPlacement: VirtualAssetHoldingInfoPlacement

    init(
        viewportWidth: CGFloat,
        sections: [VirtualAssetHoldingSection] = .virtualAssetHoldingPreview,
        isNumberHidden: Bool = false,
        initialInfoPlacement: VirtualAssetHoldingInfoPlacement = .head,
        initiallyCollapsedCategories: Set<VirtualAssetHoldingCategory> = [],
        initiallyExpandedHoldingID: VirtualAssetHoldingItem.ID? = nil,
        onAction: @escaping (
            VirtualAssetHoldingAction,
            VirtualAssetHoldingItem
        ) -> Void = { _, _ in }
    ) {
        self.viewportWidth = viewportWidth
        self.sections = sections
        self.isNumberHidden = isNumberHidden
        self.onAction = onAction
        _collapsedCategories = State(
            initialValue: TradeAggregationExpansionState.restoredCollapsed(
                for: TradeAggregationExpansionStorageKey.virtualAssetHoldingGroups,
                fallback: initiallyCollapsedCategories
            )
        )
        _expandedHoldingID = State(initialValue: initiallyExpandedHoldingID)
        _infoPlacement = State(initialValue: initialInfoPlacement)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView(.horizontal, showsIndicators: false) {
                scrollableContent
            }
            .frame(
                width: viewportWidth,
                height: contentHeight,
                alignment: .topLeading
            )
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .defaultScrollAnchor(.topLeading)
            .zIndex(0)

            fixedContent
                .zIndex(1)
        }
        .frame(
            width: viewportWidth,
            height: contentHeight,
            alignment: .topLeading
        )
        .background(Color("color-base-1"))
        .clipped()
        .environment(\.tradeAggregationViewportWidth, viewportWidth)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("trade.holdingsViewport")
    }

    private var scrollableContent: some View {
        VStack(
            alignment: .leading,
            spacing: VirtualAssetHoldingLayout.sectionSpacing
        ) {
            ForEach(sections) { section in
                VirtualAssetHoldingScrollableSection(
                    section: section,
                    isExpanded: isCategoryExpanded(section.category),
                    showsHeadInfo: showsHeadInfo(for: section.category),
                    showsFooterInfo: showsFooterInfo(for: section.category),
                    isNumberHidden: isNumberHidden,
                    expandedHoldingID: expandedHoldingID,
                    onHoldingTap: toggleHolding
                )
            }
        }
        .frame(
            width: VirtualAssetHoldingLayout.contentWidth,
            height: contentHeight,
            alignment: .topLeading
        )
    }

    private var fixedContent: some View {
        VStack(
            alignment: .leading,
            spacing: VirtualAssetHoldingLayout.sectionSpacing
        ) {
            ForEach(sections) { section in
                VirtualAssetHoldingFixedSection(
                    section: section,
                    isExpanded: isCategoryExpanded(section.category),
                    showsHeadInfo: showsHeadInfo(for: section.category),
                    showsFooterInfo: showsFooterInfo(for: section.category),
                    isNumberHidden: isNumberHidden,
                    expandedHoldingID: expandedHoldingID,
                    toggleCategory: {
                        toggleCategory(section.category)
                    },
                    dismissHeadInfo: dismissHeadInfo,
                    onAction: onAction
                )
            }
        }
        .frame(
            width: viewportWidth,
            height: contentHeight,
            alignment: .topLeading
        )
    }

    private var contentHeight: CGFloat {
        let sectionHeights = sections.reduce(CGFloat.zero) {
            $0 + sectionHeight(for: $1)
        }
        let gaps = CGFloat(max(sections.count - 1, 0))
            * VirtualAssetHoldingLayout.sectionSpacing
        return sectionHeights + gaps
    }

    private func sectionHeight(
        for section: VirtualAssetHoldingSection
    ) -> CGFloat {
        var childCount = 2
        var height = VirtualAssetHoldingLayout.marketHeaderHeight
            + VirtualAssetHoldingLayout.separatorAreaHeight

        if showsHeadInfo(for: section.category) {
            childCount += 1
            height += VirtualAssetHoldingLayout.headInfoHeight
        }

        if isCategoryExpanded(section.category) {
            childCount += 1
            height += tableHeight(for: section)
        }

        if showsFooterInfo(for: section.category) {
            childCount += 1
            height += VirtualAssetHoldingLayout.footerInfoHeight
        }

        return height
            + CGFloat(childCount - 1) * VirtualAssetHoldingLayout.sectionContentSpacing
    }

    private func tableHeight(
        for section: VirtualAssetHoldingSection
    ) -> CGFloat {
        VirtualAssetHoldingLayout.headerHeight
            + section.holdings.reduce(CGFloat.zero) {
                $0 + rowHeight(for: $1)
            }
    }

    private func rowHeight(for holding: VirtualAssetHoldingItem) -> CGFloat {
        expandedHoldingID == holding.id
            ? VirtualAssetHoldingLayout.expandedRowHeight
            : VirtualAssetHoldingLayout.rowHeight
    }

    private func isCategoryExpanded(
        _ category: VirtualAssetHoldingCategory
    ) -> Bool {
        !collapsedCategories.contains(category)
    }

    private func showsHeadInfo(
        for category: VirtualAssetHoldingCategory
    ) -> Bool {
        category == .cryptocurrency
            && isCategoryExpanded(category)
            && infoPlacement == .head
    }

    private func showsFooterInfo(
        for category: VirtualAssetHoldingCategory
    ) -> Bool {
        category == .cryptocurrency
            && isCategoryExpanded(category)
            && infoPlacement == .footer
    }

    private func toggleCategory(_ category: VirtualAssetHoldingCategory) {
        if collapsedCategories.contains(category) {
            collapsedCategories.remove(category)
        } else {
            collapsedCategories.insert(category)

            if let section = sections.first(where: { $0.category == category }),
               section.holdings.contains(where: { $0.id == expandedHoldingID }) {
                expandedHoldingID = nil
            }
        }

        TradeAggregationExpansionState.saveCollapsed(
            collapsedCategories,
            for: TradeAggregationExpansionStorageKey.virtualAssetHoldingGroups
        )
    }

    private func toggleHolding(_ holding: VirtualAssetHoldingItem) {
        withAnimation(
            SubAssetCardMotion.expansion(
                reduceMotion: accessibilityReduceMotion
            )
        ) {
            expandedHoldingID = expandedHoldingID == holding.id ? nil : holding.id
        }
    }

    private func dismissHeadInfo() {
        infoPlacement = .footer
    }
}

private enum VirtualAssetHoldingLayout {
    static let contentWidth: CGFloat = 622
    static let sectionSpacing: CGFloat = 10
    static let sectionContentSpacing: CGFloat = 10
    static let marketHeaderHeight: CGFloat = 20
    static let headInfoHeight: CGFloat = 52
    static let footerInfoHeight: CGFloat = 40
    static let separatorAreaHeight: CGFloat = 1
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

private struct VirtualAssetHoldingScrollableSection: View {
    let section: VirtualAssetHoldingSection
    let isExpanded: Bool
    let showsHeadInfo: Bool
    let showsFooterInfo: Bool
    let isNumberHidden: Bool
    let expandedHoldingID: VirtualAssetHoldingItem.ID?
    let onHoldingTap: (VirtualAssetHoldingItem) -> Void

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: VirtualAssetHoldingLayout.sectionContentSpacing
        ) {
            placeholder(height: VirtualAssetHoldingLayout.marketHeaderHeight)

            if showsHeadInfo {
                placeholder(height: VirtualAssetHoldingLayout.headInfoHeight)
            }

            if isExpanded {
                VirtualAssetHoldingScrollableTable(
                    holdings: section.holdings,
                    isNumberHidden: isNumberHidden,
                    expandedHoldingID: expandedHoldingID,
                    onHoldingTap: onHoldingTap
                )
            }

            if showsFooterInfo {
                placeholder(height: VirtualAssetHoldingLayout.footerInfoHeight)
            }

            placeholder(height: VirtualAssetHoldingLayout.separatorAreaHeight)
        }
    }

    private func placeholder(height: CGFloat) -> some View {
        Color.clear.frame(
            width: VirtualAssetHoldingLayout.contentWidth,
            height: height
        )
    }
}

private struct VirtualAssetHoldingFixedSection: View {
    @Environment(\.tradeAggregationViewportWidth) private var viewportWidth

    let section: VirtualAssetHoldingSection
    let isExpanded: Bool
    let showsHeadInfo: Bool
    let showsFooterInfo: Bool
    let isNumberHidden: Bool
    let expandedHoldingID: VirtualAssetHoldingItem.ID?
    let toggleCategory: () -> Void
    let dismissHeadInfo: () -> Void
    let onAction: (VirtualAssetHoldingAction, VirtualAssetHoldingItem) -> Void

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: VirtualAssetHoldingLayout.sectionContentSpacing
        ) {
            Color.clear
                .frame(
                    width: viewportWidth,
                    height: VirtualAssetHoldingLayout.marketHeaderHeight
                )
                .allowsHitTesting(false)

            if showsHeadInfo {
                VirtualAssetHoldingHeadInfo(action: dismissHeadInfo)
            }

            if isExpanded {
                VirtualAssetHoldingFixedTable(
                    section: section,
                    isNumberHidden: isNumberHidden,
                    expandedHoldingID: expandedHoldingID,
                    onAction: onAction
                )
            }

            if showsFooterInfo {
                VirtualAssetHoldingFooterInfo()
            }

            VirtualAssetHoldingSeparator()
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topLeading) {
            VirtualAssetHoldingMarketHeader(
                category: section.category,
                isExpanded: isExpanded,
                action: toggleCategory
            )
            .background(Color("color-base-1"))
            .zIndex(1)
        }
    }
}

private struct VirtualAssetHoldingMarketHeader: View {
    @Environment(\.tradeAggregationViewportWidth) private var viewportWidth
    @Environment(\.demoLanguage) private var language

    let category: VirtualAssetHoldingCategory
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(category.flagImageName)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)

                Text(category.title(language: language))
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
                width: viewportWidth,
                height: VirtualAssetHoldingLayout.marketHeaderHeight
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(category.title(language: language))
        .accessibilityValue(language.text(isExpanded ? .expanded : .collapsed))
        .accessibilityHint(language.text(isExpanded ? .collapsePositions : .expandPositions))
        .accessibilityIdentifier("trade.virtualGroup.\(category.rawValue)")
    }
}

private struct VirtualAssetHoldingHeadInfo: View {
    @Environment(\.tradeAggregationViewportWidth) private var viewportWidth

    let action: () -> Void
    @Environment(\.demoLanguage) private var language

    var body: some View {
        HStack(spacing: 0) {
            Text(language.text(.cryptoPricingInfo))
                .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                .foregroundColor(Color("color-text-60"))
                .frame(width: max(viewportWidth - 72, 0), height: 40, alignment: .leading)
                .lineLimit(2)

            Button(action: action) {
                Image("virtual_holding_close")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(language.text(.closePricingInformation))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(width: max(viewportWidth - 32, 0), height: VirtualAssetHoldingLayout.headInfoHeight)
        .background(Color("color-scale-1"))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color("color-separator-10"), lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .frame(
            width: viewportWidth,
            height: VirtualAssetHoldingLayout.headInfoHeight
        )
    }
}

private struct VirtualAssetHoldingFooterInfo: View {
    @Environment(\.tradeAggregationViewportWidth) private var viewportWidth
    @Environment(\.demoLanguage) private var language

    var body: some View {
        Text(language.text(.cryptoPricingInfo))
            .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
            .foregroundColor(Color("color-text-60"))
            .frame(
                width: max(viewportWidth - 32, 0),
                height: VirtualAssetHoldingLayout.footerInfoHeight,
                alignment: .leading
            )
            .lineLimit(2)
            .frame(
                width: viewportWidth,
                height: VirtualAssetHoldingLayout.footerInfoHeight
            )
    }
}

private struct VirtualAssetHoldingScrollableTable: View {
    let holdings: [VirtualAssetHoldingItem]
    let isNumberHidden: Bool
    let expandedHoldingID: VirtualAssetHoldingItem.ID?
    let onHoldingTap: (VirtualAssetHoldingItem) -> Void
    @Environment(\.demoLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VirtualAssetHoldingScrollableHeader()

            ForEach(holdings) { holding in
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        onHoldingTap(holding)
                    } label: {
                        VirtualAssetHoldingMetricsRow(
                            holding: holding,
                            isNumberHidden: isNumberHidden
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(
                        language.actionAccessibilityLabel(
                            name: language.securityName(id: holding.id, fallback: holding.name),
                            action: holding.symbol
                        )
                    )
                    .accessibilityValue(
                        language.text(isNumberHidden ? .valuesHidden : .positionDataShown)
                    )
                    .accessibilityHint(
                        language.text(expandedHoldingID == holding.id ? .collapseQuickActions : .expandQuickActions)
                    )
                    .accessibilityIdentifier("trade.holding.\(holding.id)")

                    Color.clear
                        .frame(
                            width: VirtualAssetHoldingLayout.contentWidth,
                            height: VirtualAssetHoldingLayout.actionAreaHeight
                        )
                        .subAssetExpansion(
                            isExpanded: expandedHoldingID == holding.id,
                            blurRadius: 0
                        )
                        .allowsHitTesting(false)
                }
            }
        }
        .frame(
            width: VirtualAssetHoldingLayout.contentWidth,
            alignment: .topLeading
        )
        .background(Color("color-base-1"))
    }
}

private struct VirtualAssetHoldingFixedTable: View {
    @Environment(\.tradeAggregationViewportWidth) private var viewportWidth

    let section: VirtualAssetHoldingSection
    let isNumberHidden: Bool
    let expandedHoldingID: VirtualAssetHoldingItem.ID?
    let onAction: (VirtualAssetHoldingAction, VirtualAssetHoldingItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VirtualAssetHoldingNameHeader()
                .allowsHitTesting(false)

            ForEach(section.holdings) { holding in
                VStack(alignment: .leading, spacing: 0) {
                    VirtualAssetHoldingNameCell(
                        holding: holding,
                        isNumberHidden: isNumberHidden
                    )
                    .allowsHitTesting(false)

                    VirtualAssetHoldingActionBar(
                        holding: holding,
                        actions: section.actions,
                        onAction: onAction
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .frame(
                        width: viewportWidth,
                        height: VirtualAssetHoldingLayout.actionAreaHeight,
                        alignment: .topLeading
                    )
                    .subAssetExpansion(
                        isExpanded: expandedHoldingID == holding.id,
                        blurRadius: expandedHoldingID == holding.id ? 0 : 5
                    )
                }
                .frame(
                    width: viewportWidth,
                    alignment: .topLeading
                )
            }
        }
        .frame(
            width: viewportWidth,
            alignment: .topLeading
        )
    }
}

private struct VirtualAssetHoldingScrollableHeader: View {
    @Environment(\.demoLanguage) private var language
    private let columns: [(key: DemoCopyKey, imageName: String)] = [
        (.marketValueQuantityHeader, "holding_sort_descending"),
        (.lastCostHeader, "holding_sort_default"),
        (.dayProfitLossHeader, "holding_sort_default"),
        (.positionProfitLossHeader, "holding_sort_default"),
        (.portfolioWeightHeader, "holding_sort_default")
    ]

    var body: some View {
        HStack(spacing: VirtualAssetHoldingLayout.metricSpacing) {
            ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
                HStack(spacing: 2) {
                    Text(language.text(column.key))
                        .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
                        .foregroundColor(Color("color-text-60"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .allowsTightening(true)
                        .accessibilityLabel(language.accessibilityText(column.key))
                        .accessibilityIdentifier("trade.header.\(String(describing: column.key))")

                    Image(column.imageName)
                        .resizable()
                        .frame(width: 8, height: 16)
                        .accessibilityHidden(true)
                }
                .frame(
                    width: VirtualAssetHoldingLayout.metricWidth,
                    height: 16,
                    alignment: .trailing
                )
            }
        }
        .padding(.leading, VirtualAssetHoldingLayout.metricsLeadingInset)
        .padding(.trailing, VirtualAssetHoldingLayout.trailingInset)
        .padding(.top, 8)
        .frame(
            width: VirtualAssetHoldingLayout.contentWidth,
            height: VirtualAssetHoldingLayout.headerHeight,
            alignment: .top
        )
        .background(Color("color-base-1"))
    }
}

private struct VirtualAssetHoldingNameHeader: View {
    @Environment(\.demoLanguage) private var language

    var body: some View {
        Text(language.text(.name))
            .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
            .foregroundColor(Color("color-text-60"))
            .frame(width: 110, height: 16, alignment: .leading)
            .padding(.leading, 16)
            .padding(.top, 8)
            .frame(
                width: VirtualAssetHoldingLayout.nameWidth,
                height: VirtualAssetHoldingLayout.headerHeight,
                alignment: .topLeading
            )
            .background(Color("color-base-1"))
    }
}

private struct VirtualAssetHoldingNameCell: View {
    let holding: VirtualAssetHoldingItem
    let isNumberHidden: Bool
    @Environment(\.demoLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(display(language.securityName(id: holding.id, fallback: holding.name)))
                .font(.custom("PlusJakartaSans-Regular", size: 16, relativeTo: .body))
                .foregroundColor(Color("color-text-30"))
                .frame(width: 110, height: 24, alignment: .leading)

            Text(display(holding.symbol))
                .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                .foregroundColor(
                    Color(isNumberHidden ? "color-text-30" : "color-text-60")
                )
                .frame(width: 110, height: 20, alignment: .leading)
        }
        .padding(.leading, 16)
        .frame(
            width: VirtualAssetHoldingLayout.nameWidth,
            height: VirtualAssetHoldingLayout.rowHeight,
            alignment: .leading
        )
        .background(Color("color-base-1"))
    }

    private func display(_ value: String) -> String {
        isNumberHidden ? "***" : value
    }
}

private struct VirtualAssetHoldingMetricsRow: View {
    let holding: VirtualAssetHoldingItem
    let isNumberHidden: Bool

    var body: some View {
        HStack(spacing: VirtualAssetHoldingLayout.metricSpacing) {
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
        .padding(.leading, VirtualAssetHoldingLayout.metricsLeadingInset)
        .padding(.trailing, VirtualAssetHoldingLayout.trailingInset)
        .padding(.top, 8)
        .frame(
            width: VirtualAssetHoldingLayout.contentWidth,
            height: VirtualAssetHoldingLayout.rowHeight,
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
        VirtualAssetHoldingValuePairCell(
            primary: isNumberHidden ? "***" : primary,
            secondary: secondary.map { isNumberHidden ? "***" : $0 },
            primaryColor: isNumberHidden ? Color("color-text-30") : primaryColor,
            secondaryColor: isNumberHidden ? Color("color-text-30") : secondaryColor
        )
    }
}

private struct VirtualAssetHoldingValuePairCell: View {
    let primary: String
    let secondary: String?
    let primaryColor: Color
    let secondaryColor: Color

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(primary)
                .font(.custom("PlusJakartaSans-Regular", size: 16, relativeTo: .body))
                .foregroundColor(primaryColor)
                .frame(
                    width: VirtualAssetHoldingLayout.metricWidth,
                    height: 24,
                    alignment: .trailing
                )
                .lineLimit(1)

            if let secondary {
                Text(secondary)
                    .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                    .foregroundColor(secondaryColor)
                    .frame(
                        width: VirtualAssetHoldingLayout.metricWidth,
                        height: 20,
                        alignment: .trailing
                    )
                    .lineLimit(1)
            }
        }
        .frame(
            width: VirtualAssetHoldingLayout.metricWidth,
            height: 46,
            alignment: .topTrailing
        )
    }
}

private struct VirtualAssetHoldingActionBar: View {
    @Environment(\.tradeAggregationViewportWidth) private var viewportWidth
    @Environment(\.demoLanguage) private var language

    let holding: VirtualAssetHoldingItem
    let actions: [VirtualAssetHoldingAction]
    let onAction: (VirtualAssetHoldingAction, VirtualAssetHoldingItem) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
                Button {
                    onAction(action, holding)
                } label: {
                    Text(action.title(language: language))
                        .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                        .foregroundColor(Color("color-text-30"))
                        .frame(maxWidth: .infinity, minHeight: VirtualAssetHoldingLayout.actionHeight, maxHeight: VirtualAssetHoldingLayout.actionHeight)
                        .background(Color("color-scale-2"))
                        .clipShape(
                            UnevenRoundedRectangle(
                                cornerRadii: cornerRadii(at: index),
                                style: .continuous
                            )
                        )
                }
                .buttonStyle(WatchlistRedesignActionPressStyle())
                .accessibilityLabel(
                    language.actionAccessibilityLabel(
                        name: language.securityName(id: holding.id, fallback: holding.name),
                        action: action.title(language: language)
                    )
                )
                .accessibilityIdentifier("trade.holding.\(holding.id).\(action.rawValue)")
            }
        }
        .frame(width: max(viewportWidth - 32, 0), height: VirtualAssetHoldingLayout.actionHeight)
    }

    private func cornerRadii(at index: Int) -> RectangleCornerRadii {
        if index == 0 {
            return RectangleCornerRadii(
                topLeading: 12,
                bottomLeading: 12,
                bottomTrailing: 4,
                topTrailing: 4
            )
        }

        if index == actions.count - 1 {
            return RectangleCornerRadii(
                topLeading: 4,
                bottomLeading: 4,
                bottomTrailing: 12,
                topTrailing: 12
            )
        }

        return RectangleCornerRadii(
            topLeading: 4,
            bottomLeading: 4,
            bottomTrailing: 4,
            topTrailing: 4
        )
    }
}

private struct VirtualAssetHoldingSeparator: View {
    @Environment(\.tradeAggregationViewportWidth) private var viewportWidth

    var body: some View {
        Rectangle()
            .fill(Color("color-separator-10"))
            .frame(width: max(viewportWidth - 32, 0), height: 0.5)
            .frame(
                width: viewportWidth,
                height: VirtualAssetHoldingLayout.separatorAreaHeight
            )
    }
}

struct VirtualAssetHoldingListGroup_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VirtualAssetHoldingPreviewContainer {
                VirtualAssetHoldingListGroup(viewportWidth: 402)
            }
            .previewDisplayName("Default")

            VirtualAssetHoldingPreviewContainer {
                VirtualAssetHoldingListGroup(viewportWidth: 402, isNumberHidden: true)
            }
            .previewDisplayName("Numbers Hidden")

            VirtualAssetHoldingPreviewContainer {
                VirtualAssetHoldingListGroup(
                    viewportWidth: 402,
                    initialInfoPlacement: .footer,
                    initiallyCollapsedCategories: [.cryptocurrency]
                )
            }
            .previewDisplayName("Mixed Category States")

            VirtualAssetHoldingPreviewContainer {
                VirtualAssetHoldingListGroup(
                    viewportWidth: 402,
                    initialInfoPlacement: .footer
                )
            }
            .previewDisplayName("Footer Info")
        }
        .previewLayout(.fixed(width: 402, height: 880))
    }
}

private struct VirtualAssetHoldingPreviewContainer<Content: View>: View {
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
            width: 402,
            height: 880,
            alignment: .top
        )
        .background(Color("color-base-1"))
    }
}
