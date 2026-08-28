//
//  StockDetailRelatedInfo.swift
//  SuperPreview
//

import SwiftUI

enum StockDetailRelatedInfoTone: Hashable {
    case primary
    case secondary
    case positive
    case negative

    fileprivate var color: Color {
        switch self {
        case .primary:
            Color("color-text-30")
        case .secondary:
            Color("color-text-60")
        case .positive:
            Color("color-utility3-red")
        case .negative:
            Color("color-utility3-green")
        }
    }
}

/// A compact quote shared by connection and extended-hours related-info rows.
struct StockDetailRelatedInfoQuote: Hashable {
    let title: String
    let price: String
    let change: String?
    let changePercent: String?
    let tone: StockDetailRelatedInfoTone

    init(
        title: String,
        price: String,
        change: String? = nil,
        changePercent: String? = nil,
        tone: StockDetailRelatedInfoTone
    ) {
        self.title = title
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.tone = tone
    }
}

struct StockDetailRelatedInfoMetric: Hashable, Identifiable {
    let label: String
    let value: String
    let tone: StockDetailRelatedInfoTone

    var id: String { label }

    init(
        label: String,
        value: String,
        tone: StockDetailRelatedInfoTone = .primary
    ) {
        self.label = label
        self.value = value
        self.tone = tone
    }
}

struct StockDetailRelatedInfoConnection: Hashable {
    let quote: StockDetailRelatedInfoQuote
    let trailingLabel: String?
    let trailingValue: String?
    let trailingTone: StockDetailRelatedInfoTone

    init(
        quote: StockDetailRelatedInfoQuote,
        trailingLabel: String? = nil,
        trailingValue: String? = nil,
        trailingTone: StockDetailRelatedInfoTone = .primary
    ) {
        self.quote = quote
        self.trailingLabel = trailingLabel
        self.trailingValue = trailingValue
        self.trailingTone = trailingTone
    }
}

struct StockDetailRelatedInfoADRConnection: Hashable {
    let conversionTitle: String
    let conversionPrice: String
    let conversionTone: StockDetailRelatedInfoTone
    let relativeTitle: String
    let relativeChange: String
    let relativeChangePercent: String
    let relativeTone: StockDetailRelatedInfoTone
    let relatedQuote: StockDetailRelatedInfoQuote?

    init(
        conversionTitle: String,
        conversionPrice: String,
        conversionTone: StockDetailRelatedInfoTone,
        relativeTitle: String,
        relativeChange: String,
        relativeChangePercent: String,
        relativeTone: StockDetailRelatedInfoTone,
        relatedQuote: StockDetailRelatedInfoQuote? = nil
    ) {
        self.conversionTitle = conversionTitle
        self.conversionPrice = conversionPrice
        self.conversionTone = conversionTone
        self.relativeTitle = relativeTitle
        self.relativeChange = relativeChange
        self.relativeChangePercent = relativeChangePercent
        self.relativeTone = relativeTone
        self.relatedQuote = relatedQuote
    }
}

struct StockDetailRelatedInfoRange: Hashable {
    let title: String
    let rangeLabel: String
    let rangeValue: String

    init(title: String, rangeLabel: String, rangeValue: String) {
        self.title = title
        self.rangeLabel = rangeLabel
        self.rangeValue = rangeValue
    }
}

struct StockDetailRelatedInfoFinancialReport: Hashable {
    let date: String
    let event: String

    init(date: String, event: String) {
        self.date = date
        self.event = event
    }
}

struct StockDetailRelatedInfoCashDividend: Hashable {
    let summary: String
    let details: [StockDetailRelatedInfoMetric]

    init(summary: String, details: [StockDetailRelatedInfoMetric]) {
        self.summary = summary
        self.details = details
    }
}

enum StockDetailRelatedInfoExtendedHoursState: Hashable {
    case trading
    case flat
    case noTrade

    fileprivate var quoteTone: StockDetailRelatedInfoTone {
        switch self {
        case .trading:
            .positive
        case .flat, .noTrade:
            .secondary
        }
    }
}

struct StockDetailRelatedInfoExtendedHours: Hashable {
    let state: StockDetailRelatedInfoExtendedHoursState
    let sessionTitle: String
    let price: String
    let change: String?
    let changePercent: String?
    let timestamp: String
    let metrics: [StockDetailRelatedInfoMetric]

