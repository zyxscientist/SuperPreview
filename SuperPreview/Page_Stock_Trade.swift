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
    @State var priceTargetingMenu: Bool = false
    @State var quantityQuickType: Bool = false
    @State var advanceSetting: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // MARK: 一个Stack内不能超过十个元素，所以要打个组
                Group {
                    // 搜索框
                    Symbol_Inputfield()
                    
                    // 行情栏
                    Symbol_Quote(openGraphView: $openGraphView)
                    
                    // 图表组件
                    HStack {
                        Image("graphview")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                        .frame(height: openGraphView ? UIScreen.main.bounds.width * 0.9253333333 : 0)
                        .opacity(openGraphView ? 1 : 0) // 防止在隐藏时遮盖了其他操作热区
                        .blur(radius: openGraphView ? 0 : 3)
                        .clipped()
                }
                
                // 十档报价
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
                                        .frame(minWidth: 400)
                                        .contentShape(Rectangle()) // 扩大操作热区
                                        .rotationEffect(.degrees(openTapeView ? -180 : 0))
                                        .padding(.top, openTapeView ? 10 : 15)
                                        .onTapGesture {
                                            HapticManager.instance.impactHaptic(type: .medium)
                                            withAnimation(.spring(response: 0.4, dampingFraction: 1, blendDuration: 0.8)){
                                                openTapeView.toggle()
                                            }
                                        }
                                }
                        }
                    }
                
                // 订单类型
                Order_Type()
                    .padding(.top, 5)
                
                // 价格输入栏
                Price_Inputfield(priceTargetingMenu: $priceTargetingMenu)
                    .zIndex(2)
                
                // 数量输入栏
                Quantity_Inputfield(quantityQuickType: $quantityQuickType)
                
                // 数量快选组件
                HStack(spacing: 0) {
                    
                    // 现金可买
                    VStack(alignment: .center, spacing:0){
                        Text("现金可买")
                            .foregroundColor(Color("color-text-60"))
                            .font(.system(size: 10, weight: .regular, design: .default))
                            .padding(.bottom, 5)
                        VStack(spacing: 15){
                            Text("1/4")
                                .foregroundColor(Color("color-utility3-red"))
                                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                            Text("1/3")
                                .foregroundColor(Color("color-utility3-red"))
                                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                            Text("1/2")
                                .foregroundColor(Color("color-utility3-red"))
                                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                            Text("全仓")
                                .foregroundColor(Color("color-utility3-red"))
                                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                        }
                        .frame(width: UIScreen.main.bounds.width/4-15)
                        .padding(.vertical, 10)
                        .background(Color("color-utility3-red").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8.0))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                                .stroke(Color("color-utility3-red"), lineWidth: 1)
                        )
                    }.padding(.trailing, 5)
                    
                    // 最大可买
                    VStack(alignment: .center, spacing:0){
                        Text("最大可买")
                            .foregroundColor(Color("color-text-60"))
                            .font(.system(size: 10, weight: .regular, design: .default))
                            .padding(.bottom, 5)
                        VStack(spacing: 15){
                            Text("1/4")
                                .foregroundColor(Color("color-utility3-red"))
                                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                            Text("1/3")
                                .foregroundColor(Color("color-utility3-red"))
                                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                            Text("1/2")
                                .foregroundColor(Color("color-utility3-red"))
                                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                            Text("全仓")
                                .foregroundColor(Color("color-utility3-red"))
                                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                        }
                        .frame(width: UIScreen.main.bounds.width/4-15)
                        .padding(.vertical, 10)
                        .background(Color("color-utility3-red").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8.0))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                                .stroke(Color("color-utility3-red"), lineWidth: 1)
                        )
                    }.padding(.trailing, 10)
                    
                    // 持仓可卖
                    VStack(alignment: .center, spacing:0){
                        Text("持仓可卖")
                            .foregroundColor(Color("color-text-60"))
                            .font(.system(size: 10, weight: .regular, design: .default))
                            .padding(.bottom, 5)
                        VStack(spacing: 15){
                            Text("1/4")
                                .foregroundColor(Color("color-utility3-green"))
                                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                            Text("1/3")
                                .foregroundColor(Color("color-utility3-green"))
                                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                            Text("1/2")
                                .foregroundColor(Color("color-utility3-green"))
                                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                            Text("全仓")
                                .foregroundColor(Color("color-utility3-green"))
                                .modifier(CustomFontModifier(size: 12, customFontsStyle: "PlusJakartaSansRoman-Medium"))
                        }
                        .frame(width: UIScreen.main.bounds.width/2-20)
                        .padding(.vertical, 10)
                        .background(Color("color-utility3-green").opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8.0))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                                .stroke(Color("color-utility3-green"), lineWidth: 1)
                        )
                    }
                    
                }
                    .padding(.top, 10)
                    .padding(.bottom, 15)
                    .frame(width: UIScreen.main.bounds.size.width, height: quantityQuickType ? nil : 0)
                    .opacity(quantityQuickType ? 1 : 0)
                    .blur(radius: quantityQuickType ? 0 : 2)
                    .background(Color("color-base-1"))
                    .overlay{
                        Comp_Separator_Full()
                    }
                    .clipped()
                
                // 金额栏
                Amount(advanceSetting: $advanceSetting)
                    .zIndex(1)
                
                // MARK: 高级订单设置
                OrderExpiry()
                    .frame(width: UIScreen.main.bounds.size.width, height: advanceSetting ? nil : 0)
                    .opacity(advanceSetting ? 1 : 0)
                    .blur(radius: advanceSetting ? 0 : 2)
                
                MaximumBuyingPower()
                
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
            } // 导航栏设置
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
