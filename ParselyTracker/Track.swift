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
    var videoManagerInstance: VideoManager?
    var engagedTimeInstance: EngagedTime?

    init() {
        self.pixel = Pixel()
    }

    func event(event: Event, shouldNotSetLastRequest: Bool) {
        // generic helper function, sends the event as-is
        self.pixel.beacon(additionalParams: event, shouldNotSetLastRequest: shouldNotSetLastRequest)
        os_log("Sending an event from Track")

    }

    func pageView(params: [String: Any], shouldNotSetLastRequest: Bool) {
        let data: [String: Any] = [
            "action": "pageview",
            "ts": Date().timeIntervalSince1970,
            ]
        let updatedData = data.merging(
            params, uniquingKeysWith: { (old, _new) in old }
        )

        let event = Event(params: updatedData)
        os_log("Sending a pageview from Track")
        self.pixel.beacon(additionalParams: event, shouldNotSetLastRequest: shouldNotSetLastRequest)
    }

    func videoStart(vId: String, metadata: Dictionary<String, Any?>, urlOverride: String) {
        if self.videoManagerInstance == nil {
            self.videoManagerInstance = VideoManager()
        }
        videoManagerInstance!.trackPlay(vId: vId, metadata: metadata, urlOverride: urlOverride)
        os_log("Tracked videoStart from Track")
    }

    func videoPause(vId: String, metadata: Dictionary<String, Any?>, urlOverride: String) {
        if self.videoManagerInstance == nil {
            self.videoManagerInstance = VideoManager()
        }
        videoManagerInstance!.trackPause(vId: vId, metadata: metadata, urlOverride: urlOverride)
        os_log("Tracked videoPause from Track")
    }

    func startEngagement() {
        if self.engagedTimeInstance == nil {
            self.engagedTimeInstance = EngagedTime()
        }
        self.engagedTimeInstance!.startInteraction()
        os_log("track start engagement from Track")
    }

    func stopEngagement() {
        if self.engagedTimeInstance == nil {
            self.engagedTimeInstance = EngagedTime()
        }
        self.engagedTimeInstance!.endInteraction()
        os_log("track stop engagement from Track")
    }
}
