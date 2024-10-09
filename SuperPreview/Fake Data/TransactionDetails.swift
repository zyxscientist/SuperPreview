//
//  TransactionDetails.swift
//  SuperPreview
//
//  Created by admin on 2024/10/9.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import Foundation
import SwiftUI

// 枚举类型使得 typeSymbol 参数能够同时带颜色和图标返回
enum TypeSymbol {
    case buy
    case sell
    case neutral
    
    var imageName: String {
        switch self {
        case .buy:
            return "direction_buy"
        case .sell:
            return "direction_sale"
        case .neutral:
            return "direction_neutral"
        }
    }
    
    var color: Color {
        switch self {
        case .buy:
            return Color(.colorUtility3Red)
        case .sell:
            return Color(.colorUtility3Green)
        case .neutral:
            return Color(.colorText90)  // 假设中性交易使用默认文本颜色
        }
    }
}

struct TransactionDetailsCellData: Identifiable, Equatable {
    let id = UUID()
    let time: String
    let price: String
    let volume: String
    let typeSymbol: TypeSymbol
}
