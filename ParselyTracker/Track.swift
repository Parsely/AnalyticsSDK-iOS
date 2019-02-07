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

    func event(event: Event, shouldNotSetLastRequest: Bool) {
        // generic helper function, sends the event as-is
        self.pixel.beacon(additionalParams: event, shouldNotSetLastRequest: shouldNotSetLastRequest)
        os_log("Sending an event from Track")
        dump(event)

    }

    func pageview(url: String, params: [String: Any], shouldNotSetLastRequest: Bool) {
        let data: [String: Any] = [
            "action": "pageview",
            "url": url,
            "ts": Date().timeIntervalSince1970,
            ]
        let updatedData = data.merging(
            params, uniquingKeysWith: { (old, _new) in old }
        )

        let event_ = Event(params: updatedData)
        os_log("Sending a pageview from Track")
        event(event: event_, shouldNotSetLastRequest: shouldNotSetLastRequest)
    }

    func videoStart(url: String, vId: String, metadata: Dictionary<String, Any?>) {
        videoManager.trackPlay(url: url, vId: vId, metadata: metadata)
        os_log("Tracked videoStart from Track")
    }

    func videoPause(url: String, vId: String, metadata: Dictionary<String, Any?>) {
        videoManager.trackPause(url: url, vId: vId, metadata: metadata)
        os_log("Tracked videoPause from Track")
    }

    func startEngagement(url: String, eventArgs:Dictionary<String, Any>?) {
        self.engagedTime.startInteraction(url: url, eventArgs: eventArgs)
        os_log("track start engagement from Track")
    }

    func stopEngagement(url: String) {
        self.engagedTime.endInteraction(url: url)
        os_log("track stop engagement from Track")
    }
}
