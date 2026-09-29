//
//  StockDetailHistoryPerformance.swift
//  SuperPreview
//
//  组件名称：历史表现摘要
//  简介：按时间范围展示标的历史涨跌幅。
//  用于：加密货币详情页报价区与行情图表之间。
//

import SwiftUI

private enum StockDetailHistoryPerformanceTone {
    case positive
    case negative
    case neutral

    var color: Color {
        switch self {
        case .positive:
            Color("color-utility3-red")
        case .negative:
            Color("color-utility3-green")
        case .neutral:
            Color("color-text-60")
        }
    }
}

private struct StockDetailHistoryPerformanceItem: Identifiable {
    let id: String
    let period: StockDetailQuoteLocalizedText
    let value: String
    let tone: StockDetailHistoryPerformanceTone

    static let samples: [Self] = [
        .init(
            id: "today",
            period: .init(simplifiedChinese: "今天", traditionalChinese: "今天", english: "Today"),
            value: "+3.21%",
            tone: .positive
        ),
        .init(
            id: "sevenDays",
            period: .init(simplifiedChinese: "7天", traditionalChinese: "7天", english: "7D"),
            value: "-3.21%",
            tone: .negative
        ),
        .init(
            id: "thirtyDays",
            period: .init(simplifiedChinese: "30天", traditionalChinese: "30天", english: "30D"),
            value: "3.21%",
            tone: .neutral
        ),
        .init(
            id: "ninetyDays",
            period: .init(simplifiedChinese: "90天", traditionalChinese: "90天", english: "90D"),
            value: "--",
            tone: .neutral
        ),
        .init(
            id: "oneHundredEightyDays",
            period: .init(simplifiedChinese: "180天", traditionalChinese: "180天", english: "180D"),
            value: "+3.21%",
            tone: .positive
        ),
        .init(
            id: "oneYear",
            period: .init(simplifiedChinese: "1年", traditionalChinese: "1年", english: "1Y"),
            value: "+3.21%",
            tone: .positive
        )
    ]
}

struct StockDetailHistoryPerformance: View {
    @Environment(\.demoLanguage) private var language

    var body: some View {
        HStack(spacing: 0) {
            ForEach(StockDetailHistoryPerformanceItem.samples) { item in
                VStack(alignment: .leading, spacing: StockDetailHistoryPerformanceLayout.rowSpacing) {
                    Text(item.period.text(for: language))
                        .modifier(
                            CustomFontModifier(
                                size: StockDetailHistoryPerformanceLayout.fontSize,
                                font: .regular,
                                lineHeight: StockDetailHistoryPerformanceLayout.lineHeight
                            )
                        )
                        .foregroundColor(Color("color-text-60"))
                        .frame(height: StockDetailHistoryPerformanceLayout.lineHeight, alignment: .leading)

                    Text(item.value)
                        .modifier(
                            CustomFontModifier(
                                size: StockDetailHistoryPerformanceLayout.fontSize,
                                font: .regular,
                                lineHeight: StockDetailHistoryPerformanceLayout.lineHeight
                            )
                        )
                        .foregroundColor(item.tone.color)
                        .frame(height: StockDetailHistoryPerformanceLayout.lineHeight, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("stockDetail.historyPerformance.\(item.id)")
            }
        }
        .padding(.horizontal, StockDetailHistoryPerformanceLayout.horizontalPadding)
        .frame(maxWidth: .infinity)
        .frame(height: StockDetailHistoryPerformanceLayout.height)
        .background(Color("color-base-1"))
        .overlay(alignment: .top) {
            separator
        }
        .overlay(alignment: .bottom) {
            separator
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.historyPerformance")
    }

    private var separator: some View {
        Rectangle()
            .fill(Color("color-separator-10"))
            .frame(height: StockDetailHistoryPerformanceLayout.separatorHeight)
            .accessibilityHidden(true)
    }
}

private enum StockDetailHistoryPerformanceLayout {
    static let horizontalPadding: CGFloat = 16
    static let height: CGFloat = 50
    static let rowSpacing: CGFloat = 2
    static let fontSize: CGFloat = 12
    static let lineHeight: CGFloat = 16
    static let separatorHeight: CGFloat = 0.5
}

struct StockDetailHistoryPerformance_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailHistoryPerformance()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Chinese")

            StockDetailHistoryPerformance()
                .environment(\.demoLanguage, .english)
                .previewDisplayName("English")
        }
        .frame(width: 402)
        .previewLayout(.sizeThatFits)
    }
}
