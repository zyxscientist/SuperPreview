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
    
    @State var index = 0
    
    var body: some View {
        
        HStack(spacing: 0.0){
            VStack(alignment: .center, spacing: 5.0)  {
                Text("对比")
                    .font(.system(size: 16))
                    .foregroundColor(self.index == 0 ? Color("color-text-30") : Color("color-text-60"))
                    .fontWeight(self.index == 0 ? .semibold : .regular)
                    .onTapGesture {
                        withAnimation(.none){
                            self.index = 0
                        }
                    }
                
                Capsule()
                    .frame(width:30  ,height: 2)
                    .foregroundColor(Color("color-brand-blue").opacity(self.index == 0 ? 1 : 0))
                
            }
            .fixedSize()
            .padding(.trailing, 20)
            .padding(.leading, 0)
            .padding(.top, 11)
            
            VStack(alignment: .center, spacing: 5.0)  {
                Text("全涨")
                    .font(.system(size: 16))
                    .foregroundColor(self.index == 1 ? Color("color-text-30") : Color("color-text-60"))
                    .fontWeight(self.index == 1 ? .semibold : .regular)
                    .onTapGesture {
                        withAnimation(.none){
                            self.index = 1
                        }
                    }
                
                Capsule()
                    .frame(height: 2)
                    .foregroundColor(Color("color-brand-blue").opacity(self.index == 1 ? 1 : 0))
                
            }
            .fixedSize()
            .padding(.trailing, 20)
            .padding(.leading, 0)
            .padding(.top, 11)
            
            
            VStack(alignment: .center, spacing: 5.0)  {
                Text("全跌")
                    .font(.system(size: 16))
                    .foregroundColor(self.index == 2 ? Color("color-text-30") : Color("color-text-60"))
                    .fontWeight(self.index == 2 ? .semibold : .regular)
                    .onTapGesture {
                        withAnimation(.none){
                            self.index = 2
                        }
                    }
                
                Capsule()
                    .frame(height: 2)
                    .foregroundColor(Color("color-brand-blue").opacity(self.index == 2 ? 1 : 0))
                
            }
            .fixedSize()
            .padding(.trailing, 20)
            .padding(.leading, 0)
            .padding(.top, 11)
            
            
            VStack(alignment: .center, spacing: 5.0)  {
                Text("涨跌")
                    .font(.system(size: 16))
                    .foregroundColor(self.index == 3 ? Color("color-text-30") : Color("color-text-60"))
                    .fontWeight(self.index == 3 ? .semibold : .regular)
                    .onTapGesture {
                        withAnimation(.none){
                            self.index = 3
                        }
                    }
                
                Capsule()
                .frame(height: 2)
                    .foregroundColor(Color("color-brand-blue").opacity(self.index == 3 ? 1 : 0))
                
            }
            .fixedSize()
            .padding(.trailing, 20)
            .padding(.leading, 0)
            .padding(.top, 11)
            
            
            VStack(alignment: .center, spacing: 5.0)  {
                Text("组件库")
                    .font(.system(size: 16))
                    .foregroundColor(self.index == 4 ? Color("color-text-30") : Color("color-text-60"))
                    .fontWeight(self.index == 4 ? .semibold : .regular)
                    .onTapGesture {
                        withAnimation(.none){
                            self.index = 4
                        }
                    }
                
                Capsule()
                    .frame(height: 2)
                    .foregroundColor(Color("color-brand-blue").opacity(self.index == 4 ? 1 : 0))
                
            }
            .fixedSize()
            .padding(.trailing, 20)
            .padding(.leading, 0)
            .padding(.top, 11)
            
            Spacer()
            
            Image("headertab_sort")
                .padding(.top, 4)
        }
        .padding(.leading, 15)
        .padding(.trailing, 11)
        .background(Color("color-base-1"))
        
        .overlay(
            FullWidthSeparatorView()
        )
        
        
        // The under view group by headertab
        
        if #available(iOS 14.0, *) {
            TabView(selection: self.$index){
                CompareTab1View().tag(0)
                CompareTab2View().tag(1)
                CompareTab3View().tag(2)
                CompareTab4View().tag(3)
                CompareTab5View().tag(4)
            }
            .edgesIgnoringSafeArea(.all)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        } else {
            // Fallback on earlier versions
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
