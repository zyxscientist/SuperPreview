import XCTest
import UIKit

final class StockDetailChartUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments += ["-UITesting", "-UIPreferredContentSizeCategory", "UICTContentSizeCategoryL"]
        app.launchEnvironment["UITEST_MODE"] = "1"
        app.launch()
    }

    override func tearDown() {
        if (testRun?.failureCount ?? 0) > 0 { screenshot("chart-failure") }
        super.tearDown()
    }

    func testPeriodPanPinchAndLongPress() {
        openDetail()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        XCTAssertEqual(state(canvas)["period"], "intraday")
        XCTAssertTrue(state(canvas)["main"]?.contains("ma") == true)
        XCTAssertTrue(state(canvas)["sub"]?.contains("volume") == true)
        XCTAssertEqual(canvas.frame.height, 333, accuracy: 2)
        screenshot("chart-intraday")

        element("stockDetail.chart.period.day").tap()
        waitForState(canvas, key: "period", value: "day")
        let latestStart = integerState(canvas, "start")
        XCTAssertGreaterThan(latestStart, 0)
        XCTAssertEqual(integerState(canvas, "count"), 60)
        drag(canvas, from: CGVector(dx: 0.25, dy: 0.45), to: CGVector(dx: 0.8, dy: 0.45))
        waitForStateChange(canvas, key: "start", from: String(latestStart))
        XCTAssertLessThan(integerState(canvas, "start"), latestStart, "A rightward drag should reveal older candles")

        let previousCount = integerState(canvas, "count")
        canvas.pinch(withScale: 1.8, velocity: 1)
        waitForStateChange(canvas, key: "count", from: String(previousCount))
        XCTAssertLessThan(integerState(canvas, "count"), previousCount, "Pinching out should zoom in")

        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.4)).press(forDuration: 0.7)
        waitForStateChange(canvas, key: "selected", from: "none")
        XCTAssertNotNil(Int(state(canvas)["selected"] ?? ""))
        XCTAssertTrue(element("stockDetail.chart.selection").exists, "Long press should display candle details")
        screenshot("chart-selected-candle")
    }

    func testIntradayTradesLayoutAndDetails() {
        openDetail()
        element("stockDetail.navbar.debug").tap()
        elementByLabel("简体中文").tap()
        element("stockDetail.debug.done").tap()
        showChart()
        let chart = element("stockDetail.chart")
        let canvas = element("stockDetail.chart.canvas")
        let trades = element("stockDetail.chart.trades")
        XCTAssertEqual(state(canvas)["period"], "intraday")
        XCTAssertEqual(trades.frame.width, 130, accuracy: 2)
        XCTAssertEqual(canvas.frame.width, chart.frame.width - 154, accuracy: 2)
        XCTAssertEqual(canvas.frame.minX - chart.frame.minX, 12, accuracy: 2)
        XCTAssertEqual(trades.frame.minX - canvas.frame.maxX, 12, accuracy: 2)
        XCTAssertEqual(canvas.frame.height, 333, accuracy: 2)
        let intradayTab = element("stockDetail.chart.period.intraday")
        let volumeShortcut = element("stockDetail.chart.indicator.sub.volume")
        let details = element("stockDetail.chart.trades.details")
        // AX groups omit trailing empty padding, so verify the visible child
        // positions that define the 32-point bar and the 44-point footer.
        XCTAssertEqual(intradayTab.frame.height, 32, accuracy: 2)
        XCTAssertEqual(canvas.frame.minY, intradayTab.frame.maxY, accuracy: 2)
        XCTAssertEqual(canvas.frame.maxY - intradayTab.frame.minY, 32 + 333, accuracy: 2)
        XCTAssertEqual(volumeShortcut.frame.midY - canvas.frame.maxY, 22, accuracy: 2)
        XCTAssertEqual(details.frame.maxY - canvas.frame.maxY, 44 - 7, accuracy: 2)
        XCTAssertTrue(element("stockDetail.chart.trades.list").exists)
        screenshot("chart-intraday-trades")

        details.tap()
        XCTAssertTrue(app.staticTexts["逐笔明细"].waitForExistence(timeout: 5), "Trade details title should be visible")
        let detailsSheet = element("stockDetail.chart.trades.sheet")
        XCTAssertTrue(scopedElement("stockDetail.chart.trades.list", in: detailsSheet).exists)
        XCTAssertFalse(detailsSheet.descendants(matching: .any)["stockDetail.chart.trades.details"].firstMatch.exists,
                       "The full trade list should not show another details button")
        screenshot("chart-trade-details")
        element("stockDetail.chart.settings.done").tap()
        XCTAssertTrue(element("stockDetail.chart.trades.details").isHittable)

        for period in ["fiveDays", "day"] {
            element("stockDetail.chart.period.\(period)").tap()
            waitForState(canvas, key: "period", value: period)
            let absent = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: trades)
            XCTAssertEqual(XCTWaiter.wait(for: [absent], timeout: 5), .completed,
                           "Trade tape should only be shown for intraday")
            XCTAssertEqual(canvas.frame.width, chart.frame.width - 24, accuracy: 2)
            XCTAssertEqual(canvas.frame.minX - chart.frame.minX, 12, accuracy: 2)
        }
        element("stockDetail.chart.period.intraday").tap()
        waitForState(canvas, key: "period", value: "intraday")
        XCTAssertTrue(trades.waitForExistence(timeout: 5))
        XCTAssertEqual(trades.frame.width, 130, accuracy: 2)
    }

    func testPeriodAggregationAndIndicatorSettings() {
        openDetail()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        let periods = ["fiveDays", "day", "week", "month", "intraday"]
        var starts: [String: Int] = [:]
        for period in periods {
            element("stockDetail.chart.period.\(period)").tap()
            waitForState(canvas, key: "period", value: period)
            starts[period] = integerState(canvas, "start")
        }
        XCTAssertGreaterThan(starts["day"] ?? -1, starts["week"] ?? -1)
        XCTAssertGreaterThan(starts["week"] ?? -1, starts["month"] ?? -1)
        for minute in [1, 5, 15, 30, 60] {
            element("stockDetail.chart.period.minutes").tap()
            element("stockDetail.chart.period.minute\(minute)").tap()
            waitForState(canvas, key: "period", value: "minute\(minute)")
            starts["minute\(minute)"] = integerState(canvas, "start")
        }
        XCTAssertGreaterThan(starts["minute1"] ?? -1, starts["minute5"] ?? -1)
        XCTAssertGreaterThan(starts["minute5"] ?? -1, starts["minute60"] ?? -1)

        element("stockDetail.chart.settings").tap()
        setIndicatorSwitch("stockDetail.chart.main.ema", from: "0", to: "1")
        setIndicatorSwitch("stockDetail.chart.sub.macd", from: "0", to: "1")
        setIndicatorSwitch("stockDetail.chart.sub.kdj", from: "0", to: "1")
        element("stockDetail.chart.settings.done").tap()
        waitForStateContaining(canvas, key: "main", value: "ema")
        waitForStateContaining(canvas, key: "sub", value: "macd")
        waitForStateContaining(canvas, key: "sub", value: "kdj")
        XCTAssertGreaterThan(canvas.frame.height, 333, "Additional subcharts must add drawing space")
        screenshot("chart-indicators")

        element("stockDetail.chart.settings").tap()
        setIndicatorSwitch("stockDetail.chart.sub.macd", from: "1", to: "0")
        setIndicatorSwitch("stockDetail.chart.sub.kdj", from: "1", to: "0")
        setIndicatorSwitch("stockDetail.chart.sub.rsi", from: "0", to: "1")
        setIndicatorSwitch("stockDetail.chart.main.boll", from: "0", to: "1")
        element("stockDetail.chart.settings.done").tap()
        waitForStateContaining(canvas, key: "sub", value: "rsi")
        waitForStateContaining(canvas, key: "main", value: "boll")
        waitForStateNotContaining(canvas, key: "sub", value: "macd")
        waitForStateNotContaining(canvas, key: "sub", value: "kdj")
        XCTAssertEqual(canvas.frame.height, 441, accuracy: 2)
    }

    func testIndicatorShortcutsAndLegendFold() {
        openDetail()
        showChart()
        element("stockDetail.chart.period.day").tap()
        let canvas = element("stockDetail.chart.canvas")
        waitForState(canvas, key: "period", value: "day")

        let legend = element("stockDetail.chart.indicatorFold")
        let expandedLabel = legend.label
        legend.tap()
        let labelChanged = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", expandedLabel), object: legend)
        XCTAssertEqual(XCTWaiter.wait(for: [labelChanged], timeout: 5), .completed, "Legend button should switch to expand")
        legend.tap()
        let labelRestored = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", expandedLabel), object: legend)
        XCTAssertEqual(XCTWaiter.wait(for: [labelRestored], timeout: 5), .completed, "Legend button should switch back to collapse")

        let indicatorBar = element("stockDetail.chart.indicators")
        let quoteScroll = app.scrollViews["stockDetail.page.quotePage"].firstMatch
        for _ in 0..<6 where !indicatorBar.isHittable || indicatorBar.frame.maxY > app.windows.firstMatch.frame.maxY - 60 {
            quoteScroll.swipeUp()
        }
        XCTAssertTrue(indicatorBar.isHittable)
        let ema = element("stockDetail.chart.indicator.main.ema")
        XCTAssertTrue(ema.isHittable)
        // The AX bar encloses its 20-point buttons, excluding the 12-point
        // padding above and below inside the actual 44-point footer.
        XCTAssertEqual(ema.frame.height, 20, accuracy: 2)
        XCTAssertEqual(ema.frame.midY - canvas.frame.maxY, 22, accuracy: 2)
        XCTAssertEqual(indicatorBar.frame.midY, ema.frame.midY, accuracy: 2)
        ema.tap()
        waitForStateContaining(canvas, key: "main", value: "ema")
        XCTAssertTrue(ema.isSelected)
        let macd = element("stockDetail.chart.indicator.sub.macd")
        XCTAssertTrue(macd.isHittable)
        macd.tap()
        waitForStateContaining(canvas, key: "sub", value: "macd")
        XCTAssertEqual(canvas.frame.height, 441, accuracy: 2)
        screenshot("chart-shortcut-indicators")
    }

    func testDoubleTapExpandsAndCloseReturnsToDetail() {
        openDetail()
        showChart()
        element("stockDetail.chart.period.day").tap()
        let canvas = element("stockDetail.chart.canvas")
        waitForState(canvas, key: "period", value: "day")
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.45)).doubleTap()
        let expanded = element("stockDetail.chart.expanded")
        XCTAssertTrue(expanded.exists)
        let close = element("stockDetail.chart.expanded.close")
        XCTAssertTrue(close.isHittable)
        screenshot("chart-expanded")
        close.tap()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: expanded)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed)
        XCTAssertTrue(element("stockDetail.page").exists)
        waitForState(element("stockDetail.chart.canvas"), key: "period", value: "day")
    }

    func testLocalizationAndMarketColors() {
        openDetail()
        // Restore the persistent color preference even when an assertion fails.
        element("stockDetail.navbar.debug").tap()
        let green = element("debug.marketColors.greenUp")
        let originalReversed = green.isSelected
        addTeardownBlock { [weak self] in self?.restoreMarketColor(originalReversed) }
        for (language, intraday, daily, settings) in [
            ("简体中文", "分时", "日K", "指标设置"),
            ("English", "1d", "Daily", "Indicator Settings"),
            ("繁體中文", "分時", "日K", "指標設定")
        ] {
            elementByLabel(language).tap()
            element("stockDetail.debug.done").tap()
            showChart()
            XCTAssertEqual(element("stockDetail.chart.period.intraday").label, intraday)
            XCTAssertEqual(element("stockDetail.chart.period.day").label, daily)
            element("stockDetail.chart.settings").tap()
            XCTAssertTrue(app.staticTexts[settings].waitForExistence(timeout: 5), "Missing localized settings title: \(settings)")
            element("stockDetail.chart.settings.done").tap()
            showDebug()
        }
        elementByLabel("简体中文").tap()
        element("debug.marketColors.redUp").tap()
        element("stockDetail.debug.done").tap()
        showChart()
        element("stockDetail.chart.period.day").tap()
        let canvas = element("stockDetail.chart.canvas")
        waitForState(canvas, key: "period", value: "day")
        waitForState(canvas, key: "reversed", value: "false")
        let redUp = canvas.screenshot().image
        screenshot("chart-red-up")
        showDebug()
        element("debug.marketColors.greenUp").tap()
        element("stockDetail.debug.done").tap()
        showChart()
        waitForState(canvas, key: "reversed", value: "true")
        let greenUp = canvas.screenshot().image
        screenshot("chart-green-up")
        assertMarketColorsSwap(redUp, greenUp)

        // The tape uses a fixed fixture and scrolls to its last row on appearance.
        // Crop the same element for each appearance so page scroll offsets do not
        // affect the pixel comparison.
        element("stockDetail.chart.period.intraday").tap()
        waitForState(canvas, key: "period", value: "intraday")
        let trades = element("stockDetail.chart.trades")
        let tapeGreen = trades.screenshot().image
        attachImage(tapeGreen, name: "trades-green-up")
        showDebug()
        element("debug.marketColors.redUp").tap()
        element("stockDetail.debug.done").tap()
        showChart()
        waitForState(canvas, key: "reversed", value: "false")
        XCTAssertEqual(state(canvas)["period"], "intraday")
        let tapeRed = element("stockDetail.chart.trades").screenshot().image
        attachImage(tapeRed, name: "trades-red-up")
        assertMarketColorsSwap(tapeRed, tapeGreen, subject: "Trade tape")
    }

    func testScrollIgnoresPresentingChartRegionAndOrderChartTracksGlobalColors() {
        openDetail()
        element("stockDetail.navbar.debug").tap()
        let originalReversed = element("debug.marketColors.greenUp").isSelected
        addTeardownBlock { [weak self] in self?.restoreColorFromScrollOrder(originalReversed) }
        element("debug.marketColors.redUp").tap()
        element("stockDetail.debug.done").tap()
        let presentingChartFrame = element("stockDetail.chart").frame
        element("stockDetail.bottomActionBar.scroll").tap()
        let card = element("stockDetail.scroll.card.current")
        let currentPeriod = scopedElement("stockDetail.chart.period.intraday", in: card)
        let currentCanvas = scopedElement("stockDetail.chart.canvas", in: card)
        waitForState(currentCanvas, key: "reversed", value: "false")
        let window = app.windows.firstMatch
        let y = currentPeriod.frame.minY - 8
        let x = window.frame.minX + window.frame.width * 0.62
        let point = CGPoint(x: x, y: y)
        XCTAssertTrue(card.frame.contains(point), "Gesture should start on the current card")
        XCTAssertTrue(presentingChartFrame.contains(point), "Fixture must overlap the presenting page chart")
        XCTAssertLessThan(y, currentPeriod.frame.minY, "Gesture must start outside the current chart")
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(
            CGVector(dx: x - window.frame.minX, dy: y - window.frame.minY)
        )
        start.press(forDuration: 0.01,
                    thenDragTo: start.withOffset(CGVector(dx: -window.frame.width * 0.42, dy: 0)))
        XCTAssertTrue(element("stockOrder.demo").exists, "Presenting chart must not block order entry")
        XCTAssertEqual(element("stockOrder.debug.status.symbol").label, "NVDA")
        element("stockOrder.symbolInput.expandChart").tap()
        let orderCanvas = element("stockDetail.chart.canvas")
        waitForState(orderCanvas, key: "reversed", value: "false")
        let tape = element("stockDetail.chart.trades")
        let red = tape.screenshot().image
        attachImage(red, name: "scroll-order-trades-red-up")

        element("stockOrder.navbar.debug").tap()
        element("debug.marketColors.greenUp").tap()
        element("stockOrder.debug.close").tap()
        waitForState(orderCanvas, key: "reversed", value: "true")
        let green = tape.screenshot().image
        attachImage(green, name: "scroll-order-trades-green-up")
        assertMarketColorsSwap(red, green, subject: "Scroll order trade tape")
    }

    func testScrollChartModalsDoNotPageOrOpenOrderDuringDrags() {
        openDetail()
        element("stockDetail.bottomActionBar.scroll").tap()
        let scroll = element("stockDetail.scroll.root")
        let card = element("stockDetail.scroll.card.current")
        let canvas = scopedElement("stockDetail.chart.canvas", in: card)
        let period = scopedElement("stockDetail.chart.period.intraday", in: card)
        let originalPeriodTop = period.frame.minY
        scopedElement("stockDetail.chart.settings", in: card).tap()
        let done = element("stockDetail.chart.settings.done")
        let macd = element("stockDetail.chart.sub.macd")
        let initialValue = macd.value as? String
        XCTAssertNotNil(initialValue)
        let sheetStart = done.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        sheetStart.press(forDuration: 0.05, thenDragTo: sheetStart.withOffset(CGVector(dx: -100, dy: 0)))
        XCTAssertTrue(done.exists, "Dragging the settings sheet must not dismiss it")
        XCTAssertEqual(macd.value as? String, initialValue, "Dragging must not change the indicator toggle")
        screenshot("scroll-chart-settings-drag")
        done.tap()
        assertStillInScroll(scroll)

        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.4)).doubleTap()
        let expanded = element("stockDetail.chart.expanded")
        let window = app.windows.firstMatch
        XCTAssertLessThan(window.frame.minY + window.frame.height * 0.18, originalPeriodTop,
                          "The full-screen drag should start outside the underlying chart")
        drag(window, from: CGVector(dx: 0.62, dy: 0.18), to: CGVector(dx: 0.20, dy: 0.18))
        XCTAssertTrue(expanded.exists, "Dragging the expanded chart must not dismiss it")
        XCTAssertFalse(app.descendants(matching: .any)["stockOrder.demo"].exists, "A full-screen chart drag must not open an order")
        screenshot("scroll-chart-expanded-drag")
        element("stockDetail.chart.expanded.close").tap()
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: expanded)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed)
        assertStillInScroll(scroll)
    }

    func testScrollSymbolBarSwipeStillOpensOrder() {
        openDetail()
        element("stockDetail.bottomActionBar.scroll").tap()
        let card = element("stockDetail.scroll.card.current")
        let canvas = scopedElement("stockDetail.chart.canvas", in: card)
        // An extra subchart makes the plot extend behind the floating bar on
        // both screen heights, so this exercises actual overlap in each case.
        scopedElement("stockDetail.chart.settings", in: card).tap()
        setIndicatorSwitch("stockDetail.chart.sub.macd", from: "0", to: "1")
        element("stockDetail.chart.settings.done").tap()
        waitForStateContaining(canvas, key: "sub", value: "macd")
        let symbol = element("stockDetail.scroll.symbol.us:NVDA")
        XCTAssertTrue(symbol.isHittable)
        let point = CGPoint(x: symbol.frame.midX, y: symbol.frame.midY)
        XCTAssertTrue(canvas.frame.contains(point), "Symbol-bar start must overlap the current chart canvas")
        let start = symbol.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.01, thenDragTo: start.withOffset(CGVector(dx: -80, dy: 0)))
        XCTAssertTrue(element("stockOrder.demo").exists, "A swipe on the overlaid symbol bar should open the order page")
        XCTAssertEqual(element("stockOrder.debug.status.symbol").label, "NVDA")
        screenshot("scroll-symbol-bar-order")
    }

    func testOrderChartInteractionAndCollapseKeepsOrderControlsWorking() {
        openDetail()
        element("stockDetail.bottomActionBar.trade").tap()
        _ = element("stockOrder.demo")
        XCTAssertEqual(element("stockOrder.debug.status.symbol").label, "NVDA")
        let toggle = element("stockOrder.symbolInput.expandChart")
        XCTAssertTrue(toggle.isHittable)
        toggle.tap()
        let canvas = element("stockDetail.chart.canvas")
        let orderScroll = app.scrollViews.firstMatch
        let day = element("stockDetail.chart.period.day")
        for _ in 0..<6 where !day.isHittable { orderScroll.swipeUp() }
        XCTAssertTrue(day.isHittable)
        day.tap()
        waitForState(canvas, key: "period", value: "day")
        for _ in 0..<6 where !canvas.isHittable { orderScroll.swipeUp() }
        XCTAssertTrue(canvas.isHittable)
        let latestStart = integerState(canvas, "start")
        drag(canvas, from: CGVector(dx: 0.25, dy: 0.4), to: CGVector(dx: 0.8, dy: 0.4))
        waitForStateChange(canvas, key: "start", from: String(latestStart))
        XCTAssertLessThan(integerState(canvas, "start"), latestStart)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 0.7)
        waitForStateChange(canvas, key: "selected", from: "none")
        XCTAssertTrue(element("stockDetail.chart.selection").exists)
        screenshot("order-chart-selected")
        let week = element("stockDetail.chart.period.week")
        for _ in 0..<6 where !week.isHittable { orderScroll.swipeDown() }
        XCTAssertTrue(week.isHittable)
        week.tap()
        waitForState(canvas, key: "period", value: "week")

        for _ in 0..<8 where !toggle.isHittable { orderScroll.swipeDown() }
        XCTAssertTrue(toggle.isHittable)
        toggle.tap()
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: canvas)
        XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 5), .completed, "Collapsing must remove the chart")
        XCTAssertTrue(element("stockOrder.demo").exists)
        XCTAssertEqual(element("stockOrder.debug.status.symbol").label, "NVDA")
        let orderType = element("stockOrder.orderTypeInput.selection")
        for _ in 0..<6 where !orderType.isHittable { orderScroll.swipeUp() }
        XCTAssertTrue(orderType.isHittable)
        orderType.tap()
        XCTAssertTrue(element("stockOrder.orderTypeActionSheet").exists)
        element("stockOrder.orderTypeActionSheet.cancel").tap()
        XCTAssertTrue(element("stockOrder.tradeActionBar.buy").isHittable)
        screenshot("order-controls-after-chart")
    }

    func testScrollChartGesturesStayInCurrentStockAndOutsideSwipeStillPages() {
        openDetail()
        element("stockDetail.bottomActionBar.scroll").tap()
        let scroll = element("stockDetail.scroll.root")
        XCTAssertEqual(element("stockDetail.scroll.committedInstrument").label, "us:NVDA")
        let current = element("stockDetail.scroll.card.current")
        let canvas = scopedElement("stockDetail.chart.canvas", in: current)
        scopedElement("stockDetail.chart.period.day", in: current).tap()
        waitForState(canvas, key: "period", value: "day")
        let before = integerState(canvas, "start")
        drag(canvas, from: CGVector(dx: 0.25, dy: 0.45), to: CGVector(dx: 0.75, dy: 0.45))
        waitForStateChange(canvas, key: "start", from: String(before))
        assertStillInScroll(scroll)
        let count = integerState(canvas, "count")
        canvas.pinch(withScale: 1.6, velocity: 1)
        waitForStateChange(canvas, key: "count", from: String(count))
        assertStillInScroll(scroll)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)).press(forDuration: 0.7)
        waitForStateChange(canvas, key: "selected", from: "none")
        XCTAssertTrue(scopedElement("stockDetail.chart.selection", in: current).exists)
        assertStillInScroll(scroll)
        screenshot("chart-scroll-gestures")

        // Begin outside the chart in the current card, not in the presenting
        // detail page or an offscreen previous/next card.
        let header = scopedElement("stockDetail.quoteData.header", in: current)
        XCTAssertTrue(header.isHittable)
        XCTAssertLessThan(header.frame.midY, scopedElement("stockDetail.chart.period.day", in: current).frame.minY)
        let start = header.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: -200)))
        let status = element("stockDetail.scroll.committedInstrument")
        let next = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "us:AAPL"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [next], timeout: 5), .completed, "Swipe outside the chart should advance to AAPL")
        XCTAssertTrue(scroll.exists)

        // The known window drag starts above the current card's period bar;
        // this exercises the order transition without crossing the chart.
        let nextCard = element("stockDetail.scroll.card.current")
        let periodBar = scopedElement("stockDetail.chart.period.intraday", in: nextCard)
        let window = app.windows.firstMatch
        let dragY = window.frame.minY + window.frame.height * 0.18
        XCTAssertLessThan(dragY, periodBar.frame.minY, "Order swipe must start above the chart")
        drag(window, from: CGVector(dx: 0.62, dy: 0.18), to: CGVector(dx: 0.20, dy: 0.18))
        XCTAssertTrue(element("stockOrder.demo").exists, "A horizontal swipe outside the chart should still open the order page")
    }

    private func openDetail() {
        let watchlist = app.descendants(matching: .any)["watchlist.root"].firstMatch
        let tab = app.descendants(matching: .any)["mainTab.tab1"].firstMatch
        dismissVisibleStockDetail()
        if tab.waitForExistence(timeout: 8), tab.isHittable { tab.tap() }
        if !watchlist.waitForExistence(timeout: 5) {
            // A restored detail can cover an otherwise existing tab; dismiss it
            // before the retry and never tap through an obscured tab.
            dismissVisibleStockDetail()
            XCTAssertTrue(tab.waitForExistence(timeout: 8), "Missing watchlist tab")
            XCTAssertTrue(tab.isHittable, "Watchlist tab is covered or unavailable")
            if tab.isHittable { tab.tap() }
        }
        XCTAssertTrue(watchlist.waitForExistence(timeout: 8), "Watchlist did not appear after selecting its tab")
        let row = element("watchlist.row.us:NVDA")
        for _ in 0..<6 where !row.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(row.isHittable)
        row.tap()
        _ = element("stockDetail.page")
    }

    private func dismissVisibleStockDetail() {
        let back = app.buttons.matching(identifier: "stockDetail.navbar.back")
            .allElementsBoundByIndex.first(where: { $0.isHittable })
        back?.tap()
    }

    private func showChart() {
        let chart = element("stockDetail.chart")
        let canvas = element("stockDetail.chart.canvas")
        let scroll = app.scrollViews["stockDetail.page.quotePage"].firstMatch
        // Include the 44-point indicator bar and the tape details control in
        // the visible area, not just the plot's bottom edge.
        for _ in 0..<8 where !canvas.isHittable || chart.frame.maxY > app.windows.firstMatch.frame.maxY - 60 { scroll.swipeUp() }
        XCTAssertTrue(canvas.isHittable, "Chart must be visible and interactive")
    }

    private func showDebug() {
        let debug = app.descendants(matching: .any)["stockDetail.navbar.debug"].firstMatch
        let scroll = app.scrollViews["stockDetail.page.quotePage"].firstMatch
        for _ in 0..<10 where !debug.isHittable { scroll.swipeDown() }
        XCTAssertTrue(debug.isHittable)
        debug.tap()
        _ = element("stockDetail.debug.sheet")
    }

    private func restoreMarketColor(_ reversed: Bool) {
        guard app.state == .runningForeground else { return }
        let debug = app.descendants(matching: .any)["stockDetail.navbar.debug"].firstMatch
        if !app.buttons["debug.marketColors.redUp"].exists {
            let scroll = app.scrollViews["stockDetail.page.quotePage"].firstMatch
            if scroll.exists { for _ in 0..<10 where !debug.isHittable { scroll.swipeDown() } }
            if debug.isHittable { debug.tap() }
        }
        let choice = app.buttons[reversed ? "debug.marketColors.greenUp" : "debug.marketColors.redUp"].firstMatch
        if choice.waitForExistence(timeout: 3), !choice.isSelected { choice.tap() }
        let done = app.descendants(matching: .any)["stockDetail.debug.done"].firstMatch
        if done.isHittable { done.tap() }
    }

    private func restoreColorFromScrollOrder(_ reversed: Bool) {
        guard app.state == .runningForeground else { return }
        let orderPanel = app.descendants(matching: .any)["stockOrder.debug.panel"].firstMatch
        let orderDebug = app.descendants(matching: .any)["stockOrder.navbar.debug"].firstMatch
        if !orderPanel.exists && orderDebug.isHittable { orderDebug.tap() }
        if orderPanel.waitForExistence(timeout: 2) {
            let choice = app.buttons[reversed ? "debug.marketColors.greenUp" : "debug.marketColors.redUp"].firstMatch
            if choice.waitForExistence(timeout: 2), !choice.isSelected { choice.tap() }
            let close = app.descendants(matching: .any)["stockOrder.debug.close"].firstMatch
            if close.isHittable { close.tap() }
            return
        }
        let closeScroll = app.descendants(matching: .any)["stockDetail.scroll.close"].firstMatch
        if closeScroll.isHittable { closeScroll.tap() }
        restoreMarketColor(reversed)
    }

    private func assertStillInScroll(_ scroll: XCUIElement) {
        XCTAssertTrue(scroll.exists, "Chart gestures must not exit Scroll")
        XCTAssertEqual(element("stockDetail.scroll.committedInstrument").label, "us:NVDA")
        XCTAssertFalse(app.descendants(matching: .any)["stockOrder.demo"].exists, "Chart gestures must not open an order")
    }

    private func setIndicatorSwitch(_ identifier: String, from initial: String, to expected: String) {
        let control = app.switches[identifier].firstMatch
        XCTAssertTrue(control.waitForExistence(timeout: 8), "Missing indicator switch: \(identifier)")
        let window = app.windows.firstMatch
        for _ in 0..<6 {
            let frame = control.frame
            if control.isHittable && frame.midY > window.frame.minY + 40 && frame.midY < window.frame.maxY - 40 { break }
            if frame.midY < window.frame.midY { app.swipeDown() } else { app.swipeUp() }
        }
        XCTAssertTrue(control.isHittable, "Indicator switch should be visible: \(identifier)")
        XCTAssertEqual(control.value as? String, initial, "Unexpected initial value for \(identifier)")
        // SwiftUI's Switch accessibility frame includes the row label. Tap the
        // trailing track itself rather than the center of the whole row.
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", expected), object: control)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed,
                       "Indicator switch did not change to \(expected): \(identifier)")
    }

    private func scopedElement(_ identifier: String, in parent: XCUIElement) -> XCUIElement {
        let result = parent.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 8), "Missing \(identifier) in \(parent.identifier)")
        return result
    }

    private func element(_ identifier: String) -> XCUIElement {
        let result = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 8), "Missing \(identifier)")
        return result
    }

    private func elementByLabel(_ label: String) -> XCUIElement {
        let result = app.buttons[label].firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5), "Missing button \(label)")
        return result
    }

    private func state(_ canvas: XCUIElement) -> [String: String] {
        let value = canvas.value as? String ?? ""
        return Dictionary(value.split(separator: ",").compactMap { component -> (String, String)? in
            let parts = component.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { return nil }
            return (String(parts[0]), String(parts[1]))
        }, uniquingKeysWith: { _, new in new })
    }

    private func integerState(_ canvas: XCUIElement, _ key: String) -> Int {
        guard let value = state(canvas)[key], let number = Int(value) else {
            XCTFail("Missing integer \(key) in canvas value \(String(describing: canvas.value))")
            return -1
        }
        return number
    }

    private func waitForState(_ canvas: XCUIElement, key: String, value: String) {
        waitForCanvas(canvas) { self.state(canvas)[key] == value }
    }
    private func waitForStateChange(_ canvas: XCUIElement, key: String, from old: String) {
        waitForCanvas(canvas) { guard let value = self.state(canvas)[key] else { return false }; return value != old }
    }
    private func waitForStateContaining(_ canvas: XCUIElement, key: String, value: String) {
        waitForCanvas(canvas) { self.state(canvas)[key]?.contains(value) == true }
    }
    private func waitForStateNotContaining(_ canvas: XCUIElement, key: String, value: String) {
        waitForCanvas(canvas) { guard let state = self.state(canvas)[key] else { return false }; return !state.contains(value) }
    }
    private func waitForCanvas(_ canvas: XCUIElement, condition: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in condition() }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed, "Canvas state did not update: \(String(describing: canvas.value))")
    }

    private func drag(_ element: XCUIElement, from: CGVector, to: CGVector) {
        element.coordinate(withNormalizedOffset: from).press(forDuration: 0.05, thenDragTo: element.coordinate(withNormalizedOffset: to))
    }
    private func screenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func attachImage(_ image: UIImage, name: String) {
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func assertMarketColorsSwap(_ first: UIImage, _ second: UIImage, subject: String = "Chart") {
        guard let a = rgba(first), let b = rgba(second), a.width == b.width, a.height == b.height else {
            XCTFail("Unable to compare \(subject) screenshots with matching dimensions")
            return
        }
        var redToGreen = 0, greenToRed = 0
        for i in stride(from: 0, to: a.pixels.count, by: 4) {
            let ar = Int(a.pixels[i]), ag = Int(a.pixels[i + 1]), ab = Int(a.pixels[i + 2])
            let br = Int(b.pixels[i]), bg = Int(b.pixels[i + 1]), bb = Int(b.pixels[i + 2])
            let aRed = ar > ag + 50 && ar > ab + 50
            let aGreen = ag > ar + 50 && ag > ab + 10
            let bRed = br > bg + 50 && br > bb + 50
            let bGreen = bg > br + 50 && bg > bb + 10
            if aRed && bGreen { redToGreen += 1 }
            if aGreen && bRed { greenToRed += 1 }
        }
        XCTAssertGreaterThan(redToGreen, 10, "\(subject) red pixels should change to green at the same position")
        XCTAssertGreaterThan(greenToRed, 10, "\(subject) green pixels should change to red at the same position")
    }
    private func rgba(_ image: UIImage) -> (width: Int, height: Int, pixels: [UInt8])? {
        guard let cg = image.cgImage else { return nil }
        var pixels = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        let ok = pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(data: bytes.baseAddress, width: cg.width, height: cg.height,
                bitsPerComponent: 8, bytesPerRow: cg.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue) else { return false }
            context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
            return true
        }
        return ok ? (cg.width, cg.height, pixels) : nil
    }
}
