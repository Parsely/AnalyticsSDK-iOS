//
//  StorageTests.swift
//  StorageTests
//
//  Created by Chris Wisecarver on 7/6/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker

class StorageTests: ParselyTestCase {
    var storage = Storage()

    func testSetGetWithoutExpires() {
        let expected = ["foo": "bar"]
        _ = storage.set(key: "baz", value: expected, expires: nil)
        let actual = storage.get(key: "baz")!
        XCTAssertEqual(expected, actual as! [String: String],
                       "Sequential calls to Storage.set and Storage.get should preserve the stored object")
    }

    func testSetGetWithExpires() {
        let data: Dictionary<String, Any?> = ["foo": "bar"]
        let fifteenMinutes = Double(1000 * 15 * 60)
        let expires = Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes))
        _ = storage.set(key: "baz", value: data, expires: expires)
        let retrievedData = storage.get(key: "baz")
        var expected = data
        expected["expires"] = expires
        XCTAssertEqual(expected as NSObject, retrievedData! as NSObject,
                       "Sequential calls to Storage.set and Storage.get should preserve the stored object and its " +
                       "expiry information")
    }

    func testGetSetWithNegativeExpires() {
        let data: Dictionary<String, Any?> = ["foo": "bar"]
        let fifteenMinutes = Double(1000 * 15 * 60) * -1.0
        let expires = Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes))
        _ = storage.set(key: "baz", value: data, expires: expires)
        let retrievedData = storage.get(key: "baz") ?? [:]
        XCTAssert(retrievedData.isEmpty,
                  "After a call to Storage.set with a negative expires argument, calls to Storage.get for the set key " +
                  "should return nil")
    }

    func testDataTypes() {
        let data: Dictionary<String, Any> = [
            "foo": "bar",
            "baz": 10,
            "bzz": 10.5,
            "lol": ["huh": "yah", "right": 10, "yup": 10.5],
            "millis": Date().millisecondsSince1970
        ]
        let fifteenMinutes = Double(1000 * 15 * 60)
        let expires = Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes))
        _ = storage.set(key: "bzz", value: data, expires: expires)
        let retrievedData = storage.get(key: "bzz") ?? [:]
        var expected = data
        expected["expires"] = expires
        XCTAssertEqual(expected as NSObject, retrievedData as NSObject,
                       "Sequential calls to Storage.set and Storage.get storing and retrieving varied datatypes should " +
                       "preserve the stored object and its expiry information")
    }

    func testExtendExpiry() {
        let data = ["test": "stuff"]
        let fifteenMinutes = 15 * 60
        let expires = Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes))
        _ = storage.set(key: "shouldextend", value: data, expires: expires)
        let capturedExpiryOne: Date = storage.get(key: "shouldextend")!["expires"] as! Date
        _ = storage.extendExpiry(key: "shouldextend", expires: Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes * 2)))
        let capturedExpiryTwo: Date = storage.get(key: "shouldextend")!["expires"] as! Date
        XCTAssert(capturedExpiryOne < capturedExpiryTwo,
                  "Storage.extendExpiry should correctly set the expiry of a stored object")

    }

    func testExpire() {
        let data = ["test": "stuff"]
        let expires = Date(timeIntervalSinceNow: TimeInterval(1))
        _ = storage.set(key: "shouldextend", value: data, expires: expires)
        sleep(2)
        let actual = storage.get(key: "shouldextend") ?? [:]
        XCTAssert(actual.isEmpty, "Calls to Storage.get requesting expired keys should return empty objects")
    }
}
