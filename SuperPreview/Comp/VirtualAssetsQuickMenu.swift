//
//  VirtualAssetsQuickMenu.swift
//  SuperPreview
//

import SwiftUI

struct VirtualAssetsQuickMenu: View {
    let onTrade: () -> Void
    let onTodayOrders: () -> Void
    let onInternalTransfer: () -> Void
    let onFundRecords: () -> Void
    let onMore: () -> Void

    init(
        onTrade: @escaping () -> Void = {},
        onTodayOrders: @escaping () -> Void = {},
        onInternalTransfer: @escaping () -> Void = {},
        onFundRecords: @escaping () -> Void = {},
        onMore: @escaping () -> Void = {}
    ) {
        self.onTrade = onTrade
        self.onTodayOrders = onTodayOrders
        self.onInternalTransfer = onInternalTransfer
        self.onFundRecords = onFundRecords
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
                    title: "资金内转",
                    imageName: "internal_transfer",
                    action: onInternalTransfer
                ),
                AssetQuickMenuItem(
                    title: "资金记录",
                    imageName: "fund_record",
                    action: onFundRecords
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

struct VirtualAssetsQuickMenu_Previews: PreviewProvider {
    static var previews: some View {
        VirtualAssetsQuickMenu()
            .previewLayout(.fixed(width: 402, height: 74))
            .previewDisplayName("Virtual Assets Quick Menu")
    }
}
