import Foundation
import Combine
import os.log

let SAMPLE_RATE = TimeInterval(0.1)
let MIN_TIME_BETWEEN_HEARTBEATS: TimeInterval = TimeInterval(1)
let MAX_TIME_BETWEEN_HEARTBEATS: TimeInterval = TimeInterval(900000)
let BACKOFF_THRESHOLD = 60

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
    var eventArgs: Dictionary<String, Any>
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
    var samplerTimer: Cancellable?
    var heartbeatsTimer: Cancellable?
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

    func trackKey(
        key: String,
        contentDuration: TimeInterval?,
        eventArgs: Dictionary<String, Any> = [:],
        resetOnExisting: Bool = false
    ) -> Void {
        os_log("Sampler tracked key: %s in class %@", log: OSLog.tracker, type: .debug, key, String(describing: self))
        let isNew: Bool = accumulators.index(forKey: key) == nil
        let shouldReset: Bool = !isNew && resetOnExisting
        if isNew || shouldReset {
            heartbeatInterval = baseHeartbeatInterval
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
        os_log("Restarted Timers in %@", log: OSLog.tracker, type: .debug, String(describing: self))
        if samplerTimer != nil {
            samplerTimer!.cancel()
        }
        samplerTimer = parselyTracker.scheduleEventProcessing(inSeconds: SAMPLE_RATE, target: self, selector: #selector(sample))
        if heartbeatsTimer != nil {
            heartbeatsTimer!.cancel()
        }
        heartbeatsTimer = parselyTracker.scheduleEventProcessing(inSeconds: heartbeatInterval, target: self, selector: #selector(sendHeartbeats))
    }

    func dropKey(key: String) -> Void {
        os_log("Dropping Sampler key: %s", log: OSLog.tracker, type: .debug, key)
        sendHeartbeat(key: key)
        accumulators.removeValue(forKey: key)
    }

    func generateEventArgs(url: String, urlref: String, metadata: ParselyMetadata? = nil, extra_data: Dictionary<String, Any>?, idsite: String) -> Dictionary<String, Any> {
        var eventArgs: [String: Any] = ["urlref": urlref, "url": url, "idsite": idsite]
        if metadata != nil {
            eventArgs["metadata"] = metadata!
        }
        if extra_data != nil {
            eventArgs["extra_data"] = extra_data!
        }
        return eventArgs
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
        samplerTimer = parselyTracker.scheduleEventProcessing(inSeconds: SAMPLE_RATE, target: self, selector: #selector(sample))
    }

    private func getHeartbeatInterval(existingTimeout: TimeInterval,
                                      totalTrackedTime: TimeInterval) -> TimeInterval {
        let totalWithOffset: TimeInterval = totalTrackedTime + offsetMatchingBaseInterval
        let newInterval: TimeInterval = totalWithOffset * backoffProportion
        let clampedNewInterval: TimeInterval = min(MAX_TIME_BETWEEN_HEARTBEATS, newInterval)
        return clampedNewInterval
    }

    private func sendHeartbeat(key: String) -> Void {
        guard var trackedData = accumulators[key] else {
            os_log("No accumulator found for %s, skipping sendHeartbeat", log: OSLog.tracker, type: .debug, key)
            return
        }
        let incSecs: TimeInterval = trackedData.accumulatedTime
        if incSecs > 0 {
            os_log("Sending heartbeat for %s", log: OSLog.tracker, type: .debug, key)
            heartbeatFn(data: trackedData, enableHeartbeats: true)
        }
        trackedData.accumulatedTime = 0
        let totalTrackedTime: TimeInterval = Date().timeIntervalSince(trackedData.firstSampleTime!)
        trackedData.heartbeatTimeout = self.getHeartbeatInterval(
            existingTimeout: trackedData.heartbeatTimeout!,
            totalTrackedTime: totalTrackedTime)
        updateAccumulator(acc: trackedData)
        heartbeatInterval = trackedData.heartbeatTimeout!
    }

    @objc internal func sendHeartbeats() -> Void {
        os_log("called send heartbeats for %@", log: OSLog.tracker, type: .debug, String(describing: self))
        for (key, _) in accumulators {
            sendHeartbeat(key: key)
        }
        heartbeatsTimer = parselyTracker.scheduleEventProcessing(inSeconds: heartbeatInterval, target: self, selector: #selector(sendHeartbeats))
    }

    private func updateAccumulator(acc: Accumulator) -> Void {
        accumulators[acc.key] = acc
    }

    internal func pause() {
        os_log("Paused from %@", log: OSLog.tracker, type: .debug, String(describing: self))
        if samplerTimer != nil {
            samplerTimer!.cancel()
            samplerTimer = nil
        }
        if heartbeatsTimer != nil {
            heartbeatsTimer!.cancel()
            heartbeatsTimer = nil
        }
    }

    internal func resume() {
        os_log("Resumed from %@", log: OSLog.tracker, type: .debug, String(describing: self))
        if hasStartedSampling {
            restartTimers()
        }
    }
}
