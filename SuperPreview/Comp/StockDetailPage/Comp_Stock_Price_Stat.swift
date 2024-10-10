//
//  Comp_Stock_Price_Stat.swift
//  SuperPreview
//
//  Created by admin on 2024/10/10.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Stock_Price_Stat: View {
    
    let stockStats: [StockStatData]
    @State private var isExpanded = false
    @State private var blurAmount: CGFloat = 7
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing:0){
            
            // 第一个 LazyVGrid 显示前9个元素
            LazyVGrid(columns: columns, alignment: .leading, spacing: 5) {
                ForEach(Array(stockStats.prefix(9)), id: \.id) { stat in
                    StockStat(data: stat)
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 0)
            .padding(.horizontal, 15)
            
            // 第二个 LazyVGrid 显示剩余元素, 分开显示以实现展开时的模糊效果
                if stockStats.count > 9 {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 5) {
                        ForEach(Array(stockStats.dropFirst(9)), id: \.id) { stat in
                            StockStat(data: stat)
                                .opacity(isExpanded ? 1 : 0)
                                .blur(radius: blurAmount)
                        }
                    }
                    .padding(.top, 5)
                    .padding(.horizontal, 15)
                    .frame(height: isExpanded ? nil : 0, alignment: .top)
                }
            
            Image(.statExpandChevron)
                .resizable()
                .padding(.top, 1)
                .padding(.bottom, 0)
                .frame(width:16, height: 10)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        
        // 必须在这里顶bottom的距离
        .padding(.bottom, 2)
        .background(Color(.colorBase1))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        // 描边
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(.colorSeparator10), lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 2)
        .contentShape(Rectangle()) // 确保整个区域可点击
        .onTapGesture {
            HapticManager.instance.impactHaptic(type: .medium)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2)) {
                isExpanded.toggle()
                blurAmount = isExpanded ? 0 : 5
            }
        }
        
        Spacer()
    }
}

struct StockStat: View {
    
    let data: StockStatData
    
    var body: some View {
        HStack {
            HStack(alignment: .bottom, spacing:0) {
                
                // 标题
                Text(data.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(Color(.colorText60))
                    .modifier(CustomFontModifier(size: 13, font: .regular))
                
                //下标
                if let subtag = data.subtag {
                    Text(subtag)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color(.colorText60))
                        .modifier(CustomFontModifier(size: 8, font: .regular))
                }
                
            }
            .padding(0)
            
            Spacer()
            
            HStack(spacing: 0){
                
                //数值
                Text(data.value)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.trailing)
                // 有可能有红绿黑三种字色
                    .foregroundColor(Color(data.valueColor))
                    .modifier(CustomFontModifier(size: 13, font: .medium))
                
                //单位
                if let unit = data.unit{
                    Text(unit)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(Color(.colorText30))
                        .modifier(CustomFontModifier(size: 13, font: .medium))
                }
            }
            .padding(0)
        }
        
        // TODO: 修改为minwidth，目前只是看看单元格效果
        .frame(minWidth: 108)
    }
}

#Preview {
    Comp_Stock_Price_Stat(stockStats: stockstat)
}