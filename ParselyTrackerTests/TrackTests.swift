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
        // TODO: Test that events make it into the event queue.
        let eventQueue = parsely.eventQueue
        XCTAssertEqual(eventQueue.length(), 0,
                       "Event queue should be empty before creating events.")
        let event = Event("pageview", url: "http://parsely-stuff.com", urlref: "", metadata: nil, extra_data: nil)
        _ = parsely.track.event(event: event)
        // FIXME: This seems to work in smoke testing; it's unclear how threads or the testing environment
        // might affect things not being added to the queue.
        XCTAssertEqual(eventQueue.length(), 1,
                       "Track should add an event into the eventQueue.")
    }
}


