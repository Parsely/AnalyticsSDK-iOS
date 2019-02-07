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
    public static let sharedInstance = Parsely()
    var visitorManager: VisitorManager?
    
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
    
    public func trackPageView(url: String, params: [String: Any]) {
        os_log("Tracking PageView", log: OSLog.default, type: .info)
        self.track.pageview(url: url, params: params, shouldNotSetLastRequest: true)
    }

    public func startEngagement(url: String, qsargs:[String: Any]? = nil) {
        track.startEngagement(url: url, eventArgs:qsargs)
    }

    public func stopEngagement(url: String) {
        track.stopEngagement(url: url)
    }

    public func trackPlay(url: String, videoID: String, metadata:[String: Any]) {
        track.videoStart(url: url, vId: videoID, metadata: metadata)
    }

    public func trackPause(url: String, videoID: String, metadata:[String: Any]) {
        track.videoPause(url: url, vId: videoID, metadata: metadata)
    }
}
