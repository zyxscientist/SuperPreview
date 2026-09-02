//
//  StockDetailPageConfiguration.swift
//  SuperPreview
//

import Foundation
import SwiftUI

/// The product kind is deliberately separate from the market. The same market
/// can contain common stocks and ETFs, while crypto has its own quote and
/// transaction rules.
enum StockDetailInstrumentKind: String, CaseIterable, Hashable, Identifiable {
    case stock
    case etf
    case crypto
    case fund
    case other

    var id: String { rawValue }
}

enum StockDetailInstrumentMarket: String, CaseIterable, Hashable, Identifiable {
    case hongKong
    case us
    case aShare
    case crypto
    case fund

    var id: String { rawValue }

    var stockOrderMarket: StockOrderMarket? {
        switch self {
        case .hongKong:
            .hk
        case .us:
            .us
        case .aShare:
            .china
        case .crypto:
            .crypto
        case .fund:
            nil
        }
    }

    var quoteMarket: StockDetailQuoteMarket {
        switch self {
        case .hongKong:
            .hongKong
        case .us:
            .us
        case .aShare, .fund:
            .aShare
        case .crypto:
            .crypto
        }
    }

    var orderBookMarket: StockDetailOrderBookMarket? {
        switch self {
        case .hongKong:
            .hongKong
        case .us:
            .us
        case .aShare:
            .aShare
        case .crypto:
            .crypto
        case .fund:
            nil
        }
    }
}

enum StockDetailInstrumentSession: Hashable {
    case regular
    case closed
    case halted
    case preMarket(change: String)
    case afterHours(change: String)

    var isExtendedHours: Bool {
        switch self {
        case .regular, .closed, .halted:
            false
        case .preMarket, .afterHours:
            true
        }
    }
}

struct StockDetailInstrumentQuote: Hashable {
    let price: String
    let secondaryPrice: String?
    let changePercent: String
    let trend: StockDetailQuoteTrend
    let session: StockDetailInstrumentSession

    init(
        price: String,
        secondaryPrice: String? = nil,
        changePercent: String,
        trend: StockDetailQuoteTrend,
        session: StockDetailInstrumentSession = .regular
    ) {
        self.price = price
        self.secondaryPrice = secondaryPrice
        self.changePercent = changePercent
        self.trend = trend
        self.session = session
    }
}

struct StockDetailInstrument: Hashable, Identifiable {
    let symbol: String
    let fallbackName: String
    let localizationID: String?
    let market: StockDetailInstrumentMarket
    let kind: StockDetailInstrumentKind
    let quote: StockDetailInstrumentQuote

    var id: String {
        "\(market.rawValue):\(symbol)"
    }

    init(
        symbol: String,
        fallbackName: String,
        localizationID: String? = nil,
        market: StockDetailInstrumentMarket,
        kind: StockDetailInstrumentKind,
        quote: StockDetailInstrumentQuote
    ) {
        self.symbol = symbol
        self.fallbackName = fallbackName
        self.localizationID = localizationID
        self.market = market
        self.kind = kind
        self.quote = quote
    }
}

/// The tabs are shared by every detail-page variant. A configuration only
/// chooses an ordered subset, which keeps the paging shell and its liquid-glass
/// selection surface identical across markets.
enum StockDetailPageTab: String, Hashable, Identifiable {
    case quote
    case warrants
    case options
    case etf
    case data
    case analysis
    case news
    case financials
    case overview

    var id: String { rawValue }

    func title(for language: DemoLanguage) -> String {
        language.text(copyKey)
    }

    private var copyKey: DemoCopyKey {
        switch self {
        case .quote:
            .stockDetailTabQuote
        case .warrants:
            .stockDetailTabWarrants
        case .options:
            .stockDetailTabOptions
        case .etf:
            .stockDetailTabETF
        case .data:
            .stockDetailTabData
        case .analysis:
            .stockDetailTabAnalysis
        case .news:
            .stockDetailTabNews
        case .financials:
            .stockDetailTabFinancials
        case .overview:
            .stockDetailTabOverview
        }
    }

    var accessibilityIdentifier: String {
        "stockDetail.pageTab.\(rawValue)"
    }
}

