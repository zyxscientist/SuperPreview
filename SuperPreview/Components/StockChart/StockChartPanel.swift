import SwiftUI
import UIKit

private enum StockChartSettingsStorage {
    static let defaults: UserDefaults = {
        guard ProcessInfo.processInfo.environment["UITEST_MODE"] == "1" else { return .standard }
        let name = "SuperPreview.StockChart.UITests"
        let defaults = UserDefaults(suiteName: name)!
        if ProcessInfo.processInfo.environment["UITEST_PRESERVE_CHART_SETTINGS"] != "1" {
            defaults.removePersistentDomain(forName: name)
        }
        return defaults
    }()
}

/// The production chart's presentation boundary. Market services are replaced
/// by deterministic fixtures; chart state belongs to each detail-page instance.
struct StockChartPanel: View {
    @Environment(\.demoLanguage) private var language
    @Environment(\.marketColorReversed) private var reversed
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.stockChartTouchScope) private var touchScope
    @State private var period: StockChartPeriod = .intraday
    @AppStorage("stockChart.selected.main", store: StockChartSettingsStorage.defaults) private var selectedMainStorage = "ma"
    @AppStorage("stockChart.selected.sub.intraday", store: StockChartSettingsStorage.defaults) private var selectedMinuteStorage = "volume"
    @AppStorage("stockChart.selected.sub.candle", store: StockChartSettingsStorage.defaults) private var selectedCandleStorage = "volume"
    @AppStorage("stockChart.visible.main", store: StockChartSettingsStorage.defaults) private var visibleMainStorage = "ma,ema,boll"
    @AppStorage("stockChart.visible.sub.intraday", store: StockChartSettingsStorage.defaults) private var visibleMinuteStorage = "volume,macd,kdj,rsi"
    @AppStorage("stockChart.visible.sub.candle", store: StockChartSettingsStorage.defaults) private var visibleCandleStorage = "volume,macd,kdj,rsi"
    @AppStorage("stockChart.indicatorSettings", store: StockChartSettingsStorage.defaults) private var indicatorSettingsStorage = ""
    @AppStorage("stockChart.adjustment", store: StockChartSettingsStorage.defaults) private var adjustmentStorage = "forward"
    @AppStorage("stockChart.annotation.buySellPoint", store: StockChartSettingsStorage.defaults) private var annotationTrades = true
    @AppStorage("stockChart.annotation.currentPrice", store: StockChartSettingsStorage.defaults) private var annotationPrice = true
    @AppStorage("stockChart.annotation.cost", store: StockChartSettingsStorage.defaults) private var annotationCost = true
    @AppStorage("stockChart.annotation.priceAlert", store: StockChartSettingsStorage.defaults) private var annotationAlert = true
    @AppStorage("stockChart.annotation.corporate", store: StockChartSettingsStorage.defaults) private var annotationCorporate = true
    @State private var selection: StockChartCandle?
    @State private var selectedMockOrders: [MockChartOrder] = []
    @State private var pagePresentation: Presentation?
    @State private var expandedPresentation: Presentation?
    @State private var isExpanded = false
    @State private var pageLabelsPresented = false
    @State private var expandedLabelsPresented = false

    private var mainIndicators: [StockChartMainIndicator] {
        get { selectedMainStorage.split(separator: ",").compactMap { StockChartMainIndicator(rawValue: String($0)) } }
        nonmutating set { selectedMainStorage = newValue.map(\.rawValue).joined(separator: ",") }
    }
    private var subIndicators: [StockChartSubIndicator] {
        get { (period.isIntraday ? selectedMinuteStorage : selectedCandleStorage).split(separator: ",").compactMap { StockChartSubIndicator(rawValue: String($0)) } }
        nonmutating set {
            let value = newValue.map(\.rawValue).joined(separator: ",")
            if period.isIntraday { selectedMinuteStorage = value } else { selectedCandleStorage = value }
        }
    }
    private var visibleMainIndicators: [StockChartMainIndicator] {
        get { visibleMainStorage.split(separator: ",").compactMap { StockChartMainIndicator(rawValue: String($0)) } }
        nonmutating set { visibleMainStorage = newValue.map(\.rawValue).joined(separator: ",") }
    }
    private var visibleSubIndicators: [StockChartSubIndicator] {
        get { (period.isIntraday ? visibleMinuteStorage : visibleCandleStorage).split(separator: ",").compactMap { StockChartSubIndicator(rawValue: String($0)) } }
        nonmutating set {
            let value = newValue.map(\.rawValue).joined(separator: ",")
            if period.isIntraday { visibleMinuteStorage = value } else { visibleCandleStorage = value }
        }
    }
    private var indicatorSettings: ChartIndicatorSettings {
        get {
            guard let data = Data(base64Encoded: indicatorSettingsStorage),
                  let value = try? JSONDecoder().decode(ChartIndicatorSettings.self, from: data) else { return ChartIndicatorSettings() }
            return value.normalized
        }
        nonmutating set { if let data = try? JSONEncoder().encode(newValue.normalized) { indicatorSettingsStorage = data.base64EncodedString() } }
    }
    private var adjustment: StockChartAdjustment {
        get { StockChartAdjustment(rawValue: adjustmentStorage) ?? .forward }
        nonmutating set { adjustmentStorage = newValue.rawValue }
    }

    private enum Presentation: Identifiable {
        case settings, trades, mockOrders
        case corporate(StockChartCorporateMarker)
        var id: String {
            switch self {
            case .settings: return "settings"
            case .trades: return "trades"
            case .mockOrders: return "mockOrders"
            case .corporate(let marker): return "corporate-\(marker.id)"
            }
        }
    }

    var body: some View {
        chart(expanded: false)
            .background(StockChartTouchRegion(scope: touchScope))
            .background(Color("color-base1"))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("stockDetail.chart")
            .sheet(item: $pagePresentation) { target in
                presentationContent(target)
            }
            .fullScreenCover(isPresented: $isExpanded, onDismiss: { selection = nil }) {
                expandedChart
                    .background(StockChartModalRegion(scope: touchScope))
                    .sheet(item: $expandedPresentation) { target in
                        presentationContent(target)
                    }
                    .fullScreenCover(isPresented: $expandedLabelsPresented) { labelsPage }
            }
            .fullScreenCover(isPresented: $pageLabelsPresented) { labelsPage }
    }

    private var expandedChart: some View {
        GeometryReader { geometry in
            // The app stays portrait-locked. Rotate a safe-area-sized canvas,
            // so the portrait top/bottom insets become landscape side insets.
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(language.text(.done)) {
                        expandedPresentation = nil
                        isExpanded = false
                    }
                    .accessibilityIdentifier("stockDetail.chart.expanded.close")
                }
                .padding(.horizontal, 12)
                .frame(height: 32)
                ScrollView(.vertical) {
                    chart(expanded: true)
                }
            }
            .frame(width: geometry.size.height, height: geometry.size.width)
            .background(Color("color-base1"))
            .rotationEffect(.degrees(90))
            .frame(width: geometry.size.width, height: geometry.size.height)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("stockDetail.chart.expanded")
        }
        .background(Color("color-base1").ignoresSafeArea())
    }

    @ViewBuilder private func presentationContent(_ target: Presentation) -> some View {
        Group {
            switch target {
            case .settings:
                StockChartSettingsSheet(
                    period: period, language: language,
                    visibleMain: Binding(get: { visibleMainIndicators }, set: { visibleMainIndicators = $0 }),
                    visibleSub: Binding(get: { visibleSubIndicators }, set: { visibleSubIndicators = $0 }),
                    indicatorSettings: Binding(get: { indicatorSettings }, set: { indicatorSettings = $0 }),
                    adjustment: Binding(get: { adjustment }, set: { adjustment = $0 }),
                    onLandscape: {
                        let alreadyExpanded = isExpanded
                        pagePresentation = nil; expandedPresentation = nil
                        if !alreadyExpanded { DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isExpanded = true } }
                    },
                    onLabels: {
                        let inExpanded = isExpanded
                        pagePresentation = nil; expandedPresentation = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            if inExpanded { expandedLabelsPresented = true } else { pageLabelsPresented = true }
                        }
                    }
                )
            case .corporate(let marker):
                StockChartCorporateSheet(marker: marker, language: language, reversed: reversed)
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.height(marker.preferredHeight), .large])
            case .trades:
                NavigationStack {
                    StockChartTrades(showsDetails: false)
                        .padding(.horizontal, 12)
                        .background(Color("color-base1"))
                        .navigationTitle(stockChartText(.transactionDetails, language: language))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { doneButton } }
                }
                .presentationDetents([.large])
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("stockDetail.chart.trades.sheet")
            case .mockOrders:
                mockOrdersSheet
            }
        }
        .background(StockChartModalRegion(scope: touchScope))
    }

    private var labelsPage: some View {
        StockChartAnnotationsPage(language: language,
            bindings: StockChartAnnotationBindings(trades: $annotationTrades, price: $annotationPrice,
                cost: $annotationCost, alert: $annotationAlert, corporate: $annotationCorporate))
            .background(StockChartModalRegion(scope: touchScope))
    }

    private func show(_ target: Presentation, expanded: Bool) {
        if expanded { expandedPresentation = target } else { pagePresentation = target }
    }

    private func chart(expanded: Bool) -> some View {
        VStack(spacing: 0) {
            periodBar(expanded: expanded)
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 12) {
                        ZStack(alignment: .topLeading) {
                            StockChartCanvas(
                                period: period, mainIndicators: mainIndicators.filter { visibleMainIndicators.contains($0) },
                                subIndicators: subIndicators.filter { visibleSubIndicators.contains($0) },
                                indicatorSettings: indicatorSettings, adjustment: adjustment,
                                annotations: StockChartAnnotations(buySellPoint: annotationTrades, currentPrice: annotationPrice,
                                    cost: annotationCost, priceAlert: annotationAlert, corporate: annotationCorporate), reversed: reversed,
                                language: language, colorScheme: colorScheme,
                                onSelection: { selection = $0 },
                                onCorporateTap: { marker in
                                    show(.corporate(marker), expanded: expanded)
                                },
                                onExpand: {
                                    guard !expanded, pagePresentation == nil else { return }
                                    selection = nil
                                    isExpanded = true
                                }
                            )
                            .frame(height: StockChartCanvasView.height(subchartCount: subIndicators.filter { visibleSubIndicators.contains($0) }.count))
                            if let selection {
                                selectionInfo(selection, expanded: expanded)
                            }
                        }
                        if period == .intraday { Color.clear.frame(width: 130) }
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, period == .intraday ? 0 : 12)
                    indicatorBar
                }
                if period == .intraday {
                    StockChartTrades(onDetails: { show(.trades, expanded: expanded) })
                        .frame(width: 130, height: StockChartCanvasView.height(subchartCount: subIndicators.filter { visibleSubIndicators.contains($0) }.count) + 44)
                }
            }
        }
        .onChange(of: period) { _, _ in selection = nil }
        .onChange(of: adjustment) { _, _ in selection = nil }
    }

    private var indicatorBar: some View {
        HStack(spacing: 16) {
            if !period.isIntraday {
                HStack(spacing: 16) {
                    ForEach(visibleMainIndicators, id: \.rawValue) { item in
                        indicatorButton(item.rawValue.uppercased(), selected: mainIndicators.contains(item), id: "main.\(item.rawValue)") {
                            if mainIndicators.contains(item) { mainIndicators.removeAll { $0 == item } }
                            else { mainIndicators.append(item) }
                        }
                    }
                }
                Color("color-grayscale1").frame(width: 1, height: 16)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(visibleSubIndicators, id: \.rawValue) { item in
                        indicatorButton(item == .volume ? "VOL" : item.rawValue.uppercased(), selected: subIndicators.contains(item), id: "sub.\(item.rawValue)") {
                            if subIndicators.contains(item) { subIndicators.removeAll { $0 == item } }
                            else { subIndicators.append(item) }
                        }
                    }
                }
                .frame(height: 20)
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, period == .intraday ? 142 : 16)
        .frame(height: 44)
        .background(Color("color-base1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.chart.indicators")
    }

    private func indicatorButton(_ title: String, selected: Bool, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("PlusJakartaSans-Regular", size: 14))
                .foregroundStyle(Color(selected ? "color-blue1" : "color-text-60"))
                .frame(height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("stockDetail.chart.indicator.\(id)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func periodBar(expanded: Bool) -> some View {
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach([StockChartPeriod.intraday, .fiveDays, .day, .week, .month], id: \.rawValue) { item in
                    Button { period = item } label: {
                        periodLabel(stockChartText(item.text, language: language), selected: period == item)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("stockDetail.chart.period.\(item.rawValue)")
                    .accessibilityAddTraits(period == item ? .isSelected : [])
                    Spacer(minLength: 3)
                }
                Menu {
                    ForEach([StockChartPeriod.minute1, .minute5, .minute15, .minute30, .minute60], id: \.rawValue) { item in
                        Button { period = item } label: {
                            Label(stockChartText(item.text, language: language), systemImage: period == item ? "checkmark" : "")
                        }
                        .accessibilityIdentifier("stockDetail.chart.period.\(item.rawValue)")
                    }
                } label: {
                    periodLabel(stockChartText(period.isMinuteCandle ? period.text : .minute, language: language), selected: period.isMinuteCandle, showsArrow: true)
                }
                .accessibilityIdentifier("stockDetail.chart.period.minutes")
                .accessibilityAddTraits(period.isMinuteCandle ? .isSelected : [])
            }
            .padding(.leading, 15)
            .padding(.trailing, 10)
            Button { show(.settings, expanded: expanded) } label: {
                Image("stock_chart_setting").resizable().frame(width: 20, height: 20)
                    .frame(width: 40, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(stockChartText(.indicatorSettings, language: language))
            .accessibilityIdentifier("stockDetail.chart.settings")
        }
        .frame(height: 32)
        .overlay(alignment: .bottom) { Color("color-separator1").frame(height: 0.5) }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.chart.periodBar")
    }

    private func periodLabel(_ title: String, selected: Bool, showsArrow: Bool = false) -> some View {
        HStack(spacing: 1) {
            Text(title)
                .font(.custom(selected ? "PlusJakartaSans-Medium" : "PlusJakartaSans-Regular", size: 14))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(height: 20)
                .overlay(alignment: .bottom) {
                    if selected {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color("color-blue1"))
                            .frame(height: 2)
                            .offset(y: 6)
                    }
                }
            if showsArrow {
                Image("chart_timeframe_more").resizable().frame(width: 10, height: 16)
            }
        }
        .foregroundStyle(Color(selected ? "color-text1" : "color-text-60"))
        .frame(height: 32)
        .contentShape(Rectangle())
    }

    private var doneButton: some View {
        Button(language.text(.done)) {
            pagePresentation = nil
            expandedPresentation = nil
        }
            .accessibilityIdentifier("stockDetail.chart.settings.done")
    }

    private func selectionInfo(_ candle: StockChartCandle, expanded: Bool) -> some View {
        let data = StockChartMock.adjustedDataset(for: period, adjustment: adjustment)
        let index = data.candles.firstIndex { $0.date == candle.date } ?? 0
        let reference: Double
        if period.isIntraday {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(identifier: "America/New_York")!
            let dayStart = calendar.startOfDay(for: candle.date)
            reference = data.candles[..<index].last(where: { $0.date < dayStart })?.close
                ?? data.candles.first?.open ?? data.referenceClose
        } else {
            reference = index > 0 ? data.candles[index - 1].close : candle.open
        }
        let delta = candle.close - reference
        let changeColor: Color = abs(delta) < 0.0000001
            ? Color("color-text1")
            : MarketColor.resolve(delta > 0 ? "color-red" : "color-green", reversed: reversed)
        let percent = reference != 0 ? delta / reference * 100 : 0
        let averages = period.isIntraday ? StockChartSeriesCache.series(for: data, period: period).averagePrices : []
        let average = averages.indices.contains(index) ? averages[index] : candle.close
        let fields: [(StockChartText, String)] = period.isIntraday
            ? [(.price, price(candle.close)), (.changePercent, String(format: "%+.2f%%", percent)), (.turnover, String(format: "%.0f", candle.close * candle.volume)), (.averagePrice, price(average)), (.change, String(format: "%+.3f", delta)), (.volume, String(format: "%.0f", candle.volume))]
            : [(.open, price(candle.open)), (.high, price(candle.high)), (.changePercent, String(format: "%+.2f%%", percent)), (.close, price(candle.close)), (.low, price(candle.low)), (.change, String(format: "%+.3f", delta))]
        let orders = mockOrders(for: index, candle: candle, count: data.candles.count)
        return VStack(alignment: .leading, spacing: 3) {
            Text(selectionDate(candle.date)).foregroundStyle(Color("color-text3"))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 3) {
                ForEach(fields, id: \.0) { key, value in
                    HStack(spacing: 3) {
                        Text(stockChartText(key, language: language)).foregroundStyle(Color("color-text-60"))
                        Text(value)
                            .foregroundStyle(key == .change || key == .changePercent ? changeColor : Color("color-text1"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if !orders.isEmpty {
                Divider().padding(.vertical, 3)
                HStack {
                    Text(mockText("成交均价@数量", "成交均價@數量", "AVG Price@QTY"))
                        .foregroundStyle(Color("color-text-60"))
                    Spacer(minLength: 4)
                    Button {
                        selectedMockOrders = orders
                        show(.mockOrders, expanded: expanded)
                    } label: {
                        HStack(spacing: 2) {
                            Text("\(mockText("查看订单", "查看訂單", "Details")) (\(orders.count))")
                            Image(systemName: "chevron.right")
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("stockDetail.chart.selection.orders")
                }
                HStack(spacing: 20) {
                    ForEach(orders) { order in
                        HStack(spacing: 3) {
                            Image(order.imageName(reversed: reversed)).resizable().frame(width: 10, height: 13)
                            Text("\(price(order.price))@\(String(format: "%.2f", order.quantity))")
                        }
                    }
                }
                .accessibilityIdentifier("stockDetail.chart.selection.tradeMarks")
            }
        }
        .font(.custom("PlusJakartaSans-Regular", size: 10))
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base1").opacity(0.96))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.chart.selection")
    }

    private struct MockChartOrder: Identifiable {
        let id: Int
        let isBuy: Bool
        let price: Double
        let quantity: Double
        let date: Date

        func imageName(reversed: Bool) -> String {
            if isBuy { return reversed ? "icon_green_buy_point" : "icon_red_buy_point" }
            return reversed ? "icon_red_sell_point" : "icon_green_sell_point"
        }
    }

    private func mockOrders(for index: Int, candle: StockChartCandle, count: Int) -> [MockChartOrder] {
        guard annotationTrades else { return [] }
        let indices = period.isIntraday
            ? [max(0, count - 300), max(0, count - 180), max(0, count - 100)]
            : [max(0, count - 18), max(0, count - 12), max(0, count - 4)]
        guard let marker = indices.firstIndex(of: index) else { return [] }
        let buy = MockChartOrder(id: 0, isBuy: true, price: candle.close * 0.997, quantity: 100, date: candle.date)
        let sell = MockChartOrder(id: 1, isBuy: false, price: candle.close * 1.003, quantity: 50, date: candle.date)
        switch marker {
        case 0: return [buy]
        case 1: return [buy, sell]
        default: return [sell]
        }
    }

    private var mockOrdersSheet: some View {
        NavigationStack {
            List(selectedMockOrders) { order in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(order.imageName(reversed: reversed)).resizable().frame(width: 10, height: 13)
                        Text(order.isBuy ? mockText("买入", "買入", "Buy") : mockText("卖出", "賣出", "Sell"))
                        Spacer()
                        Text(selectionDate(order.date)).foregroundStyle(Color("color-text-60"))
                    }
                    HStack {
                        Text(stockChartText(.price, language: language) + " " + price(order.price))
                        Spacer()
                        Text(mockText("数量", "數量", "Quantity") + " " + String(format: "%.2f", order.quantity))
                    }
                    .font(.system(size: 13))
                }
                .accessibilityIdentifier("stockDetail.chart.mockOrder.\(order.id)")
            }
            .navigationTitle(mockText("模拟订单", "模擬訂單", "Sample Orders"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { doneButton } }
        }
        .presentationDetents([.large])
        .accessibilityIdentifier("stockDetail.chart.mockOrders.sheet")
    }

    private func mockText(_ simplified: String, _ traditional: String, _ english: String) -> String {
        switch language {
        case .simplifiedChinese: return simplified
        case .traditionalChinese: return traditional
        case .english: return english
        }
    }

    private func price(_ value: Double) -> String { String(format: "%.3f", value) }
    private func selectionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.dateFormat = period.isIntraday || period.isMinuteCandle ? "yyyy/MM/dd HH:mm" : "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

private struct StockChartCanvas: UIViewRepresentable {
    let period: StockChartPeriod
    let mainIndicators: [StockChartMainIndicator]
    let subIndicators: [StockChartSubIndicator]
    let indicatorSettings: ChartIndicatorSettings
    let adjustment: StockChartAdjustment
    let annotations: StockChartAnnotations
    let reversed: Bool
    let language: DemoLanguage
    let colorScheme: ColorScheme
    let onSelection: (StockChartCandle?) -> Void
    let onCorporateTap: (StockChartCorporateMarker) -> Void
    let onExpand: () -> Void

    func makeUIView(context: Context) -> StockChartCanvasView { StockChartCanvasView() }
    func updateUIView(_ view: StockChartCanvasView, context: Context) {
        // A configuration reset can clear UIKit's selection. SwiftUI already
        // clears that state on period changes; do not mutate it inside update.
        view.onSelection = nil
        view.onExpand = onExpand
        view.onCorporateTap = onCorporateTap
        view.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        view.configure(dataset: StockChartMock.adjustedDataset(for: period, adjustment: adjustment), period: period,
                       mainIndicators: mainIndicators, subIndicators: subIndicators,
                       reversed: reversed, language: language, indicatorSettings: indicatorSettings, annotations: annotations, adjustment: adjustment)
        view.onSelection = onSelection
    }
}

private extension StockChartPeriod {
    var isMinuteCandle: Bool { rawValue.hasPrefix("minute") }
    var text: StockChartText {
        switch self {
        case .intraday: return .intraday
        case .fiveDays: return .fiveDay
        case .day: return .daily
        case .week: return .weekly
        case .month: return .monthly
        case .minute1: return .minute1
        case .minute5: return .minute5
        case .minute15: return .minute15
        case .minute30: return .minute30
        case .minute60: return .minute60
        }
    }
}

/// Each Scroll session assigns a token only to its current card. Charts in
/// presenting pages and other cards must not block that session's pager.
private struct StockChartTouchScopeKey: EnvironmentKey {
    static let defaultValue: UUID? = nil
}

extension EnvironmentValues {
    var stockChartTouchScope: UUID? {
        get { self[StockChartTouchScopeKey.self] }
        set { self[StockChartTouchScopeKey.self] = newValue }
    }
}

@MainActor enum StockChartTouchRegions {
    private static let chartScopes = NSMapTable<UIView, NSUUID>.weakToStrongObjects()
    private static let pagerScopes = NSMapTable<UIView, NSUUID>.weakToStrongObjects()
    private static let modalScopes = NSMapTable<UIView, NSUUID>.weakToStrongObjects()

    static func setModalScope(_ scope: UUID?, for view: UIView) {
        if let scope { modalScopes.setObject(scope as NSUUID, forKey: view) }
        else { modalScopes.removeObject(forKey: view) }
    }

    static func hasActiveModal(scope: UUID) -> Bool {
        modalScopes.keyEnumerator().allObjects.compactMap { $0 as? UIView }.contains { view in
            modalScopes.object(forKey: view) == (scope as NSUUID) && view.window != nil
        }
    }

    static func setScope(_ scope: UUID?, for view: UIView, allowsPager: Bool) {
        chartScopes.removeObject(forKey: view)
        pagerScopes.removeObject(forKey: view)
        guard let scope else { return }
        (allowsPager ? pagerScopes : chartScopes).setObject(scope as NSUUID, forKey: view)
    }

    private static func matches(_ touch: UITouch, scope: UUID, in table: NSMapTable<UIView, NSUUID>) -> Bool {
        table.keyEnumerator().allObjects.compactMap { $0 as? UIView }.contains { view in
            table.object(forKey: view) == (scope as NSUUID)
                && view.window != nil && view.window === touch.window && !view.isHidden
                && view.bounds.contains(touch.location(in: view))
        }
    }

    static func contains(_ touch: UITouch, scope: UUID) -> Bool {
        // An overlaid control wins over the chart behind it.
        if matches(touch, scope: scope, in: pagerScopes) { return false }
        return matches(touch, scope: scope, in: chartScopes)
    }
}

struct StockChartTouchRegion: UIViewRepresentable {
    let scope: UUID?
    var allowsPager = false

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        StockChartTouchRegions.setScope(scope, for: uiView, allowsPager: allowsPager)
    }
    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        StockChartTouchRegions.setScope(nil, for: uiView, allowsPager: false)
    }
}

/// Mounted only in chart-owned modal content. Its weak registration blocks
/// the window-level Scroll pager until the presentation leaves its window.
private struct StockChartModalRegion: UIViewRepresentable {
    let scope: UUID?
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        StockChartTouchRegions.setModalScope(scope, for: uiView)
    }
    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        StockChartTouchRegions.setModalScope(nil, for: uiView)
    }
}

struct StockChartAnnotations: Hashable {
    var buySellPoint, currentPrice, cost, priceAlert, corporate: Bool
}

private struct StockChartAnnotationBindings {
    var trades, price, cost, alert, corporate: Binding<Bool>
}

private struct StockChartSettingsSheet: View {
    let period: StockChartPeriod
    let language: DemoLanguage
    @Binding var visibleMain: [StockChartMainIndicator]
    @Binding var visibleSub: [StockChartSubIndicator]
    @Binding var indicatorSettings: ChartIndicatorSettings
    @Binding var adjustment: StockChartAdjustment
    let onLandscape, onLabels: () -> Void
    @State private var showingIndicators = false
    @State private var detail: Detail?
    @Environment(\.dismiss) private var dismiss

    private enum Detail: String, Identifiable {
        case ma, ema, boll, macd, kdj, rsi
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if showingIndicators {
                    if !period.isIntraday {
                        StockChartIndicatorSection(title: stockChartText(.mainIndicator, language: language),
                            items: ["ma", "ema", "boll"], selected: Set(visibleMain.map(\.rawValue)),
                            toggle: { name in toggleMain(name) }, open: { detail = Detail(rawValue: $0) })
                            .padding(.bottom, 32)
                    }
                    StockChartIndicatorSection(title: stockChartText(.subIndicator, language: language),
                        items: ["volume", "macd", "kdj", "rsi"], selected: Set(visibleSub.map(\.rawValue)),
                        toggle: { name in toggleSub(name) }, open: { detail = Detail(rawValue: $0) })
                } else {
                    StockChartSettingsEntries(language: language, onLandscape: onLandscape,
                        onIndicators: { showingIndicators = true }, onLabels: onLabels)
                    if period == .day || period == .week || period == .month {
                        StockChartAdjustmentSection(language: language, adjustment: $adjustment)
                            .padding(.top, 32)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 32)
        }
        .background(Color("color-base1"))
        .presentationDragIndicator(.visible)
        .presentationDetents(showingIndicators ? [.height(period.isIntraday ? 350 : 590), .large] : [period == .day || period == .week || period == .month ? .height(468) : .height(204)])
        .accessibilityIdentifier(showingIndicators ? "stockDetail.chart.indicators.sheet" : "stockDetail.chart.settings.sheet")
        .accessibilityAction(.escape) { dismiss() }
        .fullScreenCover(item: $detail) { item in
            StockChartParameterPage(name: item.rawValue, language: language, settings: $indicatorSettings)
        }
    }

    private func toggleMain(_ name: String) {
        guard let item = StockChartMainIndicator(rawValue: name) else { return }
        if visibleMain.contains(item) { visibleMain.removeAll { $0 == item } }
        else { visibleMain = [StockChartMainIndicator.ma, .ema, .boll].filter { visibleMain.contains($0) || $0 == item } }
    }
    private func toggleSub(_ name: String) {
        guard let item = StockChartSubIndicator(rawValue: name) else { return }
        if visibleSub.contains(item) { visibleSub.removeAll { $0 == item } }
        else { visibleSub = StockChartSubIndicator.allCases.filter { visibleSub.contains($0) || $0 == item } }
    }
}

private struct StockChartSettingsEntries: View {
    let language: DemoLanguage
    let onLandscape, onIndicators, onLabels: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                entry(.landscapeMode, image: "landscape_mode", id: "landscape", action: onLandscape)
                entry(.indicatorSettings, image: "indicator_setting", id: "indicators", action: onIndicators)
            }
            HStack(spacing: 16) {
                entry(.chartAnnotations, image: "chart_annotations", id: "labels", action: onLabels)
                Color.clear.frame(maxWidth: .infinity, minHeight: 56)
            }
        }
    }
    private func entry(_ title: StockChartText, image: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(image).resizable().scaledToFit().frame(width: 20, height: 20)
                Text(stockChartText(title, language: language)).font(.custom("PlusJakartaSans-Regular", size: 16)).lineLimit(1).minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .foregroundStyle(Color("color-text1"))
            .padding(.horizontal, 16).frame(maxWidth: .infinity).frame(height: 56)
            .background(Color("color-grayscale1"), in: RoundedRectangle(cornerRadius: 8))
        }.buttonStyle(.plain).accessibilityIdentifier("stockDetail.chart.settings.\(id)")
    }
}

