//
//  StockDetailQuoteDetails.swift
//  SuperPreview
//

import SwiftUI

/// A localized label/value pair used by the expanded quote-data grid.
struct StockDetailQuoteLocalizedText: Hashable {
    let simplifiedChinese: String
    let traditionalChinese: String
    let english: String

    init(
        simplifiedChinese: String,
        traditionalChinese: String? = nil,
        english: String
    ) {
        self.simplifiedChinese = simplifiedChinese
        self.traditionalChinese = traditionalChinese ?? simplifiedChinese
        self.english = english
    }

    func text(for language: DemoLanguage) -> String {
        switch language {
        case .simplifiedChinese:
            simplifiedChinese
        case .traditionalChinese:
            traditionalChinese
        case .english:
            english
        }
    }
}

enum StockDetailQuoteDetailTone: Hashable {
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

struct StockDetailQuoteDetailItem: Hashable, Identifiable {
    let id: String
    let label: StockDetailQuoteLocalizedText
    let value: StockDetailQuoteLocalizedText
    let suffix: StockDetailQuoteLocalizedText?
    let tone: StockDetailQuoteDetailTone

    init(
        id: String,
        label: StockDetailQuoteLocalizedText,
        value: StockDetailQuoteLocalizedText,
        suffix: StockDetailQuoteLocalizedText? = nil,
        tone: StockDetailQuoteDetailTone = .primary
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.suffix = suffix
        self.tone = tone
    }
}

/// The instrument-specific field family defined by the QuoteData Figma component.
enum StockDetailQuoteDetailInstrument: Hashable {
    case stock
    case etf
    case index
    case bullBearCertificate
    case warrantOrInlineCertificate
    case crypto
}

enum StockDetailQuoteDetailPresentation: Hashable {
    /// Details are disclosed by the quote section's expand control.
    case disclosure
    /// Crypto data is part of the always-visible quote section in the design.
    case alwaysVisible
}

/// Data and presentation rules for an instrument's expanded quote fields.
struct StockDetailQuoteDetailsData: Hashable {
    let instrument: StockDetailQuoteDetailInstrument
    let columns: Int
    let presentation: StockDetailQuoteDetailPresentation
    let items: [StockDetailQuoteDetailItem]

    init(
        instrument: StockDetailQuoteDetailInstrument,
        columns: Int = 3,
        presentation: StockDetailQuoteDetailPresentation = .disclosure,
        items: [StockDetailQuoteDetailItem]
    ) {
        self.instrument = instrument
        self.columns = columns
        self.presentation = presentation
        self.items = items
    }
}

/// The adaptive grid used after a quote's compact summary is expanded.
///
/// Chinese uses inline label/value pairs. English reserves a distinct two-line
/// cell, matching the component variants in the design instead of merely
/// translating the Chinese layout.
struct StockDetailQuoteDetails: View {
    let data: StockDetailQuoteDetailsData

    @Environment(\.demoLanguage) private var language

    var body: some View {
        LazyVGrid(
            columns: gridColumns,
            alignment: .leading,
            spacing: StockDetailQuoteDetailsLayout.rowSpacing
        ) {
            ForEach(data.items) { item in
                detailItem(item)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.quoteData.details")
    }

    private var gridColumns: [GridItem] {
        Array(
            repeating: GridItem(
                .flexible(minimum: 0),
                spacing: StockDetailQuoteDetailsLayout.columnSpacing
            ),
            count: data.columns
        )
    }

    @ViewBuilder
    private func detailItem(_ item: StockDetailQuoteDetailItem) -> some View {
        if language == .english {
            englishDetailItem(item)
        } else {
            chineseDetailItem(item)
        }
    }

    private func chineseDetailItem(_ item: StockDetailQuoteDetailItem) -> some View {
        HStack(spacing: StockDetailQuoteDetailsLayout.inlineItemSpacing) {
            label(for: item)

            Spacer(minLength: 0)

            value(for: item)
        }
        .frame(height: StockDetailQuoteDetailsLayout.chineseCellHeight)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockDetail.quoteData.details.\(item.id)")
    }

    private func englishDetailItem(_ item: StockDetailQuoteDetailItem) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            label(for: item)
            value(for: item)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: StockDetailQuoteDetailsLayout.englishCellHeight,
            alignment: .leading
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockDetail.quoteData.details.\(item.id)")
    }

    private func label(for item: StockDetailQuoteDetailItem) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 0) {
            Text(item.label.text(for: language))

            if let suffix = item.suffix {
                Text(suffix.text(for: language))
                    .modifier(
                        CustomFontModifier(
                            size: StockDetailQuoteDetailsLayout.suffixFontSize,
                            font: .regular,
                            lineHeight: StockDetailQuoteDetailsLayout.suffixLineHeight
                        )
                    )
                    .padding(.bottom, StockDetailQuoteDetailsLayout.suffixBottomOffset)
            }
        }
        .modifier(
            CustomFontModifier(
                size: StockDetailQuoteDetailsLayout.fontSize,
                font: .regular,
                lineHeight: StockDetailQuoteDetailsLayout.lineHeight
            )
        )
        .foregroundColor(Color("color-text-60"))
        .lineLimit(1)
        .minimumScaleFactor(0.65)
    }