enum StockDetailPageVariant: String, Hashable, Identifiable {
    case hongKongStock
    case hongKongETF
    case usStock
    case usETF
    case aShareStock
    case aShareETF
    case crypto
    case fallback

    var id: String { rawValue }

    var debugTitleKey: DemoCopyKey {
        switch self {
        case .hongKongStock:
            .stockDetailVariantHongKongStock
        case .hongKongETF:
            .stockDetailVariantHongKongETF
        case .usStock:
            .stockDetailVariantUSStock
        case .usETF:
            .stockDetailVariantUSETF
        case .aShareStock:
            .stockDetailVariantAShareStock
        case .aShareETF:
            .stockDetailVariantAShareETF
        case .crypto:
            .stockDetailVariantCrypto
        case .fallback:
            .stockDetailVariantOther
        }
    }

    init(instrument: StockDetailInstrument) {
        switch (instrument.market, instrument.kind) {
        case (.hongKong, .stock):
            self = .hongKongStock
        case (.hongKong, .etf):
            self = .hongKongETF
        case (.us, .stock):
            self = .usStock
        case (.us, .etf):
            self = .usETF
        case (.aShare, .stock):
            self = .aShareStock
        case (.aShare, .etf):
            self = .aShareETF
        case (.crypto, .crypto):
            self = .crypto
        default:
            self = .fallback
        }
    }

    var tabs: [StockDetailPageTab] {
        switch self {
        case .hongKongStock:
            [.quote, .warrants, .analysis, .news, .financials, .overview]
        case .hongKongETF:
            [.quote, .news, .analysis, .overview]
        case .usStock:
            [.quote, .options, .etf, .analysis, .news, .financials, .overview]
        case .usETF:
            [.quote, .news, .overview]
        case .aShareStock, .aShareETF:
            [.quote, .analysis, .news, .overview]
        case .crypto:
            [.quote, .data, .news, .overview]
        case .fallback:
            [.quote]
        }
    }

    var showsRelatedInfo: Bool {
        self != .crypto && self != .fallback
    }

    var showsTransactionModule: Bool {
        self != .fallback
    }

    var showsOrderBook: Bool {
        self != .fallback
    }

    var showsBrokerOrderBook: Bool {
        self == .hongKongStock || self == .hongKongETF
    }

    var showsCapitalDistribution: Bool {
        switch self {
        case .hongKongStock, .hongKongETF, .usStock, .usETF, .aShareStock, .aShareETF:
            true
        case .crypto, .fallback:
            false
        }
    }

    var showsMoneyFlow: Bool {
        showsCapitalDistribution
    }

    var quoteDetailInstrument: StockDetailQuoteDetailInstrument {
        switch self {
        case .hongKongETF, .usETF, .aShareETF:
            .etf
        case .crypto:
            .crypto
        default:
            .stock
        }
    }
}

struct StockDetailPageConfiguration {
    let instrument: StockDetailInstrument
    let symbol: StockOrderSymbol
    let variant: StockDetailPageVariant
    let tabs: [StockDetailPageTab]
    let quoteData: StockDetailQuoteDataModel
    let relatedItems: [StockDetailRelatedInfoItem]
    let orderBookData: StockDetailOrderBookData?
    let brokerOrderBookData: StockDetailBrokerOrderBookData?
    let capitalDistributionData: StockDetailCapitalDistributionData?
    let moneyFlowData: StockDetailMoneyFlowTrendData?
    let positionState: StockDetailTransactionPositionState?
    let transactionOrders: [StockOrderTodayOrderItem]?
    let historyOrders: [StockDetailTransactionHistoryOrderData]?
}

