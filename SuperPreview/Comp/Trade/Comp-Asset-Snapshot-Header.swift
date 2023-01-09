//
//  Comp-Asset-Snapshot-Header.swift
//  SuperPreview
//
//  Created by PeterZ on 2020/9/8.
//  Copyright © 2020 PeterZ. All rights reserved.
//

import SwiftUI



struct Comp_Asset_Snapshot_Header: View {
    
    var market : String
    
    var body: some View {
        HStack(alignment: .center) {
            HStack(spacing: 7) {
                Rectangle()
                    .frame(width: 3, height: 11)
                    .foregroundColor(Color("color-brand-blue"))
                Text(market)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color("color-text-30"))
            }
            Spacer()
            HStack(spacing: 0.0) {
                VStack(alignment: .trailing){
                    Text("HKD 6,600,000.00")
                        .modifier(CustomFontModifier(size: 16, customFontsStyle: "PlusJakartaSansRoman-Semibold"))
                        .foregroundColor(Color("color-text-30"))
                    HStack(spacing: 10.0) {
                        Text("+1,600,000.00")
                            .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Semibold"))
                            .foregroundColor(Color("color-utility-red"))
                        Text("+41.83%")
                            .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Semibold"))
                            .foregroundColor(Color("color-utility-red"))
                        }
                    
                }
                Image("chevron_right_text30_sm")
            }
            
        }
        .padding(.leading, 0)
        .padding(.trailing, 10)
        .padding(.vertical, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
        .background(Color("color-base-1"))
    }
}

struct Comp_Asset_Snapshot_Header_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Asset_Snapshot_Header(market:"香港")
            .preferredColorScheme(.dark)
    }
}