    init(
        state: StockDetailRelatedInfoExtendedHoursState,
        sessionTitle: String,
        price: String,
        change: String? = nil,
        changePercent: String? = nil,
        timestamp: String,
        metrics: [StockDetailRelatedInfoMetric]
    ) {
        self.state = state
        self.sessionTitle = sessionTitle
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.timestamp = timestamp
        self.metrics = metrics
    }
}

/// Every related-information row that can appear on the stock detail page.
///
/// The page data source decides which items to include for a particular
/// instrument; the container keeps their visual grouping and interaction state
/// consistent regardless of that combination.
struct StockDetailRelatedInfoItem: Hashable, Identifiable {
    enum Content: Hashable {
        case aShareConnection(StockDetailRelatedInfoConnection)
        case shareConnection(StockDetailRelatedInfoConnection)
        case dualCounter(StockDetailRelatedInfoConnection)
        case adrConnectionUS(StockDetailRelatedInfoADRConnection)
        case adrConnectionHongKong(StockDetailRelatedInfoADRConnection)
        case cas(StockDetailRelatedInfoRange)
        case vcm(StockDetailRelatedInfoRange)
        case financialReport(StockDetailRelatedInfoFinancialReport)
        case cashDividend(StockDetailRelatedInfoCashDividend)
        case extendedHours(StockDetailRelatedInfoExtendedHours)
    }

    let id: String
    let content: Content

    init(id: String, content: Content) {
        self.id = id
        self.content = content
    }
}

/// Page-owned state for the independently expandable and calendar-aware rows.
struct StockDetailRelatedInfoInteractionState: Hashable {
    var expandedItemIDs: Set<String>
    var calendarAddedItemIDs: Set<String>

    init(
        expandedItemIDs: Set<String> = [],
        calendarAddedItemIDs: Set<String> = []
    ) {
        self.expandedItemIDs = expandedItemIDs
        self.calendarAddedItemIDs = calendarAddedItemIDs
    }
}

