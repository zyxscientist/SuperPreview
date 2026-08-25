//
//  StockOrderDemoViewModel.swift
//  SuperPreview
//

import Foundation
import SwiftUI

/// All presentation rules needed by one market variant of the stock-order
/// demo. Keeping them together prevents the root view from becoming a chain of
/// market-specific conditionals.
struct StockOrderDemoProfile {
    let market: StockOrderMarket?
    let accountTitleKey: DemoCopyKey
    let accountNumber: String
    let buyingPower: StockOrderBuyingPower?
    let currencyCode: String
    let supportedOrderTypes: [StockOrderOrderTypeOption]
    let defaultOrderType: StockOrderOrderType
    let defaultPriceTarget: StockOrderPriceTarget
    let supportedPriceTargets: [StockOrderPriceTarget]
    let defaultPrice: String
    let defaultQuantity: String
    let currentPrice: Decimal?
    let priceStep: Decimal
    let priceFractionDigits: Int
    let quantityStep: Decimal
    let quantityInputMode: StockOrderQuantityInputMode
    let orderBookDepth: StockOrderBookDepth?
    let orderBookDistribution: StockOrderBookDistribution
    let bidLevels: [StockOrderBookLevel]
    let askLevels: [StockOrderBookLevel]
    let cashPurchasable: StockOrderQuantityAvailabilityValue
    let maximumPurchasable: StockOrderQuantityAvailabilityValue?
    let positionSellable: StockOrderQuantityAvailabilityValue
    let usesMargin: Bool

    var isCrypto: Bool {
        market == .crypto
    }

    var showsMaximumPurchasable: Bool {
        maximumPurchasable != nil
    }

    static let empty = StockOrderDemoProfile(
        market: nil,
        accountTitleKey: .securitiesMarginAccount,
        accountNumber: "0909",
        buyingPower: nil,
        currencyCode: "",
        supportedOrderTypes: StockOrderOrderTypeOptions.hongKong,
        defaultOrderType: .enhancedLimit,
        defaultPriceTarget: .specifiedPrice,
        supportedPriceTargets: StockOrderPriceTargetOptions.advancedQuote,
        defaultPrice: "",
        defaultQuantity: "",
        currentPrice: nil,
        priceStep: 0.01,
        priceFractionDigits: 2,
        quantityStep: 100,
        quantityInputMode: .wholeNumber,
        orderBookDepth: nil,
        orderBookDistribution: .init(
            bidPercentage: "--",
            askPercentage: "--",
            bidFraction: 0.5
        ),
        bidLevels: [],
        askLevels: [],
        cashPurchasable: .init(displayValue: "--", inputValue: ""),
        maximumPurchasable: .init(displayValue: "--", inputValue: ""),
        positionSellable: .init(displayValue: "--", inputValue: ""),
        usesMargin: false
    )

    static let hongKong = StockOrderDemoProfile(
        market: .hk,
        accountTitleKey: .securitiesMarginAccount,
        accountNumber: "0909",
        buyingPower: .init(currencyCode: "HKD", formattedAmount: "200,000.00"),
        currencyCode: "HKD",
        supportedOrderTypes: StockOrderOrderTypeOptions.hongKong,
        defaultOrderType: .enhancedLimit,
        defaultPriceTarget: .specifiedPrice,
        supportedPriceTargets: StockOrderPriceTargetOptions.advancedQuote,
        defaultPrice: "82.150",
        defaultQuantity: "",
        currentPrice: Decimal(string: "82.15"),
        priceStep: 0.01,
        priceFractionDigits: 3,
        quantityStep: 100,
        quantityInputMode: .wholeNumber,
        orderBookDepth: .ten,
        orderBookDistribution: .init(
            bidPercentage: "56%",
            askPercentage: "44%",
            bidVolume: 5_600,
            askVolume: 4_400
        ),
        bidLevels: Self.makeLevels(
            prices: ["82.140", "82.130", "82.120", "82.110", "82.100", "82.090", "82.080", "82.070", "82.060", "82.050"],
            quantities: ["1.2K", "2.4K", "3.1K", "1.8K", "4.7K", "2.0K", "5.2K", "3.6K", "1.4K", "2.8K"],
            tone: .buy
        ),
        askLevels: Self.makeLevels(
            prices: ["82.160", "82.170", "82.180", "82.190", "82.200", "82.210", "82.220", "82.230", "82.240", "82.250"],
            quantities: ["1.5K", "2.1K", "3.8K", "2.2K", "4.1K", "1.7K", "3.4K", "2.8K", "1.9K", "2.5K"],
            tone: .sell
        ),
        cashPurchasable: .init(displayValue: "2,400", inputValue: "2400"),
        maximumPurchasable: .init(displayValue: "4,800", inputValue: "4800"),
        positionSellable: .init(displayValue: "2,000", inputValue: "2000"),
        usesMargin: true
    )

