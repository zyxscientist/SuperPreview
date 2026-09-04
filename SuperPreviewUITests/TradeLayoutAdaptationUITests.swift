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
        enterComponentLibrary()

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
        let scroll = app.scrollViews["trade.scroll"].firstMatch
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
        XCTAssertEqual(waitFor("trade.categoryTab.stocks").label, "Stocks")
        XCTAssertEqual(waitFor("trade.metric.securitiesMarketValue").label, "Securities Market Value")
        XCTAssertEqual(waitFor("trade.header.marketValueQuantityHeader").label, "Market Value and Quantity")
        XCTAssertEqual(waitFor("trade.debug.status.marketValueHeader").label, "MKV/Qty")
        XCTAssertTrue(app.staticTexts["Position Details"].exists)

        openDebugAndSelectLanguage("繁體中文")
        XCTAssertEqual(waitFor("trade.categoryTab.virtualAssets").label, "虛擬資產")
        XCTAssertTrue(app.staticTexts["持倉明細"].exists)

        openDebugAndSelectLanguage("简体中文")
        XCTAssertEqual(waitFor("trade.categoryTab.stocks").label, "股票")

        openDebugAndSelectLanguage("English")
        selectMainTab("mainTab.tab1")
        XCTAssertTrue(waitFor("watchlist.root").exists)
        XCTAssertEqual(waitFor("watchlist.header.changePercent").label, "Percentage Change")
        XCTAssertEqual(waitFor("watchlist.debug.status.changeHeader").label, "Chg%")
    }

    func testStockDetailDebugLanguageSelectionUpdatesPage() throws {
        enterComponentLibrary()

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
        XCTAssertEqual(waitFor("stockDetail.page.headerTab.quote", label: "报价").label, "报价")

        waitFor("stockDetail.navbar.debug").tap()
        XCTAssertTrue(waitFor("stockDetail.debug.sheet").exists)
        XCTAssertTrue(waitFor("stockDetail.debug.language").exists)

        selectStockDetailLanguage("English")
        dismissStockDetailDebugPanel()
        XCTAssertEqual(waitFor("stockDetail.page.headerTab.quote", label: "Quote").label, "Quote")
        XCTAssertEqual(waitFor("stockDetail.bottomActionBar.trade").label, "Trade")
        XCTAssertTrue(waitFor("stockDetail.page.disclaimer").label.hasPrefix("Notice:"))

        waitFor("stockDetail.navbar.debug").tap()
        selectStockDetailLanguage("繁體中文")
        dismissStockDetailDebugPanel()
        XCTAssertEqual(waitFor("stockDetail.page.headerTab.quote", label: "報價").label, "報價")
        XCTAssertTrue(waitFor("stockDetail.page.disclaimer").label.hasPrefix("提示:本頁面"))

        waitFor("stockDetail.navbar.debug").tap()
        selectStockDetailLanguage("简体中文")
        dismissStockDetailDebugPanel()
        XCTAssertEqual(waitFor("stockDetail.page.headerTab.quote", label: "报价").label, "报价")
    }

    func testStockDetailTradePrefillsSelectedInstrumentAndReturns() throws {
        enterWatchlist()
        tapWatchlistRow("watchlist.row.us:NVDA")

        XCTAssertTrue(waitFor("stockDetail.page").exists)
        waitFor("stockDetail.bottomActionBar.trade").tap()

        assertStockOrderPrefill(
            symbol: "NVDA",
            name: "英伟达",
            price: "142.61"
        )

        waitFor("stockOrder.navbar.back").tap()
        XCTAssertTrue(waitFor("stockDetail.page").exists)

        // The same detail page can open a new order route after returning.
        waitFor("stockDetail.bottomActionBar.trade").tap()
        assertStockOrderPrefill(
            symbol: "NVDA",
            name: "英伟达",
            price: "142.61"
        )
    }

    func testStockDetailTradePrefillsMarketAndQuoteSnapshot() throws {
        enterWatchlist()

        let cases = [
            (tab: "watchlist.tab.港股", row: "watchlist.row.hk:09988", symbol: "09988", name: "阿里巴巴-W", price: "118.600"),
            (tab: "watchlist.tab.ETFs", row: "watchlist.row.hk:03032", symbol: "03032", name: "恒生科技ETF", price: "4.812"),
            (tab: "watchlist.tab.美股", row: "watchlist.row.us:NVDA", symbol: "NVDA", name: "英伟达", price: "142.61"),
            (tab: "watchlist.tab.ETFs", row: "watchlist.row.us:VOO", symbol: "VOO", name: "先锋标普500ETF", price: "512.33"),
            (tab: "watchlist.tab.沪深", row: "watchlist.row.cn:300750", symbol: "300750", name: "宁德时代", price: "189.610"),
            (tab: "watchlist.tab.ETFs", row: "watchlist.row.cn:513100", symbol: "513100", name: "纳指100ETF", price: "1.482"),
            (tab: "watchlist.tab.自定义", row: "watchlist.row.crypto:BTC/USD", symbol: "BTC/USD", name: "比特币/美元", price: "66666.61")
        ]

        for item in cases {
            waitFor(item.tab).tap()
            tapWatchlistRow(item.row)

            XCTAssertTrue(waitFor("stockDetail.page").exists)
            waitFor("stockDetail.bottomActionBar.trade").tap()
            assertStockOrderPrefill(
                symbol: item.symbol,
                name: item.name,
                price: item.price
            )

            waitFor("stockOrder.navbar.back").tap()
            XCTAssertTrue(waitFor("stockDetail.page").exists)
            waitFor("stockDetail.navbar.back").tap()
            XCTAssertTrue(waitFor("watchlist.root").exists)
        }
    }

    func testStockDetailTradeUsesCurrentShuffleInstrument() throws {
        enterWatchlist()
        tapWatchlistRow("watchlist.row.us:NVDA")

        XCTAssertTrue(waitFor("stockDetail.page").exists)
        waitFor("stockDetail.bottomActionBar.shuffle").tap()

        let shuffleRoot = waitFor("stockDetail.shuffle.root")
        let secondSymbol = waitFor("stockDetail.shuffle.symbol.us:AAPL")
        secondSymbol.tap()
        waitForCommittedInstrument("us:AAPL")
        waitForParentCommittedInstrument("us:AAPL")

        waitFor("stockDetail.shuffle.card.current").tap()
        waitForDisappearance(shuffleRoot)
        XCTAssertTrue(waitFor("stockDetail.page").exists)
        XCTAssertTrue(waitFor("stockDetail.navbar.title").label.contains("AAPL"))

        waitFor("stockDetail.bottomActionBar.trade").tap()
        assertStockOrderPrefill(
            symbol: "AAPL",
            name: "苹果",
            price: "212.45"
        )
    }

    func testStockDetailEdgeSwipeBackReturnsToWatchlist() throws {
        enterWatchlist()
        tapWatchlistRow("watchlist.row.us:NVDA")

        XCTAssertTrue(waitFor("stockDetail.page").exists)
        performHorizontalDrag(fromX: 0.01, toX: 0.82)

        XCTAssertTrue(
            waitFor("watchlist.root").exists,
            "A leading-edge drag should pop the detail page"
        )
    }

    func testStockDetailEdgeSwipeCancellationKeepsRoute() throws {
        enterWatchlist()
        tapWatchlistRow("watchlist.row.us:NVDA")

        let detail = waitFor("stockDetail.page")
        performHorizontalDrag(fromX: 0.01, toX: 0.18)

        XCTAssertTrue(
            detail.waitForExistence(timeout: 3),
            "A short, cancelled drag must keep the detail route active"
        )
        XCTAssertTrue(waitFor("stockDetail.bottomActionBar.trade").exists)
    }

    func testStockOrderSystemEdgeSwipeBackReturnsToDetail() throws {
        enterWatchlist()
        tapWatchlistRow("watchlist.row.us:NVDA")
        waitFor("stockDetail.bottomActionBar.trade").tap()
        assertStockOrderPrefill(symbol: "NVDA", name: "英伟达", price: "142.61")

        performHorizontalDrag(fromX: 0.01, toX: 0.82)

        XCTAssertTrue(
            waitFor("stockDetail.page").exists,
            "The order page should use the native edge pop and return to detail"
        )
        let orderPage = app.descendants(matching: .any)["stockOrder.demo"].firstMatch
        let goneExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: orderPage
        )
        XCTAssertEqual(XCTWaiter.wait(for: [goneExpectation], timeout: 3), .completed)
    }

    func testStockOrderEdgeSwipeWithKeyboardReturnsToDetail() throws {
        enterWatchlist()
        tapWatchlistRow("watchlist.row.us:NVDA")
        waitFor("stockDetail.bottomActionBar.trade").tap()

        let priceField = app.textFields["stockOrder.priceInput.field"].firstMatch
        XCTAssertTrue(priceField.waitForExistence(timeout: 5), "Missing order price field")
        priceField.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 3), "Keyboard did not appear")

        performHorizontalDrag(fromX: 0.01, toX: 0.82)

        XCTAssertTrue(
            waitFor("stockDetail.page").exists,
            "An edge back swipe must not get stuck while the keyboard is visible"
        )
    }

    func testStockOrderConfirmationCardBlocksBackSwipeUntilDismissed() throws {
        enterWatchlist()
        tapWatchlistRow("watchlist.row.us:NVDA")
        waitFor("stockDetail.bottomActionBar.trade").tap()

        waitFor("stockOrder.tradeActionBar.buy").tap()
        XCTAssertTrue(waitFor("stockOrder.confirmationSheet").exists)

        performHorizontalDrag(fromX: 0.01, toX: 0.82)
        XCTAssertTrue(
            waitFor("stockOrder.confirmationSheet").exists,
            "The confirmation card must own the interaction before navigation can pop"
        )

        waitFor("stockOrder.confirmationSheet.button.cancel").tap()
        XCTAssertTrue(waitFor("stockOrder.demo").exists)

        performHorizontalDrag(fromX: 0.01, toX: 0.82)
        XCTAssertTrue(waitFor("stockDetail.page").exists)
    }

    func testWatchlistRootRejectsBackSwipe() throws {
        enterWatchlist()

        performHorizontalDrag(fromX: 0.01, toX: 0.82)

        XCTAssertTrue(waitFor("watchlist.root").exists)
    }

    func testStockDetailCenterSwipeUsesPagerInsteadOfNavigationPop() throws {
        enterWatchlist()
        tapWatchlistRow("watchlist.row.us:NVDA")

        let analysisTab = waitFor("stockDetail.page.headerTab.analysis")
        analysisTab.tap()
        XCTAssertTrue(analysisTab.isSelected)
        sleep(1)

        // Detail pages opt into edge-only navigation, so a center swipe is
        // left to the TabView pager and must not pop the navigation route.
        performHorizontalDrag(fromX: 0.52, toX: 0.97)

        XCTAssertTrue(waitFor("stockDetail.page").exists)
        XCTAssertTrue(
            waitFor("stockDetail.page.headerTab.etf").isSelected,
            "A center right swipe should page to the preceding detail tab, not pop detail"
        )
    }

    func testShuffleIgnoresNavigationBackSwipe() throws {
        enterWatchlist()
        tapWatchlistRow("watchlist.row.us:NVDA")
        waitFor("stockDetail.bottomActionBar.shuffle").tap()

        let shuffle = waitFor("stockDetail.shuffle.root")
        performHorizontalDrag(fromX: 0.01, toX: 0.82)

        XCTAssertTrue(
            shuffle.waitForExistence(timeout: 3),
            "Shuffle is a full-screen cover and must not be closed by navigation back"
        )
    }

    func testStockDetailShuffleUsesWatchlistSnapshotAndExitsToSelectedInstrument() throws {
        enterWatchlist()

        let firstRow = waitFor("watchlist.row.us:NVDA")
        XCTAssertTrue(firstRow.isHittable)
        firstRow.tap()

        XCTAssertTrue(waitFor("stockDetail.page").exists)
        waitFor("stockDetail.bottomActionBar.shuffle").tap()

        let shuffleRoot = waitFor("stockDetail.shuffle.root")
        XCTAssertTrue(waitFor("stockDetail.shuffle.close").exists)
        let firstSymbol = waitFor("stockDetail.shuffle.symbol.us:NVDA")
        XCTAssertTrue(firstSymbol.isSelected)
        waitForCommittedInstrument("us:NVDA")
        waitForParentCommittedInstrument("us:NVDA")
        XCTAssertFalse(
            app.descendants(matching: .any)["stockDetail.shuffle.symbol.fund:LU012376428"].exists,
            "Funds must not enter the Shuffle snapshot"
        )

        let secondSymbol = waitFor("stockDetail.shuffle.symbol.us:AAPL")
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
        waitForCommittedInstrument("us:AAPL")
        waitForParentCommittedInstrument("us:AAPL")

        let thirdSymbol = waitFor("stockDetail.shuffle.symbol.us:TSLA")
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
        waitForCommittedInstrument("us:TSLA")
        waitForParentCommittedInstrument("us:TSLA")

        waitFor("stockDetail.shuffle.close").tap()
        waitForDisappearance(shuffleRoot)
        XCTAssertTrue(waitFor("stockDetail.page").exists)
        XCTAssertTrue(
            waitFor("stockDetail.navbar.title").label.contains("TSLA"),
            "Exiting Shuffle should keep the currently viewed instrument"
        )
    }

    func testStockDetailShuffleCurrentCardTapExitsToSelectedInstrument() throws {
        enterWatchlist()

        let firstRow = waitFor("watchlist.row.us:NVDA")
        XCTAssertTrue(firstRow.isHittable)
        firstRow.tap()

        XCTAssertTrue(waitFor("stockDetail.page").exists)
        waitFor("stockDetail.bottomActionBar.shuffle").tap()

        let shuffleRoot = waitFor("stockDetail.shuffle.root")
        let secondSymbol = waitFor("stockDetail.shuffle.symbol.us:AAPL")
        secondSymbol.tap()
        waitForCommittedInstrument("us:AAPL")
        waitForParentCommittedInstrument("us:AAPL")

        waitFor("stockDetail.shuffle.card.current").tap()
        waitForDisappearance(shuffleRoot)
        XCTAssertTrue(waitFor("stockDetail.page").exists)
        XCTAssertTrue(
            waitFor("stockDetail.navbar.title").label.contains("AAPL"),
            "Tapping the current Shuffle card should exit to the selected instrument"
        )
    }

    func testStockDetailShuffleAdjacentCardTapExitsToTappedInstrument() throws {
        enterWatchlist()

        let firstRow = waitFor("watchlist.row.us:NVDA")
        XCTAssertTrue(firstRow.isHittable)
        firstRow.tap()

        XCTAssertTrue(waitFor("stockDetail.page").exists)
        waitFor("stockDetail.bottomActionBar.shuffle").tap()

        let shuffleRoot = waitFor("stockDetail.shuffle.root")
        let nextCard = waitFor("stockDetail.shuffle.card.next")
        let appFrame = app.windows.firstMatch.frame
        XCTAssertTrue(nextCard.frame.intersects(appFrame), "The next-card peek should be visible")

        nextCard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.04)).tap()
        waitForParentCommittedInstrument("us:AAPL")
        waitForDisappearance(shuffleRoot)
        XCTAssertTrue(waitFor("stockDetail.page").exists)
        XCTAssertTrue(
            waitFor("stockDetail.navbar.title").label.contains("AAPL"),
            "Tapping the next Shuffle card should exit to that instrument"
        )
    }

    func testStockDetailShuffleQuoteExpansionIsSharedPersistedAndIndependent() throws {
        enterWatchlist()

        let firstRow = waitFor("watchlist.row.us:NVDA")
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

        waitFor("stockDetail.shuffle.symbol.us:AAPL").tap()
        waitForCommittedInstrument("us:AAPL")
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
        let notificationToggle = app.switches["watchlist.debug.inAppNotification"]
        XCTAssertTrue(notificationToggle.waitForExistence(timeout: 8))
        notificationToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        let debugPanel = waitFor("watchlist.debug.panel")
        let sheetGrabber = app.buttons["Sheet Grabber"]
        XCTAssertTrue(sheetGrabber.waitForExistence(timeout: 5), "Missing sheet grabber")
        sheetGrabber.swipeDown()
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

        let debugButton = waitFor("trade.debug.open")
        debugButton.tap()
        toggleDebugSwitch("trade.debug.inAppNotification")
        dismissDebugPanel()
        XCTAssertEqual(
            waitFor("trade.debug.status.inAppNotification").label,
            "INAPP_ENABLED"
        )

        let banner = waitFor("inAppNotification.tradeBanner")
        assertInAppNotificationFrame(banner)

        sleep(4)
        XCTAssertTrue(banner.exists, "Banner should remain visible for five seconds")
        XCTAssertTrue(
            waitUntilDisappears(banner, timeout: 8),
            "Banner should exit before the next repeated notification"
        )
        XCTAssertTrue(
            banner.waitForExistence(timeout: 3),
            "Banner should reappear one second after its exit animation"
        )
        XCTAssertTrue(
            waitUntilDisappears(banner, timeout: 8),
            "The repeated banner should eventually leave the viewport"
        )

        debugButton.tap()
        toggleDebugSwitch("trade.debug.inAppNotification")
        dismissDebugPanel()
        XCTAssertEqual(
            waitFor("trade.debug.status.inAppNotification").label,
            "INAPP_DISABLED"
        )

        XCTAssertTrue(
            waitUntilDisappears(banner, timeout: 3),
            "Disabling the simulation should dismiss the current banner"
        )
        sleep(2)
        XCTAssertFalse(banner.exists, "Banner must not restart after the toggle is disabled")
    }

    func testTradeInAppNotificationTouchResetsCountdownAndSwipeUpDismisses() throws {
        enterTrade()

        waitFor("trade.debug.open").tap()
        toggleDebugSwitch("trade.debug.inAppNotification")
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
        if !waitUntilDisappears(banner, timeout: 1) {
            let start = banner.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.8))
            let end = banner.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1))
            start.press(
                forDuration: 0.1,
                thenDragTo: end,
                withVelocity: .fast,
                thenHoldForDuration: 0
            )
        }
        XCTAssertTrue(
            waitUntilDisappears(banner, timeout: 3),
            "Swiping the banner up should dismiss it"
        )
        XCTAssertTrue(
            banner.waitForExistence(timeout: 3),
            "A manually dismissed banner should continue the enabled simulation cycle"
        )
    }

    func testTradeMultipleInAppNotificationsReplaceCurrentBanner() throws {
        enterTrade()

        waitFor("trade.debug.open").tap()
        toggleDebugSwitch("trade.debug.inAppNotification")
        toggleDebugSwitch("trade.debug.inAppNotificationMultiple")
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
        selectMainTab("mainTab.tab1")
        XCTAssertTrue(waitFor("watchlist.root").exists)
    }

    private func enterTrade() {
        selectMainTab("mainTab.tab2")
        XCTAssertTrue(waitFor("trade.root").exists)
    }

    private func enterComponentLibrary() {
        selectMainTab("mainTab.tab6")
        XCTAssertTrue(waitFor("compare.componentLibrary").exists)
    }

    private func selectMainTab(_ identifier: String) {
        waitFor(identifier).tap()
    }

    private func tapWatchlistRow(_ identifier: String) {
        let row = waitFor(identifier)
        let watchlistScroll = app.scrollViews.firstMatch

        for _ in 0..<6 where !row.isHittable {
            watchlistScroll.swipeUp()
        }

        XCTAssertTrue(row.isHittable, "Watchlist row should be hittable: \(identifier)")
        row.tap()
    }

    private func performHorizontalDrag(
        fromX: CGFloat,
        toX: CGFloat,
        y: CGFloat = 0.5
    ) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 3), "Missing application window")

        let start = window.coordinate(
            withNormalizedOffset: CGVector(dx: fromX, dy: y)
        )
        let end = window.coordinate(
            withNormalizedOffset: CGVector(dx: toX, dy: y)
        )
        start.press(forDuration: 0.01, thenDragTo: end)
    }

    private func assertStockOrderPrefill(
        symbol: String,
        name: String,
        price: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(waitFor("stockOrder.demo").exists, file: file, line: line)
        XCTAssertEqual(
            waitFor("stockOrder.debug.status.symbol").label,
            symbol,
            file: file,
            line: line
        )
        XCTAssertEqual(
            waitFor("stockOrder.debug.status.name").label,
            name,
            file: file,
            line: line
        )
        XCTAssertEqual(
            waitFor("stockOrder.debug.status.price").label,
            price,
            file: file,
            line: line
        )
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

    private func toggleDebugSwitch(_ identifier: String) {
        let toggle = app.switches[identifier].firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 8), "Missing debug switch: \(identifier)")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
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

    private func waitUntilDisappears(
        _ element: XCUIElement,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !element.exists {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return !element.exists
    }

    @discardableResult
    private func waitFor(_ identifier: String, timeout: TimeInterval = 8) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Missing element: \(identifier)")
        return element
    }

    @discardableResult
    private func waitFor(
        _ identifier: String,
        label: String,
        timeout: TimeInterval = 8
    ) -> XCUIElement {
        let element = waitFor(identifier, timeout: timeout)
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", label),
            object: element
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout),
            .completed,
            "Element \(identifier) did not update to label \(label)"
        )
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

final class NavigationBackSwipeHarnessUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait

        app = XCUIApplication()
        app.launchArguments = ["-UITesting", "-BackSwipeHarness"]
        app.launchEnvironment["UITEST_MODE"] = "1"
        app.launch()
    }

    func testEdgePolicyCompletesNativeBackSwipe() throws {
        openDestination(.edge)

        performHorizontalDrag(fromX: 0.01, toX: 0.82)

        XCTAssertTrue(waitFor("backSwipeHarness.root").exists)
    }

    func testUIKitBaselineCompletesNativeBackSwipe() throws {
        let link = app.buttons["Native"].firstMatch
        XCTAssertTrue(link.waitForExistence(timeout: 5), "Missing native harness link")
        link.tap()
        XCTAssertTrue(waitFor("backSwipeHarness.destination.native").exists)

        performHorizontalDrag(fromX: 0.2, toX: 0.98)

        XCTAssertTrue(waitFor("backSwipeHarness.root").exists)
    }

    func testEdgePolicyCancelsShortBackSwipe() throws {
        openDestination(.edge)

        performHorizontalDrag(fromX: 0.01, toX: 0.18)

        XCTAssertTrue(
            waitFor("backSwipeHarness.destination.edge").waitForExistence(timeout: 3),
            "A short edge drag must leave the navigation route active"
        )
    }

    func testSystemPolicyCompletesContentAreaBackSwipe() throws {
        openDestination(.system)

        performHorizontalDrag(fromX: 0.2, toX: 0.98)

        XCTAssertTrue(waitFor("backSwipeHarness.root").exists)
    }

    func testSystemPolicyFallsBackToEdgeWithCustomNavigationBar() throws {
        openDestination(.systemHidden)

        performHorizontalDrag(fromX: 0.01, toX: 0.82)

        XCTAssertTrue(waitFor("backSwipeHarness.root").exists)
    }

    func testDisabledPolicyRejectsBackSwipes() throws {
        openDestination(.disabled)

        performHorizontalDrag(fromX: 0.01, toX: 0.82)
        XCTAssertTrue(waitFor("backSwipeHarness.destination.disabled").exists)

        performHorizontalDrag(fromX: 0.5, toX: 0.96)
        XCTAssertTrue(waitFor("backSwipeHarness.destination.disabled").exists)

        let backButton = app.buttons["Back"].firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: 5), "Missing custom back button")
        backButton.tap()
        XCTAssertTrue(waitFor("backSwipeHarness.root").exists)
    }

    private enum Destination: String {
        case edge
        case system
        case systemHidden
        case disabled

        var displayName: String {
            switch self {
            case .systemHidden:
                "System custom"
            default:
                rawValue.capitalized
            }
        }
    }

    private func openDestination(_ destination: Destination) {
        let link = app.buttons[destination.displayName].firstMatch
        XCTAssertTrue(
            link.waitForExistence(timeout: 5),
            "Missing harness link: \(destination.rawValue)"
        )
        link.tap()
        XCTAssertTrue(
            waitFor("backSwipeHarness.destination.\(destination.rawValue)").exists,
            "Expected harness destination: \(destination.rawValue)"
        )
    }

    private func performHorizontalDrag(
        fromX: CGFloat,
        toX: CGFloat,
        y: CGFloat = 0.5
    ) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 3), "Missing application window")

        let start = window.coordinate(withNormalizedOffset: CGVector(dx: fromX, dy: y))
        let end = window.coordinate(withNormalizedOffset: CGVector(dx: toX, dy: y))
        start.press(forDuration: 0.01, thenDragTo: end)
    }

    @discardableResult
    private func waitFor(_ identifier: String, timeout: TimeInterval = 5) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Missing element: \(identifier)")
        return element
    }
}
