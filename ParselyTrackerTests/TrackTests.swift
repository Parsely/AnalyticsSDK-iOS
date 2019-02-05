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
    let parselyTrackerInstance: Parsely = Parsely.sharedInstance
    let track: Track = Track()
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTrackPageView() {
        // TODO: test side effects of this function?
        // parselyBeacon.trackPageView(params: [:], shouldNotSetLastRequest: true)
        XCTAssert(true)
    }
}


