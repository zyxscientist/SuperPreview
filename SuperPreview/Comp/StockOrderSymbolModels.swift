//
//  StockOrderSymbolModels.swift
//  SuperPreview
//

import Foundation
import SwiftUI

enum StockOrderMarket: String, CaseIterable, Equatable, Identifiable {
    case hk
    case us
    case china
    case crypto

    var id: String { rawValue }

    var badgeAssetName: String {
        switch self {
        case .hk:
            return "Glyph_HK"
        case .us:
            return "Glyph_US"
        case .china:
            return "Glyph_SZ"
        case .crypto:
            return "market_crypto"
        }
    }
}

enum StockOrderQuoteTrend: Equatable {
    case up
    case down
    case flat
}

extension StockOrderQuoteTrend {
    var tileColor: Color {
        switch self {
        case .up:
            return Color("color-utility3-red")
        case .down:
            return Color("color-utility3-green")
        case .flat:
            return Color("color-text-90")
        }
    }

    var lineColor: Color {
        tileColor
    }
}

enum StockOrderTradingSession: Equatable {
    case regular
    case preMarket(change: String)
    case afterHours(change: String)

    var secondaryChange: String? {
        switch self {
        case .regular:
            return nil
        case let .preMarket(change), let .afterHours(change):
            return change
        }
    }

    var localizationKey: DemoCopyKey? {
        switch self {
        case .regular:
            return nil
        case .preMarket:
            return .preMarket
        case .afterHours:
            return .afterHours
        }
    }
}

enum StockOrderMarketNotice: Equatable {
    case closingAuction(priceRange: String)
    case volatilityCoolingOff(priceRange: String)

    var titleKey: DemoCopyKey {
        switch self {
        case .closingAuction:
            return .closingAuction
        case .volatilityCoolingOff:
            return .volatilityCoolingOff
        }
    }

    var priceRange: String {
        switch self {
        case let .closingAuction(priceRange), let .volatilityCoolingOff(priceRange):
            return priceRange
        }
    }

    var showsCASIcon: Bool {
        if case .closingAuction = self {
            return true
        }
        return false
    }
}

struct StockOrderQuote: Equatable {
    let price: String
    let secondaryPrice: String?
    let changePercent: String
    let trend: StockOrderQuoteTrend
    let miniKPoints: [CGFloat]
    let session: StockOrderTradingSession

    init(
        price: String,
        secondaryPrice: String? = nil,
        changePercent: String,
        trend: StockOrderQuoteTrend,
        miniKPoints: [CGFloat],
        session: StockOrderTradingSession
    ) {
        self.price = price
        self.secondaryPrice = secondaryPrice
        self.changePercent = changePercent
        self.trend = trend
        self.miniKPoints = miniKPoints
        self.session = session
    }
}

struct StockOrderSymbol: Equatable, Identifiable {
    let id: String
    let fallbackName: String
    let localizationID: String?
    let market: StockOrderMarket
    let marketBadgeAssetName: String?
    let quote: StockOrderQuote
    let marketNotice: StockOrderMarketNotice?
    let searchAliases: [String]

    init(
        id: String,
        fallbackName: String,
        localizationID: String? = nil,
        market: StockOrderMarket,
        quote: StockOrderQuote,
        marketNotice: StockOrderMarketNotice? = nil,
        searchAliases: [String] = [],
        marketBadgeAssetName: String? = nil
    ) {
        self.id = id
        self.fallbackName = fallbackName
        self.localizationID = localizationID
        self.market = market
        self.marketBadgeAssetName = marketBadgeAssetName
        self.quote = quote
        self.marketNotice = marketNotice
        self.searchAliases = searchAliases
    }

    var badgeAssetName: String {
        marketBadgeAssetName ?? market.badgeAssetName
    }

    func localizedName(for language: DemoLanguage) -> String {
        localizationID.map { language.securityName(id: $0, fallback: fallbackName) } ?? fallbackName
    }

    func searchableText(for language: DemoLanguage) -> [String] {
        [id, fallbackName, localizedName(for: language)] + searchAliases
    }
}

enum StockOrderSearchAvailability: Equatable {
    case available
    case networkError
}

extension String {
    var stockOrderSearchNormalized: String {
        lowercased()
            .filter { !$0.isWhitespace }
            .folding(options: [.diacriticInsensitive, .widthInsensitive], locale: .current)
    }
}