private struct StockChartAdjustmentSection: View {
    let language: DemoLanguage
    @Binding var adjustment: StockChartAdjustment
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(stockChartText(.priceAdjustment, language: language)).font(.custom("PlusJakartaSans-Medium", size: 18)).frame(height: 28)
            ForEach([StockChartAdjustment.forward, .backward, .none], id: \.self) { option in
                Button { adjustment = option } label: {
                    HStack {
                        Text(stockChartText(option == .forward ? .adjustedForward : option == .backward ? .adjustedBackward : .unadjusted, language: language))
                        Spacer()
                        if adjustment == option { Image(systemName: "checkmark").font(.system(size: 16, weight: .medium)) }
                    }
                    .font(.custom("PlusJakartaSans-Regular", size: 16))
                    .foregroundStyle(Color("color-text1"))
                    .padding(.horizontal, 16).frame(height: 56)
                    .background(Color("color-grayscale1"), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(adjustment == option ? Color("color-text-60") : .clear, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("stockDetail.chart.adjustment.\(option == .forward ? "forward" : option == .backward ? "backward" : "none")")
                .accessibilityAddTraits(adjustment == option ? .isSelected : [])
            }
        }.foregroundStyle(Color("color-text1"))
    }
}

private struct StockChartIndicatorSection: View {
    let title: String
    let items: [String]
    let selected: Set<String>
    let toggle, open: (String) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.custom("PlusJakartaSans-Medium", size: 18)).frame(height: 28)
            VStack(spacing: 16) {
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 0) {
                        Button { toggle(item) } label: {
                            HStack(spacing: 16) {
                                Image(systemName: selected.contains(item) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 24)).foregroundStyle(Color(selected.contains(item) ? "color-blue1" : "color-text-60"))
                                Text(item == "volume" ? "VOL" : item.uppercased())
                                    .font(.custom("PlusJakartaSans-Regular", size: 16)).foregroundStyle(Color("color-text1"))
                                Spacer(minLength: 0)
                            }.padding(.leading, 16).frame(maxWidth: .infinity).frame(height: 48).contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("stockDetail.chart.\(items.contains("volume") ? "sub" : "main").\(item)")
                        .accessibilityValue(selected.contains(item) ? "1" : "0")
                        .accessibilityAddTraits(selected.contains(item) ? .isSelected : [])
                        if item != "volume" {
                            Button { open(item) } label: {
                                Image(systemName: "chevron.right").font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color("color-text-60"))
                                    .frame(width: 70, height: 48).contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityLabel(item.uppercased()).accessibilityIdentifier("stockDetail.chart.parameter.\(item)")
                        }
                    }.background(Color("color-grayscale1"), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }.foregroundStyle(Color("color-text1"))
    }
}

