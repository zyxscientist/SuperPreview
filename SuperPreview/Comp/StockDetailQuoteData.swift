//
//  StockDetailQuoteData.swift
//  SuperPreview
//

import SwiftUI

/// The market family determines the default identifiers displayed beside a quote.
enum StockDetailQuoteMarket: Hashable {
    case us
    case hongKong
    case aShare
    case crypto

    fileprivate var defaultBadges: [StockDetailQuoteBadge] {
        switch self {
        case .us:
            [.unitedStates, .margin, .usLevel1]
        case .hongKong:
            [.hongKong, .stockConnection, .margin, .hongKongLevel2]
        case .aShare:
            [.china, .stockConnection, .aShareLevel1]
        case .crypto:
            [.crypto]
        }
    }
}

/// A market badge provided by the shared Glyph library.
enum StockDetailQuoteBadge: String, Hashable {
    case unitedStates = "UnitedState"
    case hongKong = "HongKong"
    case china = "China"
    case stockConnection = "stock_connection"
    case margin
    case usLevel1 = "us_lv1"
    case hongKongLevel2 = "hk_lv2"
    case aShareLevel1 = "a_lv1"
    case crypto
}

/// Market-time states shown in the quote timestamp.
///
/// `preMarketTrading` and `afterHoursTrading` are supplied only for US
/// instruments by the page data source; the component remains presentation-only.
enum StockDetailTradingSession: Hashable {
    case trading
    case closed
    case halted
    case preMarketTrading
    case afterHoursTrading

    fileprivate var title: String {
        switch self {
        case .trading:
            "交易中"
        case .closed:
            "已收盘"
        case .halted:
            "停牌"
        case .preMarketTrading:
            "盘前交易中"
        case .afterHoursTrading:
            "盘后交易中"
        }
    }

    fileprivate func localizedTitle(for language: DemoLanguage) -> String {
        switch self {
        case .trading:
            language.text(.stockDetailTradingSession)
        case .closed:
            language.text(.stockDetailClosedSession)
        case .halted:
            language.text(.stockDetailHaltedSession)
        case .preMarketTrading:
            language.text(.stockDetailPreMarketTrading)
        case .afterHoursTrading:
            language.text(.stockDetailAfterHoursTrading)
        }
    }

    fileprivate var color: Color {
        switch self {
        case .trading, .preMarketTrading, .afterHoursTrading:
            Color("color-brand-blue")
        case .closed, .halted:
            Color("color-text-60")
        }
    }

    fileprivate var showsLiveIndicator: Bool {
        switch self {
        case .trading, .preMarketTrading, .afterHoursTrading:
            true
        case .closed, .halted:
            false
        }
    }

    fileprivate var showsTimestamp: Bool {
        self != .halted
    }
}

enum StockDetailLiveQuoteBackground {
    static func color(for colorScheme: ColorScheme) -> Color {
        Color("color-brand-blue")
            .opacity(colorScheme == .dark ? 0.15 : 0.05)
    }
}

/// Timestamp data displayed at the top leading edge of a quote component.
struct StockDetailQuoteTimestamp: Hashable {
    let session: StockDetailTradingSession
    let date: String
    let time: String
    let timeZone: String?
    private let localizedTimeZone: StockDetailQuoteLocalizedText?

    init(
        session: StockDetailTradingSession,
        date: String,
        time: String,
        timeZone: String? = nil,
        localizedTimeZone: StockDetailQuoteLocalizedText? = nil
    ) {
        self.session = session
        self.date = date
        self.time = time
        self.timeZone = timeZone
        self.localizedTimeZone = localizedTimeZone
    }

    fileprivate func displayTimeZone(for language: DemoLanguage) -> String? {
        localizedTimeZone?.text(for: language) ?? timeZone
    }
}

enum StockDetailQuoteTrend: Hashable {
    case up
    case down
    case flat

    fileprivate var color: Color {
        switch self {
        case .up:
            Color("color-utility3-red")
        case .down:
            Color("color-utility3-green")
        case .flat:
            Color("color-text-30")
        }
    }

