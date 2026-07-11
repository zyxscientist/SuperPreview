//
//  WatchlistRedesignViewModel.swift
//  SuperPreview
//
//  Created by Codex on 2026/07/01.
//  Copyright © 2026 PeterZ. All rights reserved.
//

import Foundation
import SwiftUI

enum WatchlistRedesignMarket {
    case hk
    case cn
    case us
    case crypto
    case fund
}

enum WatchlistRedesignTrend {
    case up
    case down
    case flat
}

enum WatchlistRedesignSession {
    case regular
    case preMarket(label: String, change: String)
    case afterHours(label: String, change: String)
}

struct WatchlistRedesignItem: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
    let market: WatchlistRedesignMarket
    let price: String
    let secondaryPrice: String?
    let changePercent: String
    let trend: WatchlistRedesignTrend
    let session: WatchlistRedesignSession
    let miniKPoints: [CGFloat]
    let tagAssets: [String]
    let isTinted: Bool
}

class WatchlistRedesignViewModel: ObservableObject {
    @Published var selectedTab = "全部"

    let tabs = ["全部", "港股", "沪深", "美股", "ETFs", "自定义"]
    private let groupedItems: [String: [WatchlistRedesignItem]]

    var items: [WatchlistRedesignItem] {
        items(for: selectedTab)
    }

    init() {
        let upLine = WatchlistRedesignViewModel.makeMiniKPoints(rising: true)
        let downLine = WatchlistRedesignViewModel.makeMiniKPoints(rising: false)
        let flatLine = Array(repeating: CGFloat(0.5), count: 50)

        let hkItems = [
            WatchlistRedesignItem(
                name: "阿里巴巴-W",
                symbol: "09988",
                market: .hk,
                price: "118.600",
                secondaryPrice: nil,
                changePercent: "2.36%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: ["price_alert"],
                isTinted: true
            ),
            WatchlistRedesignItem(
                name: "腾讯控股",
                symbol: "00700",
                market: .hk,
                price: "382.400",
                secondaryPrice: nil,
                changePercent: "1.18%",
                trend: .down,
                session: .regular,
                miniKPoints: downLine,
                tagAssets: [],
                isTinted: true
            ),
            WatchlistRedesignItem(
                name: "小米集团-W",
                symbol: "01810",
                market: .hk,
                price: "18.720",
                secondaryPrice: nil,
                changePercent: "0.00%",
                trend: .flat,
                session: .regular,
                miniKPoints: flatLine,
                tagAssets: [],
                isTinted: true
            ),
            WatchlistRedesignItem(
                name: "美团-W",
                symbol: "03690",
                market: .hk,
                price: "93.850",
                secondaryPrice: nil,
                changePercent: "3.42%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isTinted: false
            )
        ]

        let cnItems = [
            WatchlistRedesignItem(
                name: "宁德时代",
                symbol: "300750",
                market: .cn,
                price: "189.61",
                secondaryPrice: nil,
                changePercent: "1.66%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isTinted: true
            ),
            WatchlistRedesignItem(
                name: "贵州茅台",
                symbol: "600519",
                market: .cn,
                price: "1518.20",
                secondaryPrice: nil,
                changePercent: "0.74%",
                trend: .down,
                session: .regular,
                miniKPoints: downLine,
                tagAssets: [],
                isTinted: true
            ),
            WatchlistRedesignItem(
                name: "比亚迪",
                symbol: "002594",
                market: .cn,
                price: "251.08",
                secondaryPrice: nil,
                changePercent: "2.91%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isTinted: false
            ),
            WatchlistRedesignItem(
                name: "招商银行",
                symbol: "600036",
                market: .cn,
                price: "39.44",
                secondaryPrice: nil,
                changePercent: "0.00%",
                trend: .flat,
                session: .regular,
                miniKPoints: flatLine,
                tagAssets: [],
                isTinted: false
            )
        ]

        let usItems = [
            WatchlistRedesignItem(
                name: "英伟达",
                symbol: "NVDA",
                market: .us,
                price: "142.610",
                secondaryPrice: "142.610",
                changePercent: "11.23%",
                trend: .up,
                session: .afterHours(label: "盘后", change: "+0.23%"),
                miniKPoints: upLine,
                tagAssets: [],
                isTinted: false
            ),
            WatchlistRedesignItem(
                name: "苹果",
                symbol: "AAPL",
                market: .us,
                price: "212.450",
                secondaryPrice: "212.450",
                changePercent: "0.86%",
                trend: .up,
                session: .preMarket(label: "盘前", change: "+0.23%"),
                miniKPoints: upLine,
                tagAssets: [],
                isTinted: false
            ),
            WatchlistRedesignItem(
                name: "特斯拉",
                symbol: "TSLA",
                market: .us,
                price: "179.240",
                secondaryPrice: "179.240",
                changePercent: "4.18%",
                trend: .down,
                session: .regular,
                miniKPoints: downLine,
                tagAssets: [],
                isTinted: false
            ),
            WatchlistRedesignItem(
                name: "微软",
                symbol: "MSFT",
                market: .us,
                price: "428.020",
                secondaryPrice: "428.020",
                changePercent: "0.00%",
                trend: .flat,
                session: .regular,
                miniKPoints: flatLine,
                tagAssets: [],
                isTinted: false
            )
        ]

        let etfItems = [
            WatchlistRedesignItem(
                name: "恒生科技ETF",
                symbol: "03032",
                market: .hk,
                price: "4.812",
                secondaryPrice: nil,
                changePercent: "2.02%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isTinted: false
            ),
            WatchlistRedesignItem(
                name: "纳指100ETF",
                symbol: "513100",
                market: .cn,
                price: "1.482",
                secondaryPrice: nil,
                changePercent: "0.61%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isTinted: false
            ),
            WatchlistRedesignItem(
                name: "贝莱德世界能源基金",
                symbol: "LU012376428",
                market: .fund,
                price: "16.920",
                secondaryPrice: nil,
                changePercent: "0.01%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isTinted: false
            ),
            WatchlistRedesignItem(
                name: "先锋标普500ETF",
                symbol: "VOO",
                market: .us,
                price: "512.330",
                secondaryPrice: "512.330",
                changePercent: "0.38%",
                trend: .down,
                session: .regular,
                miniKPoints: downLine,
                tagAssets: [],
                isTinted: false
            )
        ]

        let customItems = [
            WatchlistRedesignItem(
                name: "比特币/美元",
                symbol: "BTC/USD",
                market: .crypto,
                price: "66666.61",
                secondaryPrice: nil,
                changePercent: "6.66%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isTinted: true
            ),
            WatchlistRedesignItem(
                name: "以太坊/美元",
                symbol: "ETH/USD",
                market: .crypto,
                price: "3468.82",
                secondaryPrice: nil,
                changePercent: "2.14%",
                trend: .down,
                session: .regular,
                miniKPoints: downLine,
                tagAssets: [],
                isTinted: true
            ),
            WatchlistRedesignItem(
                name: "阿里巴巴",
                symbol: "BABA",
                market: .us,
                price: "86.210",
                secondaryPrice: "86.210",
                changePercent: "1.03%",
                trend: .up,
                session: .afterHours(label: "盘后", change: "+0.08%"),
                miniKPoints: upLine,
                tagAssets: ["price_alert"],
                isTinted: false
            ),
            WatchlistRedesignItem(
                name: "安硕中国大盘ETF",
                symbol: "FXI",
                market: .us,
                price: "27.650",
                secondaryPrice: "27.650",
                changePercent: "0.00%",
                trend: .flat,
                session: .regular,
                miniKPoints: flatLine,
                tagAssets: [],
                isTinted: false
            )
        ]

        groupedItems = [
            "全部": hkItems + cnItems + usItems + etfItems + customItems,
            "港股": hkItems,
            "沪深": cnItems,
            "美股": usItems,
            "ETFs": etfItems,
            "自定义": customItems
        ]
    }

