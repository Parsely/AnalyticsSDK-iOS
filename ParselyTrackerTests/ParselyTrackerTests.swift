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

    func testConfigure() {
        let expected = "exampleparsely.com"
        // XXX this assertion failing indicates a lack of isolation between tests
        // this should be fixed by having each test set up and tear down its own Parsely object instead of having
        // all tests use the same Parsely.sharedInstance.
        XCTAssertEqual(parselyTracker.apikey, "",
                       "Before calls to Parsely.configure, Parsely.apikey should be the empty string")
        parselyTracker.configure(siteId: expected)
        XCTAssertEqual(parselyTracker.apikey, expected,
                       "After a call to Parsely.configure, Parsely.apikey should be the value used in the call's " +
                       "siteId argument")
    }
    
    func testTrackPageView() { XCTAssert(false, "not implemented") }
    func testStartEngagement() { XCTAssert(false, "not implemented") }
    func testStopEngagement() { XCTAssert(false, "not implemented") }
    func testTrackPlay() { XCTAssert(false, "not implemented") }
    func testTrackPause() { XCTAssert(false, "not implemented") }
}
