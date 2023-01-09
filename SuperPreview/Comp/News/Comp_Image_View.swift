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
            .frame(width: .infinity, height: 194)
            .cornerRadius(6)
            .clipped()
            .padding(.horizontal, 15)
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
