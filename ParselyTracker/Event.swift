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
    
    
    init(action: String, url: String, ts: TimeInterval, urlref: String?, extra_data: Dictionary<String, Any?>?) {
        let params: Dictionary<String, Any?> = [
            "ts": ts,
            "parsely_site_uuid": "", // todo: Implement
            "url": url,
            "urlref": urlref!,
            "idsite": Parsely.sharedInstance.apikey,
            "action": action,
            "data": extra_data!
            
        ]
        self.originalData = params
    }
    
    func toDict() -> Dictionary<String,Any?> {
        // eventually this should validate the contents
        return self.originalData
    }

    func toJSON() -> String {
        return ""
    }

}