    func items(for tab: String) -> [WatchlistRedesignItem] {
        groupedItems[tab] ?? []
    }

    private static func makeMiniKPoints(rising: Bool) -> [CGFloat] {
        let upPoints: [CGFloat] = [
            0.000000, 0.072914, 0.257300, 0.218146, 0.208289, 0.279614,
            0.308686, 0.345496, 0.203411, 0.125989, 0.065111, 0.222525,
            0.142825, 0.160539, 0.087211, 0.176604, 0.162268, 0.131454,
            0.035821, 0.075500, 0.053554, 0.147789, 0.181346, 0.302982,
            0.356718, 0.380536, 0.221968, 0.138836, 0.224436, 0.223861,
            0.378339, 0.421346, 0.371936, 0.487039, 0.422918, 0.522929,
            0.572368, 0.639593, 0.763907, 0.827962, 0.782095, 0.851145,
            0.876789, 0.773415, 0.923136, 1.000000, 0.926466, 0.927486,
            0.905137, 0.993134, 0.965814
        ]

        let downPoints: [CGFloat] = [
            1.000000, 0.927084, 0.742700, 0.781855, 0.791713, 0.720387,
            0.691314, 0.654502, 0.796590, 0.874009, 0.934891, 0.777473,
            0.857176, 0.839461, 0.912790, 0.823395, 0.837732, 0.868545,
            0.964180, 0.924502, 0.946445, 0.852212, 0.818655, 0.697019,
            0.643282, 0.619464, 0.778033, 0.861164, 0.775564, 0.776139,
            0.621661, 0.578654, 0.628064, 0.512961, 0.577082, 0.477071,
            0.427632, 0.360407, 0.236093, 0.172039, 0.217904, 0.148854,
            0.123211, 0.226586, 0.076864, 0.000000, 0.073532, 0.072514,
            0.094864, 0.006864, 0.034186
        ]

        if rising {
            return upPoints
        } else {
            return downPoints
        }
    }
}
