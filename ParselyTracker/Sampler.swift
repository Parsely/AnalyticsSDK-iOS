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
    public func trackKey(key: String,  contentDuration: TimeInterval?, eventArgs: Dictionary<String, Any>?) -> Void {
        os_log("Sampler tracked key: %s", log: OSLog.tracker, type: .debug, key)
        if accumulators.index(forKey: key) == nil {
            let newTrackedData = Accumulator.init(
                  key: key,
                  accumulatedTime: TimeInterval(0),
                  totalTime: TimeInterval(0),
                  lastSampleTime: Date(),
                  lastPositiveSampleTime: nil,
                  heartbeatTimeout: timeoutFromDuration(contentDuration: contentDuration),
                  contentDuration: contentDuration,
                  isEngaged: false,
                  eventArgs: eventArgs
              )
            accumulators[key] = newTrackedData
          }

        if hasStartedSampling == false {
            hasStartedSampling = true
            startTimers()
        }
    }
    
    private func startTimers() {
        guard samplerTimer == nil else { return }
        guard heartbeatsTimer == nil else { return }
        self.samplerTimer = Timer.scheduledTimer(timeInterval: SAMPLE_RATE, target: self, selector: #selector(self.sample), userInfo: nil, repeats: false)
        self.heartbeatsTimer = Timer.scheduledTimer(timeInterval: self.heartbeatInterval, target: self, selector: #selector(self.sendHeartbeats), userInfo: nil, repeats: false)
    }

    // Stop tracking this item altogether.
    public func dropKey(key: String) -> Void {
        os_log("Dropping Sampler key: %s", log: OSLog.tracker, type:.debug, key)
        sendHeartbeat(key: key)
        accumulators.removeValue(forKey: key)
    }

    public func generateEventArgs(url: String, urlref: String, metadata: Dictionary<String, Any>?, extra_data: Dictionary<String, Any> = [:], idsite: String) -> Dictionary<String, Any> {
        // eventArgs: url, urlref, metadata for heartbeats
        let metadata_ = metadata ?? [:]
        let eventArgs = ["urlref": urlref, "url": url, "metadata": metadata_, "extra_data": extra_data, "idsite": idsite] as [String : Any]
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
        Timer.scheduledTimer(withTimeInterval: SAMPLE_RATE, repeats: false) { timer in self.sample() }
    }

    private func sendHeartbeat(key: String) -> Void {
        var trackedData = accumulators[key]
        let incSecs: TimeInterval = trackedData!.accumulatedTime
        if incSecs > 0 && incSecs <= (baseHeartbeatInterval + 0.25) {
            os_log("Sending heartbeat for %s", log: OSLog.tracker, type:.debug, key)
            heartbeatFn(data: trackedData!, enableHeartbeats: true)
        }
        trackedData!.accumulatedTime = 0
        updateAccumulator(acc: trackedData!)
    }

    @objc internal func sendHeartbeats() -> Void { // this is some bullshit. obj-c can't represent an optional so this needs to change to something else.
        // maybe just wrap it in a dictionary and set it to nil if the key isn't there.
        os_log("called send heartbeats", log: OSLog.tracker, type: .debug)
        for (key, trackedData) in accumulators {
            let sendThreshold = trackedData.heartbeatTimeout! - heartbeatInterval

            if Double(trackedData.accumulatedTime) >= sendThreshold {
                sendHeartbeat(key: key)
            }
        }
        self.heartbeatsTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(heartbeatInterval), repeats: false) { timer in
            self.sendHeartbeats()
        }
    }
    
    // Calculate an accumulator's timeout based on the content length, to ensure we capture
    // all completion intervals.
    private func timeoutFromDuration(contentDuration: TimeInterval?) -> TimeInterval {
        if contentDuration != nil && contentDuration! > 0 {
            let completionInterval = contentDuration! / Double(5)
            if completionInterval < baseHeartbeatInterval / Double(2) {
                return max(contentDuration! / 5, MIN_TIME_BETWEEN_HEARTBEATS)
            }
            if completionInterval < baseHeartbeatInterval {
                return max(baseHeartbeatInterval / Double(2), MIN_TIME_BETWEEN_HEARTBEATS)
            }
            if completionInterval > baseHeartbeatInterval * Double(2) {
                // double the heartbeat interval for long durations to avoid flooding with heartbeats
                // don't check MAX_TIME_BETWEEN_HEARTBEATS here since we know what we're doing
                return baseHeartbeatInterval * Double(2)
            }
        }
        return baseHeartbeatInterval
    }

    // copies of accumulators passed into methods do not update the shared accumulator[id] copy
    private func updateAccumulator(acc: Accumulator) -> Void {
        // gross, dude
        accumulators[acc.key] = acc
    }
    
    internal func pause() {
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
        // don't restart unless previously paused
        if hasStartedSampling {
            startTimers()
        }
    }
    
}
