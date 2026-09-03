import XCTest

final class StockOrderConfirmationSheetUITests: XCTestCase {
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

    func testConfirmationCardUsesContentHeightAndKeepsLastRowSpacing() throws {
        enterStockOrder()
        presentConfirmation(side: "buy")

        let card = waitFor("stockOrder.confirmationSheet")
        let lastRow = waitFor("stockOrder.confirmationSheet.row.effectPeriod")
        let lastRowBottomSpacing = waitFor(
            "stockOrder.confirmationSheet.lastRowBottomSpacing"
        )
        let buttons = waitFor("stockOrder.confirmationSheet.buttons")
        let window = app.windows.firstMatch

        waitForPresentationToSettle()

        XCTAssertTrue(waitFor("stockOrder.demo").exists)
        XCTAssertEqual(card.frame.maxY, window.frame.maxY, accuracy: 2)
        XCTAssertLessThan(
            card.frame.height,
            window.frame.height - 100,
            "The confirmation card should size itself to its content"
        )
        XCTAssertEqual(
            lastRowBottomSpacing.frame.height,
            10,
            accuracy: 1,
            "The last row should keep a 10pt gap before the button separator"
        )
        XCTAssertGreaterThanOrEqual(
            lastRowBottomSpacing.frame.minY,
            lastRow.frame.maxY,
            "The 10pt spacing should follow the last detail row"
        )
        XCTAssertEqual(
            buttons.frame.minY,
            lastRowBottomSpacing.frame.maxY,
            accuracy: 1,
            "The button separator should follow the 10pt spacing"
        )
    }

    func testDimmingTapCancelAndConfirmDismissConfirmation() throws {
        enterStockOrder()

        let firstSheet = presentConfirmation(side: "buy")
        let window = app.windows.firstMatch
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()
        waitForDisappearance(firstSheet)

        let secondSheet = presentConfirmation(side: "buy")
        waitFor("stockOrder.confirmationSheet.button.cancel").tap()
        waitForDisappearance(secondSheet)

        let thirdSheet = presentConfirmation(side: "sell")
        waitFor("stockOrder.confirmationSheet.button.confirm").tap()
        waitForDisappearance(thirdSheet)
    }

    func testShortDragReboundsLongDragDismissesAndCanReopen() throws {
        enterStockOrder()

        let sheet = presentConfirmation(side: "buy")
        let initialFrame = sheet.frame
        dragSheet(sheet, distanceFraction: 0.12)

        XCTAssertTrue(sheet.waitForExistence(timeout: 2))
        waitForPresentationToSettle()
        XCTAssertEqual(
            sheet.frame.minY,
            initialFrame.minY,
            accuracy: 4,
            "A short downward drag should rebound to its original position"
        )

        dragSheet(sheet, distanceFraction: 0.35)
        waitForDisappearance(sheet)

        XCTAssertTrue(presentConfirmation(side: "sell").exists)
    }

    func testConfirmIsOneShotAndCanReopen() throws {
        enterStockOrder()

        let sheet = presentConfirmation(side: "buy")
        let confirm = waitFor("stockOrder.confirmationSheet.button.confirm")
        confirm.doubleTap()
        waitForDisappearance(sheet)

        XCTAssertEqual(
            waitFor("stockOrder.confirmation.confirmCount").label,
            "1",
            "A double tap must invoke the confirmation callback only once"
        )
        XCTAssertTrue(presentConfirmation(side: "buy").exists)
    }

    @discardableResult
    private func presentConfirmation(side: String) -> XCUIElement {
        waitFor("stockOrder.tradeActionBar.\(side)").tap()
        return waitFor("stockOrder.confirmationSheet")
    }

    private func enterStockOrder() {
        waitFor("mainTab.tab6").tap()
        XCTAssertTrue(waitFor("compare.componentLibrary").exists)
        waitFor("compare.stockOrder").tap()
        XCTAssertTrue(waitFor("stockOrder.demo").exists)

        waitFor("stockOrder.symbolInput.emptyField").tap()
        // The search box's container owns the accessibility identifier in the
        // composed SwiftUI hierarchy, while the editable control remains a
        // text field with that same identifier.
        let query = waitForTextField("stockOrder.symbolSearchSheet.searchBox")
        query.tap()
        query.typeText("09988")
        waitFor("stockOrder.symbolSearchSheet.result.09988").tap()
        XCTAssertTrue(waitFor("stockOrder.symbolInput.selectedSymbol").exists)
    }

    private func dragSheet(_ sheet: XCUIElement, distanceFraction: CGFloat) {
        let start = sheet.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)
        )
        let end = sheet.coordinate(
            withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08 + distanceFraction)
        )
        start.press(
            forDuration: 0.05,
            thenDragTo: end,
            withVelocity: 100,
            thenHoldForDuration: 0
        )
    }

    private func waitForPresentationToSettle() {
        sleep(1)
    }

    private func waitForDisappearance(
        _ element: XCUIElement,
        timeout: TimeInterval = 4,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Element did not disappear", file: file, line: line)
    }

    @discardableResult
    private func waitFor(
        _ identifier: String,
        timeout: TimeInterval = 8,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Missing element: \(identifier)",
            file: file,
            line: line
        )
        return element
    }

    @discardableResult
    private func waitForTextField(
        _ identifier: String,
        timeout: TimeInterval = 8,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let textField = app.textFields[identifier].firstMatch
        XCTAssertTrue(
            textField.waitForExistence(timeout: timeout),
            "Missing text field: \(identifier)",
            file: file,
            line: line
        )
        return textField
    }
}
