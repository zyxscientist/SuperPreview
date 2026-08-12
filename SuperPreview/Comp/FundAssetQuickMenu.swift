//
//  FundAssetQuickMenu.swift
//  SuperPreview
//

import SwiftUI

struct FundAssetQuickMenu: View {
    let onDeposit: () -> Void
    let onTransactionRecords: () -> Void
    let onRecurringInvestment: () -> Void
    let onStatement: () -> Void
    let onMore: () -> Void
    @Environment(\.demoLanguage) private var language

    init(
        onDeposit: @escaping () -> Void = {},
        onTransactionRecords: @escaping () -> Void = {},
        onRecurringInvestment: @escaping () -> Void = {},
        onStatement: @escaping () -> Void = {},
        onMore: @escaping () -> Void = {}
    ) {
        self.onDeposit = onDeposit
        self.onTransactionRecords = onTransactionRecords
        self.onRecurringInvestment = onRecurringInvestment
        self.onStatement = onStatement
        self.onMore = onMore
    }

    var body: some View {
        AssetQuickMenu(
            items: [
                AssetQuickMenuItem(
                    title: language.text(.deposit),
                    imageName: "deposit_outline",
                    action: onDeposit
                ),
                AssetQuickMenuItem(
                    title: language.text(.transactionHistory),
                    imageName: "his_order_outline",
                    accessibilityLabel: language.accessibilityText(.transactionHistory),
                    action: onTransactionRecords
                ),
                AssetQuickMenuItem(
                    title: language.text(.recurringInvestment),
                    imageName: "my_AIP_outline",
                    accessibilityLabel: language.accessibilityText(.recurringInvestment),
                    action: onRecurringInvestment
                ),
                AssetQuickMenuItem(
                    title: language.text(.statements),
                    imageName: "statement_outline",
                    action: onStatement
                ),
                AssetQuickMenuItem(
                    title: language.text(.more),
                    imageName: "more_outline",
                    action: onMore
                )
            ]
        )
    }
}

struct FundAssetQuickMenu_Previews: PreviewProvider {
    static var previews: some View {
        FundAssetQuickMenu()
            .previewLayout(.fixed(width: 402, height: 74))
            .previewDisplayName("Fund Asset Quick Menu")
    }
}
