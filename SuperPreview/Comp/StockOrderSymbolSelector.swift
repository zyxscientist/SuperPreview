//
//  StockOrderSymbolSelector.swift
//  SuperPreview
//

import SwiftUI

struct StockOrderSymbolSelector: View {
    @Binding var selection: StockOrderSymbol?
    @Binding var isChartExpanded: Bool
    @Binding var recentSymbols: [StockOrderSymbol]

    let searchableSymbols: [StockOrderSymbol]
    let searchAvailability: StockOrderSearchAvailability
    let onRetrySearch: () -> Void

    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @State private var isSearchPresented = false
    @State private var query = ""

    init(
        selection: Binding<StockOrderSymbol?>,
        isChartExpanded: Binding<Bool>,
        recentSymbols: Binding<[StockOrderSymbol]>,
        searchableSymbols: [StockOrderSymbol],
        searchAvailability: StockOrderSearchAvailability = .available,
        onRetrySearch: @escaping () -> Void = {}
    ) {
        _selection = selection
        _isChartExpanded = isChartExpanded
        _recentSymbols = recentSymbols
        self.searchableSymbols = searchableSymbols
        self.searchAvailability = searchAvailability
        self.onRetrySearch = onRetrySearch
    }

    var body: some View {
        StockOrderSymbolInput(
            symbol: selection,
            isChartExpanded: $isChartExpanded,
            onSearchRequested: {
                isSearchPresented = true
            },
            onClearSelection: clearSelection
        )
        .sheet(isPresented: $isSearchPresented, onDismiss: {
            query = ""
        }) {
            StockOrderSymbolSearchSheet(
                query: $query,
                recentSymbols: recentSymbols,
                results: filteredSearchResults,
                availability: searchAvailability,
                onSelect: selectSymbol,
                onClearHistory: {
                    recentSymbols.removeAll()
                },
                onRetry: onRetrySearch
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationCornerRadius(10)
        }
        .accessibilityIdentifier("stockOrder.symbolSelector")
    }

    private var filteredSearchResults: [StockOrderSymbol] {
        let normalizedQuery = query.stockOrderSearchNormalized
        guard !normalizedQuery.isEmpty else { return [] }

        return searchableSymbols.filter { symbol in
            symbol.searchableText(for: language).contains {
                $0.stockOrderSearchNormalized.contains(normalizedQuery)
            }
        }
    }

    private func selectSymbol(_ symbol: StockOrderSymbol) {
        selection = symbol
        recentSymbols.removeAll { $0.id == symbol.id }
        recentSymbols.insert(symbol, at: 0)
        if recentSymbols.count > 7 {
            recentSymbols.removeLast()
        }

        withAnimation(
            StockOrderMotion.expansion(reduceMotion: accessibilityReduceMotion)
        ) {
            isChartExpanded = false
        }
        isSearchPresented = false
    }

    private func clearSelection() {
        guard selection != nil else { return }

        HapticManager.instance.impactHaptic(type: .medium)

        withAnimation(
            StockOrderMotion.expansion(reduceMotion: accessibilityReduceMotion)
        ) {
            selection = nil
            isChartExpanded = false
        }
    }
}

struct StockOrderSymbolInput: View {
    let symbol: StockOrderSymbol?
    @Binding var isChartExpanded: Bool
    let onSearchRequested: () -> Void
    let onClearSelection: () -> Void

    @Environment(\.demoLanguage) private var language
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    init(
        symbol: StockOrderSymbol?,
        isChartExpanded: Binding<Bool>,
        onSearchRequested: @escaping () -> Void,
        onClearSelection: @escaping () -> Void = {}
    ) {
        self.symbol = symbol
        _isChartExpanded = isChartExpanded
        self.onSearchRequested = onSearchRequested
        self.onClearSelection = onClearSelection
    }

