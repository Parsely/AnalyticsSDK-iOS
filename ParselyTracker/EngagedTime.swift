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
        let roundedSecs: Int = Int(data.heartbeatCandidateSampledTime)
        let totalMs: Int = Int(data.totalSampledTime * 1000)

        let event = Event(params: [
            "action": "heartbeat",
            "inc": roundedSecs,
            "tt": totalMs,
            "url": data.eventArgs!["url"]
        ])
        for (k, v) in data.eventArgs! {  // XXX replace with merging()
            if !event.originalData.keys.contains(k) {
                event.originalData[k] = v;
            }
        }
        Parsely.sharedInstance.track.event(event: event, shouldNotSetLastRequest: false)
        os_log("Sent heartbeat for:")
        dump(data)
    }
    
    func startInteraction(url: String, eventArgs: Dictionary<String, Any>?) {
        os_log("Starting Interaction", log: OSLog.default, type: .debug)
        var _eventArgs: [String: Any] = ["url": url]
        if eventArgs != nil {
            for (k, v) in eventArgs! {
                _eventArgs[k] = v
            }
        }
        trackKey(key: url, contentDuration: nil, eventArgs: _eventArgs);
        accumulators[url]!.isEngaged = true
    }
    
    func endInteraction(url: String) {
        os_log("Ending Interaction", log: OSLog.default, type: .debug)
        accumulators[url]!.isEngaged = false
    }
}
