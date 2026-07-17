//
//  FundHoldingListGroup.swift
//  SuperPreview
//

import SwiftUI

enum FundHoldingCurrency: String, CaseIterable, Identifiable {
    case hongKongDollar
    case unitedStatesDollar
    case renminbi

    var id: Self { self }

    var title: String {
        switch self {
        case .hongKongDollar:
            return "港币基金"
        case .unitedStatesDollar:
            return "美元基金"
        case .renminbi:
            return "人民币基金"
        }
    }

    var flagImageName: String {
        switch self {
        case .hongKongDollar:
            return "subasset_flag_hkd"
        case .unitedStatesDollar:
            return "subasset_flag_usd"
        case .renminbi:
            return "subasset_flag_cny"
        }
    }
}

enum FundHoldingValueTone {
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

enum FundHoldingNameAccessory {
    case none
    case tPlusZero
    case legacyFundInfo
}

struct FundHoldingItem: Identifiable {
    let id: String
    let name: String
    let symbol: String
    let marketValue: String
    let yesterdayIncome: String
    let holdingIncome: String
    let holdingIncomeRate: String
    let holdingRatio: String
    let incomeTone: FundHoldingValueTone
    let nameAccessory: FundHoldingNameAccessory
    let showsAIPTag: Bool
}

struct FundHoldingCurrencySection: Identifiable {
    let currency: FundHoldingCurrency
    let holdings: [FundHoldingItem]

    var id: FundHoldingCurrency { currency }
}

extension Array where Element == FundHoldingCurrencySection {
    static var fundHoldingPreview: [FundHoldingCurrencySection] {
        [
            previewSection(
                currency: .hongKongDollar,
                primaryFundName: "康泰开泰港元货币基金"
            ),
            previewSection(
                currency: .unitedStatesDollar,
                primaryFundName: "康泰开泰美元货币基金"
            ),
            previewSection(
                currency: .renminbi,
                primaryFundName: "康泰开泰人民币货币基金"
            )
        ]
    }

    private static func previewSection(
        currency: FundHoldingCurrency,
        primaryFundName: String
    ) -> FundHoldingCurrencySection {
        FundHoldingCurrencySection(
            currency: currency,
            holdings: [
                FundHoldingItem(
                    id: "\(currency.rawValue)-standard",
                    name: primaryFundName,
                    symbol: "LU12345678",
                    marketValue: "473.120",
                    yesterdayIncome: "+2.12",
                    holdingIncome: "2,473.120",
                    holdingIncomeRate: "+8.12%",
                    holdingRatio: "100.00%",
                    incomeTone: .gain,
                    nameAccessory: .none,
                    showsAIPTag: false
                ),
                FundHoldingItem(
                    id: "\(currency.rawValue)-t0",
                    name: "康泰开泰美元货币基金",
                    symbol: "LU12345678",
                    marketValue: "473.120",
                    yesterdayIncome: "+2.12",
                    holdingIncome: "2,473.120",
                    holdingIncomeRate: "+8.12%",
                    holdingRatio: "100.00%",
                    incomeTone: .gain,
                    nameAccessory: .tPlusZero,
                    showsAIPTag: true
                ),
                FundHoldingItem(
                    id: "\(currency.rawValue)-legacy",
                    name: "康泰开泰美元货币基金",
                    symbol: "LU12345678",
                    marketValue: "473.120",
                    yesterdayIncome: "+2.12",
                    holdingIncome: "2,473.120",
                    holdingIncomeRate: "+8.12%",
                    holdingRatio: "100.00%",
                    incomeTone: .gain,
                    nameAccessory: .legacyFundInfo,
                    showsAIPTag: true
                ),
                FundHoldingItem(
                    id: "\(currency.rawValue)-loss",
                    name: "骏利环球房地产基金A",
                    symbol: "LU12345678",
                    marketValue: "85.600",
                    yesterdayIncome: "+2.12",
                    holdingIncome: "1,285.600",
                    holdingIncomeRate: "-5.23%",
                    holdingRatio: "100.00%",
                    incomeTone: .loss,
                    nameAccessory: .none,
                    showsAIPTag: false
                )
            ]
        )
    }
}

struct FundHoldingListGroup: View {
    let sections: [FundHoldingCurrencySection]
    let isNumberHidden: Bool

    @State private var collapsedCurrencies: Set<FundHoldingCurrency>

