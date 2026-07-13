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
    var lineHeight: CGFloat?
    
    enum CustomFont: String {
        case regular = "PlusJakartaSans-Regular"
        case medium = "PlusJakartaSans-Medium"
        case semibold = "PlusJakartaSans-SemiBold"
        case bold = "PlusJakartaSans-Bold"
        // Add more cases for other font styles if needed
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if let lineHeight = lineHeight {
            content
                .font(.custom(font.rawValue, size: size))
                .lineSpacing(max(lineHeight - size, 0))
        } else {
            content.font(.custom(font.rawValue, size: size))
        }
    }
}
