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
    private let localizedTitle: StockDetailQuoteLocalizedText?

    init(
        title: String,
        price: String,
        change: String? = nil,
        changePercent: String? = nil,
        tone: StockDetailRelatedInfoTone,
        localizedTitle: StockDetailQuoteLocalizedText? = nil
    ) {
        self.title = title
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.tone = tone
        self.localizedTitle = localizedTitle
    }

    fileprivate func displayTitle(for language: DemoLanguage) -> String {
        localizedTitle?.text(for: language) ?? title
    }
}

struct StockDetailRelatedInfoMetric: Hashable, Identifiable {
    let label: String
    let value: String
    let tone: StockDetailRelatedInfoTone
    private let localizedLabel: StockDetailQuoteLocalizedText?
    private let localizedValue: StockDetailQuoteLocalizedText?

    var id: String { label }

    init(
        label: String,
        value: String,
        tone: StockDetailRelatedInfoTone = .primary,
        localizedLabel: StockDetailQuoteLocalizedText? = nil,
        localizedValue: StockDetailQuoteLocalizedText? = nil
    ) {
        self.label = label
        self.value = value
        self.tone = tone
        self.localizedLabel = localizedLabel
        self.localizedValue = localizedValue
    }

    fileprivate func displayLabel(for language: DemoLanguage) -> String {
        localizedLabel?.text(for: language) ?? label
    }

    fileprivate func displayValue(for language: DemoLanguage) -> String {
        localizedValue?.text(for: language) ?? value
    }
}

struct StockDetailRelatedInfoConnection: Hashable {
    let quote: StockDetailRelatedInfoQuote
    let trailingLabel: String?
    let trailingValue: String?
    let trailingTone: StockDetailRelatedInfoTone
    private let localizedTrailingLabel: StockDetailQuoteLocalizedText?

    init(
        quote: StockDetailRelatedInfoQuote,
        trailingLabel: String? = nil,
        trailingValue: String? = nil,
        trailingTone: StockDetailRelatedInfoTone = .primary,
        localizedTrailingLabel: StockDetailQuoteLocalizedText? = nil
    ) {
        self.quote = quote
        self.trailingLabel = trailingLabel
        self.trailingValue = trailingValue
        self.trailingTone = trailingTone
        self.localizedTrailingLabel = localizedTrailingLabel
    }

    fileprivate func displayTrailingLabel(for language: DemoLanguage) -> String? {
        localizedTrailingLabel?.text(for: language) ?? trailingLabel
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
    private let localizedConversionTitle: StockDetailQuoteLocalizedText?
    private let localizedRelativeTitle: StockDetailQuoteLocalizedText?

    init(
        conversionTitle: String,
        conversionPrice: String,
        conversionTone: StockDetailRelatedInfoTone,
        relativeTitle: String,
        relativeChange: String,
        relativeChangePercent: String,
        relativeTone: StockDetailRelatedInfoTone,
        relatedQuote: StockDetailRelatedInfoQuote? = nil,
        localizedConversionTitle: StockDetailQuoteLocalizedText? = nil,
        localizedRelativeTitle: StockDetailQuoteLocalizedText? = nil
    ) {
        self.conversionTitle = conversionTitle
        self.conversionPrice = conversionPrice
        self.conversionTone = conversionTone
        self.relativeTitle = relativeTitle
        self.relativeChange = relativeChange
        self.relativeChangePercent = relativeChangePercent
        self.relativeTone = relativeTone
        self.relatedQuote = relatedQuote
        self.localizedConversionTitle = localizedConversionTitle
        self.localizedRelativeTitle = localizedRelativeTitle
    }

    fileprivate func displayConversionTitle(for language: DemoLanguage) -> String {
        localizedConversionTitle?.text(for: language) ?? conversionTitle
    }

    fileprivate func displayRelativeTitle(for language: DemoLanguage) -> String {
        localizedRelativeTitle?.text(for: language) ?? relativeTitle
    }
}

struct StockDetailRelatedInfoRange: Hashable {
    let title: String
    let rangeLabel: String
    let rangeValue: String
    private let localizedTitle: StockDetailQuoteLocalizedText?
    private let localizedRangeLabel: StockDetailQuoteLocalizedText?

    init(
        title: String,
        rangeLabel: String,
        rangeValue: String,
        localizedTitle: StockDetailQuoteLocalizedText? = nil,
        localizedRangeLabel: StockDetailQuoteLocalizedText? = nil
    ) {
        self.title = title
        self.rangeLabel = rangeLabel
        self.rangeValue = rangeValue
        self.localizedTitle = localizedTitle
        self.localizedRangeLabel = localizedRangeLabel
    }

