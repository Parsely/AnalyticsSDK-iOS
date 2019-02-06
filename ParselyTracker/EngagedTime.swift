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
    var isInteracting = false

    override init() {
        super.init()
        self.trackKey(key: self.ENGAGED_TIME_SAMPLER_KEY, contentDuration: nil)
    }
    
    override func sampleFn(params: Dictionary<String, Any?>) -> Bool {
        Parsely.sharedInstance.isEngaged = isInteracting || Parsely.sharedInstance.videoPlaying
        os_log("Sampling engaged time", log: OSLog.default, type: .info)
        return Parsely.sharedInstance.isEngaged
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
    
    func startInteraction() {
        os_log("Starting Interaction", log: OSLog.default, type: .debug)
        isInteracting = true
    }
    
    func endInteraction() {
        os_log("Ending Interaction", log: OSLog.default, type: .debug)
        isInteracting = false
    }
}
