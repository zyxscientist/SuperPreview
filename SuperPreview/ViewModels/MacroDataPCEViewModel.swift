//
//  MacroDataPCEViewModel.swift
//  SuperPreview
//
//  Created by admin on 2024/10/17.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import Foundation

class MacroDataPCEViewModel: ObservableObject {
    
    @Published var data_pce: [PCEData] = []
    
    init(){
        generatePCEData(startYear: 2015, endYear: 2024)
    }
    
    // 生成过往 10 年的 PCE 数据
    private func generatePCEData(startYear: Int, endYear: Int){
        
        let baseValue = 309.0 // 初始值
        let peakValue = 550.0 // 峰值（2022年的剧烈上升达到的最高值）
        let lowValue = 190.0 // 最低值
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for year in startYear...endYear {
            for month in 1...12 {
                let day = month % 2 == 0 ? 14 : 12 // 假设2月和偶数月是14号，其他月份是12号
                let dateString = String(format: "%04d-%02d-%02d 00:00", year, month, day)
                
                var pceValue: Double
                
                if year < 2021 {
                    // 2014-2019: 平稳运行，波动较小
                    let randomVariation = Double.random(in: -2.0...19.0)
                    pceValue = baseValue + randomVariation
                    
                } else if year >= 2021 && year <= 2022 {
                    // 2020-2022: 剧烈上升，加入较大波动
                    let progress = Double((year - 2020) * 12 + month - 1) / Double((2022 - 2020 + 1) * 12)
                    pceValue = lowValue + progress * (peakValue - lowValue)
                    
                    let randomVariation = Double.random(in: -10.0...11.0) // 加大波动
                    pceValue += randomVariation
                    
                } else if year == 2023 {
                    // 2023: 平稳回落
                    let progress = Double((year - 2023) * 12 + month - 1) / Double(12)
                    pceValue = peakValue - progress * (peakValue - lowValue)
                    let randomVariation = Double.random(in: -20.0...18.0)
                    pceValue += randomVariation
                    
                } else {
                    // 2024及以后：保持平稳
                    let randomVariation = Double.random(in: -10.0...13.0)
                    pceValue = lowValue + randomVariation
                }
                
                // 保留三位小数
                pceValue = round(pceValue * 1000) / 1000
                
                let pceDataItem = PCEData(date: dateString, value: pceValue)
                data_pce.append(pceDataItem)

            }
        }
        
    }
    
}
