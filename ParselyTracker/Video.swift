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
    var metadata: Dictionary<String, Any?> = [:]
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
        let vId: String = data.key
        let roundedSecs: Int = Int(data.totalMs / 1000)  // logic check!
        let totalMs: Int = Int(data.totalMs)
        // get metadata for this video, too
        var curVideo = trackedVideos[data.key]
        // TODO: fix video events (need url, vid)
        let event = Event(params: [
            "date": Date().timeIntervalSince1970,
            "action": "vheartbeat",
            "inc": roundedSecs,
            "url": vId,
            "metadata": curVideo!.metadata,
            "tt": totalMs,
            "urlref": Parsely.sharedInstance.lastRequest?["urlref"]!! ?? ""
        ])
        Parsely.sharedInstance.track.event(event: event, shouldNotSetLastRequest: false)
        os_log("Sent vheartbeat for video %s", data.key)
        curVideo?._heartbeatsSent += 1
        updateVideo(video: curVideo!)
    }
    
    func trackPlay(url: String, vId: String, metadata: Dictionary<String, Any?>) -> Void {
        // set the video metas in the collector, and merge metadata if it's already being tracked
        var curVideo = self.updateVideoData(vId: vId, url: url, metadata: metadata)
        if (curVideo.hasStartedPlaying != true) {
            curVideo.hasStartedPlaying = true
            Parsely.sharedInstance.track.event(event: Event(params:[
                    "date": Date(),
                    "action": "videostart",
                    "url": vId,
                    "metadata": metadata,
                    "urlref": Parsely.sharedInstance.lastRequest?["urlref"] as? String ?? ""
                ]), shouldNotSetLastRequest: false
            )
            curVideo.isPlaying = true
            updateVideo(video: curVideo)
        }
    }
    
    func trackPause(url: String, vId: String, metadata: Dictionary<String, Any?>) -> Void {
        var curVideo = self.updateVideoData(vId: vId, url: url, metadata: metadata)
        curVideo.isPlaying = false
        updateVideo(video: curVideo)
    }

    private func updateVideoData(vId: String, url: String, metadata: Dictionary<String, Any?>) -> TrackedVideo {
        if metadata["link"] == nil {
            var metadata = metadata
            metadata["link"] = vId
        }
        let key: String = createVideoTrackingKey(vId: vId, url: url)
        // is this video key already tracked?
        if (trackedVideos[key] != nil) {
            trackedVideos[key]!.metadata = trackedVideos[key]!.metadata.merging(metadata, uniquingKeysWith: { (_old, new) in new })
        } else {
            // register video metas
            trackedVideos[key] = TrackedVideo.init(
                key: key,
                vId: vId,
                url: url,
                isPlaying: false,
                hasStartedPlaying: false,
                metadata: metadata,
                _heartbeatsSent: 0)
            // register with sampler, using same composite key as the videos metas
            trackKey(key: key, contentDuration: TimeInterval(metadata["duration"] as? Int ?? 0))
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
