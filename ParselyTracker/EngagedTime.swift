//
//  engaged_time.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation
import os.log

class EngagedTime: Sampler {
    let ENGAGED_TIME_SAMPLER_KEY = "engagedTime"
    var isEngaged: Bool = false

    override init() {
        super.init()
    }
    
    override func sampleFn(key : String) -> Bool {
        return isEngaged
    }
    
    override func heartbeatFn(data: Accumulator, enableHeartbeats: Bool) {
        if enableHeartbeats != true {
            return
        }
        let roundedSecs: Int = Int(data.totalMs / 1000)  // logic check!
        let totalMs: Int = Int(data.totalMs)

        let event = Event(params: [
            "date": Date().timeIntervalSince1970,
            "action": "heartbeat",
            "inc": roundedSecs,
            "tt": totalMs,
            "url": Parsely.sharedInstance.lastRequest?["url"]!! ?? "",
            "urlref": Parsely.sharedInstance.lastRequest?["urlref"]!! ?? ""
        ])
        Parsely.sharedInstance.track.event(event: event, shouldNotSetLastRequest: false)
        os_log("Sent heartbeat for:")
        dump(data)
    }
    
    func startInteraction(url: String) {
        os_log("Starting Interaction", log: OSLog.default, type: .debug)
        trackKey(key: url, contentDuration: nil)
        isEngaged = true
    }
    
    func endInteraction(url: String) {
        os_log("Ending Interaction", log: OSLog.default, type: .debug)
        isEngaged = false
    }
}
