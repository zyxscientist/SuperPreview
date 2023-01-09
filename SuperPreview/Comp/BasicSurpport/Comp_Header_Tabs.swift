//
//  Comp-Big-Tabs.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/8.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Header_Tabs: View {
    var body: some View {
        HStack(alignment: .top, spacing: 20.0) {
            VStack(spacing: 5.0) {
                Text("股票")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
                
                 Capsule()
                    .frame(width: 32, height: 2)
                    .foregroundColor(Color("color-brand-blue"))
            }
                Text("基金")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
            
                Text("有鱼额")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
            
                Text("股权激励")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color("color-text-60"))
            
                Spacer()
            
            Image("headertab_sort")
                .padding(.top, 0)
            
        }
        .background(Color("color-transparent"))
        .padding(.horizontal,15)
        .padding(.top, 5)
    }
}

struct Comp_Header_Tabs_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Header_Tabs()
    }
}