    init(
        sections: [FundHoldingCurrencySection] = .fundHoldingPreview,
        isNumberHidden: Bool = false,
        initiallyCollapsedCurrencies: Set<FundHoldingCurrency> = []
    ) {
        self.sections = sections
        self.isNumberHidden = isNumberHidden
        _collapsedCurrencies = State(initialValue: initiallyCollapsedCurrencies)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView(.horizontal, showsIndicators: false) {
                scrollableContent
            }
            .frame(
                width: FundHoldingLayout.viewportWidth,
                height: contentHeight,
                alignment: .topLeading
            )
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)

            fixedContent
        }
        .frame(
            width: FundHoldingLayout.viewportWidth,
            height: contentHeight,
            alignment: .topLeading
        )
        .background(Color("color-base-1"))
        .clipped()
    }

    private var scrollableContent: some View {
        VStack(alignment: .leading, spacing: FundHoldingLayout.sectionSpacing) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: FundHoldingLayout.sectionContentSpacing) {
                    Color.clear
                        .frame(
                            width: FundHoldingLayout.contentWidth,
                            height: FundHoldingLayout.marketHeaderHeight
                        )

                    if isCurrencyExpanded(section.currency) {
                        FundHoldingScrollableTable(
                            holdings: section.holdings,
                            isNumberHidden: isNumberHidden
                        )
                    }

                    Color.clear
                        .frame(width: FundHoldingLayout.contentWidth, height: 1)
                }
            }
        }
        .frame(width: FundHoldingLayout.contentWidth, alignment: .topLeading)
    }

    private var fixedContent: some View {
        VStack(alignment: .leading, spacing: FundHoldingLayout.sectionSpacing) {
            ForEach(sections) { section in
                FundHoldingFixedCurrencySection(
                    section: section,
                    isExpanded: isCurrencyExpanded(section.currency),
                    isNumberHidden: isNumberHidden,
                    toggleExpansion: {
                        toggleCurrency(section.currency)
                    }
                )
            }
        }
        .frame(width: FundHoldingLayout.viewportWidth, alignment: .topLeading)
    }

    private var contentHeight: CGFloat {
        var height = CGFloat(max(sections.count - 1, 0)) * FundHoldingLayout.sectionSpacing

        for section in sections {
            height += FundHoldingLayout.collapsedSectionHeight

            if isCurrencyExpanded(section.currency) {
                height += FundHoldingLayout.sectionContentSpacing
                    + tableHeight(for: section)
            }
        }

        return height
    }

    private func tableHeight(for section: FundHoldingCurrencySection) -> CGFloat {
        FundHoldingLayout.tableHeaderHeight
            + CGFloat(section.holdings.count) * FundHoldingLayout.rowHeight
    }

    private func isCurrencyExpanded(_ currency: FundHoldingCurrency) -> Bool {
        !collapsedCurrencies.contains(currency)
    }

    private func toggleCurrency(_ currency: FundHoldingCurrency) {
        if collapsedCurrencies.contains(currency) {
            collapsedCurrencies.remove(currency)
        } else {
            collapsedCurrencies.insert(currency)
        }
    }
}

private enum FundHoldingLayout {
    static let viewportWidth: CGFloat = 402
    static let contentWidth: CGFloat = 502
    static let nameWidth: CGFloat = 190
    static let metricsLeadingInset: CGFloat = 206
    static let metricWidth: CGFloat = 88
    static let metricSpacing: CGFloat = 8
    static let trailingInset: CGFloat = 16
    static let tableHeaderHeight: CGFloat = 32
    static let rowHeight: CGFloat = 62
    static let marketHeaderHeight: CGFloat = 20
    static let sectionSpacing: CGFloat = 10
    static let sectionContentSpacing: CGFloat = 10
    static let collapsedSectionHeight: CGFloat = marketHeaderHeight + sectionContentSpacing + 1
}

private struct FundHoldingCurrencyHeader: View {
    let currency: FundHoldingCurrency
    let isExpanded: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(currency.flagImageName)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)

                Text(currency.title)
                    .font(.custom("PlusJakartaSans-Medium", size: 16, relativeTo: .body))
                    .foregroundColor(Color("color-text-30"))
                    .frame(height: FundHoldingLayout.marketHeaderHeight)

                Spacer(minLength: 0)

                Image("holding_market_chevron")
                    .resizable()
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(isExpanded ? 0 : 180))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .frame(
                width: FundHoldingLayout.viewportWidth,
                height: FundHoldingLayout.marketHeaderHeight
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(currency.title)
        .accessibilityValue(isExpanded ? "已展开" : "已收起")
        .accessibilityHint(isExpanded ? "双击收起基金持仓" : "双击展开基金持仓")
    }
}

