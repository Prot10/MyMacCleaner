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

        // Wait for main window to appear with timeout
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 10), "Main window should appear")
    }

    @MainActor
    func testSidebarNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for main window to appear
        let mainWindow = app.windows.firstMatch
        XCTAssertTrue(mainWindow.waitForExistence(timeout: 10), "Main window should appear")

        // Give the app time to fully load its content
        Thread.sleep(forTimeInterval: 1)

        // Verify the app has loaded by checking for split view content
        // NavigationSplitView creates groups for sidebar and detail
        let hasContent = app.groups.count > 0 || app.scrollViews.count > 0
        XCTAssertTrue(hasContent, "App should have navigation content")
    }
}