    static let unitedStates = StockOrderDemoProfile(
        market: .us,
        accountTitleKey: .securitiesMarginAccount,
        accountNumber: "0909",
        buyingPower: .init(currencyCode: "USD", formattedAmount: "200,000.00"),
        currencyCode: "USD",
        supportedOrderTypes: StockOrderOrderTypeOptions.us,
        defaultOrderType: .limit,
        defaultPriceTarget: .specifiedPrice,
        supportedPriceTargets: StockOrderPriceTargetOptions.advancedQuote,
        defaultPrice: "131.72",
        defaultQuantity: "",
        currentPrice: Decimal(string: "131.72"),
        priceStep: 0.01,
        priceFractionDigits: 2,
        quantityStep: 1,
        quantityInputMode: .wholeNumber,
        orderBookDepth: .one,
        orderBookDistribution: .init(
            bidPercentage: "48%",
            askPercentage: "52%",
            bidVolume: 4_800,
            askVolume: 5_200
        ),
        bidLevels: Self.makeLevels(
            prices: ["131.70"],
            quantities: ["6.4K"],
            tone: .buy
        ),
        askLevels: Self.makeLevels(
            prices: ["131.74"],
            quantities: ["5.1K"],
            tone: .sell
        ),
        cashPurchasable: .init(displayValue: "1,500", inputValue: "1500"),
        maximumPurchasable: .init(displayValue: "3,000", inputValue: "3000"),
        positionSellable: .init(displayValue: "800", inputValue: "800"),
        usesMargin: true
    )

    static let chinaA = StockOrderDemoProfile(
        market: .china,
        accountTitleKey: .securitiesMarginAccount,
        accountNumber: "0909",
        buyingPower: .init(currencyCode: "CNH", formattedAmount: "200,000.00"),
        currencyCode: "CNH",
        supportedOrderTypes: StockOrderOrderTypeOptions.aShare,
        defaultOrderType: .limit,
        defaultPriceTarget: .specifiedPrice,
        supportedPriceTargets: StockOrderPriceTargetOptions.basicQuote,
        defaultPrice: "16.400",
        defaultQuantity: "",
        currentPrice: Decimal(string: "16.40"),
        priceStep: 0.01,
        priceFractionDigits: 3,
        quantityStep: 100,
        quantityInputMode: .wholeNumber,
        orderBookDepth: .ten,
        orderBookDistribution: .init(
            bidPercentage: "52%",
            askPercentage: "48%",
            bidVolume: 5_200,
            askVolume: 4_800
        ),
        bidLevels: Self.makeLevels(
            prices: ["16.390", "16.380", "16.370", "16.360", "16.350", "16.340", "16.330", "16.320", "16.310", "16.300"],
            quantities: ["6.4K", "3.1K", "2.8K", "4.2K", "1.6K", "5.8K", "2.4K", "3.9K", "1.2K", "2.5K"],
            tone: .buy
        ),
        askLevels: Self.makeLevels(
            prices: ["16.410", "16.420", "16.430", "16.440", "16.450", "16.460", "16.470", "16.480", "16.490", "16.500"],
            quantities: ["4.8K", "2.2K", "3.6K", "1.7K", "5.1K", "2.9K", "4.4K", "2.0K", "3.3K", "1.1K"],
            tone: .sell
        ),
        cashPurchasable: .init(displayValue: "6,000", inputValue: "6000"),
        maximumPurchasable: nil,
        positionSellable: .init(displayValue: "1,000", inputValue: "1000"),
        usesMargin: false
    )

