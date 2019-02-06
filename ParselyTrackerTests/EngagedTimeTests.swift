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
    
    func testSampleFn() {}
    func testHeartbeatFn() {}
    func testStartInteraction() {}
    func testMultipleTrackedItems() {
        // should track engagement for different items, separately
        let itemOne: String = "itemOne"
        let itemTwo: String = "itemTwo"
        parsely.startEngagement(id: itemOne)
        parsely.startEngagement(id: itemTwo)
        // stop one after 2 seconds
        // wait 2 seconds
        parsely.stopEngagement(id: itemOne)
        // wait another 2 seconds
        parsely.stopEngagement(id: itemTwo)
        // they should be tracked separately
        XCTAssert(parsely.track.engagedTime.accumulators[itemOne]!.id != parsely.track.engagedTime.accumulators[itemTwo]!.id,
                  "The two items should not be tracked in the same Accumulator")
        XCTAssert(parsely.track.engagedTime.accumulators[itemOne]!.ms > parsely.track.engagedTime.accumulators[itemTwo]!.ms,
                  "Waiting for the second item should not add time to the first")
    }
    func testEndInteraction() {}
}
