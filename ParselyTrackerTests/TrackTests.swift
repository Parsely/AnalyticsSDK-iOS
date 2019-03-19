//
//  BeaconTests.swift
//  ParselyTrackerTests
//
//  Created by Chris Wisecarver on 11/5/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//
import XCTest
@testable import ParselyTracker
import Foundation

class TrackTests: XCTestCase {
    let parsely: Parsely = Parsely.sharedInstance
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTrackEvent() {
        XCTAssertEqual(parsely.eventQueue.length(), 0, "eventQueue should be empty immediately after initialization")
        let dummyEvent = Event("pageview", url: "http://parsely-stuff.com", urlref: "", metadata: nil, extra_data: nil)
        parsely.track.event(event: dummyEvent)
        XCTAssertEqual(parsely.eventQueue.length(), 1,
                       "A call to Parsely.track.event should add an event to eventQueue")
    }
}


