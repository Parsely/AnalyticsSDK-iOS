//
//  video.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

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
    
    override init() {
        super.init()
    }
    
    override func sampleFn(key: String) -> Bool {
        return (trackedVideos[key]?.isPlaying)!
    }
    
    override func heartbeatFn(data: Accumulator, enableHeartbeats: Bool) -> Void {
        if enableHeartbeats != true {
            return
        }
        let roundedSecs: Int = Int(data.ms)
        let totalMs: Int = Int(data.totalMs * 1000)
        var curVideo = trackedVideos[data.key]
        let event = Heartbeat(
            "vheartbeat",
            url: curVideo!.url,
            urlref: curVideo?.eventArgs["urlref"] as? String,
            inc: roundedSecs,
            tt: totalMs,
            metadata: curVideo?.eventArgs["metadata"] as? Dictionary<String, Any>
        )
        Parsely.sharedInstance.track.event(event: event)
        os_log("Sent vheartbeat for video %s", data.key)
        curVideo?._heartbeatsSent += 1
        updateVideo(video: curVideo!)
    }
    
    func trackPlay(url: String, urlref: String, vId: String, metadata: Dictionary<String, Any>?) -> Void {
        let eventArgs = generateEventArgs(urlref: urlref, metadata: metadata)
        var curVideo = self.updateVideoData(vId: vId, url: url, eventArgs: eventArgs)
        if (curVideo.hasStartedPlaying != true) {
            curVideo.hasStartedPlaying = true
            let event = Event(
                "videostart",
                url: url,
                urlref: urlref,
                metadata: eventArgs["metadata"] as? Dictionary<String, Any>
            )
            Parsely.sharedInstance.track.event(event: event)
            curVideo.isPlaying = true
            updateVideo(video: curVideo)
        }
    }
    
    func trackPause(url: String, urlref: String, vId: String, metadata: Dictionary<String, Any>?) -> Void {
        let eventArgs = generateEventArgs(urlref: urlref, metadata: metadata)
        var curVideo = self.updateVideoData(vId: vId, url: url, eventArgs: eventArgs)
        curVideo.isPlaying = false
        updateVideo(video: curVideo)
    }

    private func updateVideoData(vId: String, url: String, eventArgs: Dictionary<String, Any>?) -> TrackedVideo {
        var _eventArgs: [String: Any] = eventArgs ?? [String: Any]()
        var metadata = _eventArgs["metadata"] as? Dictionary<String, Any> ?? [String: Any]()
        if metadata["link"] == nil {
            metadata["link"] = vId
        }
        _eventArgs["metadata"] = metadata
        let key: String = createVideoTrackingKey(vId: vId, url: url)
        // is this video key already tracked?
        if (trackedVideos[key] != nil) {
            trackedVideos[key]!.eventArgs = _eventArgs
        } else {
            // register video metas
            trackedVideos[key] = TrackedVideo.init(
                key: key,
                vId: vId,
                url: url,
                isPlaying: false,
                hasStartedPlaying: false,
                eventArgs: _eventArgs,
                _heartbeatsSent: 0)
            // register with sampler, using same composite key as the videos metas
            trackKey(key: key, contentDuration: TimeInterval(metadata["duration"] as? Int ?? 0), eventArgs:_eventArgs)
        }

        return trackedVideos[key]!
    }

    private func updateVideo(video: TrackedVideo) {
        trackedVideos[video.key] = video
    }

    private func createVideoTrackingKey(vId: String, url: String) -> String {
        return url + "::" + vId
    }

    // todo: this isn't called anywhere
    func reset(key: String) -> Void {
        if var curVideo = trackedVideos[key] {
            curVideo.hasStartedPlaying = false
            curVideo.isPlaying = false
            dropKey(key: key)
        }
    }
    
}
