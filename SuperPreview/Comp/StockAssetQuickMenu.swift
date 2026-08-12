//
//  StockAssetQuickMenu.swift
//  SuperPreview
//

import SwiftUI

struct StockAssetQuickMenu: View {
    let onTrade: () -> Void
    let onTodayOrders: () -> Void
    let onIPOCenter: () -> Void
    let onDeposit: () -> Void
    let onMore: () -> Void
    @Environment(\.demoLanguage) private var language

    init(
        onTrade: @escaping () -> Void = {},
        onTodayOrders: @escaping () -> Void = {},
        onIPOCenter: @escaping () -> Void = {},
        onDeposit: @escaping () -> Void = {},
        onMore: @escaping () -> Void = {}
    ) {
        self.onTrade = onTrade
        self.onTodayOrders = onTodayOrders
        self.onIPOCenter = onIPOCenter
        self.onDeposit = onDeposit
        self.onMore = onMore
    }

    var body: some View {
        AssetQuickMenu(
            items: [
                AssetQuickMenuItem(
                    title: language.text(.trade),
                    imageName: "stock_trade_outline",
                    action: onTrade
                ),
                AssetQuickMenuItem(
                    title: language.text(.todayOrders),
                    imageName: "today_order_outline",
                    accessibilityLabel: language.accessibilityText(.todayOrders),
                    action: onTodayOrders
                ),
                AssetQuickMenuItem(
                    title: language.text(.ipoCenter),
                    imageName: "ipo_outline",
                    action: onIPOCenter
                ),
                AssetQuickMenuItem(
                    title: language.text(.deposit),
                    imageName: "deposit_outline",
                    action: onDeposit
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

struct StockAssetQuickMenu_Previews: PreviewProvider {
    static var previews: some View {
        StockAssetQuickMenu()
            .previewLayout(.fixed(width: 402, height: 74))
            .previewDisplayName("Stock Asset Quick Menu")
    }
}
