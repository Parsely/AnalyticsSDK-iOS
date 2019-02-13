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
    var idsite: String
    var extra_data: Dictionary<String, Any>
    var session_id: Int?
    var session_timestamp: Int?
    var session_url: String?
    var session_referrer: String?
    var last_session_timestamp: Int?
    
    init(_ action: String,
         url: String,
         urlref: String?,
         metadata: Dictionary<String, Any>?,
         extra_data: Dictionary<String, Any> = [:],
         idsite: String = Parsely.sharedInstance.apikey,
         session_id: Int? = nil,
         session_timestamp: Int? = nil,
         session_url: String? = nil,
         session_referrer: String? = nil,
         last_session_timestamp: Int? = nil
    ) {
        // set instance properties
        self.action = action
        self.url = url
        self.urlref = urlref ?? ""
        self.idsite = idsite
        self.data = [:]
        self.metadata = metadata
        self.extra_data = extra_data
        self.session_id = session_id
        self.session_timestamp = session_timestamp
        self.session_url = session_url
        self.session_referrer = session_referrer
        self.last_session_timestamp = last_session_timestamp

        // preserve original data as dict
        var params: Dictionary<String, Any> = [
            "url": url,
            "urlref": self.urlref,
            "action": self.action,
            "idsite": self.idsite,
            "data": self.data
        ]
        // add metadata at top level if present
        if let metas = self.metadata {
            params["metadata"] = metas
        }
        if self.session_id != nil {
            params["sid"] = self.session_id
            params["sts"] = self.session_timestamp
            params["surl"] = self.session_url
            params["sref"] = self.session_referrer
            params["slts"] = self.last_session_timestamp
        }
        self.originalData = params
    }
    
    func setSessionInfo(session: Dictionary<String, Any?>) {
        dump(session)
        self.session_id = session["session_id"] as? Int ?? 0
        self.session_timestamp = session["session_ts"] as? Int ?? 0
        self.session_url = session["session_url"] as? String ?? ""
        self.session_referrer = session["session_referrer"] as? String ?? ""
        self.last_session_timestamp = session["last_session_ts"] as? Int ?? 0
        
        self.originalData["sid"] = self.session_id
        self.originalData["sts"] = self.session_timestamp
        self.originalData["surl"] = self.session_url
        self.originalData["sref"] = self.session_referrer
        self.originalData["slts"] = self.last_session_timestamp
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

    init(_ action: String, url: String, urlref: String?, inc: Int, tt: Int, metadata: Dictionary<String, Any>?, extra_data: Dictionary<String, Any> = [:], idsite: String = Parsely.sharedInstance.apikey) {
        self.tt = tt
        self.inc = inc
        super.init(action, url: url, urlref: urlref, metadata: metadata, extra_data: extra_data, idsite: idsite)
        self.originalData["tt"] = self.tt
        self.originalData["inc"] = self.inc
    }
}
