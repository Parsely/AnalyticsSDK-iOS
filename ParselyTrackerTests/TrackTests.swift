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
        XCTAssertEqual(parsely.eventQueue.length(), 0,
                       "Event queue should be empty before creating events.")
        let dummyEvent = Event("pageview", url: "http://parsely-stuff.com", urlref: "", metadata: nil, extra_data: nil)
        parsely.track.event(event: dummyEvent)
        XCTAssertEqual(parsely.eventQueue.length(), 1,
                       "Track should add an event into the eventQueue.")
    }
}


