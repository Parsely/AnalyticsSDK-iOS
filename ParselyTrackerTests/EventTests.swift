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
    
//    func testBasic() {
//        let now = Date()
//        let evDict:[String: Any] = ["action": "pageview", "ts": now, "idsite": "example.com"]
//        let event = Event(params: evDict)
//        let evJSON = event.toJSON()
//        let jsonString:String = "{\"action\":\"pageview\",\"ts\":\(Int(now.timeIntervalSince1970 * 1000))}"
//        XCTAssert(evJSON == jsonString,
//                  "event.toJSON should produce valid JSON")
//    }

//    func testMetadataEncode() {
//        XCTAssert(false,
//                  "TODO: implement metadata encoding in Event class. Should take a Dictionary, encode to pretty-printedJSON, and ascii encode that. Formerly in Video class")
//    }

//    func testNested() {
//        let now = Date()
//        let dataDict: [String: Any] = ["slts": 12345, "_region": 24.74, "__things__": 1985]
//        let evDict:[String: Any] = ["action": "pageview", "ts": now, "data": dataDict, "idsite": "example.com"]
//        let event = Event(params: evDict)
//        let evJSON = event.toJSON()
//        let jsonString:String = "{\"action\":\"pageview\",\"ts\":\(Int(now.timeIntervalSince1970 * 1000))}"
//        XCTAssert(evJSON == jsonString,
//                  "event.toJSON should produce valid JSON with nested data")
//    }
    func testHeartbeatEvents() {
        var event = Heartbeat(
            "heartbeat",
            url: "http://test.com",
            urlref: nil,
            inc: 5,
            tt: 15,
            metadata: nil,
            extra_data: nil,
            idsite: "parsely-test.com"
        )
        XCTAssert(event.url == "http://test.com",
                  "Heartbeat events should handle inc and tt.")
        XCTAssert(event.inc == 5,
                  "Should initialize and preserve subclass parameters.")
        XCTAssert(event.idsite == "parsely-test.com",
                  "Should initialize and preserve subclass parameters.")
    }
    
    func testValidity() {
        // make an Event
        var event = Event("pageview", url: "http://test.com", urlref: nil, metadata: nil, extra_data: nil)
        XCTAssert(event.idsite == "parsely.com", "Events should automatically know which apikey to use.")
    }
}

