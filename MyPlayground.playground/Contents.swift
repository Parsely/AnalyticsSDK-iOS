//: Playground - noun: a place where people can play

import UIKit

//  event.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation

class Event {
    // underlying object behind pageview, heartbeat, videostart, vheartbeat, custom events
    // takes a Dictionary<String: Any> and goes through it forcing it to be JSON Encodable.
    let originalData: [String: Any]
    let newData: [String: String]
    let jsonEncoder = JSONEncoder()
    
    init(params: [String: Any]) {
        self.originalData = params
        self.newData = self.makeEncodableObject(params: params)
    }
    
    func makeEncodableObject(params: [String: Any]) -> Dictionary<String,String> {
        var newData: [String: String] = Dictionary()
        for (key, value) in params {
            switch value {
            case let someDict as Dictionary<String,Any>:
                newData[key] = try? String(describing: self.jsonEncoder.encode(someDict))
            case let someArray as Array<Any>:
                newData[key] = try? String(describing: self.jsonEncoder.encode(someArray))
            case let someDate as Date:
                newData[key] = String(someDate.timeIntervalSince1970)
            default:
                newData[key] = String(describing: value)
            }
        }
        return newData
    }
    
    func toJSON() -> String {
        return try! String(describing: self.jsonEncoder.encode(self.newData))
    }
}


var mah_dictionary: [String: Any]

mah_dictionary["action"] = "pageview"

mah_dictionary["ts"] = 12345.34

event = Event(mah_dictionary)
event.toJSON()

