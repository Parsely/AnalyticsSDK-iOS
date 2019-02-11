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
    // takes a Dictionary<String: Any>.
    var originalData: [String: Any]
    var action: String
    var url: String
    var urlref: String
    var idsite: String
    var data: Dictionary<String, Any>
    
    init(_ action: String, url: String, urlref: String?, data: Dictionary<String, Any>?) {
        // set instance properties
        self.action = action
        self.url = url
        self.urlref = urlref ?? ""
        self.data = data ?? [:]
        self.idsite = Parsely.sharedInstance.apikey
        // preserve original data as dict
        let params: Dictionary<String, Any> = [
            "parsely_site_uuid": "", // todo: Implement
            "url": url,
            "urlref": self.urlref,
            "idsite": self.idsite,
            "action": action,
            "data": self.data
            
        ]
        self.originalData = params
    }
    
    func toDict() -> Dictionary<String,Any> {
        // eventually this should validate the contents
        return self.originalData
    }

    func toJSON() -> String {
        return ""
    }

}

class Heartbeat: Event {
    var tt: Int
    var inc: Int

    init(_ action: String, url: String, urlref: String?, inc: Int, tt: Int, data: Dictionary<String, Any>?) {
        self.tt = tt
        self.inc = inc
        super.init(action, url: url, urlref: urlref, data: data)
        self.originalData["tt"] = self.tt
        self.originalData["inc"] = self.inc
    }
}
