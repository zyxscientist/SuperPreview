//
//  StockOrderPriceTargetMenu.swift
//  SuperPreview
//

import SwiftUI

/// The source used to derive a stock-order price.
///
/// The parent page owns quote availability and updates the bound `price` when
/// a live target is selected. This type only describes the selected source.
enum StockOrderPriceTarget: String, CaseIterable, Hashable, Identifiable {
    case specifiedPrice
    case marketPrice
    case bidOne
    case askOne

    var id: String { rawValue }

    var isSpecifiedPrice: Bool {
        self == .specifiedPrice
    }

    var menuTitleKey: DemoCopyKey {
        switch self {
        case .specifiedPrice:
            .specifiedPrice
        case .marketPrice:
            .followMarketPrice
        case .bidOne:
            .followBidOne
        case .askOne:
            .followAskOne
        }
    }

    var priceLabelKey: DemoCopyKey {
        isSpecifiedPrice ? .price : menuTitleKey
    }

}

/// Standard target groups for the quote permissions represented in the Figma
/// specification. The eventual order page can provide a symbol-specific set.
enum StockOrderPriceTargetOptions {
    static let basicQuote: [StockOrderPriceTarget] = [
        .specifiedPrice,
        .marketPrice
    ]

    static let advancedQuote: [StockOrderPriceTarget] = [
        .specifiedPrice,
        .marketPrice,
        .bidOne,
        .askOne
    ]
}

struct StockOrderPriceTargetMenu: View {
    @Binding var selection: StockOrderPriceTarget

    let supportedTargets: [StockOrderPriceTarget]
    let onSelection: (StockOrderPriceTarget) -> Void

    @Environment(\.demoLanguage) private var language

    init(
        selection: Binding<StockOrderPriceTarget>,
        supportedTargets: [StockOrderPriceTarget],
        onSelection: @escaping (StockOrderPriceTarget) -> Void = { _ in }
    ) {
        _selection = selection
        self.supportedTargets = supportedTargets
        self.onSelection = onSelection
    }

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: StockOrderPriceTargetMenuLayout.pointerReserveHeight)
                .accessibilityHidden(true)

            menuCard
        }
        .frame(width: StockOrderPriceTargetMenuLayout.menuWidth)
        .overlay(alignment: .topTrailing) {
            Image("stock_order_price_target_menu_pointer")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Color("color-base-1"))
                .scaledToFit()
                .frame(
                    width: StockOrderPriceTargetMenuLayout.pointerWidth,
                    height: StockOrderPriceTargetMenuLayout.pointerHeight
                )
                .padding(
                    .trailing,
                    StockOrderPriceTargetMenuLayout.pointerTrailingInset
                )
                .accessibilityHidden(true)
        }
        .shadow(
            color: .black.opacity(StockOrderPriceTargetMenuLayout.shadowOpacity),
            radius: StockOrderPriceTargetMenuLayout.shadowRadius,
            x: 0,
            y: StockOrderPriceTargetMenuLayout.shadowYOffset
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(language.text(.priceTracking))
        .accessibilityIdentifier("stockOrder.priceInput.targetMenu")
    }

    private var menuCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(supportedTargets.enumerated()), id: \.element.id) {
                index,
                target in
                targetRow(target)
                    .overlay(alignment: .bottom) {
                        if index < supportedTargets.count - 1 {
                            Rectangle()
                                .fill(Color("color-separator-10"))
                                .frame(
                                    height: StockOrderPriceTargetMenuLayout.separatorHeight
                                )
                                .accessibilityHidden(true)
                        }
                    }
            }
        }
        .background(Color("color-base-1"))
        .clipShape(
            RoundedRectangle(
                cornerRadius: StockOrderPriceTargetMenuLayout.cornerRadius,
                style: .continuous
            )
        )
    }

    private func targetRow(_ target: StockOrderPriceTarget) -> some View {
        Button {
            selection = target
            onSelection(target)
        } label: {
            Text(language.text(target.menuTitleKey))
                .modifier(
                    CustomFontModifier(
                        size: 14,
                        font: .regular,
                        lineHeight: 20
                    )
                )
                .foregroundColor(
                    target == selection
                        ? Color("color-brand-blue")
                        : Color("color-text-30")
                )
                .lineLimit(1)
                .minimumScaleFactor(0.62)
                .frame(
                    maxWidth: .infinity,
                    minHeight: StockOrderPriceTargetMenuLayout.rowHeight,
                    maxHeight: StockOrderPriceTargetMenuLayout.rowHeight
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(language.text(target.menuTitleKey))
        .accessibilityIdentifier(
            "stockOrder.priceInput.targetMenu.option.\(target.rawValue)"
        )
    }
}

private enum StockOrderPriceTargetMenuLayout {
    static let menuWidth: CGFloat = 88
    static let rowHeight: CGFloat = 40
    static let separatorHeight: CGFloat = 0.5
    static let cornerRadius: CGFloat = 4
    static let pointerReserveHeight: CGFloat = 4
    static let pointerWidth: CGFloat = 9
    static let pointerHeight: CGFloat = 3.324
    static let pointerTrailingInset: CGFloat = 10
    static let shadowOpacity: CGFloat = 0.08
    static let shadowRadius: CGFloat = 5
    static let shadowYOffset: CGFloat = 4
}

private struct StockOrderPriceTargetMenuPreviewHarness: View {
    @State private var selection: StockOrderPriceTarget = .specifiedPrice

    var body: some View {
        StockOrderPriceTargetMenu(
            selection: $selection,
            supportedTargets: StockOrderPriceTargetOptions.advancedQuote
        )
        .padding(24)
        .background(Color("color-base-0"))
    }
}

struct StockOrderPriceTargetMenu_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderPriceTargetMenuPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Advanced Quote · Simplified Chinese")

            StockOrderPriceTargetMenu(
                selection: .constant(.marketPrice),
                supportedTargets: StockOrderPriceTargetOptions.basicQuote
            )
            .padding(24)
            .background(Color("color-base-0"))
            .environment(\.demoLanguage, .english)
            .preferredColorScheme(.dark)
            .previewDisplayName("Basic Quote · English · Dark")
        }
        .previewLayout(.sizeThatFits)
    }
}
