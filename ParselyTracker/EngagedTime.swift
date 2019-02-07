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

    override init() {
        super.init()
    }
    
    override func sampleFn(key : String) -> Bool {
        let trackedData: Accumulator = accumulators[key]!
        return trackedData.isEngaged // TODO: consider video playing
    }
    
    override func heartbeatFn(data: Accumulator, enableHeartbeats: Bool) {
        if enableHeartbeats != true {
            return
        }
        let roundedSecs: Int = Int(data.ms)
        let totalMs: Int = Int(data.totalMs * 1000)

        let event = Event(params: [
            "date": Date().timeIntervalSince1970,
            "action": "heartbeat",
            "inc": roundedSecs,
            "tt": totalMs,
            "url": data.key,  // XXX populate this from a data.eventArgs object
            "urlref": ""  // XXX populate this from a data.eventArgs object
        ])
        Parsely.sharedInstance.track.event(event: event, shouldNotSetLastRequest: false)
        os_log("Sent heartbeat for:")
        dump(data)
    }
    
    func startInteraction(url: String) {
        os_log("Starting Interaction", log: OSLog.default, type: .debug)
        trackKey(key: url, contentDuration: nil)
        accumulators[url]!.isEngaged = true
    }
    
    func endInteraction(url: String) {
        os_log("Ending Interaction", log: OSLog.default, type: .debug)
        accumulators[url]!.isEngaged = false
    }
}