    static let crypto = StockOrderDemoProfile(
        market: .crypto,
        accountTitleKey: .virtualAssetCashAccount,
        accountNumber: "0801",
        buyingPower: .init(currencyCode: "USD", formattedAmount: "200,000.00"),
        currencyCode: "USD",
        supportedOrderTypes: StockOrderOrderTypeOptions.crypto,
        defaultOrderType: .limit,
        defaultPriceTarget: .specifiedPrice,
        supportedPriceTargets: StockOrderPriceTargetOptions.basicQuote,
        defaultPrice: "102345.12",
        defaultQuantity: "",
        currentPrice: Decimal(string: "102345.12"),
        priceStep: 0.01,
        priceFractionDigits: 2,
        quantityStep: 0.00001,
        quantityInputMode: .decimal(maxFractionDigits: 5, placeholder: nil),
        orderBookDepth: .ten,
        orderBookDistribution: .init(
            bidPercentage: "61%",
            askPercentage: "39%",
            bidVolume: 6_100,
            askVolume: 3_900
        ),
        bidLevels: Self.makeLevels(
            prices: ["102344.90", "102344.70", "102344.50", "102344.30", "102344.10", "102343.90", "102343.70", "102343.50", "102343.30", "102343.10"],
            quantities: ["0.42", "0.31", "0.28", "0.55", "0.18", "0.64", "0.37", "0.22", "0.48", "0.19"],
            tone: .buy
        ),
        askLevels: Self.makeLevels(
            prices: ["102345.30", "102345.50", "102345.70", "102345.90", "102346.10", "102346.30", "102346.50", "102346.70", "102346.90", "102347.10"],
            quantities: ["0.24", "0.35", "0.17", "0.43", "0.29", "0.51", "0.33", "0.20", "0.46", "0.27"],
            tone: .sell
        ),
        cashPurchasable: .init(displayValue: "1.23450", inputValue: "1.23450"),
        maximumPurchasable: nil,
        positionSellable: .init(displayValue: "0.85000", inputValue: "0.85000"),
        usesMargin: false
    )

    private static func makeLevels(
        prices: [String],
        quantities: [String],
        tone: StockOrderQuantityQuickInputTone
    ) -> [StockOrderBookLevel] {
        let maximum = quantities.compactMap { Double($0.replacingOccurrences(of: "K", with: "000")) }.max() ?? 1

        return zip(prices, quantities).enumerated().map { index, pair in
            StockOrderBookLevel(
                price: pair.0,
                quantity: pair.1,
                brokerCount: tone == .buy ? "\(index + 1)" : nil,
                volumeFraction: CGFloat(
                    (Double(pair.1.replacingOccurrences(of: "K", with: "000")) ?? 0) / maximum
                )
            )
        }
    }
}

final class StockOrderDemoViewModel: ObservableObject {
    static let searchableSymbols: [StockOrderSymbol] = [
        .alibaba,
        .tencent,
        .nvidia,
        .hybl,
        .spcx,
        .haitian,
        .bitcoin
    ]

