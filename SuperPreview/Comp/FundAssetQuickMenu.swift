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
                    title: "入金",
                    imageName: "deposit_outline",
                    action: onDeposit
                ),
                AssetQuickMenuItem(
                    title: "交易记录",
                    imageName: "his_order_outline",
                    action: onTransactionRecords
                ),
                AssetQuickMenuItem(
                    title: "我的定投",
                    imageName: "my_AIP_outline",
                    action: onRecurringInvestment
                ),
                AssetQuickMenuItem(
                    title: "结单",
                    imageName: "statement_outline",
                    action: onStatement
                ),
                AssetQuickMenuItem(
                    title: "更多",
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
