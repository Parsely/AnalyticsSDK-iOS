//
//  VideoTests.swift
//  ParselyTrackerTests
//
//  Created by Chris Wisecarver on 11/5/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker

class VideoTests: ParselyTestCase {
    func testTrackVideo() {
        let videoManager = parselyTestTracker.track.videoManager
        XCTAssert(videoManager.accumulators.count == 0,
                  "videoManager.accumulators should be empty before calling trackPlay")
        parselyTestTracker.trackPlay(url: "testurl", videoID: "videoId", duration: TimeInterval(0))
        XCTAssert(videoManager.accumulators.count == 1,
                  "A call to trackPlay should populate videoManager.accumulators with one object")
        parselyTestTracker.trackPause()
        XCTAssert(videoManager.accumulators.count == 1,
                  "A call to trackPause should not remove an accumulator from videoManager.accumulators")
    }
    
    func testReset() {
        let testUrl: String = "testurl"
        let testVideoId: String = "videoId"
        let videoManager = parselyTestTracker.track.videoManager
        videoManager.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                               metadata: nil, extra_data: nil, idsite: testApikey)
        videoManager.reset(url: testUrl, vId: testVideoId)
        XCTAssertEqual(videoManager.trackedVideos.count, 0,
                  "A call to Parsely.track.videoManager.reset should remove an accumulator from videoManager.accumulators")
    }
    func testUpdateVideoMetadata() { XCTAssert(false, "not implemented") }
}
