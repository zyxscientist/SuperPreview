//
//  TradeAggregationDemoViewModel.swift
//  SuperPreview
//

import Foundation
import SwiftUI

enum TradeAggregationSimulationTarget: Hashable {
    case stock(String)
    case fund(String)
    case virtualAsset(String)
}

struct TradeAggregationDemoSnapshot {
    let totalAmount: String
    let totalProfitLoss: String
    let stockCard: StockSubAssetCardModel
    let fundCard: FundSubAssetCardModel
    let virtualAssetCard: VirtualAssetsSubAssetCardModel
    let stockSections: [StockHoldingMarketSection]
    let fundSections: [FundHoldingCurrencySection]
    let virtualAssetSections: [VirtualAssetHoldingSection]
}

final class TradeAggregationDemoViewModel: ObservableObject {
    @Published private(set) var snapshot: TradeAggregationDemoSnapshot

    let simulationTargets: [TradeAggregationSimulationTarget]

    private var stockPositions: [StockPosition]
    private var fundPositions: [FundPosition]
    private var virtualAssetPositions: [VirtualAssetPosition]

    private let hkdToUSD = 7.8
    private let cnyToUSD = 7.2

    init() {
        stockPositions = Self.makeStockPositions()
        fundPositions = Self.makeFundPositions()
        virtualAssetPositions = Self.makeVirtualAssetPositions()

        simulationTargets = stockPositions.map { .stock($0.id) }
            + fundPositions.map { .fund($0.id) }
            + virtualAssetPositions.map { .virtualAsset($0.id) }

        snapshot = TradeAggregationDemoSnapshot.empty
        snapshot = makeSnapshot()
        assertInvariants()
    }

    func simulateRefresh(for target: TradeAggregationSimulationTarget) {
        switch target {
        case .stock(let id):
            guard let index = stockPositions.firstIndex(where: { $0.id == id }) else {
                return
            }

            let profile = simulationProfile(for: stockPositions[index])
            stockPositions[index].currentPrice = nextValue(
                current: stockPositions[index].currentPrice,
                baseline: stockPositions[index].baselinePrice,
                cost: stockPositions[index].costPrice,
                previous: stockPositions[index].previousClose,
                isTodayGain: stockPositions[index].isTodayGain,
                profile: profile,
                minimumIncrement: stockPositions[index].minimumPriceIncrement
            )

        case .fund(let id):
            guard let index = fundPositions.firstIndex(where: { $0.id == id }) else {
                return
            }

            let position = fundPositions[index]
            fundPositions[index].marketValue = nextValue(
                current: position.marketValue,
                baseline: position.baselineMarketValue,
                cost: position.costValue,
                previous: position.previousMarketValue,
                isTodayGain: true,
                profile: Self.fundSimulationProfile,
                minimumIncrement: 0.01
            )

        case .virtualAsset(let id):
            guard let index = virtualAssetPositions.firstIndex(where: { $0.id == id }) else {
                return
            }

            let profile = simulationProfile(for: virtualAssetPositions[index])
            virtualAssetPositions[index].currentPrice = nextValue(
                current: virtualAssetPositions[index].currentPrice,
                baseline: virtualAssetPositions[index].baselinePrice,
                cost: virtualAssetPositions[index].costPrice,
                previous: virtualAssetPositions[index].previousClose,
                isTodayGain: true,
                profile: profile,
                minimumIncrement: virtualAssetPositions[index].minimumPriceIncrement
            )
        }

        snapshot = makeSnapshot()
        assertInvariants()
    }

    func simulateRandomRefresh() {
        guard let target = simulationTargets.randomElement() else {
            return
        }

        simulateRefresh(for: target)
    }

