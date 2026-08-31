//
//  StockDetailOrderBook.swift
//  SuperPreview
//

import SwiftUI

/// Markets that use the stock-detail buy/sell book presentation.
enum StockDetailOrderBookMarket: Hashable {
    case hongKong
    case us
    case aShare
    case crypto

    fileprivate var depth: StockOrderBookDepth {
        switch self {
        case .us:
            .one
        case .hongKong, .aShare, .crypto:
            .ten
        }
    }

    fileprivate var showsBrokerCounts: Bool {
        self == .hongKong
    }
}

/// Market-specific data used by the static stock-detail order book.
///
/// Hong Kong supplies broker counts, US presents one best level, and A-share
/// plus crypto deliberately suppress broker counts even when upstream data
/// happens to contain them. All available non-US levels are rendered directly
/// instead of being hidden behind a disclosure control.
struct StockDetailOrderBookData: Equatable {
    let market: StockDetailOrderBookMarket
    let distribution: StockOrderBookDistribution
    let bidLevels: [StockOrderBookLevel]
    let askLevels: [StockOrderBookLevel]

    init(
        market: StockDetailOrderBookMarket,
        distribution: StockOrderBookDistribution,
        bidLevels: [StockOrderBookLevel],
        askLevels: [StockOrderBookLevel]
    ) {
        self.market = market
        self.distribution = distribution
        self.bidLevels = bidLevels
        self.askLevels = askLevels
    }
}

/// A fixed-depth buy/sell book for the stock-detail page.
///
/// It intentionally reuses the stock-order book's pricing, distribution and
/// volume-fill semantics while selecting the correct market depth and broker
/// count policy for the detail page. Unlike the order form, it has no expand
/// or collapse control.
struct StockDetailOrderBook: View {
    let data: StockDetailOrderBookData

    init(data: StockDetailOrderBookData = .hongKongMock) {
        self.data = data
    }

    var body: some View {
        StockOrderBook(
            depth: data.market.depth,
            distribution: data.distribution,
            bidLevels: displayedBidLevels,
            askLevels: displayedAskLevels,
            isExpanded: .constant(true),
            presentation: .fixedDepth,
            fixedLevelCount: displayedLevelCount
        )
        .accessibilityIdentifier("stockDetail.orderBook")
    }

    private var displayedBidLevels: [StockOrderBookLevel] {
        displayedLevels(from: data.bidLevels)
    }

    private var displayedAskLevels: [StockOrderBookLevel] {
        displayedLevels(from: data.askLevels)
    }

    private var displayedLevelCount: Int? {
        guard data.market != .us else {
            return nil
        }

        return max(displayedBidLevels.count, displayedAskLevels.count)
    }

    private func displayedLevels(from levels: [StockOrderBookLevel]) -> [StockOrderBookLevel] {
        let marketLevels: ArraySlice<StockOrderBookLevel>
        switch data.market {
        case .us:
            marketLevels = levels.prefix(1)
        case .hongKong, .aShare, .crypto:
            marketLevels = levels[...]
        }

        return marketLevels.map { level in
            guard !data.market.showsBrokerCounts else {
                return level
            }

            return StockOrderBookLevel(
                id: level.id,
                price: level.price,
                quantity: level.quantity,
                volumeFraction: level.volumeFraction
            )
        }
    }
}

private enum StockDetailOrderBookMockData {
    static let distribution = StockOrderBookDistribution(
        bidPercentage: "84.22%",
        askPercentage: "15.78%",
        bidVolume: 84.22,
        askVolume: 15.78
    )

    static let bidLevels = [
        StockOrderBookLevel(price: "16.400", quantity: "15K", brokerCount: "96", volumeFraction: 0.90),
        StockOrderBookLevel(price: "16.390", quantity: "50K", brokerCount: "325", volumeFraction: 0.60),
        StockOrderBookLevel(price: "16.380", quantity: "20K", brokerCount: "75", volumeFraction: 0.52),
        StockOrderBookLevel(price: "16.370", quantity: "150K", brokerCount: "594", volumeFraction: 0.47),
        StockOrderBookLevel(price: "16.360", quantity: "100K", brokerCount: "464", volumeFraction: 0.43),
        StockOrderBookLevel(price: "16.350", quantity: "10K", brokerCount: "455", volumeFraction: 0.39),
        StockOrderBookLevel(price: "16.340", quantity: "2K", brokerCount: "586", volumeFraction: 0.31),
        StockOrderBookLevel(price: "16.330", quantity: "10K", brokerCount: "788", volumeFraction: 0.24),
        StockOrderBookLevel(price: "16.320", quantity: "100K", brokerCount: "937", volumeFraction: 0.19),
        StockOrderBookLevel(price: "16.310", quantity: "1K", brokerCount: "825", volumeFraction: 0.14)
    ]

