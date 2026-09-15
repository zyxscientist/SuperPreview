//
//  StockDetailChart.swift
//  SuperPreview
//
//  组件名称：详情页行情图表
//  简介：展示股票详情页的静态行情图表预览。
//  用于：股票详情页报价区域下方的图表占位内容。
//

import SwiftUI

/// A chart placeholder for the stock-detail prototype.
///
/// The production chart is intentionally represented by the same static
/// snapshot used by the stock-order prototype until the chart interaction and
/// rendering model are implemented.
struct StockDetailChart: View {
    static let snapshotAspectRatio: CGFloat = 402.0 / 409.0

    var body: some View {
        Image("stock_order_chart_snapshot")
            .resizable()
            .aspectRatio(Self.snapshotAspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Stock chart preview")
            .accessibilityIdentifier("stockDetail.chart")
    }
}

struct StockDetailChart_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailChart()
                .previewDisplayName("Light")

            StockDetailChart()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
        .frame(width: 402)
        .previewLayout(.sizeThatFits)
    }
}
