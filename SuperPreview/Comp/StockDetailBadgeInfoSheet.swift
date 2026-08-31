//
//  StockDetailBadgeInfoSheet.swift
//  SuperPreview
//

import SwiftUI

/// The bottom-sheet content that explains the badges displayed with a quote.
///
/// `InteractiveBottomCard` supplies the presentation, dimming, and
/// finger-tracking dismissal. This view deliberately owns only the Figma
/// sheet content so it can be previewed in isolation as well.
struct StockDetailBadgeInfoSheet: View {
    let market: StockDetailQuoteMarket
    let badges: [StockDetailQuoteBadge]

    @Environment(\.demoLanguage) private var language

    init(market: StockDetailQuoteMarket, badges: [StockDetailQuoteBadge]) {
        self.market = market
        self.badges = badges
    }

    var body: some View {
        VStack(spacing: 0) {
            sheetHandle
            sheetContent
            homeIndicatorArea
        }
        .frame(maxWidth: .infinity)
        .background(Color("color-base-1"))
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(
                    topLeading: StockDetailBadgeInfoSheetLayout.cornerRadius,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: StockDetailBadgeInfoSheetLayout.cornerRadius
                ),
                style: .continuous
            )
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.badgeInfoSheet")
    }

    private var sheetHandle: some View {
        Capsule()
            .fill(Color("color-scale-3"))
            .frame(
                width: StockDetailBadgeInfoSheetLayout.handleWidth,
                height: StockDetailBadgeInfoSheetLayout.handleHeight
            )
            .padding(.top, StockDetailBadgeInfoSheetLayout.handleTopPadding)
            .frame(
                maxWidth: .infinity,
                minHeight: StockDetailBadgeInfoSheetLayout.handleAreaHeight,
                maxHeight: StockDetailBadgeInfoSheetLayout.handleAreaHeight,
                alignment: .top
            )
            .accessibilityHidden(true)
    }

    private var sheetContent: some View {
        VStack(
            alignment: .leading,
            spacing: StockDetailBadgeInfoSheetLayout.rowSpacing
        ) {
            ForEach(Array(infos.enumerated()), id: \.offset) { _, info in
                infoRow(info)
            }
        }
        .padding(.horizontal, StockDetailBadgeInfoSheetLayout.horizontalPadding)
        .padding(.bottom, StockDetailBadgeInfoSheetLayout.contentBottomPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var homeIndicatorArea: some View {
        Color.clear
            .frame(height: StockDetailBadgeInfoSheetLayout.homeIndicatorAreaHeight)
            .accessibilityHidden(true)
    }

    private func infoRow(_ info: StockDetailBadgeInfo) -> some View {
        HStack(spacing: StockDetailBadgeInfoSheetLayout.iconTextSpacing) {
            Image(info.largeIconAssetName)
                .resizable()
                .scaledToFit()
                .frame(
                    width: StockDetailBadgeInfoSheetLayout.iconSize,
                    height: StockDetailBadgeInfoSheetLayout.iconSize
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: StockDetailBadgeInfoSheetLayout.textSpacing) {
                Text(info.title.text(for: language))
                    .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                if let subtitle = info.subtitle {
                    Text(subtitle.text(for: language))
                        .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                        .foregroundColor(Color("color-brand-blue"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockDetail.badgeInfoSheet.row.\(info.badge.rawValue)")
    }

    private var infos: [StockDetailBadgeInfo] {
        badges.map { StockDetailBadgeInfo(badge: $0, market: market) }
    }
}

private struct StockDetailBadgeInfo {
    let badge: StockDetailQuoteBadge
    let market: StockDetailQuoteMarket

    var largeIconAssetName: String {
        "\(badge.rawValue)_large"
    }

    var title: StockDetailQuoteLocalizedText {
        switch badge {
        case .unitedStates:
            StockDetailQuoteLocalizedText(
                simplifiedChinese: "美国市场",
                traditionalChinese: "美國市場",
                english: "US Market"
            )
        case .hongKong:
            StockDetailQuoteLocalizedText(
                simplifiedChinese: "香港市场",
                traditionalChinese: "香港市場",
                english: "Hong Kong Market"
            )
        case .china:
            StockDetailQuoteLocalizedText(
                simplifiedChinese: "中国市场",
                traditionalChinese: "中國市場",
                english: "China Market"
            )
        case .stockConnection:
            stockConnectionTitle
        case .margin:
            StockDetailQuoteLocalizedText(
                simplifiedChinese: "支持融资",
                traditionalChinese: "支持融資",
                english: "Margin Eligible"
            )
        case .usLevel1:
            StockDetailQuoteLocalizedText(
                simplifiedChinese: "Lv1实时行情",
                traditionalChinese: "Lv1實時行情",
                english: "Lv1 Real-time Quotes"
            )
        case .hongKongLevel2:
            StockDetailQuoteLocalizedText(
                simplifiedChinese: "Lv2实时行情",
                traditionalChinese: "Lv2實時行情",
                english: "Lv2 Real-time Quotes"
            )
        case .aShareLevel1:
            StockDetailQuoteLocalizedText(
                simplifiedChinese: "Lv1实时行情",
                traditionalChinese: "Lv1實時行情",
                english: "Lv1 Real-time Quotes"
            )
        case .crypto:
            StockDetailQuoteLocalizedText(
                simplifiedChinese: "虚拟资产",
                traditionalChinese: "虛擬資產",
                english: "Virtual Assets"
            )
        }
    }

    var subtitle: StockDetailQuoteLocalizedText? {
        guard badge == .margin else { return nil }

        return StockDetailQuoteLocalizedText(
            simplifiedChinese: "融资抵押率：60%",
            traditionalChinese: "融資抵押率：60%",
            english: "Margin Ratio: 60%"
        )
    }

    private var stockConnectionTitle: StockDetailQuoteLocalizedText {
        switch market {
        case .hongKong:
            StockDetailQuoteLocalizedText(
                simplifiedChinese: "沪股通",
                traditionalChinese: "滬股通",
                english: "Shanghai Stock Connect"
            )
        case .aShare:
            StockDetailQuoteLocalizedText(
                simplifiedChinese: "港股通",
                traditionalChinese: "港股通",
                english: "Hong Kong Stock Connect"
            )
        case .us, .crypto:
            StockDetailQuoteLocalizedText(
                simplifiedChinese: "互联互通",
                traditionalChinese: "互聯互通",
                english: "Stock Connect"
            )
        }
    }
}

private enum StockDetailBadgeInfoSheetLayout {
    static let horizontalPadding: CGFloat = 16
    static let handleAreaHeight: CGFloat = 44
    static let handleTopPadding: CGFloat = 10
    static let handleWidth: CGFloat = 40
    static let handleHeight: CGFloat = 4
    static let iconSize: CGFloat = 32
    static let iconTextSpacing: CGFloat = 12
    static let textSpacing: CGFloat = 2
    static let rowSpacing: CGFloat = 18
    static let contentBottomPadding: CGFloat = 32
    static let homeIndicatorAreaHeight: CGFloat = 34
    static let cornerRadius: CGFloat = 10
}

struct StockDetailBadgeInfoSheet_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailBadgeInfoSheet(
                market: .hongKong,
                badges: [.hongKong, .stockConnection, .margin, .hongKongLevel2]
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewDisplayName("Hong Kong · Chinese")

            StockDetailBadgeInfoSheet(
                market: .us,
                badges: [.unitedStates, .margin, .usLevel1]
            )
            .environment(\.demoLanguage, .english)
            .previewDisplayName("US · English")
        }
        .frame(width: 402)
        .previewLayout(.sizeThatFits)
    }
}