    fileprivate var glyphAssetName: String? {
        switch self {
        case .up:
            "watchlistItem_up_red"
        case .down:
            "watchlistItem_down_green"
        case .flat:
            nil
        }
    }
}

struct StockDetailQuoteSummaryItem: Hashable, Identifiable {
    enum Tone: Hashable {
        case primary
        case positive
        case negative

        fileprivate var color: Color {
            switch self {
            case .primary:
                Color("color-text-30")
            case .positive:
                Color("color-utility3-red")
            case .negative:
                Color("color-utility3-green")
            }
        }
    }

    let label: String
    let value: String
    let tone: Tone
    private let localizedLabel: StockDetailQuoteLocalizedText?
    private let localizedValue: StockDetailQuoteLocalizedText?

    var id: String { label }

    init(label: String, value: String, tone: Tone = .primary) {
        self.label = label
        self.value = value
        self.tone = tone
        self.localizedLabel = nil
        self.localizedValue = nil
    }

    init(
        localizedLabel: StockDetailQuoteLocalizedText,
        value: String,
        localizedValue: StockDetailQuoteLocalizedText? = nil,
        tone: Tone = .primary
    ) {
        self.label = localizedLabel.simplifiedChinese
        self.value = value
        self.tone = tone
        self.localizedLabel = localizedLabel
        self.localizedValue = localizedValue
    }

    func displayLabel(for language: DemoLanguage) -> String {
        localizedLabel?.text(for: language) ?? label
    }

    func displayValue(for language: DemoLanguage) -> String {
        localizedValue?.text(for: language) ?? value
    }
}

/// Presentation data for the top-level quote section of the stock detail page.
struct StockDetailQuoteDataModel: Hashable {
    let market: StockDetailQuoteMarket
    let timestamp: StockDetailQuoteTimestamp
    let badges: [StockDetailQuoteBadge]
    let price: String
    let change: String
    let changePercent: String
    let trend: StockDetailQuoteTrend
    let summaryItems: [StockDetailQuoteSummaryItem]
    let details: StockDetailQuoteDetailsData?

    init(
        market: StockDetailQuoteMarket,
        timestamp: StockDetailQuoteTimestamp,
        badges: [StockDetailQuoteBadge]? = nil,
        price: String,
        change: String,
        changePercent: String,
        trend: StockDetailQuoteTrend,
        summaryItems: [StockDetailQuoteSummaryItem] = [],
        details: StockDetailQuoteDetailsData? = nil
    ) {
        self.market = market
        self.timestamp = timestamp
        self.badges = badges ?? market.defaultBadges
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.trend = trend
        self.summaryItems = summaryItems
        self.details = details
    }
}

