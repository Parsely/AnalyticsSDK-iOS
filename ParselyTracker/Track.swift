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
        Parsely.sharedInstance.startFlushTimer();
        // generic helper function, sends the event as-is
        self.pixel.beacon(event: event, shouldNotSetLastRequest: true)
        os_log("Sending an event from Track")
        dump(event)

    }

    func pageview(url: String, urlref: String = "", metadata: Dictionary<String, Any> = [:], extra_data: Dictionary<String, Any> = [:]) {
        let event_ = Event(
            "pageview",
            url: url,
            urlref: urlref,
            metadata: metadata,
            extra_data: extra_data
        )

        os_log("Sending a pageview from Track")
        event(event: event_)
    }

    func videoStart(url: String, urlref: String, vId: String, metadata: Dictionary<String, Any>?) {
        videoManager.trackPlay(url: url, urlref: urlref, vId: vId, metadata: metadata)
        os_log("Tracked videoStart from Track")
    }

    func videoPause(url: String, urlref: String, vId: String, metadata: Dictionary<String, Any>?) {
        videoManager.trackPause(url: url, urlref: urlref, vId: vId, metadata: metadata)
        os_log("Tracked videoPause from Track")
    }

    func startEngagement(url: String, metadata:Dictionary<String, Any>?) {
        self.engagedTime.startInteraction(url: url, metadata: metadata)
        os_log("track start engagement from Track")
    }

    func stopEngagement(url: String) {
        self.engagedTime.endInteraction(url: url)
        os_log("track stop engagement from Track")
    }
}
