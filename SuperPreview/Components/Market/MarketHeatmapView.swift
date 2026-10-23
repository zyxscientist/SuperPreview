//
//  MarketHeatmapView.swift
//  SuperPreview
//
//  组件名称：热力图
//  简介：以颜色和面积展示行业涨跌幅。
//  用于：新市场页的港股分类，也可独立预览。
//

import SwiftUI

struct MarketHeatmapSector: Identifiable, Hashable {
    let id: String
    let name: String
    let percentChange: Double
    let backgroundOpacity: Double
    let widthRatio: CGFloat

    static let figmaReferenceRows: [[Self]] = [
        [
            Self(id: "internet-content", name: "互联网内容与信息", percentChange: 4.66, backgroundOpacity: 0.2, widthRatio: 0.5),
            Self(id: "bank", name: "银行", percentChange: 0.66, backgroundOpacity: 0.1, widthRatio: 0.3),
            Self(id: "insurance", name: "保险", percentChange: -0.66, backgroundOpacity: 0.05, widthRatio: 0.2)
        ],
        [
            Self(id: "biotech-pharma", name: "药品制造商-生物", percentChange: -1.66, backgroundOpacity: 0.1, widthRatio: 0.35),
            Self(id: "internet-retail", name: "互联网零售", percentChange: -19.66, backgroundOpacity: 0.2, widthRatio: 0.25),
            Self(id: "software", name: "软件-基", percentChange: 0.99, backgroundOpacity: 0.1, widthRatio: 0.2),
            Self(id: "semiconductor", name: "半导体", percentChange: 1.01, backgroundOpacity: 0.1, widthRatio: 0.2)
        ]
    ]
}

/// A reusable two-row market heatmap using fixed visual sample data by default.
struct MarketHeatmapView: View {
    let rows: [[MarketHeatmapSector]]
    let onShowAll: () -> Void

    init(
        rows: [[MarketHeatmapSector]] = MarketHeatmapSector.figmaReferenceRows,
        onShowAll: @escaping () -> Void = { /* TODO: connect the heatmap destination. */ }
    ) {
        self.rows = rows
        self.onShowAll = onShowAll
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            VStack(spacing: 2) {
                ForEach(Array(rows.enumerated()), id: \.offset) { rowIndex, sectors in
                    heatmapRow(sectors, rowIndex: rowIndex)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("market.heatmap")
    }

    private var header: some View {
        Button(action: onShowAll) {
            HStack(spacing: 8) {
                Text("热力图")
                    .modifier(CustomFontModifier(size: 18, font: .medium, lineHeight: 28))
                    .foregroundStyle(Color("color-text-30"))

                Spacer(minLength: 0)

                Image("chevron_right_text30_sm")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
            }
            .frame(height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("热力图，查看全部")
        .accessibilityIdentifier("market.heatmap.showAll")
    }

    private func heatmapRow(_ sectors: [MarketHeatmapSector], rowIndex: Int) -> some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(Array(sectors.enumerated()), id: \.element.id) { columnIndex, sector in
                    heatmapTile(
                        sector,
                        rowIndex: rowIndex,
                        columnIndex: columnIndex,
                        columnCount: sectors.count
                    )
                    .frame(width: tileWidth(for: sector, in: sectors, availableWidth: geometry.size.width))
                }
            }
        }
        .frame(height: 82)
    }

    private func heatmapTile(
        _ sector: MarketHeatmapSector,
        rowIndex: Int,
        columnIndex: Int,
        columnCount: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(sector.name)
                .foregroundStyle(Color("color-text-30"))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(height: 14, alignment: .leading)

            Text(formattedChange(sector.percentChange))
                .foregroundStyle(changeColor(for: sector))
                .lineLimit(1)
                .frame(height: 14, alignment: .leading)
        }
        .modifier(CustomFontModifier(size: 14, font: .medium, lineHeight: 14))
        .padding(.horizontal, 4)
        .padding(.vertical, 24)
        .frame(height: 82, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(changeColor(for: sector).opacity(sector.backgroundOpacity))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: rowIndex == 0 && columnIndex == 0 ? 20 : 0,
                bottomLeadingRadius: rowIndex == rows.count - 1 && columnIndex == 0 ? 20 : 0,
                bottomTrailingRadius: rowIndex == rows.count - 1 && columnIndex == columnCount - 1 ? 20 : 0,
                topTrailingRadius: rowIndex == 0 && columnIndex == columnCount - 1 ? 20 : 0
            )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sector.name)，\(formattedChange(sector.percentChange))")
        .accessibilityIdentifier("market.heatmap.tile.\(sector.id)")
    }

    private func tileWidth(
        for sector: MarketHeatmapSector,
        in sectors: [MarketHeatmapSector],
        availableWidth: CGFloat
    ) -> CGFloat {
        let gapWidth = CGFloat(max(sectors.count - 1, 0)) * 2
        let rowWidth = sectors.reduce(CGFloat.zero) { $0 + $1.widthRatio }
        return (availableWidth - gapWidth) * sector.widthRatio / rowWidth
    }

    private func changeColor(for sector: MarketHeatmapSector) -> Color {
        Color(sector.percentChange >= 0 ? "color-utility3-red" : "color-utility3-green")
    }

    private func formattedChange(_ change: Double) -> String {
        String(format: "%+.2f%%", locale: Locale(identifier: "en_US_POSIX"), change)
    }
}

struct MarketHeatmapView_Previews: PreviewProvider {
    static var previews: some View {
        MarketHeatmapView()
            .background(Color("color-base-1"))
            .previewLayout(.fixed(width: 402, height: 206))
            .previewDisplayName("热力图")
    }
}
