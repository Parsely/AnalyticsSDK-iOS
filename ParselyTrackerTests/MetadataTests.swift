//
//  MetadataTests.swift
//  ParselyTrackerTests
//
//  Created by Ashley Drake on 2/19/19.
//  Copyright © 2019 Parse.ly. All rights reserved.
//

import Foundation
@testable import ParselyTracker
import XCTest

class MetadataTests: XCTestCase {
    override func setUp() {
    }
    
    override func tearDown() {
    }
    
    func testMetadataValidation() {
        // valid metas
        var metas = ParselyMetadata()
        // should be able to create nothing, if you want
        XCTAssert(metas.toDict().isEmpty,
                  "Empty metadata is just fine")
        metas = ParselyMetadata(canonical_url: "http://test.com")
        let expected = ["link": "http://test.com"]
        let actual = metas.toDict()
        XCTAssertEqual(expected as NSObject, actual as NSObject,
                       "Should handle scant arguments with no issues")
        metas = ParselyMetadata(
            canonical_url: "http://parsely-test.com", pub_date: Date.init(), title: "a title.", authors: ["Yogi Berra"], image_url: "http://parsely-test.com/image2", section: "Things my mother says", tags: ["tag1", "tag2"], duration: TimeInterval(100)
        )
        XCTAssertFalse(metas.toDict().isEmpty,
            "Should handle all arguments.")
    }
}
