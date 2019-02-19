//
//  EngagedTimeTests.swift
//  ParselyTrackerTests
//
//  Created by Chris Wisecarver on 11/5/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker
import Foundation

class EngagedTimeTests: XCTestCase {
    
    let parsely: Parsely = Parsely.sharedInstance
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSampleFn() {
        // accumulators should be able to increase time
        parsely.startEngagement(url: "sampler-test")
        sleep(4)
        parsely.stopEngagement()
        dump(parsely.track.engagedTime.accumulators["sampler-test"])
        XCTAssert(parsely.track.engagedTime.accumulators["sampler-test"]!.totalTime > 0,
                  "The sampler should run as soon as an item is tracked.")
        XCTAssert(parsely.track.engagedTime.accumulators["sampler-test"]!.totalTime >= 3.8 * 1000,
                  "The sampler should collect information as long as the item is engaged.")
    }
    func testHeartbeatFn() {}
    func testStartInteraction() {}
    func testMultipleTrackedItems() {
        // should track engagement for different items, separately
        let itemOne: String = "itemOne"
        let itemTwo: String = "itemTwo"
        parsely.startEngagement(url: itemOne)
        parsely.startEngagement(url: itemTwo)
        // stop one after 2 seconds
        sleep(2)
        parsely.stopEngagement()
        sleep(2)
        parsely.stopEngagement()
        // they should be tracked separately
        dump(parsely.track.engagedTime.accumulators)
        XCTAssert(parsely.track.engagedTime.accumulators[itemOne]!.key != parsely.track.engagedTime.accumulators[itemTwo]!.key,
                  "The two items should not be tracked in the same Accumulator")
        XCTAssert(parsely.track.engagedTime.accumulators[itemOne]!.accumulatedTime < parsely.track.engagedTime.accumulators[itemTwo]!.accumulatedTime,
                  "Waiting for the second item should not add time to the first")
    }
    func testEndInteraction() {}
}
