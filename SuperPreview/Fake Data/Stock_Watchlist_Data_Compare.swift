//
//  Stock_Watchlist_Data_Compare.swift
//  SuperPreview
//
//  Created by 朱宇軒 on 2022/6/9.
//  Copyright © 2022 PeterZ. All rights reserved.
//

import Foundation


struct Stock_3: Identifiable {
    var id = UUID()
    var type_icon : String
    var name : String
    var symbol : String
    var alert : Bool
    var spark : String // no longer using
    var price : String
    var rate : String
    var direction : String
}


let stocks_compare = [

    Stock(type_icon: "Glyph_HK", name: "云锋金融", symbol: "00376(now)",alert : false, spark: "up_2", price: "16.680", rate: "+11.11%", direction: "color-utility-red"),
    Stock(type_icon: "Glyph_HK", name: "云锋金融", symbol: "00376(futu)",alert : false, spark: "up_2", price: "16.680", rate: "+11.11%", direction: "color-futu-red"),
    Stock(type_icon: "Glyph_HK", name: "云锋金融", symbol: "00376(new1)",alert : false, spark: "up_2", price: "16.680", rate: "+11.11%", direction: "color-utility2-red"),
    Stock(type_icon: "Glyph_HK", name: "云锋金融", symbol: "00376(new2)",alert : false, spark: "up_2", price: "16.680", rate: "+11.11%", direction: "color-utility3-red"),
    
    Stock(type_icon: "Glyph_HK", name: "小米集团-W", symbol: "01810(now)",alert : false, spark: "down_2", price: "12.680", rate: "-11.11%", direction: "color-utility-green"),
    Stock(type_icon: "Glyph_HK", name: "小米集团-W", symbol: "01810(futu)",alert : false, spark: "down_2", price: "12.680", rate: "-11.11%", direction: "color-futu-green"),
    Stock(type_icon: "Glyph_HK", name: "小米集团-W", symbol: "00376(new1)",alert : false, spark: "down_2", price: "12.680", rate: "-11.11%", direction: "color-utility2-green"),
    Stock(type_icon: "Glyph_HK", name: "小米集团-W", symbol: "00376(new2)",alert : false, spark: "down_2", price: "12.680", rate: "-11.11%", direction: "color-utility3-green"),
    
]
