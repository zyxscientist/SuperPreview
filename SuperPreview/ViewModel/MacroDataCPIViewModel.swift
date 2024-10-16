//
//  Untitled.swift
//  SuperPreview
//
//  Created by admin on 2024/10/15.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import Foundation

class MacroDataCPIViewModel: ObservableObject {
    
    @Published var data_cpi: [CPIData] = []
    @Published var data_predict_cpi: [CPIData] = []
    
    init() {
        generateCPIData(startYear: 2015, endYear: 2024)
        generateCPIPredictData(startYear: 2015, endYear: 2024)
    }

    // 生成过往 10 年的 CPI 数据, 每次都不同
    private func generateCPIData(startYear: Int, endYear: Int){
        
        let baseValue = 299.0 // 初始值
        let peakValue = 510.0 // 峰值（2022年的剧烈上升达到的最高值）
        let lowValue = 230.0 // 最低值
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for year in startYear...endYear {
            for month in 1...12 {
                let day = month % 2 == 0 ? 14 : 12 // 假设2月和偶数月是14号，其他月份是12号
                let dateString = String(format: "%04d-%02d-%02d 00:00", year, month, day)
                
                var cpiValue: Double
                
                if year < 2021 {
                    // 2014-2019: 平稳运行，波动较小
                    let randomVariation = Double.random(in: -8.0...13.0)
                    cpiValue = baseValue + randomVariation
                    
                } else if year >= 2021 && year <= 2022 {
                    // 2020-2022: 剧烈上升，加入较大波动
                    let progress = Double((year - 2020) * 12 + month - 1) / Double((2022 - 2020 + 1) * 12)
                    cpiValue = lowValue + progress * (peakValue - lowValue)
                    
                    let randomVariation = Double.random(in: -10.0...11.0) // 加大波动
                    cpiValue += randomVariation
                    
                } else if year == 2023 {
                    // 2023: 平稳回落
                    let progress = Double((year - 2023) * 12 + month - 1) / Double(12)
                    cpiValue = peakValue - progress * (peakValue - lowValue)
                    let randomVariation = Double.random(in: -20.0...18.0)
                    cpiValue += randomVariation
                    
                } else {
                    // 2024及以后：保持平稳
                    let randomVariation = Double.random(in: -10.0...13.0)
                    cpiValue = lowValue + randomVariation
                }
                
                // 保留三位小数
                cpiValue = round(cpiValue * 1000) / 1000
                
                let cpiDataItem = CPIData(date: dateString, value: cpiValue) // 保留三位小数
                data_cpi.append(cpiDataItem)
                
                print("\(dateString)")
            }
        }
        
    }
    
    // 生成过往 10 年的 CPI 预测数据, 每次都不同
    private func generateCPIPredictData(startYear: Int, endYear: Int){
        
        let baseValue = 280.0 // 初始值
        let peakValue = 500.0 // 峰值（2022年的剧烈上升达到的最高值）
        let lowValue = 200.0 // 最低值
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for year in startYear...endYear {
            for month in 1...12 {
                let day = month % 2 == 0 ? 14 : 12 // 假设2月和偶数月是14号，其他月份是12号
                let dateString = String(format: "%04d-%02d-%02d 00:00", year, month, day)
                
                var cpiValue: Double
                
                if year < 2021 {
                    // 2014-2019: 平稳运行，波动较小
                    let randomVariation = Double.random(in: -8.0...13.0)
                    cpiValue = baseValue + randomVariation
                    
                } else if year >= 2021 && year <= 2022 {
                    // 2020-2022: 剧烈上升，加入较大波动
                    let progress = Double((year - 2020) * 12 + month - 1) / Double((2022 - 2020 + 1) * 12)
                    cpiValue = lowValue + progress * (peakValue - lowValue)
                    
                    let randomVariation = Double.random(in: -10.0...11.0) // 加大波动
                    cpiValue += randomVariation
                    
                } else if year == 2023 {
                    // 2023: 平稳回落
                    let progress = Double((year - 2023) * 12 + month - 1) / Double(12)
                    cpiValue = peakValue - progress * (peakValue - lowValue)
                    let randomVariation = Double.random(in: -20.0...18.0)
                    cpiValue += randomVariation
                    
                } else {
                    // 2024及以后：保持平稳
                    let randomVariation = Double.random(in: -10.0...13.0)
                    cpiValue = lowValue + randomVariation
                }
                
                // 保留三位小数
                cpiValue = round(cpiValue * 1000) / 1000
                
                let cpiDataItem = CPIData(date: dateString, value: cpiValue) // 保留三位小数
                data_predict_cpi.append(cpiDataItem)
                
                print("\(dateString)")
            }
        }
        
    }
    
}