    private func makeSnapshot() -> TradeAggregationDemoSnapshot {
        let stockMarketValueTotalUSD = stockPositions.reduce(0) {
            $0 + stockMarketValueUSD(for: $1)
        }
        let stockTodayProfitLossTotalUSD = stockPositions.reduce(0) {
            $0 + stockTodayProfitLossUSD(for: $1)
        }
        let stockHoldingProfitLossTotalUSD = stockPositions.reduce(0) {
            $0 + stockHoldingProfitLossUSD(for: $1)
        }
        let stockCashUSD = stockCashBalances.reduce(0) { $0 + cashUSD(for: $1) }
        let stockNetAssetUSD = stockMarketValueTotalUSD + stockCashUSD + 1_250

        let fundMarketValueTotalUSD = fundPositions.reduce(0) {
            $0 + $1.marketValue / exchangeRate(for: $1.currency)
        }
        let fundYesterdayIncomeUSD = fundPositions.reduce(0) {
            $0 + ($1.marketValue - $1.previousMarketValue) / exchangeRate(for: $1.currency)
        }
        let fundHoldingIncomeUSD = fundPositions.reduce(0) {
            $0 + ($1.marketValue - $1.costValue) / exchangeRate(for: $1.currency)
        }
        let fundNetAssetUSD = fundMarketValueTotalUSD + 480

        let virtualAssetMarketValueTotalUSD = virtualAssetPositions.reduce(0) {
            $0 + $1.currentPrice * $1.quantity
        }
        let virtualAssetTodayProfitLossUSD = virtualAssetPositions.reduce(0) {
            $0 + ($1.currentPrice - $1.previousClose) * $1.quantity
        }
        let virtualAssetHoldingProfitLossUSD = virtualAssetPositions.reduce(0) {
            $0 + ($1.currentPrice - $1.costPrice) * $1.quantity
        }
        let virtualAssetCashUSD = virtualAssetCashBalances.reduce(0) { $0 + cashUSD(for: $1) }
        let virtualAssetNetAssetUSD = virtualAssetMarketValueTotalUSD + virtualAssetCashUSD

        let totalAssetUSD = stockNetAssetUSD + fundNetAssetUSD + virtualAssetNetAssetUSD
        let totalProfitLossUSD = stockHoldingProfitLossTotalUSD
            + fundHoldingIncomeUSD
            + virtualAssetHoldingProfitLossUSD

        return TradeAggregationDemoSnapshot(
            totalAmount: money(totalAssetUSD),
            totalProfitLoss: signedMoney(totalProfitLossUSD),
            stockCard: StockSubAssetCardModel(
                currency: "USD",
                netAsset: money(stockNetAssetUSD),
                todayProfitLoss: signedMoneyWithRate(
                    stockTodayProfitLossTotalUSD,
                    denominator: stockNetAssetUSD - stockTodayProfitLossTotalUSD
                ),
                securitiesMarketValue: money(stockMarketValueTotalUSD),
                totalCash: money(stockCashUSD),
                positionProfitLoss: signedMoney(stockHoldingProfitLossTotalUSD),
                fundsInTransit: money(1_250),
                ipoFundsInTransit: money(0),
                frozenFunds: money(800),
                currencyBalances: stockCashBalances
            ),
            fundCard: FundSubAssetCardModel(
                currency: "USD",
                netAsset: money(fundNetAssetUSD),
                yesterdayIncome: signedMoney(fundYesterdayIncomeUSD),
                fundMarketValue: money(fundMarketValueTotalUSD),
                positionIncome: signedMoney(fundHoldingIncomeUSD),
                fundsInTransit: money(480),
                frozenFunds: money(120)
            ),
            virtualAssetCard: VirtualAssetsSubAssetCardModel(
                currency: "USD",
                netAsset: money(virtualAssetNetAssetUSD),
                todayProfitLoss: signedMoneyWithRate(
                    virtualAssetTodayProfitLossUSD,
                    denominator: virtualAssetNetAssetUSD - virtualAssetTodayProfitLossUSD
                ),
                marketValue: money(virtualAssetMarketValueTotalUSD),
                availableCash: money(virtualAssetCashUSD),
                positionProfitLoss: signedMoney(virtualAssetHoldingProfitLossUSD),
                currencyBalances: virtualAssetCashBalances
            ),
            stockSections: makeStockSections(totalMarketValueUSD: stockMarketValueTotalUSD),
            fundSections: makeFundSections(totalMarketValueUSD: fundMarketValueTotalUSD),
            virtualAssetSections: makeVirtualAssetSections(totalMarketValueUSD: virtualAssetMarketValueTotalUSD)
        )
    }

