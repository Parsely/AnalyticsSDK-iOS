//
//  event.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation

class Event {
    // underlying object behind pageview, heartbeat, videostart, vheartbeat, custom events
    // takes a Dictionary<String: Any?>.
    var originalData: [String: Any?]
    
    
    init(params: [String: Any?]) {
        self.originalData = params
    }
    
    func toDict() -> Dictionary<String,Any?> {
        // eventually this should validate the contents
        return self.originalData
    }
}