    private func value(for item: StockDetailQuoteDetailItem) -> some View {
        Text(item.value.text(for: language))
            .modifier(
                CustomFontModifier(
                    size: StockDetailQuoteDetailsLayout.fontSize,
                    font: .medium,
                    lineHeight: StockDetailQuoteDetailsLayout.lineHeight
                )
            )
            .foregroundColor(item.tone.color)
            .lineLimit(1)
            .minimumScaleFactor(0.65)
    }
}

private enum StockDetailQuoteDetailsLayout {
    static let columnSpacing: CGFloat = 8
    static let rowSpacing: CGFloat = 4
    static let inlineItemSpacing: CGFloat = 2
    static let chineseCellHeight: CGFloat = 16
    static let englishCellHeight: CGFloat = 32
    static let fontSize: CGFloat = 13
    static let lineHeight: CGFloat = 16
    static let suffixFontSize: CGFloat = 8
    static let suffixLineHeight: CGFloat = 8
    static let suffixBottomOffset: CGFloat = 1
}

private extension StockDetailQuoteLocalizedText {
    static func detail(_ chinese: String, _ english: String) -> Self {
        StockDetailQuoteLocalizedText(simplifiedChinese: chinese, english: english)
    }
}

private extension StockDetailQuoteDetailItem {
    static func detail(
        _ id: String,
        chineseLabel: String,
        englishLabel: String,
        chineseValue: String,
        englishValue: String? = nil,
        suffixChinese: String? = nil,
        suffixEnglish: String? = nil,
        tone: StockDetailQuoteDetailTone = .primary
    ) -> Self {
        StockDetailQuoteDetailItem(
            id: id,
            label: .detail(chineseLabel, englishLabel),
            value: .detail(chineseValue, englishValue ?? chineseValue),
            suffix: suffixChinese.map {
                .detail($0, suffixEnglish ?? $0)
            },
            tone: tone
        )
    }
}

extension StockDetailQuoteDetailsData {
    /// Figma Type=Stock(HK&US·Stock/iBond/Trust).
    static let stockHongKongOrUS = StockDetailQuoteDetailsData(
        instrument: .stock,
        items: [
            .detail("open", chineseLabel: "今开", englishLabel: "Open", chineseValue: "16.000", englishValue: "16.00", tone: .positive),
            .detail("lotSize", chineseLabel: "每手", englishLabel: "Lot Size", chineseValue: "2,000股", englishValue: "2,000"),
            .detail("volume", chineseLabel: "成交量", englishLabel: "Volume", chineseValue: "44.99万股", englishValue: "449.9K"),
            .detail("preClose", chineseLabel: "昨收", englishLabel: "Pre Close", chineseValue: "16.100", englishValue: "16.10"),
            .detail("marketCap", chineseLabel: "总市值", englishLabel: "Cap", chineseValue: "610.99亿", englishValue: "60.09B"),
            .detail("turnoverRatio", chineseLabel: "换手率", englishLabel: "Turnover Ratio", chineseValue: "2.98%"),
            .detail("pe", chineseLabel: "市盈率", englishLabel: "P/E", chineseValue: "30.55", suffixChinese: "TTM", suffixEnglish: "TTM"),
            .detail("shares", chineseLabel: "总股本", englishLabel: "Shares", chineseValue: "38.68亿股", englishValue: "3.86B"),
            .detail("volumeRatio", chineseLabel: "量比", englishLabel: "Volume Ratio", chineseValue: "2.22"),
            .detail("floatCap", chineseLabel: "流通市值", englishLabel: "Float Cap", chineseValue: "610.99亿", englishValue: "61.09B"),
            .detail("historicalHigh", chineseLabel: "历史最高", englishLabel: "Historical High", chineseValue: "20.220", englishValue: "20.22"),
            .detail("bidAsk", chineseLabel: "委比", englishLabel: "Bid/Ask %", chineseValue: "14.23%"),
            .detail("floatShares", chineseLabel: "流通股", englishLabel: "Float Shares", chineseValue: "38.68亿股", englishValue: "3.86B"),
            .detail("historicalLow", chineseLabel: "历史最低", englishLabel: "Historical Low", chineseValue: "1.250", englishValue: "1.25"),
            .detail("amplitude", chineseLabel: "振幅", englishLabel: "Amplitude", chineseValue: "2.98%"),
            .detail("weekHigh", chineseLabel: "52周最高", englishLabel: "52W High", chineseValue: "17.320", englishValue: "17.32"),
            .detail("dividendYield", chineseLabel: "股息率", englishLabel: "DY", chineseValue: "15.99%", suffixChinese: "TTM", suffixEnglish: "TTM"),
            .detail("averagePrice", chineseLabel: "平均价", englishLabel: "Avg Price", chineseValue: "16.121", englishValue: "16.12"),
            .detail("weekLow", chineseLabel: "52周最低", englishLabel: "52W Low", chineseValue: "15.990", englishValue: "15.99"),
            .detail("dividend", chineseLabel: "股息", englishLabel: "Dividend", chineseValue: "15.990", suffixChinese: "TTM", suffixEnglish: "TTM")
        ]
    )

