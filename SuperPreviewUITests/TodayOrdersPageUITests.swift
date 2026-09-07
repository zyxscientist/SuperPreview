import XCTest

final class TodayOrdersPageUITests: XCTestCase {
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

    func testTodayOrdersPageExpandsRowsAndPinsHeader() throws {
        openTodayOrdersPage()

        let scroll = waitFor("todayOrders.scroll")
        let header = waitFor("todayOrders.header")
        XCTAssertTrue(waitFor("todayOrders.order.stock-order-demo-pending").exists)

        waitFor("stockOrder.todayOrder.summary").tap()
        XCTAssertTrue(waitFor("stockOrder.todayOrder.action.quote").exists)

        scroll.swipeUp()
        XCTAssertEqual(
            waitFor("todayOrders.header").frame.minY,
            scroll.frame.minY,
            accuracy: 2,
            "The table header should remain pinned below the custom navbar"
        )
        XCTAssertLessThanOrEqual(header.frame.minY, scroll.frame.maxY)
    }

    func testTodayOrdersPageSupportsCustomBackAndEdgeSwipe() throws {
        openTodayOrdersPage()

        waitFor("stockOrder.navbar.back").tap()
        XCTAssertTrue(waitFor("trade.root").exists)

        openTodayOrdersPage()
        performHorizontalDrag(fromX: 0.01, toX: 0.82)
        XCTAssertTrue(waitFor("trade.root").exists)
    }

    private func openTodayOrdersPage() {
        waitFor("mainTab.tab2").tap()
        XCTAssertTrue(waitFor("trade.root").exists)

        let todayOrders = app.buttons["今日订单"].firstMatch
        XCTAssertTrue(todayOrders.waitForExistence(timeout: 5), "Missing today's orders entry")
        todayOrders.tap()

        XCTAssertTrue(waitFor("todayOrders.page").exists)
        XCTAssertTrue(waitFor("todayOrders.navbar").exists)
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
        timeout: TimeInterval = 5
    ) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "Missing element: \(identifier)")
        return element
    }
}
