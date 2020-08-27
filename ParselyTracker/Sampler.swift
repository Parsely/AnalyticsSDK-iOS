import Foundation
import os.log

let SAMPLE_RATE = TimeInterval(0.1)
let MIN_TIME_BETWEEN_HEARTBEATS: TimeInterval = TimeInterval(1)
let MAX_TIME_BETWEEN_HEARTBEATS: TimeInterval = TimeInterval(900000)
let BACKOFF_THRESHOLD = 60

struct EventArgs {
    var url: String?
    var urlref: String?
    var metadata: ParselyMetadata?
    var extra_data: Dictionary<String, Any>?
    var idsite: String?
}

struct Accumulator {
    var key: String
    var accumulatedTime: TimeInterval = TimeInterval(0)
    var totalTime: TimeInterval = TimeInterval(0)
    var firstSampleTime: Date?
    var lastSampleTime: Date?
    var lastPositiveSampleTime: Date?
    var heartbeatTimeout: TimeInterval?
    var contentDuration: TimeInterval?
    var isEngaged: Bool
    var eventArgs: EventArgs?
}

extension TimeInterval {
    func milliseconds() -> Int {
        return Int(self * 1000)
    }
}

class Sampler {
    var baseHeartbeatInterval = TimeInterval(floatLiteral: 10.5)
    private let offsetMatchingBaseInterval: TimeInterval = TimeInterval(35)
    private let backoffProportion: Double = 0.3
    var heartbeatInterval: TimeInterval
    var hasStartedSampling: Bool = false
    var accumulators: Dictionary<String, Accumulator> = [:]
    var samplerTimer: Timer?
    var heartbeatsTimer: Timer?
    internal let parselyTracker: Parsely
    
    init(trackerInstance: Parsely) {
        parselyTracker = trackerInstance
        
        if let secondsBetweenHeartbeats: TimeInterval = parselyTracker.secondsBetweenHeartbeats {
            if secondsBetweenHeartbeats >= MIN_TIME_BETWEEN_HEARTBEATS && secondsBetweenHeartbeats <= MAX_TIME_BETWEEN_HEARTBEATS {
                baseHeartbeatInterval = secondsBetweenHeartbeats
            }
        }
        heartbeatInterval = baseHeartbeatInterval
    }

    // Child classes should override these
    // heartbeatFn is called every time an Accumulator is eligible to send a heartbeat.
    func heartbeatFn(data: Accumulator, enableHeartbeats: Bool) -> Void { }
    // sampleFn is called to determine if an Accumulator is eligible to be sampled.
    // if true, the sample() loop will accumulate time for that item.
    func sampleFn(key: String) -> Bool { return true }

    public func trackKey(key: String,
                         contentDuration: TimeInterval?,
                         eventArgs: EventArgs?,
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
                  firstSampleTime: Date(),
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
            restartTimers()
        }
    }
    
    private func restartTimers() {
        if self.samplerTimer != nil {
            self.samplerTimer!.invalidate()
        }
        self.samplerTimer = Timer.scheduledTimer(timeInterval: SAMPLE_RATE, target: self, selector: #selector(self.sample), userInfo: nil, repeats: false)
        if self.heartbeatsTimer != nil {
            self.heartbeatsTimer!.invalidate()
        }
        self.heartbeatsTimer = Timer.scheduledTimer(timeInterval: self.heartbeatInterval, target: self, selector: #selector(self.sendHeartbeats), userInfo: nil, repeats: false)
    }

    public func dropKey(key: String) -> Void {
        os_log("Dropping Sampler key: %s", log: OSLog.tracker, type:.debug, key)
        sendHeartbeat(key: key)
        accumulators.removeValue(forKey: key)
    }

    public func generateEventArgs(url: String, urlref: String, metadata: ParselyMetadata? = nil, extra_data: Dictionary<String, Any>?, idsite: String) -> EventArgs {
        return EventArgs(url: url, urlref: urlref, metadata: metadata ?? ParselyMetadata(), extra_data: extra_data ?? [:], idsite: idsite)
    }

    @objc private func sample() -> Void {
        let currentTime = Date()
        var shouldCountSample: Bool, increment: TimeInterval
        
        for var (_, trackedData) in accumulators {
            shouldCountSample = sampleFn(key: trackedData.key)
            if shouldCountSample {
                increment = currentTime.timeIntervalSince(trackedData.lastSampleTime!)
                trackedData.accumulatedTime += increment
                trackedData.totalTime += increment
            }
            trackedData.lastSampleTime = currentTime
            updateAccumulator(acc: trackedData)
        }
        self.samplerTimer = Timer.scheduledTimer(withTimeInterval: SAMPLE_RATE, repeats: false) { timer in self.sample() }
    }
    
    private func getHeartbeatInterval(existingTimeout: TimeInterval,
                                      totalTrackedTime: TimeInterval) -> TimeInterval
    {
        let totalWithOffset: TimeInterval = totalTrackedTime + offsetMatchingBaseInterval
        let newInterval: TimeInterval = totalWithOffset * backoffProportion
        let clampedNewInterval: TimeInterval = min(MAX_TIME_BETWEEN_HEARTBEATS, newInterval)
        return clampedNewInterval
    }

    private func sendHeartbeat(key: String) -> Void {
        guard var trackedData = accumulators[key] else {
            os_log("No accumulator found for %s, skipping sendHeartbeat", log: OSLog.tracker, type:.debug, key)
            return
        }
        let incSecs: TimeInterval = trackedData.accumulatedTime
        if incSecs > 0 {
            os_log("Sending heartbeat for %s", log: OSLog.tracker, type:.debug, key)
            heartbeatFn(data: trackedData, enableHeartbeats: true)
        }
        trackedData.accumulatedTime = 0
        let totalTrackedTime: TimeInterval = Date().timeIntervalSince(trackedData.firstSampleTime!);
        trackedData.heartbeatTimeout = self.getHeartbeatInterval(
            existingTimeout: trackedData.heartbeatTimeout!,
            totalTrackedTime: totalTrackedTime)
        updateAccumulator(acc: trackedData)
        self.heartbeatInterval = trackedData.heartbeatTimeout!
    }

    @objc internal func sendHeartbeats() -> Void {
        os_log("called send heartbeats", log: OSLog.tracker, type: .debug)
        for (key, _) in accumulators {
            sendHeartbeat(key: key)
        }
        self.heartbeatsTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(heartbeatInterval), repeats: false) { timer in
            self.sendHeartbeats()
        }
    }

    private func updateAccumulator(acc: Accumulator) -> Void {
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
        if hasStartedSampling {
            restartTimers()
        }
    }
}
