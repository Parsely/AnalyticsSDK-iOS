import Foundation
import os.log

struct TrackedVideo {
    var key: String
    var vId: String
    var url: String
    var isPlaying: Bool = false
    var hasStartedPlaying: Bool = false
    var eventArgs: Dictionary<String, Any>
    var _heartbeatsSent: Int = 0
}

class VideoManager: Sampler {

    var trackedVideos: Dictionary<String, TrackedVideo> = [:]

    override func sampleFn(key: String) -> Bool {
        if trackedVideos[key] == nil {
            return false
        }
        return (trackedVideos[key]?.isPlaying)!
    }

    override func heartbeatFn(data: Accumulator, enableHeartbeats: Bool) -> Void {
        if enableHeartbeats != true {
            return
        }
        let roundedSecs: Int = Int(data.accumulatedTime)
        let totalMs: Int = Int(data.totalTime.milliseconds())

        guard var curVideo = trackedVideos[data.key] else {
            os_log("Skipping heartbeat for video %s because it is not in the tracked videos list", log: OSLog.tracker, type:.debug, data.key)
            return
        }

        let event = Heartbeat(
            "vheartbeat",
            url: curVideo.url,
            urlref: curVideo.eventArgs["urlref"] as? String,
            inc: roundedSecs,
            tt: totalMs,
            metadata: curVideo.eventArgs["metadata"] as? ParselyMetadata,
            extra_data: curVideo.eventArgs["extra_data"] as? Dictionary<String, Any>,
            idsite: curVideo.eventArgs["idsite"] as! String
        )
        parselyTracker.track.event(event: event)
        os_log("Sent vheartbeat for video %s", log: OSLog.tracker, type:.debug, data.key)
        curVideo._heartbeatsSent += 1
        trackedVideos[curVideo.key] = curVideo
    }

    func trackPlay(url: String, urlref: String, vId: String, duration: TimeInterval, metadata: ParselyMetadata?, extra_data: Dictionary<String, Any>?, idsite: String) -> Void {
        trackPause()
        let eventArgs = generateEventArgs(url: url, urlref: urlref, metadata: metadata, extra_data: extra_data, idsite: idsite)
        var curVideo = self.updateVideoData(vId: vId, url: url, duration: duration, eventArgs: eventArgs)
        if (curVideo.hasStartedPlaying != true) {
            curVideo.hasStartedPlaying = true
            let event = Event(
                "videostart",
                url: url,
                urlref: urlref,
                metadata: curVideo.eventArgs["metadata"] as? ParselyMetadata,
                extra_data: curVideo.eventArgs["extra_data"] as? Dictionary<String, Any>,
                idsite: idsite
            )
            parselyTracker.track.event(event: event)
        }
        curVideo.isPlaying = true
        trackedVideos[curVideo.key] = curVideo
    }

    func trackPause() -> Void {
        os_log("Pausing all tracked videos", log: OSLog.tracker, type:.debug)
        for (key, _) in trackedVideos {
            var curVideo = trackedVideos[key]
            curVideo!.isPlaying = false
            trackedVideos[curVideo!.key] = curVideo
        }
    }

    func reset(url: String, vId: String) {
        os_log("Reset video accumulator for url %s and vId %s", log: OSLog.tracker, type:.debug, url, vId)
        trackPause()
        let key: String = createVideoTrackingKey(vId: vId, url: url)
        trackedVideos.removeValue(forKey:key)
    }

    private func updateVideoData(vId: String, url: String, duration: TimeInterval, eventArgs: Dictionary<String, Any>?) -> TrackedVideo {
        var _eventArgs: [String: Any] = eventArgs ?? [String: Any]()
        let metadata = _eventArgs["metadata"] as? ParselyMetadata

        if (metadata != nil) {
            metadata!.canonical_url = vId
            metadata!.duration = duration
        }
        _eventArgs["metadata"] = metadata
        let key: String = createVideoTrackingKey(vId: vId, url: url)

        if (trackedVideos[key] != nil) {
            trackedVideos[key]!.eventArgs = _eventArgs
        } else {
            trackedVideos[key] = TrackedVideo.init(
                key: key,
                vId: vId,
                url: url,
                isPlaying: false,
                hasStartedPlaying: false,
                eventArgs: _eventArgs,
                _heartbeatsSent: 0)

            trackKey(key: key, contentDuration: duration, eventArgs:_eventArgs)
        }

        return trackedVideos[key]!
    }

    private func createVideoTrackingKey(vId: String, url: String) -> String {
        return url + "::" + vId
    }
}