private struct FundHoldingScrollableTable: View {
    let holdings: [FundHoldingItem]
    let isNumberHidden: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FundHoldingScrollableHeader()

            ForEach(holdings) { holding in
                FundHoldingMetricsRow(
                    holding: holding,
                    isNumberHidden: isNumberHidden
                )
            }
        }
        .frame(width: FundHoldingLayout.contentWidth, alignment: .topLeading)
        .background(Color("color-base-1"))
    }
}

private struct FundHoldingFixedCurrencySection: View {
    let section: FundHoldingCurrencySection
    let isExpanded: Bool
    let isNumberHidden: Bool
    let toggleExpansion: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: FundHoldingLayout.sectionContentSpacing) {
            FundHoldingCurrencyHeader(
                currency: section.currency,
                isExpanded: isExpanded,
                action: toggleExpansion
            )

            if isExpanded {
                FundHoldingFixedTable(
                    holdings: section.holdings,
                    isNumberHidden: isNumberHidden
                )
            }

            FundHoldingSeparator()
                .allowsHitTesting(false)
        }
    }
}

private struct FundHoldingFixedTable: View {
    let holdings: [FundHoldingItem]
    let isNumberHidden: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            FundHoldingNameHeader()
                .allowsHitTesting(false)

            ForEach(holdings) { holding in
                FundHoldingNameCell(
                    holding: holding,
                    isNumberHidden: isNumberHidden
                )
                .allowsHitTesting(false)
            }
        }
        .frame(width: FundHoldingLayout.viewportWidth, alignment: .topLeading)
    }
}

private struct FundHoldingScrollableHeader: View {
    private let columns: [(title: String, imageName: String)] = [
        ("市值/昨日收益", "holding_sort_descending"),
        ("持仓收益", "holding_sort_default"),
        ("持仓占比", "holding_sort_default")
    ]

    var body: some View {
        HStack(spacing: FundHoldingLayout.metricSpacing) {
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
                .frame(
                    width: FundHoldingLayout.metricWidth,
                    height: 16,
                    alignment: .trailing
                )
            }
        }
        .padding(.leading, FundHoldingLayout.metricsLeadingInset)
        .padding(.trailing, FundHoldingLayout.trailingInset)
        .padding(.top, 8)
        .frame(
            width: FundHoldingLayout.contentWidth,
            height: FundHoldingLayout.tableHeaderHeight,
            alignment: .top
        )
        .background(Color("color-base-1"))
    }
}

private struct FundHoldingNameHeader: View {
    var body: some View {
        Text("名称")
            .font(.custom("PlusJakartaSans-Regular", size: 12, relativeTo: .caption))
            .foregroundColor(Color("color-text-60"))
            .frame(height: 16)
            .padding(.leading, 16)
            .padding(.top, 8)
            .frame(
                width: FundHoldingLayout.nameWidth,
                height: FundHoldingLayout.tableHeaderHeight,
                alignment: .topLeading
            )
            .background(Color("color-base-1"))
    }
}

private struct FundHoldingNameCell: View {
    let holding: FundHoldingItem
    let isNumberHidden: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            titleRow
                .frame(width: 174, height: 24, alignment: .leading)

            subtitleRow
                .frame(width: 174, height: 20, alignment: .leading)
        }
        .padding(.leading, 16)
        .padding(.vertical, 8)
        .frame(
            width: FundHoldingLayout.nameWidth,
            height: FundHoldingLayout.rowHeight,
            alignment: .topLeading
        )
        .background(Color("color-base-1"))
        .clipped()
    }

    private var titleRow: some View {
        HStack(spacing: 2) {
            Text(display(holding.name))
                .font(.custom("PlusJakartaSans-Regular", size: 16, relativeTo: .body))
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .truncationMode(.tail)

            if !isNumberHidden {
                switch holding.nameAccessory {
                case .none:
                    EmptyView()
                case .tPlusZero:
                    FundHoldingTPlusZeroTag()
                case .legacyFundInfo:
                    Image("fund_holding_info")
                        .resizable()
                        .frame(width: 16, height: 16)
                        .accessibilityLabel("旧基金说明")
                }
            }
        }
    }

    private var subtitleRow: some View {
        HStack(spacing: 2) {
            Text(display(holding.symbol))
                .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                .foregroundColor(Color(isNumberHidden ? "color-text-30" : "color-text-60"))
                .lineLimit(1)

            if holding.showsAIPTag && !isNumberHidden {
                FundHoldingAIPTag()
            }
        }
    }

    private func display(_ value: String) -> String {
        isNumberHidden ? "***" : value
    }
}

