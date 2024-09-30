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
    var font: CustomFont
    
    enum CustomFont: String {
        case regular = "PlusJakartaSans-Regular"
        case medium = "PlusJakartaSansRoman-Medium"
        case semibold = "PlusJakartaSansRoman-SemiBold"
        case bold = "PlusJakartaSansRoman-Bold"
        // Add more cases for other font styles if needed
    }
    
    
    func body(content: Content) -> some View {
        content.font(.custom(font.rawValue, size: size))
    }
}
