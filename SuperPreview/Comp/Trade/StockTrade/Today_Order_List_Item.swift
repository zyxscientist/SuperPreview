//
//  Today_Order_List_Item.swift
//  SuperPreview
//
//  Created by admin on 2023/1/13.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct Today_Order_List_Item: View {
    
    enum Direction: String {
        case buy = "买入"
        case sell = "卖出"
    }
    
    enum OrderStatu: Int {
        case processing = 1
        case doneDeal = 2
        case cancelled = 3
        case error = 4
    }
    
    var statu: OrderStatu
    var direction : Direction
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            VStack(alignment: .leading,spacing: 1) {
                Text("\(direction.rawValue)")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(directionColor(direction: direction.rawValue)))
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 15)
                
                HStack(spacing: 2) {
                    Image(orderStatuIcon(orderStatuCode: statu.rawValue))
                    Text(orderStatuString(orderStatuCode: statu.rawValue))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color("color-text-60"))
                        .multilineTextAlignment(.leading)
                }.padding(.leading, 15)
            }.frame(width: UIScreen.main.bounds.width * 24 / 100, alignment: .leading)
            
            
            VStack(alignment: .leading, spacing: 1) {
                Text("云锋金融")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color("color-text-30"))
                Text("00376.HK")
                    .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                    .foregroundColor(Color("color-text-60"))
                    .multilineTextAlignment(.leading)
            }
            .frame(width: UIScreen.main.bounds.width * 26 / 100, alignment: .leading)
            
            VStack(alignment: .trailing) {
                HStack(spacing: 5) {
                    Image(statu.rawValue != 1 ? "TO_price_nudge_minus_invisiable" : "TO_price_nudge_minus") // 根据状态隐藏价格微调按钮
                    Text("16.39")
                        .modifier(CustomFontModifier(size: 15, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                        .foregroundColor(Color("color-text-30"))
                    Image(statu.rawValue != 1 ? "TO_price_nudge_minus_invisiable" : "TO_price_nudge_add") // 根据状态隐藏价格微调按钮
                    }
            }
            .frame(width: UIScreen.main.bounds.width * 27 / 100, alignment: .trailing)
            
            VStack(alignment: .trailing, spacing: 1.0) {
                Text("2,000")
                    .modifier(CustomFontModifier(size: 15, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                    .foregroundColor(Color("color-text-30"))
                    .padding(.trailing, 15)
                Text(statu.rawValue != 1 ? "2000" : "0") // 根据状态显示成交数量
                    .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                    .foregroundColor(Color("color-text-60"))
                    .padding(.trailing, 15)
            }
            .frame(width: UIScreen.main.bounds.width * 23 / 100, alignment: .trailing)
            
        }
        .background(Color("color-transparent"))
        .padding(.vertical, 10)
    }
}

struct Today_Order_List_Item_Previews: PreviewProvider {
    static var previews: some View {
        Today_Order_List_Item(statu: .doneDeal, direction: .buy)
    }
}
