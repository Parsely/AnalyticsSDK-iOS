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
        var data: Dictionary<String,Any?> = ["rand": rand]
        data = data.merging(["idsite": Parsely.sharedInstance.apikey, "data": [:]], uniquingKeysWith: { (old, _new) in old })
        data = data.merging(session, uniquingKeysWith: { (old, _new) in old })
        data = data.merging(additionalParams.toDict(), uniquingKeysWith: { (old, _new) in old })
        let visitorInfo = Parsely.sharedInstance.visitorManager?.getVisitorInfo(shouldExtendExisting: true)
        var dataString = ""
        let subData = data["data"] ?? [:] as Dictionary<String, Any?>
        do {
            let subData = try JSONSerialization.data(withJSONObject: subData ?? [:], options: .prettyPrinted)
            dataString = String(data: subData, encoding: .ascii) ?? ""
        } catch {
            dataString = ""
        }
        data["data"] = dataString
        if (shouldNotSetLastRequest) {
            Parsely.sharedInstance.lastRequest = data
        }
        Parsely.sharedInstance.config["uuid"] = visitorInfo?["id"]!
        Parsely.sharedInstance.eventQueue.push(Event(params: data))
    }
}
