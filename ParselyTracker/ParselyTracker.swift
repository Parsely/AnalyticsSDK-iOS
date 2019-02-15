//
//  Tracker.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation
import os.log

import Reachability

public class Parsely {
    public var apikey = ""
    var config: [String: Any] = [:]
    private var default_config = [String: Any]()
    let track = Track()
    var lastRequest: Dictionary<String, Any?>? = [:]
    var eventQueue: EventQueue<Event> = EventQueue()
    private var configured = false
    private var flushTimer: Timer?
    private var flushInterval: TimeInterval = 30
    private let reachability: Reachability = Reachability()!
    private var backgroundFlushTask: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    private var active: Bool = true
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
        os_log("Initializing ParselyTracker", log: OSLog.tracker, type: .info)
        addApplicationObservers()
    }
    
    public func configure(apikey: String, options: [String: Any]) {
        os_log("Configuring ParselyTracker", log: OSLog.tracker, type: .debug)
        self.apikey = apikey
        self.default_config = [
            "secondsBetweenHeartbeats": 10
        ]
        self.config = self.default_config.merging(
                options, uniquingKeysWith: { (_old, new) in new }
        )
        self.configured = true
    }

    /**
     Track a pageview event
     
     - Parameter url: The url of the page that was viewed
     - Parameter urlref: The url of the page that linked to the viewed page
     - Parameter metadata: A dictionary of metadata for the viewed page
     - Parameter extra_data: A dictionary of additional information to send with the generated pageview event
     - Parameter idsite: The Parsely public API key for which the pageview event should be counted
     */
    public func trackPageView(url: String, urlref: String = "", metadata: Dictionary<String, Any> = [:], extra_data: Dictionary<String, Any> = [:], idsite: String = Parsely.sharedInstance.apikey) {
        os_log("Tracking PageView", log: OSLog.tracker, type: .debug)
        self.track.pageview(url: url, urlref: urlref, metadata: metadata, extra_data: extra_data, idsite: idsite)
    }

    // Engagement functions

    public func startEngagement(url: String, urlref: String = "", metadata:[String: Any]? = nil, extra_data: Dictionary<String, Any> = [:], idsite: String = Parsely.sharedInstance.apikey) {
        track.startEngagement(url: url, urlref: urlref, metadata:metadata, extra_data: extra_data, idsite: idsite)
    }

    public func stopEngagement() {
        track.stopEngagement()
    }

    // Video functions
    public func trackPlay(url: String, urlref: String = "", videoID: String, duration: TimeInterval, metadata:[String: Any]? = nil, extra_data: Dictionary<String, Any> = [:], idsite: String = Parsely.sharedInstance.apikey) {
        track.videoStart(url: url, urlref: urlref, vId: videoID, duration: duration, metadata: metadata, extra_data: extra_data, idsite: idsite)
    }

    public func trackPause() {
        track.videoPause()
    }
    
    public func resetVideo(url:String, vId:String) {
        track.videoReset(url: url, vId: vId)
    }
    
    @objc private func flush() {
        if self.eventQueue.length() == 0 {
            return
        }
        if reachability.connection == .none {
            os_log("Network not reachable. Continuing", log:OSLog.tracker, type:.error)
            return
        }
        os_log("Flushing event queue", log: OSLog.tracker, type:.debug)
        let events = self.eventQueue.get()
        os_log("Got %s events", log: OSLog.tracker, type:.debug, String(describing: events.count))
        let request = RequestBuilder.buildRequest(events: events)
        HttpClient.sendRequest(request: request!)
    }
    
    internal func startFlushTimer() {
        os_log("Flush timer starting", log: OSLog.tracker, type:.debug)
        if self.flushTimer == nil && self.active {
            self.flushTimer = Timer.scheduledTimer(timeInterval: self.flushInterval, target: self, selector: #selector(self.flush), userInfo: nil, repeats: true)
            os_log("Flush timer started", log: OSLog.tracker, type:.debug)
        }
    }
    
    internal func pauseFlushTimer() {
        os_log("Flush timer stopping", log: OSLog.tracker, type:.debug)
        if self.flushTimer != nil && !self.active {
            self.flushTimer!.invalidate()
            self.flushTimer = nil
            os_log("Flush timer stopped", log: OSLog.tracker, type:.debug)
        }
    }
    
    private func addApplicationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(resumeExecution), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeExecution), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(suspendExecution), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(suspendExecution), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(suspendExecution), name: UIApplication.willTerminateNotification, object: nil)
    }

    @objc private func resumeExecution() {
        if active {
            return
        }
        self.active = true
        os_log("Resuming execution after foreground/active", log:OSLog.tracker, type:.info)
        startFlushTimer()
        track.resume()
    }
    
    @objc private func suspendExecution() {
        if !active {
            return
        }
        self.active = false
        os_log("Stopping execution before background/inactive/terminate", log:OSLog.tracker, type:.info)
        pauseFlushTimer()
        track.pause()
        
        DispatchQueue.global(qos: .userInitiated).async{
            let _self = Parsely.sharedInstance
            _self.backgroundFlushTask = UIApplication.shared.beginBackgroundTask(expirationHandler:{
                _self.endBackgroundFlushTask()
            })
            os_log("Flushing queue in background", log:OSLog.tracker, type:.info)
            _self.track.sendHeartbeats()
            _self.flush()
            _self.endBackgroundFlushTask()
        }
    }
    
    private func endBackgroundFlushTask() {
        UIApplication.shared.endBackgroundTask(self.backgroundFlushTask)
        self.backgroundFlushTask = UIBackgroundTaskIdentifier.invalid
    }
}

extension OSLog {
    private static var logger = "ParselyTracker"
    static let tracker = OSLog(subsystem: "ParselyTracker", category: "parsely_tracker")
}
