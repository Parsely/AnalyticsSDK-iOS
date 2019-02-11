//
//  pixel.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation
import SwiftHTTP
import os.log

class Pixel {
    
    func beacon(additionalParams: Event, shouldNotSetLastRequest: Bool) {
        os_log("Fired beacon", log: OSLog.default, type: .debug)
        let session = Session().get(extendSession: true)
        let rand = Date().millisecondsSince1970
        // start building the data dictionary
        var data: Dictionary<String,Any?> = ["rand": rand]
        // todo: allow idsite to be set here
        // merge dict with apikey, "extradata"
        data = data.merging(["idsite": Parsely.sharedInstance.apikey, "data": [:]], uniquingKeysWith: { (old, _new) in old })
        // add in session
        data = data.merging(session, uniquingKeysWith: { (old, _new) in old })
        // add in the event toDict itself
        data = data.merging(additionalParams.toDict(), uniquingKeysWith: { (old, _new) in old })
        // visitor info
        let visitorInfo = Parsely.sharedInstance.visitorManager?.getVisitorInfo(shouldExtendExisting: true)
        Parsely.sharedInstance.config["uuid"] = visitorInfo?["id"]!
        // json serialize the nested data
        var dataString = ""
        let subData = data["data"] ?? [:] as Dictionary<String, Any?>
        do {
            let subData = try JSONSerialization.data(withJSONObject: subData ?? [:], options: .prettyPrinted)
            dataString = String(data: subData, encoding: .ascii) ?? ""
        } catch {
            dataString = ""
        }
        data["data"] = dataString
        // TODO is this needed?
        if (shouldNotSetLastRequest) {
            Parsely.sharedInstance.lastRequest = data
        }
        // TODO: update to enqueue a modified event
        let event = Event(
            data["action"] as! String,
            url: additionalParams.url,
            urlref: additionalParams.urlref,
            data: data as Dictionary<String, Any>)
        Parsely.sharedInstance.eventQueue.push(event)
    }
}
