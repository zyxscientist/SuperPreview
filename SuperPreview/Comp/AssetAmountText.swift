//
//  AssetAmountText.swift
//  SuperPreview
//
//  组件名称：资产大金额文本
//  简介：整数使用 30pt，小数点及小数使用 24pt，共用文字基线。
//  用于：总资产和各类子资产卡片的主要金额。
//

import SwiftUI

struct AssetAmountText: View {
    let value: String

    init(_ value: String) {
        self.value = value
    }

    var body: some View {
        Text(attributedValue)
            .accessibilityLabel(value)
    }

    private var attributedValue: AttributedString {
        var text = AttributedString(value)
        text.font = .custom("PlusJakartaSans-Bold", size: 30, relativeTo: .largeTitle)

        // Keep the supplied formatting and apply the smaller font to the
        // decimal separator as well. Masked and unavailable values stay whole.
        if let separator = text.range(of: ".") {
            text[separator.lowerBound...].font = .custom(
                "PlusJakartaSans-Bold",
                size: 24,
                relativeTo: .largeTitle
            )
        }

        return text
    }
}
