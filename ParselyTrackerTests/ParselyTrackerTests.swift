import XCTest
@testable import ParselyTracker

class ParselyTrackerTests: ParselyTestCase {
    let testUrl = "http://example.com/testurl"
    let testVideoId = "12345"
    
    override func setUp() {
        super.setUp()
        parselyTestTracker.configure(siteId: testApikey)
    }
    
    func testConfigure() {
        XCTAssertEqual(parselyTestTracker.apikey, testApikey,
                       "After a call to Parsely.configure, Parsely.apikey should be the value used in the call's " +
                       "siteId argument")
    }
    
    func testTrackPageView() {
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 0,
                       "eventQueue should be empty immediately after initialization")
        parselyTestTracker.trackPageView(url: testUrl, urlref: testUrl, metadata: nil, extraData: nil)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Parsely.trackPageView should add an event to eventQueue")
    }
    
    func testStartEngagement() {
        parselyTestTracker.startEngagement(url: testUrl)
        let internalAccumulators:Dictionary<String, Accumulator> = parselyTestTracker.track.engagedTime.accumulators
        let testUrlAccumulator: Accumulator = internalAccumulators[testUrl]!
        XCTAssert(testUrlAccumulator.isEngaged,
                  "After a call to Parsely.startEngagement, the internal accumulator for the engaged url should exist " +
                  "and its isEngaged flag should be set")
    }
    func testStopEngagement() {
        parselyTestTracker.startEngagement(url: testUrl)
        parselyTestTracker.stopEngagement()
        let internalAccumulators:Dictionary<String, Accumulator> = parselyTestTracker.track.engagedTime.accumulators
        let testUrlAccumulator: Accumulator = internalAccumulators[testUrl]!
        XCTAssertFalse(testUrlAccumulator.isEngaged,
                  "After a call to Parsely.startEngagement followed by a call to Parsely.stopEngagement, the internal " +
                  "accumulator for the engaged url should exist and its isEngaged flag should be unset")
    }
    func testTrackPlay() {
        parselyTestTracker.trackPlay(url: testUrl, videoID: testVideoId, duration: TimeInterval(10))
        let videoManager: VideoManager = parselyTestTracker.track.videoManager
        let trackedVideos: Dictionary<String, TrackedVideo> = videoManager.trackedVideos
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Parsely.track.videoManager.trackPlay should add an event to eventQueue")
        XCTAssertEqual(trackedVideos.count, 1,
                       "After a call to parsely.trackPlay, there should be exactly one video being tracked")
        let testVideo: TrackedVideo = trackedVideos.values.first!
        XCTAssert(testVideo.isPlaying,
                  "After a call to Parsely.trackPlay, the tracked video should have its isPlaying flag set")
    }
    func testTrackPause() {
        parselyTestTracker.trackPlay(url: testUrl, videoID: testVideoId, duration: TimeInterval(10))
        parselyTestTracker.trackPause()
        let videoManager: VideoManager = parselyTestTracker.track.videoManager
        let trackedVideos: Dictionary<String, TrackedVideo> = videoManager.trackedVideos
        XCTAssertEqual(trackedVideos.count, 1,
                       "After a call to parsely.trackPlay followed by a call to parsely.trackPause, there should be " +
                       "exactly one video being tracked")
        let testVideo: TrackedVideo = trackedVideos.values.first!
        XCTAssertFalse(testVideo.isPlaying,
                       "After a call to Parsely.trackPlay, the tracked video should have its isPlaying flag unset")
    }
    func testResetVideo() {
        parselyTestTracker.trackPlay(url: testUrl, videoID: testVideoId, duration: TimeInterval(10))
        parselyTestTracker.resetVideo(url: testUrl, videoID: testVideoId)
        let videoManager: VideoManager = parselyTestTracker.track.videoManager
        let trackedVideos: Dictionary<String, TrackedVideo> = videoManager.trackedVideos
        XCTAssertEqual(trackedVideos.count, 0,
                       "A call to Parsely.resetVideo should remove an tracked video from the video manager")
    }
}
