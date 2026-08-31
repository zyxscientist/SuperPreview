//
//  StockDetailBrokerOrderBook.swift
//  SuperPreview
//

import Foundation
import SwiftUI

/// The rows shown in the Hong Kong broker buy/sell order book.
///
/// A price level introduces a queue of broker seats, while a seat row keeps
/// the broker code and name visible until the next price level.
enum StockDetailBrokerOrderBookRow: Equatable {
    case level(StockDetailBrokerOrderBookLevel)
    case seat(StockDetailBrokerOrderBookSeat)
}

/// One priced buy or sell level that introduces its broker-seat queue.
struct StockDetailBrokerOrderBookLevel: Equatable {
    let rank: Int
    let price: String
    let quantity: String
    let brokerCount: String
    let volumeFraction: CGFloat
    let showsVolumeFill: Bool

    init(
        rank: Int,
        price: String,
        quantity: String,
        brokerCount: String,
        volumeFraction: CGFloat = 0,
        showsVolumeFill: Bool = false
    ) {
        self.rank = rank
        self.price = price
        self.quantity = quantity
        self.brokerCount = brokerCount
        self.volumeFraction = min(max(volumeFraction, 0), 1)
        self.showsVolumeFill = showsVolumeFill
    }
}

/// A Hong Kong Exchange broker seat associated with an order-book level.
struct StockDetailBrokerOrderBookSeat: Equatable {
    let code: String
    let brokerName: String

    init(code: String, brokerName: String) {
        self.code = code
        self.brokerName = brokerName
    }
}

/// Input data for the Hong Kong-only broker buy/sell order book.
///
/// The visual supports ten queue rows per side, matching the static depth
/// label at the upper-right corner. Extra rows are intentionally discarded.
struct StockDetailBrokerOrderBookData: Equatable {
    let bidRows: [StockDetailBrokerOrderBookRow]
    let askRows: [StockDetailBrokerOrderBookRow]

    init(
        bidRows: [StockDetailBrokerOrderBookRow],
        askRows: [StockDetailBrokerOrderBookRow]
    ) {
        self.bidRows = Array(bidRows.prefix(StockDetailBrokerOrderBookLayout.maximumRowCount))
        self.askRows = Array(askRows.prefix(StockDetailBrokerOrderBookLayout.maximumRowCount))
    }
}

/// A Hong Kong-only broker-seat order book for the stock-detail page.
///
/// The depth indicator is deliberately static in this prototype. It reflects
/// the Figma state, but does not change the shown depth or attach an action.
struct StockDetailBrokerOrderBook: View {
    let data: StockDetailBrokerOrderBookData

    @Environment(\.demoLanguage) private var language

    init(data: StockDetailBrokerOrderBookData = .mock) {
        self.data = data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StockDetailBrokerOrderBookLayout.headerToGridSpacing) {
            header
            orderBookGrid
        }
        .padding(.top, StockDetailBrokerOrderBookLayout.topPadding)
        .padding(.horizontal, StockDetailBrokerOrderBookLayout.horizontalPadding)
        .padding(.bottom, StockDetailBrokerOrderBookLayout.bottomPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.brokerOrderBook")
    }

