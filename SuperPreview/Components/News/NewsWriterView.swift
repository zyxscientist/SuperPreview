//
//  NewsWriterView.swift
//  SuperPreview
//
//  Created by admin on 2021/5/19.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct NewsWriterView: View {
    var body: some View {
        HStack {
            Text("作者：刘少杰 苏扬")
                .lineSpacing(13.8)
                .font(.system(size: 14))
                .foregroundColor(Color("color-text-90"))
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 25)
    }
}

struct NewsWriterViewPreviews: PreviewProvider {
    static var previews: some View {
        NewsWriterView()
    }
}
