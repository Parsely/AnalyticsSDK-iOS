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
    var duration: TimeInterval?
    var sampleFn: (_ params: Dictionary<String, Any?>) -> Bool
    var heartbeatFn: (_ params: Dictionary<String, Any?>) -> Void
    var sampler: Sampler?
}

protocol Accumulates {
//    func sampleFn(params: Dictionary<String, Any?>) -> Bool
//    func heartbeatFn(params: Dictionary<String, Any?>) -> Void
    func trackKey(key: String,  duration: TimeInterval?) -> Void
}

extension TimeInterval {
    func milliseconds() -> Int {
        return Int(self * 1000)
    }
}

class Sampler {
    // handles timers for engagement and video
    // generates events and pushes them into the event queue
    
    var baseHeartbeatInterval = TimeInterval(floatLiteral: 10.5) // default 10.5s
    var heartbeatInterval: TimeInterval
    var hasStartedSampling: Bool = false
    
    init() {
        // Allow publishers to configure secondsBetweenHeartbeats if, for example, they
        // wish to send fewer pixels
        if let secondsBetweenHeartbeats: TimeInterval = Parsely.sharedInstance.secondsBetweenHeartbeats {
            if secondsBetweenHeartbeats >= MIN_TIME_BETWEEN_HEARTBEATS && secondsBetweenHeartbeats <= MAX_TIME_BETWEEN_HEARTBEATS {
                baseHeartbeatInterval = secondsBetweenHeartbeats
            }
        }
        
        // the default frequency at which heartbeats are sent is the
        // _baseHeartbeatInterval, but videos that are short enough to require a smaller
        // interval can change it
        heartbeatInterval = baseHeartbeatInterval
    }
    
    
    /*
     * Add a sampling function to the registry
     *
     * The sampler maintains a registry mapping keys to sampler functions and
     * heartbeat functions. Every few milliseconds, the sampler function for each key
     * is called. If this function returns true, the accumulator for that key is
     * incremented by the appropriate time step. Every few seconds, the heartbeat
     * function for each key is run if that key's accumulator for the time window
     * is greater than zero.
     *
     * @param {string} key The key by which to identify this sampling function
     *                     in the registry
     * @param {function} sampleFn A function to run every SAMPLE_RATE ms that
     returns a boolean indicating whether the sampler
     for `key` should increment its accumulator. For
     example, engaged time tracking's sampleFn would
     return a boolean indicating whether or not the
     client is currently engaged.
     * @param {function} heartbeatFn A function to run every
     `_baseHeartbeatInterval ms if any
     time has been accumulated by the sampler. This
     function should accept the number of seconds
     accumulated after rounding.
     */
  public func trackKey(key: String,  duration: TimeInterval?) -> Void {
     os_log("Tracking Key: %s", log: OSLog.default, type: .debug, key)
    if Parsely.sharedInstance.accumulators.index(forKey: key) == nil {
        var newTrackedData = Accumulator.init(
              ms: TimeInterval(0),
              totalMs: TimeInterval(0),
              lastSampleTime: Date(),
              lastPositiveSampleTime: nil,
              heartbeatTimeout: nil,
              duration: duration,
              sampleFn: self.sampleFn,
              heartbeatFn: self.heartbeatFn,
              sampler: self
          )
        let heartbeatTimeout = timeoutFromDuration(duration: duration)
        newTrackedData.heartbeatTimeout = heartbeatTimeout
        Parsely.sharedInstance.accumulators[key] = newTrackedData
      }
      if hasStartedSampling == false {
          hasStartedSampling = true
          // set the first timeout for all of the heartbeats;
          // the callback will set itself again with the correct interval
          Timer.scheduledTimer(timeInterval: self.heartbeatInterval/1000, target: self, selector: #selector(self.sendHeartbeats), userInfo: nil, repeats: false)
      }
    }

    private func timeoutFromDuration(duration: TimeInterval?) -> TimeInterval {
        /* Returns an appropriate interval timeout in ms, based on the duration
         * of the item being tracked (also in ms), to ensure each of the 5 completion
         * intervals is tracked with a heartbeat.
         
         * A 'completion interval' is 20% of the total duration of the item being
         * tracked, so there are 5 possible completion intervals/heartbeats to send.
         
         * For many short videos, cutting the default base interval in half is enough;
         * for some very short videos, we use a custom interval determined by the
         * duration of the video.
         */
        let timeoutDefault = baseHeartbeatInterval
        if duration != nil {
            let completionInterval = duration! / Double(5)
            if completionInterval < timeoutDefault / Double(2) {
                // use a custom 20% interval if the video is so short that two completion
                // intervals would finish within our current timeout interval
                return duration! / 5
            }
            
            if completionInterval < timeoutDefault {
                // otherwise, use half the default if the video is still short enough that
                // the default would possibly skip a heartbeat
                return timeoutDefault / Double(2)
            }
            
        }
        // video is long enough that we don't need a custom interval, default is fine
        return timeoutDefault
    }
    
    private func sample(_currentTime: Date?, lastSampleTime: Date, _backoffThreshold: TimeInterval?) -> Void {
        let currentTime = _currentTime ?? Date()
        let backoffThreshold = _backoffThreshold ?? TimeInterval(BACKOFF_THRESHOLD)
        
        var shouldCountSample: Bool, increment: TimeInterval, _lastSampleTime: Date, timeSinceLastPositiveSample: TimeInterval
        
        for var (trackedKey, trackedData) in Parsely.sharedInstance.accumulators {
            _lastSampleTime = trackedData.lastSampleTime ?? lastSampleTime
            increment = currentTime.timeIntervalSince(_lastSampleTime)
            
            shouldCountSample = trackedData.sampleFn([:])
            
            if shouldCountSample {
                trackedData.ms += increment
                trackedData.totalMs += increment
            }
            trackedData.lastSampleTime = currentTime
            if (shouldCountSample) {
                timeSinceLastPositiveSample = currentTime.timeIntervalSince(trackedData.lastPositiveSampleTime!)
                // this condition denotes a key that's been tracked for long enough
                // to start backing off *and* has been negative since before the
                // last time it would have sent a heartbeat - eg a video that
                // just became unpaused
                if (trackedData.totalMs > backoffThreshold && timeSinceLastPositiveSample > self.heartbeatInterval) {
                    // reset timeout to its value pre backoff
                    // TODO: implement & test the backoff
                    trackedData.heartbeatTimeout = self.timeoutFromDuration(duration: trackedData.duration)
                }
            }
        }
    }
    
    // these are stubs that should be overriden by child classes
    func heartbeatFn(params: Dictionary<String, Any?>) -> Void {}
    func sampleFn(params: Dictionary<String, Any?>) -> Bool { return false }
    
    public func dropKey(key: String) -> Void {
        Parsely.sharedInstance.accumulators.removeValue(forKey: key)
    }
    
    /*
     * Send a heartbeat for the given key
     *
     * @param {string} trackedKey The key for which to send the heartbeat
     * @param {int} incSecs_ The number of seconds of accumulated time for each
     *                       key. This should be used only for testing.
     */
    func sendHeartbeat(trackedKey: String) -> Void {
        var trackedData = Parsely.sharedInstance.accumulators[trackedKey]
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
    

    /*
     * Send heartbeats for all accumulators with accumulated time
     *
     * Runs at intervals of _heartbeatInterval and sends heartbeats for
     * each appropriate key
     *
     * @param {int} incSecs_ The number of seconds of accumulated time for each
     *                       key. This should be used only for testing.
     */
    @objc func sendHeartbeats() -> Void { // this is some bullshit. obj-c can't represent an optional so this needs to change to something else.
        // maybe just wrap it in a dictionary and set it to nil if the key isn't there.
        os_log("Sending heartbeats", log: OSLog.default, type: .debug)
        for (key, trackedData) in Parsely.sharedInstance.accumulators {
            let sendThreshold = trackedData.heartbeatTimeout! - heartbeatInterval
            // for the shortest video, this ensures we send the heartbeats as soon as
            // possible for longer videos, in the window right before the timeout for
            // each completion interval
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
