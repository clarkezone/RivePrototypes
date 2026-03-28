//
//  RiveMenuPrototypesUITestsLaunchTests.swift
//  RiveMenuPrototypesUITests
//
//  Created by James Clarke on 3/24/26.
//

import XCTest

final class RiveMenuPrototypesUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
