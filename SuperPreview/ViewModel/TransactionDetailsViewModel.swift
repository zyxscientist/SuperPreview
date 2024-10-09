//
//  TransactionDetailsViewModel.swift
//  SuperPreview
//
//  Created by admin on 2024/10/9.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import Foundation


class TransactionViewModel: ObservableObject {
    
    @Published var transactions: [TransactionDetailsCellData] = []
    
    private var lastTransactionTime: Date?
    
    init() {
        generateInitialData()
        startSimulatingDataPush()
    }
    
    
    private func generateInitialData() {
            
        let initialCount = 20 // 初始数据数量
            let currentTime = Date()
            
            for i in 0..<initialCount {
                let timeOffset = TimeInterval(-i * 60) // 每条数据间隔1分钟
                let transactionTime = currentTime.addingTimeInterval(timeOffset)
                let transaction = generateTransaction(at: transactionTime)
                transactions.append(transaction)
            }
            
            lastTransactionTime = currentTime
        }
    
    func startSimulatingDataPush() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.addNewTransaction()
        }
    }
    
    
    func addNewTransaction() {
        
        // 生成时间，且用DispatchQueue.main.async排序
        let currentTime = Date()
        let timeString = formatTime(currentTime)
        
        // 生成价格, 确保第三位小数为0
        let basePrice = Double.random(in: 15...18)
        let roundedPrice = (basePrice * 100).rounded() / 100  // 四舍五入到两位小数
        let priceString = String(format: "%.3f", roundedPrice)
        
        //生成成交量，且只有四位数以上用K修饰
        let volume = Int.random(in: 100...5000)
        let volumeString = formatVolume(volume)
        
        //生成类型
        let typeSymbol: TypeSymbol
            switch Int.random(in: 0...2) {
            case 0:
                typeSymbol = .buy
            case 1:
                typeSymbol = .sell
            default:
                typeSymbol = .neutral
            }
        
        
        // 数据汇总
        let newTransaction = TransactionDetailsCellData(
            time: timeString,
            price: priceString,
            volume: volumeString,
            typeSymbol: typeSymbol
        )
        
        // 主线程上异步执行排序
        DispatchQueue.main.async {
            
            
            if let lastTime = self.lastTransactionTime, currentTime <= lastTime {
                // 如果新生成的时间小于或等于上一条记录的时间,则将其插入到合适的位置
                let index = self.transactions.firstIndex { $0.time <= timeString } ?? 0
                self.transactions.insert(newTransaction, at: index)
            } else {
                // 如果新生成的时间大于上一条记录的时间,则插入到列表开头
                self.transactions.insert(newTransaction, at: 0)
            }
            
            self.lastTransactionTime = currentTime
            
            // 删除60条以外的数据
            if self.transactions.count > 60 {
                self.transactions.removeLast()
            }
        }
    }
    
    // 默认生成数据撑满视图
    private func generateTransaction(at date: Date) -> TransactionDetailsCellData {
        
        let timeString = formatTime(date)
        
        // 生成价格, 确保第三位小数为0
        let basePrice = Double.random(in: 15...18)
        let roundedPrice = (basePrice * 100).rounded() / 100  // 四舍五入到两位小数
        let priceString = String(format: "%.3f", roundedPrice)
        
        // 生成成交量，且只有四位数以上用K修饰
        let volume = Int.random(in: 100...5000)
        let volumeString = formatVolume(volume)
        
        // 生成类型
        let typeSymbol: TypeSymbol
            switch Int.random(in: 0...2) {
            case 0:
                typeSymbol = .buy
            case 1:
                typeSymbol = .sell
            default:
                typeSymbol = .neutral
            }
        
        return TransactionDetailsCellData(
            time: timeString,
            price: priceString,
            volume: volumeString,
            typeSymbol: typeSymbol
        )
    }
}
    

// 时间格式整理
private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

// 单量格式整理
private func formatVolume(_ volume: Int) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK", Double(volume) / 1000.0)
        } else {
            return String(volume)
        }
}



