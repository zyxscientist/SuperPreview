//
//  HapticManager.swift
//  SuperPreview
//
//  Created by admin on 2023/1/11.
//  Copyright © 2023 PeterZ. All rights reserved.
//

import SwiftUI

class HapticManager {
    
    static let instance = HapticManager()
    
    // 通知类
    func notificationHaptic(type: UINotificationFeedbackGenerator.FeedbackType){
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    // 操作响应类
    func impactHaptic(type: UIImpactFeedbackGenerator.FeedbackStyle){
        let generator = UIImpactFeedbackGenerator(style: type)
        generator.impactOccurred()
    }
    
}