/// The grouped related-information area of the stock-detail page.
///
/// It deliberately has the final page insets defined by the Figma assembly
/// frame so it can be dropped into the future detail page unchanged.
struct StockDetailRelatedInfo: View {
    let items: [StockDetailRelatedInfoItem]
    @Binding var interactionState: StockDetailRelatedInfoInteractionState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        items: [StockDetailRelatedInfoItem],
        interactionState: Binding<StockDetailRelatedInfoInteractionState>
    ) {
        self.items = items
        _interactionState = interactionState
    }

    var body: some View {
        VStack(spacing: StockDetailRelatedInfoLayout.itemSpacing) {
            ForEach(items.indices, id: \.self) { index in
                relatedInfoRow(items[index], at: index)
            }
        }
        .padding(.top, StockDetailRelatedInfoLayout.topPadding)
        .padding(.horizontal, StockDetailRelatedInfoLayout.horizontalPadding)
        .padding(.bottom, StockDetailRelatedInfoLayout.bottomPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.relatedInfo")
    }

    private func relatedInfoRow(
        _ item: StockDetailRelatedInfoItem,
        at index: Int
    ) -> some View {
        relatedInfoContent(item, isExpanded: isExpanded(item))
            .padding(.horizontal, StockDetailRelatedInfoLayout.rowHorizontalPadding)
            .padding(.vertical, StockDetailRelatedInfoLayout.rowVerticalPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("color-scale-1"))
            .clipShape(rowShape(at: index))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("stockDetail.relatedInfo.\(item.id)")
    }

    @ViewBuilder
    private func relatedInfoContent(
        _ item: StockDetailRelatedInfoItem,
        isExpanded: Bool
    ) -> some View {
        switch item.content {
        case let .aShareConnection(connection),
            let .shareConnection(connection),
            let .dualCounter(connection):
            connectionRow(connection)

        case let .adrConnectionUS(connection),
            let .adrConnectionHongKong(connection):
            adrConnectionRow(
                connection,
                isExpanded: isExpanded,
                onToggle: { toggleExpansion(for: item.id) }
            )

        case let .cas(range):
            rangeRow(range, showsCASIcon: true)

        case let .vcm(range):
            rangeRow(range, showsCASIcon: false)

        case let .financialReport(report):
            financialReportRow(
                report,
                isCalendarAdded: isCalendarAdded(item),
                onCalendarToggle: { toggleCalendar(for: item.id) }
            )

        case let .cashDividend(dividend):
            cashDividendRow(
                dividend,
                isExpanded: isExpanded,
                onToggle: { toggleExpansion(for: item.id) }
            )

        case let .extendedHours(hours):
            extendedHoursRow(
                hours,
                isExpanded: isExpanded,
                onToggle: { toggleExpansion(for: item.id) }
            )
        }
    }

    private func connectionRow(_ connection: StockDetailRelatedInfoConnection) -> some View {
        HStack(spacing: StockDetailRelatedInfoLayout.connectionGroupSpacing) {
            quoteRow(connection.quote)

            if let trailingLabel = connection.trailingLabel,
                let trailingValue = connection.trailingValue {
                HStack(spacing: StockDetailRelatedInfoLayout.quoteSpacing) {
                    relatedText(trailingLabel)
                    relatedText(trailingValue, tone: connection.trailingTone)
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func adrConnectionRow(
        _ connection: StockDetailRelatedInfoADRConnection,
        isExpanded: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        let canExpand = connection.relatedQuote != nil

        return VStack(
            alignment: .leading,
            spacing: isExpanded && canExpand
                ? StockDetailRelatedInfoLayout.adrExpandedSpacing
                : 0
        ) {
            HStack(spacing: 0) {
                HStack(spacing: StockDetailRelatedInfoLayout.quoteSpacing) {
                    relatedText(connection.conversionTitle)
                    relatedText(connection.conversionPrice, tone: connection.conversionTone)
                }

                Spacer(minLength: 0)

                HStack(spacing: StockDetailRelatedInfoLayout.trailingControlSpacing) {
                    HStack(spacing: StockDetailRelatedInfoLayout.quoteSpacing) {
                        relatedText(connection.relativeTitle)
                        relatedText(connection.relativeChange, tone: connection.relativeTone)
                        relatedText(connection.relativeChangePercent, tone: connection.relativeTone)
                    }

                    if canExpand {
                        disclosureButton(
                            isExpanded: isExpanded,
                            accessibilityLabel: "ADR换算价",
                            action: onToggle
                        )
                    }
                }
            }
            .lineLimit(1)

            if let relatedQuote = connection.relatedQuote {
                quoteRow(relatedQuote)
                    .stockDetailRelatedInfoExpansion(isExpanded: isExpanded)
            }
        }
    }

    private func rangeRow(
        _ range: StockDetailRelatedInfoRange,
        showsCASIcon: Bool
    ) -> some View {
        HStack(spacing: StockDetailRelatedInfoLayout.rangeSpacing) {
            HStack(spacing: StockDetailRelatedInfoLayout.rangeTitleSpacing) {
                if showsCASIcon {
                    glyph("stock_order_associate_info_cas", size: StockDetailRelatedInfoLayout.leadingGlyphSize)
                }

                relatedText(range.title)
            }

            relatedText(range.rangeLabel, tone: .secondary)
            relatedText(range.rangeValue)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func financialReportRow(
        _ report: StockDetailRelatedInfoFinancialReport,
        isCalendarAdded: Bool,
        onCalendarToggle: @escaping () -> Void
    ) -> some View {
        HStack(spacing: StockDetailRelatedInfoLayout.financialReportSpacing) {
            HStack(spacing: StockDetailRelatedInfoLayout.financialReportContentSpacing) {
                HStack(spacing: StockDetailRelatedInfoLayout.rangeTitleSpacing) {
                    glyph("assciate_info_financial_report", size: StockDetailRelatedInfoLayout.leadingGlyphSize)
                    relatedText(report.date)
                }

                relatedText(report.event)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)

            Spacer(minLength: 0)

            calendarButton(isAdded: isCalendarAdded, action: onCalendarToggle)
        }
    }

    private func cashDividendRow(
        _ dividend: StockDetailRelatedInfoCashDividend,
        isExpanded: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        let canExpand = !dividend.details.isEmpty

        return VStack(
            alignment: .leading,
            spacing: isExpanded && canExpand
                ? StockDetailRelatedInfoLayout.cashDividendExpandedSpacing
                : 0
        ) {
            HStack(
                alignment: isExpanded && canExpand ? .top : .center,
                spacing: StockDetailRelatedInfoLayout.cashDividendHeaderSpacing
            ) {
                HStack(alignment: .top, spacing: StockDetailRelatedInfoLayout.cashDividendLeadingSpacing) {
                    glyph("assciate_info_dividen", size: StockDetailRelatedInfoLayout.leadingGlyphSize)
                        .padding(.top, StockDetailRelatedInfoLayout.cashDividendGlyphTopOffset)

                    Text(dividend.summary)
                        .modifier(
                            CustomFontModifier(
                                size: StockDetailRelatedInfoLayout.fontSize,
                                font: .regular,
                                lineHeight: StockDetailRelatedInfoLayout.lineHeight
                            )
                        )
                        .foregroundColor(StockDetailRelatedInfoTone.primary.color)
                        .lineLimit(isExpanded && canExpand ? nil : 1)
                        .fixedSize(horizontal: false, vertical: isExpanded && canExpand)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if canExpand {
                    disclosureButton(
                        isExpanded: isExpanded,
                        accessibilityLabel: "除权除息信息",
                        action: onToggle
                    )
                }
            }

            if canExpand {
                dividendDetails(dividend.details)
                    .stockDetailRelatedInfoExpansion(isExpanded: isExpanded)
            }
        }
    }

    private func dividendDetails(
        _ details: [StockDetailRelatedInfoMetric]
    ) -> some View {
        VStack(spacing: StockDetailRelatedInfoLayout.dividendDetailSpacing) {
            ForEach(details) { detail in
                HStack(spacing: 0) {
                    relatedText(
                        detail.label,
                        tone: .secondary,
                        size: StockDetailRelatedInfoLayout.detailFontSize
                    )

                    Spacer(minLength: 0)

                    relatedText(
                        detail.value,
                        tone: detail.tone,
                        size: StockDetailRelatedInfoLayout.detailFontSize
                    )
                }
                .frame(height: StockDetailRelatedInfoLayout.lineHeight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func extendedHoursRow(
        _ hours: StockDetailRelatedInfoExtendedHours,
        isExpanded: Bool,
        onToggle: @escaping () -> Void
    ) -> some View {
        let canExpand = !hours.metrics.isEmpty

        return VStack(
            alignment: .leading,
            spacing: isExpanded && canExpand
                ? StockDetailRelatedInfoLayout.extendedHoursExpandedSpacing
                : 0
        ) {
            HStack(spacing: 0) {
                HStack(spacing: StockDetailRelatedInfoLayout.quoteSpacing) {
                    relatedText(hours.sessionTitle)
                    relatedText(hours.price, tone: hours.state.quoteTone)

                    if let change = hours.change {
                        relatedText(change, tone: hours.state.quoteTone)
                    }

                    if let changePercent = hours.changePercent {
                        relatedText(changePercent, tone: hours.state.quoteTone)
                    }
                }

                Spacer(minLength: 0)

                HStack(spacing: StockDetailRelatedInfoLayout.trailingControlSpacing) {
                    relatedText(hours.timestamp, tone: .secondary)

                    if canExpand {
                        disclosureButton(
                            isExpanded: isExpanded,
                            accessibilityLabel: "盘前盘后行情",
                            action: onToggle
                        )
                    }
                }
            }
            .lineLimit(1)

            if canExpand {
                extendedHoursMetrics(hours.metrics)
                    .stockDetailRelatedInfoExpansion(isExpanded: isExpanded)
            }
        }
    }

    private func extendedHoursMetrics(
        _ metrics: [StockDetailRelatedInfoMetric]
    ) -> some View {
        LazyVGrid(
            columns: [
                GridItem(
                    .flexible(minimum: 0),
                    spacing: StockDetailRelatedInfoLayout.extendedHoursColumnSpacing
                ),
                GridItem(.flexible(minimum: 0))
            ],
            alignment: .leading,
            spacing: StockDetailRelatedInfoLayout.extendedHoursRowSpacing
        ) {
            ForEach(metrics) { metric in
                HStack(spacing: StockDetailRelatedInfoLayout.metricSpacing) {
                    relatedText(metric.label, tone: .secondary)

                    Spacer(minLength: 0)

                    relatedText(metric.value, tone: metric.tone, font: .medium)
                }
                .frame(height: StockDetailRelatedInfoLayout.lineHeight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func quoteRow(_ quote: StockDetailRelatedInfoQuote) -> some View {
        HStack(spacing: StockDetailRelatedInfoLayout.quoteSpacing) {
            relatedText(quote.title)
            relatedText(quote.price, tone: quote.tone)

            if let change = quote.change {
                relatedText(change, tone: quote.tone)
            }

            if let changePercent = quote.changePercent {
                relatedText(changePercent, tone: quote.tone)
            }
        }
    }

    private func disclosureButton(
        isExpanded: Bool,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image("stat_expand_chevron")
                .resizable()
                .scaledToFit()
                .frame(
                    width: StockDetailRelatedInfoLayout.disclosureGlyphWidth,
                    height: StockDetailRelatedInfoLayout.disclosureGlyphHeight
                )
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
                .frame(
                    width: StockDetailRelatedInfoLayout.disclosureTapSize,
                    height: StockDetailRelatedInfoLayout.disclosureTapSize
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "收起\(accessibilityLabel)" : "展开\(accessibilityLabel)")
        .accessibilityValue(isExpanded ? "已展开" : "已收起")
    }

    private func calendarButton(
        isAdded: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(
                isAdded
                    ? "stock_detail_date_reminder_added"
                    : "stock_detail_date_reminder_no_add"
            )
            .resizable()
            .scaledToFit()
            .frame(
                width: StockDetailRelatedInfoLayout.calendarGlyphSize,
                height: StockDetailRelatedInfoLayout.calendarGlyphSize
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isAdded ? "移除业绩日历提醒" : "添加业绩日历提醒")
        .accessibilityValue(isAdded ? "已添加" : "未添加")
    }

    private func glyph(_ assetName: String, size: CGFloat) -> some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private func relatedText(
        _ value: String,
        tone: StockDetailRelatedInfoTone = .primary,
        size: CGFloat = StockDetailRelatedInfoLayout.fontSize,
        font: CustomFontModifier.CustomFont = .regular
    ) -> some View {
        Text(value)
            .modifier(
                CustomFontModifier(
                    size: size,
                    font: font,
                    lineHeight: StockDetailRelatedInfoLayout.lineHeight
                )
            )
            .foregroundColor(tone.color)
    }

    private func rowShape(at index: Int) -> UnevenRoundedRectangle {
        let topRadius = index == 0
            ? StockDetailRelatedInfoLayout.outerCornerRadius
            : StockDetailRelatedInfoLayout.innerCornerRadius
        let bottomRadius = index == items.count - 1
            ? StockDetailRelatedInfoLayout.outerCornerRadius
            : StockDetailRelatedInfoLayout.innerCornerRadius

        return UnevenRoundedRectangle(
            topLeadingRadius: topRadius,
            bottomLeadingRadius: bottomRadius,
            bottomTrailingRadius: bottomRadius,
            topTrailingRadius: topRadius,
            style: .continuous
        )
    }

    private func isExpanded(_ item: StockDetailRelatedInfoItem) -> Bool {
        interactionState.expandedItemIDs.contains(item.id)
    }

    private func isCalendarAdded(_ item: StockDetailRelatedInfoItem) -> Bool {
        interactionState.calendarAddedItemIDs.contains(item.id)
    }

    private func toggleExpansion(for itemID: String) {
        withAnimation(
            reduceMotion
                ? nil
                : .easeOut(duration: StockDetailRelatedInfoLayout.expansionDuration)
        ) {
            var expandedIDs = interactionState.expandedItemIDs

            if expandedIDs.contains(itemID) {
                expandedIDs.remove(itemID)
            } else {
                expandedIDs.insert(itemID)
            }

            interactionState.expandedItemIDs = expandedIDs
        }
    }

    private func toggleCalendar(for itemID: String) {
        var calendarIDs = interactionState.calendarAddedItemIDs

        if calendarIDs.contains(itemID) {
            calendarIDs.remove(itemID)
        } else {
            calendarIDs.insert(itemID)
        }

        interactionState.calendarAddedItemIDs = calendarIDs
    }
}

private enum StockDetailRelatedInfoLayout {
    static let topPadding: CGFloat = 8
    static let horizontalPadding: CGFloat = 16
    static let bottomPadding: CGFloat = 16
    static let itemSpacing: CGFloat = 2
    static let rowHorizontalPadding: CGFloat = 8
    static let rowVerticalPadding: CGFloat = 6
    static let outerCornerRadius: CGFloat = 8
    static let innerCornerRadius: CGFloat = 2
    static let fontSize: CGFloat = 13
    static let detailFontSize: CGFloat = 12
    static let lineHeight: CGFloat = 16
    static let quoteSpacing: CGFloat = 8
    static let connectionGroupSpacing: CGFloat = 10
    static let rangeSpacing: CGFloat = 10
    static let rangeTitleSpacing: CGFloat = 4
    static let financialReportSpacing: CGFloat = 10
    static let financialReportContentSpacing: CGFloat = 8
    static let cashDividendHeaderSpacing: CGFloat = 10
    static let cashDividendLeadingSpacing: CGFloat = 4
    static let cashDividendGlyphTopOffset: CGFloat = 1
    static let cashDividendExpandedSpacing: CGFloat = 8
    static let dividendDetailSpacing: CGFloat = 4
    static let adrExpandedSpacing: CGFloat = 6
    static let extendedHoursExpandedSpacing: CGFloat = 8
    static let extendedHoursColumnSpacing: CGFloat = 20
    static let extendedHoursRowSpacing: CGFloat = 4
    static let metricSpacing: CGFloat = 2
    static let trailingControlSpacing: CGFloat = 4
    static let leadingGlyphSize: CGFloat = 14
    static let calendarGlyphSize: CGFloat = 16
    static let disclosureGlyphWidth: CGFloat = 16
    static let disclosureGlyphHeight: CGFloat = 10
    static let disclosureTapSize: CGFloat = 16
    static let expansionDuration: CGFloat = 0.2
}

private struct StockDetailRelatedInfoExpansionModifier: ViewModifier {
    let isExpanded: Bool

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: isExpanded ? nil : 0, alignment: .topLeading)
            .clipped()
            .opacity(isExpanded ? 1 : 0)
            .blur(radius: isExpanded ? 0 : 2)
            .accessibilityHidden(!isExpanded)
    }
}

private extension View {
    func stockDetailRelatedInfoExpansion(isExpanded: Bool) -> some View {
        modifier(StockDetailRelatedInfoExpansionModifier(isExpanded: isExpanded))
    }
}

private enum StockDetailRelatedInfoPreviewData {
    static let financialReport = StockDetailRelatedInfoItem(
        id: "financial-report",
        content: .financialReport(
            StockDetailRelatedInfoFinancialReport(
                date: "2026/08/10(香港)",
                event: "公布业绩"
            )
        )
    )

    static let cashDividend = StockDetailRelatedInfoItem(
        id: "cash-dividend",
        content: .cashDividend(
            StockDetailRelatedInfoCashDividend(
                summary: "除权除息日:2026/06/13  每股派息3.40001HKD 超过截断",
                details: [
                    .init(label: "除权除息日", value: "2026/05/29"),
                    .init(label: "股权登记日", value: "2026/05/28"),
                    .init(label: "派息日", value: "2026/06/13")
                ]
            )
        )
    )

    static let cas = StockDetailRelatedInfoItem(
        id: "cas",
        content: .cas(
            StockDetailRelatedInfoRange(
                title: "竞价时段",
                rangeLabel: "价格范围",
                rangeValue: "16.400 ~ 16.800"
            )
        )
    )

    static let vcm = StockDetailRelatedInfoItem(
        id: "vcm",
        content: .vcm(
            StockDetailRelatedInfoRange(
                title: "冷静期",
                rangeLabel: "价格范围",
                rangeValue: "16.400 ~ 16.800"
            )
        )
    )

    static let adrUS = StockDetailRelatedInfoItem(
        id: "adr-us",
        content: .adrConnectionUS(
            StockDetailRelatedInfoADRConnection(
                conversionTitle: "ADR换算价",
                conversionPrice: "12.300",
                conversionTone: .negative,
                relativeTitle: "相对港股",
                relativeChange: "-5.552",
                relativeChangePercent: "-5.55%",
                relativeTone: .negative,
                relatedQuote: StockDetailRelatedInfoQuote(
                    title: "阿里巴巴",
                    price: "12.300",
                    change: "+2.22",
                    changePercent: "+1.23%",
                    tone: .positive
                )
            )
        )
    )

    static let aShareConnection = StockDetailRelatedInfoItem(
        id: "a-share-connection",
        content: .aShareConnection(
            StockDetailRelatedInfoConnection(
                quote: StockDetailRelatedInfoQuote(
                    title: "H股",
                    price: "293.860",
                    change: "+0.540",
                    changePercent: "+0.18%",
                    tone: .positive
                ),
                trailingLabel: "溢价(H/A)",
                trailingValue: "-0.34%"
            )
        )
    )

    static let shareConnection = StockDetailRelatedInfoItem(
        id: "share-connection",
        content: .shareConnection(
            StockDetailRelatedInfoConnection(
                quote: StockDetailRelatedInfoQuote(
                    title: "腾讯控股",
                    price: "12.300",
                    change: "+2.22",
                    changePercent: "+1.23%",
                    tone: .positive
                )
            )
        )
    )

    static let dualCounter = StockDetailRelatedInfoItem(
        id: "dual-counter",
        content: .dualCounter(
            StockDetailRelatedInfoConnection(
                quote: StockDetailRelatedInfoQuote(
                    title: "人民币柜台",
                    price: "293.860",
                    change: "+0.540",
                    changePercent: "+0.18%",
                    tone: .positive
                )
            )
        )
    )

    static let extendedHours = StockDetailRelatedInfoItem(
        id: "extended-hours",
        content: .extendedHours(
            StockDetailRelatedInfoExtendedHours(
                state: .trading,
                sessionTitle: "盘前",
                price: "12.300",
                change: "+2.220",
                changePercent: "+1.23%",
                timestamp: "8:01 美东",
                metrics: [
                    .init(label: "最高价", value: "12.65", tone: .positive),
                    .init(label: "成交额", value: "4001.22万"),
                    .init(label: "最低价", value: "12.45", tone: .negative),
                    .init(label: "成交量", value: "44.99万股")
                ]
            )
        )
    )

    static let adrHongKong = StockDetailRelatedInfoItem(
        id: "adr-hong-kong",
        content: .adrConnectionHongKong(
            StockDetailRelatedInfoADRConnection(
                conversionTitle: "港股换算价",
                conversionPrice: "12.300",
                conversionTone: .negative,
                relativeTitle: "相对美股",
                relativeChange: "-5.552",
                relativeChangePercent: "-5.55%",
                relativeTone: .negative,
                relatedQuote: StockDetailRelatedInfoQuote(
                    title: "阿里巴巴",
                    price: "12.300",
                    change: "+2.22",
                    changePercent: "+1.23%",
                    tone: .positive
                )
            )
        )
    )

    static let combined: [StockDetailRelatedInfoItem] = [
        financialReport,
        cashDividend,
        cas,
        vcm,
        adrUS,
        aShareConnection,
        shareConnection,
        dualCounter,
        extendedHours
    ]

    static let allVariants: [StockDetailRelatedInfoItem] = [
        financialReport,
        cashDividend,
        cas,
        vcm,
        adrUS,
        adrHongKong,
        aShareConnection,
        shareConnection,
        dualCounter,
        extendedHours
    ]
}

private struct StockDetailRelatedInfoPreview: View {
    let items: [StockDetailRelatedInfoItem]
    @State private var interactionState: StockDetailRelatedInfoInteractionState

    init(
        items: [StockDetailRelatedInfoItem],
        interactionState: StockDetailRelatedInfoInteractionState = .init()
    ) {
        self.items = items
        _interactionState = State(initialValue: interactionState)
    }

    var body: some View {
        StockDetailRelatedInfo(
            items: items,
            interactionState: $interactionState
        )
        .frame(width: 402)
    }
}

struct StockDetailRelatedInfo_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockDetailRelatedInfoPreview(items: StockDetailRelatedInfoPreviewData.combined)
                .previewDisplayName("Combined · Collapsed")

            StockDetailRelatedInfoPreview(
                items: StockDetailRelatedInfoPreviewData.allVariants,
                interactionState: StockDetailRelatedInfoInteractionState(
                    expandedItemIDs: ["cash-dividend", "adr-us", "extended-hours"],
                    calendarAddedItemIDs: ["financial-report"]
                )
            )
            .previewDisplayName("All Variants · Expanded")
        }
        .previewLayout(.sizeThatFits)
    }
}
