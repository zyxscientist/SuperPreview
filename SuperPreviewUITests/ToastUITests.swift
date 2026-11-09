import XCTest

final class ToastUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments += [
            "-UITesting",
            "-compare.demo.interfaceLanguage", "zh-Hans",
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
        element("watchlist.debug.open").tap()
        element("debug.toast.queue").tap()

        let submitted = toast(labeled: "订单已提交")
        let addedToWatchlist = toast(labeled: "已添加到自选")
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
        element("watchlist.debug.open").tap()
        let toggle = app.switches["debug.toast.simulation"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 4))
        XCTAssertEqual(toggle.value as? String, "0")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertTrue(toast.waitForExistence(timeout: 3), "The toast should appear with the Debug sheet still open")
    }

    private func element(_ identifier: String) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing \(identifier)")
        return element
    }
}
