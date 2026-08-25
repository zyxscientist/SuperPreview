//
//  StockOrderOrderBook.swift
//  SuperPreview
//

import SwiftUI

enum StockOrderBookDepth: Int, CaseIterable, Equatable {
    case one = 1
    case five = 5
    case ten = 10

    var supportsExpansion: Bool {
        self != .one
    }

    static func standard(for market: StockOrderMarket) -> StockOrderBookDepth {
        market == .us ? .one : .ten
    }
}

struct StockOrderBookDistribution: Equatable {
    let bidPercentage: String
    let askPercentage: String
    let bidFraction: CGFloat

    var askFraction: CGFloat {
        1 - bidFraction
    }

    init(bidPercentage: String, askPercentage: String, bidFraction: CGFloat) {
        self.bidPercentage = bidPercentage
        self.askPercentage = askPercentage
        self.bidFraction = min(max(bidFraction, 0), 1)
    }

    init(
        bidPercentage: String,
        askPercentage: String,
        bidVolume: CGFloat,
        askVolume: CGFloat
    ) {
        let normalizedBidVolume = max(bidVolume, 0)
        let normalizedAskVolume = max(askVolume, 0)
        let totalVolume = normalizedBidVolume + normalizedAskVolume

        self.init(
            bidPercentage: bidPercentage,
            askPercentage: askPercentage,
            bidFraction: totalVolume > 0 ? normalizedBidVolume / totalVolume : 0.5
        )
    }
}

struct StockOrderBookLevel: Equatable, Identifiable {
    let id: UUID
    let price: String
    let quantity: String
    let brokerCount: String?
    let volumeFraction: CGFloat

    init(
        id: UUID = UUID(),
        price: String,
        quantity: String,
        brokerCount: String? = nil,
        volumeFraction: CGFloat
    ) {
        self.id = id
        self.price = price
        self.quantity = quantity
        self.brokerCount = brokerCount
        self.volumeFraction = min(max(volumeFraction, 0), 1)
    }
}

