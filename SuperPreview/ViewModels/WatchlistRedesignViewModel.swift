//
//  WatchlistRedesignViewModel.swift
//  SuperPreview
//
//  Created by Codex on 2026/07/01.
//  Copyright © 2026 PeterZ. All rights reserved.
//

import Foundation
import SwiftUI

enum WatchlistRedesignMarket: String, Hashable {
    case hk
    case cn
    case us
    case crypto
    case fund
}

enum WatchlistRedesignTagAsset {
    static let delayQuote = "watchlist_tag_delay_quote"
    static let specialAttention = "watchlist_tag_special_attention"
    static let holdings = "watchlist_tag_holdings"
    static let alert = "price_alert"
    static let financialReport = "watchlist_tag_financial_report"
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

enum WatchlistRedesignUSMarketPhase: Equatable {
    case preMarket
    case regular
    case afterHours
}

/// The exchange's actual phase. The watchlist deliberately maps `.closed` to
/// its carry-forward after-hours visual, while detail pages retain `.closed`.
enum USMarketTradingPhase: Hashable {
    case preMarket
    case regular
    case afterHours
    case closed

    var watchlistVisualPhase: WatchlistRedesignUSMarketPhase {
        switch self {
        case .preMarket:
            .preMarket
        case .regular:
            .regular
        case .afterHours, .closed:
            .afterHours
        }
    }
}

/// Nasdaq's current U.S. equity schedule as of September 2026. `Date` is an
/// absolute moment, so converting it with this fixed exchange timezone keeps
/// the UI correct regardless of the device's configured timezone.
enum USMarketSchedule {
    private struct MarketDate: Hashable {
        let year: Int
        let month: Int
        let day: Int
    }

    private static let easternTimeZone = TimeZone(identifier: "America/New_York")!
    private static let easternCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = easternTimeZone
        return calendar
    }()
    private static let preMarketOpenMinutes = 4 * 60
    private static let regularOpenMinutes = 9 * 60 + 30
    private static let regularCloseMinutes = 16 * 60
    private static let afterHoursCloseMinutes = 20 * 60

    // Nasdaq's published 2026 U.S. market closures.
    private static let closedDates: Set<MarketDate> = [
        .init(year: 2026, month: 1, day: 1),
        .init(year: 2026, month: 1, day: 19),
        .init(year: 2026, month: 2, day: 16),
        .init(year: 2026, month: 4, day: 3),
        .init(year: 2026, month: 5, day: 25),
        .init(year: 2026, month: 6, day: 19),
        .init(year: 2026, month: 7, day: 3),
        .init(year: 2026, month: 9, day: 7),
        .init(year: 2026, month: 11, day: 26),
        .init(year: 2026, month: 12, day: 25)
    ]

    private static let earlyCloseDates: Set<MarketDate> = [
        .init(year: 2026, month: 11, day: 27),
        .init(year: 2026, month: 12, day: 24)
    ]

    static func tradingPhase(at date: Date) -> USMarketTradingPhase {
        let components = easternCalendar.dateComponents(
            [.year, .month, .day, .weekday, .hour, .minute],
            from: date
        )
        guard
            let year = components.year,
            let month = components.month,
            let day = components.day,
            let weekday = components.weekday,
            let hour = components.hour,
            let minute = components.minute
        else {
            return .closed
        }

        let marketDate = MarketDate(year: year, month: month, day: day)
        let isWeekend = weekday == 1 || weekday == 7
        guard !isWeekend, !closedDates.contains(marketDate) else {
            return .closed
        }

        let minutesAfterMidnight = hour * 60 + minute
        let closeMinutes = earlyCloseDates.contains(marketDate) ? 13 * 60 : regularCloseMinutes

        if minutesAfterMidnight < preMarketOpenMinutes {
            return .closed
        }
        if minutesAfterMidnight < regularOpenMinutes {
            return .preMarket
        }
        if minutesAfterMidnight < closeMinutes {
            return .regular
        }
        if minutesAfterMidnight < afterHoursCloseMinutes {
            return .afterHours
        }

        return .closed
    }

