//
//  NewsHeading2View.swift
//  SuperPreview
//
//  Created by admin on 2021/4/29.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct NewsHeading2View: View {
    
    var content: String
    
    var body: some View  {
        VStack {
            HStack(spacing: 0.0) {
                Text(content)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                
                Spacer()
            }.padding(.trailing, 15)
        }
        .padding(.top, 0)
        .padding(.bottom, 20)
        .padding(.horizontal, 15)
    }
}

struct NewsHeading2ViewPreviews: PreviewProvider {
    static var previews: some View {
        NewsHeading2View(content: "Heading2")
    }
}
