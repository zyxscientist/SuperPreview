//
//  Page_Stock_Trade.swift
//  SuperPreview
//
//  Created by admin on 2023/1/9.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct Page_Stock_Trade: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
                ScrollView {
                    Text("Hello, World!")
                }
                .frame(width: UIScreen.main.bounds.size.width)
                .background(Color("color-base-0"))
                .overlay(
                    // 买卖按钮组
                    StockTradeButtonBar(),alignment: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
                
                // 导航栏设置
                .navigationBarBackButtonHidden(true)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarLeading) {
                        HStack(alignment: .top, spacing:0) {
                            Image("back-Left")
                                .onTapGesture {
                                    presentationMode.wrappedValue.dismiss()
                                }
                            HStack(alignment: .bottom, spacing:3) {
                                HStack(spacing:1){
                                    Text("港股融资账户")
                                        .modifier(CustomFontModifier(size: 16, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                                        .foregroundColor(Color("color-text-30"))
                                    Text("(0168)")
                                        .modifier(CustomFontModifier(size: 16, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                                        .foregroundColor(Color("color-text-30"))
                                }
                                Image("chevron_down_filled_sm")
                            }
                        }
                    }
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Image("refresh-Right")
                    }
            }
    }
}

struct Page_Stock_Trade_Previews: PreviewProvider {
    static var previews: some View {
        Page_Stock_Trade()
    }
}

struct StockTradeButtonBar: View {
    var body: some View {
        Rectangle()
            .foregroundColor(Color("color-base-1"))
            .frame(width: UIScreen.main.bounds.size.width, height: 94)
        
        // 按钮组
            .overlay(
                VStack(spacing: 8) {
                    Comp_Separator_Full()
                    VStack(spacing: 0) {
                        HStack(spacing: 10){
                            Rectangle()
                                .foregroundColor(Color("color-utility3-red"))
                                .frame(maxWidth:UIScreen.main.bounds.size.width/2-15, minHeight: 44,  maxHeight: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                                .overlay(
                                    Text("买入")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                )
                            
                            Rectangle()
                                .foregroundColor(Color("color-utility3-green"))
                                .frame(maxWidth:UIScreen.main.bounds.size.width, minHeight: 44, maxHeight: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
                                .overlay(
                                    Text("卖出")
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                )
                        }.padding(.horizontal, 15)
                        
                        //服务提供商，品牌露出
                        HStack(spacing: 5) {
                            Image("ysl_mini_logo")
                            Text("交易服务由云锋证券提供")
                                .modifier(CustomFontModifier(size: 9, customFontsStyle: "PlusJakartaSansRoman-Regular"))
                                .foregroundColor(Color("color-text-90"))
                        }.padding(.top, 6)
                    }
                }.padding(.bottom, 33)
            )
        
    }
}
