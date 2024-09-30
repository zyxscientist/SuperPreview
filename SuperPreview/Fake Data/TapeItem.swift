//
//  TapeItem.swift
//  SuperPreview
//
//  Created by admin on 2024/9/30.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import Foundation

struct TapeCellData: Identifiable {
    let id = UUID()
    var price: Double
    var volume: Int
    var brokerCount: Int
}
