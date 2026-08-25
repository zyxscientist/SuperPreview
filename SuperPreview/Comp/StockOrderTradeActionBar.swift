//
//  StockOrderTradeActionBar.swift
//  SuperPreview
//

import SwiftUI

enum StockOrderTradeActionBarStatus: Hashable {
    case locked
    case unlocked
}

/// The bottom trade actions for the stock-order page.
///
/// The component defaults to the unlocked state shown in the current design.
/// Its outer capsule uses native Liquid Glass on iOS 26 and gracefully falls
/// back to a system material on earlier versions.
struct StockOrderTradeActionBar: View {
    let status: StockOrderTradeActionBarStatus
    let onUnlock: () -> Void
    let onBuy: () -> Void
    let onSell: () -> Void

    @Environment(\.demoLanguage) private var language

    init(
        status: StockOrderTradeActionBarStatus = .unlocked,
        onUnlock: @escaping () -> Void = {},
        onBuy: @escaping () -> Void = {},
        onSell: @escaping () -> Void = {}
    ) {
        self.status = status
        self.onUnlock = onUnlock
        self.onBuy = onBuy
        self.onSell = onSell
    }

    var body: some View {
        glassWrappedActions
            .padding(.horizontal, StockOrderTradeActionBarLayout.horizontalPadding)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("stockOrder.tradeActionBar")
    }

    @ViewBuilder
    private var glassWrappedActions: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: StockOrderTradeActionBarLayout.buttonSpacing) {
                actionButtons
                    .padding(StockOrderTradeActionBarLayout.glassInset)
                    .frame(height: StockOrderTradeActionBarLayout.containerHeight)
                    .glassEffect(.regular, in: .capsule)
            }
        } else {
            actionButtons
                .padding(StockOrderTradeActionBarLayout.glassInset)
                .frame(height: StockOrderTradeActionBarLayout.containerHeight)
                .background(.ultraThinMaterial, in: Capsule())
                .shadow(
                    color: Color.black.opacity(0.12),
                    radius: StockOrderTradeActionBarLayout.fallbackShadowRadius,
                    y: StockOrderTradeActionBarLayout.fallbackShadowYOffset
                )
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch status {
        case .locked:
            tradeButton(
                title: language.text(.unlockTrading),
                color: Color("color-brand-blue"),
                action: onUnlock,
                identifier: "unlock"
            )
        case .unlocked:
            HStack(spacing: StockOrderTradeActionBarLayout.buttonSpacing) {
                tradeButton(
                    title: language.text(.buy),
                    color: Color("color-utility3-red"),
                    action: onBuy,
                    identifier: "buy"
                )

                tradeButton(
                    title: language.text(.sell),
                    color: Color("color-utility3-green"),
                    action: onSell,
                    identifier: "sell"
                )
            }
        }
    }

    private func tradeButton(
        title: String,
        color: Color,
        action: @escaping () -> Void,
        identifier: String
    ) -> some View {
        Button(action: action) {
            Text(title)
                .modifier(CustomFontModifier(size: 16, font: .bold, lineHeight: 16))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: StockOrderTradeActionBarLayout.buttonHeight)
                .background(color, in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityIdentifier("stockOrder.tradeActionBar.\(identifier)")
    }
}

private enum StockOrderTradeActionBarLayout {
    static let horizontalPadding: CGFloat = 16
    static let containerHeight: CGFloat = 60
    static let buttonHeight: CGFloat = 44
    static let glassInset: CGFloat = 8
    static let buttonSpacing: CGFloat = 12
    static let fallbackShadowRadius: CGFloat = 20
    static let fallbackShadowYOffset: CGFloat = 4
}

private struct StockOrderTradeActionBarPreviewHarness: View {
    @State private var latestAction = ""
    @State private var status: StockOrderTradeActionBarStatus = .unlocked

    var body: some View {
        VStack(spacing: 24) {
            StockOrderTradeActionBar(
                status: status,
                onUnlock: { latestAction = "unlock" },
                onBuy: { latestAction = "buy" },
                onSell: { latestAction = "sell" }
            )

            Button("Toggle") {
                status = status == .unlocked ? .locked : .unlocked
            }

            Text(latestAction)
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color("color-base-1"))
    }
}

struct StockOrderTradeActionBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderTradeActionBarPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Simplified Chinese · Unlocked")

            StockOrderTradeActionBar(status: .unlocked)
                .environment(\.demoLanguage, .english)
                .preferredColorScheme(.dark)
                .previewDisplayName("English · Unlocked")
        }
        .previewLayout(.fixed(width: 402, height: 140))
    }
}
