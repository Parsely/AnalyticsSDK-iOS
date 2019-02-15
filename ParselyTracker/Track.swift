//
//  Track.swift
//  ParselyTracker
//
//  Created by Ashley Drake on 2/4/19.
//  Copyright © 2019 Parse.ly. All rights reserved.
//

import Foundation
import os.log

class Track {
    // handles "back of house" work to turn Events into pixels
    // and enqueue them to be sent

    let pixel: Pixel
    lazy var videoManager = VideoManager()
    lazy var engagedTime = EngagedTime()

    init() {
        self.pixel = Pixel()
    }

    func event(event: Event) {
        if event.idsite.isEmpty {
            os_log("idsite not specified. Use ParselyTracker.configure or specify it as an argument to tracking functions.", log: OSLog.tracker, type:.error)
            return
        }
        Parsely.sharedInstance.startFlushTimer();
        // generic helper function, sends the event as-is
        self.pixel.beacon(event: event)
        os_log("Sending an event from Track", log: OSLog.tracker, type:.debug)
    }

    func pageview(url: String, urlref: String = "", metadata: Dictionary<String, Any> = [:], extra_data: Dictionary<String, Any> = [:], idsite: String) {
        let event_ = Event(
            "pageview",
            url: url,
            urlref: urlref,
            metadata: metadata,
            extra_data: extra_data,
            idsite: idsite
        )

        os_log("Sending a pageview from Track", log: OSLog.tracker, type:.debug)
        event(event: event_)
    }

    func videoStart(url: String, urlref: String, vId: String, duration: TimeInterval, metadata: Dictionary<String, Any>?, extra_data: Dictionary<String, Any> = [:], idsite: String) {
        videoManager.trackPlay(url: url, urlref: urlref, vId: vId, duration: duration, metadata: metadata, extra_data: extra_data, idsite: idsite)
        os_log("Tracked videoStart from Track", log: OSLog.tracker, type:.debug)
    }

    func videoPause() {
        videoManager.trackPause()
        os_log("Tracked videoPause from Track", log: OSLog.tracker, type:.debug)
    }
    
    func videoReset(url:String, vId:String) {
        videoManager.reset(url:url, vId:vId)
    }

    func startEngagement(url: String, urlref: String = "", metadata:Dictionary<String, Any>?, extra_data: Dictionary<String, Any> = [:], idsite: String) {
        self.engagedTime.startInteraction(url: url, urlref: urlref, metadata: metadata, extra_data: extra_data, idsite: idsite)
        os_log("track start engagement from Track", log: OSLog.tracker, type:.debug)
    }

    func stopEngagement() {
        self.engagedTime.endInteraction()
        os_log("track stop engagement from Track", log: OSLog.tracker, type:.debug)
    }
    
    internal func pause() {
        os_log("Pausing from track", log:OSLog.tracker, type:.debug)
        engagedTime.pause()
        videoManager.pause()
    }
    
    internal func resume() {
        os_log("Resuming from track", log:OSLog.tracker, type:.debug)
        engagedTime.resume()
        videoManager.resume()
    }
    
    internal func sendHeartbeats() {
        os_log("Sending heartbeats from track", log:OSLog.tracker, type:.debug)
        engagedTime.sendHeartbeats()
        videoManager.sendHeartbeats()
    }
}