    var body: some View {
        Group {
            if let symbol {
                selectedContent(symbol)
            } else {
                emptyContent
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockOrder.symbolInput")
    }

    private var emptyContent: some View {
        HStack(spacing: 0) {
            Text(language.text(.name))
                .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 24))
                .foregroundColor(Color("color-text-30"))
                .frame(width: 112, height: 44, alignment: .leading)

            Button(action: onSearchRequested) {
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color("color-scale-2"))

                    Text(language.text(.stockInputPlaceholder))
                        .modifier(CustomFontModifier(size: 16, font: .regular, lineHeight: 28))
                        .foregroundColor(Color("color-text-60"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.leading, 12)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .frame(maxWidth: .infinity, minHeight: 44, maxHeight: 44)
            .accessibilityLabel(language.text(.stockInputPlaceholder))
            .accessibilityIdentifier("stsockOrder.symbolInput.emptyField")
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }

    private func selectedContent(_ symbol: StockOrderSymbol) -> some View {
        VStack(spacing: 0) {
            selectedSummary(symbol)

            if isChartExpanded {
                StockOrderChartSnapshot()
                    .padding(.top, 6)
                    .transition(
                        .opacity.combined(
                            with: .scale(scale: 0.98, anchor: .top)
                        )
                    )
            }
        }
        .animation(
            StockOrderMotion.expansion(reduceMotion: accessibilityReduceMotion),
            value: isChartExpanded
        )
        .highPriorityGesture(
            TapGesture(count: 2)
                .onEnded {
                    onClearSelection()
                }
        )
    }

    private func selectedSummary(_ symbol: StockOrderSymbol) -> some View {
        let baseHeight: CGFloat = symbol.marketNotice == nil ? 76 : 115

        return ZStack(alignment: .bottom) {
            Button(action: onSearchRequested) {
                VStack(spacing: 0) {
                    StockOrderQuoteSummary(symbol: symbol)
                        .frame(height: 66)

                    if let marketNotice = symbol.marketNotice {
                        StockOrderMarketNoticeView(notice: marketNotice)
                            .frame(height: 29)
                    } else {
                        Color.clear
                            .frame(height: 10)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: baseHeight, alignment: .top)
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())
            .accessibilityLabel(
                language.actionAccessibilityLabel(
                    name: symbol.localizedName(for: language),
                    action: language.text(.search)
                )
            )
            .accessibilityIdentifier("stockOrder.symbolInput.selectedSymbol")

            chartToggle
                .zIndex(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: baseHeight, alignment: .top)
    }

    private var chartToggle: some View {
        Button {
            HapticManager.instance.impactHaptic(type: .medium)

            withAnimation(
                StockOrderMotion.expansion(reduceMotion: accessibilityReduceMotion)
            ) {
                isChartExpanded.toggle()
            }
        } label: {
            HStack(spacing: 0) {
                Text(language.text(isChartExpanded ? .collapseChart : .expandChart))
                    .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                    .foregroundColor(Color("color-text-60"))
                    .fixedSize(horizontal: true, vertical: false)

                Image(isChartExpanded ? "stock_order_chevron_up" : "stock_order_chevron_down")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            }
            .padding(.leading, 12)
            .padding(.trailing, 8)
            .frame(minWidth: 80, minHeight: 20)
            .background(Color("color-scale-2"))
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
        .accessibilityLabel(language.text(isChartExpanded ? .collapseChart : .expandChart))
        .accessibilityIdentifier("stockOrder.symbolInput.expandChart")
    }
}

private struct StockOrderQuoteSummary: View {
    let symbol: StockOrderSymbol

    var body: some View {
        GeometryReader { proxy in
            let nameWidth = max(CGFloat(110), proxy.size.width - 252)

            ZStack(alignment: .topLeading) {
                StockOrderSelectedSymbolCell(
                    symbol: symbol
                )
                .frame(width: nameWidth, height: 66, alignment: .leading)
                .clipped()
                .position(x: nameWidth / 2, y: 33)

                StockOrderMiniKLine(
                    points: symbol.quote.miniKPoints,
                    trend: symbol.quote.trend
                )
                .frame(width: 52, height: 28)
                .position(x: nameWidth + 26, y: 33)
                .accessibilityHidden(true)

                StockOrderPriceView(quote: symbol.quote)
                    .frame(width: 90, height: 66)
                    .position(x: proxy.size.width - 110 - 45, y: 33)

                StockOrderChangeTile(quote: symbol.quote)
                    .frame(width: 90, height: 66)
                    .position(x: proxy.size.width - 45, y: 33)
            }
            .frame(width: proxy.size.width, height: 66, alignment: .topLeading)
        }
    }
}

private struct StockOrderSelectedSymbolCell: View {
    let symbol: StockOrderSymbol

    @Environment(\.demoLanguage) private var language

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .center, spacing: 4) {
                Image(symbol.badgeAssetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 10)

                Text(symbol.id)
                    .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                    .foregroundColor(Color("color-text-30"))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Image("stock_order_search")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }

            Text(symbol.localizedName(for: language))
                .modifier(CustomFontModifier(size: 13, font: .medium, lineHeight: 16))
                .foregroundColor(Color("color-text-60"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.leading, 16)
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StockOrderPriceView: View {
    let quote: StockOrderQuote

    var body: some View {
        VStack(alignment: .trailing, spacing: 7) {
            Text(quote.price)
                .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 24))
                .monospacedDigit()
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if let secondaryPrice = quote.secondaryPrice {
                Text(secondaryPrice)
                    .modifier(CustomFontModifier(size: 13, font: .medium, lineHeight: 16))
                    .monospacedDigit()
                    .foregroundColor(Color("color-text-60"))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }
}

private struct StockOrderChangeTile: View {
    let quote: StockOrderQuote

    @Environment(\.demoLanguage) private var language

    var body: some View {
        switch quote.session {
        case .regular:
            regularTile
        case .preMarket, .afterHours:
            extendedHoursTile
        }
    }

    private var regularTile: some View {
        HStack(spacing: 2) {
            StockOrderChangeDirectionIcon(trend: quote.trend, contrast: .white)
                .frame(width: 12, height: 12)

            Text(quote.changePercent.stockOrderUnsignedChange)
                .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 20))
                .monospacedDigit()
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 82, height: 28)
        .background(quote.trend.tileColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }

    private var extendedHoursTile: some View {
        VStack(alignment: .trailing, spacing: 1) {
            HStack(spacing: 2) {
                StockOrderChangeDirectionIcon(trend: quote.trend, contrast: .tinted)
                    .frame(width: 12, height: 12)

                Text(quote.changePercent.stockOrderUnsignedChange)
                    .modifier(CustomFontModifier(size: 16, font: .medium, lineHeight: 20))
                    .monospacedDigit()
                    .foregroundColor(quote.trend.tileColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 82, height: 26)
            .background(quote.trend.tileColor.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(spacing: 4) {
                if let secondaryChange = quote.session.secondaryChange {
                    Text(secondaryChange.stockOrderUnsignedChange)
                        .modifier(CustomFontModifier(size: 13, font: .medium, lineHeight: 16))
                        .monospacedDigit()
                        .foregroundColor(Color("color-text-60"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.01)
                        .allowsTightening(true)
                }

                Spacer(minLength: 4)

                if let localizationKey = quote.session.localizationKey {
                    Text(language.text(localizationKey))
                        .modifier(CustomFontModifier(size: 8, font: .regular, lineHeight: 8))
                        .foregroundColor(Color("color-text-30"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.01)
                        .allowsTightening(true)
                        .padding(.horizontal, 4)
                        .frame(height: 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .stroke(Color("color-separator-20"), lineWidth: 0.5)
                        )
                }
            }
            .frame(width: 82, alignment: .leading)
        }
        .padding(.trailing, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
    }
}

private enum StockOrderChangeIconContrast {
    case white
    case tinted
}

private struct StockOrderChangeDirectionIcon: View {
    let trend: StockOrderQuoteTrend
    let contrast: StockOrderChangeIconContrast

    var body: some View {
        switch (trend, contrast) {
        case (.up, .white):
            Image("watchlistItem_up_white")
                .resizable()
                .scaledToFit()
        case (.down, .white):
            Image("watchlistItem_down_white")
                .resizable()
                .scaledToFit()
        case (.up, .tinted):
            Image("watchlistItem_up_red")
                .resizable()
                .scaledToFit()
        case (.down, .tinted):
            Image("watchlistItem_down_green")
                .resizable()
                .scaledToFit()
        case (.flat, .white):
            Circle()
                .fill(.white)
                .frame(width: 5, height: 5)
        case (.flat, .tinted):
            Circle()
                .fill(Color("color-text-90"))
                .frame(width: 5, height: 5)
        }
    }
}

private struct StockOrderMiniKLine: View {
    let points: [CGFloat]
    let trend: StockOrderQuoteTrend

    var body: some View {
        ZStack {
            StockOrderReferenceLine()
                .stroke(
                    Color("color-separator-20"),
                    style: StrokeStyle(lineWidth: 0.5, dash: [1.5, 2])
                )
                .frame(height: 1)

            MiniLineGraph(dataPoints: points)
                .stroke(
                    trend.lineColor,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                )
        }
    }
}

private struct StockOrderReferenceLine: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

private struct StockOrderMarketNoticeView: View {
    let notice: StockOrderMarketNotice

    @Environment(\.demoLanguage) private var language

    var body: some View {
        HStack(spacing: 4) {
            if notice.showsCASIcon {
                Image("stock_order_associate_info_cas")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
            }

            Text(language.text(notice.titleKey))
                .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                .foregroundColor(Color("color-text-30"))

            Text(language.text(.priceRange))
                .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                .foregroundColor(Color("color-text-60"))

            Text(notice.priceRange)
                .modifier(CustomFontModifier(size: 12, font: .regular, lineHeight: 16))
                .foregroundColor(Color("color-text-30"))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 29)
        .background(Color("color-base-1"))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color("color-separator-10"))
                .frame(height: 0.5)
                .padding(.horizontal, 16)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockOrder.symbolInput.marketNotice")
    }
}

private struct StockOrderChartSnapshot: View {
    var body: some View {
        Image("stock_order_chart_snapshot")
            .resizable()
            .aspectRatio(402.0 / 409.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("Stock chart preview")
            .accessibilityIdentifier("stockOrder.symbolInput.chartSnapshot")
    }
}

enum StockOrderSymbolPreviewData {
    static let upPoints = ChartMockData.miniChart_50_point.normalized
    static let downPoints = ChartMockData.miniChart_30_point.normalized

    static let nvda = StockOrderSymbol(
        id: "NVDA",
        fallbackName: "英伟达",
        localizationID: "wl-us-nvidia",
        market: .us,
        quote: StockOrderQuote(
            price: "233.610",
            changePercent: "6.66%",
            trend: .up,
            miniKPoints: upPoints,
            session: .regular
        ),
        searchAliases: ["nvidia", "英伟达", "nvidia corporation"]
    )

    static let aapl = StockOrderSymbol(
        id: "AAPL",
        fallbackName: "苹果",
        localizationID: "wl-us-apple",
        market: .us,
        quote: StockOrderQuote(
            price: "227.160",
            changePercent: "1.28%",
            trend: .up,
            miniKPoints: upPoints,
            session: .regular
        ),
        searchAliases: ["apple", "苹果", "apple inc"]
    )

    static let hkTencent = StockOrderSymbol(
        id: "00700",
        fallbackName: "腾讯控股",
        localizationID: "wl-hk-tencent",
        market: .hk,
        quote: StockOrderQuote(
            price: "382.400",
            changePercent: "1.18%",
            trend: .up,
            miniKPoints: upPoints,
            session: .regular
        ),
        marketNotice: .closingAuction(priceRange: "600.000-650.000"),
        searchAliases: ["tencent", "腾讯", "tengxun"]
    )

    static let hkTencentCoolingOff = StockOrderSymbol(
        id: "00700",
        fallbackName: "腾讯控股",
        localizationID: "wl-hk-tencent",
        market: .hk,
        quote: hkTencent.quote,
        marketNotice: .volatilityCoolingOff(priceRange: "600.000-650.000"),
        searchAliases: hkTencent.searchAliases
    )

    static let usPreMarket = StockOrderSymbol(
        id: "NVDA",
        fallbackName: "英伟达",
        localizationID: "wl-us-nvidia",
        market: .us,
        quote: StockOrderQuote(
            price: "233.610",
            secondaryPrice: "233.610",
            changePercent: "6.66%",
            trend: .up,
            miniKPoints: upPoints,
            session: .preMarket(change: "+1.20%")
        ),
        searchAliases: nvda.searchAliases
    )

    static let recentSymbols = [hkTencent, nvda, aapl]

    static let searchableSymbols = [
        aapl,
        nvda,
        hkTencent,
        StockOrderSymbol(
            id: "09988",
            fallbackName: "阿里巴巴-W",
            localizationID: "wl-hk-alibaba",
            market: .hk,
            quote: StockOrderQuote(
                price: "118.600",
                changePercent: "2.36%",
                trend: .up,
                miniKPoints: upPoints,
                session: .regular
            ),
            searchAliases: ["alibaba", "阿里巴巴", "ali"]
        )
    ]
}

private struct StockOrderSymbolPreviewHarness: View {
    @State private var selection: StockOrderSymbol?
    @State private var isChartExpanded = false
    @State private var recentSymbols = StockOrderSymbolPreviewData.recentSymbols

    var body: some View {
        VStack(spacing: 16) {
            StockOrderSymbolSelector(
                selection: $selection,
                isChartExpanded: $isChartExpanded,
                recentSymbols: $recentSymbols,
                searchableSymbols: StockOrderSymbolPreviewData.searchableSymbols
            )

            Text(selection?.id ?? "未选择标的")
                .modifier(CustomFontModifier(size: 14, font: .medium, lineHeight: 20))
                .foregroundColor(Color("color-text-60"))
        }
        .background(Color("color-base-1"))
    }
}

struct StockOrderSymbolSelector_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StockOrderSymbolInput(
                symbol: nil,
                isChartExpanded: .constant(false),
                onSearchRequested: {}
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewLayout(.fixed(width: 402, height: 44))
            .previewDisplayName("Empty")

            StockOrderSymbolInput(
                symbol: StockOrderSymbolPreviewData.nvda,
                isChartExpanded: .constant(false),
                onSearchRequested: {}
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewLayout(.fixed(width: 402, height: 76))
            .previewDisplayName("US · Regular")

            StockOrderSymbolInput(
                symbol: StockOrderSymbolPreviewData.usPreMarket,
                isChartExpanded: .constant(false),
                onSearchRequested: {}
            )
            .environment(\.demoLanguage, .english)
            .previewLayout(.fixed(width: 402, height: 76))
            .previewDisplayName("US · Pre-market")

            StockOrderSymbolInput(
                symbol: StockOrderSymbolPreviewData.hkTencent,
                isChartExpanded: .constant(false),
                onSearchRequested: {}
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewLayout(.fixed(width: 402, height: 115))
            .previewDisplayName("HK · CAS")

            StockOrderSymbolInput(
                symbol: StockOrderSymbolPreviewData.hkTencentCoolingOff,
                isChartExpanded: .constant(false),
                onSearchRequested: {}
            )
            .environment(\.demoLanguage, .traditionalChinese)
            .previewLayout(.fixed(width: 402, height: 115))
            .previewDisplayName("HK · VCM")

            StockOrderSymbolInput(
                symbol: StockOrderSymbolPreviewData.nvda,
                isChartExpanded: .constant(true),
                onSearchRequested: {}
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .previewLayout(.fixed(width: 402, height: 491))
            .previewDisplayName("Expanded · Light")

            StockOrderSymbolInput(
                symbol: StockOrderSymbolPreviewData.nvda,
                isChartExpanded: .constant(true),
                onSearchRequested: {}
            )
            .environment(\.demoLanguage, .simplifiedChinese)
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 402, height: 491))
            .previewDisplayName("Expanded · Dark")

            StockOrderSymbolPreviewHarness()
                .environment(\.demoLanguage, .simplifiedChinese)
                .previewLayout(.fixed(width: 402, height: 180))
                .previewDisplayName("Interactive")
        }
    }
}