enum StockDetailPageConfigurationFactory {
    static func make(
        for instrument: StockDetailInstrument,
        includesBelowChartComponents: Bool = true
    ) -> StockDetailPageConfiguration {
        let variant = StockDetailPageVariant(instrument: instrument)
        let symbol = makeOrderSymbol(for: instrument)
        let quoteData = makeQuoteData(for: instrument, variant: variant)

        return StockDetailPageConfiguration(
            instrument: instrument,
            symbol: symbol,
            variant: variant,
            tabs: variant.tabs,
            quoteData: quoteData,
            relatedItems: variant.showsRelatedInfo ? relatedItems(for: instrument, variant: variant) : [],
            orderBookData: includesBelowChartComponents && variant.showsOrderBook
                ? orderBookData(for: instrument)
                : nil,
            brokerOrderBookData: includesBelowChartComponents && variant.showsBrokerOrderBook
                ? brokerOrderBookData(for: instrument)
                : nil,
            capitalDistributionData: includesBelowChartComponents && variant.showsCapitalDistribution
                ? .mock
                : nil,
            moneyFlowData: includesBelowChartComponents && variant.showsMoneyFlow
                ? .mock
                : nil,
            positionState: includesBelowChartComponents && variant.showsTransactionModule
                ? positionState(for: instrument)
                : nil,
            transactionOrders: includesBelowChartComponents && variant.showsTransactionModule
                ? transactionOrders(for: instrument)
                : nil,
            historyOrders: includesBelowChartComponents && variant.showsTransactionModule
                ? historyOrders(for: instrument)
                : nil
        )
    }

    private static func makeOrderSymbol(for instrument: StockDetailInstrument) -> StockOrderSymbol {
        let market = instrument.market.stockOrderMarket ?? .us
        let session: StockOrderTradingSession

        switch instrument.quote.session {
        case .regular:
            session = .regular
        case .closed, .halted:
            // The order-form quote model has no closed/halted session. Keep
            // its input shape valid while QuoteData retains the exact status.
            session = .regular
        case let .preMarket(change):
            session = .preMarket(change: signedPercent(change, trend: instrument.quote.trend))
        case let .afterHours(change):
            session = .afterHours(change: signedPercent(change, trend: instrument.quote.trend))
        }

        let badgeAssetName: String?
        if market == .china {
            badgeAssetName = instrument.symbol == "513100" || instrument.symbol.hasPrefix("6")
                ? "Glyph_SH"
                : "Glyph_SZ"
        } else {
            badgeAssetName = nil
        }

        return StockOrderSymbol(
            id: instrument.symbol,
            fallbackName: instrument.fallbackName,
            localizationID: instrument.localizationID,
            market: market,
            quote: StockOrderQuote(
                price: instrument.quote.price,
                secondaryPrice: instrument.quote.secondaryPrice,
                changePercent: signedPercent(instrument.quote.changePercent, trend: instrument.quote.trend),
                trend: instrument.quote.stockOrderTrend,
                miniKPoints: Array(repeating: 0.5, count: 50),
                session: session
            ),
            searchAliases: [instrument.symbol, instrument.fallbackName],
            marketBadgeAssetName: badgeAssetName
        )
    }

    private static func makeQuoteData(
        for instrument: StockDetailInstrument,
        variant: StockDetailPageVariant
    ) -> StockDetailQuoteDataModel {
        let fractionDigits = decimalPlaces(instrument.quote.price)
        let numericPrice = max(instrument.quote.price.numericStockDetailValue, 0)
        let absolutePercent = abs(instrument.quote.changePercent.numericStockDetailValue)
        let changeAmount = numericPrice * absolutePercent / 100
        let signedChange = signedNumber(
            changeAmount,
            fractionDigits: max(fractionDigits, 2),
            trend: instrument.quote.trend
        )
        let high = format(
            numericPrice + max(changeAmount * 1.4, pow(10, -Double(max(fractionDigits, 2)))),
            fractionDigits: fractionDigits
        )
        let low = format(
            max(numericPrice - max(changeAmount * 1.1, pow(10, -Double(max(fractionDigits, 2)))), 0),
            fractionDigits: fractionDigits
        )
        let turnover = turnoverValues(for: numericPrice)

        return StockDetailQuoteDataModel(
            market: instrument.market.quoteMarket,
            timestamp: timestamp(for: instrument),
            price: instrument.quote.price,
            change: signedChange,
            changePercent: signedPercent(instrument.quote.changePercent, trend: instrument.quote.trend),
            trend: instrument.quote.trend,
            summaryItems: [
                StockDetailQuoteSummaryItem(
                    localizedLabel: .init(
                        simplifiedChinese: "最高",
                        traditionalChinese: "最高",
                        english: "High"
                    ),
                    value: high,
                    tone: .positive
                ),
                StockDetailQuoteSummaryItem(
                    localizedLabel: .init(
                        simplifiedChinese: "最低",
                        traditionalChinese: "最低",
                        english: "Low"
                    ),
                    value: low,
                    tone: .negative
                ),
                StockDetailQuoteSummaryItem(
                    localizedLabel: .init(
                        simplifiedChinese: "成交额",
                        traditionalChinese: "成交額",
                        english: "Turnover"
                    ),
                    value: turnover.chinese,
                    localizedValue: .init(
                        simplifiedChinese: turnover.chinese,
                        traditionalChinese: turnover.traditionalChinese,
                        english: turnover.english
                    )
                )
            ],
            details: makeQuoteDetails(for: variant)
        )
    }

