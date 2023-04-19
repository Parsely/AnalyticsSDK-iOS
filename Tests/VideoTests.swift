import XCTest
@testable import ParselyAnalytics

class VideoTests: ParselyTestCase {
    let testVideoId: String = "videoId"
    let testUrl: String = "testurl"
    var videoManager: VideoManager?
    
    override func setUp() {
        super.setUp()
        videoManager = VideoManager(trackerInstance: parselyTestTracker)
    }
    
    func testTrackPlay() {
        XCTAssertEqual(videoManager!.trackedVideos.count, 0,
                       "videoManager.accumulators should be empty before calling trackPlay")
        videoManager!.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                                metadata: nil, extra_data: nil, idsite: ParselyTestCase.testApikey)
        XCTAssertEqual(videoManager!.trackedVideos.count, 1,
                       "A call to trackPlay should populate videoManager.accumulators with one object")
    }
    
    func testTrackPause() {
        videoManager!.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                                metadata: nil, extra_data: nil, idsite: ParselyTestCase.testApikey)
        videoManager!.trackPause()
        XCTAssertEqual(videoManager!.trackedVideos.count, 1,
                       "A call to trackPause should not remove an accumulator from videoManager.accumulators")
    }
    
    func testReset() {
        videoManager!.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                                metadata: nil, extra_data: nil, idsite: ParselyTestCase.testApikey)
        videoManager!.reset(url: testUrl, vId: testVideoId)
        XCTAssertNotNil(videoManager!.samplerTimer,
                        "videoReset should run successfully without the VideoManager instance being paused")
        XCTAssertEqual(videoManager!.trackedVideos.count, 0,
                       "A call to Parsely.track.videoManager.reset should remove a video from videoManager.trackedVideos")
    }
    func testUpdateVideoEventArgs() {
        let testSectionFirst: String = "sectionname"
        let testSectionSecond: String = "adifferentsection"
        let firstTestMetadata: ParselyMetadata = ParselyMetadata(canonical_url: testUrl, pub_date: Date(), title: "test",
                                                                 authors: nil, image_url: nil, section: testSectionFirst,
                                                                 tags: nil, duration: nil)
        videoManager!.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                                metadata: firstTestMetadata, extra_data: nil, idsite: ParselyTestCase.testApikey)
        let testTrackedVideo: TrackedVideo = videoManager!.trackedVideos.values.first!
        let actualMetadata: ParselyMetadata = testTrackedVideo.eventArgs["metadata"]! as! ParselyMetadata
        XCTAssertEqual(actualMetadata.section, testSectionFirst,
                       "The section metadata stored for a video after a call to parsely.track.videoManager.trackPlay " +
                       "should match the section metadata passed to that call.")
        let secondTestMetadata: ParselyMetadata = ParselyMetadata(canonical_url: testUrl, pub_date: Date(), title: "test",
                                                                  authors: nil, image_url: nil, section: testSectionSecond,
                                                                  tags: nil, duration: nil)
        videoManager!.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                                metadata: secondTestMetadata, extra_data: nil, idsite: ParselyTestCase.testApikey)
        let secondTestTrackedVideo: TrackedVideo = videoManager!.trackedVideos.values.first!
        let secondActualMetadata: ParselyMetadata = secondTestTrackedVideo.eventArgs["metadata"]! as! ParselyMetadata
        XCTAssertEqual(secondActualMetadata.section, testSectionSecond,
                       "The section metadata stored for a preexisting video after a call to parsely.track.videoManager.trackPlay " +
                       "should match the section metadata passed to that call.")
    }
    
    func testSampleFn() {
        let testVideoKey: String = testUrl + "::" + testVideoId
        videoManager!.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                                metadata: nil, extra_data: nil, idsite: ParselyTestCase.testApikey)
        let sampleResult: Bool = videoManager!.sampleFn(key: testVideoKey)
        XCTAssert(sampleResult,
                  "After a call to VideoManager.trackPlay, VideoManager.sample should return true for the viewing key")
    }
    
    func testSampleFnPaused() {
        let testVideoKey: String = testUrl + "::" + testVideoId
        videoManager!.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                                metadata: nil, extra_data: nil, idsite: ParselyTestCase.testApikey)
        videoManager!.trackPause()
        let sampleResult: Bool = videoManager!.sampleFn(key: testVideoKey)
        XCTAssertFalse(sampleResult,
                       "After a call to VideoManager.trackPlay followed by a call to VideoManager.trackPause, " +
                       "VideoManager.sample should return false for the viewing key")
    }
    
    func testHeartbeatFn() {
        let testVideoKey: String = testUrl + "::" + testVideoId
        let dummyEventArgs: Dictionary<String, Any> = videoManager!.generateEventArgs(
            url: testUrl, urlref: "", extra_data: nil, idsite: ParselyTestCase.testApikey)
        let dummyAccumulator: Accumulator = Accumulator(key: testVideoKey, accumulatedTime: 0, totalTime: 0,
                                                        firstSampleTime: Date(),
                                                        lastSampleTime: Date(), lastPositiveSampleTime: Date(),
                                                        heartbeatTimeout: 0, contentDuration: 0, isEngaged: false,
                                                        eventArgs: dummyEventArgs)
        videoManager!.trackPlay(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10),
                                metadata: nil, extra_data: nil, idsite: ParselyTestCase.testApikey)
        videoManager!.heartbeatFn(data: dummyAccumulator, enableHeartbeats: true)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 2,
                       "A call to VideoManager should add two events to eventQueue")
    }
}
