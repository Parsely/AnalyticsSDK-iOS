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

        let event = Heartbeat(
            "heartbeat",
            url: data.eventArgs!["url"] as! String,
            urlref: nil,
            inc: roundedSecs,
            tt: totalMs,
            metadata: nil
        )
        for (k, v) in data.eventArgs! {  // XXX replace with merging()
            if !event.originalData.keys.contains(k) {
                event.originalData[k] = v;
            }
        }
        Parsely.sharedInstance.track.event(event: event)
        os_log("Sent heartbeat for:")
        dump(data)
    }
    
    func startInteraction(url: String, urlref: String = "", metadata: Dictionary<String, Any>?, extra_data: Dictionary<String, Any> = [:]) {
        os_log("Starting Interaction", log: OSLog.default, type: .debug)
        let eventArgs = generateEventArgs(url: url, urlref: urlref, metadata: metadata)
        trackKey(key: url, contentDuration: nil, eventArgs: eventArgs);
        accumulators[url]!.isEngaged = true
    }
    
    func endInteraction(url: String) {
        os_log("Ending Interaction", log: OSLog.default, type: .debug)
        accumulators[url]!.isEngaged = false
    }
}
