//
//  BlurModifier.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/8/30.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import Foundation
import SwiftUI

struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterial // 默认值，随意都行
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}
