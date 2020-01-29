import Foundation
import os.log

class EngagedTime: Sampler {
    override func sampleFn(key : String) -> Bool {
        let trackedData: Accumulator = accumulators[key]!
        return trackedData.isEngaged
    }
    
    override func heartbeatFn(data: Accumulator, enableHeartbeats: Bool) {
        if enableHeartbeats != true {
            return
        }
        let roundedSecs: Int = Int(data.accumulatedTime)
        let totalMs: Int = Int(data.totalTime.milliseconds())
        let eventArgs = data.eventArgs!

        let event = Heartbeat(
            "heartbeat",
            url: eventArgs["url"] as! String,
            urlref: eventArgs["urlref"] as? String,
            inc: roundedSecs,
            tt: totalMs,
            metadata: eventArgs["metadata"] as? ParselyMetadata,
            extra_data: eventArgs["extra_data"] as? Dictionary<String, Any>,
            idsite: (eventArgs["idsite"] as! String)
        )

        parselyTracker.track.event(event: event)
    }
    
    func startInteraction(url: String, urlref: String = "", extra_data: Dictionary<String, Any>?, idsite: String) {
        endInteraction()
        os_log("Starting Interaction", log: OSLog.tracker, type: .debug)
        let eventArgs = generateEventArgs(url: url, urlref: urlref, extra_data: extra_data, idsite: idsite)
        trackKey(key: url, contentDuration: nil, eventArgs: eventArgs, resetOnExisting: true);
        accumulators[url]!.isEngaged = true
    }
    
    func endInteraction() {
        os_log("Ending Interaction", log: OSLog.tracker, type: .debug)
        for (url, _) in accumulators {
            guard var _ = accumulators[url] else {
                os_log("No accumulator found for %s, skipping endInteraction", log: OSLog.tracker, type:.debug, url)
                return
            }
            accumulators[url]!.isEngaged = false
        }
    }
}