    private static func timestamp(for instrument: StockDetailInstrument) -> StockDetailQuoteTimestamp {
        let session: StockDetailTradingSession
        switch instrument.quote.session {
        case .regular:
            session = .trading
        case .closed:
            session = .closed
        case .halted:
            session = .halted
        case .preMarket:
            session = .preMarketTrading
        case .afterHours:
            session = .afterHoursTrading
        }

        let timeZone: StockDetailQuoteLocalizedText?
        switch instrument.market {
        case .hongKong:
            timeZone = nil
        case .us:
            timeZone = .init(simplifiedChinese: "(美东)", traditionalChinese: "(美東)", english: "(ET)")
        case .aShare:
            timeZone = nil
        case .crypto:
            timeZone = nil
        case .fund:
            timeZone = .init(simplifiedChinese: "(北京)", traditionalChinese: "(北京)", english: "(CST)")
        }

        return StockDetailQuoteTimestamp(
            session: session,
            date: "08/31",
            time: "14:44:01",
            localizedTimeZone: timeZone
        )
    }

    private static func makeQuoteDetails(for variant: StockDetailPageVariant) -> StockDetailQuoteDetailsData? {
        switch variant.quoteDetailInstrument {
        case .stock:
            return switch variant {
            case .aShareStock:
                .stockAShare
            default:
                .stockHongKongOrUS
            }
        case .etf:
            return switch variant {
            case .aShareETF:
                .etfAShare
            default:
                .etfHongKongOrUS
            }
        case .crypto:
            return .crypto
        case .index:
            return .index
        case .bullBearCertificate:
            return .bullBearCertificate
        case .warrantOrInlineCertificate:
            return .warrantOrInlineCertificate
        }
    }

    private static func relatedItems(
        for instrument: StockDetailInstrument,
        variant: StockDetailPageVariant
    ) -> [StockDetailRelatedInfoItem] {
        switch variant {
        case .hongKongStock:
            // A regular HK stock should not present every exchange-specific
            // feature at once. CAS, VCM, linked quotes, and dual counters
            // are eligibility- or event-dependent and can be added by the
            // real data source when they actually apply.
            return [
                StockDetailRelatedInfoPreviewData.financialReport,
                StockDetailRelatedInfoPreviewData.cashDividend
            ]
        case .hongKongETF:
            return [
                StockDetailRelatedInfoPreviewData.financialReport,
                StockDetailRelatedInfoPreviewData.shareConnection
            ]
        case .usStock:
            return [
                StockDetailRelatedInfoPreviewData.usFinancialReport,
                StockDetailRelatedInfoPreviewData.cashDividend
            ] + extendedHoursItems(for: instrument)
        case .usETF:
            return [StockDetailRelatedInfoPreviewData.usFinancialReport] + extendedHoursItems(for: instrument)
        case .aShareStock:
            return [
                StockDetailRelatedInfoPreviewData.financialReport,
                StockDetailRelatedInfoPreviewData.aShareConnection
            ]
        case .aShareETF:
            return [StockDetailRelatedInfoPreviewData.aShareConnection]
        case .crypto, .fallback:
            return []
        }
    }