    private func makeStockSections(totalMarketValueUSD: Double) -> [StockHoldingMarketSection] {
        StockHoldingMarket.allCases.compactMap { market in
            let positions = stockPositions.filter { $0.market == market }
            guard !positions.isEmpty else { return nil }

            return StockHoldingMarketSection(
                market: market,
                holdings: positions.map { position in
                    let marketValue = position.currentPrice * position.quantity
                    let todayProfitLoss = (position.currentPrice - position.previousClose) * position.quantity
                    let holdingProfitLoss = (position.currentPrice - position.costPrice) * position.quantity

                    return StockHoldingItem(
                        id: position.id,
                        name: position.name,
                        symbol: position.symbol,
                        marketValue: money(marketValue),
                        quantity: quantity(position.quantity, decimals: position.quantityDecimals),
                        currentPrice: price(position.currentPrice, decimals: position.priceDecimals),
                        costPrice: price(position.costPrice, decimals: position.priceDecimals),
                        todayProfitLoss: signedMoney(todayProfitLoss),
                        todayProfitLossRate: signedPercent(position.currentPrice / position.previousClose - 1),
                        holdingProfitLoss: signedMoney(holdingProfitLoss),
                        holdingProfitLossRate: signedPercent(position.currentPrice / position.costPrice - 1),
                        holdingRatio: percent(marketValue / exchangeRate(for: position.currency) / totalMarketValueUSD),
                        todayTone: todayProfitLoss >= 0 ? .gain : .loss,
                        holdingTone: holdingProfitLoss >= 0 ? .gain : .loss
                    )
                }
            )
        }
    }

    private func makeFundSections(totalMarketValueUSD: Double) -> [FundHoldingCurrencySection] {
        FundHoldingCurrency.allCases.compactMap { currency in
            let positions = fundPositions.filter { $0.currency == currency }
            guard !positions.isEmpty else { return nil }

            return FundHoldingCurrencySection(
                currency: currency,
                holdings: positions.map { position in
                    let holdingIncome = position.marketValue - position.costValue
                    let yesterdayIncome = position.marketValue - position.previousMarketValue
                    let marketValueUSD = position.marketValue / exchangeRate(for: position.currency)

                    return FundHoldingItem(
                        id: position.id,
                        name: position.name,
                        symbol: position.symbol,
                        marketValue: money(position.marketValue),
                        yesterdayIncome: signedMoney(yesterdayIncome),
                        holdingIncome: signedMoney(holdingIncome),
                        holdingIncomeRate: signedPercent(position.marketValue / position.costValue - 1),
                        holdingRatio: percent(marketValueUSD / totalMarketValueUSD),
                        incomeTone: holdingIncome >= 0 ? .gain : .loss,
                        nameAccessory: position.nameAccessory,
                        showsAIPTag: position.showsAIPTag
                    )
                }
            )
        }
    }

    private func makeVirtualAssetSections(totalMarketValueUSD: Double) -> [VirtualAssetHoldingSection] {
        [
            VirtualAssetHoldingSection(
                category: .cryptocurrency,
                holdings: virtualAssetPositions
                    .filter { !$0.isRWA }
                    .map { virtualAssetHoldingItem($0, totalMarketValueUSD: totalMarketValueUSD) }
            ),
            VirtualAssetHoldingSection(
                category: .rwa,
                holdings: virtualAssetPositions
                    .filter { $0.isRWA }
                    .map { virtualAssetHoldingItem($0, totalMarketValueUSD: totalMarketValueUSD) }
            )
        ]
    }

