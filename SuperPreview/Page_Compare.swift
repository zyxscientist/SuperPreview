//
//  Page_Compare.swift
//  SuperPreview
//
//  Created by PeterZ on 2022/06/09.
//  Copyright © 2022 PeterZ. All rights reserved.
//

import SwiftUI


struct Page_Compare: View {
    var body: some View {
        VStack(spacing: 0.0) {
            Page_Compare_HeaderTabView()
        }
    }
}

struct Page_Compare_Previews: PreviewProvider {
static var previews: some View {
        ZStack {
            Color("color-base-0")
                .edgesIgnoringSafeArea(.all)
            Page_Compare()
        }
        .preferredColorScheme(.dark)
    }
}


// 顶部Tabber·HeaderTab组件

struct Page_Compare_HeaderTabView: View {
    
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
            Comp_Separator_Full()
        )
        
        
        // The under view group by headertab
        
        if #available(iOS 14.0, *) {
            TabView(selection: self.$index){
                Tab_Compare_1().tag(0)
                Tab_Compare_2().tag(1)
                Tab_Compare_3().tag(2)
                Tab_Compare_4().tag(3)
                Tab_Compare_5().tag(4)
            }
            .edgesIgnoringSafeArea(.all)
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        } else {
            // Fallback on earlier versions
        }
    }
}


struct Tab_Compare_1: View {
    var body: some View {

            ScrollView{
                VStack(spacing: 0.0){
                    Comp_TableHeader_Watchlist(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                    VStack(spacing: 0.0) {
                        ForEach(stocks_compare) { stock in
                            Comp_Watchlist_Item(stock: stock)
                        }
                    }
                }.background(Color("color-base-0"))
            }
        }
    }


struct Tab_Compare_2: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0.0){
                Comp_TableHeader_Watchlist(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                VStack(spacing: 0.0) {
                    ForEach(stocks_2) { stock in
                        Comp_Watchlist_Item(stock: stock)
                    }
                }
            }.background(Color("color-base-0"))
        }
    }
}


struct Tab_Compare_3: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0.0){
                Comp_TableHeader_Watchlist(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                VStack(spacing: 0.0) {
                    ForEach(stocks_4) { stock in
                        Comp_Watchlist_Item(stock: stock)
                    }
                }
            }.background(Color("color-base-0"))
        }
    }
}


struct Tab_Compare_4: View {
    var body: some View{
        ScrollView{
            VStack(spacing: 0.0){
                Comp_TableHeader_Watchlist(key_col: "名称", first_col: "现价", second_col: "涨跌幅")
                VStack(spacing: 0.0) {
                    ForEach(stocks_5) { stock in
                        Comp_Watchlist_Item(stock: stock)
                    }
                }
            }.background(Color("color-base-0"))
        }
    }
}

struct Tab_Compare_5: View {
    var body: some View{
        List{
            
            // 组件列表单元
            NavigationLink(
                    destination: IntraDayCardView(),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text("分时走势卡片")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("IntraDayCardView")
                            .foregroundColor(.gray)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                    }
                }
            )
            // 结束
            
            NavigationLink(
                    destination: Comp_Tape(),
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
                    destination: Comp_Tape(),
                label:{
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TransactionDetails")
                            .font(.system(size: 16, weight: .semibold, design: .default))
                        Text("QuoteStat")
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

