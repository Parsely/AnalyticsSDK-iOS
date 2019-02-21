//
//  ParselyTrackerTests.swift
//  ParselyTrackerTests
//
//  Created by Chris Wisecarver on 7/6/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker

class ParselyTrackerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    let parselyTracker: Parsely = Parsely.sharedInstance
    
    // TODO: implement complete public API testing here, not in the demo app
    // TODO: separate the library into a separate xcode project from the demo app

    func testConfigure() {}
    func testTrackPageView() {}
    func testStartEngagement() {}
    func testStopEngagement() {}
    func testTrackPlay() {}
    func testTrackPause() {}
    
    func testPerformanceExample() {
        // TODO
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
