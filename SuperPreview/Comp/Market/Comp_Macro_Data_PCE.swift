//
//  Comp_Macro_Data_PCE.swift
//  SuperPreview
//
//  Created by admin on 2024/10/17.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import SwiftUI
import Foundation

struct Comp_Macro_Data_PCE: View {
    
    @StateObject private var viewModel = MacroDataPCEViewModel()
       
       var body: some View {
               VStack(spacing: 0.0) {
                   
                   // 标题
                   HStack {
                       Text("美国PCE")
                           .foregroundStyle(Color(.colorText30))
                           .modifier(CustomFontModifier(size: 18, font: .medium))
                       Spacer()
                   }
                   .padding(.top, 15)
                   .padding(.horizontal, 15)
                   .padding(.bottom, 10)
                   
                   // 发布时间
                   HStack(spacing: 5.0) {
                       Text("发布时间:")
                           .foregroundStyle(Color(.colorText60))
                           .modifier(CustomFontModifier(size: 13, font: .regular))
                       
                       Text("2024/09/30")
                           .foregroundStyle(Color(.colorText60))
                           .modifier(CustomFontModifier(size: 13, font: .regular))
                       
                       Text("09:30")
                           .foregroundStyle(Color(.colorText60))
                           .modifier(CustomFontModifier(size: 13, font: .regular))
                       
                       Text("月公布")
                           .foregroundStyle(Color(.colorText60))
                           .modifier(CustomFontModifier(size: 13, font: .regular))
                       
                       Spacer()
                   }
                   .padding(.horizontal, 15)
                   .padding(.bottom, 15)
                   
                   // 数据栏
                   HStack(spacing: 10) {
                       VStack(alignment: .leading, spacing: 5) {
                           Text("公布值")
                               .multilineTextAlignment(.leading)
                               .foregroundStyle(Color(.colorText60))
                               .modifier(CustomFontModifier(size: 14, font: .regular))
                           Text("2.40%")
                               .multilineTextAlignment(.leading)
                               .foregroundStyle(Color(.colorBrandBlue))
                               .modifier(CustomFontModifier(size: 16, font: .bold))
                       }
                       .frame(width: 100, alignment: .leading)
                       
                       VStack(alignment: .leading, spacing: 5){
                           
                           Text("预测值")
                               .multilineTextAlignment(.leading)
                               .foregroundStyle(Color(.colorText60))
                               .modifier(CustomFontModifier(size: 14, font: .regular))
                           Text("2.30%")
                               .multilineTextAlignment(.leading)
                               .foregroundStyle(Color(.colorText30))
                               .modifier(CustomFontModifier(size: 16, font: .bold))
                       }
                       .frame(width:100, alignment: .leading)
                       
                       VStack(alignment: .leading, spacing: 5) {
                           Text("前值")
                               .multilineTextAlignment(.leading)
                               .foregroundStyle(Color(.colorText60))
                               .modifier(CustomFontModifier(size: 14, font: .regular))
                           Text("2.20%")
                               .multilineTextAlignment(.leading)
                               .foregroundStyle(Color(.colorText30))
                               .modifier(CustomFontModifier(size: 16, font: .bold))
                       }
                       .frame(width: 100, alignment: .leading)
                       
                       Spacer()
                   }
                   .padding(.horizontal, 15)
                   .padding(.bottom, 15)
                   
                   // 图表部分
                   GeometryReader { geometry in
                       ZStack {
                           // 添加月份标签（仅显示5个点）
                           ForEach(0..<5, id: \.self) { index in
                               yearLabel(for: index, in: geometry)
                           }
                           
                           // 添加PCE数值横轴（仅显示5条）
                           ForEach(0..<5, id: \.self) { index in
                               pceValueLabel_h_axis(for: index, in: geometry)
                           }
                           
                           // 添加PCE柱状图
                           pceBarChart(in: geometry)
                           
                           // 添加PCE数值（仅显示5个点）
                           ForEach(0..<5, id: \.self) { index in
                               pceValueLabel(for: index, in: geometry)
                           }
                       }
                   }
                   .frame(height: 200)
               }
               .background(Color(.colorBase1))
               .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
               .overlay(
                   RoundedRectangle(cornerRadius: 10, style: .continuous)
                       .stroke(Color(.colorSeparator10), lineWidth: 0.5)
               )
               .padding(.horizontal, 10)
               .shadow(color: Color.black.opacity(0.15), radius: 25, x: 0, y: 2)
       }
       