    fileprivate func displayTitle(for language: DemoLanguage) -> String {
        localizedTitle?.text(for: language) ?? title
    }

    fileprivate func displayRangeLabel(for language: DemoLanguage) -> String {
        localizedRangeLabel?.text(for: language) ?? rangeLabel
    }
}

struct StockDetailRelatedInfoFinancialReport: Hashable {
    let date: String
    let event: String
    private let localizedDate: StockDetailQuoteLocalizedText?
    private let localizedEvent: StockDetailQuoteLocalizedText?

    init(
        date: String,
        event: String,
        localizedDate: StockDetailQuoteLocalizedText? = nil,
        localizedEvent: StockDetailQuoteLocalizedText? = nil
    ) {
        self.date = date
        self.event = event
        self.localizedDate = localizedDate
        self.localizedEvent = localizedEvent
    }

    fileprivate func displayDate(for language: DemoLanguage) -> String {
        localizedDate?.text(for: language) ?? date
    }

    fileprivate func displayEvent(for language: DemoLanguage) -> String {
        localizedEvent?.text(for: language) ?? event
    }
}

struct StockDetailRelatedInfoCashDividend: Hashable {
    let summary: String
    let details: [StockDetailRelatedInfoMetric]
    private let localizedSummary: StockDetailQuoteLocalizedText?

    init(
        summary: String,
        details: [StockDetailRelatedInfoMetric],
        localizedSummary: StockDetailQuoteLocalizedText? = nil
    ) {
        self.summary = summary
        self.details = details
        self.localizedSummary = localizedSummary
    }

    fileprivate func displaySummary(for language: DemoLanguage) -> String {
        localizedSummary?.text(for: language) ?? summary
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
    private let localizedSessionTitle: StockDetailQuoteLocalizedText?
    private let localizedTimestamp: StockDetailQuoteLocalizedText?

    init(
        state: StockDetailRelatedInfoExtendedHoursState,
        sessionTitle: String,
        price: String,
        change: String? = nil,
        changePercent: String? = nil,
        timestamp: String,
        metrics: [StockDetailRelatedInfoMetric],
        localizedSessionTitle: StockDetailQuoteLocalizedText? = nil,
        localizedTimestamp: StockDetailQuoteLocalizedText? = nil
    ) {
        self.state = state
        self.sessionTitle = sessionTitle
        self.price = price
        self.change = change
        self.changePercent = changePercent
        self.timestamp = timestamp
        self.metrics = metrics
        self.localizedSessionTitle = localizedSessionTitle
        self.localizedTimestamp = localizedTimestamp
    }

    fileprivate func displaySessionTitle(for language: DemoLanguage) -> String {
        localizedSessionTitle?.text(for: language) ?? sessionTitle
    }

    fileprivate func displayTimestamp(for language: DemoLanguage) -> String {
        localizedTimestamp?.text(for: language) ?? timestamp
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
    let onInteraction: (() -> Void)?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.demoLanguage) private var language

    init(
        items: [StockDetailRelatedInfoItem],
        interactionState: Binding<StockDetailRelatedInfoInteractionState>,
        onInteraction: (() -> Void)? = nil
    ) {
        self.items = items
        _interactionState = interactionState
        self.onInteraction = onInteraction
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
            .background(rowBackground(for: item))
            .clipShape(rowShape(at: index))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("stockDetail.relatedInfo.\(item.id)")
    }

    private func rowBackground(for item: StockDetailRelatedInfoItem) -> Color {
        if case let .extendedHours(hours) = item.content, hours.state == .trading {
            return StockDetailLiveQuoteBackground.color(for: colorScheme)
        }

        return Color("color-scale-1")
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
                onToggle: { handleInteraction { toggleExpansion(for: item.id) } }
            )

        case let .cas(range):
            rangeRow(range, showsCASIcon: true)

        case let .vcm(range):
            rangeRow(range, showsCASIcon: false)

        case let .financialReport(report):
            financialReportRow(
                report,
                isCalendarAdded: isCalendarAdded(item),
                onCalendarToggle: { handleInteraction { toggleCalendar(for: item.id) } }
            )

        case let .cashDividend(dividend):
            cashDividendRow(
                dividend,
                isExpanded: isExpanded,
                onToggle: { handleInteraction { toggleExpansion(for: item.id) } }
            )

        case let .extendedHours(hours):
            extendedHoursRow(
                hours,
                isExpanded: isExpanded,
                onToggle: { handleInteraction { toggleExpansion(for: item.id) } }
            )
        }
    }

