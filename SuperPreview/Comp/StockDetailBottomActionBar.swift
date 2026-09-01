//
//  StockDetailBottomActionBar.swift
//  SuperPreview
//

import SwiftUI

/// The fixed bottom actions used by the stock-detail page.
///
/// The bar keeps each utility action at 60 points and lets the primary action
/// use the remaining width. The utility actions are grouped together so the
/// primary action has the single 8-point gap shown in the Figma layout.
struct StockDetailBottomActionBar: View {
    let onTrade: () -> Void
    let onWatchlist: () -> Void
    let onReminder: () -> Void

    @Environment(\.demoLanguage) private var language

    init(
        onTrade: @escaping () -> Void = {},
        onWatchlist: @escaping () -> Void = {},
        onReminder: @escaping () -> Void = {}
    ) {
        self.onTrade = onTrade
        self.onWatchlist = onWatchlist
        self.onReminder = onReminder
    }

    var body: some View {
        glassWrappedActions
            .padding(.horizontal, StockDetailBottomActionBarLayout.horizontalPadding)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("stockDetail.bottomActionBar")
    }

    @ViewBuilder
    private var glassWrappedActions: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 0) {
                actionButtons
                    .padding(StockDetailBottomActionBarLayout.glassInset)
                    .frame(height: StockDetailBottomActionBarLayout.containerHeight)
                    .glassEffect(.regular, in: .capsule)
            }
        } else {
            actionButtons
                .padding(StockDetailBottomActionBarLayout.glassInset)
                .frame(height: StockDetailBottomActionBarLayout.containerHeight)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(
                    color: Color.black.opacity(0.12),
                    radius: StockDetailBottomActionBarLayout.fallbackShadowRadius,
                    y: StockDetailBottomActionBarLayout.fallbackShadowYOffset
                )
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 0) {
            Button(action: onTrade) {
                Text(language.text(.trade))
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailBottomActionBarLayout.primaryFontSize,
                            font: .bold,
                            lineHeight: StockDetailBottomActionBarLayout.primaryFontSize
                        )
                    )
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity)
                    .frame(height: StockDetailBottomActionBarLayout.buttonHeight)
                    .background(Color("color-brand-blue"), in: Capsule())
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(language.text(.trade))
            .accessibilityIdentifier("stockDetail.bottomActionBar.trade")

            HStack(spacing: 0) {
                utilityButton(
                    title: language.text(.watchlist),
                    iconAssetName: "Favorite",
                    action: onWatchlist,
                    identifier: "watchlist"
                )

                utilityButton(
                    title: language.text(.reminder),
                    iconAssetName: "Alert-Inactive",
                    action: onReminder,
                    identifier: "reminder"
                )

                utilityButton(
                    title: language.text(.shuffle),
                    iconAssetName: "stock_detail_shuffle",
                    action: {},
                    identifier: "shuffle"
                )
            }
            .padding(.leading, StockDetailBottomActionBarLayout.primaryToUtilitySpacing)
        }
        .padding(.trailing, StockDetailBottomActionBarLayout.contentTrailingPadding)
    }

    private func utilityButton(
        title: String,
        iconAssetName: String,
        action: @escaping () -> Void,
        identifier: String
    ) -> some View {
        Button(action: action) {
            VStack(spacing: StockDetailBottomActionBarLayout.iconTitleSpacing) {
                Image(iconAssetName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: StockDetailBottomActionBarLayout.iconSize,
                        height: StockDetailBottomActionBarLayout.iconSize
                    )
                    .foregroundColor(Color("color-text-30"))

                Text(title)
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailBottomActionBarLayout.utilityFontSize,
                            font: .medium,
                            lineHeight: StockDetailBottomActionBarLayout.utilityFontSize
                        )
                    )
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .allowsTightening(true)
            }
            .frame(
                width: StockDetailBottomActionBarLayout.utilityButtonWidth,
                height: StockDetailBottomActionBarLayout.buttonHeight
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityIdentifier("stockDetail.bottomActionBar.\(identifier)")
    }
}

private enum StockDetailBottomActionBarLayout {
    static let horizontalPadding: CGFloat = 16
    static let containerHeight: CGFloat = 60
    static let glassInset: CGFloat = 8
    static let buttonHeight: CGFloat = 44
    static let utilityButtonWidth: CGFloat = 60
    static let iconSize: CGFloat = 24
    static let iconTitleSpacing: CGFloat = 4
    static let primaryToUtilitySpacing: CGFloat = 8
    static let contentTrailingPadding: CGFloat = 8
    static let primaryFontSize: CGFloat = 16
    static let utilityFontSize: CGFloat = 10
    static let fallbackShadowRadius: CGFloat = 20
    static let fallbackShadowYOffset: CGFloat = 4
}

private struct StockDetailBottomActionBarPreviewHarness: View {
    @State private var latestAction = ""

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            if !latestAction.isEmpty {
                Text(latestAction)
                    .modifier(CustomFontModifier(size: 13, font: .regular, lineHeight: 13))
                    .foregroundColor(Color("color-text-60"))
            }

            StockDetailBottomActionBar(
                onTrade: { latestAction = "trade" },
                onWatchlist: { latestAction = "watchlist" },
                onReminder: { latestAction = "reminder" }
            )
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("color-base-1"))
    }
}

struct StockDetailBottomActionBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailBottomActionBarPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Simplified Chinese")

            StockDetailBottomActionBarPreviewHarness()
                .environment(\.demoLanguage, .english)
                .preferredColorScheme(.dark)
                .previewDisplayName("English · Dark")
        }
        .previewLayout(.fixed(width: 402, height: 140))
    }
}