private struct StockChartParameterPage: View {
    let name: String
    let language: DemoLanguage
    @Binding var settings: ChartIndicatorSettings
    @Environment(\.dismiss) private var dismiss
    @State private var values: [String]
    @State private var enabled: [Bool]
    @State private var confirmingReset = false

    init(name: String, language: DemoLanguage, settings: Binding<ChartIndicatorSettings>) {
        self.name = name
        self.language = language
        self._settings = settings
        let initial = Self.fields(name: name, settings: settings.wrappedValue)
        self._values = State(initialValue: initial.map { Self.display($0.value) })
        self._enabled = State(initialValue: initial.map(\.enabled))
    }

    private struct Field {
        var title: String
        var value: Double
        var range: ClosedRange<Double>
        var step: Double = 1
        var selectable = false
        var enabled = true
    }

    var body: some View {
        let fields = Self.fields(name: name, settings: settings)
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if fields.first?.selectable == true {
                            Text(stockChartText(.movingAveragePeriod, language: language))
                                .font(.custom("PlusJakartaSans-Medium", size: 16)).frame(height: 48)
                        } else { Color.clear.frame(height: 12) }
                        ForEach(fields.indices, id: \.self) { index in
                            parameterRow(fields[index], index: index)
                        }
                        Text(tip(fields)).font(.custom("PlusJakartaSans-Regular", size: 12))
                            .foregroundStyle(Color("color-text-60")).padding(.top, 12)
                    }.padding(.horizontal, 16)
                }
                Button { confirmingReset = true } label: {
                    Text(stockChartText(.resetParameters, language: language))
                        .font(.custom("PlusJakartaSans-Medium", size: 16))
                        .foregroundStyle(Color("color-text1"))
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(Color("color-grayscale1"), in: RoundedRectangle(cornerRadius: 5))
                }.buttonStyle(.plain).padding(16).accessibilityIdentifier("stockDetail.chart.parameter.reset")
            }
            .background(Color("color-base1"))
            .navigationTitle(name.uppercased() + (language == .english ? " " : "") + stockChartText(.parameterSettings, language: language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left") }
                        .accessibilityIdentifier("stockDetail.chart.parameter.back")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(stockChartText(.save, language: language)) { commit(fields); dismiss() }
                        .accessibilityIdentifier("stockDetail.chart.parameter.save")
                }
            }
            .alert(stockChartText(.confirmReset, language: language), isPresented: $confirmingReset) {
                Button(stockChartText(.cancel, language: language), role: .cancel) {}
                Button(stockChartText(.confirm, language: language)) {
                    let defaults = Self.fields(name: name, settings: ChartIndicatorSettings())
                    values = defaults.map { Self.display($0.value) }
                    enabled = defaults.map(\.enabled)
                    commit(defaults)
                }
            }
        }
    }

    private func parameterRow(_ field: Field, index: Int) -> some View {
        HStack(spacing: 12) {
            if field.selectable {
                Button { enabled[index].toggle() } label: {
                    Image(systemName: enabled[index] ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24)).foregroundStyle(Color(enabled[index] ? "color-blue1" : "color-text-60"))
                }.buttonStyle(.plain).accessibilityIdentifier("stockDetail.chart.parameter.enabled.\(index)")
                    .accessibilityValue(enabled[index] ? "1" : "0")
                    .accessibilityAddTraits(enabled[index] ? .isSelected : [])
            }
            Text(localizedTitle(field.title)).font(.custom("PlusJakartaSans-Regular", size: 16)).foregroundStyle(Color("color-text1"))
            Spacer(minLength: 4)
            HStack(spacing: 0) {
                Button { step(index, field: field, direction: -1) } label: { Image(systemName: "minus").frame(width: 32, height: 32) }
                    .accessibilityIdentifier("stockDetail.chart.parameter.decrement.\(index)")
                TextField("", text: $values[index]).keyboardType(field.step < 1 ? .decimalPad : .numberPad)
                    .multilineTextAlignment(.center).font(.custom("PlusJakartaSans-Regular", size: 16)).frame(width: 48)
                    .accessibilityIdentifier("stockDetail.chart.parameter.value.\(index)")
                Button { step(index, field: field, direction: 1) } label: { Image(systemName: "plus").frame(width: 32, height: 32) }
                    .accessibilityIdentifier("stockDetail.chart.parameter.increment.\(index)")
            }.buttonStyle(.plain).foregroundStyle(Color("color-text1"))
                .background(Color("color-grayscale1"), in: RoundedRectangle(cornerRadius: 4))
        }.frame(height: 56)
    }

    private func step(_ index: Int, field: Field, direction: Double) {
        let current = Double(values[index]) ?? field.value
        let result = min(field.range.upperBound, max(field.range.lowerBound, current + field.step * direction))
        values[index] = Self.display((result / field.step).rounded() * field.step)
    }
    private func tip(_ fields: [Field]) -> String {
        fields.map { "\(localizedTitle($0.title)): \(Self.display($0.range.lowerBound)) - \(Self.display($0.range.upperBound))" }.joined(separator: "\n")
    }
    private func localizedTitle(_ raw: String) -> String {
        guard let key = StockChartText(rawValue: raw) else { return raw }
        return stockChartText(key, language: language)
    }
    private static func display(_ number: Double) -> String {
        if number.rounded() == number { return String(Int(number)) }
        return String(format: "%.1f", number)
    }
    private static func fields(name: String, settings: ChartIndicatorSettings) -> [Field] {
        switch name {
        case "ma", "ema", "rsi":
            let lines = name == "ma" ? settings.ma : name == "ema" ? settings.ema : settings.rsi
            let range: ClosedRange<Double> = name == "ma" ? 1...250 : name == "ema" ? 2...250 : 1...100
            return lines.enumerated().map { Field(title: "\(name.uppercased())\($0.offset + 1)", value: Double($0.element.period), range: range, selectable: true, enabled: $0.element.isEnabled) }
        case "boll": return [Field(title: "周期", value: Double(settings.bollPeriod), range: 1...100), Field(title: "标准差倍数", value: settings.bollStandardDeviations, range: 0.1...5, step: 0.1)]
        case "macd": return [Field(title: "快线周期", value: Double(settings.macdFast), range: 2...100), Field(title: "慢线周期", value: Double(settings.macdSlow), range: 2...100), Field(title: "信号线周期", value: Double(settings.macdSignal), range: 2...100)]
        default: return [Field(title: "计算周期", value: Double(settings.kdjPeriod), range: 2...100), Field(title: "移动平均周期1", value: Double(settings.kdjKSmoothing), range: 1...50), Field(title: "移动平均周期2", value: Double(settings.kdjDSmoothing), range: 1...50)]
        }
    }
    private func commit(_ fields: [Field]) {
        let parsed = fields.indices.map { index -> Double in
            let value = Double(values[index]) ?? fields[index].value
            return min(fields[index].range.upperBound, max(fields[index].range.lowerBound, (value / fields[index].step).rounded() * fields[index].step))
        }
        switch name {
        case "ma": settings.ma = parsed.indices.map { ChartIndicatorLine(period: Int(parsed[$0]), isEnabled: enabled[$0]) }
        case "ema": settings.ema = parsed.indices.map { ChartIndicatorLine(period: Int(parsed[$0]), isEnabled: enabled[$0]) }
        case "rsi": settings.rsi = parsed.indices.map { ChartIndicatorLine(period: Int(parsed[$0]), isEnabled: enabled[$0]) }
        case "boll": settings.bollPeriod = Int(parsed[0]); settings.bollStandardDeviations = parsed[1]
        case "macd": settings.macdFast = Int(parsed[0]); settings.macdSlow = Int(parsed[1]); settings.macdSignal = Int(parsed[2])
        case "kdj": settings.kdjPeriod = Int(parsed[0]); settings.kdjKSmoothing = Int(parsed[1]); settings.kdjDSmoothing = Int(parsed[2])
        default: break
        }
    }
}