    private var header: some View {
        HStack(spacing: 0) {
            Text(language.text(.brokerBuy))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                Text(language.text(.brokerSell))

                Spacer(minLength: 0)

                Image("stock_detail_broker_orderbook_depth_10")
                    .resizable()
                    .frame(
                        width: StockDetailBrokerOrderBookLayout.depthGlyphSize,
                        height: StockDetailBrokerOrderBookLayout.depthGlyphSize
                    )
                    .accessibilityLabel(language.text(.tenLevels))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .modifier(
            CustomFontModifier(
                size: StockDetailBrokerOrderBookLayout.headerFontSize,
                font: .regular,
                lineHeight: StockDetailBrokerOrderBookLayout.headerLineHeight
            )
        )
        .foregroundColor(Color("color-text-30"))
        .frame(height: StockDetailBrokerOrderBookLayout.headerHeight)
    }

    private var orderBookGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<displayedRowCount, id: \.self) { index in
                HStack(spacing: 0) {
                    rowCell(row(at: index, in: data.bidRows), side: .bid)
                    rowCell(row(at: index, in: data.askRows), side: .ask)
                }
                .frame(height: StockDetailBrokerOrderBookLayout.rowHeight)
            }
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: StockDetailBrokerOrderBookLayout.cornerRadius,
                style: .continuous
            )
        )
    }

    private var displayedRowCount: Int {
        min(
            max(data.bidRows.count, data.askRows.count),
            StockDetailBrokerOrderBookLayout.maximumRowCount
        )
    }

    @ViewBuilder
    private func rowCell(
        _ row: StockDetailBrokerOrderBookRow?,
        side: StockDetailBrokerOrderBookSide
    ) -> some View {
        switch row {
        case let .level(level):
            StockDetailBrokerOrderBookLevelCell(level: level, side: side)
        case let .seat(seat):
            StockDetailBrokerOrderBookSeatCell(seat: seat, side: side)
        case nil:
            side.tint.opacity(StockDetailBrokerOrderBookLayout.seatBackgroundOpacity)
        }
    }

    private func row(
        at index: Int,
        in rows: [StockDetailBrokerOrderBookRow]
    ) -> StockDetailBrokerOrderBookRow? {
        guard rows.indices.contains(index) else {
            return nil
        }

        return rows[index]
    }
}

private enum StockDetailBrokerOrderBookLayout {
    static let maximumRowCount = 10
    static let horizontalPadding: CGFloat = 16
    static let topPadding: CGFloat = 6
    static let bottomPadding: CGFloat = 12
    static let headerHeight: CGFloat = 24
    static let headerToGridSpacing: CGFloat = 12
    static let headerFontSize: CGFloat = 14
    static let headerLineHeight: CGFloat = 20
    static let depthGlyphSize: CGFloat = 17
    static let rowHeight: CGFloat = 28
    static let rowHorizontalPadding: CGFloat = 8
    static let rowTextFontSize: CGFloat = 12
    static let rowTextLineHeight: CGFloat = 16
    static let rowContentSpacing: CGFloat = 4
    static let seatCodeWidth: CGFloat = 44
    static let brokerCountWidth: CGFloat = 43
    static let rankSize: CGFloat = 13
    static let rankFontSize: CGFloat = 8
    static let rankLineHeight: CGFloat = 8
    static let cornerRadius: CGFloat = 6
    static let seatBackgroundOpacity = 0.05
    static let bestLevelBackgroundOpacity = 0.10
    static let volumeFillOpacity = 0.15
}

private enum StockDetailBrokerOrderBookSide {
    case bid
    case ask

    var tint: Color {
        switch self {
        case .bid:
            Color("color-utility3-red")
        case .ask:
            Color("color-utility3-green")
        }
    }

    var fillAlignment: Alignment {
        switch self {
        case .bid:
            .trailing
        case .ask:
            .leading
        }
    }

    func accessibilityName(for language: DemoLanguage) -> String {
        switch self {
        case .bid:
            language.text(.buyOrderBook)
        case .ask:
            language.text(.sellOrderBook)
        }
    }
}

private struct StockDetailBrokerOrderBookLevelCell: View {
    let level: StockDetailBrokerOrderBookLevel
    let side: StockDetailBrokerOrderBookSide

    @Environment(\.demoLanguage) private var language

