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

    func testUpdateGlobalHeartbeatInterval() {
        // tracking a new key should result in changing the global heartbeat interval
        let sampler = Sampler()
        let initialHbValue = sampler.heartbeatInterval
        XCTAssert(initialHbValue == TimeInterval(floatLiteral: 10.5))

        sampler.trackKey(key: "testKey", contentDuration: TimeInterval(floatLiteral: 10.0))
        let newHbValue = sampler.heartbeatInterval
        XCTAssert(newHbValue != initialHbValue, "A shorter content duration should decrease the global timeout.")
        XCTAssert(newHbValue == TimeInterval(floatLiteral: 2.0), "10s content duration should account for all completion intervals.")
    }
}
