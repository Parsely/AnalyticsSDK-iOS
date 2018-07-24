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
    private var beacon = Beacon()
    private var eventQueue: EventQueue<Event> = EventQueue()
    private var configured = false
    public static let sharedInstance = Parsely()
    
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
        self.beacon = Beacon()
        self.eventQueue = EventQueue()
        // TODO: Should get device info and

        self.configured = true
    }
    
    public func trackPageView(params: [String: Any]) {
        self.beacon.trackPageView(params: params)
    }

    public func startEngagement() {

    }

    public func stopEngagement() {
    }

    public func trackPlay(videoID: String, metadata:[String: Any], urlOverride: String) {
    }

    public func trackPause(videoID: String, metadata:[String: Any], urlOverride: String) {
    }
}
