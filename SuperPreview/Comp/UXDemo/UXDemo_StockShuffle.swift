//
//  dragtest.swift
//  SuperPreview
//
//  Created by admin on 2024/10/11.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import SwiftUI

struct UXDemo_StockShuffle: View {
    
    @State private var offset: CGFloat = 0 // 按钮边缘到屏幕边缘(左/右) 之间的距离，初始值为0
    @State private var isDragging = false
    @State private var hasVibratedLeft = false
    @State private var hasVibratedRight = false
    private var widthOfTheView: CGFloat = 250
    
    // 添加新的状态变量来跟踪当前股票序号
    @State private var currentStockIndex: Int = 1
    
    var body: some View {
        
        VStack{
            
            Spacer()
            
            // 添加显示当前股票序号的文本
            
            Text("自选列表的第 \(currentStockIndex) 个股票")
                .modifier(CustomFontModifier(size: 32, font: .medium))
                .foregroundColor(Color(.colorText30))
            
            Text("Feature: Stock Shuffle")
                .modifier(CustomFontModifier(size: 22, font: .medium))
                .foregroundColor(Color(.colorText60))
            
            Spacer()
            
            GeometryReader { geometry in
                
                HStack(spacing: 0) {
                    
                    // 左箭头
                    Image(.shuffleArrowPrevious)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 15, height: 24)
                        .foregroundColor(Color(.colorText30))
                        .offset(x: -35)
                        .opacity(opacityForArrow(maxOffset: (geometry.size.width - widthOfTheView) / 2))
                        .blur(radius: blurForArrow(maxOffset: (geometry.size.width - widthOfTheView) / 2))
                        .scaleEffect(scaleForArrow(maxOffset: (geometry.size.width - widthOfTheView) / 2))
                    
                    Text("交易")
                        .modifier(CustomFontModifier(size: 16, font: .medium))
                        .frame(maxWidth: 500, minHeight: 48)
                        .background(Color(.colorBrandBlue))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    
                    HStack(spacing:0){
                        
                        // 第一个按钮
                        VStack(spacing:4){
                            
                            Image(.favorite)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width:24, height: 24)
                                .foregroundColor(Color(.colorText30))
                            
                            Text("自选")
                                .foregroundColor(Color(.colorText60))
                                .modifier(CustomFontModifier(size: 10, font: .regular))
                                .frame(maxWidth:52)
                            
                        } // 结束
                        
                        // 第二个按钮
                        VStack(spacing:4){
                            
                            Image(.alertInactive)
                                .renderingMode(.template)
                                .resizable()
                                .frame(width:24, height: 24)
                                .foregroundColor(Color(.colorText30))
                            
                            Text("提醒")
                                .foregroundColor(Color(.colorText60))
                                .modifier(CustomFontModifier(size: 10, font: .regular))
                                .frame(maxWidth:52)
                            
                        } // 结束
                    }
                        .padding(.leading, 5)
                    
                    // 右箭头
                    Image(.shuffleArrowNext)
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 15, height: 24)
                        .foregroundColor(Color(.colorText30))
                        .offset(x: 35)
                        .opacity(opacityForArrow(maxOffset: (geometry.size.width - widthOfTheView) / 2))
                        .blur(radius: blurForArrow(maxOffset: (geometry.size.width - widthOfTheView) / 2))
                        .scaleEffect(scaleForArrow(maxOffset: (geometry.size.width - widthOfTheView) / 2))
                    
                }
                .background(Color(.colorBase1))
                .padding(.vertical, 10)
                .position(x: geometry.size.width / 2 + offset, y: geometry.size.height / 2)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            isDragging = true
                            let newOffset = gesture.translation.width // 只取横向拖动的距离值
                            let maxOffset = (geometry.size.width - widthOfTheView) / 2 // 边缘限制
                            
                            offset = min(max(newOffset, -maxOffset), maxOffset)
                            
                            // 触发震动代表释放可以切换股票
                            if abs(offset) >= maxOffset * 1 { // 可以通过数值控制触发提前量
                                if offset > 0 && !hasVibratedRight {
                                    HapticManager.instance.impactHaptic(type: .rigid)
                                    hasVibratedRight = true
                                    hasVibratedLeft = false
                                } else if offset < 0 && !hasVibratedLeft {
                                    HapticManager.instance.impactHaptic(type: .rigid)
                                    hasVibratedLeft = true
                                    hasVibratedRight = false
                                }
                            } else {
                                hasVibratedLeft = false
                                hasVibratedRight = false
                            }
                        }
                    
                        .onEnded { _ in
                            
                            isDragging = false
                            
                            let maxOffset = (geometry.size.width - widthOfTheView) / 2  //边缘限制
                            
                            
                            // 松手再判断一次，这样可以实现可撤销操作
                            if abs(offset) >= maxOffset * 0.95 { // 可以通过数值控制触发提前量
                                if offset > 0 {
                                    print("右切上一个个股")
                                    currentStockIndex = max(1, currentStockIndex - 1)
                                } else {
                                    currentStockIndex += 1
                                    print("左切下一个个股")
                                }
                            } else {
                                print("未触发切换, \(abs(offset)) 不大于 \(maxOffset)")
                            }
                            
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.8)) {
                                offset = 0 // 使其回到原来的位置
                            }
                            
                            // 重置震动状态
                            hasVibratedLeft = false
                            hasVibratedRight = false
                        }
                )
            }
                .frame(maxHeight: 62)
                .background(Color(.colorBase1))
                .overlay {
                    Comp_Separator_Full()
                        .rotationEffect(.degrees(180))
                }
        }
    }
    
    // 计算箭头的不透明度
    private func opacityForArrow(maxOffset: CGFloat) -> Double {
        let progress = min(abs(offset) / maxOffset, 1.0)
        return Double(progress)
    }
    
    // 计算箭头的模糊度
    private func blurForArrow(maxOffset: CGFloat) -> CGFloat {
        let progress = min(abs(offset) / maxOffset, 1.0)
        let maxBlur: CGFloat = 10
        return maxBlur * (1 - progress)
    }
    
    // 计算箭头的大小
    private func scaleForArrow(maxOffset: CGFloat) -> Double {
        let progress = min(abs(offset) / maxOffset, 1)
        return Double(progress)
    }
    
}




#Preview {
    UXDemo_StockShuffle()
}