    /// Figma Type=Stock(SHSZ), including the daily price-limit fields.
    static let stockAShare = StockDetailQuoteDetailsData(
        instrument: .stock,
        items: stockHongKongOrUS.items + [
            .detail("limitUp", chineseLabel: "涨停价", englishLabel: "Limit Up", chineseValue: "17.710", englishValue: "17.71"),
            .detail("limitDown", chineseLabel: "跌停价", englishLabel: "Limit Down", chineseValue: "14.490", englishValue: "14.49")
        ]
    )

    /// Figma Type=ETF(HK&US).
    static let etfHongKongOrUS = StockDetailQuoteDetailsData(
        instrument: .etf,
        items: [
            .detail("open", chineseLabel: "今开", englishLabel: "Open", chineseValue: "16.000", englishValue: "16.00", tone: .positive),
            .detail("lotSize", chineseLabel: "每手", englishLabel: "Lot Size", chineseValue: "2,000股", englishValue: "2,000"),
            .detail("volume", chineseLabel: "成交量", englishLabel: "Volume", chineseValue: "40.22万股", englishValue: "402.2K"),
            .detail("preClose", chineseLabel: "昨收", englishLabel: "Pre Close", chineseValue: "16.100", englishValue: "16.10"),
            .detail("aum", chineseLabel: "资产规模", englishLabel: "AUM", chineseValue: "22.99亿", englishValue: "2.30B"),
            .detail("turnoverRatio", chineseLabel: "换手率", englishLabel: "Turnover Ratio", chineseValue: "2.98%"),
            .detail("weekHigh", chineseLabel: "52周最高", englishLabel: "52W High", chineseValue: "17.320", englishValue: "17.32"),
            .detail("shares", chineseLabel: "发行量", englishLabel: "Shares", chineseValue: "1,070.00万股", englishValue: "10.70M"),
            .detail("volumeRatio", chineseLabel: "量比", englishLabel: "Volume Ratio", chineseValue: "2.22"),
            .detail("weekLow", chineseLabel: "52周最低", englishLabel: "52W Low", chineseValue: "15.990", englishValue: "15.99"),
            .detail("averagePrice", chineseLabel: "平均价", englishLabel: "Avg Price", chineseValue: "16.121", englishValue: "16.12"),
            .detail("bidAsk", chineseLabel: "委比", englishLabel: "Bid/Ask %", chineseValue: "14.23%"),
            .detail("historicalHigh", chineseLabel: "历史最高", englishLabel: "Historical High", chineseValue: "20.220", englishValue: "20.22"),
            .detail("dividendYield", chineseLabel: "股息率", englishLabel: "Dividend Yield", chineseValue: "15.99%", suffixChinese: "TTM", suffixEnglish: "TTM"),
            .detail("amplitude", chineseLabel: "振幅", englishLabel: "Amplitude", chineseValue: "2.98%"),
            .detail("historicalLow", chineseLabel: "历史最低", englishLabel: "Historical Low", chineseValue: "1.250", englishValue: "1.25"),
            .detail("dividend", chineseLabel: "股息", englishLabel: "Dividend", chineseValue: "15.990", suffixChinese: "TTM", suffixEnglish: "TTM")
        ]
    )

