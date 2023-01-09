//
//  Comp_Image_View.swift
//  SuperPreview
//
//  Created by admin on 2021/4/29.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Image_View: View {
    
    var image_name : String
    
    var body: some View {
        VStack {
            HStack {
                Image(image_name)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            .frame(width: UIScreen.main.bounds.size.width-30, height: 194)
            .clipShape(RoundedRectangle(cornerRadius: 6.0, style: .continuous))
            .clipped()
        }
        .padding(.top, 0)
        .padding(.bottom, 20)
    }
}

struct Comp_Image_View_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Image_View(image_name: "tesla")
    }
}
