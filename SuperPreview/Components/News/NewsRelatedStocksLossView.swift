//
//  NewsRelatedStocksLossView.swift
//  SuperPreview
//
//  Created by PeterZ on 2021/6/19.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct NewsRelatedStocksLossView: View {
    
    var name : String
    
    
    var body: some View {
        HStack {
            Text(name)
                .foregroundColor(Color("color-brand-blue"))
            Spacer()
            Text("150.600")
                .foregroundColor(Color("color-utility-green"))
                .padding(.trailing,20)
            Text("-5.20%")
                .foregroundColor(Color("color-utility-green"))
                .padding(.leading,20)
        }
        .modifier(CustomFontModifier(size: 12, font: .medium))
        .padding(.horizontal, 15)
    }
}

struct NewsRelatedStocksLossViewPreviews: PreviewProvider {
    static var previews: some View {
        NewsRelatedStocksLossView(name: "特斯拉(TSLA.US)")
    }
}
