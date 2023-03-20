//
//  BuyAndSellTips.swift
//  SuperPreview
//
//  Created by admin on 2023/1/13.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct BuyAndSellTips: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                HStack(spacing: 0) {
                    Text("现金可买")
                        .foregroundColor(Color("color-text-60"))
                        .font(.system(size: 12, weight: .regular, design: .default))
                    Text("250")
                        .padding(.leading, 10)
                        .foregroundColor(Color("color-utility3-red"))
                        .modifier(CustomFontModifier(size: 12, font: .medium))
                }.frame(width: UIScreen.main.bounds.width/2-20, alignment: .leading)
                
                HStack(spacing: 0) {
                    Text("持仓可卖")
                        .foregroundColor(Color("color-text-60"))
                        .font(.system(size: 12, weight: .regular, design: .default))
                    Text("0")
                        .padding(.leading, 10)
                        .foregroundColor(Color("color-utility3-green"))
                        .modifier(CustomFontModifier(size: 12, font: .medium))
                }.frame(width: UIScreen.main.bounds.width/2-20, alignment: .leading)
            }
            
            HStack(spacing: 0) {
                Text("最大可买")
                    .foregroundColor(Color("color-text-60"))
                    .font(.system(size: 12, weight: .regular, design: .default))
                Text("500")
                    .padding(.leading, 10)
                    .foregroundColor(Color("color-utility3-red"))
                    .modifier(CustomFontModifier(size: 12, font: .medium))
            }
            .frame(width: UIScreen.main.bounds.width/2-20, alignment: .leading)
            .padding(.top, 5)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
    }
}

struct BuyAndSellTips_Previews: PreviewProvider {
    static var previews: some View {
        BuyAndSellTips()
    }
}
