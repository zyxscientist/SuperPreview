//
//  StockOrderNavbar.swift
//  SuperPreview
//

import SwiftUI

struct StockOrderBuyingPower: Equatable {
    let currencyCode: String
    let formattedAmount: String

    var displayValue: String {
        "\(currencyCode) \(formattedAmount)"
    }
}

struct StockOrderNavbar: View {
    let accountTitle: String
    let buyingPower: StockOrderBuyingPower?
    let onBack: () -> Void
    let onRefresh: () -> Void

    @Environment(\.demoLanguage) private var language

    init(
        accountTitle: String,
        buyingPower: StockOrderBuyingPower? = nil,
        onBack: @escaping () -> Void = {},
        onRefresh: @escaping () -> Void = {}
    ) {
        self.accountTitle = accountTitle
        self.buyingPower = buyingPower
        self.onBack = onBack
        self.onRefresh = onRefresh
    }

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: StockOrderNavbarLayout.leadingTitleSpacing) {
                Button(action: onBack) {
                    Image("back-Left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: StockOrderNavbarLayout.iconSize, height: StockOrderNavbarLayout.iconSize)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: StockOrderNavbarLayout.iconSize, height: StockOrderNavbarLayout.height)
                .contentShape(Rectangle())
                .accessibilityLabel(language.text(.back))
                .accessibilityIdentifier("stockOrder.navbar.back")

                titleContent
            }

            Spacer(minLength: 0)

            Button(action: onRefresh) {
                Image("refresh-Right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: StockOrderNavbarLayout.iconSize, height: StockOrderNavbarLayout.iconSize)
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: StockOrderNavbarLayout.iconSize, height: StockOrderNavbarLayout.height)
            .contentShape(Rectangle())
            .accessibilityLabel(language.text(.refresh))
            .accessibilityIdentifier("stockOrder.navbar.refresh")
        }
        .padding(.horizontal, StockOrderNavbarLayout.horizontalPadding)
        .frame(
            maxWidth: .infinity,
            minHeight: StockOrderNavbarLayout.height,
            maxHeight: StockOrderNavbarLayout.height
        )
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.navbar")
    }

    @ViewBuilder
    private var titleContent: some View {
        Group {
            if let buyingPower {
                titleWithBuyingPower(buyingPower)
            } else {
                Text(accountTitle)
                    .modifier(CustomFontModifier(size: 16, font: .bold, lineHeight: 24))
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(
                        width: StockOrderNavbarLayout.titleWidth,
                        height: StockOrderNavbarLayout.height,
                        alignment: .leading
                    )
            }
        }
        .frame(
            width: StockOrderNavbarLayout.titleWidth,
            height: StockOrderNavbarLayout.height,
            alignment: .leading
        )
        .transaction { transaction in
            transaction.animation = nil
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.navbar.title")
    }

    private func titleWithBuyingPower(_ buyingPower: StockOrderBuyingPower) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(accountTitle)
                .modifier(CustomFontModifier(size: 14, font: .bold, lineHeight: 20))
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(
                    width: StockOrderNavbarLayout.titleWidth,
                    height: StockOrderNavbarLayout.rowHeight,
                    alignment: .leading
                )

            HStack(spacing: 2) {
                Text("\(language.text(.maximumBuyingPower)):")
                Text(buyingPower.displayValue)
            }
            .modifier(CustomFontModifier(size: 14, font: .medium, lineHeight: 20))
            .foregroundColor(Color("color-text-30"))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .frame(
                width: StockOrderNavbarLayout.titleWidth,
                height: StockOrderNavbarLayout.rowHeight,
                alignment: .leading
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(
                "\(language.accessibilityText(.maximumBuyingPower)): \(buyingPower.displayValue)"
            )
            .accessibilityIdentifier("stockOrder.navbar.buyingPower")
        }
        .frame(
            width: StockOrderNavbarLayout.titleWidth,
            height: StockOrderNavbarLayout.height,
            alignment: .leading
        )
    }

}

private enum StockOrderNavbarLayout {
    static let horizontalPadding: CGFloat = 16
    static let leadingTitleSpacing: CGFloat = 2
    static let iconSize: CGFloat = 24
    static let titleWidth: CGFloat = 240
    static let rowHeight: CGFloat = 20
    static let height: CGFloat = 40
}

private struct StockOrderNavbarPreviewHarness: View {
    @Environment(\.demoLanguage) private var language
    @State private var buyingPower: StockOrderBuyingPower?

    var body: some View {
        VStack(spacing: 16) {
            StockOrderNavbar(
                accountTitle: accountTitle,
                buyingPower: buyingPower
            )

            Button {
                buyingPower = buyingPower == nil
                    ? StockOrderBuyingPower(
                        currencyCode: "HKD",
                        formattedAmount: "200,000.00"
                    )
                    : nil
            } label: {
                Text(buyingPower == nil ? "选择港股标的" : "清空标的")
                    .modifier(CustomFontModifier(size: 14, font: .medium, lineHeight: 20))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(Color("color-base-1"))
    }

    private var accountTitle: String {
        "\(language.text(.securitiesMarginAccount))(0909)"
    }
}

struct StockOrderNavbar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Group {
                StockOrderNavbar(
                    accountTitle: "证券融资账户(0909)"
                )
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Light · Empty")

                StockOrderNavbar(
                    accountTitle: "证券融资账户(0909)",
                    buyingPower: StockOrderBuyingPower(
                        currencyCode: "HKD",
                        formattedAmount: "200,000.00"
                    )
                )
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Light · HKD")

                StockOrderNavbar(
                    accountTitle: "證券融資帳戶(0909)",
                    buyingPower: StockOrderBuyingPower(
                        currencyCode: "HKD",
                        formattedAmount: "200,000.00"
                    )
                )
                .environment(\.demoLanguage, .traditionalChinese)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark · Traditional Chinese · HKD")

                StockOrderNavbar(
                    accountTitle: "Securities Margin Account(0909)",
                    buyingPower: StockOrderBuyingPower(
                        currencyCode: "USD",
                        formattedAmount: "11,000.00"
                    )
                )
                .environment(\.demoLanguage, .english)
                .previewDisplayName("Light · English · USD")
            }
            .previewLayout(.fixed(width: 402, height: 40))

            StockOrderNavbarPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewLayout(.fixed(width: 402, height: 120))
                .previewDisplayName("Interactive State Transition")
        }
    }
}