    /// Figma Type=ETF(SHSZ), including the daily price-limit fields.
    static let etfAShare = StockDetailQuoteDetailsData(
        instrument: .etf,
        items: etfHongKongOrUS.items + [
            .detail("limitUp", chineseLabel: "涨停价", englishLabel: "Limit Up", chineseValue: "17.710", englishValue: "17.71"),
            .detail("limitDown", chineseLabel: "跌停价", englishLabel: "Limit Down", chineseValue: "14.490", englishValue: "14.49")
        ]
    )

    /// Figma Type=Index.
    static let index = StockDetailQuoteDetailsData(
        instrument: .index,
        items: [
            .detail("open", chineseLabel: "今开", englishLabel: "Open", chineseValue: "26,708.45", englishValue: "26708.45", tone: .positive),
            .detail("rise", chineseLabel: "涨家数", englishLabel: "Rise", chineseValue: "64"),
            .detail("amplitude", chineseLabel: "振幅", englishLabel: "Amplitude", chineseValue: "2.98%"),
            .detail("preClose", chineseLabel: "昨收", englishLabel: "Pre Close", chineseValue: "27,009.50", englishValue: "27009.50"),
            .detail("fall", chineseLabel: "跌家数", englishLabel: "Fall", chineseValue: "16"),
            .detail("unchanged", chineseLabel: "平家数", englishLabel: "Unchanged", chineseValue: "2")
        ]
    )

    /// Figma Type=Derivative(HK·Bull&Bear).
    static let bullBearCertificate = StockDetailQuoteDetailsData(
        instrument: .bullBearCertificate,
        items: [
            .detail("open", chineseLabel: "今开", englishLabel: "Open", chineseValue: "16.000", englishValue: "16.00", tone: .positive),
            .detail("lotSize", chineseLabel: "每手", englishLabel: "Lot Size", chineseValue: "10,000股", englishValue: "10,000"),
            .detail("volume", chineseLabel: "成交量", englishLabel: "Volume", chineseValue: "44.99万股", englishValue: "449.9K"),
            .detail("preClose", chineseLabel: "昨收", englishLabel: "Pre Close", chineseValue: "16.100", englishValue: "16.10"),
            .detail("outstandingRatio", chineseLabel: "街货比", englishLabel: "Outstanding", chineseValue: "44.44%"),
            .detail("callPrice", chineseLabel: "回收价", englishLabel: "Call Price", chineseValue: "17,000.000", englishValue: "17000.000"),
            .detail("gearing", chineseLabel: "杠杆比率", englishLabel: "Gearing Ratio", chineseValue: "15.88"),
            .detail("outstandingQuantity", chineseLabel: "街货量", englishLabel: "Outstanding Qty", chineseValue: "1.16亿", englishValue: "116.00M"),
            .detail("distanceToCall", chineseLabel: "距回收价", englishLabel: "To Call Price", chineseValue: "10.21%"),
            .detail("moneyness", chineseLabel: "价格/价外", englishLabel: "ITM/OTM", chineseValue: "3.22%"),
            .detail("conversionPrice", chineseLabel: "换股价", englishLabel: "Conv. Price", chineseValue: "480.000"),
            .detail("lastTradingDay", chineseLabel: "最后交易", englishLabel: "LTD", chineseValue: "2026/04/14"),
            .detail("premium", chineseLabel: "溢价", englishLabel: "Premium", chineseValue: "-0.76%"),
            .detail("entitlement", chineseLabel: "换股比率", englishLabel: "Entitlement Ratio", chineseValue: "10,000.00", englishValue: "10000.00"),
            .detail("expiryDate", chineseLabel: "到期日", englishLabel: "Expiry Date", chineseValue: "2026/04/14"),
            .detail("strikePrice", chineseLabel: "行使价", englishLabel: "Strike Price", chineseValue: "16,980.000", englishValue: "16980.000"),
            .detail("breakEven", chineseLabel: "打和点", englishLabel: "BEP", chineseValue: "16,980.000", englishValue: "16980.000")
        ]
    )

