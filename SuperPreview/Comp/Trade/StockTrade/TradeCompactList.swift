//
//  TradeCompactList.swift
//  SuperPreview
//
//  Created by admin on 2023/1/13.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct TradeCompactList: View {
    
    @State var positionList: Bool = true
    @State var todayOrderList: Bool = false
    @State var conditionalOrderList: Bool = false
    
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 15) {
                Text("持仓(2)")
                    .foregroundColor(positionList ? Color("color-text-30") : Color("color-text-60"))
                    .modifier(CustomFontModifier(size: 14, customFontsStyle: positionList ? "PlusJakartaSansRoman-Semibold" : "PlusJakartaSansRoman-Medium"))
                    .onTapGesture {
                        positionList = true
                        todayOrderList = false
                        conditionalOrderList = false
                    }
                Text("今日订单(0/3)")
                    .foregroundColor(todayOrderList ? Color("color-text-30") : Color("color-text-60"))
                    .modifier(CustomFontModifier(size: 14, customFontsStyle: todayOrderList ? "PlusJakartaSansRoman-Semibold" : "PlusJakartaSansRoman-Medium"))
                    .onTapGesture {
                        positionList = false
                        todayOrderList = true
                        conditionalOrderList = false
                    }
                Text("条件单(0/0)")
                    .foregroundColor(conditionalOrderList ? Color("color-text-30") : Color("color-text-60"))
                    .modifier(CustomFontModifier(size: 14, customFontsStyle: conditionalOrderList ? "PlusJakartaSansRoman-Semibold" : "PlusJakartaSansRoman-Medium"))
                    .onTapGesture {
                        positionList = false
                        todayOrderList = false
                        conditionalOrderList = true
                    }
                Spacer()
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            
            // 持仓列表
            VStack(spacing: 0) {
                Comp_Snapshot_Group_Table_Header()
                    .padding(.leading, 15)
                Comp_List_Snapshot_Holdings_Gain(name: "阿里巴巴-W", symbol: "09988.HK")
                    .padding(.leading, 15)
                Comp_List_Snapshot_Holdings_Gain(name: "汇丰银行", symbol: "00005.HK")
                    .padding(.leading, 15)
            }
            .frame(height: positionList ? nil : 0, alignment: .top)
            .opacity(positionList ? 1 : 0)
            
            // 今日订单
            VStack(spacing: 0) {
                Comp_Today_Order_Table_Header(horizontalPadding: 15)
                Today_Order_List_Item()
                Today_Order_List_Item()
                Today_Order_List_Item()
            }
            .frame(height: todayOrderList ? nil : 0, alignment: .top)
            .opacity(todayOrderList ? 1 : 0)
            
            // 条件单列表
            VStack(spacing: 0) {
                Image("empty_portfolio")
                Text("暂无条件单")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
                    .padding(.top, 25)
                    .padding(.bottom, 25)
            }
            .frame(height: conditionalOrderList ? nil : 0, alignment: .top)
            .opacity(conditionalOrderList ? 1 : 0)
            
        }.background(Color("color-base-1"))
    }
}

struct TradeCompactList_Previews: PreviewProvider {
    static var previews: some View {
        TradeCompactList()
    }
}
