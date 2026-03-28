//
//  RiveMenuPrototypesUITests.swift
//  RiveMenuPrototypesUITests
//
//  Created by James Clarke on 3/24/26.
//

import XCTest

final class RiveMenuPrototypesUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
