//
//  ParselyTrackerTests.swift
//  ParselyTrackerTests
//
//  Created by Chris Wisecarver on 7/6/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker

class ParselyTrackerTests: ParselyTestCase {
    func testConfigure() {
        let expected = "exampleparsely.com"
        // XXX this assertion failing indicates a lack of isolation between tests
        // this should be fixed by having each test set up and tear down its own Parsely object instead of having
        // all tests use the same Parsely.sharedInstance.
        XCTAssertEqual(parselyTestTracker.apikey, "",
                       "Before calls to Parsely.configure, Parsely.apikey should be the empty string")
        parselyTestTracker.configure(siteId: expected)
        XCTAssertEqual(parselyTestTracker.apikey, expected,
                       "After a call to Parsely.configure, Parsely.apikey should be the value used in the call's " +
                       "siteId argument")
    }
    
    func testTrackPageView() {
        let testApikey = "example.com"
        parselyTestTracker.configure(siteId: testApikey)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 0, "eventQueue should be empty immediately after initialization")
        parselyTestTracker.trackPageView(url: "http://example.com/testurl", urlref: "http://example.com/testurl",
                                         metadata: nil, extraData: nil)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Parsely.trackPageView should add an event to eventQueue")
    }
    
    func testStartEngagement() { XCTAssert(false, "not implemented") }
    func testStopEngagement() { XCTAssert(false, "not implemented") }
    func testTrackPlay() { XCTAssert(false, "not implemented") }
    func testTrackPause() { XCTAssert(false, "not implemented") }
}
