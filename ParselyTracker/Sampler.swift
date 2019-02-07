//
//  Sampler.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation
import os.log

let SAMPLE_RATE = 100.0
let MIN_TIME_BETWEEN_HEARTBEATS: TimeInterval = TimeInterval(1)
let MAX_TIME_BETWEEN_HEARTBEATS: TimeInterval = TimeInterval(15)
let BACKOFF_THRESHOLD = 60

struct Accumulator {
    var key: String
    var ms: TimeInterval = TimeInterval(0)
    var totalMs: TimeInterval = TimeInterval(0)
    var lastSampleTime: Date?
    var lastPositiveSampleTime: Date?
    var heartbeatTimeout: TimeInterval? {
        willSet(newInterval) {
            sampler!.heartbeatInterval = min(sampler!.heartbeatInterval, newInterval!)
        }
    }
    var contentDuration: TimeInterval?
    var sampler: Sampler?
    var isEngaged: Bool
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
    public func trackKey(key: String,  contentDuration: TimeInterval?) -> Void {
        os_log("Tracking Key: %s", log: OSLog.default, type: .debug, key)

        if accumulators.index(forKey: key) == nil {
            var newTrackedData = Accumulator.init(
                  key: key,
                  ms: TimeInterval(0),
                  totalMs: TimeInterval(0),
                  lastSampleTime: Date(),
                  lastPositiveSampleTime: nil,
                  heartbeatTimeout: nil,
                  contentDuration: contentDuration,
                  sampler: self,
                  isEngaged: false
              )
            let heartbeatTimeout = timeoutFromDuration(contentDuration: contentDuration)
            newTrackedData.heartbeatTimeout = heartbeatTimeout
            os_log("Tracking key: %s, data", key)
            dump(newTrackedData)
            accumulators[key] = newTrackedData
          }

        if hasStartedSampling == false {
            hasStartedSampling = true
            // start the sampler and heartbeat timer loops
            guard samplerTimer == nil else { print("OOPS"); return }
            guard heartbeatsTimer == nil else { print("OOPS HB"); return }

            self.samplerTimer = Timer.scheduledTimer(timeInterval: TimeInterval(SAMPLE_RATE / 1000), target: self, selector: #selector(self.sample), userInfo: nil, repeats: false)
            self.heartbeatsTimer = Timer.scheduledTimer(timeInterval: TimeInterval(self.heartbeatInterval / 1000), target: self, selector: #selector(self.sendHeartbeats), userInfo: nil, repeats: false)
        }
    }

    // Stop tracking this item altogether.
    public func dropKey(key: String) -> Void {
        os_log("Dropping key: %s", key)
        sendHeartbeat(key: key)
        accumulators.removeValue(forKey: key)
    }

    // Sampler loop. Started on first trackKey call. Adds accumulated time to each
    // Accumulator that is eligible.
    @objc private func sample() -> Void {
        // removed: backoff_threshold, _currentTime (For testing? why was this here?)
        let currentTime = Date()
        var shouldCountSample: Bool, increment: TimeInterval, _lastSampleTime: Date
        
        for var (_, trackedData) in accumulators {
            _lastSampleTime = trackedData.lastSampleTime!
            increment = currentTime.timeIntervalSince(_lastSampleTime)

            shouldCountSample = trackedData.sampler!.sampleFn(key: trackedData.key)
            if shouldCountSample {
                os_log("Counting sample for %s", trackedData.key)
                trackedData.ms += increment
                trackedData.totalMs += increment
                trackedData.lastSampleTime = currentTime
                updateAccumulator(acc: trackedData)
            }
        }
        Timer.scheduledTimer(withTimeInterval: TimeInterval(SAMPLE_RATE / 1000), repeats: false) { timer in self.sample() }
    }

    private func sendHeartbeat(key: String) -> Void {
        var trackedData = accumulators[key]
        let incSecs: Int = Int(trackedData!.ms)
        if incSecs > 0 && Float(incSecs) <= (Float(baseHeartbeatInterval / 1000) + 0.25) {
            os_log("Sending heartbeat for %s", key)
            trackedData!.sampler!.heartbeatFn(data: trackedData!, enableHeartbeats: true)
        }
        trackedData!.ms = 0
        updateAccumulator(acc: trackedData!)
    }

    @objc private func sendHeartbeats() -> Void { // this is some bullshit. obj-c can't represent an optional so this needs to change to something else.
        // maybe just wrap it in a dictionary and set it to nil if the key isn't there.
        os_log("called send heartbeats", log: OSLog.default, type: .debug)
        for (key, trackedData) in accumulators {
            let sendThreshold = trackedData.heartbeatTimeout! - heartbeatInterval

            if Double(trackedData.ms) >= sendThreshold {
                sendHeartbeat(key: key)
            }
        }
        Timer.scheduledTimer(withTimeInterval: TimeInterval(heartbeatInterval), repeats: false) { timer in
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
        }
        return baseHeartbeatInterval
    }

    // copies of accumulators passed into methods do not update the shared accumulator[id] copy
    private func updateAccumulator(acc: Accumulator) -> Void {
        // gross, dude
        accumulators[acc.key] = acc
    }
    
}
