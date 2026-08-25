//
//  StockOrderQuantityAvailability.swift
//  SuperPreview
//

import SwiftUI

/// A formatted quantity shown in the order form's buy/sell availability tool.
/// `displayValue` is presentation-only while `inputValue` is written to the
/// quantity field when the user taps the corresponding row.
struct StockOrderQuantityAvailabilityValue: Hashable {
    let displayValue: String
    let inputValue: String

    init(displayValue: String, inputValue: String) {
        self.displayValue = displayValue
        self.inputValue = inputValue
    }
}

/// Identifies the availability amount selected by the user.
enum StockOrderQuantityAvailabilitySelection: String, Hashable {
    case cashPurchasable
    case maximumPurchasable
    case positionSellable
}

/// Buy/sell quantity availability shortcuts for the stock-order demo.
///
/// The parent order page calculates the applicable quantities. Pass `nil` for
/// `maximumPurchasable` on non-margin accounts; that row is then not rendered.
struct StockOrderQuantityAvailability: View {
    @Binding var quantity: String

    let cashPurchasable: StockOrderQuantityAvailabilityValue
    let maximumPurchasable: StockOrderQuantityAvailabilityValue?
    let positionSellable: StockOrderQuantityAvailabilityValue
    let onSelect: (StockOrderQuantityAvailabilitySelection) -> Void

    @Environment(\.demoLanguage) private var language

    init(
        quantity: Binding<String>,
        cashPurchasable: StockOrderQuantityAvailabilityValue,
        maximumPurchasable: StockOrderQuantityAvailabilityValue? = nil,
        positionSellable: StockOrderQuantityAvailabilityValue,
        onSelect: @escaping (StockOrderQuantityAvailabilitySelection) -> Void = { _ in }
    ) {
        _quantity = quantity
        self.cashPurchasable = cashPurchasable
        self.maximumPurchasable = maximumPurchasable
        self.positionSellable = positionSellable
        self.onSelect = onSelect
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(
                alignment: .leading,
                spacing: StockOrderQuantityAvailabilityLayout.leftColumnSpacing
            ) {
                quantityButton(
                    title: language.text(.cashPurchasable),
                    value: cashPurchasable,
                    tone: .buy,
                    selection: .cashPurchasable
                )

                if let maximumPurchasable {
                    quantityButton(
                        title: language.text(.maximumPurchasable),
                        value: maximumPurchasable,
                        tone: .buy,
                        selection: .maximumPurchasable
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            quantityButton(
                title: language.text(.positionSellable),
                value: positionSellable,
                tone: .sell,
                selection: .positionSellable,
                contentAlignment: .trailing
            )
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, StockOrderQuantityAvailabilityLayout.horizontalPadding)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.quantityAvailability")
    }

    private func quantityButton(
        title: String,
        value: StockOrderQuantityAvailabilityValue,
        tone: StockOrderQuantityAvailabilityTone,
        selection: StockOrderQuantityAvailabilitySelection,
        contentAlignment: Alignment = .leading
    ) -> some View {
        Button {
            quantity = value.inputValue
            onSelect(selection)
        } label: {
            HStack(spacing: StockOrderQuantityAvailabilityLayout.textSpacing) {
                Text(title + ":")
                    .foregroundColor(Color("color-text-90"))

                Text(value.displayValue)
                    .foregroundColor(tone.color)
            }
            .modifier(
                CustomFontModifier(
                    size: 12,
                    font: .regular,
                    lineHeight: 16
                )
            )
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(
                maxWidth: .infinity,
                minHeight: StockOrderQuantityAvailabilityLayout.rowHeight,
                maxHeight: StockOrderQuantityAvailabilityLayout.rowHeight,
                alignment: contentAlignment
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title): \(value.displayValue)")
        .accessibilityIdentifier("stockOrder.quantityAvailability.\(selection.rawValue)")
    }
}

private enum StockOrderQuantityAvailabilityTone {
    case buy
    case sell

    var color: Color {
        switch self {
        case .buy:
            Color("color-utility3-red")
        case .sell:
            Color("color-utility3-green")
        }
    }
}

private enum StockOrderQuantityAvailabilityLayout {
    static let horizontalPadding: CGFloat = 16
    static let leftColumnSpacing: CGFloat = 8
    static let textSpacing: CGFloat = 4
    static let rowHeight: CGFloat = 16
}

private struct StockOrderQuantityAvailabilityPreviewHarness: View {
    @State private var quantity = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            StockOrderQuantityAvailability(
                quantity: $quantity,
                cashPurchasable: .init(displayValue: "20", inputValue: "20"),
                maximumPurchasable: .init(displayValue: "100", inputValue: "100"),
                positionSellable: .init(displayValue: "0", inputValue: "0")
            )

            StockOrderQuantityAvailability(
                quantity: $quantity,
                cashPurchasable: .init(displayValue: "20", inputValue: "20"),
                positionSellable: .init(displayValue: "0", inputValue: "0")
            )
        }
        .padding(.vertical, 16)
    }
}

struct StockOrderQuantityAvailability_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderQuantityAvailabilityPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Simplified Chinese · Margin and Cash")

            StockOrderQuantityAvailability(
                quantity: .constant(""),
                cashPurchasable: .init(displayValue: "20", inputValue: "20"),
                positionSellable: .init(displayValue: "0", inputValue: "0")
            )
            .environment(\.demoLanguage, .english)
            .preferredColorScheme(.dark)
            .previewDisplayName("English · Cash")
        }
        .previewLayout(.fixed(width: 402, height: 88))
    }
}
