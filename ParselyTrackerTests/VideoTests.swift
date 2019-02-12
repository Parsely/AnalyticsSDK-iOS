//
//  VideoTests.swift
//  ParselyTrackerTests
//
//  Created by Chris Wisecarver on 11/5/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker
import Foundation

class VideoTests: XCTestCase {
    var parselyTrackerInstance: Parsely = Parsely.sharedInstance
    
    override func setUp() {
        super.setUp()
    }
    override func tearDown() {
        super.tearDown()
    }
    
    func testTrackVideo() {
        // pre-track state
        let videoManager = parselyTrackerInstance.track.videoManager
        XCTAssert(videoManager.accumulators.count == 0,
                  "Parsely.sharedInstance.accumulators should be empty before calling trackPlay")

        // call trackPlay
        self.parselyTrackerInstance.trackPlay(url: "testurl", videoID: "videoId", qsargs: [:])

        // post-track state
        XCTAssert(videoManager.accumulators.count == 1,
                  "trackPlay should populate Parsely.sharedInstance.accumulators with one object")

        // call trackPause
        self.parselyTrackerInstance.trackPause(url: "testurl", videoID: "videoId", qsargs: [:])

        // post-pause state
        XCTAssert(videoManager.accumulators.count == 1,
                  "trackPause should not remove an accumulator from Parsely.sharedInstance.accumulators")
        
    }
}
