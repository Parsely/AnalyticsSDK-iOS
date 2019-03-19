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
        let samplerUnderTest = Sampler()
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
