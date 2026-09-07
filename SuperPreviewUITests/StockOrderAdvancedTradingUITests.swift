import XCTest

final class StockOrderAdvancedTradingUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()
        app.launchArguments += [
            "-UITesting",
            "-UIPreferredContentSizeCategory",
            "UICTContentSizeCategoryL"
        ]
        app.launchEnvironment["UITEST_MODE"] = "1"
        app.launchEnvironment["UITEST_RESET_HIGH_FREQUENCY_TRADING"] = "1"
        app.launch()
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
        try super.tearDownWithError()
    }

    func testAdvancedTradingViewsSwitchAsPeersAndKeepOrderEntry() throws {
        enterStockOrder()

        let toolbar = waitFor("stockOrder.advancedTrading.toolbar")
        XCTAssertTrue(waitFor("stockOrder.advancedTrading.section.trade").isSelected)

        waitFor("stockOrder.advancedTrading.section.market").tap()
        XCTAssertTrue(waitFor("stockDetail.page").exists)
        XCTAssertTrue(toolbar.exists)

        waitFor("stockOrder.advancedTrading.section.orders").tap()
        XCTAssertTrue(waitFor("todayOrders.page").exists)
        XCTAssertTrue(waitFor("todayOrders.header").exists)

        waitFor("stockOrder.advancedTrading.section.positions").tap()
        XCTAssertTrue(waitFor("stockOrder.advancedTrading.positions").exists)

        waitFor("stockOrder.advancedTrading.section.trade").tap()
        XCTAssertTrue(waitFor("stockOrder.demo").exists)
        XCTAssertTrue(waitFor("stockOrder.symbolInput.selectedSymbol").exists)
    }

    func testAdvancedTradingEdgeSwipeFromPositionsReturnsToOuterEntry() throws {
        enterStockOrder()

        waitFor("stockOrder.advancedTrading.section.orders").tap()
        XCTAssertTrue(waitFor("todayOrders.page").exists)

        waitFor("stockOrder.advancedTrading.section.positions").tap()
        XCTAssertTrue(waitFor("stockOrder.advancedTrading.positions").exists)

        performHorizontalDrag(fromX: 0.01, toX: 0.82)
        XCTAssertTrue(waitFor("compare.componentLibrary").exists)
    }

    func testAdvancedTradingToolBarFollowsSymbolSelection() throws {
        enterStockOrder()

        let toolbar = waitFor("stockOrder.advancedTrading.toolbar")
        waitFor("stockOrder.symbolInput.selectedSymbol").doubleTap()

        let gone = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: toolbar
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [gone], timeout: 5),
            .completed,
            "The advanced trading tool should disappear after the symbol is cleared"
        )
        selectAlibaba()
        XCTAssertTrue(waitFor("stockOrder.advancedTrading.toolbar").exists)
        XCTAssertTrue(waitFor("stockOrder.advancedTrading.section.trade").isSelected)
    }

    func testToolsDefaultOffAndRequireSelectedSymbol() throws {
        enterStockOrder(enableTools: false, selectSymbol: false)
        waitFor("stockOrder.navbar.debug").tap()
        XCTAssertEqual(waitFor("stockOrder.debug.highFrequencyTrading").value as? String, "0")
        waitFor("stockOrder.debug.close").tap()
        assertGone("stockOrder.advancedTrading.toolbar")

        setToolsEnabled(true)
        assertGone("stockOrder.advancedTrading.toolbar")
        selectAlibaba()
        XCTAssertTrue(waitFor("stockOrder.advancedTrading.toolbar").exists)
        setToolsEnabled(false)
        assertGone("stockOrder.advancedTrading.toolbar")
        XCTAssertTrue(waitFor("stockOrder.symbolInput.selectedSymbol").exists)
        XCTAssertTrue(waitFor("stockOrder.tradeActionBar.buy").isHittable)
    }

    func testToolsPreferencePersistsAcrossPageEntryAndAppRelaunch() throws {
        enterStockOrder()
        waitFor("stockOrder.navbar.back").tap()
        enterStockOrder(enableTools: false)
        XCTAssertTrue(waitFor("stockOrder.advancedTrading.toolbar").exists)

        app.terminate()
        app.launchEnvironment.removeValue(forKey: "UITEST_RESET_HIGH_FREQUENCY_TRADING")
        app.launch()
        enterStockOrder(enableTools: false)
        XCTAssertTrue(waitFor("stockOrder.advancedTrading.toolbar").exists)
        setToolsEnabled(false)

        app.terminate()
        app.launch()
        enterStockOrder(enableTools: false)
        assertGone("stockOrder.advancedTrading.toolbar")
        waitFor("stockOrder.navbar.debug").tap()
        XCTAssertEqual(waitFor("stockOrder.debug.highFrequencyTrading").value as? String, "0")
    }

    func testTradeEdgeSwipeExitsTheWholePage() throws {
        assertEdgeSwipeExits(section: "trade")
    }

    func testMarketEdgeSwipeExitsTheWholePage() throws {
        assertEdgeSwipeExits(section: "market")
    }

    func testOrdersEdgeSwipeExitsTheWholePage() throws {
        assertEdgeSwipeExits(section: "orders")
    }

    func testPositionsEdgeSwipeExitsTheWholePage() throws {
        assertEdgeSwipeExits(section: "positions")
    }

    func testTradeNavbarBackExitsTheWholePage() throws {
        assertNavbarBackExits(section: "trade")
    }

    func testMarketNavbarBackExitsTheWholePage() throws {
        assertNavbarBackExits(section: "market")
    }

    func testOrdersNavbarBackExitsTheWholePage() throws {
        assertNavbarBackExits(section: "orders")
    }

    func testPositionsNavbarBackExitsTheWholePage() throws {
        assertNavbarBackExits(section: "positions")
    }

    func testToolbarPositionAndActionBarGapStayConstantAcrossPeers() throws {
        enterStockOrder()
        let initialFrame = waitFor("stockOrder.advancedTrading.toolbar").frame
        let tradeFrame = waitFor("stockOrder.tradeActionBar").frame
        // XCUITest reports the inner content bounds of the glass surfaces.
        // Expand those bounds by the component insets before asserting the
        // visible geometry from the design.
        let initialSurfaceFrame = initialFrame.insetBy(dx: 0, dy: -3)
        let tradeSurfaceFrame = tradeFrame.insetBy(dx: 0, dy: -8)
        XCTAssertEqual(initialSurfaceFrame.height, 40, accuracy: 1)
        XCTAssertEqual(
            tradeSurfaceFrame.minY - initialSurfaceFrame.maxY,
            8,
            accuracy: 1
        )

        for section in ["market", "orders", "positions", "trade"] {
            waitFor("stockOrder.advancedTrading.section.\(section)").tap()
            let frame = waitFor("stockOrder.advancedTrading.toolbar").frame
            XCTAssertEqual(frame.minY, initialFrame.minY, accuracy: 1)
            XCTAssertEqual(frame.height, initialFrame.height, accuracy: 1)
            if section == "market" {
                waitFor("stockDetail.page")
                // The shuffle button is a stable child of the quote action
                // surface; the parent glass container is not consistently
                // exposed by Xcode 27's accessibility snapshot.
                let quoteFrame = waitFor("stockDetail.bottomActionBar.shuffle").frame
                let quoteSurfaceFrame = quoteFrame.insetBy(dx: 0, dy: -8)
                XCTAssertEqual(quoteSurfaceFrame.minY - initialSurfaceFrame.maxY, 8, accuracy: 1)
                XCTAssertEqual(quoteSurfaceFrame.maxY, tradeSurfaceFrame.maxY, accuracy: 1)
                XCTAssertTrue(waitFor("stockDetail.bottomActionBar.shuffle").isHittable)
            }
        }
        XCTAssertTrue(waitFor("stockOrder.tradeActionBar.buy").isHittable)
        setToolsEnabled(false)
        XCTAssertEqual(waitFor("stockOrder.tradeActionBar").frame.maxY, tradeFrame.maxY, accuracy: 1)
    }

    func testSingleInstrumentShuffleCanCloseAndExitThroughCurrentCard() throws {
        enterStockOrder()
        waitFor("stockOrder.advancedTrading.section.market").tap()
        for exit in ["stockDetail.shuffle.close", "stockDetail.shuffle.card.current"] {
            waitFor("stockDetail.bottomActionBar.shuffle").tap()
            XCTAssertTrue(waitFor("stockDetail.shuffle.root").exists)
            XCTAssertTrue(waitFor("stockDetail.shuffle.committedInstrument").label.contains("09988"))
            waitFor(exit).tap()
            assertGone("stockDetail.shuffle.root")
            XCTAssertTrue(waitFor("stockOrder.advancedTrading.section.market").isSelected)
            XCTAssertTrue(waitFor("stockDetail.bottomActionBar.shuffle").isHittable)
        }
    }

    func testRapidSwitchingPreservesOrderExpansionAndStickyHeader() throws {
        enterStockOrder()
        let price = waitFor("stockOrder.debug.status.price").label
        waitFor("stockOrder.advancedTrading.section.orders").tap()
        waitFor("stockOrder.todayOrder.summary").tap()
        XCTAssertTrue(waitFor("stockOrder.todayOrder.actions").exists)
        for section in ["market", "positions", "trade", "orders", "trade", "orders"] {
            waitFor("stockOrder.advancedTrading.section.\(section)").tap()
        }
        XCTAssertTrue(waitFor("stockOrder.advancedTrading.section.orders").isSelected)
        XCTAssertTrue(waitFor("stockOrder.todayOrder.actions").exists)
        let headerY = waitFor("todayOrders.header").frame.minY
        app.scrollViews["todayOrders.scroll"].swipeUp()
        XCTAssertEqual(waitFor("todayOrders.header").frame.minY, headerY, accuracy: 1)
        waitFor("stockOrder.advancedTrading.section.trade").tap()
        XCTAssertEqual(waitFor("stockOrder.debug.status.price").label, price)
        XCTAssertTrue(waitFor("stockOrder.symbolInput.selectedSymbol").exists)
    }

    func testMiniChartSeriesSurvivesWatchlistDetailOrderAndAdvancedShuffle() throws {
        waitFor("mainTab.tab1").tap()
        let cases = [
            ("港股", "hk:09988", false),
            ("港股", "hk:00700", false),
            ("港股", "hk:01810", true),
            ("美股", "us:NVDA", false),
            ("ETFs", "hk:03032", false),
            ("沪深", "cn:300750", false),
            ("自定义", "crypto:BTC/USD", false)
        ]
        for (tab, id, isFlat) in cases {
            waitFor("watchlist.tab.\(tab)").tap()
            let row = waitFor("watchlist.row.\(id)")
            for _ in 0..<6 where !row.isHittable {
                app.scrollViews.firstMatch.swipeUp()
            }
            let points = waitFor("watchlist.debug.miniKPoints.\(id)").label
            XCTAssertFalse(points.isEmpty)
            XCTAssertEqual(Set(points.split(separator: ",")).count == 1, isFlat)
            row.tap()
            waitFor("stockDetail.bottomActionBar.trade").tap()
            XCTAssertEqual(waitFor("stockOrder.debug.status.miniKPoints").label, points)
            setToolsEnabled(true)
            waitFor("stockOrder.advancedTrading.section.market").tap()
            waitFor("stockDetail.bottomActionBar.shuffle").tap()
            waitFor("stockDetail.shuffle.close").tap()
            waitFor("stockOrder.advancedTrading.section.trade").tap()
            XCTAssertEqual(waitFor("stockOrder.debug.status.miniKPoints").label, points)
            waitFor("stockOrder.navbar.back").tap()
            waitFor("stockDetail.navbar.back").tap()
        }
    }

    private func enterStockOrder(enableTools: Bool = true, selectSymbol: Bool = true) {
        waitFor("mainTab.tab6").tap()
        XCTAssertTrue(waitFor("compare.componentLibrary").exists)
        waitFor("compare.stockOrder").tap()
        XCTAssertTrue(waitFor("stockOrder.demo").exists)

        if enableTools {
            setToolsEnabled(true)
        }
        guard selectSymbol else { return }

        selectAlibaba()
    }

    private func assertEdgeSwipeExits(section: String) {
        enterStockOrder()
        waitFor("stockOrder.advancedTrading.section.\(section)").tap()
        performHorizontalDrag(fromX: 0.01, toX: 0.82)
        XCTAssertTrue(waitFor("compare.componentLibrary").isHittable)
    }

    private func assertNavbarBackExits(section: String) {
        enterStockOrder()
        waitFor("stockOrder.advancedTrading.section.\(section)").tap()
        waitFor(section == "market" ? "stockDetail.navbar.back" : "stockOrder.navbar.back").tap()
        XCTAssertTrue(waitFor("compare.componentLibrary").isHittable)
    }

    private func selectAlibaba() {
        waitFor("stockOrder.symbolInput.emptyField").tap()
        let query = app.textFields["stockOrder.symbolSearchSheet.searchBox"].firstMatch
        XCTAssertTrue(query.waitForExistence(timeout: 8), "Missing stock search field")
        query.tap()
        query.typeText("09988")
        waitFor("stockOrder.symbolSearchSheet.result.09988").tap()

        XCTAssertTrue(waitFor("stockOrder.symbolInput.selectedSymbol").exists)
    }

    private func setToolsEnabled(_ enabled: Bool) {
        waitFor("stockOrder.navbar.debug").tap()
        let toggle = waitFor("stockOrder.debug.highFrequencyTrading")
        let expected = enabled ? "1" : "0"
        if toggle.value as? String != expected {
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        waitForSwitchValue(toggle, expected: expected)
        waitFor("stockOrder.debug.close").tap()
        assertGone("stockOrder.debug.panel")
    }

    private func waitForSwitchValue(
        _ toggle: XCUIElement,
        expected: String,
        timeout: TimeInterval = 5
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", expected),
            object: toggle
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout),
            .completed,
            "Switch did not update to value \(expected)"
        )
    }

    private func assertGone(_ identifier: String) {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 5), .completed)
    }

    private func performHorizontalDrag(fromX: CGFloat, toX: CGFloat) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 3), "Missing application window")

        let start = window.coordinate(
            withNormalizedOffset: CGVector(dx: fromX, dy: 0.5)
        )
        let end = window.coordinate(
            withNormalizedOffset: CGVector(dx: toX, dy: 0.5)
        )
        start.press(forDuration: 0.01, thenDragTo: end)
    }

    @discardableResult
    private func waitFor(
        _ identifier: String,
        timeout: TimeInterval = 8
    ) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Missing element: \(identifier)")
        return element
    }
}
