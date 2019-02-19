//
//  VisitorTests.swift
//  ParselyTrackerTests
//
//  Created by Chris Wisecarver on 11/5/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker
import Foundation


class VisitorTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    let visitors: VisitorManager = VisitorManager()

    func testGetVisitorInfo() {
        // should make a new visitor if none exists
        let visitor = visitors.getVisitorInfo()
        XCTAssertFalse(visitor.isEmpty,
                       "Should create a visitor if there is none.")
        let subsequentVisitor = visitors.getVisitorInfo()
        XCTAssertEqual(visitor["id"] as! String, subsequentVisitor["id"] as! String,
                       "Should use same sid for continued browsing")
    }
    func testExtendVisitorExpiry() {
        let visitor = visitors.getVisitorInfo()
        let capturedExpiryOne = visitor["expires"] as! Date
        let subsequentVisitor = visitors.getVisitorInfo(shouldExtendExisting: true)
        let capturedExpiryTwo = subsequentVisitor["expires"] as! Date
        XCTAssert(capturedExpiryOne < capturedExpiryTwo,
                       "Should use same sid for continued browsing")
    }
}
