//
//  Comp_Heading_2.swift
//  SuperPreview
//
//  Created by admin on 2021/4/29.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Heading_2: View {
    
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

struct Comp_Heading_2_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Heading_2(content: "Heading2")
    }
}
