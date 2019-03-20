//
//  SamplerTests.swift
//  ParselyTrackerTests
//
//  Created by Ashley Drake on 2/5/19.
//  Copyright © 2019 Parse.ly. All rights reserved.
//
import XCTest
@testable import ParselyTracker

class SamplerTests: ParselyTestCase {
    func testMultipleTrackedItemsInOneSampler() {
        let itemOne: String = "itemOne"
        let itemTwo: String = "itemTwo"
        let samplerUnderTest = Sampler(trackerInstance: parselyTestTracker)
        samplerUnderTest.trackKey(key: itemOne, contentDuration: nil, eventArgs: [:])
        samplerUnderTest.trackKey(key: itemTwo, contentDuration: nil, eventArgs: [:])

        XCTAssert(samplerUnderTest.accumulators[itemOne]!.key != samplerUnderTest.accumulators[itemTwo]!.key,
                  "Sequential calls to trackKey with different keys should not clobber each other's accumulator data")
    }

    func testSampleFn() {
        let samplerUnderTest = Sampler(trackerInstance: parselyTestTracker)
        let assertionTimeout:TimeInterval = TimeInterval(3)
        let acceptableDifference:TimeInterval = TimeInterval(0.2)
        
        samplerUnderTest.trackKey(key: "sampler-test", contentDuration: nil, eventArgs: [:])
        
        let expectation = self.expectation(description: "Sampling")
        Timer.scheduledTimer(withTimeInterval: assertionTimeout, repeats: false) { timer in
            expectation.fulfill()
        }
        waitForExpectations(timeout: assertionTimeout + acceptableDifference, handler: nil)
        
        let accumulatedTime:TimeInterval = samplerUnderTest.accumulators["sampler-test"]!.totalTime
        XCTAssert(accumulatedTime >= assertionTimeout - acceptableDifference,
                  "The sampler should accumulate time constantly after a call to trackKey")
    }

    func testBackoff() {
        let samplerUnderTest = Sampler(trackerInstance: parselyTestTracker)
        let initialInterval = samplerUnderTest.heartbeatInterval
        let expectedBackoffMultiplier = 1.25
        let expectedUpdatedInterval = initialInterval * expectedBackoffMultiplier
        let assertionTimeout:TimeInterval = initialInterval + TimeInterval(2)
        
        samplerUnderTest.trackKey(key: "sampler-test", contentDuration: nil, eventArgs: [:])
        
        let expectation = self.expectation(description: "Wait for heartbeat")
        Timer.scheduledTimer(withTimeInterval: assertionTimeout, repeats: false) { timer in
            expectation.fulfill()
        }
        waitForExpectations(timeout: assertionTimeout, handler: nil)
        
        let actualUpdatedInterval = samplerUnderTest.heartbeatInterval
        XCTAssertEqual(actualUpdatedInterval, expectedUpdatedInterval,
                  "Heartbeat interval should increase by the expected amount after a single heartbeat")
    }

    func testDistinctTrackedItems() {
        let sampler1 = Sampler(trackerInstance: parselyTestTracker)
        let sampler2 = Sampler(trackerInstance: parselyTestTracker)
        sampler1.trackKey(key: "thing", contentDuration: nil, eventArgs: [:])
        sampler2.trackKey(key: "thing", contentDuration: nil, eventArgs: [:])
        sampler1.dropKey(key: "thing")
        XCTAssert(sampler2.accumulators["thing"] != nil,
                  "A Sampler instance should not be affected by dropKey calls on another Sampler instance")
    }
}
