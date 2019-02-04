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
    var apikey = ""
    var config: [String: Any] = [:]
    private var default_config = [String: Any]()
    let track = Track()
    var lastRequest: Dictionary<String, Any?>? = [:]
    var eventQueue: EventQueue<Event> = EventQueue()
    private var configured = false
    private var session: Session = Session()
    public var secondsBetweenHeartbeats: TimeInterval? {
        get {
            if let secondsBtwnHeartbeats = config["secondsBetweenHeartbeats"] as! Int? {
                return TimeInterval(secondsBtwnHeartbeats)
            }
            return nil
        }
    }
    public var videoPlaying = false
    public var isEngaged: Bool = false;
    public static let sharedInstance = Parsely()
    var visitorManager: VisitorManager?
    var accumulators: Dictionary<String, Accumulator> = [:]
    
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
        self.visitorManager = VisitorManager()

        self.configured = true
    }
    
    public func trackPageView(params: [String: Any]) {
        os_log("Tracking PageView", log: OSLog.default, type: .info)
        self.track.pageView(params: params, shouldNotSetLastRequest: true)
    }

    public func startEngagement() {
        track.startEngagement()
    }

    public func stopEngagement() {
        track.stopEngagement()
    }

    public func trackPlay(videoID: String, metadata:[String: Any], urlOverride: String) {
        track.videoStart(vId: videoID, metadata: metadata, urlOverride: urlOverride)
    }

    public func trackPause(videoID: String, metadata:[String: Any], urlOverride: String) {
        track.videoPause(vId: videoID, metadata: metadata, urlOverride: urlOverride)
    }
}
