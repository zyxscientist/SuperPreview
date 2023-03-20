//
//  Comp_News_Title.swift
//  SuperPreview
//
//  Created by admin on 2021/4/29.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_News_Title: View {
    
    var news_title : String
    var fontsize : CGFloat
    
    var body: some View {
        HStack(spacing: 0.0) {
            Text(news_title)
                .lineSpacing(6)
                .modifier(CustomFontModifier(size: fontsize, font: .medium))
                .foregroundColor(Color("color-text-30"))
            
            Spacer()
        }
        .frame(minWidth: 0, maxWidth: .infinity)
        .padding(.horizontal, 15)
    }
}

struct Comp_News_Title_Previews: PreviewProvider {
    static var previews: some View {
        Comp_News_Title(news_title: "苹果(AAPL.US)造车或成为特斯拉(TSLA.US)重大利空，维持目标价880美元", fontsize: 24)
    }
}
