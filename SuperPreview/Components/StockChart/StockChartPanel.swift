import SwiftUI
import UIKit

/// The production chart's presentation boundary. Market services are replaced
/// by deterministic fixtures; chart state belongs to each detail-page instance.
struct StockChartPanel: View {
    @Environment(\.demoLanguage) private var language
    @Environment(\.marketColorReversed) private var reversed
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.stockChartTouchScope) private var touchScope
    @State private var period: StockChartPeriod = .intraday
    @State private var mainIndicators: [StockChartMainIndicator] = [.ma]
    @State private var subIndicators: [StockChartSubIndicator] = [.volume]
    @State private var selection: StockChartCandle?
    @State private var pagePresentation: Presentation?
    @State private var expandedPresentation: Presentation?
    @State private var isExpanded = false

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
            }
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
                settings
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
                                period: period, mainIndicators: mainIndicators,
                                subIndicators: subIndicators, reversed: reversed,
                                language: language, colorScheme: colorScheme,
                                onSelection: { selection = $0 },
                                onExpand: {
                                    guard !expanded, pagePresentation == nil else { return }
                                    selection = nil
                                    isExpanded = true
                                }
                            )
                            .frame(height: StockChartCanvasView.height(subchartCount: subIndicators.count))
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
                        .frame(width: 130, height: StockChartCanvasView.height(subchartCount: subIndicators.count) + 44)
                }
            }
        }
        .onChange(of: period) { _, _ in selection = nil }
    }

    private var indicatorBar: some View {
        HStack(spacing: 16) {
            if !period.isIntraday {
                HStack(spacing: 16) {
                    ForEach([StockChartMainIndicator.ma, .ema, .boll], id: \.rawValue) { item in
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
                    ForEach(StockChartSubIndicator.allCases, id: \.rawValue) { item in
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

    private var settings: some View {
        NavigationStack {
            Form {
                if !period.isIntraday {
                    Section(stockChartText(.mainIndicator, language: language)) {
                        ForEach([StockChartMainIndicator.ma, .ema, .boll], id: \.rawValue) { item in
                            Toggle(item.rawValue.uppercased(), isOn: Binding(
                                get: { mainIndicators.contains(item) },
                                set: { enabled in
                                    mainIndicators.removeAll { $0 == item }
                                    if enabled { mainIndicators.append(item) }
                                }
                            ))
                            .accessibilityIdentifier("stockDetail.chart.main.\(item.rawValue)")
                        }
                    }
                }
                Section(stockChartText(.subIndicator, language: language)) {
                    ForEach(StockChartSubIndicator.allCases, id: \.rawValue) { item in
                        Toggle(item == .volume ? "VOL" : item.rawValue.uppercased(), isOn: Binding(
                            get: { subIndicators.contains(item) },
                            set: { enabled in
                                subIndicators.removeAll { $0 == item }
                                if enabled { subIndicators.append(item) }
                            }
                        ))
                        .accessibilityIdentifier("stockDetail.chart.sub.\(item.rawValue)")
                    }
                }
            }
            .navigationTitle(stockChartText(.indicatorSettings, language: language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { doneButton } }
        }
        .presentationDetents([.medium, .large])
    }

    private var doneButton: some View {
        Button(language.text(.done)) {
            pagePresentation = nil
            expandedPresentation = nil
        }
            .accessibilityIdentifier("stockDetail.chart.settings.done")
    }

    private func selectionInfo(_ candle: StockChartCandle) -> some View {
        let data = StockChartMock.dataset(for: period)
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
        view.configure(dataset: StockChartMock.dataset(for: period), period: period,
                       mainIndicators: mainIndicators, subIndicators: subIndicators,
                       reversed: reversed, language: language)
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