    private func virtualAssetHoldingItem(
        _ position: VirtualAssetPosition,
        totalMarketValueUSD: Double
    ) -> VirtualAssetHoldingItem {
        let marketValue = position.currentPrice * position.quantity
        let todayProfitLoss = (position.currentPrice - position.previousClose) * position.quantity
        let holdingProfitLoss = (position.currentPrice - position.costPrice) * position.quantity

        return VirtualAssetHoldingItem(
            id: position.id,
            name: position.name,
            symbol: position.symbol,
            marketValue: money(marketValue),
            quantity: quantity(position.quantity, decimals: position.quantityDecimals),
            currentPrice: price(position.currentPrice, decimals: position.priceDecimals),
            costPrice: price(position.costPrice, decimals: position.priceDecimals),
            todayProfitLoss: signedMoney(todayProfitLoss),
            todayProfitLossRate: signedPercent(position.currentPrice / position.previousClose - 1),
            holdingProfitLoss: signedMoney(holdingProfitLoss),
            holdingProfitLossRate: signedPercent(position.currentPrice / position.costPrice - 1),
            holdingRatio: percent(marketValue / totalMarketValueUSD),
            todayTone: todayProfitLoss >= 0 ? .red : .green,
            holdingTone: holdingProfitLoss >= 0 ? .red : .green
        )
    }

    private var stockCashBalances: [SubAssetCurrencyBalance] {
        [
            SubAssetCurrencyBalance(
                currency: "HKD",
                flagImageName: "subasset_flag_hkd",
                available: money(19_500),
                withdrawable: money(18_000),
                buyingPower: money(25_000)
            ),
            equalCashBalance(currency: "USD", flagImageName: "subasset_flag_usd", amount: 8_500),
            equalCashBalance(currency: "CNY", flagImageName: "subasset_flag_cny", amount: 18_000)
        ]
    }

    private var virtualAssetCashBalances: [SubAssetCurrencyBalance] {
        [
            SubAssetCurrencyBalance(
                currency: "HKD",
                flagImageName: "subasset_flag_hkd",
                available: money(3_900),
                withdrawable: "",
                buyingPower: ""
            ),
            SubAssetCurrencyBalance(
                currency: "USD",
                flagImageName: "subasset_flag_usd",
                available: money(1_250),
                withdrawable: "",
                buyingPower: ""
            )
        ]
    }

    private func equalCashBalance(
        currency: String,
        flagImageName: String,
        amount: Double
    ) -> SubAssetCurrencyBalance {
        let formattedAmount = money(amount)
        return SubAssetCurrencyBalance(
            currency: currency,
            flagImageName: flagImageName,
            available: formattedAmount,
            withdrawable: formattedAmount,
            buyingPower: formattedAmount
        )
    }

    private func assertInvariants() {
        let usd = stockCashBalances.first(where: { $0.currency == "USD" })
        let cny = stockCashBalances.first(where: { $0.currency == "CNY" })
        assert(usd?.available == usd?.withdrawable && usd?.available == usd?.buyingPower)
        assert(cny?.available == cny?.withdrawable && cny?.available == cny?.buyingPower)

        let stockNet = stockPositions.reduce(0) { $0 + stockMarketValueUSD(for: $1) }
            + stockCashBalances.reduce(0) { $0 + cashUSD(for: $1) }
            + 1_250
        let fundNet = fundPositions.reduce(0) { $0 + $1.marketValue / exchangeRate(for: $1.currency) } + 480
        let virtualNet = virtualAssetPositions.reduce(0) { $0 + $1.currentPrice * $1.quantity }
            + virtualAssetCashBalances.reduce(0) { $0 + cashUSD(for: $1) }
        let expectedTotal = stockNet + fundNet + virtualNet
        assert(abs(parseMoney(snapshot.totalAmount) - expectedTotal) < 0.01)
    }

