//
//  Tracker.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation
import os.log

public class Parsely {
    private var apikey = ""
    private var config: [String: Any] = [:]
    private var default_config = [String: Any]()
    var beacon = Beacon()
    var lastRequest: Dictionary<String, Any?>? = [:]
    private var eventQueue: EventQueue<Event> = EventQueue()
    private var configured = false
    private var session: Session = Session()
    public var secondsBetweenHeartbeats: Int? {
        get {
            return config["secondsBetweenHeartbeats"] as! Int?
        }
    }
    public var videoPlaying = false
    public var isEngaged: Bool = false;
    public static let sharedInstance = Parsely()
    var engagedTimeInstance: EngagedTime?
    var videoInstance: Video?
    
    private init() {
        os_log("Initializing ParselyTracker", log: OSLog.default, type: .info)
    }
    
    public func configure(apikey: String, options: [String: Any]) {
        os_log("Configuring ParselyTracker", log: OSLog.default, type: .info)
        self.apikey = apikey
        self.default_config = [
            "interval": 10,
            "track_ip_addresses": true
        ]
        self.config = self.default_config.merging(
                options, uniquingKeysWith: { (_old, new) in new }
        )
        // TODO: Should get device info and session

        self.configured = true
    }
    
    public func trackPageView(params: [String: Any]) {
        os_log("Tracking PageView", log: OSLog.default, type: .info)
        self.beacon.trackPageView(params: params)
    }

    public func startEngagement() {
        if self.engagedTimeInstance == nil {
            self.engagedTimeInstance = EngagedTime()
        }
        self.engagedTimeInstance!.startInteraction()
    }

    public func stopEngagement() {
        if self.engagedTimeInstance == nil {
            self.engagedTimeInstance = EngagedTime()
        }
        self.engagedTimeInstance!.endInteraction()
    }

    public func trackPlay(videoID: String, metadata:[String: Any], urlOverride: String) {
        if self.videoInstance == nil {
            self.videoInstance = Video()
        }
        self.videoInstance!.trackPlay(vId: videoID, metadata: metadata, urlOverride: urlOverride)
    }

    public func trackPause(videoID: String, metadata:[String: Any], urlOverride: String) {
        if self.videoInstance == nil {
            self.videoInstance = Video()
        }
        self.videoInstance!.trackPause(vId: videoID, metadata: metadata, urlOverride: urlOverride)
    }
}
