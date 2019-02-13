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
    
    func beacon(event: Event) {
        os_log("Fired beacon", log: OSLog.default, type: .debug)
        // start forming dictionary
        let rand = Date().millisecondsSince1970
        var data: Dictionary<String,Any?> = ["ts": rand]
        let session: Dictionary<String, Any?> = Session().get(url: event.url, urlref: event.urlref)
        event.setSessionInfo(session: session)
        let visitorInfo = Parsely.sharedInstance.visitorManager.getVisitorInfo(shouldExtendExisting: true)
        data["parsely_site_uuid"] = visitorInfo["id"]
        
        // merge with the extra_data provided by the customer
        data = data.merging(event.extra_data, uniquingKeysWith: { (old, _new) in old })
        // update event values as needed
        event.data = data as Dictionary<String, Any>
        Parsely.sharedInstance.eventQueue.push(event)
    }
}
