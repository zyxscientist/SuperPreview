//
//  FullWidthSeparatorView.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/10/18.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct FullWidthSeparatorView: View {
    var body: some View {
        VStack() {
            Spacer()
            Rectangle()
                .frame(minHeight: 0.5, maxHeight:0.5)
                .foregroundColor(Color("color-separator-10"))
                .edgesIgnoringSafeArea(.top)
        }
    }
}

struct FullWidthSeparatorViewPreviews: PreviewProvider {
    static var previews: some View {
        FullWidthSeparatorView()
    }
}
