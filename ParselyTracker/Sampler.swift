//
//  Sampler.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation
import os.log

let SAMPLE_RATE = 100
let MIN_TIME_BETWEEN_HEARTBEATS: TimeInterval = TimeInterval(1)
let MAX_TIME_BETWEEN_HEARTBEATS: TimeInterval = TimeInterval(15)
let BACKOFF_THRESHOLD = 60

struct Accumulator {
    var ms: TimeInterval = TimeInterval(0)
    var totalMs: TimeInterval = TimeInterval(0)
    var lastSampleTime: Date?
    var lastPositiveSampleTime: Date?
    var heartbeatTimeout: TimeInterval? {
        willSet(newInterval) {
            print(newInterval!)
            sampler!.heartbeatInterval = min(sampler!.heartbeatInterval, newInterval!)
        }
    }
    var contentDuration: TimeInterval?
    var sampler: Sampler?
}

protocol Accumulates {
//    func sampleFn(params: Dictionary<String, Any?>) -> Bool
//    func heartbeatFn(params: Dictionary<String, Any?>) -> Void
    func trackKey(key: String,  contentDuration: TimeInterval?) -> Void
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
    
    init() {
        if let secondsBetweenHeartbeats: TimeInterval = Parsely.sharedInstance.secondsBetweenHeartbeats {
            if secondsBetweenHeartbeats >= MIN_TIME_BETWEEN_HEARTBEATS && secondsBetweenHeartbeats <= MAX_TIME_BETWEEN_HEARTBEATS {
                baseHeartbeatInterval = secondsBetweenHeartbeats
            }
        }
        heartbeatInterval = baseHeartbeatInterval
    }

  public func trackKey(key: String,  contentDuration: TimeInterval?) -> Void {
     os_log("Tracking Key: %s", log: OSLog.default, type: .debug, key)
    if accumulators.index(forKey: key) == nil {
        var newTrackedData = Accumulator.init(
              ms: TimeInterval(0),
              totalMs: TimeInterval(0),
              lastSampleTime: Date(),
              lastPositiveSampleTime: nil,
              heartbeatTimeout: nil,
              contentDuration: contentDuration,
              sampler: self
          )
        let heartbeatTimeout = timeoutFromDuration(contentDuration: contentDuration)
        newTrackedData.heartbeatTimeout = heartbeatTimeout
        accumulators[key] = newTrackedData
      }
      if hasStartedSampling == false {
          hasStartedSampling = true
        // this should start the timer for sampling
          Timer.scheduledTimer(timeInterval: self.heartbeatInterval/1000, target: self, selector: #selector(self.sendHeartbeats), userInfo: nil, repeats: false)
      }
    }

    private func timeoutFromDuration(contentDuration: TimeInterval?) -> TimeInterval {
        let timeoutDefault = baseHeartbeatInterval
        if contentDuration != nil {
            let completionInterval = contentDuration! / Double(5)
            if completionInterval < timeoutDefault / Double(2) {
                return contentDuration! / 5
            }
            
            if completionInterval < timeoutDefault {
                return timeoutDefault / Double(2)
            }
        }
        return timeoutDefault
    }
    
    private func sample(_currentTime: Date?, lastSampleTime: Date, _backoffThreshold: TimeInterval?) -> Void {
        let currentTime = _currentTime ?? Date()
        let backoffThreshold = _backoffThreshold ?? TimeInterval(BACKOFF_THRESHOLD)
        
        var shouldCountSample: Bool, increment: TimeInterval, _lastSampleTime: Date, timeSinceLastPositiveSample: TimeInterval
        
        for var (trackedKey, trackedData) in accumulators {
            _lastSampleTime = trackedData.lastSampleTime ?? lastSampleTime
            increment = currentTime.timeIntervalSince(_lastSampleTime)
            
            shouldCountSample = trackedData.sampler!.sampleFn(params: [:])
            
            if shouldCountSample {
                trackedData.ms += increment
                trackedData.totalMs += increment
            }
            trackedData.lastSampleTime = currentTime
            if (shouldCountSample) {
                timeSinceLastPositiveSample = currentTime.timeIntervalSince(trackedData.lastPositiveSampleTime!)
                // related to backoff
                if (trackedData.totalMs > backoffThreshold && timeSinceLastPositiveSample > self.heartbeatInterval) {
                    // reset timeout to its value pre backoff
                    // TODO: implement & test the backoff
                    trackedData.heartbeatTimeout = self.timeoutFromDuration(contentDuration: trackedData.contentDuration)
                }
            }
        }
    }
    
    // these are stubs that should be overriden by child classes
    func heartbeatFn(params: Dictionary<String, Any?>) -> Void {}
    func sampleFn(params: Dictionary<String, Any?>) -> Bool { return false }
    
    public func dropKey(key: String) -> Void {
        accumulators.removeValue(forKey: key)
    }

    func sendHeartbeat(trackedKey: String) -> Void {
        var trackedData = accumulators[trackedKey]
        let incSecs: Int = Int(trackedData!.ms)
        if incSecs > 0 && Float(incSecs) <= (Float(baseHeartbeatInterval / 1000) + 0.25) {
            self.heartbeatFn(params: [
                "roundedSeconds": incSecs,
                "enableHeartbeats": true,
                "totalMs": trackedData!.totalMs
            ])
        }
        trackedData!.ms = 0
    }

    @objc func sendHeartbeats() -> Void { // this is some bullshit. obj-c can't represent an optional so this needs to change to something else.
        // maybe just wrap it in a dictionary and set it to nil if the key isn't there.
        os_log("Sending heartbeats", log: OSLog.default, type: .debug)
        for (key, trackedData) in accumulators {
            let sendThreshold = trackedData.heartbeatTimeout! - heartbeatInterval

            if Double(trackedData.ms) >= sendThreshold {
                sendHeartbeat(trackedKey: key)
            }
        }
        // should repeats be true?
        Timer.scheduledTimer(withTimeInterval: TimeInterval(heartbeatInterval/1000), repeats: false) { timer in
            self.sendHeartbeats()
        }
    }
    
    
}
