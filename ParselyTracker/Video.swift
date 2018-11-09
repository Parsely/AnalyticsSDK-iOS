//
//  video.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation

struct TrackedVideo {
    var id: String
    var isPlaying: Bool = false
    var hasStartedPlaying: Bool = false
    var metadata: Dictionary<String, Any?> = [:]
    var urlOverride: String
    var _heartbeatsSent: Int = 0
}

class Video: Sampler, Accumulates {
    // underlying object behind a video
    // - register a video
    // - start playing
    // - pause
    // - stop
    
    var trackedVideos: Dictionary<String, TrackedVideo> = [:]
    
    override init() {
        super.init()
        Parsely.sharedInstance.videoPlaying = false
    }
    
    /*
     * Set root.videoPlaying if there is at least one tracked video currently playing
     */
    private func setVideoPlayingFlag() {
        let playingVideos = trackedVideos.values.filter { $0.isPlaying }
        if playingVideos.count > 0 {
            Parsely.sharedInstance.videoPlaying = true
        }
    }
    
    private func updateVideoData(vId: String, metadata: Dictionary<String, Any?>, urlOverride: String?) -> TrackedVideo {
        if metadata["link"] == nil {
            var metadata = metadata
            metadata["link"] = vId
        }
        // is this video ID already tracked?
        if (trackedVideos[vId] != nil) {
            trackedVideos[vId]!.metadata = trackedVideos[vId]!.metadata.merging(metadata, uniquingKeysWith: { (_old, new) in new })
            if urlOverride != nil {
                trackedVideos[vId]?.urlOverride = urlOverride!
            }
        } else {
            trackedVideos[vId] = TrackedVideo.init(id: vId, isPlaying: false, hasStartedPlaying: false, metadata: metadata, urlOverride: urlOverride!, _heartbeatsSent: 0)
        }
        self.trackKey(key: vId, duration: TimeInterval(exactly: metadata["duration"] as? Int ?? 0))
        
        self.sendHeartbeat(trackedKey: vId, incSecs_: trackedVideos[vId]!.metadata["duration"] as? Int)
        
        return trackedVideos[vId]!
    }
    
    override func sampleFn(params: Dictionary<String, Any?>) -> Bool {
        let vId: String = params["vId"] as! String
        return (trackedVideos[vId]?.isPlaying)!
    }
    
    override func heartbeatFn(params: Dictionary<String, Any?>) -> Void {
        let vId: String = params["vId"] as! String
        let roundedSecs: Int = params["roundedSecs"] as! Int
        let enableHeartbeats: Bool = params["enableHeartbeats"] as! Bool
        let totalMs: Int = params["totalMs"] as! Int
        
        if enableHeartbeats != true {
            return
        }
        
        var curVideo = trackedVideos[vId]
        let pixel = Pixel()
        var metadataString = ""
        do {
            let metadata = try JSONSerialization.data(withJSONObject: curVideo?.metadata ?? [:], options: .prettyPrinted)
            metadataString = String(data: metadata, encoding: .ascii) ?? ""
        } catch {
            metadataString = ""
        }
        let event = Event(params: [
            "date": Date().timeIntervalSince1970,
            "action": "vheartbeat",
            "inc": roundedSecs,
            "url": vId,
            "metadata": metadataString,
            "tt": totalMs,
            "urlref": Parsely.sharedInstance.lastRequest?["urlref"]!! ?? ""
        ])
        pixel.beacon(additionalParams: event, shouldNotSetLastRequest: false)
        curVideo?._heartbeatsSent += 1
    }
    
    func trackPlay(vId: String, metadata: Dictionary<String, Any?>, urlOverride: String) -> Void {
        var curVideo = self.updateVideoData(vId: vId, metadata: metadata, urlOverride: urlOverride)
        if (curVideo.hasStartedPlaying != true) {
            curVideo.hasStartedPlaying = true
            Parsely.sharedInstance.beacon.pixel.beacon(additionalParams: Event(params:[
                    "date": Date(),
                    "action": "videostart",
                    "url": vId,
                    "metadata": metadata,
                    "urlref": Parsely.sharedInstance.lastRequest?["urlref"] as? String ?? ""
                ]), shouldNotSetLastRequest: false
            )
            curVideo.isPlaying = true
            self.setVideoPlayingFlag()
        }
    }
    
    func trackPause(vId: String, metadata: Dictionary<String, Any?>, urlOverride: String) -> Void {
        var curVideo = self.updateVideoData(vId: vId, metadata: metadata, urlOverride: urlOverride)
        curVideo.isPlaying = false
        self.setVideoPlayingFlag()
    }
    
    func reset(vId: String) -> Void {
        if var curVideo = trackedVideos[vId] {
            curVideo.hasStartedPlaying = false
            curVideo.isPlaying = false
            sendHeartbeat(trackedKey: vId, incSecs_: nil)
            dropKey(key: vId)
            setVideoPlayingFlag()
        }
    }
    
}
