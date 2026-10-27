//
//  MarketStockScreenerCard.swift
//  SuperPreview
//
//  组件名称：选股器入口卡片
//  用于：美股市场页。
//

import SwiftUI

struct MarketStockScreenerCard: View {
    let reducesGlass: Bool
    let action: () -> Void

    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(reducesGlass: Bool, action: @escaping () -> Void = {}) {
        self.reducesGlass = reducesGlass
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconSurface

                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(language.text(.marketStockScreenerTitle))
                            .modifier(CustomFontModifier(size: 14, font: .medium, lineHeight: 20))
                            .foregroundStyle(Color("color-text-30"))
                            .frame(height: 20, alignment: .leading)

                        Text(language.text(.marketStockScreenerSubtitle))
                            .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                            .foregroundStyle(Color("color-text-60"))
                            .frame(height: 16, alignment: .leading)
                    }
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Image("chevron_right_text30_sm")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .accessibilityHidden(true)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Color("color-scale-1"),
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("market.usStockScreener")
    }

    private var iconSurface: some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)

        return Group {
            if #available(iOS 26.0, *), !reducesGlass, !reduceTransparency {
                Color.clear
                    .frame(width: 36, height: 36)
                    .glassEffect(.regular.interactive(), in: shape)
            } else {
                shape
                    .fill(.ultraThinMaterial)
                    .overlay {
                        shape.strokeBorder(Color("color-separator-10"), lineWidth: 0.5)
                    }
                    .frame(width: 36, height: 36)
                    .shadow(color: .black.opacity(0.02), radius: 7.5, x: 0, y: 8)
            }
        }
        .overlay {
            Image("ipo_outline")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .accessibilityHidden(true)
        }
    }
}

struct MarketStockScreenerCard_Previews: PreviewProvider {
    static var previews: some View {
        MarketStockScreenerCard(reducesGlass: false)
            .padding(.horizontal, 16)
            .previewLayout(.fixed(width: 402, height: 64))
            .previewDisplayName("美股选股器")
    }
}
