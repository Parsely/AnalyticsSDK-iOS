import XCTest
@testable import ParselyAnalytics

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
                               idsite: Parsely.testAPIKey)
        track!.event(event: dummyEvent)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Parsely.track.event should add an event to eventQueue")
    }

    func testPageview() {
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 0,
                       "eventQueue should be empty immediately after initialization")
        track!.pageview(url: testUrl, urlref: testUrl, metadata: nil, extra_data: nil, idsite: Parsely.testAPIKey)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Track.pageview should add an event to eventQueue")
    }

    func testConversion() {
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 0,
                       "eventQueue should be empty immediately after initialization")
        track!.conversion(
            url: testUrl,
            urlref: testUrl,
            conversionType: "subscription",
            conversionLabel: "weekly_plan",
            metadata: nil,
            extra_data: ["plan": "Active"],
            idsite: Parsely.testAPIKey
        )
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Track.conversion should add an event to eventQueue")

        let queued = parselyTestTracker.eventQueue.list.first!
        XCTAssertEqual(queued.action, "conversion",
                       "Track.conversion should produce an event whose action is \"conversion\"")
        XCTAssertEqual(queued.extra_data["_conversion_type"] as? String, "subscription",
                       "Track.conversion should merge _conversion_type into extra_data")
        XCTAssertEqual(queued.extra_data["_conversion_label"] as? String, "weekly_plan",
                       "Track.conversion should merge _conversion_label into extra_data")
        XCTAssertEqual(queued.extra_data["plan"] as? String, "Active",
                       "Track.conversion should preserve caller-supplied extra_data values")
    }

    func testConversionReservedKeysOverwriteCallerExtraData() {
        track!.conversion(
            url: testUrl,
            urlref: testUrl,
            conversionType: "purchase",
            conversionLabel: "cta_pricing",
            metadata: nil,
            extra_data: ["_conversion_type": "spoofed", "_conversion_label": "spoofed"],
            idsite: Parsely.testAPIKey
        )
        let queued = parselyTestTracker.eventQueue.list.first!
        XCTAssertEqual(queued.extra_data["_conversion_type"] as? String, "purchase",
                       "Reserved key _conversion_type must not be overridable via caller extra_data")
        XCTAssertEqual(queued.extra_data["_conversion_label"] as? String, "cta_pricing",
                       "Reserved key _conversion_label must not be overridable via caller extra_data")
    }

    func testVideoStart() {
        track!.videoStart(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10), metadata: nil,
                          extra_data: nil, idsite: Parsely.testAPIKey)
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

    func testVideoPause() {
        track!.videoStart(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10), metadata: nil,
                          extra_data: nil, idsite: Parsely.testAPIKey)
        track!.videoPause()
        let videoManager: VideoManager = track!.videoManager
        let trackedVideos: Dictionary<String, TrackedVideo> = videoManager.trackedVideos
        XCTAssertEqual(trackedVideos.count, 1,
                       "After a call to Track.videoStart followed by a call to track.videoPause, there should be " +
                        "exactly one video being tracked")
        let testVideo: TrackedVideo = trackedVideos.values.first!
        XCTAssertFalse(testVideo.isPlaying,
                       "After a call to Track.videoStart, the tracked video should have its isPlaying flag unset")
    }

    func testVideoReset() {
        track!.videoStart(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10), metadata: nil,
                          extra_data: nil, idsite: Parsely.testAPIKey)
        track!.videoReset(url: testUrl, vId: testVideoId)
        XCTAssertNotNil(track!.videoManager.samplerTimer,
                        "videoReset should run successfully without the Track instance being paused")
        let videoManager: VideoManager = track!.videoManager
        let trackedVideos: Dictionary<String, TrackedVideo> = videoManager.trackedVideos
        XCTAssertEqual(trackedVideos.count, 0,
                       "A call to Parsely.resetVideo should remove an tracked video from the video manager")
    }

    func testStartEngagement() {
        track!.startEngagement(url: testUrl, urlref: testUrl, extra_data: nil, idsite: Parsely.testAPIKey)
        let internalAccumulators: Dictionary<String, Accumulator> = track!.engagedTime.accumulators
        let testUrlAccumulator: Accumulator = internalAccumulators[testUrl]!
        XCTAssert(testUrlAccumulator.isEngaged,
                  "After a call to Track.startEngagement, the internal accumulator for the engaged url should exist " +
                    "and its isEngaged flag should be set")
    }

    func testStopEngagement() {
        track!.startEngagement(url: testUrl, urlref: testUrl, extra_data: nil, idsite: Parsely.testAPIKey)
        track!.stopEngagement()
        let internalAccumulators: Dictionary<String, Accumulator> = track!.engagedTime.accumulators
        let testUrlAccumulator: Accumulator = internalAccumulators[testUrl]!
        XCTAssertFalse(testUrlAccumulator.isEngaged,
                       "After a call to Track.startEngagement followed by a call to Track.stopEngagement, the internal " +
                        "accumulator for the engaged url should exist and its isEngaged flag should be unset")
    }

    func testPause() {
        track!.pause()
        XCTAssertNil(track!.engagedTime.samplerTimer,
                     "After a call to Track.pause(), Track.engagedTime.samplerTimer should be nil")
        XCTAssertNil(track!.videoManager.samplerTimer,
                     "After a call to Track.pause(), Track.videoManager.samplerTimer should be nil")
    }

    func testResumeNoTrack() {
        track!.pause()
        track!.resume()
        XCTAssertNil(track!.engagedTime.samplerTimer,
                     "After a call to Track.resume() without timers running, Track.engagedTime.samplerTimer should be nil")
        XCTAssertNil(track!.videoManager.samplerTimer,
                     "After a call to Track.resume() without timers running, Track.videoManager.samplerTimer should be nil")
    }

    func testResume() {
        track!.videoStart(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10), metadata: nil,
                          extra_data: nil, idsite: Parsely.testAPIKey)
        track!.startEngagement(url: testUrl, urlref: testUrl, extra_data: nil, idsite: Parsely.testAPIKey)
        track!.pause()
        track!.resume()
        XCTAssertNotNil(track!.engagedTime.samplerTimer,
                        "After a call to Track.resume() with timers running, Track.engagedTime.samplerTimer should be non-nil")
        XCTAssertNotNil(track!.videoManager.samplerTimer,
                        "After a call to Track.resume() with timers running, Track.videoManager.samplerTimer should be non-nil")
    }

    func testSendHeartbeats() {
        track!.videoStart(url: testUrl, urlref: testUrl, vId: testVideoId, duration: TimeInterval(10), metadata: nil,
                          extra_data: nil, idsite: Parsely.testAPIKey)
        track!.startEngagement(url: testUrl, urlref: testUrl, extra_data: nil, idsite: Parsely.testAPIKey)

        let assertionTimeout = TimeInterval(2)
        let acceptableDifference = TimeInterval(0.25)
        let accumulationExpectation = self.expectation(description: "Heartbeat sending")
        Timer.scheduledTimer(withTimeInterval: assertionTimeout, repeats: false) { timer in
            accumulationExpectation.fulfill()
        }
        waitForExpectations(timeout: assertionTimeout + acceptableDifference, handler: nil)

        track!.sendHeartbeats()

        let expectedEngagedTimeEvents: Int = 1
        let expectedVideoEvents: Int = 2
        let expectedTotalEvents: Int = expectedEngagedTimeEvents + expectedVideoEvents
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), expectedTotalEvents,
                       "A call to Track.sendHeartbeats should add the expected number of events to the event queue")
    }
}
