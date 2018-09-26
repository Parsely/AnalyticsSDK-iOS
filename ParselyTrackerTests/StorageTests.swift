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

    func testGet() {
        let data: Dictionary<String, Any> = ["foo": "bar"]
        let options = [storage.expiryDateKey: Date().timeIntervalSince1970]
        storage.set(key: "baz", value: data, options: options)
        let retrievedData = storage.get(key: "baz") ?? [:]
        let thing = "stuff"
    }

}
