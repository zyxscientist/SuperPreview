//
//  MarketQuickMenu.swift
//  SuperPreview
//
//  组件名称：港股快捷菜单
//  简介：展示港股市场常用入口。
//  用于：新市场页的港股分类。
//

import SwiftUI

struct MarketQuickMenu: View {
    @Environment(\.demoLanguage) private var language

    var body: some View {
        AssetQuickMenu(
            items: items,
            itemHeight: 58,
            accessibilityIdentifier: "market.quickMenu"
        )
    }

    private var items: [AssetQuickMenuItem] {
        [
            AssetQuickMenuItem(
                title: language.text(.marketQuickStockScreener),
                imageName: "market_quick_menu_stock_selector",
                action: {}
            ),
            AssetQuickMenuItem(
                title: language.text(.marketQuickETF),
                imageName: "market_quick_menu_etf",
                action: {}
            ),
            AssetQuickMenuItem(
                title: language.text(.marketQuickWarrants),
                imageName: "market_quick_menu_warrant",
                action: {}
            ),
            AssetQuickMenuItem(
                title: language.text(.marketQuickHKADRs),
                imageName: "market_quick_menu_adr",
                action: {}
            ),
            AssetQuickMenuItem(
                title: language.text(.marketQuickMarginableStocks),
                imageName: "market_quick_menu_marginable_stock",
                action: {}
            )
        ]
    }
}

struct MarketQuickMenu_Previews: PreviewProvider {
    static var previews: some View {
        MarketQuickMenu()
            .previewLayout(.fixed(width: 402, height: 58))
            .previewDisplayName("市场快捷菜单")
    }
}
