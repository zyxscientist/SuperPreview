//
//  JustifiedSeparatorView.swift
//  SuperPreview
//
//  Created by admin on 2021/4/30.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct JustifiedSeparatorView: View  {
    var body: some View {
        VStack() {
            Spacer()
            Rectangle()
                .frame(minHeight: 0.5, maxHeight:0.5)
                .foregroundColor(Color("color-separator-10"))
                .padding(.horizontal, 15)
        }
    }
}

struct JustifiedSeparatorViewPreviews: PreviewProvider {
    static var previews: some View {
        JustifiedSeparatorView()
    }
}