    private static func extendedHoursItems(
        for instrument: StockDetailInstrument
    ) -> [StockDetailRelatedInfoItem] {
        guard instrument.quote.session.isExtendedHours else { return [] }

        let isPreMarket: Bool
        switch instrument.quote.session {
        case .preMarket:
            isPreMarket = true
        case .afterHours:
            isPreMarket = false
        case .regular, .closed, .halted:
            return []
        }

        let sessionTitle = isPreMarket ? "盘前" : "盘后"
        let traditionalSessionTitle = isPreMarket ? "盤前" : "盤後"
        let englishSessionTitle = isPreMarket ? "Pre-market" : "After-hours"
        let sessionChangePercent: String
        switch instrument.quote.session {
        case let .preMarket(change), let .afterHours(change):
            sessionChangePercent = signedPercent(change, trend: instrument.quote.trend)
        case .regular, .closed, .halted:
            return []
        }
        let price = instrument.quote.secondaryPrice ?? instrument.quote.price
        let numericPrice = max(price.numericStockDetailValue, 0)
        let fractionDigits = decimalPlaces(price)
        let percent = abs(sessionChangePercent.numericStockDetailValue)
        let changeAmount = numericPrice * percent / 100
        let high = format(numericPrice + max(changeAmount, 0.01), fractionDigits: fractionDigits)
        let low = format(max(numericPrice - max(changeAmount, 0.01), 0), fractionDigits: fractionDigits)
        let change = signedNumber(
            changeAmount,
            fractionDigits: max(fractionDigits, 2),
            trend: instrument.quote.trend
        )

        let metrics = [
            StockDetailRelatedInfoMetric(
                label: "最高价",
                value: high,
                tone: .positive,
                localizedLabel: .init(
                    simplifiedChinese: "最高价",
                    traditionalChinese: "最高價",
                    english: "High"
                )
            ),
            StockDetailRelatedInfoMetric(
                label: "成交额",
                value: "4001.22万",
                localizedLabel: .init(
                    simplifiedChinese: "成交额",
                    traditionalChinese: "成交額",
                    english: "Turnover"
                ),
                localizedValue: .init(
                    simplifiedChinese: "4001.22万",
                    traditionalChinese: "4001.22萬",
                    english: "40.0122M"
                )
            ),
            StockDetailRelatedInfoMetric(
                label: "最低价",
                value: low,
                tone: .negative,
                localizedLabel: .init(
                    simplifiedChinese: "最低价",
                    traditionalChinese: "最低價",
                    english: "Low"
                )
            ),
            StockDetailRelatedInfoMetric(
                label: "成交量",
                value: "44.99万股",
                localizedLabel: .init(
                    simplifiedChinese: "成交量",
                    traditionalChinese: "成交量",
                    english: "Volume"
                ),
                localizedValue: .init(
                    simplifiedChinese: "44.99万股",
                    traditionalChinese: "44.99萬股",
                    english: "449.9K shares"
                )
            )
        ]

        let extendedHours = StockDetailRelatedInfoExtendedHours(
            state: .trading,
            sessionTitle: sessionTitle,
            price: price,
            change: change,
            changePercent: sessionChangePercent,
            timestamp: "8:01 美东",
            metrics: metrics,
            localizedSessionTitle: .init(
                simplifiedChinese: sessionTitle,
                traditionalChinese: traditionalSessionTitle,
                english: englishSessionTitle
            ),
            localizedTimestamp: .init(
                simplifiedChinese: "8:01 美东",
                traditionalChinese: "8:01 美東",
                english: "8:01 ET"
            )
        )

        return [
            StockDetailRelatedInfoItem(
                id: "\(instrument.symbol)-extended-hours",
                content: .extendedHours(extendedHours)
            )
        ]
    }

