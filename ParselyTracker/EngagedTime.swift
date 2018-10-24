//
//  engaged_time.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation

class EngagedTime: Sampler, Accumulates {
    let ENGAGED_TIME_SAMPLER_KEY = "engagedTime"
    var isInteracting = false

    override init() {
        super.init()
    }
    
    override func sampleFn(params: Dictionary<String, Any?>) -> Bool {
        Parsely.sharedInstance.isEngaged = isInteracting || Parsely.sharedInstance.videoPlaying
        return Parsely.sharedInstance.isEngaged
    }
    
    override func heartbeatFn(params: Dictionary<String, Any?>) {
        let roundedSecs: Int = params["roundedSecs"] as! Int
        let enableHeartbeats: Bool = params["enableHeartbeats"] as! Bool
        let totalMs: Int = params["totalMs"] as! Int

        if enableHeartbeats != true {
            return
        }
        let pixel = Pixel()
        
        let event = Event(params: [
            "date": Date().timeIntervalSince1970,
            "action": "heartbeat",
            "inc": roundedSecs,
            "tt": totalMs,
            "url": Parsely.sharedInstance.lastRequest?["url"]!! ?? "",
            "urlref": Parsely.sharedInstance.lastRequest?["urlref"]!! ?? ""
        ])
        pixel.beacon(data: event)
    }
    
    func startInteraction() {
        isInteracting = true
    }
    
    func endInteraction() {
        isInteracting = false
    }
}
