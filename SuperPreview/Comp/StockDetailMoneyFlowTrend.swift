//
//  StockDetailMoneyFlowTrend.swift
//  SuperPreview
//

import SwiftUI

/// Static presentation data for the stock-detail money-flow trend card.
///
/// The prototype currently displays the Figma-specified mock values only;
/// callers may replace this data shape when a chart data source is available.
struct StockDetailMoneyFlowTrendData: Hashable {
    let title: String
    let unit: String
    let upperValue: String
    let lowerValue: String
    let zeroValue: String
    let startTime: String
    let endTime: String
    private let localizedTitle: StockDetailQuoteLocalizedText?
    private let localizedUnit: StockDetailQuoteLocalizedText?

    init(
        title: String,
        unit: String,
        upperValue: String,
        lowerValue: String,
        zeroValue: String,
        startTime: String,
        endTime: String,
        localizedTitle: StockDetailQuoteLocalizedText? = nil,
        localizedUnit: StockDetailQuoteLocalizedText? = nil
    ) {
        self.title = title
        self.unit = unit
        self.upperValue = upperValue
        self.lowerValue = lowerValue
        self.zeroValue = zeroValue
        self.startTime = startTime
        self.endTime = endTime
        self.localizedTitle = localizedTitle
        self.localizedUnit = localizedUnit
    }

    fileprivate func displayTitle(for language: DemoLanguage) -> String {
        localizedTitle?.text(for: language) ?? title
    }

    fileprivate func displayUnit(for language: DemoLanguage) -> String {
        localizedUnit?.text(for: language) ?? unit
    }
}

/// A static money-flow trend graphic for the stock-detail prototype.
///
/// The chart path is the exported Figma vector. It intentionally does not
/// expose selection, scrolling, or any other chart interaction.
struct StockDetailMoneyFlowTrend: View {
    let data: StockDetailMoneyFlowTrendData

    @Environment(\.demoLanguage) private var language

    init(data: StockDetailMoneyFlowTrendData = .mock) {
        self.data = data
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: StockDetailMoneyFlowTrendLayout.chartToAxisSpacing) {
                chart
                timeAxis
            }
            .padding(.vertical, StockDetailMoneyFlowTrendLayout.chartVerticalPadding)
        }
        .padding(.horizontal, StockDetailMoneyFlowTrendLayout.horizontalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.moneyFlowTrend")
    }

    private var header: some View {
        HStack(spacing: StockDetailMoneyFlowTrendLayout.headerSpacing) {
            Text(data.displayTitle(for: language))
                .modifier(
                    CustomFontModifier(
                        size: StockDetailMoneyFlowTrendLayout.titleFontSize,
                        font: .medium,
                        lineHeight: StockDetailMoneyFlowTrendLayout.titleLineHeight
                    )
                )
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(data.displayUnit(for: language))
                .modifier(
                    CustomFontModifier(
                        size: StockDetailMoneyFlowTrendLayout.unitFontSize,
                        font: .medium,
                        lineHeight: StockDetailMoneyFlowTrendLayout.unitLineHeight
                    )
                )
                .foregroundColor(Color("color-text-60"))
                .lineLimit(1)
        }
        .frame(height: StockDetailMoneyFlowTrendLayout.titleLineHeight)
    }

    private var chart: some View {
        ZStack(alignment: .topLeading) {
            chartGrid

            Image("stock_detail_money_flow_trend_chart")
                .resizable()
                .frame(maxWidth: .infinity)
                .frame(height: StockDetailMoneyFlowTrendLayout.chartHeight)
                .accessibilityHidden(true)

            chartValueLabels
            zeroLineLabel
        }
        .frame(height: StockDetailMoneyFlowTrendLayout.chartHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(chartAccessibilityLabel)
    }

    private var chartGrid: some View {
        ZStack {
            Rectangle()
                .stroke(
                    Color("color-separator-10"),
                    lineWidth: StockDetailMoneyFlowTrendLayout.gridLineWidth
                )

            VStack(spacing: 0) {
                Color.clear
                    .frame(height: StockDetailMoneyFlowTrendLayout.zeroLinePosition)

                Rectangle()
                    .fill(Color("color-separator-10"))
                    .frame(height: StockDetailMoneyFlowTrendLayout.gridLineWidth)

                Spacer(minLength: 0)
            }
        }
        .frame(height: StockDetailMoneyFlowTrendLayout.chartHeight)
    }

    private var chartAccessibilityLabel: String {
        let separator = language == .english ? ", " : "，"
        return [
            data.displayTitle(for: language),
            "\(language.text(.stockDetailHigh)) \(data.upperValue)",
            "\(language.text(.stockDetailLow)) \(data.lowerValue)",
            "\(language.text(.zeroValue)) \(data.zeroValue)"
        ].joined(separator: separator)
    }

    private var chartValueLabels: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(data.upperValue)
                .capitalTrendValueStyle(color: Color("color-utility3-red"))
                .padding(.leading, StockDetailMoneyFlowTrendLayout.labelHorizontalInset)
                .padding(.top, StockDetailMoneyFlowTrendLayout.labelVerticalInset)

            Spacer(minLength: 0)

            Text(data.lowerValue)
                .capitalTrendValueStyle(color: Color("color-utility3-green"))
                .padding(.leading, StockDetailMoneyFlowTrendLayout.labelHorizontalInset)
                .padding(.bottom, StockDetailMoneyFlowTrendLayout.labelVerticalInset)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .leading
        )
        .accessibilityHidden(true)
    }

    private var zeroLineLabel: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: StockDetailMoneyFlowTrendLayout.zeroLabelTopInset)

            HStack(spacing: 0) {
                Text(data.zeroValue)
                    .capitalTrendValueStyle(color: Color("color-text-60"))
                    .padding(.leading, StockDetailMoneyFlowTrendLayout.labelHorizontalInset)

                Spacer(minLength: 0)
            }
            .frame(height: StockDetailMoneyFlowTrendLayout.valueLabelLineHeight)

            Spacer(minLength: 0)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .accessibilityHidden(true)
    }

    private var timeAxis: some View {
        HStack {
            Text(data.startTime)

            Spacer(minLength: 0)

            Text(data.endTime)
        }
        .modifier(
            CustomFontModifier(
                size: StockDetailMoneyFlowTrendLayout.axisFontSize,
                font: .regular,
                lineHeight: StockDetailMoneyFlowTrendLayout.axisLineHeight
            )
        )
        .foregroundColor(Color("color-text-60"))
        .frame(height: StockDetailMoneyFlowTrendLayout.axisLineHeight)
    }
}