    var body: some View {
        ZStack {
            side.tint.opacity(
                level.rank == 1
                    ? StockDetailBrokerOrderBookLayout.bestLevelBackgroundOpacity
                    : StockDetailBrokerOrderBookLayout.seatBackgroundOpacity
            )

            if level.showsVolumeFill {
                GeometryReader { proxy in
                    side.tint.opacity(StockDetailBrokerOrderBookLayout.volumeFillOpacity)
                        .frame(width: proxy.size.width * level.volumeFraction)
                        .frame(maxWidth: .infinity, alignment: side.fillAlignment)
                }
                .allowsHitTesting(false)
            }

            HStack(spacing: StockDetailBrokerOrderBookLayout.rowContentSpacing) {
                StockDetailBrokerOrderBookRankBadge(rank: level.rank, color: side.tint)

                Text(level.price)
                    .modifier(rowTextFont)
                    .monospacedDigit()
                    .foregroundColor(side.tint)

                Spacer(minLength: 0)

                HStack(spacing: StockDetailBrokerOrderBookLayout.rowContentSpacing) {
                    Text(level.quantity)
                        .modifier(rowTextFont)
                        .monospacedDigit()

                    HStack(spacing: 0) {
                        Text("(")

                        Spacer(minLength: 0)

                        Text(level.brokerCount)
                            .monospacedDigit()

                        Text(")")
                    }
                    .frame(width: StockDetailBrokerOrderBookLayout.brokerCountWidth)
                }
                .modifier(rowTextFont)
                .foregroundColor(Color("color-text-30"))
            }
            .padding(.horizontal, StockDetailBrokerOrderBookLayout.rowHorizontalPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(levelAccessibilityLabel)
    }

    private var levelAccessibilityLabel: String {
        let sideName = side.accessibilityName(for: language)

        switch language {
        case .simplifiedChinese:
            return "\(sideName)第\(level.rank)档，\(language.text(.price))\(level.price)，\(language.text(.quantity))\(level.quantity)，\(language.text(.brokerCount))\(level.brokerCount)家"
        case .traditionalChinese:
            return "\(sideName)第\(level.rank)檔，\(language.text(.price))\(level.price)，\(language.text(.quantity))\(level.quantity)，\(language.text(.brokerCount))\(level.brokerCount)家"
        case .english:
            return "\(sideName) \(level.rank), \(language.text(.price)) \(level.price), \(language.text(.quantity)) \(level.quantity), \(level.brokerCount) \(language.text(.brokerCount))"
        }
    }

    private var rowTextFont: CustomFontModifier {
        CustomFontModifier(
            size: StockDetailBrokerOrderBookLayout.rowTextFontSize,
            font: .regular,
            lineHeight: StockDetailBrokerOrderBookLayout.rowTextLineHeight
        )
    }
}

private struct StockDetailBrokerOrderBookSeatCell: View {
    let seat: StockDetailBrokerOrderBookSeat
    let side: StockDetailBrokerOrderBookSide

    @Environment(\.demoLanguage) private var language

    var body: some View {
        HStack(spacing: StockDetailBrokerOrderBookLayout.rowContentSpacing) {
            Text(seat.code)
                .frame(
                    width: StockDetailBrokerOrderBookLayout.seatCodeWidth,
                    alignment: .leading
                )
                .monospacedDigit()

            Text(seat.brokerName)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .modifier(
            CustomFontModifier(
                size: StockDetailBrokerOrderBookLayout.rowTextFontSize,
                font: .regular,
                lineHeight: StockDetailBrokerOrderBookLayout.rowTextLineHeight
            )
        )
        .foregroundColor(Color("color-text-30"))
        .padding(.horizontal, StockDetailBrokerOrderBookLayout.rowHorizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(side.tint.opacity(StockDetailBrokerOrderBookLayout.seatBackgroundOpacity))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(seatAccessibilityLabel)
    }

    private var seatAccessibilityLabel: String {
        let sideName = side.accessibilityName(for: language)
        let brokerSeat = language.text(.brokerSeat)

        switch language {
        case .simplifiedChinese, .traditionalChinese:
            return "\(sideName)\(brokerSeat)\(seat.code)，\(seat.brokerName)"
        case .english:
            return "\(sideName) \(brokerSeat) \(seat.code), \(seat.brokerName)"
        }
    }
}

private struct StockDetailBrokerOrderBookRankBadge: View {
    let rank: Int
    let color: Color

    var body: some View {
        Text("\(rank)")
            .modifier(
                CustomFontModifier(
                    size: StockDetailBrokerOrderBookLayout.rankFontSize,
                    font: .medium,
                    lineHeight: StockDetailBrokerOrderBookLayout.rankLineHeight
                )
            )
            .foregroundColor(.white)
            .frame(
                width: StockDetailBrokerOrderBookLayout.rankSize,
                height: StockDetailBrokerOrderBookLayout.rankSize
            )
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            .accessibilityHidden(true)
    }
}

extension StockDetailBrokerOrderBookData {
    /// Stable generated data for Xcode Canvas and snapshot-like previews.
    static let mock: StockDetailBrokerOrderBookData = {
        var generator = StockDetailBrokerOrderBookMockGenerator(seed: 0xB0C0A3E2)
        return makeMock(using: &generator)
    }()

    /// Generates a fresh Hong Kong broker-seat sample for interactive demos.
    static func randomMock() -> StockDetailBrokerOrderBookData {
        var generator = SystemRandomNumberGenerator()
        return makeMock(using: &generator)
    }

    private static func makeMock<Generator: RandomNumberGenerator>(
        using generator: inout Generator
    ) -> StockDetailBrokerOrderBookData {
        let bidSeats = makeSeats(count: 7, using: &generator)
        let askSeats = makeSeats(count: 6, using: &generator)

        let bidRows: [StockDetailBrokerOrderBookRow] = [
            .level(.init(rank: 1, price: "16.400", quantity: "2K", brokerCount: "2", volumeFraction: 0.90, showsVolumeFill: true)),
            .seat(bidSeats[0]),
            .seat(bidSeats[1]),
            .level(.init(rank: 2, price: "16.400", quantity: "2K", brokerCount: "2")),
            .seat(bidSeats[2]),
            .seat(bidSeats[3]),
            .level(.init(rank: 3, price: "16.400", quantity: "2K", brokerCount: "3")),
            .seat(bidSeats[4]),
            .seat(bidSeats[5]),
            .seat(bidSeats[6])
        ]

        let askRows: [StockDetailBrokerOrderBookRow] = [
            .level(.init(rank: 1, price: "16.490", quantity: "90K", brokerCount: "3", volumeFraction: 0.29, showsVolumeFill: true)),
            .seat(askSeats[0]),
            .seat(askSeats[1]),
            .seat(askSeats[2]),
            .level(.init(rank: 2, price: "16.490", quantity: "90K", brokerCount: "33")),
            .seat(askSeats[3]),
            .level(.init(rank: 3, price: "16.490", quantity: "90K", brokerCount: "33")),
            .seat(askSeats[4]),
            .level(.init(rank: 4, price: "16.490", quantity: "90K", brokerCount: "33")),
            .seat(askSeats[5])
        ]

        return StockDetailBrokerOrderBookData(bidRows: bidRows, askRows: askRows)
    }

    private static func makeSeats<Generator: RandomNumberGenerator>(
        count: Int,
        using generator: inout Generator
    ) -> [StockDetailBrokerOrderBookSeat] {
        let names = brokerNames.shuffled(using: &generator)
        var seatCodes = Set<String>()
        var seats: [StockDetailBrokerOrderBookSeat] = []

        while seats.count < count {
            let code = String(format: "%04d", Int.random(in: 1...9999, using: &generator))

            guard seatCodes.insert(code).inserted else {
                continue
            }

            seats.append(
                StockDetailBrokerOrderBookSeat(
                    code: code,
                    brokerName: names[seats.count % names.count]
                )
            )
        }

        return seats
    }

    private static let brokerNames = [
        "云锋证券",
        "富途证券",
        "中银国际",
        "中信建投",
        "华泰证券",
        "国泰君安",
        "辉立证券",
        "耀才证券",
        "海通国际",
        "招商证券",
        "盈透证券",
        "华盛证券",
        "星展唯高达",
        "大华继显"
    ]
}

private struct StockDetailBrokerOrderBookMockGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

struct StockDetailBrokerOrderBook_Previews: PreviewProvider {
    static var previews: some View {
        StockDetailBrokerOrderBook()
            .frame(width: 402)
            .previewLayout(.sizeThatFits)
            .previewDisplayName("Hong Kong · Broker Order Book")
    }
}
