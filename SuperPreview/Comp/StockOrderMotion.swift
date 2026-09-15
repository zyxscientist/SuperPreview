//
//  StockOrderMotion.swift
//  SuperPreview
//
//  组件名称：下单页动效定义
//  简介：集中定义下单页转场、拖拽和反馈动画所需的运动参数。
//  用于：股票下单 Demo 及详情页快捷交易面板。
//

import SwiftUI

enum StockOrderMotion {
    static func expansion(reduceMotion: Bool) -> Animation? {
        reduceMotion
            ? nil
            : .spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.2)
    }
}