    @Published var selection: StockOrderSymbol?
    @Published var isChartExpanded = false
    @Published var isOrderBookExpanded = false
    @Published var recentSymbols: [StockOrderSymbol]
    @Published var orderType: StockOrderOrderType
    @Published var price: String
    @Published var priceTarget: StockOrderPriceTarget
    @Published var quantity: String
    @Published var effectPeriod: StockOrderEffectPeriod = .day
    @Published var extendedHours: StockOrderExtendedHours = .allowed
    @Published var selectedOrdersTab: StockOrderOrdersAndPositionsTab = .todayOrders
    @Published var productCategory: StockOrderProductCategory = .stocks

    init(initialSelection: StockOrderSymbol? = nil) {
        let initialProfile = Self.profile(for: initialSelection)
        selection = initialSelection
        recentSymbols = Self.searchableSymbols
        orderType = initialProfile.defaultOrderType
        price = initialProfile.defaultPrice
        priceTarget = initialProfile.defaultPriceTarget
        quantity = initialProfile.defaultQuantity
        productCategory = initialSelection?.market == .crypto ? .crypto : .stocks
    }

    var profile: StockOrderDemoProfile {
        Self.profile(for: selection)
    }

    var accountTitle: String {
        "\(profile.accountTitleKey)(\(profile.accountNumber))"
    }

    var buyingPower: StockOrderBuyingPower? {
        profile.buyingPower
    }

    var showsExtendedHours: Bool {
        selection?.market == .us
    }

    var showsOrderBook: Bool {
        selection != nil && profile.orderBookDepth != nil
    }

    var isMarketOrder: Bool {
        orderType == .market
    }

    func synchronizeSelection() {
        let nextProfile = Self.profile(for: selection)
        orderType = nextProfile.defaultOrderType
        price = nextProfile.defaultPrice
        priceTarget = nextProfile.defaultPriceTarget
        quantity = nextProfile.defaultQuantity
        effectPeriod = .day
        extendedHours = .allowed
        isChartExpanded = false
        isOrderBookExpanded = false
        productCategory = selection?.market == .crypto ? .crypto : .stocks
    }

    func setProductCategory(_ category: StockOrderProductCategory) {
        guard category != productCategory else { return }

        productCategory = category
        if category == .stocks {
            selection = nil
            synchronizeSelection()
        }
    }

    func updatePriceTarget(_ target: StockOrderPriceTarget) {
        guard target != .specifiedPrice else { return }
        price = formattedPrice(for: target)
    }

    func decreasePrice() {
        updatePrice(by: -profile.priceStep)
    }

    func increasePrice() {
        updatePrice(by: profile.priceStep)
    }

    func decreaseQuantity() {
        updateQuantity(by: -profile.quantityStep)
    }

    func increaseQuantity() {
        updateQuantity(by: profile.quantityStep)
    }

