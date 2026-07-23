//
//  CompareView.swift
//  SuperPreview
//
//  Created by PeterZ on 2022/06/09.
//  Copyright © 2022 PeterZ. All rights reserved.
//

import SwiftUI


struct CompareView: View {
    var body: some View {
        VStack(spacing: 0.0) {
            CompareHeaderTabsView()
        }
    }
}

struct CompareViewPreviews: PreviewProvider {
static var previews: some View {
        ZStack {
            Color("color-base-0")
                .edgesIgnoringSafeArea(.all)
            CompareView()
        }
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
                        Text("新自选")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("Watchlist Redesign")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            // 结束

            NavigationLink(
                destination: TradeAggregationDemoView(),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text("新交易")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("Trade Aggregation")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
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
            
            // 结束
            
        }
        .frame(width: 390) // 整个背景的宽度
        .background(Color("color-base-0"))
    }
}

struct WatchlistRedesignPreviewView: View {
    var body: some View {
        WatchlistRedesignDemoView()
    }
}
