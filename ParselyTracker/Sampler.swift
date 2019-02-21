//
//  Sampler.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation
import os.log

let SAMPLE_RATE = TimeInterval(0.1)
let MIN_TIME_BETWEEN_HEARTBEATS: TimeInterval = TimeInterval(1)
let MAX_TIME_BETWEEN_HEARTBEATS: TimeInterval = TimeInterval(15)
let BACKOFF_THRESHOLD = 60

struct Accumulator {
    var key: String
    var accumulatedTime: TimeInterval = TimeInterval(0)
    var totalTime: TimeInterval = TimeInterval(0)
    var lastSampleTime: Date?
    var lastPositiveSampleTime: Date?
    var heartbeatTimeout: TimeInterval?
    var contentDuration: TimeInterval?
    var isEngaged: Bool
    var eventArgs: Dictionary<String, Any>?
}

extension TimeInterval {
    func milliseconds() -> Int {
        return Int(self * 1000)
    }
}

class Sampler {
    var baseHeartbeatInterval = TimeInterval(floatLiteral: 10.5) // default 10.5s
    var heartbeatInterval: TimeInterval
    var hasStartedSampling: Bool = false
    var accumulators: Dictionary<String, Accumulator> = [:]
    var samplerTimer: Timer?
    var heartbeatsTimer: Timer?
    
    init() {
        if let secondsBetweenHeartbeats: TimeInterval = Parsely.sharedInstance.secondsBetweenHeartbeats {
            if secondsBetweenHeartbeats >= MIN_TIME_BETWEEN_HEARTBEATS && secondsBetweenHeartbeats <= MAX_TIME_BETWEEN_HEARTBEATS {
                baseHeartbeatInterval = secondsBetweenHeartbeats
            }
        }
        heartbeatInterval = baseHeartbeatInterval
    }

    // Child classes should override each stub:
    // heartbeatFn is called every time an Accumulator is eligible to send a heartbeat.
    // Typical actions: send an event
    func heartbeatFn(data: Accumulator, enableHeartbeats: Bool) -> Void {}
    // sampleFn is called to determine if an Accumulator is eligible to be sampled.
    // if true, the sample() loop will accumulate time for that item.
    // e.g. "isPlaying" or "isEngaged" -> true/false
    func sampleFn(key: String) -> Bool { return false }

    // Register a piece of content to be tracked.
    public func trackKey(key: String,
                         contentDuration: TimeInterval?,
                         eventArgs: Dictionary<String, Any>?,
                         resetOnExisting: Bool = false) -> Void {
        os_log("Sampler tracked key: %s", log: OSLog.tracker, type: .debug, key)
        let isNew: Bool = accumulators.index(forKey: key) == nil
        let shouldReset: Bool = !isNew && resetOnExisting
        if isNew || shouldReset {
            self.heartbeatInterval = baseHeartbeatInterval
            let newTrackedData = Accumulator.init(
                  key: key,
                  accumulatedTime: TimeInterval(0),
                  totalTime: TimeInterval(0),
                  lastSampleTime: Date(),
                  lastPositiveSampleTime: nil,
                  heartbeatTimeout: heartbeatInterval,
                  contentDuration: contentDuration,
                  isEngaged: false,
                  eventArgs: eventArgs
              )
            accumulators[key] = newTrackedData
        }
        
        if hasStartedSampling == false || shouldReset {
            hasStartedSampling = true
            startTimers()
        }
    }
    
