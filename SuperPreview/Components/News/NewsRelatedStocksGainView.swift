//
//  NewsRelatedStocksGainView.swift
//  SuperPreview
//
//  Created by PeterZ on 2021/6/19.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct NewsRelatedStocksGainView: View {
    @Environment(\.marketColorReversed) private var marketColorReversed
    
    var name : String
    
    
    var body: some View {
        HStack {
            Text(name)
                .modifier(CustomFontModifier(size: 12, font: .medium))
                .foregroundColor(Color("color-blue1"))
            Spacer()
            Text("600.100")
                .modifier(CustomFontModifier(size: 12, font: .medium))
                .foregroundColor(MarketColor.resolve("color-utility-red", reversed: marketColorReversed))
                .padding(.trailing,20)
            Text("+1.20%")
                .modifier(CustomFontModifier(size: 12, font: .medium))
                .foregroundColor(MarketColor.resolve("color-utility-red", reversed: marketColorReversed))
                .padding(.leading,20)
        }
        .padding(.horizontal, 15)
    }
}

struct NewsRelatedStocksGainViewPreviews: PreviewProvider {
    static var previews: some View {
        NewsRelatedStocksGainView(name: "特斯拉(TSLA.US)")
    }
}
