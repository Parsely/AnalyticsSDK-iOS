//
//  event_queue.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation

extension Array {
    mutating func take(_ elementsCount: Int) -> [Element] {
        // add function to arrays that safely removes objects from
        // the beginning of the array and returns them
        if elementsCount <= 0 {
            return []
        }
        let min = Swift.min(elementsCount, count)
        let segment = Array(self[0..<min])
        self.removeFirst(min)
        return segment
    }
}

struct EventQueue<T> {
    // wrapper around an array that adds extra functionality
    var list = [T]()
    
    mutating func push(_ element:T) {
        // add an object to the end of the queue
        list.append(element)
    }
    
    mutating func pop() -> T? {
        // safely remove the last object from the queue
        if list.isEmpty {
            return nil
        }
        return list.removeFirst()
    }
    
    mutating func get(count:Int = 0) -> [T] {
        // remove and return <count> objects from the queue
        // if <count> is 0 or missing get remove and return all
        if count == 0 {
            return list.take(list.count)
        }
        return list.take(count)
    }
}