    static func easternTimestamp(at date: Date) -> (date: String, time: String) {
        let components = easternCalendar.dateComponents(
            [.month, .day, .hour, .minute, .second],
            from: date
        )

        return (
            date: String(format: "%02d/%02d", components.month ?? 1, components.day ?? 1),
            time: String(
                format: "%02d:%02d:%02d",
                components.hour ?? 0,
                components.minute ?? 0,
                components.second ?? 0
            )
        )
    }

    /// Returns the most recent completed regular-session close at or before
    /// `date`. After the exchange is closed, quote timestamps should remain
    /// anchored to this close instead of behaving like a live clock.
    static func lastRegularCloseTimestamp(at date: Date) -> (date: String, time: String) {
        var candidate = date

        for _ in 0..<366 {
            let components = easternCalendar.dateComponents(
                [.year, .month, .day, .weekday],
                from: candidate
            )
            guard
                let year = components.year,
                let month = components.month,
                let day = components.day,
                let weekday = components.weekday
            else {
                break
            }

            let marketDate = MarketDate(year: year, month: month, day: day)
            let isWeekend = weekday == 1 || weekday == 7
            let isClosedDate = closedDates.contains(marketDate)

            if !isWeekend && !isClosedDate {
                let closeHour = earlyCloseDates.contains(marketDate) ? 13 : 16
                let closeDate = easternCalendar.date(
                    from: DateComponents(
                        year: year,
                        month: month,
                        day: day,
                        hour: closeHour,
                        minute: 0,
                        second: 0
                    )
                )!

                if closeDate <= date {
                    return easternTimestamp(at: closeDate)
                }
            }

            guard let previousDay = easternCalendar.date(byAdding: .day, value: -1, to: candidate) else {
                break
            }
            candidate = previousDay
        }

        return (date: "--/--", time: "16:00:00")
    }
}

enum WatchlistRedesignPriceSimulationSpeed: String, CaseIterable, Identifiable {
    case slow
    case medium
    case fast
    case mixed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .slow:
            return "慢"
        case .medium:
            return "中"
        case .fast:
            return "快"
        case .mixed:
            return "混合"
        }
    }

    var nextInterval: TimeInterval {
        switch self {
        case .slow:
            return Double.random(in: 1.4...2.4)
        case .medium:
            return Double.random(in: 0.6...1.2)
        case .fast:
            return Double.random(in: 0.18...0.45)
        case .mixed:
            return [WatchlistRedesignPriceSimulationSpeed.slow, .medium, .fast].randomElement()?.nextInterval ?? WatchlistRedesignPriceSimulationSpeed.medium.nextInterval
        }
    }

    var initialDelay: TimeInterval {
        switch self {
        case .slow:
            return Double.random(in: 0...1.4)
        case .medium:
            return Double.random(in: 0...0.6)
        case .fast:
            return Double.random(in: 0...0.25)
        case .mixed:
            return Double.random(in: 0...1.2)
        }
    }
}

struct WatchlistRedesignItem: Identifiable {
    let name: String
    let symbol: String
    let market: WatchlistRedesignMarket
    let instrumentKind: StockDetailInstrumentKind
    var price: String
    var secondaryPrice: String?
    var changePercent: String
    var trend: WatchlistRedesignTrend
    var session: WatchlistRedesignSession
    let extendedHoursChange: String
    let miniKPoints: [CGFloat]
    var tagAssets: [String]
    let isPinned: Bool

    init(
        name: String,
        symbol: String,
        market: WatchlistRedesignMarket,
        instrumentKind: StockDetailInstrumentKind = .stock,
        price: String,
        secondaryPrice: String?,
        changePercent: String,
        trend: WatchlistRedesignTrend,
        session: WatchlistRedesignSession,
        miniKPoints: [CGFloat],
        tagAssets: [String],
        isPinned: Bool
    ) {
        self.name = name
        self.symbol = symbol
        self.market = market
        self.instrumentKind = instrumentKind
        self.price = price
        self.secondaryPrice = secondaryPrice
        self.changePercent = changePercent
        self.trend = trend
        self.session = session
        self.extendedHoursChange = session.extendedHoursChange ?? Self.defaultExtendedHoursChange(for: trend)
        self.miniKPoints = miniKPoints
        self.tagAssets = tagAssets
        self.isPinned = isPinned
    }

