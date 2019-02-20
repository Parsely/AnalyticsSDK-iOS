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
    
    // TODO: implement better ET tests.
    // SamplerTests tests the underlying accumulators/sampler class
    // ET should test the results of the heartbeatFn, samplerFn, calling its internal public API

    func testHeartbeatFn() {}
    func testStartInteraction() {}
    func testEndInteraction() {}
}
