//
//  StorageTests.swift
//  StorageTests
//
//  Created by Chris Wisecarver on 7/6/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker

class StorageTests: XCTestCase {
    var storage = Storage()


    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testSetGetWithoutExpires() {
        let data: Dictionary<String, Any> = ["foo": "bar"]
        _ = storage.set(key: "baz", value: data, expires: nil)
        _ = storage.get(key: "baz") ?? [:]
        _ = "stuff"
    }

    func testSetGetWithExpires() {
        let data: Dictionary<String, Any?> = ["foo": "bar"]
        let fifteenMinutes = Double(1000 * 15 * 60)
        let expires = Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes))
        _ = storage.set(key: "baz", value: data, expires: expires)
        let retrievedData = storage.get(key: "baz") ?? [:]
        var expected = data
        expected["expires"] = expires
        XCTAssertEqual(expected as NSObject, retrievedData as NSObject)
    }

    func testGetSetWithNegativeExpires() {
        let data: Dictionary<String, Any?> = ["foo": "bar"]
        let fifteenMinutes = Double(1000 * 15 * 60) * -1.0
        let expires = Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes))
        _ = storage.set(key: "baz", value: data, expires: expires)
        let retrievedData = storage.get(key: "baz") ?? [:]
        XCTAssert(retrievedData.isEmpty)
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
        XCTAssertEqual(expected as NSObject, retrievedData as NSObject)
    }

    func testExtendExpiry() {
        // storage should be able to update the expiry on an item.
        let data = ["test": "stuff"]
        let fifteenMinutes = 15 * 60
        let expires = Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes))
        _ = storage.set(key: "shouldextend", value: data, expires: expires)
        let capturedExpiryOne: Date = storage.get(key: "shouldextend")!["expires"] as! Date
        // update expiry to 30 mins from now
        _ = storage.extendExpiry(key: "shouldextend", expires: Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes * 2)))
        let capturedExpiryTwo: Date = storage.get(key: "shouldextend")!["expires"] as! Date
        XCTAssert(capturedExpiryOne < capturedExpiryTwo,
                  "Should update expiry times when requested.")

    }

    func testExpire() {
        // should correctly delete an item when it has expired
        let data = ["test": "stuff"]
        let expires = Date(timeIntervalSinceNow: TimeInterval(1))
        _ = storage.set(key: "shouldextend", value: data, expires: expires)
        sleep(3)
        let actual = storage.get(key: "shouldextend") ?? [:]
        XCTAssert(actual.isEmpty,
                  "Should return nothing if the value has expired.")
    }

}