    var id: String {
        "\(market.rawValue):\(symbol)"
    }

    var isShowingExtendedHoursVisual: Bool {
        guard market == .us else { return false }

        switch session {
        case .regular:
            return false
        case .preMarket, .afterHours:
            return true
        }
    }

    var displayedSecondaryPrice: String? {
        guard isShowingExtendedHoursVisual else { return nil }
        return secondaryPrice ?? price
    }

    private static func defaultExtendedHoursChange(for trend: WatchlistRedesignTrend) -> String {
        switch trend {
        case .up:
            return "+0.12%"
        case .down:
            return "-0.12%"
        case .flat:
            return "0.00%"
        }
    }
}

class WatchlistRedesignViewModel: ObservableObject {
    @Published var selectedTab = "全部"
    @Published private var groupedItems: [String: [WatchlistRedesignItem]] = [:]
    private var usMarketPhase: WatchlistRedesignUSMarketPhase?

    let tabs = ["全部", "港股", "沪深", "美股", "ETFs", "自定义"]

    var items: [WatchlistRedesignItem] {
        items(for: selectedTab)
    }

    init() {
        let upLine = WatchlistRedesignViewModel.makeMiniKPoints(rising: true)
        let downLine = WatchlistRedesignViewModel.makeMiniKPoints(rising: false)
        let flatLine = Array(repeating: CGFloat(0.5), count: 50)

        // Three arbitrary pinned examples; pinning is independent from the
        // market ordering applied to the "全部" group below.
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
                tagAssets: [WatchlistRedesignTagAsset.alert],
                isPinned: true
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
                isPinned: false
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
                isPinned: false
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
                isPinned: false
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
                isPinned: false
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
                isPinned: true
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
                isPinned: false
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
                isPinned: false
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
                isPinned: false
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
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "特斯拉",
                symbol: "TSLA",
                market: .us,
                price: "179.240",
                secondaryPrice: nil,
                changePercent: "4.18%",
                trend: .down,
                session: .regular,
                miniKPoints: downLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "微软",
                symbol: "MSFT",
                market: .us,
                price: "428.020",
                secondaryPrice: nil,
                changePercent: "0.00%",
                trend: .flat,
                session: .regular,
                miniKPoints: flatLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "亚马逊",
                symbol: "AMZN",
                market: .us,
                price: "228.150",
                secondaryPrice: nil,
                changePercent: "1.42%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isPinned: true
            ),
            WatchlistRedesignItem(
                name: "谷歌-A",
                symbol: "GOOGL",
                market: .us,
                price: "202.470",
                secondaryPrice: "202.470",
                changePercent: "0.68%",
                trend: .up,
                session: .afterHours(label: "盘后", change: "+0.11%"),
                miniKPoints: upLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "Meta",
                symbol: "META",
                market: .us,
                price: "518.420",
                secondaryPrice: nil,
                changePercent: "2.17%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "博通",
                symbol: "AVGO",
                market: .us,
                price: "178.620",
                secondaryPrice: "178.620",
                changePercent: "1.05%",
                trend: .down,
                session: .afterHours(label: "盘后", change: "-0.08%"),
                miniKPoints: downLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "AMD",
                symbol: "AMD",
                market: .us,
                price: "164.880",
                secondaryPrice: nil,
                changePercent: "3.26%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "奈飞",
                symbol: "NFLX",
                market: .us,
                price: "689.120",
                secondaryPrice: "689.120",
                changePercent: "0.94%",
                trend: .up,
                session: .preMarket(label: "盘前", change: "+0.16%"),
                miniKPoints: upLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "摩根大通",
                symbol: "JPM",
                market: .us,
                price: "214.340",
                secondaryPrice: nil,
                changePercent: "0.38%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "沃尔玛",
                symbol: "WMT",
                market: .us,
                price: "102.760",
                secondaryPrice: nil,
                changePercent: "0.00%",
                trend: .flat,
                session: .regular,
                miniKPoints: flatLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "可口可乐",
                symbol: "KO",
                market: .us,
                price: "70.180",
                secondaryPrice: nil,
                changePercent: "0.52%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "迪士尼",
                symbol: "DIS",
                market: .us,
                price: "112.430",
                secondaryPrice: nil,
                changePercent: "1.31%",
                trend: .down,
                session: .regular,
                miniKPoints: downLine,
                tagAssets: [],
                isPinned: false
            )
        ]

        let etfItems = [
            WatchlistRedesignItem(
                name: "恒生科技ETF",
                symbol: "03032",
                market: .hk,
                instrumentKind: .etf,
                price: "4.812",
                secondaryPrice: nil,
                changePercent: "2.02%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "纳指100ETF",
                symbol: "513100",
                market: .cn,
                instrumentKind: .etf,
                price: "1.482",
                secondaryPrice: nil,
                changePercent: "0.61%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "贝莱德世界能源基金",
                symbol: "LU012376428",
                market: .fund,
                instrumentKind: .fund,
                price: "16.920",
                secondaryPrice: nil,
                changePercent: "0.01%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "先锋标普500ETF",
                symbol: "VOO",
                market: .us,
                instrumentKind: .etf,
                price: "512.330",
                secondaryPrice: "512.330",
                changePercent: "0.38%",
                trend: .down,
                session: .afterHours(label: "盘后", change: "-0.04%"),
                miniKPoints: downLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "纳指100ETF",
                symbol: "QQQ",
                market: .us,
                instrumentKind: .etf,
                price: "473.180",
                secondaryPrice: "473.180",
                changePercent: "0.52%",
                trend: .up,
                session: .preMarket(label: "盘前", change: "+0.07%"),
                miniKPoints: upLine,
                tagAssets: [],
                isPinned: false
            )
        ]

        let customItems = [
            WatchlistRedesignItem(
                name: "比特币/美元",
                symbol: "BTC/USD",
                market: .crypto,
                instrumentKind: .crypto,
                price: "66666.61",
                secondaryPrice: nil,
                changePercent: "6.66%",
                trend: .up,
                session: .regular,
                miniKPoints: upLine,
                tagAssets: [],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "以太坊/美元",
                symbol: "ETH/USD",
                market: .crypto,
                instrumentKind: .crypto,
                price: "3468.82",
                secondaryPrice: nil,
                changePercent: "2.14%",
                trend: .down,
                session: .regular,
                miniKPoints: downLine,
                tagAssets: [],
                isPinned: false
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
                tagAssets: [WatchlistRedesignTagAsset.alert],
                isPinned: false
            ),
            WatchlistRedesignItem(
                name: "安硕中国大盘ETF",
                symbol: "FXI",
                market: .us,
                instrumentKind: .etf,
                price: "27.650",
                secondaryPrice: "27.650",
                changePercent: "0.00%",
                trend: .up,
                session: .preMarket(label: "盘前", change: "+0.03%"),
                miniKPoints: upLine,
                tagAssets: [],
                isPinned: false
            )
        ]

        let taggedHKItems = hkItems.map { Self.applyingRandomizedTags(to: $0) }
        let taggedCNItems = cnItems.map { Self.applyingRandomizedTags(to: $0) }
        let taggedUSItems = usItems.map { Self.applyingRandomizedTags(to: $0) }
        let taggedETFItems = etfItems.map { Self.applyingRandomizedTags(to: $0) }
        let taggedCustomItems = customItems.map { Self.applyingRandomizedTags(to: $0) }

        let allItems = taggedHKItems + taggedCNItems + taggedUSItems + taggedETFItems + taggedCustomItems
        // Some US-listed ETFs and ADRs live in the ETF/custom groups, so sort
        // by market here to keep every US-listed instrument together at the top.
        let allItemsWithUSFirst = allItems.filter { $0.market == .us } + allItems.filter { $0.market != .us }

        groupedItems = [
            "全部": allItemsWithUSFirst,
            "港股": taggedHKItems,
            "沪深": taggedCNItems,
            "美股": taggedUSItems,
            "ETFs": taggedETFItems,
            "自定义": taggedCustomItems
        ]

        refreshUSMarketSessions()
    }

    func refreshUSMarketSessions(now: Date = Date()) {
        let nextPhase = USMarketSchedule.tradingPhase(at: now).watchlistVisualPhase
        guard nextPhase != usMarketPhase else { return }

        usMarketPhase = nextPhase
        groupedItems = groupedItems.mapValues { items in
            items.map { item in
                guard item.market == .us else { return item }

                var updatedItem = item
                updatedItem.session = .forUSMarketPhase(nextPhase, change: item.extendedHoursChange)
                return updatedItem
            }
        }
    }

    func items(for tab: String) -> [WatchlistRedesignItem] {
        groupedItems[tab] ?? []
    }

    var priceSimulationSymbols: [String] {
        (groupedItems["全部"] ?? []).reduce(into: [String]()) { symbols, item in
            guard item.market != .fund, !symbols.contains(item.symbol) else { return }
            symbols.append(item.symbol)
        }
    }

    func simulatePriceRefresh(for symbol: String) {
        guard let currentItem = groupedItems["全部"]?.first(where: { $0.symbol == symbol && $0.market != .fund }) else {
            return
        }

        let tick = WatchlistRedesignPriceTick(item: currentItem)
        groupedItems = groupedItems.mapValues { items in
            items.map { item in
                guard item.symbol == symbol, item.market != .fund else {
                    return item
                }

                var updatedItem = item
                updatedItem.price = tick.price
                updatedItem.secondaryPrice = tick.secondaryPrice
                updatedItem.changePercent = tick.changePercent
                updatedItem.trend = tick.trend
                return updatedItem
            }
        }
    }

    /// Keeps the demo's tag distribution stable between refreshes while still
    /// making the selected rows look naturally random. Holding and financial
    /// report markers intentionally use lower frequencies than the other tags.
    private static func applyingRandomizedTags(to item: WatchlistRedesignItem) -> WatchlistRedesignItem {
        guard item.instrumentKind == .stock else { return item }

        var tags = item.tagAssets
        let randomizedTagNames = [
            WatchlistRedesignTagAsset.delayQuote,
            WatchlistRedesignTagAsset.specialAttention,
            WatchlistRedesignTagAsset.holdings,
            WatchlistRedesignTagAsset.financialReport
        ]
        let randomizedTags: [(String, Bool)] = [
            // Each marker uses a different salt so the rows do not cluster
            // around the same symbols when the distribution changes.
            (WatchlistRedesignTagAsset.delayQuote, stableTagHash(for: "\(item.symbol):delay") % 6 == 0),
            (WatchlistRedesignTagAsset.specialAttention, stableTagHash(for: "\(item.symbol):special") % 10 < 3),
            (WatchlistRedesignTagAsset.holdings, stableTagHash(for: "\(item.symbol):holding") % 11 == 0),
            (WatchlistRedesignTagAsset.financialReport, stableTagHash(for: "\(item.symbol):financial") % 7 == 0)
        ]

        for (tag, shouldAdd) in randomizedTags where shouldAdd && !tags.contains(tag) {
            tags.append(tag)
        }

        // A small additional chance makes stacked markers visible without
        // making the already-rare holdings marker more common. The unique-tag
        // check also guarantees that a row never renders duplicate delay icons.
        if tags.contains(where: { randomizedTagNames.contains($0) }),
           stableTagHash(for: "\(item.symbol):stack") % 17 == 0,
           let extraTag = [
               WatchlistRedesignTagAsset.specialAttention,
               WatchlistRedesignTagAsset.financialReport,
               WatchlistRedesignTagAsset.delayQuote
           ].first(where: { !tags.contains($0) }) {
            tags.append(extraTag)
        }

        var updatedItem = item
        updatedItem.tagAssets = tags
        return updatedItem
    }

    private static func stableTagHash(for symbol: String) -> UInt64 {
        symbol.utf8.reduce(UInt64(1469598103934665603)) { hash, byte in
            (hash ^ UInt64(byte)) &* UInt64(1099511628211)
        }
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

private struct WatchlistRedesignPriceTick {
    let price: String
    let secondaryPrice: String?
    let changePercent: String
    let trend: WatchlistRedesignTrend

    init(item: WatchlistRedesignItem) {
        let previousPrice = item.price.numericPrice
        let direction = WatchlistRedesignPriceTick.priceDirection(for: item.trend)
        let volatility = item.market == .crypto ? 0.0012 : 0.0007
        let changeRate = Double.random(in: 0.00003...volatility) * direction
        let nextPrice = max(previousPrice * (1 + changeRate), 0.001)
        let formattedPrice = item.price.formattedPrice(nextPrice)
        let signedChange = WatchlistRedesignPriceTick.nextSignedChangePercent(for: item, priceDirection: direction)
        let formattedChange = String(format: "%.2f%%", abs(signedChange))
        let nextTrend = WatchlistRedesignPriceTick.trend(for: signedChange)

        price = formattedPrice
        secondaryPrice = item.secondaryPrice.map { $0.formattedPrice(nextPrice) }
        changePercent = formattedChange
        trend = nextTrend
    }

    private static func priceDirection(for trend: WatchlistRedesignTrend) -> Double {
        switch trend {
        case .up:
            return Double.random(in: 0...1) < 0.7 ? 1.0 : -1.0
        case .down:
            return Double.random(in: 0...1) < 0.7 ? -1.0 : 1.0
        case .flat:
            return Bool.random() ? 1.0 : -1.0
        }
    }

    private static func nextSignedChangePercent(for item: WatchlistRedesignItem, priceDirection: Double) -> Double {
        let previousChange = item.signedChangePercent
        let deltaRange = item.market == .crypto ? 0.004...0.025 : 0.002...0.012
        let delta = Double.random(in: deltaRange) * priceDirection
        let candidate = previousChange + delta

        guard previousChange != 0, candidate.sign != previousChange.sign else {
            return candidate
        }

        return previousChange.sign == .plus ? Double.random(in: 0.02...0.06) : -Double.random(in: 0.02...0.06)
    }

    private static func trend(for signedChangePercent: Double) -> WatchlistRedesignTrend {
        if abs(signedChangePercent) < 0.005 {
            return .flat
        }

        return signedChangePercent > 0 ? .up : .down
    }
}

private extension WatchlistRedesignItem {
    var signedChangePercent: Double {
        let value = changePercent.percentValue

        switch trend {
        case .up:
            return max(value, 0.02)
        case .down:
            return -max(value, 0.02)
        case .flat:
            return 0
        }
    }
}

private extension String {
    var numericPrice: Double {
        Double(replacingOccurrences(of: ",", with: "")) ?? 0
    }

    var percentValue: Double {
        Double(
            replacingOccurrences(of: "%", with: "")
                .replacingOccurrences(of: "+", with: "")
                .replacingOccurrences(of: "-", with: "")
        ) ?? 0
    }

    func formattedPrice(_ value: Double) -> String {
        String(format: "%.\(decimalPlaces)f", value)
    }

    private var decimalPlaces: Int {
        guard let decimalIndex = firstIndex(of: ".") else {
            return 0
        }

        return distance(from: index(after: decimalIndex), to: endIndex)
    }
}

private extension WatchlistRedesignSession {
    var extendedHoursChange: String? {
        switch self {
        case .regular:
            return nil
        case .preMarket(_, let change), .afterHours(_, let change):
            return change
        }
    }

    static func forUSMarketPhase(
        _ phase: WatchlistRedesignUSMarketPhase,
        change: String
    ) -> WatchlistRedesignSession {
        switch phase {
        case .preMarket:
            return .preMarket(label: "盘前", change: change)
        case .regular:
            return .regular
        case .afterHours:
            return .afterHours(label: "盘后", change: change)
        }
    }
}
