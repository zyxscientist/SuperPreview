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

        for category in ["股票", "基金", "虚拟资产"] {
            let tab = waitFor("trade.categoryTab.\(category)")
            tab.tap()
            let page = waitFor("trade.categoryPage")
            assertWidth(of: page, equals: expectedViewportWidth)
            assertWidth(of: waitFor("trade.subAssetCard"), equals: expectedViewportWidth - 32)
            assertWidth(of: waitFor("trade.quickMenu.inline"), equals: expectedViewportWidth)
            assertWidth(of: waitFor("trade.holdingsViewport"), equals: expectedViewportWidth)
        }
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
        let fixedMarketHeader = waitForButton("港股· HKD")
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

        let holding = waitForButton("腾讯控股，00700")
        holding.tap()
        XCTAssertTrue(waitForButton("腾讯控股行情").isHittable)

        let lastHolding = waitForButton("特斯拉，TSLA")
        for _ in 0..<12 where !lastHolding.isHittable {
            scroll.swipeUp()
        }
        XCTAssertTrue(lastHolding.isHittable)
        lastHolding.tap()
        XCTAssertTrue(waitForButton("特斯拉行情").isHittable)
    }

    func testTradeDebugStatesAndLiveRefreshKeepFramesStable() throws {
        enterTrade()

        let baselineCard = waitFor("trade.subAssetCard").frame
        let baselineMenu = waitFor("trade.quickMenu.inline").frame
        let baselineHoldings = waitFor("trade.holdingsViewport").frame

        app.buttons["Debug"].tap()
        XCTAssertTrue(app.staticTexts["调试"].waitForExistence(timeout: 5))
        waitFor("trade.debug.enableStateMatrix").tap()
        dismissDebugPanel()

        XCTAssertEqual(waitFor("trade.debug.status.summerAd").label, "SUMMER_ENABLED")
        XCTAssertEqual(waitFor("trade.debug.status.mr").label, "MR_ENABLED")
        XCTAssertTrue(waitFor("trade.mrNotice").exists)
        XCTAssertTrue(waitFor("trade.summerAd").exists)
        waitFor("trade.categoryTab.虚拟资产").tap()
        assertWidth(of: waitFor("trade.categoryPage"), equals: expectedViewportWidth)
        assertWidth(of: waitFor("trade.subAssetCard"), equals: expectedViewportWidth - 32)
        assertWidth(of: waitFor("trade.quickMenu.inline"), equals: expectedViewportWidth)
        assertWidth(of: waitFor("trade.holdingsViewport"), equals: expectedViewportWidth)
        XCTAssertTrue(waitFor("trade.mrNotice").exists)
        XCTAssertTrue(waitFor("trade.summerAd").exists)

        waitFor("trade.categoryTab.股票").tap()
        XCTAssertEqual(waitFor("trade.debug.status.mr").label, "MR_ENABLED")
        XCTAssertTrue(waitFor("trade.mrMaintenance").exists)

        app.buttons["Debug"].tap()
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

    private func enterTrade() {
        waitFor("compare.newTrade").tap()
        XCTAssertTrue(waitFor("trade.root").exists)
    }

    private func dismissDebugPanel() {
        let close = app.descendants(matching: .any)["trade.debug.close"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 5), "Missing debug close button")
        close.tap()
        _ = waitFor("trade.root", timeout: 5)
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

    private func assertWidth(of element: XCUIElement, equals expected: CGFloat, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(element.frame.width, expected, accuracy: 1, file: file, line: line)
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
