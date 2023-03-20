//
//  Comp_News_Related_Stocks.swift
//  SuperPreview
//
//  Created by PeterZ on 2021/6/19.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_News_Related_Stocks_Gain: View {
    
    var name : String
    
    
    var body: some View {
        HStack {
            Text(name)
                .modifier(CustomFontModifier(size: 12, font: .medium))
                .foregroundColor(Color("color-brand-blue"))
            Spacer()
            Text("600.100")
                .modifier(CustomFontModifier(size: 12, font: .medium))
                .foregroundColor(Color("color-utility-red"))
                .padding(.trailing,20)
            Text("+1.20%")
                .modifier(CustomFontModifier(size: 12, font: .medium))
                .foregroundColor(Color("color-utility-red"))
                .padding(.leading,20)
        }
        .padding(.horizontal, 15)
    }
}

struct Comp_News_Related_Stocks_Gain_Previews: PreviewProvider {
    static var previews: some View {
        Comp_News_Related_Stocks_Gain(name: "特斯拉(TSLA.US)")
    }
}
