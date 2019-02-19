//
//  RequestBuilderTests.swift
//  ParselyTrackerTests
//
//  Created by Ashley Drake on 2/7/19.
//  Copyright © 2019 Parse.ly. All rights reserved.
//

import Foundation
@testable import ParselyTracker
import XCTest

class RequestBuilderTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    private func makeEvents() -> Array<Event> {
        return [Event(
            "pageview",
            url: "http://test.com",
            urlref: nil,
            metadata: nil, 
            extra_data: nil
            )]
    }
    
    func testEndpoint() {
        let endpoint = RequestBuilder.buildPixelEndpoint(now: nil)
        XCTAssert(endpoint != "",
                  "Should return a pixel endpoint.")
    }
    
    func testDatedEndpoint() {
        var expected: String = "https://srv-2019-01-01-12.pixel.parsely.com/mobileproxy/"
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        var now = formatter.date(from: "2019/01/01 12:31")
        var actual = RequestBuilder.buildPixelEndpoint(now: now)
        XCTAssert(actual == expected,
                  "Should build the correct pixel endpoint.")
        now = formatter.date(from: "2019/01/10 12:31")
        expected = "https://srv-2019-01-10-12.pixel.parsely.com/mobileproxy/"
        actual = RequestBuilder.buildPixelEndpoint(now: now!)
        XCTAssert(actual == expected,
                  "Should always prefer a passed-in date.")
    }
    
//    func testHeaders() {
//        let events: Array<Event> = makeEvents()
//        let actual: Dictionary<String, Any?> = RequestBuilder.buildHeadersDict(events: events)
//        dump(actual)
//        XCTAssertEqual(actual, ["User-Agent": "parsely-analytics-ios/3.0.0"],
//                       "User Agents should be correct.")
//    }

    func testRequests() {
        let events = makeEvents()
        // the builder should make a request
        let request = RequestBuilder.buildRequest(events: events)
        dump(request)
        XCTAssertNotNil(request, "Builder should build a request")
        
    }
}