private struct StockChartAnnotationsPage: View {
    let language: DemoLanguage
    let bindings: StockChartAnnotationBindings
    @Environment(\.dismiss) private var dismiss
    private var suffix: String { language == .simplifiedChinese ? "cn" : language == .traditionalChinese ? "hk" : "en" }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ZStack {
                        Image("annotations_K").resizable()
                        if bindings.trades.wrappedValue { Image("annotations_trade").resizable() }
                        if bindings.price.wrappedValue { Image("annotations_price_\(suffix)").resizable() }
                        if bindings.cost.wrappedValue { Image("annotations_cost_\(suffix)").resizable() }
                        if bindings.alert.wrappedValue { Image("annotations_alert_\(suffix)").resizable() }
                        if bindings.corporate.wrappedValue { Image("annotations_corporate").resizable() }
                    }.aspectRatio(370 / 170, contentMode: .fit).padding(.horizontal, 16).padding(.vertical, 21)
                    row(.tradeMarks, binding: bindings.trades, id: "buySellPoint", icon: "arrow.up.arrow.down")
                    row(.currentPriceLine, binding: bindings.price, id: "currentPrice", icon: "minus")
                    row(.positionCostLine, binding: bindings.cost, id: "cost", icon: "minus")
                    row(.priceAlertLine, binding: bindings.alert, id: "priceAlert", icon: "minus")
                    row(.corporateAction, binding: bindings.corporate, id: "corporate", icon: "calendar")
                }.padding(.bottom, 16)
            }
            .background(Color("color-base1"))
            .navigationTitle(stockChartText(.chartAnnotations, language: language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "chevron.left") }.accessibilityIdentifier("stockDetail.chart.labels.back")
            } }
        }
    }
    private func row(_ text: StockChartText, binding: Binding<Bool>, id: String, icon: String) -> some View {
        Toggle(isOn: binding) {
            HStack(spacing: 12) {
                Image(systemName: icon).frame(width: 24)
                Text(stockChartText(text, language: language)).font(.custom("PlusJakartaSans-Regular", size: 16))
            }.foregroundStyle(Color("color-text1"))
        }
        .tint(Color("color-blue1"))
        .padding(.horizontal, 16).frame(height: 56)
        .background(Color("color-grayscale1"), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .accessibilityIdentifier("stockDetail.chart.labels.\(id)")
    }
}

