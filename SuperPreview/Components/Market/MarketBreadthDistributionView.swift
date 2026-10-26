//
//  MarketBreadthDistributionView.swift
//  SuperPreview
//
//  组件名称：涨跌分布
//  简介：展示三段涨跌分布条及上涨、下跌数量。
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
    @Environment(\.demoLanguage) private var language

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
            Text(language.text(.marketBreadthDistribution))
                .modifier(CustomFontModifier(size: 18, font: .bold, lineHeight: 28))
                .foregroundColor(Color("color-text-30"))

            Spacer(minLength: 0)

            Text(String(format: language.text(.marketBreadthUpdatedFormat), data.updatedAt))
                .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                .foregroundColor(Color("color-text-90"))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(height: 28, alignment: .center)
    }

    private var distributionBar: some View {
        GeometryReader { geometry in
            // Preserve the Figma widths (178:39:145) with fixed 4pt gaps.
            let scale = max(geometry.size.width - 8, 0) / 362

            HStack(spacing: 4) {
                Capsule()
                    .fill(Color("color-utility3-green"))
                    .frame(width: 178 * scale)

                Capsule()
                    .fill(Color("color-text-60"))
                    .frame(width: 39 * scale)

                Capsule()
                    .fill(Color("color-utility3-red"))
                    .frame(width: 145 * scale)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    private var countSummary: some View {
        HStack(spacing: 0) {
            downCount

            Spacer(minLength: 0)

            upCount
        }
        .frame(maxWidth: .infinity)
    }

    private var downCount: some View {
        HStack(spacing: 4) {
            Image("market_breadth_distribution_down")
                .renderingMode(.template)
                .resizable()
                .frame(width: 10, height: 8)
                .rotationEffect(.degrees(90))
                .frame(width: 8, height: 10)
                .foregroundColor(Color("color-utility3-green"))
                .accessibilityHidden(true)

            Text(formatted(data.downCount))
                .modifier(CustomFontModifier(size: 14, font: .bold, lineHeight: 20))
                .foregroundColor(Color("color-utility3-green"))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: language.text(.marketBreadthDownAccessibilityFormat), formatted(data.downCount)))
    }

    private var upCount: some View {
        HStack(spacing: 4) {
            Text(formatted(data.upCount))
                .modifier(CustomFontModifier(size: 14, font: .bold, lineHeight: 20))
                .foregroundColor(Color("color-utility3-red"))

            Image("market_breadth_distribution_up")
                .renderingMode(.template)
                .resizable()
                .frame(width: 10, height: 8)
                .rotationEffect(.degrees(-90))
                .frame(width: 8, height: 10)
                .foregroundColor(Color("color-utility3-red"))
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: language.text(.marketBreadthUpAccessibilityFormat), formatted(data.upCount)))
    }

    private func formatted(_ count: Int) -> String {
        count.formatted(.number.locale(Locale(identifier: "en_US")))
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
