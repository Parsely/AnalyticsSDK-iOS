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
    
    func beacon(event: Event, shouldNotSetLastRequest: Bool) {
        os_log("Fired beacon", log: OSLog.default, type: .debug)
        // start forming dictionary
        let rand = Date().millisecondsSince1970
        var data: Dictionary<String,Any?> = ["ts": rand]
        // add session data
        let session = Session().get(extendSession: true)
        // TODO: validate these are going to the right level of the event.
        data = data.merging(session, uniquingKeysWith: { (old, _new) in old })
        // visitor info
        let visitorInfo = Parsely.sharedInstance.visitorManager.getVisitorInfo(shouldExtendExisting: true)
        data["parsely_uuid"] = visitorInfo["id"]
        // TODO: extra_data goes into the data dictionary key-by-key
        // TODO parsely_site_uuid??
        if (shouldNotSetLastRequest) {
            Parsely.sharedInstance.lastRequest = data
        }
        // merge with the extra_data provided by the customer
        data = data.merging(event.extra_data, uniquingKeysWith: { (old, _new) in old })
        // update event values as needed
        event.data = data as Dictionary<String, Any>
        event.idsite = Parsely.sharedInstance.apikey
        Parsely.sharedInstance.eventQueue.push(event)
    }
}
