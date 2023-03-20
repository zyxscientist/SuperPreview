//
//  StockTradeTape.swift
//  SuperPreview
//
//  Created by admin on 2023/1/10.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

struct StockTradeTape: View {
    
    @Binding var openTapeView: Bool
    
    var body: some View {
        VStack(spacing:10){
            HStack(spacing:0){
                Rectangle()
                    .foregroundColor(Color("color-utility3-green"))
                    .frame(height: 5)
                
                Rectangle()
                    .foregroundColor(Color("color-utility3-red"))
                    .frame(height: 5)
            }
            .cornerRadius(100)
            
            // Tape 组
            VStack(spacing: 0) {
                ZStack {
                    HStack(spacing: 0.0){
                        Rectangle()
                            .foregroundColor(Color("color-utility3-red").opacity(0.15))
                            .frame(height: 27)
                            .overlay(
                                HStack{
                                    Text("16.980")
                                        .foregroundColor(Color("color-utility3-red"))
                                        .modifier(CustomFontModifier(size: 12, font: .medium))
                                        .padding(.leading, 10)
                                    
                                    Spacer()
                                    
                                    Text("2K(       1)")
                                        .foregroundColor(Color("color-text-30"))
                                        .modifier(CustomFontModifier(size: 12, font: .medium))
                                        .padding(.trailing, 10)
                                }
                            )
                        
                        Rectangle()
                            .foregroundColor(Color("color-utility3-green").opacity(0.15))
                            .frame(height: 27)
                            .overlay(
                                HStack{
                                    Text("15.910")
                                        .foregroundColor(Color("color-utility3-green"))
                                        .modifier(CustomFontModifier(size: 12, font: .medium))
                                        .padding(.leading, 10)
                                    
                                    Spacer()
                                    
                                    Text("33.21K(      33)")
                                        .foregroundColor(Color("color-text-30"))
                                        .modifier(CustomFontModifier(size: 12, font: .medium))
                                        .padding(.trailing, 10)
                                }
                            )
                    }
                }
                OtherTape()
                OtherTape()
                OtherTape()
                OtherTape()
                OtherTape()
                OtherTape()
                OtherTape()
                OtherTape()
                OtherTape()
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        } // 十档盘口
        .padding(.horizontal, 15)
        .padding(.top, 10)
        .padding(.bottom, 10)
        
        // TODO: 记笔记他妈的这个坑我好久
        .frame(height: openTapeView ? 320 : 82, alignment: .top)
        .background(Color("color-base-1"))
        .clipped()
    }
}

struct StockTradeTape_Previews: PreviewProvider {
    static var previews: some View {
        StockTradeTape(openTapeView: .constant(false))
    }
}

struct OtherTape: View {
    var body: some View {
        ZStack {
            
            HStack(spacing: 0.0){
                Rectangle()
                    .foregroundColor(Color("color-utility3-red").opacity(0.05))
                    .frame(height: 27)
                    .overlay(
                        HStack{
                            Text("799.980")
                                .foregroundColor(Color("color-utility3-red"))
                                .modifier(CustomFontModifier(size: 12, font: .medium))
                                .padding(.leading, 10)
                            
                            Spacer()
                            
                            Text("2K(       1)")
                                .foregroundColor(Color("color-text-30"))
                                .modifier(CustomFontModifier(size: 12, font: .medium))
                                .padding(.trailing, 10)
                        }
                    )
                
                Rectangle()
                    .foregroundColor(Color("color-utility3-green").opacity(0.05))
                    .frame(height: 27)
                    .overlay(
                        HStack{
                            Text("799.980")
                                .foregroundColor(Color("color-utility3-green"))
                                .modifier(CustomFontModifier(size: 12, font: .medium))
                                .padding(.leading, 10)
                            
                            Spacer()
                            
                            Text("33.21K(      33)")
                                .foregroundColor(Color("color-text-30"))
                                .modifier(CustomFontModifier(size: 12, font: .medium))
                                .padding(.trailing, 10)
                        }
                    )
            }
        }
    }
}
