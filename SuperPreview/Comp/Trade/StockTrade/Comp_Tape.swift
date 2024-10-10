//
//  Comp_Tape.swift
//  SuperPreview
//
//  Created by admin on 2024/9/30.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Tape: View {
    
    @StateObject private var viewModel = TapeViewModel()
    
    var itemCount: Int = 10
    
    var body: some View {
        
        ScrollView{
            VStack(spacing:0){
                ForEach(0..<itemCount, id: \.self){ index in
                    
                    HStack(spacing: 0){
                        // 分买卖两侧构建
                        BuySideTapeCellView(index: index, directionColor: Color(.colorUtility3Red), data: viewModel.leftData.count > index ? viewModel.leftData[index] : nil, viewModel: viewModel) // 比较数据总量的大小，如果大过index就为nil，确保不大过 index 数量，让视图保持10档
                        SellSideTapeCellView(index: index, directionColor: Color(.colorUtility3Green), data: viewModel.rightData.count > index ? viewModel.rightData[index] : nil, viewModel: viewModel)
                    }
                }
            }
            .background(Color(.colorBase1))
            .clipShape(RoundedRectangle(cornerRadius: 6.0, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color(.colorSeparator10), lineWidth: 0.5)
            )
            .padding(.horizontal, 15)
            .padding(.top, 40)
            .shadow(color: Color.black.opacity(0.15), radius: 25, x: 0, y: 2)
        }
        .background(Color(.colorBase1))
    }
}


// 买侧单元格视图
struct BuySideTapeCellView: View {
    
    @State private var animatedVolume: CGFloat = 0 // 将单量装进来，以此驱动动画
    
    var index: Int = 1          // 序号参数
    var directionColor: Color   // 背景色参数
    var data: TapeCellData?
    var viewModel: TapeViewModel
    
    private let maxVolume: Int = 20000 // ModelView 生成的最大单量就是 20000
    
    var body: some View {
        
        ZStack(alignment: .trailing){
            
            // 现有背景
            Rectangle()
                .fill(directionColor.opacity(index == 0 ? 0.1 : 0.05))
            
            
            // 单量背景柱
            Rectangle()
                .fill(directionColor.opacity(0.15))
                .frame(width: calculateWidth(for: animatedVolume))
                .animation(.easeOut(duration: 0.2), value: animatedVolume)

            
            HStack(spacing: 0){
                HStack(spacing: 5) {
                    
                    // 序号
                    Text("\(index + 1)")
                        .foregroundColor(.white)
                        .modifier(CustomFontModifier(size: 9, font: .bold))
                        .frame(maxWidth: 13, maxHeight:13)
                        .background(directionColor.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 3.0, style: .continuous))
                    
                    
                    // 价格
                    Text(String(format: "%.3f", data?.price ?? 0))
                        .foregroundColor(directionColor)
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                }
                
                Spacer()
                
                // 单量
                HStack(spacing: 0){
                    Text(formatTapeVolume(data?.volume ?? 0))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color(.colorText30))
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                    
                    Text("(")
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color(.colorText30))
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                        .padding(.leading, 3)
                    
                    // 经纪商家数
                    Text(String(data?.brokerCount ?? 0))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(width:25, alignment: .trailing) // 固定宽度并靠右边对齐
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color(.colorText30))
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                    
                    
                    Text(")")
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color(.colorText30))
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                    
                }
            }
            .padding(.vertical, 7)
            .padding(.leading, 7)
            .padding(.trailing, 10)
        }
        .onChange(of: data?.volume) { oldValue, newValue in
            if let newValue {
                withAnimation {
                    animatedVolume = CGFloat(newValue)
                }
            }
        }
        .onAppear {
            animatedVolume = CGFloat(data?.volume ?? 0)
        }
    }
    
    // 宽度计算器
    private func calculateWidth(for volume: CGFloat) -> CGFloat {
        let maxWidth = UIScreen.main.bounds.width / 2 - 15 // 假设单个TapeCellView的最大宽度
        return (volume / CGFloat(maxVolume)) * maxWidth
    }
    
}


// 卖侧单元格视图
struct SellSideTapeCellView: View {
    
    @State private var animatedVolume: CGFloat = 0 // 将单量装进来，以此驱动动画
    
    var index: Int = 1          // 序号参数
    var directionColor: Color   // 背景色参数
    var data: TapeCellData?
    var viewModel: TapeViewModel
    
    private let maxVolume: Int = 20000 // ModelView 生成的最大单量就是 20000
    
    var body: some View {
        
        ZStack(alignment: .leading){
            
            // 现有背景
            Rectangle()
                .fill(directionColor.opacity(index == 0 ? 0.1 : 0.05))
            
            
            // 单量背景柱
            Rectangle()
                .fill(directionColor.opacity(0.15))
                .frame(width: calculateWidth(for: animatedVolume))
                .animation(.easeOut(duration: 0.2), value: animatedVolume)
            
            
            HStack(spacing: 0){
                HStack(spacing: 5) {
                    
                    // 序号
                    Text("\(index + 1)")
                        .foregroundColor(.white)
                        .modifier(CustomFontModifier(size: 9, font: .bold))
                        .frame(maxWidth: 13, maxHeight:13)
                        .background(directionColor.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 3.0, style: .continuous))
                    
                    // 价格
                    Text(String(format: "%.3f", data?.price ?? 0))
                        .foregroundColor(directionColor)
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                }
                
                Spacer()
                
                // 单量
                HStack(spacing: 0){
                    Text(formatTapeVolume(data?.volume ?? 0))
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color(.colorText30))
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                    
                    Text("(")
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color(.colorText30))
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                        .padding(.leading, 3)
                    
                    // 经纪商家数
                    Text(String(data?.brokerCount ?? 0))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(width:25, alignment: .trailing) // 固定宽度并靠右边对齐
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color(.colorText30))
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                    
                    
                    Text(")")
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(Color(.colorText30))
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                    
                }
            }
            .padding(.vertical, 7)
            .padding(.leading, 7)
            .padding(.trailing, 10)
        }
        .onChange(of: data?.volume) { oldValue, newValue in
            if let newValue {
                withAnimation {
                    animatedVolume = CGFloat(newValue)
                }
            }
        }
        .onAppear {
            animatedVolume = CGFloat(data?.volume ?? 0)
        }
    }
    
    // 宽度计算器
    private func calculateWidth(for volume: CGFloat) -> CGFloat {
        let maxWidth = UIScreen.main.bounds.width / 2 - 15 // 假设单个TapeCellView的最大宽度
        return (volume / CGFloat(maxVolume)) * maxWidth
    }
    
}

// 单量格式化器
private func formatTapeVolume(_ volume: Int) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK", Double(volume) / 1000.0)
        } else {
            return "\(volume)"
        }
    }



#Preview {
    Comp_Tape()
}


