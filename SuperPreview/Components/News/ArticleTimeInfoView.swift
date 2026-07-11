//
//  ArticleTimeInfoView.swift
//  SuperPreview
//
//  Created by admin on 2021/4/29.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct ArticleTimeInfoView: View {
    var body: some View {
        VStack {
            HStack(spacing: 5.0) {
                Text("独家")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color("color-brand-blue"))
                    .frame(minWidth: 0, maxWidth: 28, maxHeight: 16)
                    .background(Color("color-brand-blue").opacity(0.2))
                    .cornerRadius(2)
                
                Text("2021/04/12")
                    .modifier(CustomFontModifier(size: 14, font: .medium))
                    .foregroundColor(Color("color-text-90"))
                
                Text("14:20")
                    .modifier(CustomFontModifier(size: 14, font: .medium))
                    .foregroundColor(Color("color-text-90"))
                
                
                Text("有鱼投研")
                    .font(.system(size: 14))
                    .foregroundColor(Color("color-brand-blue"))
                
                Spacer()
            }
            .padding(.horizontal, 15.0)
            .frame(minWidth: 0, maxWidth: .infinity, maxHeight: 20)
        }
        .padding(.top, 15)
        .padding(.bottom,15)
    }
}

struct ArticleTimeInfoViewPreviews: PreviewProvider {
    static var previews: some View {
        ArticleTimeInfoView()
    }
}