    static let askLevels = [
        StockOrderBookLevel(price: "16.500", quantity: "10K", brokerCount: "184", volumeFraction: 0.29),
        StockOrderBookLevel(price: "16.510", quantity: "20K", brokerCount: "920", volumeFraction: 0.59),
        StockOrderBookLevel(price: "16.520", quantity: "10K", brokerCount: "285", volumeFraction: 0.47),
        StockOrderBookLevel(price: "16.530", quantity: "8K", brokerCount: "401", volumeFraction: 0.42),
        StockOrderBookLevel(price: "16.540", quantity: "8K", brokerCount: "603", volumeFraction: 0.36),
        StockOrderBookLevel(price: "16.550", quantity: "100K", brokerCount: "899", volumeFraction: 0.31),
        StockOrderBookLevel(price: "16.560", quantity: "3K", brokerCount: "178", volumeFraction: 0.28),
        StockOrderBookLevel(price: "16.570", quantity: "50K", brokerCount: "634", volumeFraction: 0.22),
        StockOrderBookLevel(price: "16.580", quantity: "150K", brokerCount: "252", volumeFraction: 0.18),
        StockOrderBookLevel(price: "16.590", quantity: "15K", brokerCount: "588", volumeFraction: 0.14)
    ]
}

extension StockDetailOrderBookData {
    static let hongKongMock = StockDetailOrderBookData(
        market: .hongKong,
        distribution: StockDetailOrderBookMockData.distribution,
        bidLevels: StockDetailOrderBookMockData.bidLevels,
        askLevels: StockDetailOrderBookMockData.askLevels
    )

    static let usMock = StockDetailOrderBookData(
        market: .us,
        distribution: StockDetailOrderBookMockData.distribution,
        bidLevels: StockDetailOrderBookMockData.bidLevels,
        askLevels: StockDetailOrderBookMockData.askLevels
    )

    static let aShareMock = StockDetailOrderBookData(
        market: .aShare,
        distribution: StockDetailOrderBookMockData.distribution,
        bidLevels: StockDetailOrderBookMockData.bidLevels,
        askLevels: StockDetailOrderBookMockData.askLevels
    )

    static let aShareThreeLevelsMock = StockDetailOrderBookData(
        market: .aShare,
        distribution: StockDetailOrderBookMockData.distribution,
        bidLevels: Array(StockDetailOrderBookMockData.bidLevels.prefix(3)),
        askLevels: Array(StockDetailOrderBookMockData.askLevels.prefix(3))
    )

    static let cryptoMock = StockDetailOrderBookData(
        market: .crypto,
        distribution: StockDetailOrderBookMockData.distribution,
        bidLevels: StockDetailOrderBookMockData.bidLevels,
        askLevels: StockDetailOrderBookMockData.askLevels
    )
}

struct StockDetailOrderBook_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailOrderBook(data: .hongKongMock)
                .previewDisplayName("Hong Kong · Broker Counts")

            StockDetailOrderBook(data: .usMock)
                .previewDisplayName("US · Best Level")

            StockDetailOrderBook(data: .aShareMock)
                .previewDisplayName("A-Share · No Broker Counts")

            StockDetailOrderBook(data: .aShareThreeLevelsMock)
                .previewDisplayName("A-Share · All Available Levels")

            StockDetailOrderBook(data: .cryptoMock)
                .previewDisplayName("Crypto · No Broker Counts")
        }
        .environment(\.demoLanguage, .simplifiedChinese)
        .frame(width: 402)
        .previewLayout(.sizeThatFits)
    }
}