// Offline AAPL events, sourced from Apple earnings releases and dividend history.
// Ex-dividend dates are cross-checked against published market dividend histories.
struct StockChartCorporateEarning: Identifiable {
    let id: String
    let date: Date
    let period: String
    // nil means the public reference did not provide the app's server colorType.
    let colorType: Int?
    let defaultCurrency: String
    let values: [String: StockChartCorporateEarningValues]
}

struct StockChartCorporateEarningValues {
    let eps: String?
    let epsYoY: Double?
    let revenue: String?
    let revenueYoY: Double?
}

struct StockChartCorporateDividend: Identifiable {
    let id: String
    let date: Date
    let amount: String
    let recordDate: Date
    let payDate: Date
}

struct StockChartCorporateMarker: Identifiable {
    let candleIndex: Int
    let earnings: [StockChartCorporateEarning]
    let dividends: [StockChartCorporateDividend]
    var id: Int { candleIndex }
    var colorType: Int? { earnings.first?.colorType }
    var preferredHeight: CGFloat {
        let header: CGFloat = earnings.isEmpty || dividends.isEmpty ? 92 : 134
        return min(UIScreen.main.bounds.height - 120,
                   header + max(CGFloat(earnings.count) * 188, CGFloat(dividends.count) * 180) + 16)
    }
}

