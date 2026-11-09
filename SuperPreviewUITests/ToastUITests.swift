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

        let center = toast.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.05, thenDragTo: center.withOffset(CGVector(dx: 0, dy: -48)))
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

    private var toast: XCUIElement {
        app.descendants(matching: .any)["toast.message"].firstMatch
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