    private func connectionRow(_ connection: StockDetailRelatedInfoConnection) -> some View {
        HStack(spacing: StockDetailRelatedInfoLayout.connectionGroupSpacing) {
            quoteRow(connection.quote)

            if let trailingLabel = connection.displayTrailingLabel(for: language),
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

        return StockDetailRelatedInfoExpandableRow(
            isExpanded: isExpanded,
            spacing: StockDetailRelatedInfoLayout.adrExpandedSpacing,
            header: {
                HStack(spacing: 0) {
                    HStack(spacing: StockDetailRelatedInfoLayout.quoteSpacing) {
                        relatedText(connection.displayConversionTitle(for: language))
                        relatedText(connection.conversionPrice, tone: connection.conversionTone)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: StockDetailRelatedInfoLayout.trailingControlSpacing) {
                        HStack(spacing: StockDetailRelatedInfoLayout.quoteSpacing) {
                            relatedText(connection.displayRelativeTitle(for: language))
                            relatedText(connection.relativeChange, tone: connection.relativeTone)
                            relatedText(connection.relativeChangePercent, tone: connection.relativeTone)
                        }

                        if canExpand {
                            disclosureButton(
                                isExpanded: isExpanded,
                                accessibilityLabel: language.text(.adrConversionPrice),
                                action: onToggle
                            )
                        }
                    }
                }
                .lineLimit(1)
            },
            details: {
                if let relatedQuote = connection.relatedQuote {
                    quoteRow(relatedQuote)
                }
            }
        )
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

                relatedText(range.displayTitle(for: language))
            }

            relatedText(range.displayRangeLabel(for: language), tone: .secondary)
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
                    relatedText(report.displayDate(for: language))
                }

                relatedText(report.displayEvent(for: language))
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

