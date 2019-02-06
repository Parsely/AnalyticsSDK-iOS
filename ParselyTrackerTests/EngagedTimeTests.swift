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
        parsely.startEngagement(id: "sampler-test")
        sleep(4)
        parsely.stopEngagement(id: "sampler-test")
        dump(parsely.track.engagedTime.accumulators["sampler-test"])
        XCTAssert(parsely.track.engagedTime.accumulators["sampler-test"]!.totalMs > 0,
                  "The sampler should run as soon as an item is tracked.")
        XCTAssert(parsely.track.engagedTime.accumulators["sampler-test"]!.totalMs >= 3.8 * 1000,
                  "The sampler should collect information as long as the item is engaged.")
    }
    func testHeartbeatFn() {}
    func testStartInteraction() {}
    func testMultipleTrackedItems() {
        // should track engagement for different items, separately
        let itemOne: String = "itemOne"
        let itemTwo: String = "itemTwo"
        parsely.startEngagement(id: itemOne)
        parsely.startEngagement(id: itemTwo)
        // stop one after 2 seconds
        sleep(2)
        parsely.stopEngagement(id: itemOne)
        sleep(2)
        parsely.stopEngagement(id: itemTwo)
        // they should be tracked separately
        XCTAssert(parsely.track.engagedTime.accumulators[itemOne]!.id != parsely.track.engagedTime.accumulators[itemTwo]!.id,
                  "The two items should not be tracked in the same Accumulator")
        XCTAssert(parsely.track.engagedTime.accumulators[itemOne]!.ms > parsely.track.engagedTime.accumulators[itemTwo]!.ms,
                  "Waiting for the second item should not add time to the first")
    }
    func testEndInteraction() {}
}