    private func nextValue(
        current: Double,
        baseline: Double,
        cost: Double,
        previous: Double,
        isTodayGain: Bool,
        profile: SimulationProfile,
        minimumIncrement: Double
    ) -> Double {
        let lowerDrift = baseline * (1 - profile.maximumDrift)
        let upperDrift = baseline * (1 + profile.maximumDrift)
        var lowerBound = max(lowerDrift, cost + minimumIncrement)
        var upperBound = upperDrift

        if isTodayGain {
            lowerBound = max(lowerBound, previous + minimumIncrement)
        } else {
            upperBound = min(upperBound, previous - minimumIncrement)
        }

        guard lowerBound <= upperBound else { return current }

        let percentageChange = Double.random(in: profile.tickRange)
        let candidate = current * (1 + percentageChange)
        return min(max(candidate, lowerBound), upperBound)
    }

    private func simulationProfile(for position: StockPosition) -> SimulationProfile {
        switch position.market {
        case .hongKong:
            return SimulationProfile(tickRange: -0.0006...0.0006, maximumDrift: 0.008)
        case .chinaA:
            return SimulationProfile(tickRange: -0.0005...0.0005, maximumDrift: 0.008)
        case .unitedStates:
            return SimulationProfile(tickRange: -0.0008...0.0008, maximumDrift: 0.009)
        }
    }

    private func simulationProfile(for position: VirtualAssetPosition) -> SimulationProfile {
        if position.isRWA {
            return SimulationProfile(tickRange: -0.00025...0.00025, maximumDrift: 0.006)
        }

        return SimulationProfile(tickRange: -0.0012...0.0012, maximumDrift: 0.012)
    }

    private func stockMarketValueUSD(for position: StockPosition) -> Double {
        position.currentPrice * position.quantity / exchangeRate(for: position.currency)
    }

    private func stockTodayProfitLossUSD(for position: StockPosition) -> Double {
        (position.currentPrice - position.previousClose) * position.quantity / exchangeRate(for: position.currency)
    }

    private func stockHoldingProfitLossUSD(for position: StockPosition) -> Double {
        (position.currentPrice - position.costPrice) * position.quantity / exchangeRate(for: position.currency)
    }

    private func cashUSD(for balance: SubAssetCurrencyBalance) -> Double {
        let numericValue = parseMoney(balance.available)
        switch balance.currency {
        case "HKD": return numericValue / hkdToUSD
        case "CNY": return numericValue / cnyToUSD
        default: return numericValue
        }
    }

    private func exchangeRate(for currency: FundHoldingCurrency) -> Double {
        switch currency {
        case .hongKongDollar: return hkdToUSD
        case .unitedStatesDollar: return 1
        case .renminbi: return cnyToUSD
        }
    }

    private func exchangeRate(for currency: String) -> Double {
        switch currency {
        case "HKD": return hkdToUSD
        case "CNY": return cnyToUSD
        default: return 1
        }
    }

    private func money(_ value: Double) -> String {
        formatted(value, decimals: 2, grouping: true, includeSign: false)
    }

    private func signedMoney(_ value: Double) -> String {
        formatted(value, decimals: 2, grouping: true, includeSign: true)
    }

    private func signedMoneyWithRate(_ value: Double, denominator: Double) -> String {
        "\(signedMoney(value))(\(signedPercent(value / denominator)))"
    }

    private func price(_ value: Double, decimals: Int) -> String {
        formatted(value, decimals: decimals, grouping: false, includeSign: false)
    }

    private func quantity(_ value: Double, decimals: Int) -> String {
        formatted(value, decimals: decimals, grouping: true, includeSign: false)
    }

    private func percent(_ value: Double) -> String {
        formatted(value * 100, decimals: 2, grouping: false, includeSign: false) + "%"
    }

    private func signedPercent(_ value: Double) -> String {
        formatted(value * 100, decimals: 2, grouping: false, includeSign: true) + "%"
    }