    private static func orderBookData(for instrument: StockDetailInstrument) -> StockDetailOrderBookData? {
        guard let market = instrument.market.orderBookMarket else { return nil }

        let basePrice = max(instrument.quote.price.numericStockDetailValue, 0.01)
        let fractionDigits = decimalPlaces(instrument.quote.price)
        let step = pow(10, -Double(max(fractionDigits, 2)))
        let bidQuantities = ["15K", "50K", "20K", "150K", "100K", "10K", "2K", "10K", "100K", "1K"]
        let askQuantities = ["10K", "20K", "10K", "8K", "8K", "100K", "3K", "50K", "150K", "15K"]

        let bidLevels = bidQuantities.enumerated().map { index, quantity in
            StockOrderBookLevel(
                id: levelID(index: index, side: 0),
                price: format(max(basePrice - step * Double(index + 1), 0), fractionDigits: fractionDigits),
                quantity: quantity,
                brokerCount: market == .hongKong ? "\(96 + index * 31)" : nil,
                volumeFraction: CGFloat(max(0.14, 0.9 - Double(index) * 0.08)
                )
            )
        }

        let askLevels = askQuantities.enumerated().map { index, quantity in
            StockOrderBookLevel(
                id: levelID(index: index, side: 1),
                price: format(basePrice + step * Double(index + 1), fractionDigits: fractionDigits),
                quantity: quantity,
                brokerCount: market == .hongKong ? "\(184 + index * 29)" : nil,
                volumeFraction: CGFloat(max(0.14, 0.29 + Double(index) * 0.07)
                )
            )
        }

        let bidFraction: CGFloat
        switch instrument.quote.trend {
        case .up:
            bidFraction = 0.68
        case .down:
            bidFraction = 0.32
        case .flat:
            bidFraction = 0.5
        }
        let bidPercentage = Int((bidFraction * 100).rounded())

        return StockDetailOrderBookData(
            market: market,
            distribution: StockOrderBookDistribution(
                bidPercentage: "\(bidPercentage)%",
                askPercentage: "\(100 - bidPercentage)%",
                bidFraction: bidFraction
            ),
            bidLevels: bidLevels,
            askLevels: askLevels
        )
    }

    private static func brokerOrderBookData(
        for instrument: StockDetailInstrument
    ) -> StockDetailBrokerOrderBookData? {
        guard instrument.market == .hongKong else { return nil }

        let basePrice = max(instrument.quote.price.numericStockDetailValue, 0.01)
        let fractionDigits = decimalPlaces(instrument.quote.price)
        let step = pow(10, -Double(max(fractionDigits, 2)))
        let bidPrices = (0..<3).map {
            format(max(basePrice - step * Double($0 + 1), 0), fractionDigits: fractionDigits)
        }
        let askPrices = (0..<3).map {
            format(basePrice + step * Double($0 + 1), fractionDigits: fractionDigits)
        }

        let bidRows: [StockDetailBrokerOrderBookRow] = [
            .level(.init(rank: 1, price: bidPrices[0], quantity: "15K", brokerCount: "3", volumeFraction: 0.9, showsVolumeFill: true)),
            .seat(.init(code: "0123", brokerName: "富途证券")),
            .seat(.init(code: "0456", brokerName: "中银国际")),
            .level(.init(rank: 2, price: bidPrices[1], quantity: "50K", brokerCount: "2")),
            .seat(.init(code: "0789", brokerName: "华泰证券")),
            .level(.init(rank: 3, price: bidPrices[2], quantity: "20K", brokerCount: "4")),
            .seat(.init(code: "1023", brokerName: "国泰君安")),
            .seat(.init(code: "1567", brokerName: "耀才证券"))
        ]
        let askRows: [StockDetailBrokerOrderBookRow] = [
            .level(.init(rank: 1, price: askPrices[0], quantity: "10K", brokerCount: "2", volumeFraction: 0.29, showsVolumeFill: true)),
            .seat(.init(code: "2345", brokerName: "中信建投")),
            .seat(.init(code: "2678", brokerName: "招商证券")),
            .level(.init(rank: 2, price: askPrices[1], quantity: "20K", brokerCount: "3")),
            .seat(.init(code: "3012", brokerName: "盈透证券")),
            .level(.init(rank: 3, price: askPrices[2], quantity: "10K", brokerCount: "1")),
            .seat(.init(code: "3456", brokerName: "华盛证券"))
        ]

        return StockDetailBrokerOrderBookData(bidRows: bidRows, askRows: askRows)
    }

    private static func positionState(
        for instrument: StockDetailInstrument
    ) -> StockDetailTransactionPositionState {
        let price = instrument.quote.price.numericStockDetailValue
        let marketValue = format(max(price * 1_500, 0), fractionDigits: 2)

        return .position(
            StockDetailTransactionPositionData(
                positionProfitLoss: "+6,100.00",
                positionProfitLossRate: "+9.53%",
                todayProfitLoss: "+1,123.01",
                quantity: "1,500",
                marketValue: marketValue,
                costPrice: format(max(price * 0.91, 0), fractionDigits: max(decimalPlaces(instrument.quote.price), 2)),
                portfolioWeight: "8.38%",
                positionProfitLossTone: .gain,
                todayProfitLossTone: .gain
            )
        )
    }

