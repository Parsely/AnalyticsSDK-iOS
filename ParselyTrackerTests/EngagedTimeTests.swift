//
//  EngagedTimeTests.swift
//  ParselyTrackerTests
//
//  Created by Chris Wisecarver on 11/5/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker

class EngagedTimeTests: ParselyTestCase {
    func testHeartbeatFn() {
        let dummyEventArgs: Dictionary<String, Any> = parselyTestTracker.track.engagedTime.generateEventArgs(
            url: "http://parsely-stuff.com", urlref: "", extra_data: nil, idsite: testApikey)
        let dummyAccumulator: Accumulator = Accumulator(key: "", accumulatedTime: 0, totalTime: 0,
                                                        lastSampleTime: Date(), lastPositiveSampleTime: Date(),
                                                        heartbeatTimeout: 0, contentDuration: 0, isEngaged: false,
                                                        eventArgs: dummyEventArgs)
        parselyTestTracker.track.engagedTime.heartbeatFn(data: dummyAccumulator, enableHeartbeats: true)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Parsely.track.engagedTime.heartbeatFn should add an event to eventQueue")
    }
    
    func testStartInteraction() { XCTAssert(false, "not implemented") }
    func testEndInteraction() { XCTAssert(false, "not implemented") }
}
