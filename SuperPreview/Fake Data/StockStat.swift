//
//  StockStat.swift
//  SuperPreview
//
//  Created by admin on 2024/10/10.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import Foundation
import SwiftUI

struct StockStatData: Identifiable {
    var id = UUID()
    var title: String
    var subtag: String?
    var value: String
    var unit: String?
    var valueColor: Color
    
    init(title: String, subtag: String? = nil, value: String, unit: String? = nil, valueColor: Color = Color(.colorText30)) {
        self.title = title
        self.subtag = subtag
        self.value = value
        self.unit = unit
        self.valueColor = valueColor
    }
}


let stockstat = [
    
    StockStatData(title: "今开", value: "15.880", valueColor: Color(.colorUtility3Green)),
    StockStatData(title: "最高", value: "16.400", valueColor: Color(.colorUtility3Red)),
    StockStatData(title: "成交额", value: "4001.22", unit: "万", valueColor: Color(.colorText30)),
    StockStatData(title: "昨收", value: "16.100", valueColor: Color(.colorText30)),
    StockStatData(title: "最低", value: "15.880", valueColor: Color(.colorUtility3Green)),
    StockStatData(title: "成交量", value: "44.99", unit: "万股", valueColor: Color(.colorText30)),
    StockStatData(title: "市盈率", subtag: "TTM", value: "30.55", valueColor: Color(.colorText30)),
    StockStatData(title: "每手", value: "2000", unit: "股", valueColor: Color(.colorText30)),
    StockStatData(title: "换手率", value: "2.98%", valueColor: Color(.colorText30)),
    StockStatData(title: "市盈率", subtag: "静", value: "30.55", valueColor: Color(.colorText30)),
    StockStatData(title: "总市值", value: "610.99", unit: "亿", valueColor: Color(.colorText30)),
    StockStatData(title: "量比", value: "2.22", valueColor: Color(.colorText30)),
    StockStatData(title: "市净率", value: "30.55", valueColor: Color(.colorText30)),
    StockStatData(title: "总股本", value: "38.68", unit: "亿股", valueColor: Color(.colorText30)),
    StockStatData(title: "委比", value: "14.23%", valueColor: Color(.colorText30)),
    StockStatData(title: "52周最高", value: "17.320", valueColor: Color(.colorText30)),
    StockStatData(title: "流通市值", value: "610.99", unit: "亿", valueColor: Color(.colorText30)),
    StockStatData(title: "振幅", value: "2.98%", valueColor: Color(.colorText30)),
    StockStatData(title: "52周最低", value: "9.590", valueColor: Color(.colorText30)),
    StockStatData(title: "流通股", value: "38.68", unit: "亿股", valueColor: Color(.colorText30)),
    StockStatData(title: "平均价", value: "16.121", valueColor: Color(.colorText30)),
    StockStatData(title: "历史最高", value: "39.220", valueColor: Color(.colorText30)),
    StockStatData(title: "股息", subtag: "TTM",value: "1.11", valueColor: Color(.colorText30)),
    StockStatData(title: "股息", subtag: "LFY",value: "1.12", valueColor: Color(.colorText30)),
    StockStatData(title: "历史最低", value: "1.220", valueColor: Color(.colorText30)),
    StockStatData(title: "股息率", subtag: "TTM", value: "7.18%", valueColor: Color(.colorText30)),
    StockStatData(title: "股息率", subtag: "LFY", value: "7.19%", valueColor: Color(.colorText30))
    
]
