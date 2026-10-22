//
//  MarketBreadthDistributionView.swift
//  SuperPreview
//
//  组件名称：涨跌分布
//  简介：展示上涨、平盘和下跌数量及其分布条。
//

import SwiftUI

struct MarketBreadthDistributionData: Hashable {
    let updatedAt: String
    let downCount: Int
    let unchangedCount: Int
    let upCount: Int

    static let figmaReference = Self(
        updatedAt: "11/25 14:59",
        downCount: 1_567,
        unchangedCount: 567,
        upCount: 3_366
    )
}

/// A standalone market-breadth summary matching the Figma "涨跌分布" component.
struct MarketBreadthDistributionView: View {
    let data: MarketBreadthDistributionData

    init(data: MarketBreadthDistributionData = .figmaReference) {
        self.data = data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            VStack(spacing: 12) {
                distributionBar
                countSummary
                    .frame(height: 20)
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("market.breadthDistribution")
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("涨跌分布")
                .modifier(CustomFontModifier(size: 18, font: .medium, lineHeight: 28))
                .foregroundColor(Color("color-text-30"))

            Spacer(minLength: 0)

            Text("更新：\(data.updatedAt)")
                .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                .foregroundColor(Color("color-text-90"))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(height: 28, alignment: .center)
    }

    private var distributionBar: some View {
        GeometryReader { geometry in
            ZStack {
                barSegments(width: geometry.size.width)
                    .opacity(0.1)
                    .blur(radius: 4)
                    .offset(y: 4)

                barSegments(width: geometry.size.width)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    private func barSegments(width: CGFloat) -> some View {
        let scale = width / 370
        let unchangedBand = Path { path in
            path.move(to: CGPoint(x: 170 * scale, y: 0))
            path.addLine(to: CGPoint(x: 204 * scale, y: 0))
            path.addLine(to: CGPoint(x: 202 * scale, y: 8))
            path.addLine(to: CGPoint(x: 168 * scale, y: 8))
            path.closeSubpath()
        }

        return ZStack {
            Capsule()
                .fill(Color("color-utility3-green"))

            Color("color-utility3-red")
                .frame(width: width / 2)
                .frame(width: width, alignment: .trailing)

            unchangedBand.stroke(Color("color-base-1"), lineWidth: 4)
            unchangedBand.fill(Color("color-text-90"))
        }
        .frame(width: width, height: 8)
        .clipShape(Capsule())
    }

    private var countSummary: some View {
        HStack(spacing: 0) {
            downCount

            Spacer(minLength: 0)

            unchangedCount

            Spacer(minLength: 0)

            upCount
        }
        .frame(maxWidth: .infinity)
    }

    private var downCount: some View {
        HStack(spacing: 4) {
            Image("market_breadth_distribution_down")
                .resizable()
                .frame(width: 10, height: 8)
                .rotationEffect(.degrees(90))
                .frame(width: 8, height: 10)
                .accessibilityHidden(true)

            Text(formatted(data.downCount))
                .modifier(CustomFontModifier(size: 14, font: .bold, lineHeight: 20))
                .foregroundColor(Color("color-utility3-green"))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("下跌 \(formatted(data.downCount))")
    }

    private var unchangedCount: some View {
        HStack(spacing: 4) {
            Capsule()
                .fill(Color("color-text-90"))
                .frame(width: 6, height: 2)
                .accessibilityHidden(true)

            Text(formatted(data.unchangedCount))
                .modifier(CustomFontModifier(size: 14, font: .bold, lineHeight: 20))
                .foregroundColor(Color("color-text-90"))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("平盘 \(formatted(data.unchangedCount))")
    }

    private var upCount: some View {
        HStack(spacing: 4) {
            Text(formatted(data.upCount))
                .modifier(CustomFontModifier(size: 14, font: .bold, lineHeight: 20))
                .foregroundColor(Color("color-utility3-red"))

            Image("market_breadth_distribution_up")
                .resizable()
                .frame(width: 10, height: 8)
                .rotationEffect(.degrees(-90))
                .frame(width: 8, height: 10)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("上涨 \(formatted(data.upCount))")
    }

    private func formatted(_ count: Int) -> String {
        count.formatted(.number.locale(Locale(identifier: "en_US_POSIX")))
    }
}

struct MarketBreadthDistributionView_Previews: PreviewProvider {
    static var previews: some View {
        MarketBreadthDistributionView()
            .frame(width: 402)
            .background(Color("color-base-1"))
            .previewLayout(.sizeThatFits)
            .previewDisplayName("涨跌分布")
    }
}