enum StockChartCorporateMock {
    private static let events: (earnings: [StockChartCorporateEarning], dividends: [StockChartCorporateDividend]) = {
        // Revenue is the one-decimal-billion figure in Apple's press releases.
        // The return uses only the matching quarter present in this fixture.
        let earningsData: [(date: String, year: Int, quarter: Int, eps: Double?, revenue: Double?)] = [
            ("2024-10-31", 2024, 4, 0.97, 94.9),
            ("2025-01-30", 2025, 1, 2.40, 124.3),
            ("2025-05-01", 2025, 2, 1.65, 95.4),
            ("2025-07-31", 2025, 3, 1.57, 94.0),
            ("2025-10-30", 2025, 4, 1.85, 102.5),
            ("2026-01-29", 2026, 1, 2.84, 143.8),
            ("2026-04-30", 2026, 2, 2.01, 111.2),
            ("2026-07-30", 2026, 3, 2.02, 109.4),
            ("2026-11-02", 2026, 4, 2.10, 114.5)
        ]
        let dividendData: [(ex: String, record: String, pay: String, amount: Double)] = [
            ("2024-11-08", "2024-11-11", "2024-11-14", 0.25),
            ("2025-02-10", "2025-02-10", "2025-02-13", 0.25),
            ("2025-05-12", "2025-05-12", "2025-05-15", 0.26),
            ("2025-08-11", "2025-08-11", "2025-08-14", 0.26),
            ("2025-11-10", "2025-11-10", "2025-11-13", 0.26),
            ("2026-02-09", "2026-02-09", "2026-02-12", 0.26),
            ("2026-05-11", "2026-05-11", "2026-05-14", 0.27),
            ("2026-08-10", "2026-08-10", "2026-08-13", 0.27),
            ("2026-11-12", "2026-11-12", "2026-11-16", 0.27)
        ]
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "America/New_York")!
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        func date(_ string: String) -> Date { formatter.date(from: string)! }
        func change(_ value: Double?, _ previous: Double?) -> Double? {
            guard let value, let previous, previous != 0 else { return nil }
            return (value / previous - 1) * 100
        }
        let earnings = earningsData.map { item in
            let prior = earningsData.first { $0.year == item.year - 1 && $0.quarter == item.quarter }
            let values = StockChartCorporateEarningValues(
                eps: item.eps.map { String(format: "%.2f", $0) },
                epsYoY: change(item.eps, prior?.eps),
                revenue: item.revenue.map { String(format: "%.1fB", $0) },
                revenueYoY: change(item.revenue, prior?.revenue))
            // No analyst estimate is available to support an earnings-surprise color.
            return StockChartCorporateEarning(id: "earning-\(item.date)", date: date(item.date),
                period: "\(item.year)/Q\(item.quarter)", colorType: nil, defaultCurrency: "USD",
                values: ["USD": values])
        }
        let dividends = dividendData.map { item in
            StockChartCorporateDividend(id: "dividend-\(item.ex)", date: date(item.ex),
                amount: String(format: "%.2f USD", item.amount),
                recordDate: date(item.record), payDate: date(item.pay))
        }
        return (earnings, dividends)
    }()

    static func markers(for period: StockChartPeriod, candles: [StockChartCandle]) -> [StockChartCorporateMarker] {
        guard [.day, .week, .month].contains(period) else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        let component: Calendar.Component = period == .day ? .day : (period == .week ? .weekOfYear : .month)
        guard let lastCandle = candles.last,
              let lastDay = calendar.dateInterval(of: .day, for: lastCandle.date) else { return [] }
        return candles.enumerated().compactMap { index, candle in
            guard let interval = calendar.dateInterval(of: component, for: candle.date) else { return nil }
            let earnings = events.earnings.filter { interval.contains($0.date) && $0.date < lastDay.end }.sorted { $0.date > $1.date }
            let dividends = events.dividends.filter { interval.contains($0.date) && $0.date < lastDay.end }.sorted { $0.date > $1.date }
            guard !earnings.isEmpty || !dividends.isEmpty else { return nil }
            return StockChartCorporateMarker(candleIndex: index, earnings: earnings, dividends: dividends)
        }
    }
}

