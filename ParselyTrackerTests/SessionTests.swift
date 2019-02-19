//
//  SessionTests.swift
//  ParselyTrackerTests
//
//  Created by Chris Wisecarver on 11/5/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker
import Foundation

class SessionTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    let sessions = SessionManager()
    let emptyDict: [String: Any?] = [:]

    func testGet() {
        // should be able to create a session if there is none
        let url1 = "http://parsely-test.com/123"
        let url2 = "http://parsely-test.com/"
        let session = sessions.get(url: url1, urlref: "") // will not extend by default
        XCTAssertFalse(session.isEmpty,
                  "Should create a session if there is none.")
        let subsequentSession = sessions.get(url: url2, urlref: url1, shouldExtendExisting: true)
        XCTAssertEqual(session["session_id"] as! Int, subsequentSession["session_id"] as! Int,
                          "Should use same sid for continued browsing")
    }

    func testExpiry() {
        // should be able to extend expiry on a session for each use
        let url1 = "http://parsely-test.com/123"
        let session = sessions.get(url: url1, urlref: "") // will not extend by default
        let subsequentSession = sessions.get(url: url1, urlref: "", shouldExtendExisting: true)
        XCTAssertEqual(session["session_id"] as! Int, subsequentSession["session_id"] as! Int,
                       "Should use same sid for continued browsing")
        XCTAssert(subsequentSession["expires"] as! Date > session["expires"] as! Date,
                  "Should extend the expiration each time the session is accessed.")

    }
}