    private func formatted(
        _ value: Double,
        decimals: Int,
        grouping: Bool,
        includeSign: Bool
    ) -> String {
        let normalizedValue = abs(value) < pow(10, -Double(decimals)) / 2 ? 0 : value
        let sign = normalizedValue < 0 ? "-" : (includeSign ? "+" : "")
        let plainValue = String(
            format: "%.\(decimals)f",
            abs(normalizedValue)
        )

        guard grouping else {
            return sign + plainValue
        }

        let parts = plainValue.split(separator: ".", omittingEmptySubsequences: false)
        let integerDigits = Array(parts[0])
        var groups: [String] = []
        var endIndex = integerDigits.count

        while endIndex > 3 {
            let startIndex = endIndex - 3
            groups.insert(String(integerDigits[startIndex..<endIndex]), at: 0)
            endIndex = startIndex
        }

        groups.insert(String(integerDigits[0..<endIndex]), at: 0)
        let groupedInteger = groups.joined(separator: ",")
        let fraction = parts.count > 1 ? ".\(parts[1])" : ""
        return sign + groupedInteger + fraction
    }

    private func parseMoney(_ value: String) -> Double {
        Double(value.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    private struct SimulationProfile {
        let tickRange: ClosedRange<Double>
        let maximumDrift: Double
    }

    private static let fundSimulationProfile = SimulationProfile(
        tickRange: -0.00002...0.00002,
        maximumDrift: 0.004
    )

    private struct StockPosition {
        let id: String
        let market: StockHoldingMarket
        let currency: String
        let name: String
        let symbol: String
        let quantity: Double
        let quantityDecimals: Int
        var currentPrice: Double
        let baselinePrice: Double
        let costPrice: Double
        let previousClose: Double
        let priceDecimals: Int
        let minimumPriceIncrement: Double
        let isTodayGain: Bool
    }

    private struct FundPosition {
        let id: String
        let currency: FundHoldingCurrency
        let name: String
        let symbol: String
        var marketValue: Double
        let baselineMarketValue: Double
        let costValue: Double
        let previousMarketValue: Double
        let nameAccessory: FundHoldingNameAccessory
        let showsAIPTag: Bool
    }

    private struct VirtualAssetPosition {
        let id: String
        let name: String
        let symbol: String
        let quantity: Double
        let quantityDecimals: Int
        var currentPrice: Double
        let baselinePrice: Double
        let costPrice: Double
        let previousClose: Double
        let priceDecimals: Int
        let minimumPriceIncrement: Double
        let isRWA: Bool
    }

    private static func makeStockPositions() -> [StockPosition] {
        [
            StockPosition(id: "hk-tencent", market: .hongKong, currency: "HKD", name: "腾讯控股", symbol: "00700", quantity: 100, quantityDecimals: 0, currentPrice: 520, baselinePrice: 520, costPrice: 445, previousClose: 514.8, priceDecimals: 3, minimumPriceIncrement: 0.001, isTodayGain: true),
            StockPosition(id: "hk-hstech", market: .hongKong, currency: "HKD", name: "南方恒生科技", symbol: "03033", quantity: 2_000, quantityDecimals: 0, currentPrice: 5.32, baselinePrice: 5.32, costPrice: 4.86, previousClose: 5.27, priceDecimals: 3, minimumPriceIncrement: 0.001, isTodayGain: true),
            StockPosition(id: "hk-alibaba", market: .hongKong, currency: "HKD", name: "阿里巴巴-W", symbol: "09988", quantity: 200, quantityDecimals: 0, currentPrice: 118.6, baselinePrice: 118.6, costPrice: 102.4, previousClose: 117.2, priceDecimals: 3, minimumPriceIncrement: 0.001, isTodayGain: true),
            StockPosition(id: "hk-xiaomi", market: .hongKong, currency: "HKD", name: "小米集团-W", symbol: "01810", quantity: 1_200, quantityDecimals: 0, currentPrice: 53.15, baselinePrice: 53.15, costPrice: 47.82, previousClose: 52.76, priceDecimals: 3, minimumPriceIncrement: 0.001, isTodayGain: true),
            StockPosition(id: "cn-tcl", market: .chinaA, currency: "CNY", name: "TCL 科技", symbol: "000100", quantity: 5_000, quantityDecimals: 0, currentPrice: 4.58, baselinePrice: 4.58, costPrice: 4.11, previousClose: 4.53, priceDecimals: 2, minimumPriceIncrement: 0.01, isTodayGain: true),
            StockPosition(id: "cn-powerchina", market: .chinaA, currency: "CNY", name: "中国电建", symbol: "601669", quantity: 3_000, quantityDecimals: 0, currentPrice: 5.22, baselinePrice: 5.22, costPrice: 4.84, previousClose: 5.26, priceDecimals: 2, minimumPriceIncrement: 0.01, isTodayGain: false),
            StockPosition(id: "cn-moutai", market: .chinaA, currency: "CNY", name: "贵州茅台", symbol: "600519", quantity: 20, quantityDecimals: 0, currentPrice: 1_468, baselinePrice: 1_468, costPrice: 1_325, previousClose: 1_455, priceDecimals: 2, minimumPriceIncrement: 0.01, isTodayGain: true),
            StockPosition(id: "cn-byd", market: .chinaA, currency: "CNY", name: "比亚迪", symbol: "002594", quantity: 300, quantityDecimals: 0, currentPrice: 118.4, baselinePrice: 118.4, costPrice: 124.6, previousClose: 119.25, priceDecimals: 2, minimumPriceIncrement: 0.01, isTodayGain: false),
            StockPosition(id: "us-apple", market: .unitedStates, currency: "USD", name: "苹果", symbol: "AAPL", quantity: 180, quantityDecimals: 0, currentPrice: 214.25, baselinePrice: 214.25, costPrice: 187.4, previousClose: 212.8, priceDecimals: 2, minimumPriceIncrement: 0.01, isTodayGain: true),
            StockPosition(id: "us-nvidia", market: .unitedStates, currency: "USD", name: "英伟达", symbol: "NVDA", quantity: 220, quantityDecimals: 0, currentPrice: 173.6, baselinePrice: 173.6, costPrice: 142.3, previousClose: 170.25, priceDecimals: 2, minimumPriceIncrement: 0.01, isTodayGain: true),
            StockPosition(id: "us-tesla", market: .unitedStates, currency: "USD", name: "特斯拉", symbol: "TSLA", quantity: 85, quantityDecimals: 0, currentPrice: 317.4, baselinePrice: 317.4, costPrice: 286.2, previousClose: 321.8, priceDecimals: 2, minimumPriceIncrement: 0.01, isTodayGain: false),
            StockPosition(id: "us-microsoft", market: .unitedStates, currency: "USD", name: "微软", symbol: "MSFT", quantity: 90, quantityDecimals: 0, currentPrice: 497.55, baselinePrice: 497.55, costPrice: 438.2, previousClose: 494.1, priceDecimals: 2, minimumPriceIncrement: 0.01, isTodayGain: true)
        ]
    }

    private static func makeFundPositions() -> [FundPosition] {
        [
            FundPosition(id: "fund-hkd-1", currency: .hongKongDollar, name: "南方港元货币市场基金", symbol: "968010", marketValue: 18_000, baselineMarketValue: 18_000, costValue: 17_820, previousMarketValue: 17_998.35, nameAccessory: .none, showsAIPTag: false),
            FundPosition(id: "fund-hkd-2", currency: .hongKongDollar, name: "汇丰环球货币基金-港元", symbol: "968098", marketValue: 13_200, baselineMarketValue: 13_200, costValue: 13_082, previousMarketValue: 13_198.9, nameAccessory: .tPlusZero, showsAIPTag: true),
            FundPosition(id: "fund-usd-1", currency: .unitedStatesDollar, name: "摩根美元货币基金", symbol: "968011", marketValue: 11_500, baselineMarketValue: 11_500, costValue: 10_960, previousMarketValue: 11_498.58, nameAccessory: .none, showsAIPTag: false),
            FundPosition(id: "fund-usd-2", currency: .unitedStatesDollar, name: "富兰克林美元短债基金", symbol: "968021", marketValue: 7_000, baselineMarketValue: 7_000, costValue: 6_685, previousMarketValue: 6_999.14, nameAccessory: .legacyFundInfo, showsAIPTag: true),
            FundPosition(id: "fund-cny-1", currency: .renminbi, name: "华夏人民币货币基金", symbol: "968012", marketValue: 40_000, baselineMarketValue: 40_000, costValue: 39_180, previousMarketValue: 39_995.88, nameAccessory: .none, showsAIPTag: false),
            FundPosition(id: "fund-cny-2", currency: .renminbi, name: "易方达稳健短债基金", symbol: "968028", marketValue: 37_702.4, baselineMarketValue: 37_702.4, costValue: 37_057.4, previousMarketValue: 37_698.52, nameAccessory: .tPlusZero, showsAIPTag: true)
        ]
    }

    private static func makeVirtualAssetPositions() -> [VirtualAssetPosition] {
        [
            VirtualAssetPosition(id: "crypto-btc", name: "比特币", symbol: "BTC", quantity: 0.12, quantityDecimals: 4, currentPrice: 118_500, baselinePrice: 118_500, costPrice: 101_000, previousClose: 117_800, priceDecimals: 2, minimumPriceIncrement: 0.01, isRWA: false),
            VirtualAssetPosition(id: "crypto-eth", name: "以太币", symbol: "ETH", quantity: 1.6, quantityDecimals: 4, currentPrice: 3_780, baselinePrice: 3_780, costPrice: 3_210, previousClose: 3_735, priceDecimals: 2, minimumPriceIncrement: 0.01, isRWA: false),
            VirtualAssetPosition(id: "crypto-sol", name: "Solana", symbol: "SOL", quantity: 18, quantityDecimals: 2, currentPrice: 196, baselinePrice: 196, costPrice: 168, previousClose: 193.5, priceDecimals: 2, minimumPriceIncrement: 0.01, isRWA: false),
            VirtualAssetPosition(id: "crypto-xrp", name: "瑞波币", symbol: "XRP", quantity: 4_200, quantityDecimals: 2, currentPrice: 2.24, baselinePrice: 2.24, costPrice: 1.94, previousClose: 2.21, priceDecimals: 4, minimumPriceIncrement: 0.0001, isRWA: false),
            VirtualAssetPosition(id: "crypto-doge", name: "狗狗币", symbol: "DOGE", quantity: 12_000, quantityDecimals: 2, currentPrice: 0.183, baselinePrice: 0.183, costPrice: 0.214, previousClose: 0.186, priceDecimals: 4, minimumPriceIncrement: 0.0001, isRWA: false),
            VirtualAssetPosition(id: "crypto-link", name: "Chainlink", symbol: "LINK", quantity: 420, quantityDecimals: 2, currentPrice: 18.62, baselinePrice: 18.62, costPrice: 15.84, previousClose: 18.35, priceDecimals: 2, minimumPriceIncrement: 0.01, isRWA: false),
            VirtualAssetPosition(id: "rwa-xaua", name: "黄金代币", symbol: "XAUa", quantity: 0.65, quantityDecimals: 4, currentPrice: 3_340, baselinePrice: 3_340, costPrice: 2_980, previousClose: 3_324, priceDecimals: 2, minimumPriceIncrement: 0.01, isRWA: true)
        ]
    }
}

private extension TradeAggregationDemoSnapshot {
    static let empty = TradeAggregationDemoSnapshot(
        totalAmount: "0.00",
        totalProfitLoss: "0.00",
        stockCard: .preview,
        fundCard: .preview,
        virtualAssetCard: .preview,
        stockSections: [],
        fundSections: [],
        virtualAssetSections: []
    )
}
