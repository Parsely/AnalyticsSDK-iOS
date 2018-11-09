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
        XCTAssert(parselyTrackerInstance.accumulators.count == 0)
        self.parselyTrackerInstance.trackPlay(videoID: "videoId", metadata: [:], urlOverride: "")
        XCTAssert(parselyTrackerInstance.videoPlaying == true)
        XCTAssert(parselyTrackerInstance.accumulators.count == 0)
        
    }
}
