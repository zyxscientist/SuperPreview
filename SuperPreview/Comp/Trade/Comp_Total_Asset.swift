//
//  Comp_Total_Asset.swift
//  SuperPreview
//
//  Created by admin on 2021/6/18.
//  Copyright © 2021 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Total_Asset: View {
    
    var body: some View {
        VStack(spacing: 0.0) {
            HStack {
                VStack(alignment: .leading, spacing: 0.0) {
                    HStack(spacing: 5.0) {
                        HStack(spacing: 5.0) {
                            Image("show")
                            Text("账户总资产")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(Color("color-text-60"))
                        }
                        HStack(alignment: .center, spacing: 0.0) {
                            Text("HKD")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color("color-brand-blue"))
                            Image("switch_nor")
                        }
                        
                    }
                    HStack(alignment: .bottom) {
                        Text("120,201.12")
                            .modifier(CustomFontModifier(size: 30, font: .semibold))
                            .foregroundColor(Color("color-text-30"))
                            .padding(.top,15)
                        
                        Spacer()
                        ZStack {
                            Image("total_asset_graph")
                                .frame(width: 110, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                            Rectangle()
                                .fill(LinearGradient(gradient: Gradient(colors: [Color("color-base-1").opacity(1),Color("color-base-1").opacity(0.0)]), startPoint: .leading, endPoint: .trailing))
                                .frame(width: 35,height: 50)
                                .offset(x: -38, y: 0)
                        }
                    }
                }

            }
            .padding(.top, 9)
            
            HStack {
                VStack(alignment: .leading, spacing: 0.0){
                    Text("今日盈亏")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color("color-text-60"))
                    Text("924,213.11")
                        .modifier(CustomFontModifier(size: 13, font: .semibold))
                        .foregroundColor(Color("color-text-30"))
                        .padding(.top, 5)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 0.0){
                    Text("现金")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color("color-text-60"))
                    Text("21,129.50")
                        .modifier(CustomFontModifier(size: 13, font: .semibold))
                        .foregroundColor(Color("color-text-30"))
                        .padding(.top, 5)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 0.0){
                    Text("持仓收益")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(Color("color-text-60"))
                    Text("+123,200.11")
                        .modifier(CustomFontModifier(size: 13, font: .semibold))
                        .foregroundColor(Color("color-utility-red"))
                        .padding(.top, 5)
                }
            }
            .padding(.top, 20)
            
            
            Image("asset_card_expand")
                .padding(.top, 3)
            

        }
        .padding(.horizontal, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
        .padding(.vertical, 15)
        .frame(maxHeight: 148)
        .background(Color("color-base-1"))
        .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
        .padding(.horizontal, 15)
        .padding(.top, /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
        // .animation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0))
    }
    
}

struct Comp_Total_Asset_Previews: PreviewProvider {
    static var previews: some View {
        Comp_Total_Asset()
            .preferredColorScheme(.dark)
    }
}
