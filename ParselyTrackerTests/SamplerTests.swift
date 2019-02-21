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
        // accumulators should be able to increase time
        let sampler = Sampler()
        // FIXME: The tests for Sampler do not run because the test environment never starts the sampling thread.
        // This has something to do with run loops and threads... but it is very unclear exactly how to make it work.
        // The fix would be finding a way to make sure the testing process has the ability to start the sampler threads
        // for video and engaged time, and also for a directly-created Sampler.
        sampler.trackKey(key: "sampler-test", contentDuration: TimeInterval(30), eventArgs: [:])
        XCTAssert(sampler.accumulators["sampler-test"]!.totalTime > 0,
                  "The sampler should run as soon as an item is tracked.")
        XCTAssert(sampler.accumulators["sampler-test"]!.totalTime >= 3.8 * 1000,
                  "The sampler should collect information as long as the item is engaged.")
    }

    func testUpdateGlobalHeartbeatInterval() {
        // tracking a new key should result in changing the global heartbeat interval
        let sampler = Sampler()
        let initialHbValue = sampler.heartbeatInterval
        // FIXME: This repo is structured as a workspace, which can contain many projects, but all of our
        // code is inside one project. This means that the ParselyTracker library, although it is separate from
        // the DemoApp, still uses the same project file and thus uses the AppDelegate to run tests.
        // Because our AppDelegate configures the tracker to have 8 seconds instead of the default, that's what
        // we should expect here.
        // Fix: Separate the SDK code into a completely separate project, then link it as a dependency to the demo app.
        XCTAssert(initialHbValue == TimeInterval(floatLiteral: 8.0))

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
