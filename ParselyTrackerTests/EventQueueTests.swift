//
//  EventQueueTests.swift
//  ParselyTrackerTests
//
//  Created by Chris Wisecarver on 7/9/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//
//
//  ParselyTrackerTests.swift
//  ParselyTrackerTests
//
//  Created by Chris Wisecarver on 7/6/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import XCTest
@testable import ParselyTracker

class EventQueueTests: XCTestCase {
    var queue = ParselyTracker.EventQueue<Int>()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        for i:Int in 0...30 {
            self.queue.push(i)
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPush() {
        self.queue.push(31)
        assert(self.queue.list.count == 32)
    }
    
    func testPop() {
        assert(self.queue.pop() == 0)
    }
    
    func testGet() {
        assert(self.queue.get(count:5) == [0,1,2,3,4])
        assert(self.queue.get(count:5) == [5,6,7,8,9])
        assert(self.queue.get(count:21) == [10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30])
        assert(self.queue.get(count:5) == [])
    }
    
    func testGetAll() {
        assert(self.queue.get() == [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30])
    }
    
    func testGetTooMany() {
        assert(self.queue.get(count:99999999999) == [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30])
    }
    
    func testNegativeCount() {
        let wot = self.queue.get(count:-42)
        assert(wot == [])
    }
    
}

