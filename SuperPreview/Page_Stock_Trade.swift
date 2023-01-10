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
    @State var openGraphView: Bool = false
    @State var openTapeView: Bool = false
    
    var body: some View {
            ScrollView {
                VStack(spacing: 0) {
                    
                    Symbol_Inputfield()
                    
                    Symbol_Quote(openGraphView: $openGraphView)
                    
                    HStack {
                        Image("graphview")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                    .frame(height: openGraphView ? UIScreen.main.bounds.width * 0.9253333333 : 0)
                    .opacity(openGraphView ? 1 : 0) // 防止在隐藏时遮盖了其他操作热区
                    .blur(radius: openGraphView ? 0 : 3)
                    .clipped()
                    
                    StockTradeTape(openTapeView: $openTapeView)
                        .padding(.top, 5)
                        .overlay {
                            VStack {
                                Spacer()
                                Rectangle().frame(height: 30)
                                    .blur(radius: openTapeView ? 2 : 0)
                                    .opacity(openTapeView ? 0 : 1)
                                    .foregroundColor(Color("color-base-1"))
                                    .mask(LinearGradient(
                                        gradient:
                                            Gradient(
                                                stops: [.init(color: .black, location: 0),
                                                        .init(color: .black, location: 0.4),
                                                        .init(color: .clear, location: 1)
                                                ]),
                                        startPoint: .bottom, endPoint: .top
                                    ))
                                    .overlay {
                                        Image("tape_unfold")
                                            .frame(minWidth: 320)
                                            .contentShape(Rectangle()) // 扩大操作热区
                                            .rotationEffect(.degrees(openTapeView ? -180 : 0))
                                            .padding(.top, openTapeView ? 10 : 15)
                                            .onTapGesture {
                                                withAnimation(.spring(response: 0.4, dampingFraction: 1, blendDuration: 0.8)){
                                                    openTapeView.toggle()
                                                }
                                            }
                                    }
                            }
                        }
                    
                    Order_Type()
                        .padding(.top, 5)
                }
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
        
        // 背景
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
