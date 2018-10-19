//
//  beacon.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation

class Beacon {
    // handles the timer logic for sending requests and managing the queue
    let pixel: Pixel
    
    init() {
        self.pixel = Pixel()
    }
    func trackPageView(params: [String: Any]) {
        // list of fields added to every event.
        let data: [String: Any] = [
            "action": "pageview",
            "ts": Date().timeIntervalSince1970,
        ]
        let updatedData = data.merging(
                params, uniquingKeysWith: { (old, _new) in old }
        )
        
        let event = Event(params: updatedData)
        self.pixel.beacon(data: event)
    }
}
