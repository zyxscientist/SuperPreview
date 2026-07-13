//
//  OrderExpiryView.swift
//  SuperPreview
//
//  Created by admin on 2023/1/12.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct OrderExpiryView: View {
    var body: some View {
        HStack(spacing: 0) {
            
            Text("有效期")
                .foregroundColor(Color("color-text-60"))
                .font(.system(size: 16, weight: .regular, design: .default))
            
            Text("今日有效")
                .padding(.leading, 49)
                .foregroundColor(Color("color-text-30"))
                .modifier(CustomFontModifier(size: 16, font: .medium))
            
            Spacer()
            
            Image("chevron_down_filled_sm")
                .padding(.trailing, 22)
            
        }
        .padding(.leading, 15)
        .frame(width: UIScreen.main.bounds.size.width, height: 44)
        .background(Color("color-base-1"))
        .overlay {
            FullWidthSeparatorView()
        }
    }
}

struct OrderExpiryViewPreviews: PreviewProvider {
    static var previews: some View {
        OrderExpiryView()
    }
}