private struct FundHoldingTPlusZeroTag: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("T+0")
                .font(.custom("PlusJakartaSans-Medium", size: 10, relativeTo: .caption2))
                .foregroundColor(Color("color-brand-blue"))
                .frame(height: 12)

            Image("fund_holding_tag_chevron")
                .resizable()
                .frame(width: 12, height: 12)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color("color-brand-blue").opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("支持T加零")
    }
}

private struct FundHoldingAIPTag: View {
    var body: some View {
        Text("定投")
            .font(.custom("PlusJakartaSans-Regular", size: 10, relativeTo: .caption2))
            .foregroundColor(Color("color-brand-blue"))
            .frame(height: 12)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color("color-brand-blue").opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            .fixedSize()
    }
}

private struct FundHoldingMetricsRow: View {
    let holding: FundHoldingItem
    let isNumberHidden: Bool

    var body: some View {
        HStack(spacing: FundHoldingLayout.metricSpacing) {
            FundHoldingValuePairCell(
                primary: display(holding.marketValue),
                secondary: display(holding.yesterdayIncome),
                primaryColor: valueColor(.neutral),
                secondaryColor: valueColor(holding.incomeTone)
            )

            FundHoldingValuePairCell(
                primary: display(holding.holdingIncome),
                secondary: display(holding.holdingIncomeRate),
                primaryColor: valueColor(holding.incomeTone),
                secondaryColor: valueColor(holding.incomeTone)
            )

            FundHoldingValuePairCell(
                primary: display(holding.holdingRatio),
                secondary: nil,
                primaryColor: valueColor(.neutral),
                secondaryColor: valueColor(.neutral)
            )
        }
        .padding(.leading, FundHoldingLayout.metricsLeadingInset)
        .padding(.trailing, FundHoldingLayout.trailingInset)
        .padding(.top, 8)
        .frame(
            width: FundHoldingLayout.contentWidth,
            height: FundHoldingLayout.rowHeight,
            alignment: .top
        )
        .background(Color("color-base-1"))
    }

    private func display(_ value: String) -> String {
        isNumberHidden ? "***" : value
    }

    private func valueColor(_ tone: FundHoldingValueTone) -> Color {
        isNumberHidden ? Color("color-text-30") : tone.color
    }
}

private struct FundHoldingValuePairCell: View {
    let primary: String
    let secondary: String?
    let primaryColor: Color
    let secondaryColor: Color

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(primary)
                .font(.custom("PlusJakartaSans-Regular", size: 16, relativeTo: .body))
                .foregroundColor(primaryColor)
                .frame(width: FundHoldingLayout.metricWidth, height: 24, alignment: .trailing)
                .lineLimit(1)

            if let secondary {
                Text(secondary)
                    .font(.custom("PlusJakartaSans-Regular", size: 14, relativeTo: .subheadline))
                    .foregroundColor(secondaryColor)
                    .frame(width: FundHoldingLayout.metricWidth, height: 20, alignment: .trailing)
                    .lineLimit(1)
            }
        }
        .frame(width: FundHoldingLayout.metricWidth, height: 46, alignment: .topTrailing)
    }
}

private struct FundHoldingSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color("color-separator-10"))
            .frame(width: 370, height: 0.5)
            .frame(width: FundHoldingLayout.viewportWidth, height: 1)
    }
}

struct FundHoldingListGroup_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FundHoldingListGroupPreviewContainer {
                FundHoldingListGroup()
            }
            .previewDisplayName("Default")

            FundHoldingListGroupPreviewContainer {
                FundHoldingListGroup(isNumberHidden: true)
            }
            .previewDisplayName("Numbers Hidden")

            FundHoldingListGroupPreviewContainer {
                FundHoldingListGroup(
                    initiallyCollapsedCurrencies: Set(FundHoldingCurrency.allCases)
                )
            }
            .previewDisplayName("Currencies Collapsed")
        }
        .previewLayout(.fixed(width: 402, height: 1015))
    }
}

private struct FundHoldingListGroupPreviewContainer<Content: View>: View {
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
            width: FundHoldingLayout.viewportWidth,
            height: 1015,
            alignment: .top
        )
        .background(Color("color-base-1"))
    }
}
