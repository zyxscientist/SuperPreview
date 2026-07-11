//
//  WatchlistView.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/10/18.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct WatchlistView: View {
    var body: some View {
        VStack(spacing: 0.0) {
            WatchlistHeaderTabsView()
        }
    }
}

struct WatchlistViewPreviews: PreviewProvider {
static var previews: some View {
        ZStack {
            Color("color-base-0")
                .edgesIgnoringSafeArea(.all)
            WatchlistView()
        }
        .preferredColorScheme(.dark)
    }
}



struct WatchlistHeaderTabsView: View {
    
    @State var index = 0
    
    var body: some View {
        
        HStack(spacing: 0.0){
            VStack(alignment: .center, spacing: 5.0)  {
                Text("持仓")
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
                Text("美股")
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
                Text("港股")
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
                Text("沪深")
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
                Text("新能源🚗")
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
                Tab_1().tag(0)
                Tab_2().tag(1)
                Tab_3().tag(2)
                Text("🇨🇳").tag(3)
                Text("🚗").tag(4)
            }
            .edgesIgnoringSafeArea(.all)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        } else {
            // Fallback on earlier versions
        }
    }
}


struct Tab_1: View {
    var body: some View {

            ScrollView{
                VStack(spacing: 0.0){
                    WatchlistTableHeaderView(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                    VStack(spacing: 0.0) {
                        ForEach(watchlistStocks) { stock in
                            WatchlistItemView(stock: stock)
                        }
                    }
                }.background(Color("color-base-0"))
            }
        }
    }


struct Tab_2: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0.0){
                WatchlistTableHeaderView(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                VStack(spacing: 0.0) {
                    ForEach(watchlistStocks) { stock in
                        WatchlistItemView(stock: stock)
                    }
                }
            }.background(Color("color-base-0"))
        }
    }
}


struct Tab_3: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0.0){
                WatchlistTableHeaderView(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                VStack(spacing: 0.0) {
                    ForEach(watchlistStocks) { stock in
                        WatchlistItemView(stock: stock)
                    }
                }
            }.background(Color("color-base-0"))
        }
    }
}