    private static func transactionOrders(
        for instrument: StockDetailInstrument
    ) -> [StockOrderTodayOrderItem] {
        [
            StockOrderTodayOrderItem(
                id: "\(instrument.id)-submitted",
                side: .buy,
                status: .submitted,
                productName: instrument.fallbackName,
                symbol: instrument.symbol,
                price: instrument.quote.price,
                quantity: "500",
                filledQuantity: "0"
            ),
            StockOrderTodayOrderItem(
                id: "\(instrument.id)-partial",
                side: .sell,
                status: .partiallyFilled,
                productName: instrument.fallbackName,
                symbol: instrument.symbol,
                price: instrument.quote.price,
                quantity: "1,000",
                filledQuantity: "500"
            )
        ]
    }

    private static func historyOrders(
        for instrument: StockDetailInstrument
    ) -> [StockDetailTransactionHistoryOrderData] {
        [
            StockDetailTransactionHistoryOrderData(
                id: "\(instrument.id)-history-filled",
                side: .buy,
                status: .filled,
                productName: instrument.fallbackName,
                symbol: instrument.symbol,
                price: instrument.quote.price,
                quantity: "500",
                orderDate: "26/08/28",
                orderTime: "14:37:06"
            ),
            StockDetailTransactionHistoryOrderData(
                id: "\(instrument.id)-history-cancelled",
                side: .sell,
                status: .cancelled,
                productName: instrument.fallbackName,
                symbol: instrument.symbol,
                price: instrument.quote.price,
                quantity: "200",
                orderDate: "26/08/27",
                orderTime: "09:42:18"
            )
        ]
    }

    private static func turnoverValues(for price: Double) -> (chinese: String, traditionalChinese: String, english: String) {
        let amount = max(price * 2_400_000, 0)
        let chineseAmount = amount / 100_000_000
        let englishAmount = amount / 1_000_000

        return (
            String(format: "%.2f亿", chineseAmount),
            String(format: "%.2f億", chineseAmount),
            String(format: "%.2fM", englishAmount)
        )
    }

    private static func signedPercent(
        _ value: String,
        trend: StockDetailQuoteTrend
    ) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let first = trimmed.first, first == "+" || first == "-" else {
            switch trend {
            case .up:
                return "+\(trimmed)"
            case .down:
                return "-\(trimmed)"
            case .flat:
                return trimmed
            }
        }

        return trimmed
    }

    private static func signedNumber(
        _ value: Double,
        fractionDigits: Int,
        trend: StockDetailQuoteTrend
    ) -> String {
        let absoluteValue = abs(value)
        let formatted = format(absoluteValue, fractionDigits: fractionDigits)

        switch trend {
        case .up:
            return "+\(formatted)"
        case .down:
            return "-\(formatted)"
        case .flat:
            return formatted
        }
    }

    private static func format(_ value: Double, fractionDigits: Int) -> String {
        String(format: "%.\(max(fractionDigits, 0))f", value)
    }

    private static func decimalPlaces(_ value: String) -> Int {
        guard let dot = value.firstIndex(of: ".") else { return 0 }
        return value.distance(from: value.index(after: dot), to: value.endIndex)
    }

    private static func levelID(index: Int, side: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", side * 100 + index + 1))!
    }
}

private extension StockDetailInstrumentQuote {
    var stockOrderTrend: StockOrderQuoteTrend {
        switch trend {
        case .up:
            .up
        case .down:
            .down
        case .flat:
            .flat
        }
    }
}

private extension String {
    var numericStockDetailValue: Double {
        Double(
            replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: "%", with: "")
                .replacingOccurrences(of: "+", with: "")
                .replacingOccurrences(of: "-", with: "")
        ) ?? 0
    }
}

