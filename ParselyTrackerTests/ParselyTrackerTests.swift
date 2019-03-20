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
    let testApikey: String = "examplesite.com"
    let testUrl = "http://example.com/testurl"
    
    override func setUp() {
        super.setUp()
        parselyTestTracker.configure(siteId: testApikey)
    }
    
    func testConfigure() {
        XCTAssertEqual(parselyTestTracker.apikey, testApikey,
                       "After a call to Parsely.configure, Parsely.apikey should be the value used in the call's " +
                       "siteId argument")
    }
    
    func testTrackPageView() {
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 0,
                       "eventQueue should be empty immediately after initialization")
        parselyTestTracker.trackPageView(url: testUrl, urlref: testUrl, metadata: nil, extraData: nil)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Parsely.trackPageView should add an event to eventQueue")
    }
    
    func testStartEngagement() {
        parselyTestTracker.startEngagement(url: testUrl)
        let internalAccumulators:Dictionary<String, Accumulator> = parselyTestTracker.track.engagedTime.accumulators
        let testUrlAccumulator: Accumulator = internalAccumulators[testUrl]!
        XCTAssert(testUrlAccumulator.isEngaged,
                  "After a call to Parsely.startEngagement, the internal accumulator for the engaged url should exist " +
                  "and its isEngaged flag should be set")
    }
    func testStopEngagement() {
        parselyTestTracker.startEngagement(url: testUrl)
        parselyTestTracker.stopEngagement()
        let internalAccumulators:Dictionary<String, Accumulator> = parselyTestTracker.track.engagedTime.accumulators
        let testUrlAccumulator: Accumulator = internalAccumulators[testUrl]!
        XCTAssertFalse(testUrlAccumulator.isEngaged,
                  "After a call to Parsely.startEngagement followed by a call to Parsely.stopEngagement, the internal " +
                  "accumulator for the engaged url should exist and its isEngaged flag should be unset")
    }
    func testTrackPlay() { XCTAssert(false, "not implemented") }
    func testTrackPause() { XCTAssert(false, "not implemented") }
}
