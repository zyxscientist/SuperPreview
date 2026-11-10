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
        XCTAssertEqual(integerState(canvas, "count"), 390, "The initial intraday viewport should show all 390 trading minutes")
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

    func testDetailPageScrollsVerticallyFromChart() {
        openDetail()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        let scroll = app.scrollViews["stockDetail.page.quotePage"].firstMatch
        for period in ["intraday", "fiveDays", "day"] {
            element("stockDetail.chart.period.\(period)").tap()
            waitForState(canvas, key: "period", value: period)
            assertVerticalScrollFromChart(canvas, in: scroll)
        }
    }

    func testShortOrderChartDragsMatchNativePageScrolling() {
        openDetail()
        element("stockDetail.bottomActionBar.trade").tap()
        element("stockOrder.symbolInput.expandChart").tap()
        let canvas = element("stockDetail.chart.canvas")
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(canvas.isHittable)
        assertShortChartDragsMatchNativePage(canvas, in: scroll, periods: ["intraday", "day"])
    }

    private func assertShortChartDragsMatchNativePage(_ canvas: XCUIElement, in scroll: XCUIElement, periods: [String]) {
        for period in periods {
            element("stockDetail.chart.period.\(period)").tap()
            waitForState(canvas, key: "period", value: period)
            let initialStart = state(canvas)["start"]
            // The 12pt gutter has no chart recognizers. Compare against the
            // same page, holding at the end to exclude inertial movement.
            let native = shortPageDrag(canvas, in: scroll, outsideChart: true, dx: 0, dy: -44)
            _ = shortPageDrag(canvas, in: scroll, outsideChart: true, dx: 0, dy: 44)
            XCTAssertGreaterThan(native, 24, "Native reference drag must move the page")
            for dx: CGFloat in [0, 28, -28] {
                let moved = shortPageDrag(canvas, in: scroll, outsideChart: false, dx: dx, dy: -44)
                XCTAssertEqual(moved, native, accuracy: 8,
                               "\(period): short/diagonal drags must track like the page gutter; dx=\(dx)")
                let returned = shortPageDrag(canvas, in: scroll, outsideChart: false, dx: -dx, dy: 44)
                XCTAssertEqual(returned, -native, accuracy: 8, "Reverse drag must respond without another long swipe")
                print("Chart scroll comparison: period=\(period), dx=\(dx), native=\(native), chart=\(moved), reverse=\(returned)")
                XCTAssertEqual(state(canvas)["start"], initialStart, "Vertical browsing must not pan candle history")
                XCTAssertEqual(state(canvas)["selected"], "none", "Scrolling must not select a crosshair")
            }
        }
    }

    func testShortChartDragsMatchNativePageScrolling() {
        openDetail()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        let scroll = app.scrollViews["stockDetail.page.quotePage"].firstMatch
        assertShortChartDragsMatchNativePage(canvas, in: scroll, periods: ["intraday", "fiveDays", "day"])
    }

    func testChartFlickKeepsNativeDeceleration() {
        openDetail()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        element("stockDetail.chart.period.fiveDays").tap()
        waitForState(canvas, key: "period", value: "fiveDays")
        let before = canvas.frame.minY
        let origin = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
        origin.press(forDuration: 0.01, thenDragTo: origin.withOffset(CGVector(dx: 0, dy: -70)),
                     withVelocity: XCUIGestureVelocity(rawValue: 1_200), thenHoldForDuration: 0)
        XCTAssertGreaterThan(before - canvas.frame.minY, 100,
                             "A 70pt flick must keep scrolling after release using the page's native inertia")
        XCTAssertEqual(state(canvas)["selected"], "none")
    }

    func testInlineTradeTapeScrollsThePage() {
        openDetail()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        let tape = element("stockDetail.chart.trades.list")
        let before = canvas.frame.minY
        let origin = tape.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        origin.press(forDuration: 0.01, thenDragTo: origin.withOffset(CGVector(dx: 0, dy: -70)),
                     withVelocity: XCUIGestureVelocity(rawValue: 150), thenHoldForDuration: 0.2)
        XCTAssertGreaterThan(before - canvas.frame.minY, 45, "The inline tape must not swallow page scrolling")
        let scrolledY = canvas.frame.minY
        let reverse = tape.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        reverse.press(forDuration: 0.01, thenDragTo: reverse.withOffset(CGVector(dx: 0, dy: 70)),
                      withVelocity: XCUIGestureVelocity(rawValue: 150), thenHoldForDuration: 0.2)
        XCTAssertGreaterThan(canvas.frame.minY - scrolledY, 45, "Downward drags must return the page, not scroll hidden tape rows")

        element("stockDetail.chart.trades.details").tap()
        let sheet = element("stockDetail.chart.trades.sheet")
        let list = scopedElement("stockDetail.chart.trades.list", in: sheet)
        let lastTime = list.staticTexts["15:59"].firstMatch
        XCTAssertTrue(lastTime.isHittable)
        list.swipeDown()
        XCTAssertFalse(lastTime.isHittable, "The dedicated trade detail list must still scroll independently")
        element("stockDetail.chart.settings.done").tap()
    }

    func testQuoteInfoSpacingAndTimeframeLayout() {
        openDetail()
        let header = element("stockDetail.quoteData.header")
        let firstRow = element("stockDetail.relatedInfo.us-financial-report")
        let dividend = element("stockDetail.relatedInfo.cash-dividend")
        let extendedHours = app.descendants(matching: .any)["stockDetail.relatedInfo.NVDA-extended-hours"].firstMatch
        let lastRow = extendedHours.exists ? extendedHours : dividend
        let bar = element("stockDetail.chart.periodBar")
        let intraday = element("stockDetail.chart.period.intraday")
        let fiveDays = element("stockDetail.chart.period.fiveDays")
        let settings = element("stockDetail.chart.settings")

        // Figma 11903:110282: 116pt collapsed quote; related-info rows
        // start 8pt down, have 2pt gaps and finish 16pt above the tab bar.
        // Measure visible children: SwiftUI's quote accessibility container
        // may include the clipped, collapsed detail view in its reported frame.
        XCTAssertEqual(firstRow.frame.minY - header.frame.minY, 116, accuracy: 1)
        XCTAssertEqual(dividend.frame.minY - firstRow.frame.maxY, 2, accuracy: 1)
        if extendedHours.exists { XCTAssertEqual(extendedHours.frame.minY - dividend.frame.minY, 28 + 2, accuracy: 1) }
        // A collapsed row's AX frame can include clipped detail content. Its
        // visible header is 28pt high in this fixture.
        XCTAssertEqual(bar.frame.minY - lastRow.frame.minY, 28 + 16, accuracy: 1)
        XCTAssertEqual(bar.frame.height, 32, accuracy: 1)
        XCTAssertEqual(intraday.frame.minX - bar.frame.minX, 15, accuracy: 2)
        XCTAssertEqual(settings.frame.width, 40, accuracy: 1)
        XCTAssertTrue(intraday.isSelected)
        XCTAssertFalse(fiveDays.isSelected)
        if abs(bar.frame.width - 402) < 1, intraday.label == "分时" {
            for (period, expectedX) in [("intraday", 15.0), ("fiveDays", 77.0), ("day", 139.0),
                                        ("week", 197.0), ("month", 255.0), ("minutes", 313.0)] {
                let tab = element("stockDetail.chart.period.\(period)")
                XCTAssertEqual(tab.frame.minX - bar.frame.minX, expectedX, accuracy: 3, "Unexpected position for \(period)")
            }
        }
        let image = bar.screenshot().image
        guard let pixels = rgba(image) else { XCTFail("Could not inspect timeframe bar screenshot"); return }
        let scale = CGFloat(pixels.width) / bar.frame.width
        var blueXs: [Int] = []
        for y in max(0, pixels.height - Int(3 * scale))..<pixels.height {
            for x in 0..<pixels.width {
                let i = (y * pixels.width + x) * 4
                let red = Int(pixels.pixels[i]), green = Int(pixels.pixels[i + 1]), blue = Int(pixels.pixels[i + 2])
                if blue > 175, blue > red + 80, blue > green + 45 { blueXs.append(x) }
            }
        }
        guard let left = blueXs.min(), let right = blueXs.max() else { XCTFail("The selected timeframe should have a blue underline"); return }
        XCTAssertEqual(CGFloat(right - left + 1) / scale, intraday.frame.width, accuracy: 2,
                       "The selected underline should span its text, not the whole tab")
        attachImage(image, name: "timeframe-bar")

        let expand = element("stockDetail.quoteData.expand")
        expand.tap()
        let expanded = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in firstRow.frame.minY - header.frame.minY > 116 + 20 }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expanded], timeout: 5), .completed)
        expand.tap()
        let collapsed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in abs(firstRow.frame.minY - header.frame.minY - 116) < 1 }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [collapsed], timeout: 5), .completed)
        XCTAssertEqual(bar.frame.minY - lastRow.frame.minY, 28 + 16, accuracy: 1)
    }

    func testOrderPageScrollsVerticallyFromChart() {
        openDetail()
        element("stockDetail.bottomActionBar.trade").tap()
        element("stockOrder.symbolInput.expandChart").tap()
        let canvas = element("stockDetail.chart.canvas")
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<6 where !canvas.isHittable { scroll.swipeUp() }
        XCTAssertTrue(canvas.isHittable)
        for period in ["intraday", "day"] {
            let tab = element("stockDetail.chart.period.\(period)")
            for _ in 0..<6 where !tab.isHittable { scroll.swipeDown() }
            tab.tap()
            waitForState(canvas, key: "period", value: period)
            assertVerticalScrollFromChart(canvas, in: scroll)
        }
    }

    func testScrollModePagesVerticallyFromChart() {
        openDetail()
        element("stockDetail.bottomActionBar.scroll").tap()
        let status = element("stockDetail.scroll.committedInstrument")
        XCTAssertEqual(status.label, "us:NVDA")
        let current = element("stockDetail.scroll.card.current")
        let canvas = scopedElement("stockDetail.chart.canvas", in: current)
        scopedElement("stockDetail.chart.period.day", in: current).tap()
        waitForState(canvas, key: "period", value: "day")

        dragVerticallyFromChart(canvas, in: app.windows.firstMatch, distance: -200)
        let next = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "us:AAPL"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [next], timeout: 5), .completed, "An upward drag starting in the chart should show the next stock")

        let nextCanvas = scopedElement("stockDetail.chart.canvas", in: element("stockDetail.scroll.card.current"))
        dragVerticallyFromChart(nextCanvas, in: app.windows.firstMatch, distance: 200)
        let previous = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "us:NVDA"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [previous], timeout: 5), .completed, "A downward drag starting in the chart should show the previous stock")
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
            if period == "fiveDays" {
                XCTAssertEqual(integerState(canvas, "count"), 1_950, "The five-day viewport should show five full trading sessions")
            } else if period == "intraday" {
                XCTAssertEqual(integerState(canvas, "count"), 390, "Returning to intraday should restore the full session")
            }
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

        element("stockDetail.chart.period.day").tap()
        waitForState(canvas, key: "period", value: "day")
        element("stockDetail.chart.indicator.main.ema").tap()
        element("stockDetail.chart.indicator.sub.macd").tap()
        waitForStateContaining(canvas, key: "main", value: "ema")
        waitForStateContaining(canvas, key: "sub", value: "macd")
        XCTAssertGreaterThan(canvas.frame.height, 333, "Additional subcharts must add drawing space")
        screenshot("chart-indicators")

        openIndicatorSettings()
        setIndicatorVisibility("stockDetail.chart.sub.macd", from: "1", to: "0")
        dismissIndicatorSettings()
        waitForStateNotContaining(canvas, key: "sub", value: "macd")

        openIndicatorSettings()
        setIndicatorVisibility("stockDetail.chart.sub.macd", from: "0", to: "1")
        dismissIndicatorSettings()
        waitForStateContaining(canvas, key: "sub", value: "macd")
        XCTAssertTrue(element("stockDetail.chart.indicator.sub.macd").isSelected,
                      "Showing an indicator again should preserve its previous selection")
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

    func testSettingsAdjustmentParametersAndAnnotations() {
        openDetail()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        element("stockDetail.chart.period.day").tap()
        waitForState(canvas, key: "period", value: "day")

        element("stockDetail.chart.settings").tap()
        _ = element("stockDetail.chart.settings.sheet")
        XCTAssertTrue(element("stockDetail.chart.adjustment.forward").isSelected)
        element("stockDetail.chart.adjustment.none").tap()
        XCTAssertTrue(element("stockDetail.chart.adjustment.none").isSelected)
        dismissSheet(element("stockDetail.chart.settings.sheet"))
        waitForState(canvas, key: "adjustment", value: "none")
        let originalMAImage = canvas.screenshot().image

        openIndicatorSettings()
        element("stockDetail.chart.parameter.ma").tap()
        let value = element("stockDetail.chart.parameter.value.0")
        guard let original = value.value as? String, let number = Int(original) else {
            XCTFail("The first MA parameter must be numeric")
            return
        }
        element("stockDetail.chart.parameter.increment.0").tap()
        XCTAssertEqual(value.value as? String, String(number + 1))
        element("stockDetail.chart.parameter.save").tap()
        dismissIndicatorSettings()
        let changedMAImage = canvas.screenshot().image
        attachImage(originalMAImage, name: "chart-ma-before-parameter")
        attachImage(changedMAImage, name: "chart-ma-after-parameter")
        assertPixelDifference(originalMAImage, changedMAImage, subject: "MA parameter")
        openIndicatorSettings()
        element("stockDetail.chart.parameter.ma").tap()
        XCTAssertEqual(element("stockDetail.chart.parameter.value.0").value as? String, String(number + 1),
                       "Saved parameters should survive reopening the editor")
        element("stockDetail.chart.parameter.increment.0").tap()
        element("stockDetail.chart.parameter.back").tap()
        element("stockDetail.chart.parameter.ma").tap()
        XCTAssertEqual(element("stockDetail.chart.parameter.value.0").value as? String, String(number + 1),
                       "Going back should discard unsaved edits")
        element("stockDetail.chart.parameter.reset").tap()
        let confirm = app.alerts.buttons.matching(NSPredicate(format: "label IN %@", ["确定", "確定", "Confirm"])).firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertEqual(element("stockDetail.chart.parameter.value.0").value as? String, original)
        element("stockDetail.chart.parameter.save").tap()
        dismissIndicatorSettings()

        let originalAnnotations = state(canvas)["annotations"]
        let originalAnnotationImage = canvas.screenshot().image
        element("stockDetail.chart.settings").tap()
        element("stockDetail.chart.settings.labels").tap()
        let currentPrice = element("stockDetail.chart.labels.currentPrice")
        let initialValue = currentPrice.value as? String
        XCTAssertTrue(initialValue == "0" || initialValue == "1")
        currentPrice.tap()
        XCTAssertNotEqual(currentPrice.value as? String, initialValue)
        element("stockDetail.chart.labels.back").tap()
        waitForCanvas(canvas) { self.state(canvas)["annotations"] != originalAnnotations }
        let changedAnnotationImage = canvas.screenshot().image
        attachImage(originalAnnotationImage, name: "chart-current-price-before-toggle")
        attachImage(changedAnnotationImage, name: "chart-current-price-after-toggle")
        assertPixelDifference(originalAnnotationImage, changedAnnotationImage, subject: "Current price annotation")
        element("stockDetail.chart.settings").tap()
        element("stockDetail.chart.settings.labels").tap()
        let restoredControl = element("stockDetail.chart.labels.currentPrice")
        restoredControl.tap()
        XCTAssertEqual(restoredControl.value as? String, initialValue)
        element("stockDetail.chart.labels.back").tap()
        waitForCanvas(canvas) { self.state(canvas)["annotations"] == originalAnnotations }
        XCTAssertEqual(state(canvas)["annotations"], originalAnnotations)
        screenshot("chart-settings-interactions")
    }

    func testSettingsCarryFromDetailToOrderChart() {
        openDetail()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        element("stockDetail.chart.period.day").tap()
        waitForState(canvas, key: "period", value: "day")
        element("stockDetail.chart.indicator.sub.macd").tap()
        waitForStateContaining(canvas, key: "sub", value: "macd")

        element("stockDetail.chart.settings").tap()
        element("stockDetail.chart.adjustment.none").tap()
        element("stockDetail.chart.settings.indicators").tap()
        setIndicatorVisibility("stockDetail.chart.sub.macd", from: "1", to: "0")
        element("stockDetail.chart.parameter.ma").tap()
        let parameter = element("stockDetail.chart.parameter.value.0")
        guard let original = parameter.value as? String, let number = Int(original) else {
            XCTFail("The first MA parameter must be numeric")
            return
        }
        element("stockDetail.chart.parameter.increment.0").tap()
        element("stockDetail.chart.parameter.save").tap()
        dismissIndicatorSettings()
        waitForStateNotContaining(canvas, key: "sub", value: "macd")
        waitForState(canvas, key: "adjustment", value: "none")

        element("stockDetail.bottomActionBar.trade").tap()
        element("stockOrder.symbolInput.expandChart").tap()
        let orderCanvas = element("stockDetail.chart.canvas")
        let orderScroll = app.scrollViews.firstMatch
        let day = element("stockDetail.chart.period.day")
        for _ in 0..<6 where !day.isHittable { orderScroll.swipeUp() }
        day.tap()
        waitForState(orderCanvas, key: "period", value: "day")
        waitForState(orderCanvas, key: "adjustment", value: "none")
        waitForStateNotContaining(orderCanvas, key: "sub", value: "macd")

        let settings = element("stockDetail.chart.settings")
        for _ in 0..<6 where !settings.isHittable { orderScroll.swipeUp() }
        settings.tap()
        element("stockDetail.chart.settings.indicators").tap()
        setIndicatorVisibility("stockDetail.chart.sub.macd", from: "0", to: "1")
        element("stockDetail.chart.parameter.ma").tap()
        XCTAssertEqual(element("stockDetail.chart.parameter.value.0").value as? String, String(number + 1),
                       "The order chart should share the saved detail-chart parameters")
        element("stockDetail.chart.parameter.back").tap()
        dismissIndicatorSettings()
        waitForStateContaining(orderCanvas, key: "sub", value: "macd")
        XCTAssertTrue(element("stockDetail.chart.indicator.sub.macd").isSelected,
                      "The hidden indicator's selection should survive the page transition")

        app.terminate()
        app.launchEnvironment["UITEST_PRESERVE_CHART_SETTINGS"] = "1"
        app.launch()
        openDetail()
        showChart()
        let relaunchedCanvas = element("stockDetail.chart.canvas")
        element("stockDetail.chart.period.day").tap()
        waitForState(relaunchedCanvas, key: "period", value: "day")
        waitForState(relaunchedCanvas, key: "adjustment", value: "none")
        waitForStateContaining(relaunchedCanvas, key: "sub", value: "macd")
        openIndicatorSettings()
        element("stockDetail.chart.parameter.ma").tap()
        XCTAssertEqual(element("stockDetail.chart.parameter.value.0").value as? String, String(number + 1),
                       "Saved chart parameters should survive an app restart")
        element("stockDetail.chart.parameter.back").tap()
        dismissIndicatorSettings()
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
            XCTAssertEqual(element("stockDetail.chart.settings.indicators").label, settings)
            element("stockDetail.chart.settings.indicators").tap()
            dismissIndicatorSettings()
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
        let sheet = element("stockDetail.chart.settings.sheet")
        let sheetStart = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
        sheetStart.press(forDuration: 0.05, thenDragTo: sheetStart.withOffset(CGVector(dx: -100, dy: 0)))
        XCTAssertTrue(sheet.exists, "Dragging the settings sheet must not dismiss it")
        screenshot("scroll-chart-settings-drag")
        dismissSheet(sheet)
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

    func testScrollSymbolBarSwipesScrollWithoutOpeningOrder() {
        openDetail()
        element("stockDetail.bottomActionBar.scroll").tap()
        let card = element("stockDetail.scroll.card.current")
        let canvas = scopedElement("stockDetail.chart.canvas", in: card)
        // An extra subchart makes the plot extend behind the floating bar on
        // both screen heights, so this exercises actual overlap in each case.
        scopedElement("stockDetail.chart.indicator.sub.macd", in: card).tap()
        waitForStateContaining(canvas, key: "sub", value: "macd")
        let symbol = element("stockDetail.scroll.symbol.us:NVDA")
        let nextSymbol = element("stockDetail.scroll.symbol.us:AAPL")
        XCTAssertTrue(symbol.isHittable)
        let point = CGPoint(x: symbol.frame.midX, y: symbol.frame.midY)
        XCTAssertTrue(canvas.frame.contains(point), "Symbol-bar start must overlap the current chart canvas")
        let start = symbol.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let initialX = nextSymbol.frame.midX
        start.press(forDuration: 0.01, thenDragTo: start.withOffset(CGVector(dx: -80, dy: 0)))
        let scroll = element("stockDetail.scroll.root")
        assertStillInScroll(scroll)
        XCTAssertLessThan(nextSymbol.frame.midX, initialX - 10, "Leftward drag should scroll the symbol list")

        // Start each gesture in the middle of the capsule, including repeated
        // swipes at both ends, where the list cannot consume more movement.
        let window = app.windows.firstMatch
        let middle = window.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).withOffset(
            CGVector(dx: window.frame.width * 0.55, dy: point.y - window.frame.minY)
        )
        // The default All watchlist ends with ETH/USD (funds are excluded).
        let lastSymbol = element("stockDetail.scroll.symbol.crypto:ETH/USD")
        for _ in 0..<20 where lastSymbol.frame.midX > window.frame.maxX - 20 {
            middle.press(forDuration: 0.01, thenDragTo: middle.withOffset(CGVector(dx: -120, dy: 0)))
            assertStillInScroll(scroll)
        }
        XCTAssertLessThan(lastSymbol.frame.midX, window.frame.maxX - 20, "Leftward drags must reveal the final symbol")
        // A final full swipe reaches the end even if the last label first
        // appeared partially at the capsule edge.
        middle.press(forDuration: 0.01, thenDragTo: middle.withOffset(CGVector(dx: -120, dy: 0)))
        assertStillInScroll(scroll)
        let endX = lastSymbol.frame.midX
        middle.press(forDuration: 0.01, thenDragTo: middle.withOffset(CGVector(dx: -120, dy: 0)))
        assertStillInScroll(scroll)
        XCTAssertEqual(lastSymbol.frame.midX, endX, accuracy: 3, "Another leftward drag at the end must remain at the boundary")
        for _ in 0..<20 where abs(nextSymbol.frame.midX - initialX) > 3 {
            middle.press(forDuration: 0.01, thenDragTo: middle.withOffset(CGVector(dx: 120, dy: 0)))
            assertStillInScroll(scroll)
        }
        XCTAssertEqual(nextSymbol.frame.midX, initialX, accuracy: 3, "Rightward drags should return to the start of the list")
        middle.press(forDuration: 0.01, thenDragTo: middle.withOffset(CGVector(dx: 120, dy: 0)))
        assertStillInScroll(scroll)
        XCTAssertEqual(nextSymbol.frame.midX, initialX, accuracy: 3, "Another rightward drag at the start must remain at the boundary")
        screenshot("scroll-symbol-bar-drag")
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

    func testOverlaySwitchesAndColors() {
        openDetail()
        element("stockDetail.navbar.debug").tap()
        elementByLabel("简体中文").tap()
        let originalReversed = element("debug.marketColors.greenUp").isSelected
        addTeardownBlock { [weak self] in self?.restoreMarketColor(originalReversed) }
        element("debug.marketColors.redUp").tap()
        element("stockDetail.debug.done").tap()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        element("stockDetail.chart.period.day").tap()
        waitForState(canvas, key: "period", value: "day")
        // On narrower screens the MA legend wraps to a second translucent
        // band over the plot. Fold it so the overlay pixels are not obscured
        // by a separate, independently tested layer.
        let legend = element("stockDetail.chart.indicatorFold")
        if legend.label == "收起指标" { legend.tap() }
        let folded = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "展开指标"), object: legend)
        XCTAssertEqual(XCTWaiter.wait(for: [folded], timeout: 5), .completed, "Indicator legend should fold before overlay pixel checks")

        // Isolate the overlays so that each screenshot comparison tests only
        // the corresponding switch, even when other chart content shares colors.
        setChartAnnotations(["buySellPoint": false, "currentPrice": false, "cost": false,
                             "priceAlert": false, "corporate": false])
        waitForState(canvas, key: "annotations", value: "00000")
        let baseline = canvas.screenshot().image
        XCTAssertEqual(corporateButtons().count, 0)

        setChartAnnotations(["cost": true])
        waitForState(canvas, key: "annotations", value: "00100")
        let cost = canvas.screenshot().image
        assertOverlayPixels(baseline, cost, colors: [(255, 166, 80)], subject: "Cost", canvasWidth: canvas.frame.width)

        setChartAnnotations(["cost": false, "priceAlert": true])
        waitForState(canvas, key: "annotations", value: "00010")
        let alerts = canvas.screenshot().image
        assertOverlayPixels(baseline, alerts, colors: [(255, 51, 102), (80, 213, 227)], subject: "Alerts", canvasWidth: canvas.frame.width)

        setChartAnnotations(["priceAlert": false, "currentPrice": true])
        waitForState(canvas, key: "annotations", value: "01000")
        assertOverlayPixels(baseline, canvas.screenshot().image, colors: [(25, 110, 255)], subject: "Current price", canvasWidth: canvas.frame.width, expectsIcon: false)

        showDebug()
        element("debug.marketColors.greenUp").tap()
        element("stockDetail.debug.done").tap()
        showChart()
        waitForState(canvas, key: "reversed", value: "true")
        setChartAnnotations(["currentPrice": false])
        let reversedBaseline = canvas.screenshot().image
        setChartAnnotations(["cost": true])
        assertOverlayPixels(reversedBaseline, canvas.screenshot().image, colors: [(255, 166, 80)], subject: "Cost reversed", canvasWidth: canvas.frame.width)
        setChartAnnotations(["cost": false, "priceAlert": true])
        assertOverlayPixels(reversedBaseline, canvas.screenshot().image, colors: [(255, 51, 102), (80, 213, 227)], subject: "Alerts reversed", canvasWidth: canvas.frame.width)

    }

    func testIntradayHasNoPersistentPriceLegendAndRetainsSelection() {
        openDetail()
        element("stockDetail.navbar.debug").tap()
        elementByLabel("简体中文").tap()
        element("stockDetail.debug.done").tap()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        for period in ["intraday", "fiveDays"] {
            element("stockDetail.chart.period.\(period)").tap()
            waitForState(canvas, key: "period", value: period)
            let screenshot = canvas.screenshot().image
            guard let pixels = rgba(screenshot) else { XCTFail("Could not read \(period) chart screenshot"); return }
            let scale = CGFloat(pixels.width) / canvas.frame.width
            var legendColoredPixels = 0
            // Ignore the left and right axis labels and the grid at the top.
            // A 20% price-range margin keeps the plotted lines below this band;
            // saturated blue/orange pixels here would be the old legend text.
            let minX = Int(24 * scale), maxX = pixels.width - Int(28 * scale)
            for y in Int(3 * scale)..<Int(16 * scale) {
                for x in minX..<maxX {
                    let i = (y * pixels.width + x) * 4
                    let r = Int(pixels.pixels[i]), g = Int(pixels.pixels[i + 1]), b = Int(pixels.pixels[i + 2])
                    if (b > r + 50 && b > g + 30) || (r > g + 25 && g > b + 40) { legendColoredPixels += 1 }
                }
            }
            XCTAssertLessThan(legendColoredPixels, 10, "\(period) must not show a persistent price/average legend")
            attachImage(screenshot, name: "chart-\(period)-without-price-legend")
            canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.55, dy: 0.4)).press(forDuration: 0.7)
            let selection = element("stockDetail.chart.selection")
            XCTAssertTrue(selection.staticTexts["价格"].firstMatch.exists)
            XCTAssertTrue(selection.staticTexts["均价"].firstMatch.exists)
        }
    }

    func testCorporateActionsAndTabs() {
        openDetail()
        element("stockDetail.navbar.debug").tap()
        elementByLabel("简体中文").tap()
        element("stockDetail.debug.done").tap()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        element("stockDetail.chart.period.day").tap()
        waitForState(canvas, key: "period", value: "day")
        setChartAnnotations(["corporate": true])
        let dayMarkers = corporateButtons().allElementsBoundByIndex
        guard let earning = dayMarkers.first(where: { $0.label.contains("业绩公布") }) else {
            XCTFail("The daily chart should expose an earnings marker"); return
        }
        let hierarchy = XCTAttachment(string: "marker=\(earning.frame), hittable=\(earning.isHittable), canvas=\(canvas.frame), window=\(app.windows.firstMatch.frame)\n\(app.debugDescription)")
        hierarchy.name = "corporate-marker-accessibility"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        let markerHittable = earning.isHittable
        if markerHittable {
            earning.tap()
        } else {
            let offset = CGVector(dx: earning.frame.midX - canvas.frame.minX, dy: earning.frame.midY - canvas.frame.minY)
            canvas.coordinate(withNormalizedOffset: .zero).withOffset(offset).tap()
        }
        let daySheet = app.descendants(matching: .any)["stockDetail.chart.corporate.sheet"].firstMatch
        if !daySheet.waitForExistence(timeout: 8) {
            let afterTap = XCTAttachment(string: app.debugDescription)
            afterTap.name = "corporate-after-tap-accessibility"
            afterTap.lifetime = .keepAlways
            add(afterTap)
            XCTFail("Company action sheet must appear after tapping the marker")
            return
        }
        XCTAssertTrue(markerHittable, "Daily earnings marker must also be directly hittable through accessibility")
        XCTAssertTrue(element("stockDetail.chart.corporate.currency").exists)
        for value in ["2026/Q4", "2.10", "114.5B"] {
            XCTAssertTrue(daySheet.staticTexts[value].firstMatch.exists, "Missing daily earnings value \(value)")
        }
        dismissSheet(daySheet)

        // The real AAPL fixture has earnings and ex-dividend events in May 2025.
        // They share a monthly marker and should open two selectable tabs.
        element("stockDetail.chart.period.month").tap()
        waitForState(canvas, key: "period", value: "month")
        let monthMarkers = corporateButtons().allElementsBoundByIndex
        guard let combined = monthMarkers.first(where: { $0.label.contains("业绩公布") && $0.label.contains("分红派息") }) else {
            XCTFail("Monthly chart should expose a combined earnings/dividend marker"); return
        }
        XCTAssertTrue(combined.isHittable, "Combined marker must be tappable")
        combined.tap()
        let sheet = element("stockDetail.chart.corporate.sheet")
        XCTAssertTrue(sheet.buttons["业绩公布"].firstMatch.exists)
        XCTAssertTrue(element("stockDetail.chart.corporate.currency").exists)
        XCTAssertTrue(sheet.staticTexts["2025/Q2"].firstMatch.exists)
        sheet.buttons["分红派息"].firstMatch.tap()
        XCTAssertFalse(app.descendants(matching: .any)["stockDetail.chart.corporate.currency"].exists)
        XCTAssertTrue(sheet.staticTexts["0.26 USD"].firstMatch.exists)
        XCTAssertTrue(sheet.staticTexts["2025/05/12"].firstMatch.exists)
        sheet.buttons["业绩公布"].firstMatch.tap()
        XCTAssertTrue(element("stockDetail.chart.corporate.currency").exists)
        dismissSheet(sheet)
        setChartAnnotations(["corporate": false])
        XCTAssertEqual(corporateButtons().count, 0)
    }

    func testTradeMarkerDetailsAndOrders() {
        openDetail()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        element("stockDetail.chart.period.day").tap()
        waitForState(canvas, key: "period", value: "day")
        setChartAnnotations(["buySellPoint": true, "corporate": false])
        let start = integerState(canvas, "start"), count = integerState(canvas, "count")
        // Last 18th, 12th, and 4th candles carry B, T, and S mock markers.
        let end = start + count
        for (index, rows) in [(end - 18, 1), (end - 12, 2), (end - 4, 1)] {
            let fraction = (Double(index - start) + 0.5) / Double(count)
            canvas.coordinate(withNormalizedOffset: CGVector(dx: fraction, dy: 0.35)).press(forDuration: 0.7)
            waitForState(canvas, key: "selected", value: String(index))
            XCTAssertTrue(element("stockDetail.chart.selection.tradeMarks").exists)
            let button = element("stockDetail.chart.selection.orders")
            XCTAssertTrue(button.label.contains("(\(rows))"))
            button.tap()
            let sheet = element("stockDetail.chart.mockOrders.sheet")
            XCTAssertTrue(element("stockDetail.chart.mockOrder.\(index == end - 4 ? 1 : 0)").exists)
            if rows == 2 { XCTAssertTrue(element("stockDetail.chart.mockOrder.1").exists) }
            element("stockDetail.chart.settings.done").tap()
            let absent = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: sheet)
            XCTAssertEqual(XCTWaiter.wait(for: [absent], timeout: 5), .completed)
        }
        setChartAnnotations(["buySellPoint": false])
        let fraction = (Double(end - 12 - start) + 0.5) / Double(count)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: fraction, dy: 0.35)).press(forDuration: 0.7)
        waitForState(canvas, key: "selected", value: String(end - 12))
        XCTAssertFalse(app.descendants(matching: .any)["stockDetail.chart.selection.orders"].exists)
    }

    func testIntradayTradeMarkerDetailsInEnglish() {
        openDetail()
        element("stockDetail.navbar.debug").tap()
        elementByLabel("English").tap()
        element("stockDetail.debug.done").tap()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        waitForState(canvas, key: "period", value: "intraday")
        setChartAnnotations(["buySellPoint": true])
        let start = integerState(canvas, "start"), count = integerState(canvas, "count")
        let end = start + count
        for (index, rows) in [(end - 300, 1), (end - 180, 2), (end - 100, 1)] {
            let fraction = (Double(index - start) + 0.5) / Double(count)
            canvas.coordinate(withNormalizedOffset: CGVector(dx: fraction, dy: 0.35)).press(forDuration: 0.7)
            waitForState(canvas, key: "selected", value: String(index))
            let button = element("stockDetail.chart.selection.orders")
            XCTAssertTrue(button.label.contains("Details"))
            XCTAssertTrue(button.label.contains("(\(rows))"))
            if rows == 2 {
                button.tap()
                _ = element("stockDetail.chart.mockOrders.sheet")
                XCTAssertTrue(app.staticTexts["Sample Orders"].exists)
                XCTAssertTrue(element("stockDetail.chart.mockOrder.0").exists)
                XCTAssertTrue(element("stockDetail.chart.mockOrder.1").exists)
                element("stockDetail.chart.settings.done").tap()
            }
        }
        let noMarker = end - 250
        let fraction = (Double(noMarker - start) + 0.5) / Double(count)
        canvas.coordinate(withNormalizedOffset: CGVector(dx: fraction, dy: 0.35)).press(forDuration: 0.7)
        waitForState(canvas, key: "selected", value: String(noMarker))
        XCTAssertFalse(app.descendants(matching: .any)["stockDetail.chart.selection.orders"].exists)
        showDebug()
        elementByLabel("简体中文").tap()
        element("stockDetail.debug.done").tap()
    }

    func testTradeMarkerAssetsFollowMarketColors() {
        openDetail()
        element("stockDetail.navbar.debug").tap()
        let reversed = element("debug.marketColors.greenUp").isSelected
        addTeardownBlock { [weak self] in self?.restoreMarketColor(reversed) }
        element("debug.marketColors.redUp").tap()
        element("stockDetail.debug.done").tap()
        showChart()
        let canvas = element("stockDetail.chart.canvas")
        element("stockDetail.chart.period.day").tap()
        waitForState(canvas, key: "period", value: "day")
        setChartAnnotations(["buySellPoint": false, "corporate": false])
        let redWithout = canvas.screenshot().image
        setChartAnnotations(["buySellPoint": true])
        let redWith = canvas.screenshot().image
        showDebug()
        element("debug.marketColors.greenUp").tap()
        element("stockDetail.debug.done").tap()
        showChart()
        waitForState(canvas, key: "reversed", value: "true")
        let greenWith = canvas.screenshot().image
        setChartAnnotations(["buySellPoint": false])
        let greenWithout = canvas.screenshot().image
        assertMarkerColorsSwap(redWithout, redWith, greenWithout, greenWith)
    }

    private func assertMarkerColorsSwap(_ redOff: UIImage, _ redOn: UIImage, _ greenOff: UIImage, _ greenOn: UIImage) {
        guard let a = rgba(redOff), let b = rgba(redOn), let c = rgba(greenOff), let d = rgba(greenOn),
              a.width == b.width, b.width == c.width, c.width == d.width,
              a.height == b.height, b.height == c.height, c.height == d.height else {
            XCTFail("Unable to compare trade marker images"); return
        }
        var redToGreen = 0, greenToRed = 0
        for i in stride(from: 0, to: a.pixels.count, by: 4) {
            let changedRed = (0..<3).contains { abs(Int(a.pixels[i + $0]) - Int(b.pixels[i + $0])) > 20 }
            let changedGreen = (0..<3).contains { abs(Int(c.pixels[i + $0]) - Int(d.pixels[i + $0])) > 20 }
            guard changedRed && changedGreen else { continue }
            let br = Int(b.pixels[i]), bg = Int(b.pixels[i + 1]), bb = Int(b.pixels[i + 2])
            let dr = Int(d.pixels[i]), dg = Int(d.pixels[i + 1]), db = Int(d.pixels[i + 2])
            if br > bg + 35 && br > bb + 35 && dg > dr + 35 && dg > db + 10 { redToGreen += 1 }
            if bg > br + 35 && bg > bb + 10 && dr > dg + 35 && dr > db + 35 { greenToRed += 1 }
        }
        XCTAssertGreaterThan(redToGreen, 5, "Buy marker should change from red to green")
        XCTAssertGreaterThan(greenToRed, 5, "Sell marker should change from green to red")
        attachImage(redOn, name: "chart-markers-red-up")
        attachImage(greenOn, name: "chart-markers-green-up")
    }

    private func corporateButtons() -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "stockDetail.chart.corporate."))
    }

    private func setChartAnnotations(_ values: [String: Bool]) {
        element("stockDetail.chart.settings").tap()
        element("stockDetail.chart.settings.labels").tap()
        for (name, enabled) in values.sorted(by: { $0.key < $1.key }) {
            let control = element("stockDetail.chart.labels.\(name)")
            let expected = enabled ? "1" : "0"
            if control.value as? String != expected { control.tap() }
            XCTAssertEqual(control.value as? String, expected, "Unexpected annotation setting \(name)")
        }
        element("stockDetail.chart.labels.back").tap()
    }

    private func assertOverlayPixels(_ before: UIImage, _ after: UIImage, colors: [(Int, Int, Int)], subject: String, canvasWidth: CGFloat, expectsIcon: Bool = true) {
        guard let a = rgba(before), let b = rgba(after), a.width == b.width, a.height == b.height else {
            XCTFail("Unable to compare \(subject) images"); return
        }
        let scale = CGFloat(b.width) / canvasWidth
        for (red, green, blue) in colors {
            var line = 0
            var rowCounts = [Int](repeating: 0, count: b.height)
            for y in 0..<b.height {
                for x in 0..<b.width {
                    let i = (y * b.width + x) * 4
                    let changed = (0..<3).contains { abs(Int(a.pixels[i + $0]) - Int(b.pixels[i + $0])) > 20 }
                    let near = abs(Int(b.pixels[i]) - red) < 45 && abs(Int(b.pixels[i + 1]) - green) < 45 && abs(Int(b.pixels[i + 2]) - blue) < 45
                    guard changed && near else { continue }
                    let pt = CGFloat(x) / scale
                    if pt >= 55 && pt < canvasWidth - 10 { line += 1; rowCounts[y] += 1 }
                }
            }
            XCTAssertGreaterThan(line, 20, "\(subject) should render its colored line")
            let lineY = rowCounts.indices.max(by: { rowCounts[$0] < rowCounts[$1] }) ?? 0
            let plotStart = Int(55 * scale), plotEnd = min(b.width, Int((canvasWidth - 10) * scale))
            let substantialRows = rowCounts.filter { $0 > (plotEnd - plotStart) / 5 }.count
            XCTAssertLessThanOrEqual(substantialRows, Int((2 * scale).rounded(.up)) + 1,
                                     "\(subject) line should remain approximately 1pt thick")
            var runs: [(on: Bool, length: Int)] = []
            for x in plotStart..<plotEnd {
                let i = (lineY * b.width + x) * 4
                let changed = (0..<3).contains { abs(Int(a.pixels[i + $0]) - Int(b.pixels[i + $0])) > 20 }
                let near = abs(Int(b.pixels[i]) - red) < 45 && abs(Int(b.pixels[i + 1]) - green) < 45 && abs(Int(b.pixels[i + 2]) - blue) < 45
                let on = changed && near
                if let last = runs.last, last.on == on { runs[runs.count - 1].length += 1 }
                else { runs.append((on, 1)) }
            }
            let typical = runs.filter { CGFloat($0.length) >= 2.5 * scale && CGFloat($0.length) <= 5.5 * scale }
            XCTAssertGreaterThanOrEqual(typical.filter(\.on).count, 3, "\(subject) should have repeated 4pt dashes")
            XCTAssertGreaterThanOrEqual(typical.filter { !$0.on }.count, 3, "\(subject) should have repeated 4pt gaps")
            var iconOffLine = 0
            for y in 0..<b.height where abs(y - lineY) > Int(scale.rounded(.up)) {
                for x in Int(35 * scale)..<min(b.width, Int(47 * scale)) {
                    let i = (y * b.width + x) * 4
                    let changed = (0..<3).contains { abs(Int(a.pixels[i + $0]) - Int(b.pixels[i + $0])) > 20 }
                    let near = abs(Int(b.pixels[i]) - red) < 45 && abs(Int(b.pixels[i + 1]) - green) < 45 && abs(Int(b.pixels[i + 2]) - blue) < 45
                    if changed && near { iconOffLine += 1 }
                }
            }
            if expectsIcon {
                XCTAssertGreaterThan(iconOffLine, 10, "\(subject) should render its 12pt icon at 35pt")
            } else {
                XCTAssertEqual(iconOffLine, 0, "\(subject) must not render an icon")
            }
        }
        attachImage(after, name: "chart-overlay-\(subject)")
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
        // A restored detail can appear after the tab and watchlist have already
        // entered the accessibility tree. Dismiss it before scrolling the list.
        for _ in 0..<3 where !row.isHittable {
            let back = app.buttons.matching(identifier: "stockDetail.navbar.back").allElementsBoundByIndex.first(where: { $0.isHittable })
            guard let back else { break }
            back.tap()
        }
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

    private func openIndicatorSettings() {
        element("stockDetail.chart.settings").tap()
        _ = element("stockDetail.chart.settings.sheet")
        element("stockDetail.chart.settings.indicators").tap()
        _ = element("stockDetail.chart.indicators.sheet")
    }

    private func dismissIndicatorSettings() {
        dismissSheet(element("stockDetail.chart.indicators.sheet"))
    }

    private func dismissSheet(_ sheet: XCUIElement) {
        let start = sheet.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.03))
        start.press(forDuration: 0.05, thenDragTo: start.withOffset(CGVector(dx: 0, dy: 500)))
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: sheet)
        XCTAssertEqual(XCTWaiter.wait(for: [dismissed], timeout: 5), .completed, "Sheet should dismiss after a downward drag")
    }

    private func setIndicatorVisibility(_ identifier: String, from initial: String, to expected: String) {
        let control = app.buttons[identifier].firstMatch
        XCTAssertTrue(control.waitForExistence(timeout: 8), "Missing indicator visibility control: \(identifier)")
        let window = app.windows.firstMatch
        for _ in 0..<6 {
            let frame = control.frame
            if control.isHittable && frame.midY > window.frame.minY + 40 && frame.midY < window.frame.maxY - 40 { break }
            if frame.midY < window.frame.midY { app.swipeDown() } else { app.swipeUp() }
        }
        XCTAssertTrue(control.isHittable, "Indicator control should be visible: \(identifier)")
        XCTAssertEqual(control.value as? String, initial, "Unexpected initial value for \(identifier)")
        control.tap()
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", expected), object: control)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 5), .completed,
                       "Indicator visibility did not change to \(expected): \(identifier)")
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

    private func assertVerticalScrollFromChart(_ canvas: XCUIElement, in scroll: XCUIElement) {
        let initialY = canvas.frame.minY
        dragVerticallyFromChart(canvas, in: scroll, distance: -90)
        let movedUp = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            canvas.frame.minY < initialY - 20
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [movedUp], timeout: 5), .completed, "Dragging upward from the chart should scroll the page")

        let scrolledY = canvas.frame.minY
        dragVerticallyFromChart(canvas, in: scroll, distance: 90)
        let movedDown = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            canvas.frame.minY > scrolledY + 20
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [movedDown], timeout: 5), .completed, "Dragging downward from the chart should scroll the page")
    }

    @discardableResult private func shortPageDrag(_ canvas: XCUIElement, in viewport: XCUIElement,
                                                 outsideChart: Bool, dx: CGFloat, dy: CGFloat) -> CGFloat {
        let window = app.windows.firstMatch
        let visible = canvas.frame.intersection(viewport.frame).intersection(window.frame.insetBy(dx: 0, dy: 100))
        XCTAssertGreaterThan(visible.height, 100)
        let point = CGPoint(x: outsideChart ? viewport.frame.minX + 6 : visible.midX, y: visible.midY)
        let origin = window.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: point.x, dy: point.y))
        let before = canvas.frame.minY
        origin.press(forDuration: 0.01, thenDragTo: origin.withOffset(CGVector(dx: dx, dy: dy)),
                     withVelocity: XCUIGestureVelocity(rawValue: 100), thenHoldForDuration: 0.2)
        return before - canvas.frame.minY
    }

    private func dragVerticallyFromChart(_ canvas: XCUIElement, in viewport: XCUIElement, distance: CGFloat) {
        let window = app.windows.firstMatch
        let usable = viewport.frame.intersection(window.frame.insetBy(dx: 0, dy: 55))
        let visible = canvas.frame.intersection(usable)
        XCTAssertGreaterThan(visible.height, 40, "Chart must have a visible area for the drag")
        let origin = window.coordinate(withNormalizedOffset: .zero).withOffset(
            CGVector(dx: visible.midX - window.frame.minX, dy: visible.midY - window.frame.minY)
        )
        origin.press(forDuration: 0.05, thenDragTo: origin.withOffset(CGVector(dx: 0, dy: distance)))
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

    private func assertPixelDifference(_ first: UIImage, _ second: UIImage, subject: String) {
        guard let a = rgba(first), let b = rgba(second), a.width == b.width, a.height == b.height else {
            XCTFail("Unable to compare \(subject) screenshots with matching dimensions")
            return
        }
        var changed = 0
        for i in stride(from: 0, to: a.pixels.count, by: 4) {
            if (0..<3).contains(where: { abs(Int(a.pixels[i + $0]) - Int(b.pixels[i + $0])) > 20 }) {
                changed += 1
            }
        }
        XCTAssertGreaterThan(changed, 10, "\(subject) should change the rendered chart")
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
