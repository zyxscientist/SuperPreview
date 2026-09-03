import XCTest

final class TradeLayoutAdaptationUITests: XCTestCase {
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
        app.launch()
    }

    override func tearDown() {
        if (testRun?.failureCount ?? 0) > 0 {
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = "failure-screenshot"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        super.tearDown()
    }

    func testCompareComponentLibraryUsesFullWidthAndNavigates() throws {
        let componentLibrary = waitFor("compare.componentLibrary")
        assertWidth(of: componentLibrary, equals: expectedViewportWidth)

        XCTAssertTrue(waitFor("compare.newWatchlist").isHittable)
        let newTrade = waitFor("compare.newTrade")
        XCTAssertTrue(newTrade.isHittable)

        componentLibrary.swipeUp()
        XCTAssertTrue(waitFor("compare.newTrade").exists)
        let lastComponent = app.staticTexts["Liquid Glass 调研"].firstMatch
        XCTAssertTrue(lastComponent.waitForExistence(timeout: 5))
        XCTAssertTrue(lastComponent.isHittable)

        waitFor("compare.newTrade").tap()
        XCTAssertTrue(waitFor("trade.root").exists)
    }

    func testTradeCategoryCardsMenusAndHoldingViewports() throws {
        enterTrade()

        for category in ["stocks", "funds", "virtualAssets"] {
            let tab = waitFor("trade.categoryTab.\(category)")
            tab.tap()
            let page = waitFor("trade.categoryPage")
            assertWidth(of: page, equals: expectedViewportWidth)
            assertWidth(of: waitFor("trade.subAssetCard"), equals: expectedViewportWidth - 32)
            assertWidth(of: waitFor("trade.quickMenu.inline"), equals: expectedViewportWidth)
            assertWidth(of: waitFor("trade.holdingsViewport"), equals: expectedViewportWidth)
        }
    }

    func testVirtualAssetsOmitTodayProfitLossFields() throws {
        enterTrade()

        waitFor("trade.categoryTab.virtualAssets").tap()

        let card = waitFor("trade.subAssetCard")
        XCTAssertFalse(
            card.descendants(matching: .any)["trade.subAssetCard.profitLoss"].exists,
            "Virtual-asset SubAssetCard must not show today's P/L"
        )
        XCTAssertTrue(
            waitFor("trade.metric.positionProfitLoss").exists,
            "Virtual-asset SubAssetCard must keep position P/L"
        )
        let cryptocurrencyTable = waitFor("trade.virtualTable.cryptocurrency")
        XCTAssertFalse(
            cryptocurrencyTable.descendants(matching: .any)["trade.header.dayProfitLossHeader"].exists,
            "Cryptocurrency holdings must not show a today's P/L column"
        )

        let rwaTable = waitFor("trade.virtualTable.rwa")
        XCTAssertTrue(
            rwaTable.descendants(matching: .any)["trade.header.dayProfitLossHeader"].exists,
            "RWA holdings must keep a today's P/L column"
        )
    }

    func testTradeExpansionHorizontalScrollAndStickyMenu() throws {
        enterTrade()

        let card = waitFor("trade.subAssetCard")
        waitForButton("展开资产详情").tap()
        XCTAssertTrue(waitForButton("收起资产详情").exists)
        assertWidth(of: card, equals: expectedViewportWidth - 32)

        waitForButton("隐藏资产数字").tap()
        XCTAssertTrue(waitForButton("显示资产数字").exists)

        let holdings = waitFor("trade.holdingsViewport")
        let fixedMarketHeader = waitFor("trade.market.hongKong")
        let fixedNameCell = waitForButton("腾讯控股，00700")
        holdings.swipeLeft()
        XCTAssertTrue(fixedMarketHeader.exists)
        XCTAssertTrue(fixedNameCell.exists)
        assertWidth(of: holdings, equals: expectedViewportWidth)

        fixedMarketHeader.tap()
        XCTAssertEqual(fixedMarketHeader.value as? String, "已收起")
        fixedMarketHeader.tap()
        XCTAssertEqual(fixedMarketHeader.value as? String, "已展开")

        let inlineMenu = waitFor("trade.quickMenu.inline")
        let inlineFrame = inlineMenu.frame
        let scroll = app.scrollViews.firstMatch
        XCTAssertTrue(scroll.waitForExistence(timeout: 8), "Missing trade vertical scroll view")
        for _ in 0..<6 where !element("trade.quickMenu.pinned").exists {
            scroll.swipeUp()
        }

        let pinnedMenu = waitFor("trade.quickMenu.pinned")
        XCTAssertEqual(pinnedMenu.frame.minX, inlineFrame.minX, accuracy: 1)
        XCTAssertEqual(pinnedMenu.frame.width, inlineFrame.width, accuracy: 1)

        let holding = waitFor("trade.holding.hk-tencent")
        holding.tap()
        XCTAssertTrue(waitFor("trade.holding.hk-tencent.quote").isHittable)

        let lastHolding = waitFor("trade.holding.us-tesla")
        for _ in 0..<12 where !lastHolding.isHittable {
            scroll.swipeUp()
        }
        XCTAssertTrue(lastHolding.isHittable)
        lastHolding.tap()
        XCTAssertTrue(waitFor("trade.holding.us-tesla.quote").isHittable)
    }

    func testTradeDebugStatesAndLiveRefreshKeepFramesStable() throws {
        enterTrade()

        let baselineCard = waitFor("trade.subAssetCard").frame
        let baselineMenu = waitFor("trade.quickMenu.inline").frame
        let baselineHoldings = waitFor("trade.holdingsViewport").frame

        waitFor("trade.debug.open").tap()
        XCTAssertTrue(waitFor("trade.debug.title").exists)
        waitFor("trade.debug.enableStateMatrix").tap()
        dismissDebugPanel()

        XCTAssertEqual(waitFor("trade.debug.status.summerAd").label, "SUMMER_ENABLED")
        XCTAssertEqual(waitFor("trade.debug.status.mr").label, "MR_ENABLED")
        XCTAssertTrue(waitFor("trade.mrNotice").exists)
        XCTAssertTrue(waitFor("trade.summerAd").exists)
        waitFor("trade.categoryTab.virtualAssets").tap()
        assertWidth(of: waitFor("trade.categoryPage"), equals: expectedViewportWidth)
        assertWidth(of: waitFor("trade.subAssetCard"), equals: expectedViewportWidth - 32)
        assertWidth(of: waitFor("trade.quickMenu.inline"), equals: expectedViewportWidth)
        assertWidth(of: waitFor("trade.holdingsViewport"), equals: expectedViewportWidth)
        XCTAssertTrue(waitFor("trade.mrNotice").exists)
        XCTAssertTrue(waitFor("trade.summerAd").exists)

        waitFor("trade.categoryTab.stocks").tap()
        XCTAssertEqual(waitFor("trade.debug.status.mr").label, "MR_ENABLED")
        XCTAssertTrue(waitFor("trade.mrMaintenance").exists)

        waitFor("trade.debug.open").tap()
        waitFor("trade.debug.enableLiveData").tap()
        XCTAssertEqual(waitFor("trade.debug.status.mr").label, "MR_DISABLED")
        XCTAssertEqual(waitFor("trade.debug.status.liveData").label, "LIVE_ENABLED")
        dismissDebugPanel()

        let cardAfterToggle = waitFor("trade.subAssetCard").frame
        let menuAfterToggle = waitFor("trade.quickMenu.inline").frame
        let holdingsAfterToggle = waitFor("trade.holdingsViewport").frame
        XCTAssertEqual(cardAfterToggle.width, baselineCard.width, accuracy: 1)
        XCTAssertEqual(menuAfterToggle.width, baselineMenu.width, accuracy: 1)
        XCTAssertEqual(holdingsAfterToggle.width, baselineHoldings.width, accuracy: 1)

        // The simulated stream refreshes after 4.5–5.5 seconds. Frames must remain stable.
        sleep(6)
        XCTAssertEqual(waitFor("trade.subAssetCard").frame, cardAfterToggle)
        XCTAssertEqual(waitFor("trade.quickMenu.inline").frame.width, menuAfterToggle.width, accuracy: 1)
        XCTAssertEqual(waitFor("trade.holdingsViewport").frame.width, holdingsAfterToggle.width, accuracy: 1)
    }

    func testTradeAndWatchlistShareThreeLanguageSelection() throws {
        enterTrade()

        openDebugAndSelectLanguage("English")
        XCTAssertTrue(app.navigationBars["New Trade"].waitForExistence(timeout: 5))
        XCTAssertEqual(waitFor("trade.categoryTab.stocks").label, "Stocks")
        XCTAssertEqual(waitFor("trade.metric.securitiesMarketValue").label, "Securities Market Value")
        XCTAssertEqual(waitFor("trade.header.marketValueQuantityHeader").label, "Market Value and Quantity")
        XCTAssertEqual(waitFor("trade.debug.status.marketValueHeader").label, "MKV/Qty")
        XCTAssertTrue(app.staticTexts["Position Details"].exists)

        openDebugAndSelectLanguage("繁體中文")
        XCTAssertTrue(app.navigationBars["新交易"].waitForExistence(timeout: 5))
        XCTAssertEqual(waitFor("trade.categoryTab.virtualAssets").label, "虛擬資產")
        XCTAssertTrue(app.staticTexts["持倉明細"].exists)

        openDebugAndSelectLanguage("简体中文")
        XCTAssertEqual(waitFor("trade.categoryTab.stocks").label, "股票")

        openDebugAndSelectLanguage("English")
        let backButton = app.navigationBars["New Trade"].buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap()
        waitFor("compare.newWatchlist").tap()
        XCTAssertTrue(waitFor("watchlist.root").exists)
        XCTAssertTrue(app.navigationBars["New Watchlist"].waitForExistence(timeout: 5))
        XCTAssertEqual(waitFor("watchlist.header.changePercent").label, "Percentage Change")
        XCTAssertEqual(waitFor("watchlist.debug.status.changeHeader").label, "Chg%")
    }

    func testStockDetailDebugLanguageSelectionUpdatesPage() throws {
        let detailEntry = waitFor("compare.stockDetailUSCommonStock")
        let componentLibrary = waitFor("compare.componentLibrary")

        for _ in 0..<6 where !detailEntry.isHittable {
            componentLibrary.swipeUp()
        }

        XCTAssertTrue(
            detailEntry.isHittable,
            "Stock detail entry should be reachable in the component library"
        )
        detailEntry.tap()

        XCTAssertTrue(waitFor("stockDetail.usCommonStockPage").exists)
        waitFor("stockDetail.navbar.debug").tap()
        XCTAssertTrue(waitFor("stockDetail.debug.sheet").exists)
        selectStockDetailLanguage("简体中文")
        dismissStockDetailDebugPanel()
        XCTAssertEqual(waitFor("stockDetail.page.headerTab.quote").label, "报价")

        waitFor("stockDetail.navbar.debug").tap()
        XCTAssertTrue(waitFor("stockDetail.debug.sheet").exists)
        XCTAssertTrue(waitFor("stockDetail.debug.language").exists)

        selectStockDetailLanguage("English")
        dismissStockDetailDebugPanel()
        XCTAssertEqual(waitFor("stockDetail.page.headerTab.quote").label, "Quote")
        XCTAssertEqual(waitFor("stockDetail.bottomActionBar.trade").label, "Trade")
        XCTAssertTrue(waitFor("stockDetail.page.disclaimer").label.hasPrefix("Notice:"))

        waitFor("stockDetail.navbar.debug").tap()
        selectStockDetailLanguage("繁體中文")
        dismissStockDetailDebugPanel()
        XCTAssertEqual(waitFor("stockDetail.page.headerTab.quote").label, "報價")
        XCTAssertTrue(waitFor("stockDetail.page.disclaimer").label.hasPrefix("提示:本頁面"))

        waitFor("stockDetail.navbar.debug").tap()
        selectStockDetailLanguage("简体中文")
        dismissStockDetailDebugPanel()
        XCTAssertEqual(waitFor("stockDetail.page.headerTab.quote").label, "报价")
    }

    func testStockDetailShuffleUsesWatchlistSnapshotAndExitsToSelectedInstrument() throws {
        enterWatchlist()

        let firstRow = waitFor("watchlist.row.hk:09988")
        XCTAssertTrue(firstRow.isHittable)
        firstRow.tap()

        XCTAssertTrue(waitFor("stockDetail.page").exists)
        waitFor("stockDetail.bottomActionBar.shuffle").tap()

        let shuffleRoot = waitFor("stockDetail.shuffle.root")
        XCTAssertTrue(waitFor("stockDetail.shuffle.close").exists)
        let firstSymbol = waitFor("stockDetail.shuffle.symbol.hongKong:09988")
        XCTAssertTrue(firstSymbol.isSelected)
        waitForCommittedInstrument("hongKong:09988")
        waitForParentCommittedInstrument("hongKong:09988")
        XCTAssertFalse(
            app.descendants(matching: .any)["stockDetail.shuffle.symbol.fund:LU012376428"].exists,
            "Funds must not enter the Shuffle snapshot"
        )

        let secondSymbol = waitFor("stockDetail.shuffle.symbol.hongKong:00700")
        secondSymbol.tap()
        let selectedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "selected == true"),
            object: secondSymbol
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [selectedExpectation], timeout: 2),
            .completed,
            "The symbol bar should select the fast-jumped instrument"
        )
        waitForCommittedInstrument("hongKong:00700")
        waitForParentCommittedInstrument("hongKong:00700")

        let thirdSymbol = waitFor("stockDetail.shuffle.symbol.hongKong:01810")
        shuffleRoot.swipeUp()
        let swipeExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "selected == true"),
            object: thirdSymbol
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [swipeExpectation], timeout: 2),
            .completed,
            "An upward swipe should advance to the next instrument"
        )
        waitForCommittedInstrument("hongKong:01810")
        waitForParentCommittedInstrument("hongKong:01810")

        waitFor("stockDetail.shuffle.close").tap()
        waitForDisappearance(shuffleRoot)
        XCTAssertTrue(waitFor("stockDetail.page").exists)
        XCTAssertTrue(
            waitFor("stockDetail.navbar.title").label.contains("01810"),
            "Exiting Shuffle should keep the currently viewed instrument"
        )
    }

    func testStockDetailShuffleCurrentCardTapExitsToSelectedInstrument() throws {
        enterWatchlist()

        let firstRow = waitFor("watchlist.row.hk:09988")
        XCTAssertTrue(firstRow.isHittable)
        firstRow.tap()

        XCTAssertTrue(waitFor("stockDetail.page").exists)
        waitFor("stockDetail.bottomActionBar.shuffle").tap()

        let shuffleRoot = waitFor("stockDetail.shuffle.root")
        let secondSymbol = waitFor("stockDetail.shuffle.symbol.hongKong:00700")
        secondSymbol.tap()
        waitForCommittedInstrument("hongKong:00700")
        waitForParentCommittedInstrument("hongKong:00700")

        waitFor("stockDetail.shuffle.card.current").tap()
        waitForDisappearance(shuffleRoot)
        XCTAssertTrue(waitFor("stockDetail.page").exists)
        XCTAssertTrue(
            waitFor("stockDetail.navbar.title").label.contains("00700"),
            "Tapping the current Shuffle card should exit to the selected instrument"
        )
    }

    func testStockDetailShuffleAdjacentCardTapExitsToTappedInstrument() throws {
        enterWatchlist()

        let firstRow = waitFor("watchlist.row.hk:09988")
        XCTAssertTrue(firstRow.isHittable)
        firstRow.tap()

        XCTAssertTrue(waitFor("stockDetail.page").exists)
        waitFor("stockDetail.bottomActionBar.shuffle").tap()

        let shuffleRoot = waitFor("stockDetail.shuffle.root")
        let nextCard = waitFor("stockDetail.shuffle.card.next")
        let appFrame = app.windows.firstMatch.frame
        XCTAssertTrue(nextCard.frame.intersects(appFrame), "The next-card peek should be visible")

        nextCard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.04)).tap()
        waitForParentCommittedInstrument("hongKong:00700")
        waitForDisappearance(shuffleRoot)
        XCTAssertTrue(waitFor("stockDetail.page").exists)
        XCTAssertTrue(
            waitFor("stockDetail.navbar.title").label.contains("00700"),
            "Tapping the next Shuffle card should exit to that instrument"
        )
    }

    func testStockDetailShuffleQuoteExpansionIsSharedPersistedAndIndependent() throws {
        enterWatchlist()

        let firstRow = waitFor("watchlist.row.hk:09988")
        XCTAssertTrue(firstRow.isHittable)
        firstRow.tap()

        XCTAssertTrue(waitFor("stockDetail.page").exists)
        waitFor("stockDetail.bottomActionBar.shuffle").tap()

        let shuffleRoot = waitFor("stockDetail.shuffle.root")
        XCTAssertFalse(
            shuffleRoot.descendants(matching: .any)
                .matching(identifier: "stockDetail.page.headerTabs")
                .firstMatch
                .exists,
            "Shuffle should not render the DetailPage tab bar"
        )
        let expansionButtons = shuffleRoot
            .descendants(matching: .button)
            .matching(identifier: "stockDetail.quoteData.expand")
        XCTAssertGreaterThanOrEqual(
            expansionButtons.count,
            1,
            "Shuffle should expose the current card's QuoteData expansion control"
        )

        let expansion = expansionButtons.firstMatch
        XCTAssertTrue(expansion.waitForExistence(timeout: 5))
        XCTAssertEqual(
            expansion.value as? String,
            "已展开",
            "Shuffle QuoteData should be expanded by default"
        )
        expansion.tap()
        XCTAssertTrue(waitFor("stockDetail.shuffle.root").exists)

        for index in 0..<expansionButtons.count {
            XCTAssertEqual(
                expansionButtons.element(boundBy: index).value as? String,
                "已收起",
                "All visible Shuffle cards should share the collapsed state"
            )
        }

        expansion.tap()
        for index in 0..<expansionButtons.count {
            XCTAssertEqual(
                expansionButtons.element(boundBy: index).value as? String,
                "已展开",
                "All visible Shuffle cards should share the expanded state"
            )
        }

        waitFor("stockDetail.shuffle.symbol.hongKong:00700").tap()
        waitForCommittedInstrument("hongKong:00700")
        XCTAssertEqual(
            expansionButtons.firstMatch.value as? String,
            "已展开",
            "Changing instruments must preserve the shared Shuffle expansion state"
        )

        waitFor("stockDetail.shuffle.close").tap()
        waitForDisappearance(shuffleRoot)
        let detailExpansion = app.buttons["stockDetail.quoteData.expand"].firstMatch
        XCTAssertTrue(detailExpansion.waitForExistence(timeout: 5))
        XCTAssertEqual(
            detailExpansion.value as? String,
            "已收起",
            "Shuffle expansion must not expand the underlying DetailPage"
        )

        waitFor("stockDetail.bottomActionBar.shuffle").tap()
        let reopenedShuffle = waitFor("stockDetail.shuffle.root")
        let reopenedCurrentCard = reopenedShuffle
            .descendants(matching: .any)
            .matching(identifier: "stockDetail.shuffle.card.current")
            .firstMatch
        XCTAssertTrue(reopenedCurrentCard.waitForExistence(timeout: 5))
        let reopenedExpansion = reopenedCurrentCard
            .descendants(matching: .button)
            .matching(identifier: "stockDetail.quoteData.expand")
            .firstMatch
        XCTAssertTrue(reopenedExpansion.waitForExistence(timeout: 5))
        XCTAssertEqual(
            reopenedExpansion.value as? String,
            "已展开",
            "Shuffle expansion should be restored from local storage"
        )

        reopenedExpansion.tap()
        XCTAssertEqual(reopenedExpansion.value as? String, "已收起")
    }

    func testWatchlistInAppNotificationMatchesViewport() throws {
        enterWatchlist()

        waitFor("watchlist.debug.open").tap()
        waitFor("watchlist.debug.inAppNotification").tap()

        let debugPanel = waitFor("watchlist.debug.panel")
        debugPanel.swipeDown()
        waitForDisappearance(debugPanel)

        let banner = waitFor("inAppNotification.tradeBanner")
        assertInAppNotificationFrame(banner)
    }

    func testWatchlistSelectionGlassTracksHorizontalPaging() throws {
        enterWatchlist()

        let allTab = waitFor("watchlist.tab.全部")
        let hongKongTab = waitFor("watchlist.tab.港股")
        XCTAssertTrue(allTab.isSelected)

        app.swipeLeft()

        let selectionExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "selected == true"),
            object: hongKongTab
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [selectionExpectation], timeout: 5),
            .completed,
            "The selected HeaderTab should follow horizontal paging"
        )
        XCTAssertFalse(allTab.isSelected)
        XCTAssertTrue(hongKongTab.isSelected)
    }

    func testTradeInAppNotificationRepeatsAndStops() throws {
        enterTrade()

        app.buttons["Debug"].tap()
        waitFor("trade.debug.inAppNotification").tap()
        dismissDebugPanel()
        XCTAssertEqual(
            waitFor("trade.debug.status.inAppNotification").label,
            "INAPP_ENABLED"
        )

        let banner = waitFor("inAppNotification.tradeBanner")
        assertInAppNotificationFrame(banner)

        sleep(4)
        XCTAssertTrue(banner.exists, "Banner should remain visible for five seconds")
        waitForDisappearance(banner, timeout: 2)
        XCTAssertTrue(
            banner.waitForExistence(timeout: 3),
            "Banner should reappear one second after its exit animation"
        )

        app.buttons["Debug"].tap()
        waitFor("trade.debug.inAppNotification").tap()
        dismissDebugPanel()
        XCTAssertEqual(
            waitFor("trade.debug.status.inAppNotification").label,
            "INAPP_DISABLED"
        )

        waitForDisappearance(banner, timeout: 2)
        sleep(2)
        XCTAssertFalse(banner.exists, "Banner must not restart after the toggle is disabled")
    }

    func testTradeInAppNotificationTouchResetsCountdownAndSwipeUpDismisses() throws {
        enterTrade()

        app.buttons["Debug"].tap()
        waitFor("trade.debug.inAppNotification").tap()
        dismissDebugPanel()

        let banner = waitFor("inAppNotification.tradeBanner")
        sleep(4)
        banner.press(forDuration: 1)

        sleep(4)
        XCTAssertTrue(
            banner.exists,
            "Touching the banner should restart its five-second dismissal countdown"
        )

        banner.swipeUp()
        waitForDisappearance(banner, timeout: 2)
        XCTAssertTrue(
            banner.waitForExistence(timeout: 3),
            "A manually dismissed banner should continue the enabled simulation cycle"
        )
    }

    func testTradeMultipleInAppNotificationsReplaceCurrentBanner() throws {
        enterTrade()

        app.buttons["Debug"].tap()
        waitFor("trade.debug.inAppNotification").tap()
        waitFor("trade.debug.inAppNotificationMultiple").tap()
        dismissDebugPanel()

        XCTAssertEqual(
            waitFor("trade.debug.status.inAppNotificationMultiple").label,
            "INAPP_MULTIPLE_ENABLED"
        )

        let firstMessage = waitFor("inAppNotification.tradeBanner").label
        sleep(3)

        let replacementBanner = waitFor("inAppNotification.tradeBanner")
        XCTAssertNotEqual(
            replacementBanner.label,
            firstMessage,
            "A new simulated message should replace the currently displayed banner"
        )
        assertInAppNotificationFrame(replacementBanner)
    }

    private func enterWatchlist() {
        waitFor("compare.newWatchlist").tap()
        XCTAssertTrue(waitFor("watchlist.root").exists)
    }

    private func enterTrade() {
        waitFor("compare.newTrade").tap()
        XCTAssertTrue(waitFor("trade.root").exists)
    }

    private func selectStockDetailLanguage(_ language: String) {
        let option = app.buttons[language].firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5), "Missing language option: \(language)")
        option.tap()
        _ = waitFor("stockDetail.debug.sheet", timeout: 5)
    }

    private func dismissStockDetailDebugPanel() {
        let sheet = waitFor("stockDetail.debug.sheet")
        waitFor("stockDetail.debug.done").tap()
        waitForDisappearance(sheet)
    }

    private func dismissDebugPanel() {
        let close = app.descendants(matching: .any)["trade.debug.close"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 5), "Missing debug close button")
        close.tap()
        _ = waitFor("trade.root", timeout: 5)
    }

    private func openDebugAndSelectLanguage(_ language: String) {
        waitFor("trade.debug.open").tap()
        XCTAssertTrue(waitFor("demo.language.picker").exists)
        let option = app.buttons[language].firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5), "Missing language option: \(language)")
        option.tap()
        dismissDebugPanel()
    }

    private func waitForDisappearance(
        _ element: XCUIElement,
        timeout: TimeInterval = 3,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Element did not disappear", file: file, line: line)
    }

    @discardableResult
    private func waitFor(_ identifier: String, timeout: TimeInterval = 8) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Missing element: \(identifier)")
        return element
    }

    private func waitForButton(_ label: String, timeout: TimeInterval = 8) -> XCUIElement {
        let button = app.buttons[label].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "Missing button: \(label)")
        return button
    }

    private func waitForCommittedInstrument(
        _ expectedID: String,
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let status = waitFor("stockDetail.shuffle.committedInstrument", timeout: timeout)
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", expectedID),
            object: status
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Shuffle selection was not committed to the parent detail page: \(expectedID)",
            file: file,
            line: line
        )
    }

    private func waitForParentCommittedInstrument(
        _ expectedID: String,
        timeout: TimeInterval = 2,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let status = waitFor("stockDetail.committedInstrument", timeout: timeout)
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", expectedID),
            object: status
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(
            result,
            .completed,
            "Presenting DetailPage did not commit the Shuffle exit instrument: \(expectedID)",
            file: file,
            line: line
        )
    }

    private func assertWidth(of element: XCUIElement, equals expected: CGFloat, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(element.frame.width, expected, accuracy: 1, file: file, line: line)
    }

    private func assertInAppNotificationFrame(
        _ banner: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let navigationBar = app.navigationBars.firstMatch
        XCTAssertTrue(
            navigationBar.waitForExistence(timeout: 5),
            "Missing navigation bar",
            file: file,
            line: line
        )
        XCTAssertEqual(banner.frame.minX, 10, accuracy: 1, file: file, line: line)
        XCTAssertEqual(
            banner.frame.width,
            expectedViewportWidth - 20,
            accuracy: 1,
            file: file,
            line: line
        )
        XCTAssertEqual(banner.frame.height, 90, accuracy: 1, file: file, line: line)
        XCTAssertEqual(
            banner.frame.minY,
            navigationBar.frame.minY,
            accuracy: 1,
            "Banner must begin at the top safe-area edge and overlap the navigation bar",
            file: file,
            line: line
        )
        XCTAssertGreaterThan(
            banner.frame.maxY,
            navigationBar.frame.maxY,
            "Banner must extend over the navigation bar layer",
            file: file,
            line: line
        )
    }

    private var expectedViewportWidth: CGFloat {
        if let value = ProcessInfo.processInfo.environment["TRADE_EXPECTED_VIEWPORT_WIDTH"],
           let width = Double(value) {
            return CGFloat(width)
        }

        let deviceName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? ""
        return deviceName.localizedCaseInsensitiveContains("Max") ? 440 : 402
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)[identifier].firstMatch
    }
}
