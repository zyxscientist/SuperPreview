//
//  StockDetailChart.swift
//  SuperPreview
//
//  组件名称：详情页行情图表
//  简介：使用正式图表的布局和绘制规则展示可交互的 mock 行情。
//  用于：股票详情页报价区域下方的分时、K 线和技术指标。
//

import SwiftUI
import UIKit

struct StockDetailChart: View {
    var body: some View {
        StockChartPanel()
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
