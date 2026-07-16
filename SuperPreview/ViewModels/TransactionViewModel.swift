//
//  TransactionViewModel.swift
//  SuperPreview
//
//  Created by admin on 2024/10/9.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import Foundation

enum TransactionPushFrequency: CaseIterable, Hashable, Identifiable {
    case low
    case medium
    case high
    case ultraFast

    var id: Self { self }

    var title: String {
        switch self {
        case .low:
            return "低"
        case .medium:
            return "中"
        case .high:
            return "高"
        case .ultraFast:
            return "极快"
        }
    }

    var timeInterval: TimeInterval {
        switch self {
        case .low:
            return 1.0
        case .medium:
            return 0.5
        case .high:
            return 0.1
        case .ultraFast:
            return 0.03
        }
    }

    var refreshAnimationDuration: TimeInterval {
        min(0.28, presentationInterval * 0.9)
    }

    var presentationInterval: TimeInterval {
        switch self {
        case .low:
            return 1.0
        case .medium:
            return 0.5
        case .high:
            return 0.2
        case .ultraFast:
            return 0.12
        }
    }

    var transactionsPerPresentation: Int {
        switch self {
        case .low, .medium:
            return 1
        case .high:
            return 2
        case .ultraFast:
            return 4
        }
    }
}

@MainActor
class TransactionViewModel: ObservableObject {

    @Published var transactions: [TransactionDetailsCellData] = []
    @Published var pushFrequency: TransactionPushFrequency = .medium {
        didSet {
            if isPlaying {
                startSimulationTimer()
            }
        }
    }
    @Published private(set) var isPlaying = false
    private(set) var latestPresentationCount = 0

    private var simulationTask: Task<Void, Never>?
    private var simulatedPushCount = 0
    private let simulatedPushLimit = 200
    private let maximumTransactionCount = 60
    private var isHistoryBrowsing = false

    init() {
        generateInitialData()
    }


    private func generateInitialData() {

        let initialCount = 20 // 初始数据数量
            let currentTime = Date()

            for i in (0..<initialCount).reversed() {
                let timeOffset = TimeInterval(-i * 60) // 每条数据间隔1分钟
                let transactionTime = currentTime.addingTimeInterval(timeOffset)
                let transaction = generateTransaction(at: transactionTime)
                transactions.append(transaction)
            }

        }

    func startSimulatingDataPush() {
        simulatedPushCount = 0
        latestPresentationCount = 0
        isPlaying = true
        startSimulationTimer()
    }

    func setHistoryBrowsing(_ isBrowsing: Bool) {
        guard isHistoryBrowsing != isBrowsing else { return }

        isHistoryBrowsing = isBrowsing

        if !isBrowsing {
            trimTransactionsToMaximumCount()
        }
    }

    private func startSimulationTimer() {
        simulationTask?.cancel()

        let frequency = pushFrequency
        let nanoseconds = UInt64(frequency.presentationInterval * 1_000_000_000)

        simulationTask = Task { [weak self] in
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: nanoseconds)
                } catch {
                    return
                }

                guard let self, self.isPlaying, !Task.isCancelled else { return }
                self.addNewTransactions(count: frequency.transactionsPerPresentation)
            }
        }
    }

    private func stopSimulatingDataPush() {
        simulationTask?.cancel()
        simulationTask = nil
        isPlaying = false
    }

    deinit {
        simulationTask?.cancel()
    }

    private func addNewTransactions(count: Int) {
        guard isPlaying else { return }

        let remainingCount = simulatedPushLimit - simulatedPushCount
        let batchCount = min(count, remainingCount)
        guard batchCount > 0 else {
            stopSimulatingDataPush()
            return
        }

        let latestDate = Date()
        let firstDate = latestDate.addingTimeInterval(
            -pushFrequency.timeInterval * Double(batchCount - 1)
        )
        let newTransactions = (0..<batchCount).map { index in
            generateTransaction(
                at: firstDate.addingTimeInterval(pushFrequency.timeInterval * Double(index))
            )
        }

        // 一次性提交完整数组，避免 append 和 trim 分别触发两轮 SwiftUI diff。
        var updatedTransactions = transactions
        updatedTransactions.append(contentsOf: newTransactions)

        if !isHistoryBrowsing, updatedTransactions.count > maximumTransactionCount {
            updatedTransactions.removeFirst(updatedTransactions.count - maximumTransactionCount)
        }

        latestPresentationCount = batchCount
        transactions = updatedTransactions
        simulatedPushCount += batchCount

        if simulatedPushCount >= simulatedPushLimit {
            stopSimulatingDataPush()
        }
    }

    private func trimTransactionsToMaximumCount() {
        guard transactions.count > maximumTransactionCount else { return }
        transactions = Array(transactions.suffix(maximumTransactionCount))
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
        let typeSymbol: TransactionTypeSymbol
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
private let transactionTimeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    return formatter
}()

private func formatTime(_ date: Date) -> String {
    return transactionTimeFormatter.string(from: date)
}

// 单量格式整理
private func formatVolume(_ volume: Int) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK", Double(volume) / 1000.0)
        } else {
            return String(volume)
        }
}
