//
//  Comp_News_Related_Stocks_Loss.swift
//  SuperPreview
//
//  Created by PeterZ on 2021/6/19.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_News_Related_Stocks_Loss: View {
    
    var name : String
    
    
    var body: some View {
        HStack {
            Text(name)
                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                .foregroundColor(Color("color-brand-blue"))
            Spacer()
            Text("150.600")
                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                .foregroundColor(Color("color-utility-green"))
                .padding(.trailing,20)
            Text("-5.20%")
                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                .foregroundColor(Color("color-utility-green"))
                .padding(.leading,20)
        }
        .padding(.horizontal, 15)
    }
}

struct Comp_News_Related_Stocks_Loss_Previews: PreviewProvider {
    static var previews: some View {
        Comp_News_Related_Stocks_Loss(name: "特斯拉(TSLA.US)")
    }
}
