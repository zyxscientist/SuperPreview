//
//  StockOrderAmountField.swift
//  SuperPreview
//

import Foundation
import SwiftUI

/// The calculated transaction amount shown below the quantity field.
///
/// The order page owns the price and quantity input states. This display-only
/// component derives their total for price-based orders and deliberately keeps
/// the amount indeterminate for market orders.
struct StockOrderAmountField: View {
    let price: String
    let quantity: String
    let currencyCode: String
    let orderType: StockOrderOrderType
    let fractionDigits: Int
    let usesMargin: Bool

    @Environment(\.demoLanguage) private var language

    init(
        price: String,
        quantity: String,
        currencyCode: String,
        orderType: StockOrderOrderType,
        fractionDigits: Int = 2,
        usesMargin: Bool = false
    ) {
        self.price = price
        self.quantity = quantity
        self.currencyCode = currencyCode
        self.orderType = orderType
        self.fractionDigits = fractionDigits
        self.usesMargin = usesMargin
    }

    var body: some View {
        HStack(spacing: 0) {
            amountLabel
            amountValue
        }
        .padding(.horizontal, StockOrderAmountFieldLayout.horizontalPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: StockOrderAmountFieldLayout.fieldHeight,
            maxHeight: StockOrderAmountFieldLayout.fieldHeight,
            alignment: .leading
        )
        .background(Color("color-base-1"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(language.text(.amount))
        .accessibilityValue(displayAmount)
        .accessibilityIdentifier("stockOrder.amountField")
    }

    private var amountLabel: some View {
        Text(language.text(.amount))
            .modifier(
                CustomFontModifier(
                    size: 16,
                    font: .regular,
                    lineHeight: 24
                )
            )
            .foregroundColor(Color("color-text-30"))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(
                width: StockOrderAmountFieldLayout.labelWidth,
                height: StockOrderAmountFieldLayout.fieldHeight,
                alignment: .leading
            )
            .accessibilityIdentifier("stockOrder.amountField.label")
    }

    private var amountValue: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(displayAmount)
                .modifier(
                    CustomFontModifier(
                        size: 16,
                        font: .medium,
                        lineHeight: 24
                    )
                )
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            if usesMargin {
                Text(language.text(.buyingUsesMargin))
                    .modifier(
                        CustomFontModifier(
                            size: 12,
                            font: .regular,
                            lineHeight: 16
                        )
                    )
                    .foregroundColor(Color("color-utility3-warning"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityIdentifier("stockOrder.amountField.marginReminder")
            }
        }
        .frame(
            width: StockOrderAmountFieldLayout.valueWidth,
            alignment: .leading
        )
        .accessibilityIdentifier("stockOrder.amountField.value")
    }

    private var displayAmount: String {
        guard orderType != .market else {
            return language.text(.atMarketPrice)
        }

        guard let totalAmount, let formattedAmount = format(totalAmount) else {
            return "--"
        }

        let trimmedCurrencyCode = currencyCode.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedCurrencyCode.isEmpty else {
            return formattedAmount
        }

        return "\(trimmedCurrencyCode) \(formattedAmount)"
    }

    private var totalAmount: Decimal? {
        guard
            let parsedPrice = Self.decimal(from: price),
            let parsedQuantity = Self.decimal(from: quantity)
        else {
            return nil
        }

        return parsedPrice * parsedQuantity
    }

    private func format(_ amount: Decimal) -> String? {
        let formatter = NumberFormatter()
        formatter.locale = StockOrderAmountFieldLayout.numberLocale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        formatter.minimumFractionDigits = normalizedFractionDigits
        formatter.maximumFractionDigits = normalizedFractionDigits

        return formatter.string(from: NSDecimalNumber(decimal: amount))
    }

    private var normalizedFractionDigits: Int {
        min(max(fractionDigits, 0), StockOrderAmountFieldLayout.maximumFractionDigits)
    }

    private static func decimal(from value: String) -> Decimal? {
        let normalizedValue = value
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Decimal(
            string: normalizedValue,
            locale: StockOrderAmountFieldLayout.numberLocale
        )
    }
}

private enum StockOrderAmountFieldLayout {
    static let numberLocale = Locale(identifier: "en_US_POSIX")
    static let maximumFractionDigits = 8
    static let horizontalPadding: CGFloat = 16
    static let labelWidth: CGFloat = 112
    static let valueWidth: CGFloat = 258
    static let fieldHeight: CGFloat = 44
}

struct StockOrderAmountField_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderAmountField(
                price: "233.61",
                quantity: "100",
                currencyCode: "USD",
                orderType: .limit
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewDisplayName("Simplified Chinese · Calculated")

            StockOrderAmountField(
                price: "233.61",
                quantity: "100",
                currencyCode: "USD",
                orderType: .market
            )
            .environment(\.demoLanguage, .traditionalChinese)
            .previewDisplayName("Traditional Chinese · Market")

            StockOrderAmountField(
                price: "233.61",
                quantity: "100",
                currencyCode: "USD",
                orderType: .limit,
                usesMargin: true
            )
            .environment(\.demoLanguage, .english)
            .preferredColorScheme(.dark)
            .previewDisplayName("English · Margin")
        }
        .previewLayout(.fixed(width: 402, height: 44))
    }
}