private struct StockChartCorporateSheet: View {
    let marker: StockChartCorporateMarker
    let language: DemoLanguage
    let reversed: Bool
    @State private var showsEarnings: Bool
    @State private var currency: String

    init(marker: StockChartCorporateMarker, language: DemoLanguage, reversed: Bool) {
        self.marker = marker
        self.language = language
        self.reversed = reversed
        _showsEarnings = State(initialValue: !marker.earnings.isEmpty)
        _currency = State(initialValue: marker.earnings.first?.defaultCurrency ?? "USD")
    }

    private func text(_ simplified: String, _ traditional: String, _ english: String) -> String {
        switch language {
        case .simplifiedChinese: return simplified
        case .traditionalChinese: return traditional
        case .english: return english
        }
    }

    private var earningsTitle: String { text("业绩公布", "業績公布", "Earnings Release") }
    private var dividendsTitle: String { text("分红派息", "分紅派息", "Dividend") }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !marker.earnings.isEmpty && !marker.dividends.isEmpty {
                HStack(spacing: 24) {
                    tab(earningsTitle, selected: showsEarnings) { showsEarnings = true }
                    tab(dividendsTitle, selected: !showsEarnings) { showsEarnings = false }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 28)
            }
            HStack {
                Text(showsEarnings ? earningsTitle : dividendsTitle)
                    .font(.custom("PlusJakartaSans-Medium", size: 18))
                Spacer()
                if showsEarnings {
                    Menu {
                        ForEach(["HKD", "USD", "CNY"], id: \.self) { value in
                            Button(value) { currency = value }
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text((currency == marker.earnings.first?.defaultCurrency
                                  ? text("财报币种：", "財報幣種：", "Currency: ")
                                  : text("币种：", "幣種：", "Currency: ")) + currency)
                            Image(systemName: "chevron.down").font(.system(size: 9))
                        }
                        .font(.custom("PlusJakartaSans-Regular", size: 14))
                        .foregroundStyle(Color("color-text-60"))
                    }
                    .accessibilityIdentifier("stockDetail.chart.corporate.currency")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, marker.earnings.isEmpty || marker.dividends.isEmpty ? 32 : 18)
            .padding(.bottom, 16)
            ScrollView {
                VStack(spacing: 16) {
                    if showsEarnings {
                        ForEach(marker.earnings) { earning in earningsCard(earning) }
                    } else {
                        ForEach(marker.dividends) { dividend in dividendCard(dividend) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .foregroundStyle(Color("color-text1"))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color("color-base1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.chart.corporate.sheet")
    }

    private func tab(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button { UIImpactFeedbackGenerator(style: .medium).impactOccurred(); action() } label: {
            Text(label).font(.custom(selected ? "PlusJakartaSans-Medium" : "PlusJakartaSans-Regular", size: 14))
                .foregroundStyle(Color(selected ? "color-blue1" : "color-text-60"))
                .padding(.bottom, 8)
                .overlay(alignment: .bottom) { if selected { Color("color-blue1").frame(height: 2) } }
        }.buttonStyle(.plain)
    }

    private func earningsCard(_ earning: StockChartCorporateEarning) -> some View {
        let values = earning.values[currency]
        return VStack(alignment: .leading, spacing: 12) {
            Text(earning.period).font(.custom("PlusJakartaSans-Medium", size: 16))
            VStack(spacing: 0) {
                metricRow(text("项目", "項目", "Item"), text("本期", "本期", "Current Period"), text("同比", "同比", "YoY"), header: true)
                VStack(spacing: 12) {
                    metricRow(text("每股收益", "每股收益", "EPS"), values?.eps ?? "--", percent(values?.epsYoY), change: values?.epsYoY)
                    metricRow(text("总营收", "總營收", "Total Revenue"), values?.revenue ?? "--", percent(values?.revenueYoY, approximate: true), change: values?.revenueYoY)
                }.padding(.vertical, 16)
            }
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("color-separator1"), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func metricRow(_ title: String, _ current: String, _ yoy: String, header: Bool = false, change: Double? = nil) -> some View {
        HStack(spacing: 4) {
            Text(title).frame(maxWidth: .infinity, alignment: .leading)
            Text(current).frame(maxWidth: .infinity, alignment: .trailing)
            Text(yoy).foregroundStyle(changeColor(change)).frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.custom(header ? "PlusJakartaSans-Regular" : "PlusJakartaSans-Medium", size: header ? 14 : 16))
        .foregroundStyle(Color(header ? "color-text-60" : "color-text1"))
        .padding(.horizontal, 12)
        .frame(height: header ? 44 : 24)
        .background(header ? Color("color-grayscale1") : .clear)
    }

    private func dividendCard(_ dividend: StockChartCorporateDividend) -> some View {
        VStack(spacing: 0) {
            Text(dividend.amount).font(.custom("PlusJakartaSans-Medium", size: 16))
                .frame(maxWidth: .infinity, alignment: .leading).padding(12).background(Color("color-grayscale1"))
            VStack(spacing: 12) {
                dividendRow(text("除权除息日", "除權除息日", "Ex-Date"), dividend.date)
                dividendRow(text("股权登记日", "股權登記日", "Record Date"), dividend.recordDate)
                dividendRow(text("派息日", "派息日", "Payment Date"), dividend.payDate)
            }.padding(16)
        }
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color("color-separator1"), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func dividendRow(_ label: String, _ date: Date) -> some View {
        HStack { Text(label); Spacer(); Text(Self.dateFormatter.string(from: date)) }
            .font(.custom("PlusJakartaSans-Regular", size: 14))
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "America/New_York")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()

    private func percent(_ value: Double?, approximate: Bool = false) -> String {
        value.map { (approximate ? "≈" : "") + String(format: "%+.2f%%", $0) } ?? "--"
    }
    private func changeColor(_ value: Double?) -> Color {
        guard let value, value != 0 else { return Color("color-text1") }
        return MarketColor.resolve(value > 0 ? "color-red" : "color-green", reversed: reversed)
    }
}
