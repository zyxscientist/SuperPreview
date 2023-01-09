//
//  CustomFontModifier.swift
//  SuperPreview
//
//  Created by 朱宇軒 on 2022/6/9.
//  Copyright © 2022 PeterZ. All rights reserved.
//

import SwiftUI

struct CustomFontModifier: ViewModifier {
    
    var size: CGFloat = 16
    var customFontsStyle : String
    
    func body(content: Content) -> some View {
        content.font(.custom(customFontsStyle, size: size))
    }
}
