import XCTest
import CoreGraphics

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
    func testAspectRatioToggle() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(1)

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

        // Toggle to contain
        lockButton.tap()
        sleep(2)

        let unlockButton = app.buttons["Unlock Aspect Ratio"]
        XCTAssertTrue(unlockButton.waitForExistence(timeout: 3),
            "After tapping, button should change to 'Unlock Aspect Ratio'")

        let fitModeAfterLock = app.staticTexts["fitModeValue"]
        XCTAssertTrue(fitModeAfterLock.waitForExistence(timeout: 3))
        XCTAssertEqual(fitModeAfterLock.label, "contain",
            "Inspector should show 'contain' after locking, got: '\(fitModeAfterLock.label)'")

        // Toggle back to layout
        unlockButton.tap()
        sleep(2)

        let lockButtonAgain = app.buttons["Lock Aspect Ratio"]
        XCTAssertTrue(lockButtonAgain.waitForExistence(timeout: 3),
            "After second tap, button should revert to 'Lock Aspect Ratio'")

        let fitModeAfterUnlock = app.staticTexts["fitModeValue"]
        XCTAssertTrue(fitModeAfterUnlock.waitForExistence(timeout: 3))
        XCTAssertEqual(fitModeAfterUnlock.label, "layout",
            "Inspector should show 'layout' after unlocking, got: '\(fitModeAfterUnlock.label)'")
    }

    /// Verifies that toggling fit mode with the Layout Test file causes Rive to visually
    /// re-render by sampling pixel colors at the canvas corners.
    ///
    /// Layout Test has a dark grey background with boxes pinned to corners.
    /// - In layout mode: the dark grey fills edge-to-edge, so corners are dark.
    /// - In contain mode: the artboard is letterboxed, so corners are white/light (empty).
    func testLayoutToggleChangesRenderedPixels() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(1)

        let riveCanvas = app.otherElements["riveCanvas"]
        XCTAssertTrue(riveCanvas.waitForExistence(timeout: 5), "Rive canvas should exist")

        // Open inspector and select Layout Test
        let inspectorButton = app.buttons["Inspector"]
        inspectorButton.tap()
        sleep(1)

        let picker = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Digging Dinosaurs'")).firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 3), "Animation picker should exist")
        picker.tap()
        sleep(1)
        let layoutOption = app.buttons["Layout Test"]
        XCTAssertTrue(layoutOption.waitForExistence(timeout: 2), "Layout Test option should exist")
        layoutOption.tap()
        sleep(3)

        // Close inspector
        let closeButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'xmark'")).firstMatch
        if closeButton.exists { closeButton.tap() }
        sleep(1)

        // --- Layout mode: grey should fill the canvas corners ---
        let layoutScreenshot = riveCanvas.screenshot()
        let layoutAttachment = XCTAttachment(screenshot: layoutScreenshot)
        layoutAttachment.name = "Canvas - Layout Mode"
        layoutAttachment.lifetime = .keepAlways
        add(layoutAttachment)

        let layoutCornerBrightness = averageCornerBrightness(of: layoutScreenshot.image)
        // In layout mode, corners should be dark (the grey Rive background)
        XCTAssertLessThan(layoutCornerBrightness, 0.5,
            "In layout mode, canvas corners should be dark (Rive grey background fills edge-to-edge). " +
            "Corner brightness: \(layoutCornerBrightness)")

        // --- Toggle to contain mode ---
        let lockButton = app.buttons["Lock Aspect Ratio"]
        XCTAssertTrue(lockButton.waitForExistence(timeout: 3))
        lockButton.tap()
        sleep(3)

        let containScreenshot = riveCanvas.screenshot()
        let containAttachment = XCTAttachment(screenshot: containScreenshot)
        containAttachment.name = "Canvas - Contain Mode"
        containAttachment.lifetime = .keepAlways
        add(containAttachment)

        let containCornerBrightness = averageCornerBrightness(of: containScreenshot.image)
        // In contain mode, corners should be light (white letterbox padding)
        XCTAssertGreaterThan(containCornerBrightness, 0.5,
            "In contain mode, canvas corners should be light (letterbox padding). " +
            "Corner brightness: \(containCornerBrightness)")

        // --- Toggle back to layout ---
        let unlockButton = app.buttons["Unlock Aspect Ratio"]
        XCTAssertTrue(unlockButton.waitForExistence(timeout: 3))
        unlockButton.tap()
        sleep(3)

        let restoredScreenshot = riveCanvas.screenshot()
        let restoredAttachment = XCTAttachment(screenshot: restoredScreenshot)
        restoredAttachment.name = "Canvas - Layout Mode (restored)"
        restoredAttachment.lifetime = .keepAlways
        add(restoredAttachment)

        let restoredCornerBrightness = averageCornerBrightness(of: restoredScreenshot.image)
        XCTAssertLessThan(restoredCornerBrightness, 0.5,
            "After restoring layout mode, corners should be dark again. " +
            "Corner brightness: \(restoredCornerBrightness)")
    }

    // MARK: - Helpers

    /// Samples a small region at each corner of the image and returns the average brightness (0=black, 1=white).
    private func averageCornerBrightness(of image: UIImage) -> CGFloat {
        guard let cgImage = image.cgImage else { return 0.5 }

        let width = cgImage.width
        let height = cgImage.height
        let sampleSize = max(10, min(width, height) / 20) // ~5% of the shorter dimension

        // Sample 4 corners
        let corners: [(x: Int, y: Int)] = [
            (0, 0),                                     // top-left
            (width - sampleSize, 0),                    // top-right
            (0, height - sampleSize),                   // bottom-left
            (width - sampleSize, height - sampleSize),  // bottom-right
        ]

        var totalBrightness: CGFloat = 0

        for corner in corners {
            totalBrightness += sampleBrightness(of: cgImage, x: corner.x, y: corner.y, size: sampleSize)
        }

        return totalBrightness / CGFloat(corners.count)
    }

    /// Returns average brightness (0–1) of a square region in the image.
    private func sampleBrightness(of cgImage: CGImage, x: Int, y: Int, size: Int) -> CGFloat {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * size
        var pixelData = [UInt8](repeating: 0, count: size * size * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return 0.5 }

        context.draw(cgImage, in: CGRect(x: -x, y: -(cgImage.height - y - size), width: cgImage.width, height: cgImage.height))

        var totalBrightness: CGFloat = 0
        let pixelCount = size * size

        for i in 0..<pixelCount {
            let offset = i * bytesPerPixel
            let r = CGFloat(pixelData[offset]) / 255.0
            let g = CGFloat(pixelData[offset + 1]) / 255.0
            let b = CGFloat(pixelData[offset + 2]) / 255.0
            // Perceived brightness (ITU-R BT.601)
            totalBrightness += 0.299 * r + 0.587 * g + 0.114 * b
        }

        return totalBrightness / CGFloat(pixelCount)
    }
}
