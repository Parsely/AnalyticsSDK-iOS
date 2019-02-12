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
    var data: Dictionary<String, Any> = [:] {
        willSet(updatedData) {
            self.originalData["data"] = updatedData
        }
    }
    var metadata: Dictionary<String, Any>?
    var idsite: String = "" {
        willSet(newIdsite) {
            self.originalData["idsite"] = newIdsite
        }
    }
    var extra_data: Dictionary<String, Any>
    
    init(_ action: String, url: String, urlref: String?, metadata: Dictionary<String, Any>?, extra_data: Dictionary<String, Any> = [:]) {
        // set instance properties
        self.action = action
        self.url = url
        self.urlref = urlref ?? ""
        self.data = [:]
        self.metadata = metadata
        self.extra_data = extra_data

        // preserve original data as dict
        var params: Dictionary<String, Any> = [
            "url": url,
            "urlref": self.urlref,
            "action": action,
            "data": self.data
        ]
        // add metadata at top level if present
        if let metas = self.metadata {
            params["metadata"] = metas
        }
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

    init(_ action: String, url: String, urlref: String?, inc: Int, tt: Int, metadata: Dictionary<String, Any>?, extra_data: Dictionary<String, Any> = [:]) {
        self.tt = tt
        self.inc = inc
        super.init(action, url: url, urlref: urlref, metadata: metadata, extra_data: extra_data)
        self.originalData["tt"] = self.tt
        self.originalData["inc"] = self.inc
    }
}