    private func startTimers() {
        if self.samplerTimer != nil {
            self.samplerTimer!.invalidate()
        }
        self.samplerTimer = Timer.scheduledTimer(timeInterval: SAMPLE_RATE, target: self, selector: #selector(self.sample), userInfo: nil, repeats: false)
        if self.heartbeatsTimer != nil {
            self.heartbeatsTimer!.invalidate()
        }
        self.heartbeatsTimer = Timer.scheduledTimer(timeInterval: self.heartbeatInterval, target: self, selector: #selector(self.sendHeartbeats), userInfo: nil, repeats: false)
    }

    // Stop tracking this item altogether.
    public func dropKey(key: String) -> Void {
        os_log("Dropping Sampler key: %s", log: OSLog.tracker, type:.debug, key)
        sendHeartbeat(key: key)
        accumulators.removeValue(forKey: key)
    }

    public func generateEventArgs(url: String, urlref: String, metadata: ParselyMetadata? = nil, extra_data: Dictionary<String, Any>?, idsite: String) -> Dictionary<String, Any> {
        // eventArgs: url, urlref, metadata for heartbeats
        var eventArgs: [String: Any] = ["urlref": urlref, "url": url, "idsite": idsite]
        if (metadata != nil) {
            eventArgs["metadata"] = metadata!
        }
        if (extra_data != nil) {
            eventArgs["extra_data"] = extra_data!
        }
        return eventArgs
    }

    // Sampler loop. Started on first trackKey call. Adds accumulated time to each
    // Accumulator that is eligible.
    @objc private func sample() -> Void {
        let currentTime = Date()
        var shouldCountSample: Bool, increment: TimeInterval
        
        for var (_, trackedData) in accumulators {
            shouldCountSample = sampleFn(key: trackedData.key)
            if shouldCountSample {
                // update relevant accumulator
                increment = currentTime.timeIntervalSince(trackedData.lastSampleTime!)
                trackedData.accumulatedTime += increment
                trackedData.totalTime += increment
                trackedData.lastSampleTime = currentTime
                updateAccumulator(acc: trackedData)
            }
        }
        self.samplerTimer = Timer.scheduledTimer(withTimeInterval: SAMPLE_RATE, repeats: false) { timer in self.sample() }
    }

    private func sendHeartbeat(key: String) -> Void {
        var trackedData = accumulators[key]!
        let incSecs: TimeInterval = trackedData.accumulatedTime
        if incSecs > 0 {
            os_log("Sending heartbeat for %s", log: OSLog.tracker, type:.debug, key)
            heartbeatFn(data: trackedData, enableHeartbeats: true)
        }
        trackedData.accumulatedTime = 0
        trackedData.heartbeatTimeout = TimeInterval(min(900000, trackedData.heartbeatTimeout! * 1.25))
        updateAccumulator(acc: trackedData)
        self.heartbeatInterval = trackedData.heartbeatTimeout!
    }

    @objc internal func sendHeartbeats() -> Void { // this is some bullshit. obj-c can't represent an optional so this needs to change to something else.
        // maybe just wrap it in a dictionary and set it to nil if the key isn't there.
        os_log("called send heartbeats", log: OSLog.tracker, type: .debug)
        for (key, trackedData) in accumulators {
            if Double(trackedData.accumulatedTime) >= trackedData.heartbeatTimeout! - 1.25 {
                sendHeartbeat(key: key)
            }
        }
        self.heartbeatsTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(heartbeatInterval), repeats: false) { timer in
            self.sendHeartbeats()
        }
    }

    // copies of accumulators passed into methods do not update the shared accumulator[id] copy
    private func updateAccumulator(acc: Accumulator) -> Void {
        // gross, dude
        accumulators[acc.key] = acc
    }
    
    internal func pause() {
        os_log("Paused from Sampler", log:OSLog.tracker, type:.debug)
        if samplerTimer != nil {
            self.samplerTimer!.invalidate()
            self.samplerTimer = nil
        }
        if heartbeatsTimer != nil {
            self.heartbeatsTimer!.invalidate()
            self.heartbeatsTimer = nil
        }
    }
    
    internal func resume() {
        os_log("Resumed from Sampler", log:OSLog.tracker, type:.debug)
        // don't restart unless previously paused
        if hasStartedSampling {
            startTimers()
        }
    }
    
}
