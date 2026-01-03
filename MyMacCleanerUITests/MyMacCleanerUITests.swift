import XCTest

final class MyMacCleanerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify main window appears
        XCTAssertTrue(app.windows.firstMatch.exists)
    }

    @MainActor
    func testSidebarNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // Basic navigation test
        let sidebar = app.outlines.firstMatch
        XCTAssertTrue(sidebar.waitForExistence(timeout: 5))
    }
}
