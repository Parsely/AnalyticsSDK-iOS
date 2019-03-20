//
//  ParselyTestCase.swift
//  ParselyTrackerTests
//
//  Created by Emmett Butler on 3/20/19.
//  Copyright © 2019 Parse.ly. All rights reserved.
//
import XCTest
@testable import ParselyTracker

class ParselyTestCase: XCTestCase {
    internal var parselyTestTracker: Parsely!

    override func setUp() {
        super.setUp()
        parselyTestTracker = Parsely.getInstance()
    }
    
    override func tearDown() {
        super.tearDown()
    }
}
