//
//  OrderStatuManager.swift
//  SuperPreview
//
//  Created by admin on 2023/1/16.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import Foundation

func directionColor(direction: String) -> String {
    
    if direction == "买入" { // 返回方向颜色
        return "color-utility3-red"
    } else if direction == "卖出" {
        return "color-utility3-green"
    }
    
    return "No matching statu color"
}

func orderStatuIcon(orderStatuCode: Int) -> String { // 返回状态图标
    
    if orderStatuCode == 1 {
        return "order_processing"
    } else if orderStatuCode == 2 {
        return "deal"
    }
    
    return "Code has no statu"
}


func orderStatuString(orderStatuCode: Int) -> String { // 返回状态名
    
    if orderStatuCode == 1 {
        return "待成交"
    } else if orderStatuCode == 2 {
        return "已成交"
    }
    
    return "Code has no statu string name"
}
