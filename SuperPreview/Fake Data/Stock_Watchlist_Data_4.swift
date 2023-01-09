//
//  Stock_Watchlist_Data_4.swift
//  SuperPreview
//
//  Created by 朱宇軒 on 2022/6/9.
//  Copyright © 2022 PeterZ. All rights reserved.
//

import Foundation

struct Stock_4: Identifiable {
    var id = UUID()
    var type_icon : String
    var name : String
    var symbol : String
    var alert : Bool
    var spark : String
    var price : String
    var rate : String
    var direction : String
}


let stocks_4 = [

    Stock(type_icon: "Glyph_HK", name: "云锋金融", symbol: "00376",alert : true, spark: "up_2", price: "16.680", rate: "+11.11%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_HK", name: "阿里巴巴-SW", symbol: "09988",alert : false, spark: "up_4", price: "266.880", rate: "+10.00%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_US", name: "特斯拉", symbol: "TSLA",alert : false, spark: "down_3", price: "244.440", rate: "-2.21%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_HK", name: "腾讯控股", symbol: "00700",alert : false, spark: "up_3", price: "555.550", rate: "+4.10%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_SZ", name: "美的集团", symbol: "000333",alert : false, spark: "up_4", price: "61.48", rate: "+0.12%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_SZ", name: "歌尔股份", symbol: "002241",alert : false, spark: "down_2", price: "33.48", rate: "-1.20%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_US", name: "苹果", symbol: "AAPL",alert : true, spark: "down_4", price: "160.481", rate: "-10.00%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_US", name: "微软", symbol: "MSFT",alert : false, spark: "up_3", price: "290.211", rate: "+1.20%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_US", name: "三倍做多标普500ETF-ProShare", symbol: "UPRO",alert : false, spark: "up_2", price: "89.481", rate: "+3.10%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_US", name: "纳斯达克三倍做多ETF-ProShare", symbol: "TQQQ",alert : false, spark: "up_1", price: "149.483", rate: "+12.10%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_SH", name: "科兴制药", symbol: "688136",alert : false, spark: "up_4", price: "33.48", rate: "+21.19%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_US", name: "拼多多", symbol: "PDD",alert : false, spark: "up_3", price: "63.484", rate: "+1.20%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_US", name: "ADOBE", symbol: "ADBE",alert : false, spark: "up_1", price: "333.481", rate: "+0.10%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_US", name: "Snowflake", symbol: "SNOW",alert : false, spark: "down_2", price: "33.282", rate: "-1.02%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_SH", name: "贵州茅台", symbol: "600519",alert : false, spark: "up_2", price: "1733.08", rate: "+1.23%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_SH", name: "海天味业", symbol: "603288",alert : false, spark: "up_3", price: "133.01", rate: "+10.00%", direction: "color-utility3-green"),
    Stock(type_icon: "Glyph_SZ", name: "顺丰控股", symbol: "002352",alert : false, spark: "up_4", price: "66.22", rate: "+1.19%", direction: "color-utility3-green"),
    
]


