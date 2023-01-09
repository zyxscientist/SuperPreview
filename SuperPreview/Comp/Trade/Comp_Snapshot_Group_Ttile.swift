//
//  Comp_Snapshot_Group_Ttile.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/12.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Snapshot_Group_Ttile: View {
    
    var flag_icon : String
    var title : String
    
    var body: some View {
        HStack {
            HStack(spacing: 5.0){
                Image(flag_icon)
                    .frame(width: 19, height: 13)
                Text(title)
                    .foregroundColor(Color("color-text-30"))
                    .font(.system(size: 14, weight: .semibold))
            }
            Spacer()
            
            HStack(spacing: 5.0){
                 Text("1,600,000.00")
                    .modifier(CustomFontModifier(size: 14, customFontsStyle: "PlusJakartaSansRoman-Semibold"))
                    .foregroundColor(Color("color-text-30"))
                Image("chevron_up_sm")
                    .frame(width: 19, height: 13)
            }
        }
        .frame(maxWidth: 375, minHeight: 46)
        .padding(.horizontal, 10)
        .background(Color("color-transparent"))
    }
}

struct Comp_Snapshot_Group_Ttile_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Snapshot_Group_Ttile(flag_icon: "flag_US", title: "美股市场(USD)")
    }
}
