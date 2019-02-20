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
    
    lazy var sessionManager = SessionManager()

    func beacon(event: Event) {
        if event.idsite == "" {
            os_log("apikey not configured. call Parsely.configure before using tracking methods")
            return
        }
        os_log("Fired beacon: action = %s", log: OSLog.tracker, type: .debug, event.action)
        let session: Dictionary<String, Any?> = sessionManager.get(url: event.url, urlref: event.urlref,
                                                              shouldExtendExisting: true)
        event.setSessionInfo(session: session)
        let visitorInfo = Parsely.sharedInstance.visitorManager.getVisitorInfo(shouldExtendExisting: true)
        event.setVisitorInfo(visitorInfo: visitorInfo)
        
        Parsely.sharedInstance.eventQueue.push(event)
    }
}
