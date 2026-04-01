import XCTest

final class RiveLayoutUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Verifies the Rive canvas fills the available space on launch.
    func testCanvasFillsOnLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let riveCanvas = app.otherElements["riveCanvas"]
        XCTAssertTrue(riveCanvas.waitForExistence(timeout: 5), "Rive canvas should exist")
        sleep(1)

        let windowFrame = app.windows.firstMatch.frame
        let canvasFrame = riveCanvas.frame

        XCTAssertEqual(canvasFrame.width, windowFrame.width, accuracy: 2,
            "Canvas should span full window width")

        let bottomGap = windowFrame.height - (canvasFrame.origin.y + canvasFrame.height)
        XCTAssertLessThan(bottomGap, 30,
            "Gap below canvas (\(bottomGap)pt) should be minimal. " +
            "Canvas frame: \(canvasFrame), Window frame: \(windowFrame)")
    }

    /// Verifies the aspect ratio toggle button switches between layout and contain modes.
    /// Keeps the inspector open while toggling to observe the value change live.
    func testAspectRatioToggle() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(1)

        // Default state: lockAspectRatio = false, so button should say "Lock Aspect Ratio"
        let lockButton = app.buttons["Lock Aspect Ratio"]
        XCTAssertTrue(lockButton.waitForExistence(timeout: 3),
            "Should see 'Lock Aspect Ratio' button (layout mode is default)")

        // Open inspector
        let inspectorButton = app.buttons["Inspector"]
        inspectorButton.tap()
        sleep(2)

        // Verify initial fit mode is "layout"
        let fitModeValue = app.staticTexts["fitModeValue"]
        XCTAssertTrue(fitModeValue.waitForExistence(timeout: 3),
            "fitModeValue element should exist in inspector")
        XCTAssertEqual(fitModeValue.label, "layout",
            "Inspector should show fit mode as 'layout' initially, got: '\(fitModeValue.label)'")

        // Tap the button to lock aspect ratio (switch to contain)
        // The button is in the toolbar, still accessible with inspector open
        lockButton.tap()
        sleep(2)

        // Button label should now be "Unlock Aspect Ratio"
        let unlockButton = app.buttons["Unlock Aspect Ratio"]
        XCTAssertTrue(unlockButton.waitForExistence(timeout: 3),
            "After tapping, button should change to 'Unlock Aspect Ratio'")

        // Verify fit mode changed to "contain" in the still-open inspector
        let fitModeAfterLock = app.staticTexts["fitModeValue"]
        XCTAssertTrue(fitModeAfterLock.waitForExistence(timeout: 3),
            "fitModeValue should still exist after toggle")
        XCTAssertEqual(fitModeAfterLock.label, "contain",
            "Inspector should show 'contain' after locking, got: '\(fitModeAfterLock.label)'")

        // Tap again to unlock (switch back to layout)
        unlockButton.tap()
        sleep(2)

        // Button should be back to "Lock Aspect Ratio"
        let lockButtonAgain = app.buttons["Lock Aspect Ratio"]
        XCTAssertTrue(lockButtonAgain.waitForExistence(timeout: 3),
            "After second tap, button should revert to 'Lock Aspect Ratio'")

        // Verify fit mode is back to "layout"
        let fitModeAfterUnlock = app.staticTexts["fitModeValue"]
        XCTAssertTrue(fitModeAfterUnlock.waitForExistence(timeout: 3),
            "fitModeValue should still exist after second toggle")
        XCTAssertEqual(fitModeAfterUnlock.label, "layout",
            "Inspector should show 'layout' after unlocking, got: '\(fitModeAfterUnlock.label)'")
    }
}