/// A market-aware real-time quote section for the future stock detail page.
///
/// The caller owns `isExpanded`; instrument-specific details are supplied by
/// `StockDetailQuoteDetailsData`.
struct StockDetailQuoteData: View {
    let data: StockDetailQuoteDataModel
    @Binding var isExpanded: Bool
    let onBadgesTap: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.demoLanguage) private var language
    @State private var isShowingBadgeInfoSheet = false

    init(
        data: StockDetailQuoteDataModel,
        isExpanded: Binding<Bool>,
        onBadgesTap: (() -> Void)? = nil
    ) {
        self.data = data
        _isExpanded = isExpanded
        self.onBadgesTap = onBadgesTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: StockDetailQuoteDataLayout.sectionSpacing) {
            header
            priceSection

            if let details = data.details {
                StockDetailQuoteDetails(data: details)
                    .stockDetailQuoteExpansion(isExpanded: isShowingDetails)
            }
        }
        .padding(.horizontal, StockDetailQuoteDataLayout.horizontalPadding)
        .padding(.vertical, StockDetailQuoteDataLayout.verticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.quoteData")
        .interactiveBottomCard(isPresented: $isShowingBadgeInfoSheet) {
            StockDetailBadgeInfoSheet(
                market: data.market,
                badges: data.badges
            )
        }
    }

    private var header: some View {
        HStack(spacing: StockDetailQuoteDataLayout.headerSpacing) {
            timestamp

            Spacer(minLength: StockDetailQuoteDataLayout.headerMinimumSpacer)

            if !data.badges.isEmpty {
                Button {
                    if let onBadgesTap {
                        onBadgesTap()
                    } else {
                        isShowingBadgeInfoSheet = true
                    }
                } label: {
                    HStack(spacing: StockDetailQuoteDataLayout.badgeSpacing) {
                        ForEach(data.badges, id: \.self) { badge in
                            Image(badge.rawValue)
                                .resizable()
                                .scaledToFit()
                                .frame(
                                    width: StockDetailQuoteDataLayout.badgeSize,
                                    height: StockDetailQuoteDataLayout.badgeSize
                                )
                                .accessibilityHidden(true)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .frame(height: StockDetailQuoteDataLayout.timestampHeight)
                .contentShape(Rectangle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(language.text(.viewMarketBadgeDetails))
                .accessibilityIdentifier("stockDetail.quoteData.badges")
            }
        }
        .frame(height: StockDetailQuoteDataLayout.timestampHeight)
        .accessibilityIdentifier("stockDetail.quoteData.header")
    }

    private var timestamp: some View {
        HStack(spacing: StockDetailQuoteDataLayout.timestampItemSpacing) {
            if data.timestamp.session.showsLiveIndicator {
                Circle()
                    .fill(data.timestamp.session.color)
                    .frame(
                        width: StockDetailQuoteDataLayout.statusDotSize,
                        height: StockDetailQuoteDataLayout.statusDotSize
                    )
            }

            Text(data.timestamp.session.localizedTitle(for: language))

            if data.timestamp.session.showsTimestamp {
                Text(data.timestamp.date)
                Text(data.timestamp.time)

                if let timeZone = data.timestamp.displayTimeZone(for: language) {
                    Text(timeZone)
                }
            }
        }
        .modifier(CustomFontModifier(size: 12, font: .medium, lineHeight: 16))
        .foregroundColor(timestampTextColor)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
        .padding(.horizontal, StockDetailQuoteDataLayout.timestampHorizontalPadding)
        .frame(height: StockDetailQuoteDataLayout.timestampHeight)
        .background(timestampBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: StockDetailQuoteDataLayout.timestampCornerRadius,
                style: .continuous
            )
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(timestampAccessibilityLabel)
        .accessibilityIdentifier("stockDetail.quoteData.timestamp")
    }

    private var priceSection: some View {
        HStack(alignment: .center, spacing: StockDetailQuoteDataLayout.priceSectionSpacing) {
            priceChange

            Spacer(minLength: 0)

            if !data.summaryItems.isEmpty {
                summary
            }

            if showsExpansionControl {
                expansionControl
            }
        }
        .frame(height: StockDetailQuoteDataLayout.priceSectionHeight)
    }

    private var priceChange: some View {
        VStack(alignment: .leading, spacing: StockDetailQuoteDataLayout.priceChangeSpacing) {
            HStack(alignment: .center, spacing: StockDetailQuoteDataLayout.priceTrendSpacing) {
                Text(data.price)
                    .modifier(CustomFontModifier(size: 30, font: .bold, lineHeight: 40))
                    .foregroundColor(data.trend.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                if let glyphAssetName = data.trend.glyphAssetName {
                    Image(glyphAssetName)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: StockDetailQuoteDataLayout.trendGlyphSize,
                            height: StockDetailQuoteDataLayout.trendGlyphSize
                        )
                        .accessibilityHidden(true)
                }
            }
            .frame(height: StockDetailQuoteDataLayout.priceLineHeight, alignment: .center)

            HStack(spacing: StockDetailQuoteDataLayout.changeItemSpacing) {
                Text(data.change)
                Text(data.changePercent)
            }
            .modifier(CustomFontModifier(size: 16, font: .bold, lineHeight: 24))
            .foregroundColor(data.trend.color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(priceAccessibilityLabel)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: StockDetailQuoteDataLayout.summarySpacing) {
            ForEach(data.summaryItems.prefix(3)) { item in
                HStack(spacing: StockDetailQuoteDataLayout.summaryItemSpacing) {
                    Text(item.displayLabel(for: language))
                        .modifier(
                            CustomFontModifier(
                                size: 13,
                                font: .regular,
                                lineHeight: 16
                            )
                        )
                        .foregroundColor(Color("color-text-60"))

                    Spacer(minLength: 0)

                    Text(item.displayValue(for: language))
                        .modifier(
                            CustomFontModifier(
                                size: 13,
                                font: .medium,
                                lineHeight: 16
                            )
                        )
                        .foregroundColor(item.tone.color)
                }
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: StockDetailQuoteDataLayout.summaryWidth, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockDetail.quoteData.summary")
    }

    private var expansionControl: some View {
        Button {
            HapticManager.instance.impactHaptic(type: .medium)

            withAnimation(StockOrderMotion.expansion(reduceMotion: reduceMotion)) {
                isExpanded.toggle()
            }
        } label: {
            Image("chevron_down_filled_sm")
                .resizable()
                .scaledToFit()
                .frame(
                    width: StockDetailQuoteDataLayout.expandGlyphSize,
                    height: StockDetailQuoteDataLayout.expandGlyphSize
                )
                .rotationEffect(.degrees(isShowingDetails ? 180 : 0))
                .frame(
                    width: StockDetailQuoteDataLayout.expandWidth,
                    height: StockDetailQuoteDataLayout.expandHeight
                )
                .background(Color("color-scale-1"))
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: StockDetailQuoteDataLayout.expandCornerRadius,
                        style: .continuous
                    )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(
            language.text(isShowingDetails ? .collapseQuoteDetails : .expandQuoteDetails)
        )
        .accessibilityValue(language.text(isShowingDetails ? .expanded : .collapsed))
        .accessibilityIdentifier("stockDetail.quoteData.expand")
    }

    private var timestampAccessibilityLabel: String {
        [
            data.timestamp.session.localizedTitle(for: language),
            data.timestamp.date,
            data.timestamp.time,
            data.timestamp.displayTimeZone(for: language)
        ]
        .compactMap { $0 }
        .joined(separator: language == .english ? ", " : "，")
    }

    private var priceAccessibilityLabel: String {
        let separator = language == .english ? ", " : "，"
        return [
            "\(language.text(.currentPrice)) \(data.price)",
            data.change,
            data.changePercent
        ].joined(separator: separator)
    }

    private var showsExpansionControl: Bool {
        data.details?.presentation == .disclosure
    }

    private var isShowingDetails: Bool {
        guard let details = data.details else { return false }

        return switch details.presentation {
        case .disclosure:
            isExpanded
        case .alwaysVisible:
            true
        }
    }

    private var timestampTextColor: Color {
        switch data.timestamp.session {
        case .trading, .preMarketTrading, .afterHoursTrading:
            Color("color-text-30")
        case .closed, .halted:
            Color("color-text-60")
        }
    }

    @ViewBuilder
    private var timestampBackground: some View {
        switch data.timestamp.session {
        case .trading, .preMarketTrading, .afterHoursTrading:
            StockDetailLiveQuoteBackground.color(for: colorScheme)
        case .closed:
            Color("color-scale-1")
        case .halted:
            Color.clear
        }
    }
}

/// Matches the asset-card reveal: detail content keeps a top anchor while its
/// height is released from zero, creating a downward spring expansion.
private struct StockDetailQuoteExpansionModifier: ViewModifier {
    let isExpanded: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isExpanded ? 1 : 0)
            .blur(radius: isExpanded ? 0 : 5)
            .frame(height: isExpanded ? nil : 0, alignment: .top)
            .clipped()
            .accessibilityHidden(!isExpanded)
            .allowsHitTesting(isExpanded)
    }
}

private extension View {
    func stockDetailQuoteExpansion(isExpanded: Bool) -> some View {
        modifier(StockDetailQuoteExpansionModifier(isExpanded: isExpanded))
    }
}

private enum StockDetailQuoteDataLayout {
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 8
    static let sectionSpacing: CGFloat = 8
    static let headerSpacing: CGFloat = 8
    static let headerMinimumSpacer: CGFloat = 4
    static let timestampHeight: CGFloat = 28
    static let timestampHorizontalPadding: CGFloat = 8
    static let timestampCornerRadius: CGFloat = 8
    static let timestampItemSpacing: CGFloat = 4
    static let statusDotSize: CGFloat = 8
    static let badgeSpacing: CGFloat = 4
    static let badgeSize: CGFloat = 16
    static let priceSectionHeight: CGFloat = 64
    static let priceSectionSpacing: CGFloat = 8
    static let priceChangeSpacing: CGFloat = 0
    static let priceLineHeight: CGFloat = 40
    static let priceTrendSpacing: CGFloat = 2
    static let changeItemSpacing: CGFloat = 4
    static let trendGlyphSize: CGFloat = 12
    static let summaryWidth: CGFloat = 126
    static let summarySpacing: CGFloat = 4
    static let summaryItemSpacing: CGFloat = 4
    static let expandWidth: CGFloat = 16
    static let expandHeight: CGFloat = 56
    static let expandGlyphSize: CGFloat = 16
    static let expandCornerRadius: CGFloat = 4
}

private struct StockDetailQuoteDataPreviewHarness: View {
    let data: StockDetailQuoteDataModel
    @State private var isExpanded: Bool

    init(
        data: StockDetailQuoteDataModel,
        initiallyExpanded: Bool = false
    ) {
        self.data = data
        _isExpanded = State(initialValue: initiallyExpanded)
    }

    var body: some View {
        StockDetailQuoteData(data: data, isExpanded: $isExpanded)
    }
}

private extension StockDetailQuoteDataModel {
    static let us = StockDetailQuoteDataModel(
        market: .us,
        timestamp: StockDetailQuoteTimestamp(
            session: .trading,
            date: "04/03",
            time: "14:44:01",
            timeZone: "(美东)",
            localizedTimeZone: .init(
                simplifiedChinese: "(美东)",
                traditionalChinese: "(美東)",
                english: "(ET)"
            )
        ),
        price: "1,776.740",
        change: "+1.079",
        changePercent: "+0.25%",
        trend: .up,
        summaryItems: [
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "最高", english: "High"),
                value: "1,788.80",
                tone: .positive
            ),
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "最低", english: "Low"),
                value: "1,766.03",
                tone: .negative
            ),
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "成交额", traditionalChinese: "成交額", english: "Turnover"),
                value: "3.42亿",
                localizedValue: .init(simplifiedChinese: "3.42亿", traditionalChinese: "3.42億", english: "342M")
            )
        ],
        details: .stockHongKongOrUS
    )

    static let hongKong = StockDetailQuoteDataModel(
        market: .hongKong,
        timestamp: StockDetailQuoteTimestamp(
            session: .closed,
            date: "04/03",
            time: "16:08:01"
        ),
        price: "19.970",
        change: "-0.090",
        changePercent: "-0.45%",
        trend: .down,
        summaryItems: [
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "最高", english: "High"),
                value: "20.080",
                tone: .positive
            ),
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "最低", english: "Low"),
                value: "19.780",
                tone: .negative
            ),
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "成交额", traditionalChinese: "成交額", english: "Turnover"),
                value: "17.29亿",
                localizedValue: .init(simplifiedChinese: "17.29亿", traditionalChinese: "17.29億", english: "1.729B")
            )
        ],
        details: .stockHongKongOrUS
    )

    static let aShare = StockDetailQuoteDataModel(
        market: .aShare,
        timestamp: StockDetailQuoteTimestamp(
            session: .halted,
            date: "04/03",
            time: "15:00:00"
        ),
        price: "1,949.11",
        change: "+18.08",
        changePercent: "+0.94%",
        trend: .up,
        summaryItems: [
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "最高", english: "High"),
                value: "1,953.30",
                tone: .positive
            ),
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "最低", english: "Low"),
                value: "1,921.76",
                tone: .negative
            ),
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "成交额", traditionalChinese: "成交額", english: "Turnover"),
                value: "1.96万亿",
                localizedValue: .init(simplifiedChinese: "1.96万亿", traditionalChinese: "1.96萬億", english: "1.96T")
            )
        ],
        details: .stockAShare
    )

    static let crypto = StockDetailQuoteDataModel(
        market: .crypto,
        timestamp: StockDetailQuoteTimestamp(
            session: .trading,
            date: "04/03",
            time: "16:22:01"
        ),
        price: "988,988.11",
        change: "+14,115.21",
        changePercent: "+1.45%",
        trend: .up,
        details: .crypto
    )

    static let usPreMarket = StockDetailQuoteDataModel(
        market: .us,
        timestamp: StockDetailQuoteTimestamp(
            session: .preMarketTrading,
            date: "04/03",
            time: "08:44:01",
            timeZone: "(美东)",
            localizedTimeZone: .init(
                simplifiedChinese: "(美东)",
                traditionalChinese: "(美東)",
                english: "(ET)"
            )
        ),
        price: "1,770.840",
        change: "-5.900",
        changePercent: "-0.33%",
        trend: .down,
        summaryItems: [
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "最高", english: "High"),
                value: "1,788.80",
                tone: .positive
            ),
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "最低", english: "Low"),
                value: "1,766.03",
                tone: .negative
            ),
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "成交额", traditionalChinese: "成交額", english: "Turnover"),
                value: "3.42亿",
                localizedValue: .init(simplifiedChinese: "3.42亿", traditionalChinese: "3.42億", english: "342M")
            )
        ],
        details: .stockHongKongOrUS
    )

    static let usAfterHours = StockDetailQuoteDataModel(
        market: .us,
        timestamp: StockDetailQuoteTimestamp(
            session: .afterHoursTrading,
            date: "04/03",
            time: "18:44:01",
            timeZone: "(美东)",
            localizedTimeZone: .init(
                simplifiedChinese: "(美东)",
                traditionalChinese: "(美東)",
                english: "(ET)"
            )
        ),
        price: "1,781.240",
        change: "+4.500",
        changePercent: "+0.25%",
        trend: .up,
        summaryItems: [
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "最高", english: "High"),
                value: "1,788.80",
                tone: .positive
            ),
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "最低", english: "Low"),
                value: "1,766.03",
                tone: .negative
            ),
            StockDetailQuoteSummaryItem(
                localizedLabel: .init(simplifiedChinese: "成交额", traditionalChinese: "成交額", english: "Turnover"),
                value: "3.42亿",
                localizedValue: .init(simplifiedChinese: "3.42亿", traditionalChinese: "3.42億", english: "342M")
            )
        ],
        details: .stockHongKongOrUS
    )
}

struct StockDetailQuoteData_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Use Canvas Live Preview and tap the disclosure control to inspect
            // the same spring expansion used by the stock-detail page.
            StockDetailQuoteDataPreviewHarness(data: .us)
                .previewDisplayName("US · Interactive")

            StockDetailQuoteDataPreviewHarness(data: .us, initiallyExpanded: true)
                .previewDisplayName("US · Expanded")

            // Tap the market badges in Canvas to present the same
            // finger-tracking bottom card used in the stock-detail page.
            StockDetailQuoteDataPreviewHarness(data: .hongKong)
                .previewDisplayName("Hong Kong · Badge Sheet")

            StockDetailQuoteData(data: .aShare, isExpanded: .constant(false))
                .previewDisplayName("A Share · Halted")

            StockDetailQuoteData(data: .crypto, isExpanded: .constant(false))
                .previewDisplayName("Crypto · Trading")

            StockDetailQuoteData(data: .usPreMarket, isExpanded: .constant(false))
                .previewDisplayName("US · Pre-market")

            StockDetailQuoteData(data: .usAfterHours, isExpanded: .constant(false))
                .previewDisplayName("US · After-hours")
        }
        .frame(width: 402)
        .previewLayout(.sizeThatFits)
    }
}
