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
        sleep(3)
        let anotherSession = sessions.get(url: url2, urlref: url1, shouldExtendExisting: true)
        XCTAssertEqual(session as NSObject, anotherSession as NSObject,
                          "Should use same session for continued browsing")
        dump(session)
        dump(anotherSession)
        XCTAssert(anotherSession["expires"] as! Date > session["expires"] as! Date,
                  "Should extend the expiration each time the session is accessed.")

    }

    func testExpiry() {}

}
