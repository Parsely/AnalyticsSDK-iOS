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
    private var flushTimer: Timer?
    private var flushInterval: TimeInterval = 30
    public var secondsBetweenHeartbeats: TimeInterval? {
        get {
            if let secondsBtwnHeartbeats = config["secondsBetweenHeartbeats"] as! Int? {
                return TimeInterval(secondsBtwnHeartbeats)
            }
            return nil
        }
    }
    public static let sharedInstance = Parsely()
    lazy var visitorManager = VisitorManager()
    
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
        self.configured = true
    }

    // Pageview functions

    public func trackPageView(url: String, urlref: String = "", metadata: Dictionary<String, Any> = [:]) {
        os_log("Tracking PageView", log: OSLog.default, type: .info)
        self.track.pageview(url: url, urlref: urlref, metadata: metadata)
    }

    // Engagement functions

    public func startEngagement(url: String, metadata:[String: Any]? = nil) {
        track.startEngagement(url: url, metadata:metadata)
    }

    public func stopEngagement(url: String) {
        track.stopEngagement(url: url)
    }

    // Video functions

    public func trackPlay(url: String, urlref: String, videoID: String, metadata:[String: Any]? = nil) {
        track.videoStart(url: url, urlref: urlref, vId: videoID, metadata: metadata)
    }

    public func trackPause(url: String, urlref: String, videoID: String, metadata:[String: Any]? = nil) {
        track.videoPause(url: url, urlref: urlref, vId: videoID, metadata: metadata)
    }
    
    @objc private func flush() {
        if self.eventQueue.length() == 0 {
            return
        }
        if !self.isReachable() {
            return
        }
        os_log("Flushing event queue")
        let events = self.eventQueue.get()
        os_log("Got %s events", String(describing: events.count))
        let request = RequestBuilder.buildRequest(events: events)
        HttpClient.sendRequest(request: request!)
    }
    
    internal func startFlushTimer() {
        if self.flushTimer == nil {
            self.flushTimer = Timer.scheduledTimer(timeInterval: self.flushInterval, target: self, selector: #selector(self.flush), userInfo: nil, repeats: true)
        }
    }
    
    private func isReachable() -> Bool {
        return true  // TODO
    }
}
