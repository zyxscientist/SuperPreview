//
//  Untitled.swift
//  SuperPreview
//
//  Created by admin on 2024/9/30.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import SwiftUI


// 分时走势图卡片
struct Comp_IntraDayCard: View {
    
    var index_name = "恒生指数"
    var utility_color = Color(.colorUtilityRed)
    
    // 点击后缩小
    @GestureState private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0.0){
            Text(index_name)
                .minimumScaleFactor(0.5) // 过长时缩小字符，最小至原本的0.5
                .modifier(CustomFontModifier(size: 14, font: .regular))
                .fontWeight(.medium)
                .padding(.bottom, 2)
            
            Text("23308.99")
                .minimumScaleFactor(0.5)
                .modifier(CustomFontModifier(size: 16, font: .medium))
                .foregroundColor(Color(utility_color))
                .padding(.bottom, 4)
            
            HStack(spacing: 10){
                Text("+195.77")
                    .minimumScaleFactor(0.5) 
                    .modifier(CustomFontModifier(size: 12, font: .medium))
                    .foregroundColor(Color(utility_color))
                
                Text("+1.99%")
                    .minimumScaleFactor(0.5)
                    .modifier(CustomFontModifier(size: 12, font: .medium))
                    .foregroundColor(Color(utility_color))
            }
            .padding(.bottom, 10)
            
            ZStack{
                Fill_Mini_LineGraph(dataPoints: ChartMockData.miniChart_50_point.normalized, bottomBuffer: 0)
                    .fill(LinearGradient(gradient: Gradient(colors: [Color(utility_color).opacity(0.2), Color(utility_color).opacity(0.0)]), startPoint: .top, endPoint: .bottom))
                    .frame(width: 88, height: 44)
                
                Mini_LineGraph(dataPoints: ChartMockData.miniChart_50_point.normalized)
                    .stroke(Color(utility_color), style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
                    .frame(width: 88, height: 44)
                
            }
            
        }
        .padding(10)
        .frame(maxHeight: 140)
        .background(Color("color-base-1"))
        .cornerRadius(10, antialiased: true)
        
        // 点击缩放动画效果
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .gesture(
            DragGesture(minimumDistance: 0.0)
                .updating($isPressed) {
                    _, state, _ in state = true
                }
        ).animation(.spring(response: 0.2, dampingFraction: 1, blendDuration: 0.4), value: isPressed)
        
    }
}


#Preview {
    Comp_IntraDayCard(index_name: "指数名", utility_color: Color(.colorUtilityRed))
}
