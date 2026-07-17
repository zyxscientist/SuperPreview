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
                    title: "交易",
                    imageName: "stock_trade_outline",
                    action: onTrade
                ),
                AssetQuickMenuItem(
                    title: "今日订单",
                    imageName: "today_order_outline",
                    action: onTodayOrders
                ),
                AssetQuickMenuItem(
                    title: "新股中心",
                    imageName: "ipo_outline",
                    action: onIPOCenter
                ),
                AssetQuickMenuItem(
                    title: "入金",
                    imageName: "deposit_outline",
                    action: onDeposit
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

struct StockAssetQuickMenu_Previews: PreviewProvider {
    static var previews: some View {
        StockAssetQuickMenu()
            .previewLayout(.fixed(width: 402, height: 74))
            .previewDisplayName("Stock Asset Quick Menu")
    }
}
