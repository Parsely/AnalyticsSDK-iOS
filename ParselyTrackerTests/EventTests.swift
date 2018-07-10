//
//  EventTests.swift
//  ParselyTrackerTests
//
//  Created by Chris Wisecarver on 7/10/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker

class EventTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testBasic() {
        let now = Date()
        let evDict:[String: Any] = ["action": "pageview", "ts": now]
        let event = Event(params: evDict)
        let evJSON = event.toJSON()
        let jsonString:String = "{\"action\":\"pageview\",\"ts\":\"\(now.timeIntervalSince1970)\"}"
        assert(evJSON == jsonString)
    }
}