struct StockOrderBook: View {
    let depth: StockOrderBookDepth
    let distribution: StockOrderBookDistribution
    let bidLevels: [StockOrderBookLevel]
    let askLevels: [StockOrderBookLevel]
    @Binding var isExpanded: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.demoLanguage) private var language

    init(
        depth: StockOrderBookDepth,
        distribution: StockOrderBookDistribution,
        bidLevels: [StockOrderBookLevel],
        askLevels: [StockOrderBookLevel],
        isExpanded: Binding<Bool> = .constant(false)
    ) {
        self.depth = depth
        self.distribution = distribution
        self.bidLevels = bidLevels
        self.askLevels = askLevels
        self._isExpanded = isExpanded
    }

    var body: some View {
        ZStack(alignment: .top) {
            orderBookContent
        }
        .frame(
            maxWidth: .infinity,
            minHeight: presentationHeight,
            maxHeight: presentationHeight,
            alignment: .top
        )
        .overlay(alignment: .bottom) {
            if depth.supportsExpansion {
                expansionOverlay
            }
        }
        .clipped()
        .background(Color("color-base-1"))
        .animation(
            StockOrderMotion.expansion(reduceMotion: reduceMotion),
            value: isShowingExpandedLevels
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.orderBook")
    }

    private var isShowingExpandedLevels: Bool {
        depth.supportsExpansion && isExpanded
    }

    private var presentationHeight: CGFloat {
        if depth.supportsExpansion {
            return isShowingExpandedLevels
                ? expandedContentBottom + StockOrderBookLayout.expanderTapHeight + StockOrderBookLayout.bottomPadding
                : StockOrderBookLayout.collapsedContainerHeight
        }

        return StockOrderBookLayout.topPadding
            + StockOrderBookLayout.summaryHeight
            + StockOrderBookLayout.sectionSpacing
            + StockOrderBookLayout.compactLevelHeight
            + StockOrderBookLayout.bottomPadding
    }

    private var expandedContentBottom: CGFloat {
        StockOrderBookLayout.topPadding
            + StockOrderBookLayout.summaryHeight
            + StockOrderBookLayout.sectionSpacing
            + CGFloat(depth.rawValue) * StockOrderBookLayout.expandedLevelHeight
    }

    private var orderBookContent: some View {
        VStack(alignment: .leading, spacing: StockOrderBookLayout.sectionSpacing) {
            summary

            if depth.supportsExpansion {
                expandedLevels
                    .accessibilityHidden(!isShowingExpandedLevels)
            } else {
                compactLevel
            }
        }
        .padding(.horizontal, StockOrderBookLayout.horizontalPadding)
        .padding(.top, StockOrderBookLayout.topPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var summary: some View {
        VStack(spacing: StockOrderBookLayout.summaryBarSpacing) {
            HStack(spacing: 0) {
                HStack(spacing: StockOrderBookLayout.titlePercentageSpacing) {
                    Text(language.text(.buyOrderBook))
                        .foregroundColor(Color("color-text-30"))

                    Text(distribution.bidPercentage)
                        .foregroundColor(Color("color-utility3-red"))
                        .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                }
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))
                .frame(width: StockOrderBookLayout.askTitleStart, alignment: .leading)

                HStack(spacing: StockOrderBookLayout.titlePercentageSpacing) {
                    Text(language.text(.sellOrderBook))
                        .foregroundColor(Color("color-text-30"))

                    Text(distribution.askPercentage)
                        .foregroundColor(Color("color-utility3-green"))
                        .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                }
                .modifier(CustomFontModifier(size: 14, font: .regular, lineHeight: 20))

                Spacer(minLength: 0)
            }

            GeometryReader { proxy in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(Color("color-utility3-red"))
                        .frame(width: proxy.size.width * distribution.bidFraction)

                    Rectangle()
                        .fill(Color("color-utility3-green"))
                        .frame(width: proxy.size.width * distribution.askFraction)
                }
                .clipShape(Capsule())
            }
            .frame(height: StockOrderBookLayout.distributionBarHeight)
        }
        .frame(height: StockOrderBookLayout.summaryHeight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(language.text(.buyOrderBook)) \(distribution.bidPercentage), \(language.text(.sellOrderBook)) \(distribution.askPercentage)"
        )
        .accessibilityIdentifier("stockOrder.orderBook.summary")
    }

    private var compactLevel: some View {
        HStack(spacing: 0) {
            StockOrderBookCompactCell(
                level: bidLevels.first,
                side: .bid
            )

            StockOrderBookCompactCell(
                level: askLevels.first,
                side: .ask
            )
        }
        .frame(height: StockOrderBookLayout.compactLevelHeight)
        .clipShape(RoundedRectangle(cornerRadius: StockOrderBookLayout.cornerRadius, style: .continuous))
        .accessibilityIdentifier("stockOrder.orderBook.compactLevels")
    }

    private var expandedLevels: some View {
        VStack(spacing: 0) {
            ForEach(0..<depth.rawValue, id: \.self) { index in
                HStack(spacing: 0) {
                    StockOrderBookExpandedCell(
                        level: bidLevels[safe: index],
                        side: .bid,
                        rank: index + 1
                    )

                    StockOrderBookExpandedCell(
                        level: askLevels[safe: index],
                        side: .ask,
                        rank: index + 1
                    )
                }
                .frame(height: StockOrderBookLayout.expandedLevelHeight)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: StockOrderBookLayout.cornerRadius, style: .continuous))
        .accessibilityIdentifier("stockOrder.orderBook.expandedLevels")
    }

    private var expansionButton: some View {
        Button {
            withAnimation(StockOrderMotion.expansion(reduceMotion: reduceMotion)) {
                isExpanded.toggle()
            }
        } label: {
            Image(isShowingExpandedLevels ? "stock_order_orderbook_fold" : "tape_unfold")
                .resizable()
                .scaledToFit()
                .frame(
                    width: StockOrderBookLayout.expanderIconWidth,
                    height: StockOrderBookLayout.expanderIconHeight
                )
                .frame(
                    maxWidth: .infinity,
                    minHeight: StockOrderBookLayout.expanderTapHeight,
                    maxHeight: StockOrderBookLayout.expanderTapHeight
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(
            language.text(isShowingExpandedLevels ? .collapseOrderBook : .expandOrderBook)
        )
        .accessibilityValue(language.text(isShowingExpandedLevels ? .expanded : .collapsed))
        .accessibilityIdentifier("stockOrder.orderBook.expansion")
    }

    private var collapsedMask: some View {
        Color("color-base-1")
            .mask {
                Image("stock_order_orderbook_collapsed_mask")
                    .resizable()
                    .scaledToFill()
            }
            .frame(
                maxWidth: .infinity,
                minHeight: StockOrderBookLayout.collapsedMaskHeight,
                maxHeight: StockOrderBookLayout.collapsedMaskHeight
            )
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var expansionOverlay: some View {
        ZStack(alignment: .bottom) {
            collapsedMask
                .opacity(isShowingExpandedLevels ? 0 : 1)

            expansionButton
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
    }
}

private enum StockOrderBookLayout {
    static let horizontalPadding: CGFloat = 16
    static let topPadding: CGFloat = 10
    static let bottomPadding: CGFloat = 12
    static let sectionSpacing: CGFloat = 12
    static let summaryHeight: CGFloat = 30
    static let summaryBarSpacing: CGFloat = 4
    static let titlePercentageSpacing: CGFloat = 8
    static let askTitleStart: CGFloat = 191
    static let distributionBarHeight: CGFloat = 6
    static let compactLevelHeight: CGFloat = 40
    static let expandedLevelHeight: CGFloat = 27
    static let cornerRadius: CGFloat = 6
    static let expanderIconWidth: CGFloat = 16
    static let expanderIconHeight: CGFloat = 10
    static let expanderTapHeight: CGFloat = 10
    static let collapsedContainerHeight: CGFloat = 106
    static let collapsedMaskHeight: CGFloat = 27
}

private enum StockOrderBookSide {
    case bid
    case ask

    var color: Color {
        switch self {
        case .bid:
            return Color("color-utility3-red")
        case .ask:
            return Color("color-utility3-green")
        }
    }

    var fillAlignment: Alignment {
        switch self {
        case .bid:
            return .trailing
        case .ask:
            return .leading
        }
    }

    var identifier: String {
        switch self {
        case .bid:
            return "bid"
        case .ask:
            return "ask"
        }
    }
}

private struct StockOrderBookCompactCell: View {
    let level: StockOrderBookLevel?
    let side: StockOrderBookSide

    var body: some View {
        ZStack {
            side.color.opacity(0.05)

            HStack(spacing: 4) {
                Text(level?.price ?? "")
                    .foregroundColor(side.color)
                    .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 4)

                StockOrderBookVolumeText(level: level, fontSize: 14, lineHeight: 20)
                    .foregroundColor(Color("color-text-30"))
            }
            .padding(.leading, 6)
            .padding(.trailing, 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("stockOrder.orderBook.compact.\(side.identifier)")
    }

    private var accessibilityLabel: String {
        guard let level else { return "" }
        if let brokerCount = level.brokerCount {
            return "\(level.price), \(level.quantity), \(brokerCount)"
        }
        return "\(level.price), \(level.quantity)"
    }
}

private struct StockOrderBookExpandedCell: View {
    let level: StockOrderBookLevel?
    let side: StockOrderBookSide
    let rank: Int

    var body: some View {
        ZStack {
            side.color.opacity(0.05)

            GeometryReader { proxy in
                side.color.opacity(0.15)
                    .frame(width: proxy.size.width * (level?.volumeFraction ?? 0))
                    .frame(maxWidth: .infinity, alignment: side.fillAlignment)
            }

            HStack(spacing: 4) {
                StockOrderBookRankBadge(rank: rank, color: side.color)

                Text(level?.price ?? "")
                    .foregroundColor(side.color)
                    .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 2)

                StockOrderBookVolumeText(level: level, fontSize: 12, lineHeight: 16)
                    .foregroundColor(Color("color-text-30"))
            }
            .padding(.leading, 6)
            .padding(.trailing, 8)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier("stockOrder.orderBook.\(side.identifier).\(rank)")
    }

    private var accessibilityLabel: String {
        guard let level else { return "" }
        if let brokerCount = level.brokerCount {
            return "\(rank), \(level.price), \(level.quantity), \(brokerCount)"
        }
        return "\(rank), \(level.price), \(level.quantity)"
    }
}

private struct StockOrderBookRankBadge: View {
    let rank: Int
    let color: Color

    var body: some View {
        Text("\(rank)")
            .modifier(CustomFontModifier(size: 8, font: .regular, lineHeight: 9))
            .foregroundColor(.white)
            .frame(width: 13, height: 13)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
    }
}

private struct StockOrderBookVolumeText: View {
    let level: StockOrderBookLevel?
    let fontSize: CGFloat
    let lineHeight: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            Text(level?.quantity ?? "")

            if let brokerCount = level?.brokerCount {
                Text("(")
                    .padding(.leading, 3)

                Text(brokerCount)
                    .frame(width: fontSize == 12 ? 25 : 28, alignment: .trailing)

                Text(")")
            }
        }
        .modifier(CustomFontModifier(size: fontSize, font: .regular, lineHeight: lineHeight))
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private enum StockOrderBookPreviewData {
    static let distribution = StockOrderBookDistribution(
        bidPercentage: "84.22%",
        askPercentage: "15.78%",
        bidVolume: 84.22,
        askVolume: 15.78
    )

    static let bidLevels = [
        StockOrderBookLevel(price: "16.400", quantity: "15K", brokerCount: "96", volumeFraction: 0.90),
        StockOrderBookLevel(price: "16.390", quantity: "50K", brokerCount: "325", volumeFraction: 0.65),
        StockOrderBookLevel(price: "16.380", quantity: "20K", brokerCount: "75", volumeFraction: 0.52),
        StockOrderBookLevel(price: "16.370", quantity: "150K", brokerCount: "594", volumeFraction: 0.48),
        StockOrderBookLevel(price: "16.360", quantity: "100K", brokerCount: "464", volumeFraction: 0.44),
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

private struct StockOrderBookPreviewHarness: View {
    @State private var isExpanded = false

    var body: some View {
        StockOrderBook(
            depth: .ten,
            distribution: StockOrderBookPreviewData.distribution,
            bidLevels: StockOrderBookPreviewData.bidLevels,
            askLevels: StockOrderBookPreviewData.askLevels,
            isExpanded: $isExpanded
        )
    }
}

struct StockOrderBook_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderBookPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("HK · Interactive")

            StockOrderBook(
                depth: .ten,
                distribution: StockOrderBookPreviewData.distribution,
                bidLevels: StockOrderBookPreviewData.bidLevels,
                askLevels: StockOrderBookPreviewData.askLevels,
                isExpanded: .constant(true)
            )
            .environment(\.demoLanguage, .traditionalChinese)
            .preferredColorScheme(.dark)
            .previewDisplayName("HK · Ten Levels · Expanded")

            StockOrderBook(
                depth: .five,
                distribution: StockOrderBookPreviewData.distribution,
                bidLevels: Array(StockOrderBookPreviewData.bidLevels.prefix(5)),
                askLevels: Array(StockOrderBookPreviewData.askLevels.prefix(5)),
                isExpanded: .constant(false)
            )
            .environment(\.demoLanguage, .english)
            .previewDisplayName("Five Levels · Collapsed")

            StockOrderBook(
                depth: .one,
                distribution: StockOrderBookPreviewData.distribution,
                bidLevels: Array(StockOrderBookPreviewData.bidLevels.prefix(1)),
                askLevels: Array(StockOrderBookPreviewData.askLevels.prefix(1)),
                isExpanded: .constant(false)
            )
            .environment(\.demoLanguage, .english)
            .previewDisplayName("U.S. · One Level")
        }
        .previewLayout(.fixed(width: 402, height: 360))
    }
}
