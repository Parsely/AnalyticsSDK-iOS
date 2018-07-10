//
//  pixel.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation

class Pixel {
    let jsonEncoder = JSONEncoder()
    // knows how to make an event into a https pixel request
    func beacon(data: [String: Any]) {
        do {
            let jsonData = try self.jsonEncoder.encode(data)
            print(jsonData)
        } catch {
            print("darn")
        }
    }
}
