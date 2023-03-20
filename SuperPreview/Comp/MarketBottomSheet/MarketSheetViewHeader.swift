//
//  MarketSheetViewHeader.swift
//  SuperPreview
//
//  Created by 朱宇軒 on 2023/3/11.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct MarketSheetViewHeader: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Market")
                .modifier(CustomFontModifier(size: 20, font: .medium))
                .foregroundColor(Color("color-text-30"))
            
            HStack(spacing: 2){
                Text("Swipe Up")
                    .modifier(CustomFontModifier(size: 12, font: .medium))
                    .foregroundColor(Color("color-text-60"))
            }
            
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.gray)
                .frame(height: 1)
        }.background(Color.clear)
    }
}

struct MarketSheetViewHeader_Previews: PreviewProvider {
    static var previews: some View {
        MarketSheetViewHeader()
    }
}
