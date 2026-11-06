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

    private enum Presentation: String, Identifiable {
        case settings, trades
        var id: Self { self }
    }

    var body: some View {
        chart(expanded: false)
            .background(StockChartTouchRegion(scope: touchScope))
            .background(Color("color-base-1"))
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
            .background(Color("color-base-1"))
            .rotationEffect(.degrees(90))
            .frame(width: geometry.size.width, height: geometry.size.height)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("stockDetail.chart.expanded")
        }
        .background(Color("color-base-1").ignoresSafeArea())
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
            case .trades:
                NavigationStack {
                    StockChartTrades(showsDetails: false)
                        .padding(.horizontal, 12)
                        .background(Color("color-base-1"))
                        .navigationTitle(stockChartText(.transactionDetails, language: language))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { doneButton } }
                }
                .presentationDetents([.large])
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("stockDetail.chart.trades.sheet")
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
                                onExpand: {
                                    guard !expanded, pagePresentation == nil else { return }
                                    selection = nil
                                    isExpanded = true
                                }
                            )
                            .frame(height: StockChartCanvasView.height(subchartCount: subIndicators.filter { visibleSubIndicators.contains($0) }.count))
                            if let selection {
                                selectionInfo(selection)
                                    .allowsHitTesting(false)
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
                Color("color-scale-1").frame(width: 1, height: 16)
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
        .background(Color("color-base-1"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("stockDetail.chart.indicators")
    }

    private func indicatorButton(_ title: String, selected: Bool, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.custom("PlusJakartaSans-Regular", size: 14))
                .foregroundStyle(Color(selected ? "color-brand-blue" : "color-text-60"))
                .frame(height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("stockDetail.chart.indicator.\(id)")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func periodBar(expanded: Bool) -> some View {
        HStack(spacing: 0) {
            ForEach([StockChartPeriod.intraday, .fiveDays, .day, .week, .month], id: \.rawValue) { item in
                Button { period = item } label: {
                    periodLabel(stockChartText(item.text, language: language), selected: period == item)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("stockDetail.chart.period.\(item.rawValue)")
                .accessibilityAddTraits(period == item ? .isSelected : [])
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
            Button { show(.settings, expanded: expanded) } label: {
                Image("stock_chart_setting").resizable().frame(width: 20, height: 20)
                    .frame(width: 40, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(stockChartText(.indicatorSettings, language: language))
            .accessibilityIdentifier("stockDetail.chart.settings")
        }
        .padding(.leading, 10)
        .padding(.trailing, 12)
        .frame(height: 32)
        .overlay(alignment: .bottom) { Color("color-separator-10").frame(height: 0.5) }
    }

    private func periodLabel(_ title: String, selected: Bool, showsArrow: Bool = false) -> some View {
        HStack(spacing: 2) {
            Text(title)
                .font(.custom(selected ? "PlusJakartaSans-Medium" : "PlusJakartaSans-Regular", size: 14))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if showsArrow {
                Image(systemName: "chevron.down").font(.system(size: 7, weight: .semibold))
            }
        }
        .foregroundStyle(Color(selected ? "color-brand-blue" : "color-text-90"))
        .frame(maxWidth: .infinity)
        .frame(height: 32)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if selected { Color("color-brand-blue").frame(width: 16, height: 2) }
        }
    }

    private var doneButton: some View {
        Button(language.text(.done)) {
            pagePresentation = nil
            expandedPresentation = nil
        }
            .accessibilityIdentifier("stockDetail.chart.settings.done")
    }

    private func selectionInfo(_ candle: StockChartCandle) -> some View {
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
            ? Color("color-text-30")
            : MarketColor.resolve(delta > 0 ? "color-utility3-red" : "color-utility3-green", reversed: reversed)
        let percent = reference != 0 ? delta / reference * 100 : 0
        let averages = period.isIntraday ? StockChartSeriesCache.series(for: data, period: period).averagePrices : []
        let average = averages.indices.contains(index) ? averages[index] : candle.close
        let fields: [(StockChartText, String)] = period.isIntraday
            ? [(.price, price(candle.close)), (.changePercent, String(format: "%+.2f%%", percent)), (.turnover, String(format: "%.0f", candle.close * candle.volume)), (.averagePrice, price(average)), (.change, String(format: "%+.3f", delta)), (.volume, String(format: "%.0f", candle.volume))]
            : [(.open, price(candle.open)), (.high, price(candle.high)), (.changePercent, String(format: "%+.2f%%", percent)), (.close, price(candle.close)), (.low, price(candle.low)), (.change, String(format: "%+.3f", delta))]
        return VStack(alignment: .leading, spacing: 3) {
            Text(selectionDate(candle.date)).foregroundStyle(Color("color-text-90"))
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 3) {
                ForEach(fields, id: \.0) { key, value in
                    HStack(spacing: 3) {
                        Text(stockChartText(key, language: language)).foregroundStyle(Color("color-text-60"))
                        Text(value)
                            .foregroundStyle(key == .change || key == .changePercent ? changeColor : Color("color-text-30"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .font(.custom("PlusJakartaSans-Regular", size: 10))
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color("color-base-1").opacity(0.96))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stockDetail.chart.selection")
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
    let onExpand: () -> Void

    func makeUIView(context: Context) -> StockChartCanvasView { StockChartCanvasView() }
    func updateUIView(_ view: StockChartCanvasView, context: Context) {
        // A configuration reset can clear UIKit's selection. SwiftUI already
        // clears that state on period changes; do not mutate it inside update.
        view.onSelection = nil
        view.onExpand = onExpand
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
        .background(Color("color-base-1"))
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
            .foregroundStyle(Color("color-text-30"))
            .padding(.horizontal, 16).frame(maxWidth: .infinity).frame(height: 56)
            .background(Color("color-scale-1"), in: RoundedRectangle(cornerRadius: 8))
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
                    .foregroundStyle(Color("color-text-30"))
                    .padding(.horizontal, 16).frame(height: 56)
                    .background(Color("color-scale-1"), in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(adjustment == option ? Color("color-text-60") : .clear, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("stockDetail.chart.adjustment.\(option == .forward ? "forward" : option == .backward ? "backward" : "none")")
                .accessibilityAddTraits(adjustment == option ? .isSelected : [])
            }
        }.foregroundStyle(Color("color-text-30"))
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
                                    .font(.system(size: 24)).foregroundStyle(Color(selected.contains(item) ? "color-brand-blue" : "color-text-60"))
                                Text(item == "volume" ? "VOL" : item.uppercased())
                                    .font(.custom("PlusJakartaSans-Regular", size: 16)).foregroundStyle(Color("color-text-30"))
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
                    }.background(Color("color-scale-1"), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }.foregroundStyle(Color("color-text-30"))
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
                        .foregroundStyle(Color("color-text-30"))
                        .frame(maxWidth: .infinity).frame(height: 44)
                        .background(Color("color-scale-1"), in: RoundedRectangle(cornerRadius: 5))
                }.buttonStyle(.plain).padding(16).accessibilityIdentifier("stockDetail.chart.parameter.reset")
            }
            .background(Color("color-base-1"))
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
                        .font(.system(size: 24)).foregroundStyle(Color(enabled[index] ? "color-brand-blue" : "color-text-60"))
                }.buttonStyle(.plain).accessibilityIdentifier("stockDetail.chart.parameter.enabled.\(index)")
                    .accessibilityValue(enabled[index] ? "1" : "0")
                    .accessibilityAddTraits(enabled[index] ? .isSelected : [])
            }
            Text(localizedTitle(field.title)).font(.custom("PlusJakartaSans-Regular", size: 16)).foregroundStyle(Color("color-text-30"))
            Spacer(minLength: 4)
            HStack(spacing: 0) {
                Button { step(index, field: field, direction: -1) } label: { Image(systemName: "minus").frame(width: 32, height: 32) }
                    .accessibilityIdentifier("stockDetail.chart.parameter.decrement.\(index)")
                TextField("", text: $values[index]).keyboardType(field.step < 1 ? .decimalPad : .numberPad)
                    .multilineTextAlignment(.center).font(.custom("PlusJakartaSans-Regular", size: 16)).frame(width: 48)
                    .accessibilityIdentifier("stockDetail.chart.parameter.value.\(index)")
                Button { step(index, field: field, direction: 1) } label: { Image(systemName: "plus").frame(width: 32, height: 32) }
                    .accessibilityIdentifier("stockDetail.chart.parameter.increment.\(index)")
            }.buttonStyle(.plain).foregroundStyle(Color("color-text-30"))
                .background(Color("color-scale-1"), in: RoundedRectangle(cornerRadius: 4))
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
            .background(Color("color-base-1"))
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
            }.foregroundStyle(Color("color-text-30"))
        }
        .tint(Color("color-brand-blue"))
        .padding(.horizontal, 16).frame(height: 56)
        .background(Color("color-scale-1"), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 16)
        .accessibilityIdentifier("stockDetail.chart.labels.\(id)")
    }
}