    func quickInputColumns(language: DemoLanguage) -> [StockOrderQuantityQuickInputColumn] {
        let isDecimal = profile.quantityInputMode.maxFractionDigits != nil
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = isDecimal ? 5 : 0
        formatter.maximumFractionDigits = isDecimal ? 5 : 0

        func value(_ number: Decimal) -> String {
            formatter.string(from: NSDecimalNumber(decimal: number)) ?? "0"
        }

        let baseBuy = isDecimal ? Decimal(string: "1.2345")! : Decimal(2400)
        let baseSell = isDecimal ? Decimal(string: "0.8500")! : Decimal(2000)
        let maximumBuy = profile.maximumPurchasable.flatMap {
            Decimal(string: $0.inputValue, locale: Locale(identifier: "en_US_POSIX"))
        } ?? baseBuy
        let buyOptions = [
            StockOrderQuantityQuickInputItem(
                fractionLabel: language.text(.fullPosition),
                displayQuantity: value(baseBuy),
                inputValue: value(baseBuy)
            ),
            StockOrderQuantityQuickInputItem(
                fractionLabel: "1/2",
                displayQuantity: value(baseBuy / 2),
                inputValue: value(baseBuy / 2)
            ),
            StockOrderQuantityQuickInputItem(
                fractionLabel: "1/4",
                displayQuantity: value(baseBuy / 4),
                inputValue: value(baseBuy / 4)
            )
        ]
        let sellOptions = [
            StockOrderQuantityQuickInputItem(
                fractionLabel: language.text(.fullPosition),
                displayQuantity: value(baseSell),
                inputValue: value(baseSell)
            ),
            StockOrderQuantityQuickInputItem(
                fractionLabel: "1/2",
                displayQuantity: value(baseSell / 2),
                inputValue: value(baseSell / 2)
            ),
            StockOrderQuantityQuickInputItem(
                fractionLabel: "1/4",
                displayQuantity: value(baseSell / 4),
                inputValue: value(baseSell / 4)
            )
        ]

        let columns = [
            StockOrderQuantityQuickInputColumn(
                id: "cashPurchasable",
                title: language.text(.cashPurchasable),
                tone: .buy,
                options: buyOptions
            ),
            StockOrderQuantityQuickInputColumn(
                id: "positionSellable",
                title: language.text(.positionSellable),
                tone: .sell,
                options: sellOptions
            )
        ]

        if profile.maximumPurchasable != nil {
            return [
                columns[0],
                StockOrderQuantityQuickInputColumn(
                    id: "maximumPurchasable",
                    title: language.text(.maximumPurchasable),
                    tone: .buy,
                    options: [
                        StockOrderQuantityQuickInputItem(
                            fractionLabel: language.text(.fullPosition),
                            displayQuantity: value(maximumBuy),
                            inputValue: value(maximumBuy)
                        ),
                        StockOrderQuantityQuickInputItem(
                            fractionLabel: "1/2",
                            displayQuantity: value(maximumBuy / 2),
                            inputValue: value(maximumBuy / 2)
                        ),
                        StockOrderQuantityQuickInputItem(
                            fractionLabel: "1/4",
                            displayQuantity: value(maximumBuy / 4),
                            inputValue: value(maximumBuy / 4)
                        )
                    ]
                ),
                columns[1]
            ]
        }

        return columns
    }

    func todayOrders(language: DemoLanguage) -> [StockOrderTodayOrderItem] {
        let name = language.securityName(id: "wl-us-nvidia", fallback: "NVDA")
        return StockOrderTodayOrderStatus.allCases.enumerated().map { index, status in
            StockOrderTodayOrderItem(
                id: "stock-order-demo-\(status.rawValue)",
                side: index.isMultiple(of: 2) ? .buy : .sell,
                status: status,
                productName: name,
                symbol: "NVDA",
                price: index.isMultiple(of: 2) ? "131.70" : "131.74",
                quantity: "2,000",
                filledQuantity: status == .filled ? "2,000" : (status == .partiallyFilled ? "800" : "0"),
                tag: status == .submitted ? "GTC" : nil,
                actions: StockOrderTodayOrderAction.allCases
            )
        }
    }

    private func updatePrice(by delta: Decimal) {
        let base = Decimal(string: price, locale: Locale(identifier: "en_US_POSIX"))
            ?? profile.currentPrice

        guard let base else { return }
        price = format(base + delta, fractionDigits: profile.priceFractionDigits)
        priceTarget = .specifiedPrice
    }

    private func updateQuantity(by delta: Decimal) {
        let base = Decimal(string: quantity, locale: Locale(identifier: "en_US_POSIX")) ?? 0
        let updated = max(0, base + delta)
        let digits = profile.quantityInputMode.maxFractionDigits ?? 0
        quantity = format(updated, fractionDigits: digits)
    }

    private func formattedPrice(for target: StockOrderPriceTarget) -> String {
        switch target {
        case .specifiedPrice:
            return price
        case .marketPrice:
            return profile.currentPrice.map { format($0, fractionDigits: profile.priceFractionDigits) } ?? price
        case .bidOne:
            return profile.bidLevels.first?.price ?? price
        case .askOne:
            return profile.askLevels.first?.price ?? price
        }
    }

