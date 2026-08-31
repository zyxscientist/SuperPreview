//
//  StockDetailCapitalDistribution.swift
//  SuperPreview
//

import SwiftUI

/// Static presentation data for the stock-detail capital-distribution card.
///
/// The current prototype deliberately uses mock values, while keeping the
/// data shape independent from the view so a page-level data source can
/// replace it later without changing the layout.
struct StockDetailCapitalDistributionData: Hashable {
    let date: String
    let time: String
    let unit: String
    let netFlow: String
    let netFlowTitle: String
    let inflowTotal: String
    let inflowTitle: String
    let outflowTotal: String
    let outflowTitle: String
    let breakdowns: [StockDetailCapitalDistributionBreakdown]

    init(
        date: String,
        time: String,
        unit: String,
        netFlow: String,
        netFlowTitle: String,
        inflowTotal: String,
        inflowTitle: String,
        outflowTotal: String,
        outflowTitle: String,
        breakdowns: [StockDetailCapitalDistributionBreakdown]
    ) {
        self.date = date
        self.time = time
        self.unit = unit
        self.netFlow = netFlow
        self.netFlowTitle = netFlowTitle
        self.inflowTotal = inflowTotal
        self.inflowTitle = inflowTitle
        self.outflowTotal = outflowTotal
        self.outflowTitle = outflowTitle
        self.breakdowns = breakdowns
    }
}

/// A capital-flow bucket shared by the bilateral legend and bar row.
struct StockDetailCapitalDistributionBreakdown: Hashable, Identifiable {
    let category: String
    let inflowShare: String
    let outflowShare: String
    let inflowAmount: String
    let outflowAmount: String
    let inflowBarFraction: CGFloat
    let outflowBarFraction: CGFloat
    let orderSize: StockDetailCapitalDistributionOrderSize

    var id: String { category }

    init(
        category: String,
        inflowShare: String,
        outflowShare: String,
        inflowAmount: String,
        outflowAmount: String,
        inflowBarFraction: CGFloat,
        outflowBarFraction: CGFloat,
        orderSize: StockDetailCapitalDistributionOrderSize
    ) {
        self.category = category
        self.inflowShare = inflowShare
        self.outflowShare = outflowShare
        self.inflowAmount = inflowAmount
        self.outflowAmount = outflowAmount
        self.inflowBarFraction = inflowBarFraction
        self.outflowBarFraction = outflowBarFraction
        self.orderSize = orderSize
    }
}

enum StockDetailCapitalDistributionOrderSize: Hashable {
    case large
    case medium
    case small
}

/// The static capital-distribution card shown below the stock-detail chart.
///
/// The question-mark glyph is informational only in this prototype and does
/// not attach a tap action.
struct StockDetailCapitalDistribution: View {
    let data: StockDetailCapitalDistributionData

    init(data: StockDetailCapitalDistributionData = .mock) {
        self.data = data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StockDetailCapitalDistributionLayout.sectionSpacing) {
            header
            distributionSummary

            VStack(spacing: StockDetailCapitalDistributionLayout.totalsToBarsSpacing) {
                totals
                flowBars
            }
        }
        .padding(StockDetailCapitalDistributionLayout.contentPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.capitalDistribution")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: StockDetailCapitalDistributionLayout.headerSpacing) {
            HStack(spacing: StockDetailCapitalDistributionLayout.titleToGlyphSpacing) {
                Text("当日资金分布")
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailCapitalDistributionLayout.titleFontSize,
                            font: .medium,
                            lineHeight: StockDetailCapitalDistributionLayout.titleLineHeight
                        )
                    )
                    .foregroundColor(Color("color-text-30"))