    /// Figma Type=Derivative(HK·Warrant/IC).
    static let warrantOrInlineCertificate = StockDetailQuoteDetailsData(
        instrument: .warrantOrInlineCertificate,
        items: [
            .detail("open", chineseLabel: "今开", englishLabel: "Open", chineseValue: "16.000", englishValue: "16.00", tone: .positive),
            .detail("lotSize", chineseLabel: "每手", englishLabel: "Lot Size", chineseValue: "10,000股", englishValue: "10,000"),
            .detail("volume", chineseLabel: "成交量", englishLabel: "Volume", chineseValue: "44.99万股", englishValue: "449.9K"),
            .detail("preClose", chineseLabel: "昨收", englishLabel: "Pre Close", chineseValue: "16.100", englishValue: "16.10"),
            .detail("outstandingRatio", chineseLabel: "街货比", englishLabel: "Outstanding", chineseValue: "44.44%"),
            .detail("effectiveLeverage", chineseLabel: "有效杠杆", englishLabel: "Effective", chineseValue: "11.88"),
            .detail("gearing", chineseLabel: "杠杆比率", englishLabel: "Gearing Ratio", chineseValue: "15.88"),
            .detail("outstandingQuantity", chineseLabel: "街货量", englishLabel: "Outstanding Qty", chineseValue: "3.86B"),
            .detail("impliedVolatility", chineseLabel: "引伸波幅", englishLabel: "Implied", chineseValue: "23.888"),
            .detail("delta", chineseLabel: "对冲值", englishLabel: "Delta", chineseValue: "0.288"),
            .detail("conversionPrice", chineseLabel: "换股价", englishLabel: "Conv. Price", chineseValue: "480.000"),
            .detail("lastTradingDay", chineseLabel: "最后交易", englishLabel: "LTD", chineseValue: "2023/04/14"),
            .detail("premium", chineseLabel: "溢价", englishLabel: "Premium", chineseValue: "-0.76%"),
            .detail("entitlement", chineseLabel: "换股比率", englishLabel: "Entitlement Ratio", chineseValue: "500.00"),
            .detail("expiryDate", chineseLabel: "到期日", englishLabel: "Expiry Date", chineseValue: "2023/04/15"),
            .detail("strikePrice", chineseLabel: "行使价", englishLabel: "Strike Price", chineseValue: "16,980.000", englishValue: "16980.000"),
            .detail("breakEven", chineseLabel: "打和点", englishLabel: "BEP", chineseValue: "16,980.000", englishValue: "16980.000")
        ]
    )

    /// Figma Type=Crypto. It uses a two-column detail grid and is always shown.
    static let crypto = StockDetailQuoteDetailsData(
        instrument: .crypto,
        columns: 2,
        presentation: .alwaysVisible,
        items: [
            .detail("high24h", chineseLabel: "24H 最高", englishLabel: "24H High", chineseValue: "988,988.11", englishValue: "978855.88", tone: .positive),
            .detail("turnover24h", chineseLabel: "24H 额HKD", englishLabel: "Turnover(HKD)", chineseValue: "4,001.22万", englishValue: "2144.99万"),
            .detail("low24h", chineseLabel: "24H 最低", englishLabel: "24H Low", chineseValue: "988,988.11", englishValue: "978855.88"),
            .detail("volume24h", chineseLabel: "24H 量BTC", englishLabel: "Volume(BTC)", chineseValue: "260.12345")
        ]
    )
}

struct StockDetailQuoteDetails_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailQuoteDetails(data: .stockHongKongOrUS)
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Stock · Chinese")

            StockDetailQuoteDetails(data: .stockAShare)
                .environment(\.demoLanguage, .english)
                .previewDisplayName("A Share · English")

            StockDetailQuoteDetails(data: .etfHongKongOrUS)
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("ETF · Chinese")

            StockDetailQuoteDetails(data: .index)
                .environment(\.demoLanguage, .english)
                .previewDisplayName("Index · English")

            StockDetailQuoteDetails(data: .bullBearCertificate)
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewDisplayName("Bull / Bear · Chinese")

            StockDetailQuoteDetails(data: .warrantOrInlineCertificate)
                .environment(\.demoLanguage, .english)
                .previewDisplayName("Warrant / IC · English")

            StockDetailQuoteDetails(data: .crypto)
                .environment(\.demoLanguage, .english)
                .previewDisplayName("Crypto · English")
        }
        // The standalone preview mirrors the 16pt page inset supplied by
        // StockDetailQuoteData when this grid is shown on the detail page.
        .padding(.horizontal, 16)
        .frame(width: 402)
        .previewLayout(.sizeThatFits)
    }
}
