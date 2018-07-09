//
//  event_queue.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation

struct EventQueue<T> {
    var list = [T]()
    
    mutating func push(_ element:T) {
        list.append(element)
    }
    
    mutating func pop() -> T? {
        if list.isEmpty {
            return nil
        }
        return list.removeFirst()
    }
    
    mutating func get(count:Int = 0) -> [T] {
        if list.isEmpty {
            return list
        }
        if count == 0 {
            return list
        } else {
            return Array(list.prefix(count))
        }
    }
}