private extension View {
    func capitalTrendValueStyle(color: Color) -> some View {
        modifier(
            CustomFontModifier(
                size: StockDetailMoneyFlowTrendLayout.valueLabelFontSize,
                font: .regular,
                lineHeight: StockDetailMoneyFlowTrendLayout.valueLabelLineHeight
            )
        )
        .foregroundColor(color)
        .lineLimit(1)
    }
}

extension StockDetailMoneyFlowTrendData {
    static let mock = StockDetailMoneyFlowTrendData(
        title: "资金流向趋势",
        unit: "单位：万",
        upperValue: "+4929.12",
        lowerValue: "+2099.11",
        zeroValue: "0.00",
        startTime: "9:30",
        endTime: "16:00",
        localizedTitle: .init(
            simplifiedChinese: "资金流向趋势",
            traditionalChinese: "資金流向趨勢",
            english: "Money Flow"
        ),
        localizedUnit: .init(
            simplifiedChinese: "单位：万",
            traditionalChinese: "單位：萬",
            english: "Unit: 10K"
        )
    )
}

private enum StockDetailMoneyFlowTrendLayout {
    static let horizontalPadding: CGFloat = 16
    static let headerSpacing: CGFloat = 8
    static let titleFontSize: CGFloat = 16
    static let titleLineHeight: CGFloat = 24
    static let unitFontSize: CGFloat = 12
    static let unitLineHeight: CGFloat = 16
    static let chartVerticalPadding: CGFloat = 16
    static let chartToAxisSpacing: CGFloat = 2
    static let chartHeight: CGFloat = 180
    static let gridLineWidth: CGFloat = 0.5
    static let zeroLinePosition: CGFloat = 126
    static let zeroLabelTopInset: CGFloat = 121
    static let labelHorizontalInset: CGFloat = 1
    static let labelVerticalInset: CGFloat = 1
    static let valueLabelFontSize: CGFloat = 10
    static let valueLabelLineHeight: CGFloat = 10
    static let axisFontSize: CGFloat = 10
    static let axisLineHeight: CGFloat = 10
}

struct StockDetailMoneyFlowTrend_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailMoneyFlowTrend()
                .previewDisplayName("Light")

            StockDetailMoneyFlowTrend()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
        .frame(width: 402)
        .previewLayout(.sizeThatFits)
    }
}