       // 年份标签布局方法
       private func yearLabel(for index: Int, in geometry: GeometryProxy) -> some View {
           let totalWidth = geometry.size.width - 30
           let xStep = totalWidth / 4
           let x: CGFloat
           
           if index == 0 {
               x = 25
           } else if index == 4 {
               x = geometry.size.width - 29
           } else {
               x = 15 + CGFloat(index) * xStep
           }
           
           let showIndex = round(Double(index) * Double(viewModel.data_pce.count - 1) / 4)
           let dataIndex = min(viewModel.data_pce.count - 1, Int(showIndex))
           
           return Text(monthString(from: dateFromString(viewModel.data_pce[dataIndex].date)))
               .padding(0)
               .modifier(CustomFontModifier(size: 11, font: .regular))
               .foregroundColor(Color(.colorText90))
               .frame(width: 40)
               .position(x: x, y: 177)
       }
       
       // PCE横轴布局方法
       private func pceValueLabel_h_axis(for index: Int, in geometry: GeometryProxy) -> some View {
           let y = 164 - CGFloat(index) * (164 - 20) / 4
           
           return Path { path in
               path.move(to: CGPoint(x: 15, y: y))
               path.addLine(to: CGPoint(x: geometry.size.width - 15, y: y))
           }
           .stroke(Color(.colorScale2),
                   style: StrokeStyle(
                       lineWidth: 0.5,
                       lineCap: .round,
                       dash: [3, 3]
                   )
           )
       }
       
       // PCE柱状图方法
       private func pceBarChart(in geometry: GeometryProxy) -> some View {
           
         
           
           let maxValue = viewModel.data_pce.map { $0.value }.max() ?? 0
           let minValue = 0.00
           let normalizedData = viewModel.data_pce.map { CGFloat(($0.value - minValue) / (maxValue - minValue)) }
           
           let totalWidth = geometry.size.width - 30
           let barCount = CGFloat(normalizedData.count)
           let barWidth = totalWidth / (barCount+barCount-1)
           
           
           return

                HStack(alignment:.bottom, spacing:0.0) {
                   ForEach(normalizedData.indices, id: \.self) { index in
                       Rectangle()
                           .fill(Color(.colorBrandBlue))
                           .frame(width: 2, height: max(normalizedData[index] * 144, 1))
                           .padding(.trailing, 1)
                   }
               }
               .frame(width: 239, height: 144)
               .position(x: geometry.size.width / 2, y: 92)
                
       }
    
    
       // PCE数值标签布局方法
       private func pceValueLabel(for index: Int, in geometry: GeometryProxy) -> some View {
           let maxValue = viewModel.data_pce.map { $0.value }.max() ?? 0
           let minValue = 0.00
           let valueRange = maxValue - minValue
           let step = valueRange / 4
           let value = step * Double(index)
           let y = 164 - CGFloat(index) * (164 - 20) / 4
           
           return Text(percentageString(value))
               .modifier(CustomFontModifier(size: 11, font: .regular))
               .foregroundColor(Color(.colorText60))
               .frame(width: 40, alignment: .leading)
               .position(x: 32, y: y)
       }
   }

// 辅助函数：将字符串转换为日期
private func dateFromString(_ dateString: String) -> Date {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter.date(from: dateString) ?? Date()
}

// 辅助函数：从日期获取月份字符串
private  func monthString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy"
    return formatter.string(from: date)
}

// 辅助函数：值百分比化
private  func percentageString(_ value: Double) -> String {
    let percentage = (value/100)
    return String(format: "%.2f%%", percentage)
}

#Preview {
    Comp_Macro_Data_PCE()
}