    private func format(_ decimal: Decimal, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = max(0, fractionDigits)
        formatter.maximumFractionDigits = max(0, fractionDigits)
        return formatter.string(from: NSDecimalNumber(decimal: decimal)) ?? "0"
    }

    private static func profile(for symbol: StockOrderSymbol?) -> StockOrderDemoProfile {
        guard let symbol else { return .empty }

        switch symbol.market {
        case .hk:
            return .hongKong
        case .us:
            return .unitedStates
        case .china:
            return .chinaA
        case .crypto:
            return .crypto
        }
    }
}

private extension StockOrderSymbol {
    static let alibaba = StockOrderSymbol(
        id: "09988",
        fallbackName: "阿里巴巴-W",
        localizationID: "wl-hk-alibaba",
        market: .hk,
        quote: .init(
            price: "82.150",
            changePercent: "+2.84%",
            trend: .up,
            miniKPoints: ChartMockData.miniChart_50_point.normalized,
            session: .regular
        ),
        searchAliases: ["alibaba", "阿里巴巴", "ali"]
    )

    static let tencent = StockOrderSymbol(
        id: "00700",
        fallbackName: "腾讯控股",
        localizationID: "wl-hk-tencent",
        market: .hk,
        quote: .init(
            price: "473.120",
            changePercent: "+1.26%",
            trend: .up,
            miniKPoints: ChartMockData.miniChart_50_point.normalized,
            session: .regular
        ),
        searchAliases: ["tencent", "腾讯", "tengxun"]
    )

    static let nvidia = StockOrderSymbol(
        id: "NVDA",
        fallbackName: "英伟达",
        localizationID: "wl-us-nvidia",
        market: .us,
        quote: .init(
            price: "131.72",
            secondaryPrice: "129.80",
            changePercent: "+1.91%",
            trend: .up,
            miniKPoints: ChartMockData.miniChart_50_point.normalized,
            session: .preMarket(change: "+0.72%")
        ),
        searchAliases: ["nvidia", "英伟达", "yingweida"]
    )

    static let hybl = StockOrderSymbol(
        id: "HYBL",
        fallbackName: "海博思创",
        localizationID: "wl-us-hybl",
        market: .us,
        quote: .init(
            price: "24.36",
            secondaryPrice: "24.10",
            changePercent: "-0.54%",
            trend: .down,
            miniKPoints: ChartMockData.miniChart_30_point.normalized,
            session: .afterHours(change: "-0.24%")
        ),
        searchAliases: ["hybl", "海博思创"]
    )

    static let spcx = StockOrderSymbol(
        id: "SPCX",
        fallbackName: "SPACEX",
        localizationID: "wl-us-spcx",
        market: .us,
        quote: .init(
            price: "88.50",
            secondaryPrice: "88.12",
            changePercent: "+0.18%",
            trend: .up,
            miniKPoints: ChartMockData.miniChart_50_point.normalized,
            session: .regular
        ),
        searchAliases: ["spacex", "spcx"]
    )

    static let haitian = StockOrderSymbol(
        id: "600388",
        fallbackName: "海天味业",
        localizationID: "wl-cn-haitian",
        market: .china,
        quote: .init(
            price: "16.400",
            changePercent: "+2.26%",
            trend: .up,
            miniKPoints: ChartMockData.miniChart_50_point.normalized,
            session: .regular
        ),
        searchAliases: ["600388", "海天", "haitian"],
        marketBadgeAssetName: "Glyph_SH"
    )

    static let bitcoin = StockOrderSymbol(
        id: "BTC/USD",
        fallbackName: "比特币/美元",
        localizationID: "wl-crypto-btc",
        market: .crypto,
        quote: .init(
            price: "102345.12",
            changePercent: "+3.43%",
            trend: .up,
            miniKPoints: ChartMockData.miniChart_50_point.normalized,
            session: .regular
        ),
        searchAliases: ["btc", "bitcoin", "比特币", "bitcoin/usd"]
    )
}
