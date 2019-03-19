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
    
    // TODO: Video should test handling of duration, and storing of video metas (updateVideo)
    // TODO: should test reset() method
    
    func testTrackVideo() {
        let videoManager = parselyTrackerInstance.track.videoManager
        XCTAssert(videoManager.accumulators.count == 0,
                  "videoManager.accumulators should be empty before calling trackPlay")

        self.parselyTrackerInstance.trackPlay(url: "testurl", videoID: "videoId", duration: TimeInterval(0))

        XCTAssert(videoManager.accumulators.count == 1,
                  "A call to trackPlay should populate videoManager.accumulators with one object")

        self.parselyTrackerInstance.trackPause()

        XCTAssert(videoManager.accumulators.count == 1,
                  "A call to trackPause should not remove an accumulator from videoManager.accumulators")
        
    }
}
