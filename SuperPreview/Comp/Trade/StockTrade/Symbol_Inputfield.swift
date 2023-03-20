//
//  Symbol_Inputfield.swift
//  SuperPreview
//
//  Created by admin on 2023/1/10.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct Symbol_Inputfield: View {
    var body: some View {
        HStack(spacing: 0) {
            
            Text("名称")
                .foregroundColor(Color("color-text-60"))
                .font(.system(size: 16, weight: .regular, design: .default))
            
            Text("00376.HK")
                .padding(.leading, 65)
                .foregroundColor(Color("color-text-30"))
                .modifier(CustomFontModifier(size: 16, font: .medium))
            
            Spacer()
        }
        .padding(.leading, 15)
        .frame(width: UIScreen.main.bounds.size.width,height: 44)
        .background(Color("color-base-1"))
        .overlay {
            Comp_Separator_Full()
        }
    }
}

struct Symbol_Inputfield_Previews: PreviewProvider {
    static var previews: some View {
        Symbol_Inputfield().previewLayout(.sizeThatFits)
    }
}
