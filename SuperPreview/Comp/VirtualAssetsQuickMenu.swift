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
    @Environment(\.demoLanguage) private var language

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
                    title: language.text(.internalTransfer),
                    imageName: "internal_transfer",
                    accessibilityLabel: language.accessibilityText(.internalTransfer),
                    action: onInternalTransfer
                ),
                AssetQuickMenuItem(
                    title: language.text(.cashHistory),
                    imageName: "fund_record",
                    action: onFundRecords
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

struct VirtualAssetsQuickMenu_Previews: PreviewProvider {
    static var previews: some View {
        VirtualAssetsQuickMenu()
            .previewLayout(.fixed(width: 402, height: 74))
            .previewDisplayName("Virtual Assets Quick Menu")
    }
}
