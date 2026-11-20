import XCTest

final class ToastUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
    }

    private func launchApp(language: String = "zh-Hans") {
        app.launchArguments += [
            "-UITesting",
            "-compare.demo.interfaceLanguage", language,
            "-UIPreferredContentSizeCategory", "UICTContentSizeCategoryL"
        ]
        app.launch()
    }

    func testHoldingToastPreventsTimeoutAndReleaseRestartsCountdown() {
        startToastLoop()

        XCTAssertEqual(toast.label, "订单已提交")
        XCTAssertEqual(toast.frame.width, 110, accuracy: 1)
        XCTAssertEqual(toast.frame.height, 38, accuracy: 1)
        XCTAssertEqual(toast.frame.midX, app.frame.midX, accuracy: 1)

        toast.press(forDuration: 3.25)
        XCTAssertTrue(toast.exists, "Holding the toast past its timeout should keep it visible")
        Thread.sleep(forTimeInterval: 2)
        XCTAssertTrue(toast.exists, "Releasing should start a fresh countdown")
        XCTAssertTrue(toast.waitForNonExistence(timeout: 2), "The toast should still dismiss automatically")
    }

    func testSwipeDismissesToastAndAnotherDebugPanelCanStopTheLoop() {
        startToastLoop()

        swipeUp(on: toast)
        XCTAssertTrue(toast.waitForNonExistence(timeout: 0.8), "Swiping should dismiss before the three-second timeout")
        XCTAssertTrue(toast.waitForExistence(timeout: 3), "The preview should play again after a swipe")

        element("watchlist.debug.close").tap()
        element("mainTab.tab2").tap()

        // Capture the settled toast over the trade page, as in the design.
        XCTAssertTrue(toast.waitForNonExistence(timeout: 4))
        XCTAssertTrue(toast.waitForExistence(timeout: 4))
        XCTAssertEqual(toast.frame.minY, app.navigationBars.firstMatch.frame.minY, accuracy: 1)
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = "Toast on trade page"
        screenshot.lifetime = .keepAlways
        add(screenshot)

        element("trade.debug.open").tap()

        let toggle = app.switches["debug.toast.simulation"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 4))
        XCTAssertEqual(toggle.value as? String, "1")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertTrue(toast.waitForNonExistence(timeout: 2))
        XCTAssertFalse(toast.waitForExistence(timeout: 2), "Disabling the preview must cancel the next playback")
    }

    func testQueuedToastsWaitWhileHeldAndFollowAutomaticAndSwipeDismissal() {
        launchApp()
        element("watchlist.debug.open").tap()
        element("debug.toast.queue").tap()

        let submitted = toast(labeled: "订单已提交")
        let addedToWatchlist = toast(labeled: "已添加自选")
        let cancelled = toast(labeled: "订单已撤销")
        XCTAssertTrue(submitted.exists || submitted.waitForExistence(timeout: 3))

        submitted.press(forDuration: 3.25)
        XCTAssertTrue(submitted.exists, "The queued messages must wait while the first toast is held")
        XCTAssertEqual(toasts.count, 1)

        Thread.sleep(forTimeInterval: 1.75)
        XCTAssertTrue(submitted.exists, "The first toast still gets a fresh countdown on release")
        XCTAssertTrue(addedToWatchlist.waitForExistence(timeout: 3), "The second toast should follow the first timeout")
        XCTAssertEqual(toasts.count, 1)

        swipeUp(on: addedToWatchlist)
        XCTAssertTrue(cancelled.waitForExistence(timeout: 2), "The third toast should follow the swipe dismissal")
        XCTAssertEqual(toasts.count, 1)
        XCTAssertTrue(cancelled.waitForNonExistence(timeout: 5))
        XCTAssertFalse(toast.exists, "The one-shot queue should end after its last message")
    }

    func testFavoriteDemoRevealsEditGroupAndShowsAddAndDeleteToasts() {
        openFavoriteDemo()
        let heart = element("favoriteDemo.XOMO.toggle")
        let name = element("favoriteDemo.XOMO.name")
        let edit = app.buttons["favoriteDemo.XOMO.edit"]
        let otherHeart = element("favoriteDemo.BTC/HKD.toggle")
        let originalNameFrame = name.frame
        let originalHeartCenter = heart.frame.midX
        XCTAssertFalse(edit.exists)

        heart.tap()
        XCTAssertTrue(toast(labeled: "已添加自选").waitForExistence(timeout: 4))
        XCTAssertTrue(edit.waitForExistence(timeout: 2))
        XCTAssertTrue(heart.isSelected)
        XCTAssertFalse(otherHeart.isSelected)
        XCTAssertEqual(heart.frame.midX, originalHeartCenter, accuracy: 1)
        XCTAssertLessThanOrEqual(name.frame.maxX, edit.frame.minX + 1)
        if originalNameFrame.maxX > edit.frame.minX {
            XCTAssertLessThan(name.frame.width, originalNameFrame.width)
        }

        edit.tap()
        let customGroup = app.buttons["自定义"].firstMatch
        XCTAssertTrue(customGroup.waitForExistence(timeout: 3))
        customGroup.tap()
        XCTAssertEqual(edit.value as? String, "自定义")

        heart.tap()
        XCTAssertTrue(toast(labeled: "已删除自选").waitForExistence(timeout: 6))
        XCTAssertFalse(heart.isSelected)
        XCTAssertFalse(edit.exists)
        XCTAssertEqual(heart.frame.midX, originalHeartCenter, accuracy: 1)
        XCTAssertEqual(name.frame.width, originalNameFrame.width, accuracy: 1)
    }

    func testFavoriteDemoUsesDeleteForEnglishActionAndToast() {
        openFavoriteDemo(language: "en")
        let heart = element("favoriteDemo.XOMO.toggle")
        XCTAssertTrue(heart.label.hasSuffix("Add to Watchlist"))

        heart.tap()
        let added = toast(labeled: "Added to Watchlist")
        XCTAssertTrue(added.waitForExistence(timeout: 3))
        XCTAssertTrue(heart.label.hasSuffix("Delete from Watchlist"))
        swipeUp(on: added)

        heart.tap()
        XCTAssertTrue(toast(labeled: "Deleted from Watchlist").waitForExistence(timeout: 4))
        XCTAssertTrue(heart.label.hasSuffix("Add to Watchlist"))
    }

    private var toasts: XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: "toast.message")
    }

    private var toast: XCUIElement {
        toasts.firstMatch
    }

    private func toast(labeled label: String) -> XCUIElement {
        toasts.matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    private func swipeUp(on toast: XCUIElement) {
        let center = toast.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.05, thenDragTo: center.withOffset(CGVector(dx: 0, dy: -48)))
    }

    private func startToastLoop() {
        launchApp()
        element("watchlist.debug.open").tap()
        let toggle = app.switches["debug.toast.simulation"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 4))
        XCTAssertEqual(toggle.value as? String, "0")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertTrue(toast.waitForExistence(timeout: 3), "The toast should appear with the Debug sheet still open")
    }

    private func openFavoriteDemo(language: String = "zh-Hans") {
        launchApp(language: language)
        element("mainTab.tab6").tap()
        let library = element("compare.componentLibrary")
        let demo = app.descendants(matching: .any)["compare.watchlistFavoriteDemo"].firstMatch
        let tabBarTop = element("mainTab.tab6").frame.minY
        for _ in 0..<4 {
            if demo.exists && demo.frame.midY < tabBarTop && demo.frame.midY > library.frame.minY { break }
            library.swipeUp()
        }
        XCTAssertTrue(demo.exists)
        demo.tap()
    }

    private func element(_ identifier: String) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing \(identifier)")
        return element
    }
}
