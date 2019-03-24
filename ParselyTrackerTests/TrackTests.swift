import XCTest
@testable import ParselyTracker

class TrackTests: ParselyTestCase {
    var track: Track?
    let testUrl: String = "http://parsely-stuff.com"
    let testVideoId: String = "1234567dfff"
    
    override func setUp() {
        super.setUp()
        track = Track(trackerInstance: parselyTestTracker)
    }
    
    func testTrackEvent() {
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 0, "eventQueue should be empty immediately after initialization")
        let dummyEvent = Event("pageview", url: testUrl, urlref: "", metadata: nil, extra_data: nil,
                               idsite: ParselyTestCase.testApikey)
        track!.event(event: dummyEvent)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Parsely.track.event should add an event to eventQueue")
    }
    
    func testPageview() {
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 0,
                       "eventQueue should be empty immediately after initialization")
        track!.pageview(url: testUrl, urlref: testUrl, metadata: nil, extra_data: nil, idsite: ParselyTestCase.testApikey)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Track.pageview should add an event to eventQueue")
    }
    
    func testVideoStart() {
        track!.videoStart(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10), metadata: nil,
                          extra_data: nil, idsite: ParselyTestCase.testApikey)
        let videoManager: VideoManager = track!.videoManager
        let trackedVideos: Dictionary<String, TrackedVideo> = videoManager.trackedVideos
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Track.videoStart should add an event to eventQueue")
        XCTAssertEqual(trackedVideos.count, 1,
                       "After a call to Track.videoStart, there should be exactly one video being tracked")
        let testVideo: TrackedVideo = trackedVideos.values.first!
        XCTAssert(testVideo.isPlaying,
                  "After a call to Track.videoStart, the tracked video should have its isPlaying flag set")
    }
    
    func testVideoPause() { XCTAssert(false, "not implemented") }
    func testVideoReset() { XCTAssert(false, "not implemented") }
    func testStartEngagement() { XCTAssert(false, "not implemented") }
    func testStopEngagement() { XCTAssert(false, "not implemented") }
    func testPause() { XCTAssert(false, "not implemented") }
    func testResume() { XCTAssert(false, "not implemented") }
    func testSendHeartbeats() { XCTAssert(false, "not implemented") }
}
