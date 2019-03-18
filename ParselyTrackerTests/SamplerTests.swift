//
//  SamplerTests.swift
//  ParselyTrackerTests
//
//  Created by Ashley Drake on 2/5/19.
//  Copyright © 2019 Parse.ly. All rights reserved.
//
import XCTest
@testable import ParselyTracker
import Foundation

class SamplerTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testMultipleTrackedItemsInOneSampler() {
        // should track engagement for different items, separately
        let itemOne: String = "itemOne"
        let itemTwo: String = "itemTwo"
        let sampler = Sampler()
        sampler.trackKey(key: itemOne, contentDuration: TimeInterval(30), eventArgs: [:])
        sampler.trackKey(key: itemTwo, contentDuration: TimeInterval(30), eventArgs: [:])

        // they should be tracked separately
        XCTAssert(sampler.accumulators[itemOne]!.key != sampler.accumulators[itemTwo]!.key,
                  "The two items should not be tracked in the same Accumulator")
    }

    func testSampleFn() {
        let samplerUnderTest = Sampler()
        let assertionTimeout:TimeInterval = TimeInterval(3)
        let acceptableDifference:TimeInterval = TimeInterval(0.2)
        
        samplerUnderTest.trackKey(key: "sampler-test", contentDuration: TimeInterval(30), eventArgs: [:])
        
        let expectation = self.expectation(description: "Sampling")
        Timer.scheduledTimer(withTimeInterval: assertionTimeout, repeats: false) { timer in
            expectation.fulfill()
        }
        waitForExpectations(timeout: assertionTimeout + acceptableDifference, handler: nil)
        
        let accumulatedTime:TimeInterval = samplerUnderTest.accumulators["sampler-test"]!.totalTime
        XCTAssert(accumulatedTime >= assertionTimeout - acceptableDifference,
                  "The sampler should accumulate time constantly after a call to trackKey")
    }

    func testUpdateGlobalHeartbeatInterval() {
        // tracking a new key should result in changing the global heartbeat interval
        let sampler = Sampler()
        let initialHbValue = sampler.heartbeatInterval

        // Borken: The heartbeat interval does NOT update with duration changes. This needs to be fixed.
        sampler.trackKey(key: "testKey", contentDuration: TimeInterval(10), eventArgs: [:])
        let newHbValue = sampler.heartbeatInterval
        XCTAssert(newHbValue != initialHbValue, "A shorter content duration should decrease the global timeout.")
        XCTAssert(newHbValue == TimeInterval(floatLiteral: 2.0), "10s content duration should account for all completion intervals.")
    }
    
    func testDumbBackoff() {
        // don't kill our backend with long-running videos
        let sampler = Sampler()
        let initialHbValue = sampler.heartbeatInterval
        // very long videos should have longer intervals
        sampler.trackKey(key: "longVideo", contentDuration: TimeInterval(1000), eventArgs: [:])
        let updatedHbValue = sampler.heartbeatInterval
        // Borken: The heartbeat interval does not update with duration changes, as it should
        // FIXME:
        XCTAssertNotEqual(initialHbValue, updatedHbValue,
                  "Should lengthen the base heartbeat for longer videos.")
        XCTAssertEqual(updatedHbValue, initialHbValue * 2,
                       "Should double the heartbeat interval for very long videos.")
    }

    func testDistinctTrackedItems() {
        // each sampler should handle it's own tracked items
        let sampler1 = Sampler()
        let sampler2 = Sampler()
        // track the same key, but for different reasons
        sampler1.trackKey(key: "thing", contentDuration: TimeInterval(floatLiteral: 30), eventArgs: [:])
        sampler2.trackKey(key: "thing", contentDuration: TimeInterval(floatLiteral: 30), eventArgs: [:])
        // dropping a key shouldn't affect the other sampler
        sampler1.dropKey(key: "thing")
        XCTAssert(sampler2.accumulators["thing"] != nil,
                  "Dropping a key in one sampler shouldn't drop it in the other.")
    }
}