        return StockDetailRelatedInfoExpandableRow(
            isExpanded: isExpanded,
            spacing: StockDetailRelatedInfoLayout.cashDividendExpandedSpacing,
            header: {
                HStack(
                    alignment: isExpanded && canExpand ? .top : .center,
                    spacing: StockDetailRelatedInfoLayout.cashDividendHeaderSpacing
                ) {
                    HStack(alignment: .top, spacing: StockDetailRelatedInfoLayout.cashDividendLeadingSpacing) {
                        glyph("assciate_info_dividen", size: StockDetailRelatedInfoLayout.leadingGlyphSize)
                            .padding(.top, StockDetailRelatedInfoLayout.cashDividendGlyphTopOffset)

                        Text(dividend.displaySummary(for: language))
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
                            accessibilityLabel: language.text(.exDividendInformation),
                            action: onToggle
                        )
                    }
                }
            },
            details: {
                dividendDetails(dividend.details)
            }
        )
    }

    private func dividendDetails(
        _ details: [StockDetailRelatedInfoMetric]
    ) -> some View {
        VStack(spacing: StockDetailRelatedInfoLayout.dividendDetailSpacing) {
            ForEach(details) { detail in
                HStack(spacing: 0) {
                    relatedText(
                        detail.displayLabel(for: language),
                        tone: .secondary,
                        size: StockDetailRelatedInfoLayout.detailFontSize
                    )

                    Spacer(minLength: 0)

                    relatedText(
                        detail.displayValue(for: language),
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

        return StockDetailRelatedInfoExpandableRow(
            isExpanded: isExpanded,
            spacing: StockDetailRelatedInfoLayout.extendedHoursExpandedSpacing,
            header: {
                HStack(spacing: 0) {
                    HStack(spacing: StockDetailRelatedInfoLayout.quoteSpacing) {
                        relatedText(hours.displaySessionTitle(for: language))
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
                        relatedText(hours.displayTimestamp(for: language), tone: .secondary)

                        if canExpand {
                            disclosureButton(
                                isExpanded: isExpanded,
                                accessibilityLabel: language.text(.extendedHoursQuote),
                                action: onToggle
                            )
                        }
                    }
                }
                .lineLimit(1)
            },
            details: {
                extendedHoursMetrics(hours.metrics)
            }
        )
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
                    relatedText(metric.displayLabel(for: language), tone: .secondary)

                    Spacer(minLength: 0)

                    relatedText(metric.displayValue(for: language), tone: metric.tone, font: .medium)
                }
                .frame(height: StockDetailRelatedInfoLayout.lineHeight)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func quoteRow(_ quote: StockDetailRelatedInfoQuote) -> some View {
        HStack(spacing: StockDetailRelatedInfoLayout.quoteSpacing) {
            relatedText(quote.displayTitle(for: language))
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
        .accessibilityLabel(
            language == .english
                ? "\(language.text(isExpanded ? .collapse : .expand)) \(accessibilityLabel)"
                : "\(language.text(isExpanded ? .collapse : .expand))\(accessibilityLabel)"
        )
        .accessibilityValue(language.text(isExpanded ? .expanded : .collapsed))
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
        .accessibilityLabel(
            language.text(isAdded ? .removeEarningsCalendarReminder : .addEarningsCalendarReminder)
        )
        .accessibilityValue(language.text(isAdded ? .added : .notAdded))
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

    private func handleInteraction(_ action: () -> Void) {
        if let onInteraction {
            onInteraction()
        } else {
            action()
        }
    }
}

private struct StockDetailRelatedInfoExpandableRow<Header: View, Details: View>: View {
    let isExpanded: Bool
    let spacing: CGFloat
    let header: Header
    let details: Details

    init(
        isExpanded: Bool,
        spacing: CGFloat,
        @ViewBuilder header: () -> Header,
        @ViewBuilder details: () -> Details
    ) {
        self.isExpanded = isExpanded
        self.spacing = spacing
        self.header = header()
        self.details = details()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: isExpanded ? spacing : 0) {
            // The header remains outside the clipped detail content. This
            // keeps the collapse control in the original collapsed row.
            header

            details
                .stockDetailRelatedInfoExpansion(isExpanded: isExpanded)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
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

private extension StockDetailQuoteLocalizedText {
    static func related(
        _ simplifiedChinese: String,
        traditionalChinese: String? = nil,
        english: String
    ) -> Self {
        Self(
            simplifiedChinese: simplifiedChinese,
            traditionalChinese: traditionalChinese,
            english: english
        )
    }
}

enum StockDetailRelatedInfoPreviewData {
    static let financialReport = makeFinancialReport(
        id: "financial-report",
        simplifiedDate: "2026/08/10",
        traditionalDate: "2026/08/10",
        englishDate: "2026/08/10"
    )

    static let usFinancialReport = makeFinancialReport(
        id: "us-financial-report",
        simplifiedDate: "2026/08/10(美东)",
        traditionalDate: "2026/08/10(美東)",
        englishDate: "2026/08/10 (ET)"
    )

    private static func makeFinancialReport(
        id: String,
        simplifiedDate: String,
        traditionalDate: String,
        englishDate: String
    ) -> StockDetailRelatedInfoItem {
        StockDetailRelatedInfoItem(
            id: id,
            content: .financialReport(
                StockDetailRelatedInfoFinancialReport(
                    date: simplifiedDate,
                    event: "公布业绩",
                    localizedDate: .related(
                        simplifiedDate,
                        traditionalChinese: traditionalDate,
                        english: englishDate
                    ),
                    localizedEvent: .related(
                        "公布业绩",
                        traditionalChinese: "公布業績",
                        english: "Earning Release"
                    )
                )
            )
        )
    }

    static let cashDividend = StockDetailRelatedInfoItem(
        id: "cash-dividend",
        content: .cashDividend(
            StockDetailRelatedInfoCashDividend(
                summary: "除权除息日:2026/06/13  每股派息3.40001HKD 超过截断",
                details: [
                    .init(
                        label: "除权除息日",
                        value: "2026/05/29",
                        localizedLabel: .related(
                            "除权除息日",
                            traditionalChinese: "除權除息日",
                            english: "Ex-Date"
                        )
                    ),
                    .init(
                        label: "股权登记日",
                        value: "2026/05/28",
                        localizedLabel: .related(
                            "股权登记日",
                            traditionalChinese: "股權登記日",
                            english: "Record date"
                        )
                    ),
                    .init(
                        label: "派息日",
                        value: "2026/06/13",
                        localizedLabel: .related(
                            "派息日",
                            traditionalChinese: "派息日",
                            english: "Payment date"
                        )
                    )
                ],
                localizedSummary: .related(
                    "除权除息日:2026/06/13  每股派息3.40001HKD 超过截断",
                    traditionalChinese: "除權除息日:2026/06/13  每股派息3.40001HKD 超過截斷",
                    english: "Ex-Date: 2026/06/13  Dividend per share 3.40001 HKD exceeds truncation"
                )
            )
        )
    )

    static let cas = StockDetailRelatedInfoItem(
        id: "cas",
        content: .cas(
            StockDetailRelatedInfoRange(
                title: "竞价时段",
                rangeLabel: "价格范围",
                rangeValue: "16.400 ~ 16.800",
                localizedTitle: .related(
                    "竞价时段",
                    traditionalChinese: "競價時段",
                    english: "CAS"
                ),
                localizedRangeLabel: .related(
                    "价格范围",
                    traditionalChinese: "價格範圍",
                    english: "Price range"
                )
            )
        )
    )

    static let vcm = StockDetailRelatedInfoItem(
        id: "vcm",
        content: .vcm(
            StockDetailRelatedInfoRange(
                title: "冷静期",
                rangeLabel: "价格范围",
                rangeValue: "16.400 ~ 16.800",
                localizedTitle: .related(
                    "冷静期",
                    traditionalChinese: "冷靜期",
                    english: "VCM"
                ),
                localizedRangeLabel: .related(
                    "价格范围",
                    traditionalChinese: "價格範圍",
                    english: "Price range"
                )
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
                    tone: .positive,
                    localizedTitle: .related(
                        "阿里巴巴",
                        traditionalChinese: "阿里巴巴",
                        english: "Alibaba"
                    )
                ),
                localizedConversionTitle: .related(
                    "ADR换算价",
                    traditionalChinese: "ADR換算價",
                    english: "ADR conversion price"
                ),
                localizedRelativeTitle: .related(
                    "相对港股",
                    traditionalChinese: "相對港股",
                    english: "vs HK stock"
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
                    tone: .positive,
                    localizedTitle: .related(
                        "H股",
                        traditionalChinese: "H股",
                        english: "H share"
                    )
                ),
                trailingLabel: "溢价(H/A)",
                trailingValue: "-0.34%",
                localizedTrailingLabel: .related(
                    "溢价(H/A)",
                    traditionalChinese: "溢價(H/A)",
                    english: "Premium (H/A)"
                )
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
                    tone: .positive,
                    localizedTitle: .related(
                        "腾讯控股",
                        traditionalChinese: "騰訊控股",
                        english: "Tencent"
                    )
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
                    tone: .positive,
                    localizedTitle: .related(
                        "人民币柜台",
                        traditionalChinese: "人民幣櫃台",
                        english: "CNY counter"
                    )
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
                    .init(
                        label: "最高价",
                        value: "12.65",
                        tone: .positive,
                        localizedLabel: .related(
                            "最高价",
                            traditionalChinese: "最高價",
                            english: "High"
                        )
                    ),
                    .init(
                        label: "成交额",
                        value: "4001.22万",
                        localizedLabel: .related(
                            "成交额",
                            traditionalChinese: "成交額",
                            english: "Turnover"
                        ),
                        localizedValue: .related(
                            "4001.22万",
                            traditionalChinese: "4001.22萬",
                            english: "40.0122M"
                        )
                    ),
                    .init(
                        label: "最低价",
                        value: "12.45",
                        tone: .negative,
                        localizedLabel: .related(
                            "最低价",
                            traditionalChinese: "最低價",
                            english: "Low"
                        )
                    ),
                    .init(
                        label: "成交量",
                        value: "44.99万股",
                        localizedLabel: .related(
                            "成交量",
                            traditionalChinese: "成交量",
                            english: "Volume"
                        ),
                        localizedValue: .related(
                            "44.99万股",
                            traditionalChinese: "44.99萬股",
                            english: "449.9K shares"
                        )
                    )
                ],
                localizedSessionTitle: .related(
                    "盘前",
                    traditionalChinese: "盤前",
                    english: "Pre-market"
                ),
                localizedTimestamp: .related(
                    "8:01 美东",
                    traditionalChinese: "8:01 美東",
                    english: "8:01 ET"
                )
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
                    tone: .positive,
                    localizedTitle: .related(
                        "阿里巴巴",
                        traditionalChinese: "阿里巴巴",
                        english: "Alibaba"
                    )
                ),
                localizedConversionTitle: .related(
                    "港股换算价",
                    traditionalChinese: "港股換算價",
                    english: "HK stock conversion price"
                ),
                localizedRelativeTitle: .related(
                    "相对美股",
                    traditionalChinese: "相對美股",
                    english: "vs US stock"
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
