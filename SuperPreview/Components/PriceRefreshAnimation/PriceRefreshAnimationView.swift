//
//  PriceRefreshAnimationView.swift
//  SuperPreview
//
//  Created by Peter Zhu on 2026/3/17.
//  Copyright © 2026 PeterZ. All rights reserved.
//
//  组件名称：价格刷新动画 Demo
//  简介：演示报价数值变化时的数字刷新和视觉反馈动画。
//  用于：验证行情更新时的价格变动动效。
//

import SwiftUI

struct PriceRefreshAnimationView: View {
    
    @State var randomNumber: Double = 172.23
    
    var body: some View {
        
        HStack(alignment: .center, spacing:0){
            Text("USD")
                .modifier(CustomFontModifier(size: 16, font: .bold))
                .foregroundColor(Color(.colorText30))
                .padding(.vertical, 0)
            
            Text(String(format: "%.2f", randomNumber))
                .modifier(CustomFontModifier(size: 16, font: .bold))
                .foregroundColor(Color(.colorText30))
                .contentTransition(.numericText())
                .padding(.leading, 2)
        }
        
        if #available(iOS 26.0, *) {
            Button{
                newRandomNumber()
            } label: {
                Text("生成随机数字")
            }.buttonStyle(.glass)
        } else {
            Button{
                newRandomNumber()
            } label: {
                Text("生成随机数字")
            }.buttonStyle(.borderedProminent)
        }
              
    }
    
    private func newRandomNumber() {
            withAnimation {
                randomNumber = Double.random(in: 100.00...199.99)
            }
        }
    
}

#Preview {
    PriceRefreshAnimationView()
}
