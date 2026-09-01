//
//  CompareView.swift
//  SuperPreview
//
//  Created by PeterZ on 2022/06/09.
//  Copyright © 2022 PeterZ. All rights reserved.
//

import SwiftUI


struct CompareView: View {
    @EnvironmentObject private var demoLanguageStore: DemoLanguageStore

    var body: some View {
        VStack(spacing: 0.0) {
            CompareHeaderTabsView()
        }
        .environment(\.demoLanguage, demoLanguageStore.language)
    }
}

struct CompareViewPreviews: PreviewProvider {
static var previews: some View {
        ZStack {
            Color("color-base-0")
                .edgesIgnoringSafeArea(.all)
            CompareView()
        }
        .environmentObject(DemoLanguageStore(initialLanguage: .simplifiedChinese))
        .preferredColorScheme(.dark)
    }
}


// 顶部Tabber·HeaderTab组件

struct CompareHeaderTabsView: View {
    private let tabTitles = ["组件库", "对比", "全涨", "全跌", "涨跌"]

    @State private var index = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(tabTitles.indices, id: \.self) { tabIndex in
                    Button {
                        index = tabIndex
                    } label: {
                        VStack(spacing: 5) {
                            Text(tabTitles[tabIndex])
                                .font(.system(size: 16))
                                .foregroundColor(index == tabIndex ? Color("color-text-30") : Color("color-text-60"))
                                .fontWeight(index == tabIndex ? .semibold : .regular)

                            Capsule()
                                .fill(Color("color-brand-blue"))
                                .frame(width: 30, height: 2)
                                .opacity(index == tabIndex ? 1 : 0)
                        }
                    }
                    .buttonStyle(.plain)
                    .fixedSize()
                    .padding(.trailing, 20)
                    .padding(.top, 11)
                }

                Spacer()

                Image("headertab_sort")
                    .padding(.top, 4)
            }
            .padding(.leading, 15)
            .padding(.trailing, 11)
            .background(Color("color-base-1"))
            .overlay(FullWidthSeparatorView())

            // Keep the selected vertical scroller directly under the app's TabView,
            // matching the News tab so iOS can apply its native scroll-edge effect.
            selectedTabContent
                .id(index)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch index {
        case 0:
            CompareTab5View()
        case 1:
            CompareTab1View()
        case 2:
            CompareTab2View()
        case 3:
            CompareTab3View()
        default:
            CompareTab4View()
        }
    }
}


struct CompareTab1View: View {
    var body: some View {

            ScrollView{
                VStack(spacing: 0.0){
                    WatchlistTableHeaderView(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                    VStack(spacing: 0.0) {
                        ForEach(comparisonStocks) { stock in
                            WatchlistItemView(stock: stock)
                        }
                    }
                }.background(Color("color-base-0"))
            }
        }
    }


struct CompareTab2View: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0.0){
                WatchlistTableHeaderView(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                VStack(spacing: 0.0) {
                    ForEach(watchlistStocksVariant2) { stock in
                        WatchlistItemView(stock: stock)
                    }
                }
            }.background(Color("color-base-0"))
        }
    }
}


struct CompareTab3View: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0.0){
                WatchlistTableHeaderView(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                VStack(spacing: 0.0) {
                    ForEach(watchlistStocksVariant4) { stock in
                        WatchlistItemView(stock: stock)
                    }
                }
            }.background(Color("color-base-0"))
        }
    }
}


struct CompareTab4View: View {
    var body: some View{
        ScrollView{
            VStack(spacing: 0.0){
                WatchlistTableHeaderView(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                VStack(spacing: 0.0) {
                    ForEach(watchlistStocksVariant5) { stock in
                        WatchlistItemView(stock: stock)
                    }
                }
            }.background(Color("color-base-0"))
        }
    }
}

struct CompareTab5View: View {
    @Environment(\.demoLanguage) private var demoLanguage

    var body: some View{
        
        List{
            // 组件列表单元
            NavigationLink(
                    destination: IntradayCardsView(),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text("分时走势卡片")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("IntradayCardsView")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            // 结束
            
            NavigationLink(
                    destination: OrderBookTapeView(),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text("买卖盘组件")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("Tape")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            // 结束
            
            NavigationLink(
                    destination: TransactionDetailsView(),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text("成交明细")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("TransactionDetails")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            // 结束
            
            NavigationLink(
                destination: StockPriceStatView(stockStats: stockStats),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text("报价区")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("StockPriceStat")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            // 结束
            
            NavigationLink(
                destination: StockShuffleDemoView(),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text("个股快切（交互原型）")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("WatchlistStock Shuffle(UX Demo)")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            // 结束

            NavigationLink(
                destination: WatchlistRedesignPreviewView(),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text(demoLanguage.text(.newWatchlist))
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("Watchlist Redesign")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            .accessibilityIdentifier("compare.newWatchlist")
            // 结束

            NavigationLink(
                destination: TradeAggregationDemoView(),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text(demoLanguage.text(.newTrade))
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("Trade Aggregation")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            .accessibilityIdentifier("compare.newTrade")
            // 结束

            NavigationLink(
                destination: StockOrderDemoView(),
                label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(demoLanguage.text(.stockOrderPage))
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("Stock Order (UX Demo)")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            .accessibilityIdentifier("compare.stockOrder")
            // 结束

            NavigationLink(
                destination: StockDetailUSCommonStockPage(),
                label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(stockDetailUSCommonStockTitle)
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("Stock Detail · US Common Stock")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            .accessibilityIdentifier("compare.stockDetailUSCommonStock")
            // 结束
            
            NavigationLink(
                destination: MacroDataCenterView(),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text("数据中心")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("Macro Data Center")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            // 结束
            
            NavigationLink(
                destination: InAppNotificationView(),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text("站内通知")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("In-App Notification")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            
            // 结束
            
            // 结束
            
            NavigationLink(
                destination: PriceRefreshAnimationView(),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text("价格刷新")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("Price Refresh Animation")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )

            NavigationLink(
                destination: TapticEngineDemoView(),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Taptic Engine 触感实验室")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("UIKit Feedback + Core Haptics")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )

            NavigationLink(
                destination: JakartaMonospacedComparisonView(),
                label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Jakarta 数字等宽对比")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("Plus Jakarta Sans · monospacedDigit()")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )

            NavigationLink(
                destination: LiquidGlassResearchView(),
                label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Liquid Glass 调研")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("买卖按钮 · 涨跌色 tint")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            
            // 结束
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("compare.componentLibrary")
        .background(Color("color-base-0"))
    }

    private var stockDetailUSCommonStockTitle: String {
        switch demoLanguage {
        case .simplifiedChinese:
            "美股正股详情页"
        case .traditionalChinese:
            "美股正股詳情頁"
        case .english:
            "US Common Stock Detail"
        }
    }
}

struct WatchlistRedesignPreviewView: View {
    var body: some View {
        WatchlistRedesignDemoView()
    }
}
