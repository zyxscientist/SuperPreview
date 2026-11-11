//
//  WealthView.swift
//  SuperPreview
//
//  Created by PeterZ on 2021/8/8.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct WealthView: View {
    var body: some View {
        statusCapsule
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.colorBase0))
    }

    @ViewBuilder
    private var statusCapsule: some View {
        let label = Text(verbatim: "🛠️构建中")
            .font(.system(size: 22))
            .foregroundStyle(Color(.colorText1))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

        if #available(iOS 26.0, *) {
            label.glassEffect(.regular, in: Capsule())
        } else {
            label.background(.regularMaterial, in: Capsule())
        }
    }
}

struct WealthViewPreviews: PreviewProvider {
    static var previews: some View {
        WealthView()
    }
}
