//
//  ParselyTrackerTests.swift
//  ParselyTrackerTests
//
//  Created by Chris Wisecarver on 7/6/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker

class ParselyTrackerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    let parselyTracker: Parsely = Parsely.sharedInstance
    
    // TODO: implement complete public API testing here, not in the demo app

    func testConfigure() { XCTAssert(false, "not implemented") }
    func testTrackPageView() { XCTAssert(false, "not implemented") }
    func testStartEngagement() { XCTAssert(false, "not implemented") }
    func testStopEngagement() { XCTAssert(false, "not implemented") }
    func testTrackPlay() { XCTAssert(false, "not implemented") }
    func testTrackPause() { XCTAssert(false, "not implemented") }
}
