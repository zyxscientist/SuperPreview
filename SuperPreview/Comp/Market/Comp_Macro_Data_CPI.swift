//
//  Comp_Macro_Data_CPI.swift
//  SuperPreview
//
//  Created by admin on 2024/10/15.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import SwiftUI

struct Comp_Macro_Data_CPI: View {
    
    @StateObject private var viewModel = MacroDataCPIViewModel()
    
    var body: some View {
        
        VStack(spacing: 0.0) {
            
            // 标题
            HStack{
                Text("美国CPI")
                    .foregroundStyle(Color(.colorText30))
                    .modifier(CustomFontModifier(size: 18, font: .medium))
                Spacer()
            }
            .padding(.top, 15)
            .padding(.horizontal, 15)
            .padding(.bottom, 10)
            
            // 发布时间
            HStack(spacing: 5.0){
                Text("发布时间:")
                    .foregroundStyle(Color(.colorText60))
                    .modifier(CustomFontModifier(size: 13, font: .regular))
                
                Text("2024/09/30")
                    .foregroundStyle(Color(.colorText60))
                    .modifier(CustomFontModifier(size: 13, font: .regular))
                
                Text("09:30")
                    .foregroundStyle(Color(.colorText60))
                    .modifier(CustomFontModifier(size: 13, font: .regular))
                
                Spacer()
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 15)
            
            
            // 数据栏
            HStack(spacing: 10){
                
                VStack(alignment: .leading, spacing: 5){
                    
                    Text("公布值")
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color(.colorText60))
                        .modifier(CustomFontModifier(size: 14, font: .regular))
                    Text("2.40%")
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color(.colorBrandBlue))
                        .modifier(CustomFontModifier(size: 16, font: .bold))
                }
                .frame(width:100, alignment: .leading)
                
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
                
                VStack(alignment: .leading, spacing: 5){
                    
                    Text("前值")
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color(.colorText60))
                        .modifier(CustomFontModifier(size: 14, font: .regular))
                    Text("2.20%")
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Color(.colorText30))
                        .modifier(CustomFontModifier(size: 16, font: .bold))
                }
                .frame(width:100, alignment: .leading)
                
                
                Spacer()
                
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 15)
            
            // 图表说明
            HStack(spacing: 20.0){
                
                // 第一个
                HStack(spacing: 5.5){
                    Capsule()
                        .foregroundColor(Color(.colorBrandBlue))
                        .frame(width: 10, height: 2)
                    
                    Text("公布值")
                        .foregroundStyle(Color(.colorText90))
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                }
                
                // 第二个
                HStack(spacing: 5.5){
                    Capsule()
                        .foregroundColor(Color(.colorText30))
                        .frame(width: 10, height: 2)
                    
                    Text("预测值")
                        .foregroundStyle(Color(.colorText90))
                        .modifier(CustomFontModifier(size: 13, font: .regular))
                }
                
                Spacer()
                
            }
            .padding(.horizontal, 15)
            
            
            // 图表部分
            GeometryReader { geometry in
                
                // 图层式叠加
                ZStack{
                    
                    // 添加月份标签（仅显示5个点）
                    ForEach(0..<5, id: \.self) { index in
                        yearLabel(for: index, in: geometry)
                    }
                    
                    // 添加CPI数值横轴（仅显示5条）
                    ForEach(0..<5, id: \.self) { index in
                        cpiValueLabel_h_axis(for: index, in: geometry)
                    }
                    
                    // 添加CPI预测值折线图
                    cpi_predict_LineChart(in: geometry)
                    
                    // 添加CPI实际值折线图
                    cpiLineChart(in: geometry)
                    
                    // 添加CPI数值（仅显示5个点）
                    ForEach(0..<5, id: \.self) { index in
                        cpiValueLabel(for: index, in: geometry)
                    }
                    
                }
            }
                .frame(height: 200)
            
        }
            .background(Color(.colorBase1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            // 描边
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(.colorSeparator10), lineWidth: 0.5)
            )
            .padding(.horizontal, 10)
            .shadow(color: Color.black.opacity(0.15), radius: 25, x: 0, y: 2)
        
    }
    
    // 年份标签布局方法
    private func yearLabel(for index: Int, in geometry: GeometryProxy) -> some View {
        

        let totalWidth = geometry.size.width - 30 // 总长
        let xStep = totalWidth / 4 // 等分横轴空间,并得出每等份的长度,由于是要打五5个点,所以要分四份
        let x: CGFloat // 日期的X坐标
        
        // 左右两极label定位
        if index == 0 {
            x = 25 // 最左的点
        } else if index == 4 {
            x = geometry.size.width - 29 // 最右的点
        } else {
            x = 15 + CGFloat(index) * xStep // 其余的点
        }
        
        let showIndex = round(Double(index) * Double(viewModel.data_cpi.count - 1) / 4)
        let dataIndex = min(viewModel.data_cpi.count - 1, Int(showIndex))
        
        return Text(monthString(from: dateFromString(viewModel.data_cpi[dataIndex].date)))
            .padding(0)
            .modifier(CustomFontModifier(size: 11, font: .regular))
            .foregroundColor(Color(.colorText90))
            .frame(width: 40)
            .position(x: x, y: 177)
    }
    
    // CPI横轴布局方法
    private func cpiValueLabel_h_axis (for index: Int, in geometry: GeometryProxy) -> some View {
        
        let y = 164 - CGFloat(index) * (164 - 20) / 4
        
        // 横轴
        return Path { path in
            path.move(to: CGPoint(x: 15, y: y))
            path.addLine(to: CGPoint(x: geometry.size.width - 15, y: y))
        }
        .stroke(Color(.colorScale2),
                style:StrokeStyle(
                    lineWidth: 0.5,
                    lineCap: .round,
                    dash: [3, 3]
                )
        ) // 使用较细的线条
    }
    
    // CPI折线图方法
    private func cpiLineChart(in geometry: GeometryProxy) -> some View {
        let maxValue = viewModel.data_cpi.map { $0.value }.max() ?? 0
        let minValue = viewModel.data_cpi.map { $0.value }.min() ?? 0
        let normalizedData = viewModel.data_cpi.map { CGFloat(($0.value - minValue) / (maxValue - minValue)) }
        
        return LineGraph(dataPoints: normalizedData)
            .stroke(Color(.colorBrandBlue),
                    style:StrokeStyle(
                        lineWidth: 1.5,
                        lineCap: .round
                    )
            )
            .frame(width: geometry.size.width - 30, height: 144)
            .position(x: geometry.size.width / 2, y: 92)
    }
    
    // CPI预测值折线图
    private func cpi_predict_LineChart(in geometry: GeometryProxy) -> some View {
        let maxValue = viewModel.data_predict_cpi.map { $0.value }.max() ?? 0
        let minValue = viewModel.data_predict_cpi.map { $0.value }.min() ?? 0
        let normalizedData = viewModel.data_predict_cpi.map { CGFloat(($0.value - minValue) / (maxValue - minValue)) }
        
        return LineGraph(dataPoints: normalizedData)
            .stroke(Color(.colorText30),
                    style:StrokeStyle(
                        lineWidth: 1.5,
                        lineCap: .round,
                        dash: [3, 4]
                    )
            )
            .frame(width: geometry.size.width - 30, height: 144)
            .position(x: geometry.size.width / 2, y: 92)
    }
    
    // CPI数值标签布局方法
    private func cpiValueLabel(for index: Int, in geometry: GeometryProxy) -> some View {
        let maxValue = viewModel.data_cpi.map { $0.value }.max() ?? 0
        let minValue = viewModel.data_cpi.map { $0.value }.min() ?? 0
        let valueRange = maxValue - minValue
        let step = valueRange / 4
        let value = minValue + step * Double(index)
        let y = 164 - CGFloat(index) * (164 - 20) / 4
        
        return Text(pecentageString(value))
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
private func monthString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy"
    return formatter.string(from: date)
}

// 辅助函数：值百分比化
private func pecentageString(_ value: Double) -> String {
    let percentage = (value/100)
    return String(format: "%.2f%%", percentage)
}


#Preview {
    Comp_Macro_Data_CPI()
}
