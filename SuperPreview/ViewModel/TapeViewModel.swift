//
//  TapeViewModel.swift
//  SuperPreview
//
//  Created by admin on 2024/9/30.
//  Copyright © 2024 PeterZ. All rights reserved.
//

import Foundation
import Combine

class TapeViewModel: ObservableObject {
    @Published var leftData: [TapeCellData] = []
    @Published var rightData: [TapeCellData] = []
    
    
    private var timer: AnyCancellable?
    
    init() {
        initializeData()
        startTimer()
    }
    
    private func initializeData() {
        leftData = (0..<10).map { _ in generateRandomData() }
        rightData = (0..<10).map { _ in generateRandomData() }
        sortData()
    }
    
    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateData()
            }
    }
    
    private func updateData() {
        leftData = leftData.map { _ in generateRandomData() }
        rightData = rightData.map { _ in generateRandomData() }
        sortData()
    }
    
    private func sortData() {
        leftData.sort{ $0.price > $1.price }
        rightData.sort{ $0.price < $1.price }
    }

    private func generateRandomData() -> TapeCellData {
        TapeCellData(
            price: Double.random(in: 20...22),
            volume: Int.random(in: 100...2000),
            brokerCount: Int.random(in: 50...300)
        )
    }
    
    func formatVolume(_ volume: Int) -> String {
        if volume >= 1000 {
            return String(format: "%.1fK", Double(volume) / 1000.0)
        } else {
            return "\(volume)"
        }
    }
}