                Image("question_outline_16")
                    .resizable()
                    .frame(
                        width: StockDetailCapitalDistributionLayout.questionGlyphSize,
                        height: StockDetailCapitalDistributionLayout.questionGlyphSize
                    )
                    .padding(.vertical, StockDetailCapitalDistributionLayout.questionGlyphVerticalPadding)
                    .accessibilityHidden(true)
            }
            .frame(height: StockDetailCapitalDistributionLayout.titleLineHeight, alignment: .leading)

            HStack(spacing: 0) {
                HStack(spacing: StockDetailCapitalDistributionLayout.timestampSpacing) {
                    Text(data.date)
                    Text(data.time)
                }

                Spacer(minLength: 0)

                Text(data.unit)
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailCapitalDistributionLayout.metadataFontSize,
                            font: .medium,
                            lineHeight: StockDetailCapitalDistributionLayout.metadataLineHeight
                        )
                    )
            }
            .modifier(
                CustomFontModifier(
                    size: StockDetailCapitalDistributionLayout.metadataFontSize,
                    font: .regular,
                    lineHeight: StockDetailCapitalDistributionLayout.metadataLineHeight
                )
            )
            .foregroundColor(Color("color-text-60"))
            .frame(height: StockDetailCapitalDistributionLayout.metadataLineHeight)
        }
    }

    private var distributionSummary: some View {
        HStack(spacing: StockDetailCapitalDistributionLayout.legendToRingSpacing) {
            legendColumn(for: .inflow)
            flowRing
            legendColumn(for: .outflow)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: StockDetailCapitalDistributionLayout.ringSize,
            alignment: .center
        )
    }

    private var flowRing: some View {
        ZStack {
            Image("stock_detail_capital_distribution_ring")
                .resizable()
                .frame(
                    width: StockDetailCapitalDistributionLayout.ringSize,
                    height: StockDetailCapitalDistributionLayout.ringSize
                )

            Circle()
                .fill(Color("color-base-1"))
                .frame(
                    width: StockDetailCapitalDistributionLayout.ringHoleSize,
                    height: StockDetailCapitalDistributionLayout.ringHoleSize
                )

            VStack(spacing: StockDetailCapitalDistributionLayout.ringTextSpacing) {
                Text(data.netFlow)
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailCapitalDistributionLayout.netFlowFontSize,
                            font: .medium,
                            lineHeight: StockDetailCapitalDistributionLayout.netFlowLineHeight
                        )
                    )
                    .foregroundColor(Color("color-stock-detail-capital-inflow-regular"))

                Text(data.netFlowTitle)
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailCapitalDistributionLayout.netFlowTitleFontSize,
                            font: .regular,
                            lineHeight: StockDetailCapitalDistributionLayout.netFlowTitleLineHeight
                        )
                    )
                    .foregroundColor(Color("color-text-30"))
            }
        }
        .frame(
            width: StockDetailCapitalDistributionLayout.ringSize,
            height: StockDetailCapitalDistributionLayout.ringSize
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("净流 \(data.netFlow)")
    }

    private var totals: some View {
        HStack(spacing: StockDetailCapitalDistributionLayout.totalsSpacing) {
            HStack(spacing: 0) {
                Text(data.inflowTotal)
                    .foregroundColor(Color("color-stock-detail-capital-inflow-regular"))
                Text(":\(data.inflowTitle)")
                    .foregroundColor(Color("color-text-30"))
            }

            HStack(spacing: 0) {
                Text("\(data.outflowTitle):")
                    .foregroundColor(Color("color-text-30"))
                Text(data.outflowTotal)
                    .foregroundColor(Color("color-stock-detail-capital-outflow-regular"))
            }
        }
        .modifier(
            CustomFontModifier(
                size: StockDetailCapitalDistributionLayout.totalFontSize,
                font: .medium,
                lineHeight: StockDetailCapitalDistributionLayout.totalLineHeight
            )
        )
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var flowBars: some View {
        VStack(spacing: StockDetailCapitalDistributionLayout.barRowSpacing) {
            ForEach(data.breakdowns) { breakdown in
                flowBarRow(for: breakdown)
            }
        }
    }

    private func legendColumn(for direction: StockDetailCapitalDistributionDirection) -> some View {
        VStack(spacing: StockDetailCapitalDistributionLayout.legendRowSpacing) {
            ForEach(data.breakdowns) { breakdown in
                legendRow(for: breakdown, direction: direction)
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: direction == .inflow ? .leading : .trailing
        )
    }

    @ViewBuilder
    private func legendRow(
        for breakdown: StockDetailCapitalDistributionBreakdown,
        direction: StockDetailCapitalDistributionDirection
    ) -> some View {
        if direction == .inflow {
            HStack(spacing: StockDetailCapitalDistributionLayout.legendItemSpacing) {
                legendMarker(color: breakdown.orderSize.inflowColor)
                legendLabel(breakdown.category)
                Spacer(minLength: StockDetailCapitalDistributionLayout.legendMinimumSpacer)
                legendShare(breakdown.inflowShare)
            }
        } else {
            HStack(spacing: StockDetailCapitalDistributionLayout.legendItemSpacing) {
                legendShare(breakdown.outflowShare)
                Spacer(minLength: StockDetailCapitalDistributionLayout.legendMinimumSpacer)
                legendLabel(breakdown.category)
                legendMarker(color: breakdown.orderSize.outflowColor)
            }
        }
    }

    private func legendMarker(color: Color) -> some View {
        RoundedRectangle(
            cornerRadius: StockDetailCapitalDistributionLayout.legendMarkerCornerRadius,
            style: .continuous
        )
        .fill(color)
        .frame(
            width: StockDetailCapitalDistributionLayout.legendMarkerSize,
            height: StockDetailCapitalDistributionLayout.legendMarkerSize
        )
    }

    private func legendLabel(_ text: String) -> some View {
        Text(text)
            .modifier(
                CustomFontModifier(
                    size: StockDetailCapitalDistributionLayout.legendFontSize,
                    font: .regular,
                    lineHeight: StockDetailCapitalDistributionLayout.legendLineHeight
                )
            )
            .foregroundColor(Color("color-text-30"))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    private func legendShare(_ text: String) -> some View {
        Text(text)
            .modifier(
                CustomFontModifier(
                    size: StockDetailCapitalDistributionLayout.legendFontSize,
                    font: .medium,
                    lineHeight: StockDetailCapitalDistributionLayout.legendLineHeight
                )
            )
            .foregroundColor(Color("color-text-30"))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }

    private func flowBarRow(for breakdown: StockDetailCapitalDistributionBreakdown) -> some View {
        HStack(spacing: StockDetailCapitalDistributionLayout.barItemSpacing) {
            Text(breakdown.inflowAmount)
                .modifier(
                    CustomFontModifier(
                        size: StockDetailCapitalDistributionLayout.barFontSize,
                        font: .medium,
                        lineHeight: StockDetailCapitalDistributionLayout.barLineHeight
                    )
                )
                .foregroundColor(breakdown.orderSize.inflowColor)
                .frame(
                    width: StockDetailCapitalDistributionLayout.barAmountWidth,
                    alignment: .leading
                )

            flowBar(
                color: breakdown.orderSize.inflowColor,
                fraction: breakdown.inflowBarFraction,
                alignment: .trailing
            )

            Text(breakdown.category)
                .modifier(
                    CustomFontModifier(
                        size: StockDetailCapitalDistributionLayout.barFontSize,
                        font: .regular,
                        lineHeight: StockDetailCapitalDistributionLayout.barLineHeight
                    )
                )
                .foregroundColor(Color("color-text-60"))
                .frame(
                    width: StockDetailCapitalDistributionLayout.barCategoryWidth,
                    alignment: .center
                )

            flowBar(
                color: breakdown.orderSize.outflowColor,
                fraction: breakdown.outflowBarFraction,
                alignment: .leading
            )

            Text(breakdown.outflowAmount)
                .modifier(
                    CustomFontModifier(
                        size: StockDetailCapitalDistributionLayout.barFontSize,
                        font: .medium,
                        lineHeight: StockDetailCapitalDistributionLayout.barLineHeight
                    )
                )
                .foregroundColor(breakdown.orderSize.outflowColor)
                .frame(
                    width: StockDetailCapitalDistributionLayout.barAmountWidth,
                    alignment: .trailing
                )
        }
        .frame(
            maxWidth: .infinity,
            minHeight: StockDetailCapitalDistributionLayout.barLineHeight
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockDetail.capitalDistribution.\(breakdown.id)")
    }

    private func flowBar(color: Color, fraction: CGFloat, alignment: Alignment) -> some View {
        GeometryReader { proxy in
            RoundedRectangle(
                cornerRadius: StockDetailCapitalDistributionLayout.barCornerRadius,
                style: .continuous
            )
            .fill(color)
            .frame(
                width: proxy.size.width * min(max(fraction, 0), 1),
                height: StockDetailCapitalDistributionLayout.barHeight
            )
            .frame(maxWidth: .infinity, alignment: alignment)
        }
        .frame(maxWidth: .infinity)
        .frame(height: StockDetailCapitalDistributionLayout.barHeight)
    }
}

private enum StockDetailCapitalDistributionDirection {
    case inflow
    case outflow
}

private extension StockDetailCapitalDistributionOrderSize {
    var inflowColor: Color {
        switch self {
        case .large:
            Color("color-stock-detail-capital-inflow-strong")
        case .medium:
            Color("color-stock-detail-capital-inflow-regular")
        case .small:
            Color("color-stock-detail-capital-inflow-weak")
        }
    }

    var outflowColor: Color {
        switch self {
        case .large:
            Color("color-stock-detail-capital-outflow-strong")
        case .medium:
            Color("color-stock-detail-capital-outflow-regular")
        case .small:
            Color("color-stock-detail-capital-outflow-weak")
        }
    }
}

extension StockDetailCapitalDistributionData {
    static let mock = StockDetailCapitalDistributionData(
        date: "2025/10/13",
        time: "13:35",
        unit: "单位：万",
        netFlow: "+3.10",
        netFlowTitle: "净流",
        inflowTotal: "19.38",
        inflowTitle: "流入",
        outflowTotal: "16.38",
        outflowTitle: "流出",
        breakdowns: [
            StockDetailCapitalDistributionBreakdown(
                category: "大单",
                inflowShare: "33.2%",
                outflowShare: "33.2%",
                inflowAmount: "13.99",
                outflowAmount: "10.99",
                inflowBarFraction: 1,
                outflowBarFraction: 1,
                orderSize: .large
            ),
            StockDetailCapitalDistributionBreakdown(
                category: "中单",
                inflowShare: "15.2%",
                outflowShare: "15.2%",
                inflowAmount: "5.11",
                outflowAmount: "4.37",
                inflowBarFraction: 0.48,
                outflowBarFraction: 0.52,
                orderSize: .medium
            ),
            StockDetailCapitalDistributionBreakdown(
                category: "小单",
                inflowShare: "8.2%",
                outflowShare: "8.2%",
                inflowAmount: "1.22",
                outflowAmount: "1.02",
                inflowBarFraction: 0.18,
                outflowBarFraction: 0.24,
                orderSize: .small
            )
        ]
    )
}

private enum StockDetailCapitalDistributionLayout {
    static let contentPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let headerSpacing: CGFloat = 4
    static let titleToGlyphSpacing: CGFloat = 8
    static let titleFontSize: CGFloat = 16
    static let titleLineHeight: CGFloat = 24
    static let questionGlyphSize: CGFloat = 16
    static let questionGlyphVerticalPadding: CGFloat = 4
    static let timestampSpacing: CGFloat = 4
    static let metadataFontSize: CGFloat = 12
    static let metadataLineHeight: CGFloat = 16
    static let legendToRingSpacing: CGFloat = 24
    static let legendRowSpacing: CGFloat = 14
    static let legendItemSpacing: CGFloat = 8
    static let legendMinimumSpacer: CGFloat = 2
    static let legendMarkerSize: CGFloat = 8
    static let legendMarkerCornerRadius: CGFloat = 1
    static let legendFontSize: CGFloat = 13
    static let legendLineHeight: CGFloat = 16
    static let ringSize: CGFloat = 120
    static let ringHoleSize: CGFloat = 88
    static let ringTextSpacing: CGFloat = 2
    static let netFlowFontSize: CGFloat = 14
    static let netFlowLineHeight: CGFloat = 20
    static let netFlowTitleFontSize: CGFloat = 12
    static let netFlowTitleLineHeight: CGFloat = 16
    static let totalsToBarsSpacing: CGFloat = 12
    static let totalsSpacing: CGFloat = 46
    static let totalFontSize: CGFloat = 16
    static let totalLineHeight: CGFloat = 24
    static let barRowSpacing: CGFloat = 12
    static let barItemSpacing: CGFloat = 8
    static let barAmountWidth: CGFloat = 68
    static let barCategoryWidth: CGFloat = 26
    static let barFontSize: CGFloat = 13
    static let barLineHeight: CGFloat = 16
    static let barHeight: CGFloat = 12
    static let barCornerRadius: CGFloat = 2
}

struct StockDetailCapitalDistribution_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailCapitalDistribution()
                .previewDisplayName("Light")

            StockDetailCapitalDistribution()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
        .frame(width: 402)
        .previewLayout(.sizeThatFits)
    }
}
