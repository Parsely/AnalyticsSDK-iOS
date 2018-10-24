//
//  Tracker.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation

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
    let engagedTimeInstance = EngagedTime()
    let videoInstance = Video()
    
    private init() {
        
    }
    
    public func configure(apikey: String, options: [String: Any]) {
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
        self.beacon.trackPageView(params: params)
    }

    public func startEngagement() {
        self.engagedTimeInstance.startInteraction()
    }

    public func stopEngagement() {
        self.engagedTimeInstance.endInteraction()
    }

    public func trackPlay(videoID: String, metadata:[String: Any], urlOverride: String) {
        self.videoInstance.trackPlay(vId: videoID, metadata: metadata, urlOverride: urlOverride)
    }

    public func trackPause(videoID: String, metadata:[String: Any], urlOverride: String) {
        self.videoInstance.trackPause(vId: videoID, metadata: metadata, urlOverride: urlOverride)
    }
}
