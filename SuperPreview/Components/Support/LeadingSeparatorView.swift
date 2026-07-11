//
//  LeadingSeparatorView.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/10/18.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct LeadingSeparatorView: View {
    var body: some View {
        VStack {
            Spacer()
            Rectangle()
                .frame(maxHeight:0.5)
                .foregroundColor(Color("color-separator-10"))
                .padding(.leading,15)
        }
    }
}

struct LeadingSeparatorViewPreviews: PreviewProvider {
    static var previews: some View {
        LeadingSeparatorView()
    }
}