private enum StockDetailInstrumentLocalization {
    static let ids: [String: String] = [
        "09988": "wl-hk-alibaba",
        "00700": "wl-hk-tencent",
        "01810": "wl-hk-xiaomi",
        "03690": "wl-hk-meituan",
        "300750": "wl-cn-catl",
        "600519": "wl-cn-moutai",
        "002594": "wl-cn-byd",
        "600036": "wl-cn-cmb",
        "NVDA": "wl-us-nvidia",
        "AAPL": "wl-us-apple",
        "TSLA": "wl-us-tesla",
        "MSFT": "wl-us-microsoft",
        "03032": "wl-etf-hstech",
        "513100": "wl-etf-nasdaq-cn",
        "LU012376428": "wl-fund-energy",
        "VOO": "wl-etf-voo",
        "QQQ": "wl-etf-qqq",
        "BTC/USD": "wl-crypto-btc",
        "ETH/USD": "wl-crypto-eth",
        "BABA": "wl-us-alibaba",
        "FXI": "wl-etf-fxi"
    ]
}

extension WatchlistRedesignItem {
    var stockDetailInstrument: StockDetailInstrument {
        let detailMarket: StockDetailInstrumentMarket
        switch market {
        case .hk:
            detailMarket = .hongKong
        case .cn:
            detailMarket = .aShare
        case .us:
            detailMarket = .us
        case .crypto:
            detailMarket = .crypto
        case .fund:
            detailMarket = .fund
        }

        let detailTrend: StockDetailQuoteTrend
        switch trend {
        case .up:
            detailTrend = .up
        case .down:
            detailTrend = .down
        case .flat:
            detailTrend = .flat
        }

        let detailSession: StockDetailInstrumentSession
        switch session {
        case .regular:
            detailSession = .regular
        case let .preMarket(_, change):
            detailSession = .preMarket(change: change)
        case let .afterHours(_, change):
            detailSession = .afterHours(change: change)
        }

        return StockDetailInstrument(
            symbol: symbol,
            fallbackName: name,
            localizationID: StockDetailInstrumentLocalization.ids[symbol],
            market: detailMarket,
            kind: instrumentKind,
            quote: StockDetailInstrumentQuote(
                price: price,
                secondaryPrice: secondaryPrice,
                changePercent: changePercent,
                trend: detailTrend,
                session: detailSession
            )
        )
    }
}

extension StockDetailInstrument {
    static let nvidiaPreview = StockDetailInstrument(
        symbol: "NVDA",
        fallbackName: "英伟达",
        localizationID: "wl-us-nvidia",
        market: .us,
        kind: .stock,
        quote: .init(
            price: "142.610",
            secondaryPrice: "142.940",
            changePercent: "11.23%",
            trend: .up,
            session: .afterHours(change: "+0.23%")
        )
    )
}

enum StockDetailDebugSamples {
    static let all: [StockDetailInstrument] = [
        StockDetailInstrument(
            symbol: "09988",
            fallbackName: "阿里巴巴-W",
            localizationID: "wl-hk-alibaba",
            market: .hongKong,
            kind: .stock,
            quote: .init(price: "118.600", changePercent: "2.36%", trend: .up)
        ),
        StockDetailInstrument(
            symbol: "03032",
            fallbackName: "恒生科技ETF",
            localizationID: "wl-etf-hstech",
            market: .hongKong,
            kind: .etf,
            quote: .init(price: "4.812", changePercent: "2.02%", trend: .up)
        ),
        .nvidiaPreview,
        StockDetailInstrument(
            symbol: "VOO",
            fallbackName: "先锋标普500ETF",
            localizationID: "wl-etf-voo",
            market: .us,
            kind: .etf,
            quote: .init(
                price: "512.330",
                secondaryPrice: "512.120",
                changePercent: "0.38%",
                trend: .down,
                session: .afterHours(change: "-0.04%")
            )
        ),
        StockDetailInstrument(
            symbol: "300750",
            fallbackName: "宁德时代",
            localizationID: "wl-cn-catl",
            market: .aShare,
            kind: .stock,
            quote: .init(price: "189.61", changePercent: "1.66%", trend: .up)
        ),
        StockDetailInstrument(
            symbol: "513100",
            fallbackName: "纳指100ETF",
            localizationID: "wl-etf-nasdaq-cn",
            market: .aShare,
            kind: .etf,
            quote: .init(price: "1.482", changePercent: "0.61%", trend: .up)
        ),
        StockDetailInstrument(
            symbol: "BTC/USD",
            fallbackName: "比特币/美元",
            localizationID: "wl-crypto-btc",
            market: .crypto,
            kind: .crypto,
            quote: .init(price: "66666.61", changePercent: "6.66%", trend: .up)
        )
    ]
}
