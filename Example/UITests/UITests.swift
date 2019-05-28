//
//  UITests.swift
//  UITests
//
//  Created by Josip Cavar on 28/05/2019.
//  Copyright © 2019 OwnTracks. All rights reserved.
//

import XCTest

class UITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
        self.app = XCUIApplication()
        self.app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFlow() {
        self.app.buttons["Connect/Disconnect"].tap()
        let connected = self.app.staticTexts["Connected"]
        XCTAssertTrue(connected.waitForExistence(timeout: 10))
        
        self.app.buttons["Subscribe/Unsubscribe"].tap()
        let subscribed = self.app.staticTexts["Subscribed"]
        XCTAssertTrue(subscribed.waitForExistence(timeout: 10))

    }
}
