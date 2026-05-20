import XCTest
import Nimble

@testable import ParselyAnalytics

class ParselyTrackerTests: ParselyTestCase {
    let testUrl = "http://example.com/testurl"
    let testVideoId = "12345"

    override func setUp() {
        super.setUp()
        parselyTestTracker.configure(siteId: Parsely.testAPIKey)
    }

    func testConfigure() {
        XCTAssertEqual(parselyTestTracker.apikey, Parsely.testAPIKey,
                       "After a call to Parsely.configure, Parsely.apikey should be the value used in the call's " +
                        "siteId argument")
    }

    func testTrackPageView() {
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 0,
                       "eventQueue should be empty immediately after initialization")
        parselyTestTracker.trackPageView(url: testUrl, urlref: testUrl, metadata: nil, extraData: nil)
        // A call to Parsely.trackPageView should add an event to eventQueue
        expectParselyState(self.parselyTestTracker.eventQueue.length()).toEventually(equal(1))
    }

    func testTrackConversion() {
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 0,
                       "eventQueue should be empty immediately after initialization")
        parselyTestTracker.trackConversion(
            url: testUrl,
            conversionType: .subscription,
            conversionLabel: "weekly_plan"
        )
        // A call to Parsely.trackConversion should add an event to eventQueue
        expectParselyState(self.parselyTestTracker.eventQueue.length()).toEventually(equal(1))
        expectParselyState(self.parselyTestTracker.eventQueue.list.first?.action).toEventually(equal("conversion"))
        expectParselyState(self.parselyTestTracker.eventQueue.list.first?.extra_data["_conversion_type"] as? String)
            .toEventually(equal("subscription"))
        expectParselyState(self.parselyTestTracker.eventQueue.list.first?.extra_data["_conversion_label"] as? String)
            .toEventually(equal("weekly_plan"))
    }

    func testTrackConversionWithEmptyLabelDoesNotEnqueue() {
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 0,
                       "eventQueue should be empty immediately after initialization")
        parselyTestTracker.trackConversion(
            url: testUrl,
            conversionType: .subscription,
            conversionLabel: ""
        )
        // A call to Parsely.trackConversion with an empty conversionLabel should be skipped
        // before reaching the queue, because the Parse.ly conversions backend drops such events.
        // The `expectParselyState` helper drains the eventProcessor queue, so by the time the
        // assertion runs, the trackConversion async block has fully executed (and returned early).
        expectParselyState(self.parselyTestTracker.eventQueue.length()).to(equal(0))
    }

    func testStartEngagement() {
        parselyTestTracker.startEngagement(url: testUrl)
        // After a call to Parsely.startEngagement, the internal accumulator for the engaged url should exist
        // and its isEngaged flag should be set
        expectParselyState(self.parselyTestTracker.track.engagedTime.accumulators[self.testUrl]?.isEngaged).toEventually(beTrue())
    }
    func testStopEngagement() {
        parselyTestTracker.startEngagement(url: testUrl)
        expectParselyState(self.parselyTestTracker.track.engagedTime.accumulators[self.testUrl]).toEventuallyNot(beNil())

        parselyTestTracker.stopEngagement()
        // After a call to Parsely.startEngagement followed by a call to Parsely.stopEngagement, the internal
        // accumulator for the engaged url should exist and its isEngaged flag should be unset
        expectParselyState(self.parselyTestTracker.track.engagedTime.accumulators[self.testUrl]?.isEngaged).toEventually(beFalse())
    }
    func testTrackPlay() throws {
        parselyTestTracker.trackPlay(url: testUrl, videoID: testVideoId, duration: TimeInterval(10))
        // After a call to parsely.trackPlay, there should be exactly one video being tracked
        expectParselyState(self.parselyTestTracker.track.videoManager.trackedVideos.count).toEventually(equal(1))

        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1, "A call to Parsely.trackPlay should add an event to eventQueue")
        try XCTAssertTrue(
            XCTUnwrap(parselyTestTracker.track.videoManager.trackedVideos.values.first).isPlaying,
            "After a call to Parsely.trackPlay, the tracked video should have its isPlaying flag set"
        )
    }
    func testTrackPause() throws {
        parselyTestTracker.trackPlay(url: testUrl, videoID: testVideoId, duration: TimeInterval(10))
        expectParselyState(self.parselyTestTracker.track.videoManager.trackedVideos.isEmpty).toEventually(beFalse())

        parselyTestTracker.trackPause()
        // After a call to parsely.trackPlay followed by a call to parsely.trackPause, there should be
        // exactly one video being tracked
        expectParselyState(self.parselyTestTracker.track.videoManager.trackedVideos.count).toEventually(equal(1))

        try XCTAssertFalse(
            XCTUnwrap(parselyTestTracker.track.videoManager.trackedVideos.values.first).isPlaying,
            "After a call to Parsely.trackPlay, the tracked video should have its isPlaying flag unset"
        )
    }
    func testResetVideo() {
        parselyTestTracker.trackPlay(url: testUrl, videoID: testVideoId, duration: TimeInterval(10))
        expectParselyState(self.parselyTestTracker.track.videoManager.trackedVideos.isEmpty).toEventually(beFalse())

        parselyTestTracker.resetVideo(url: testUrl, videoID: testVideoId)
        // A call to Parsely.resetVideo should remove a tracked video from the video manager
        expectParselyState(self.parselyTestTracker.track.videoManager.trackedVideos.isEmpty).toEventually(beTrue())
    }
    func testMultipleSites() {
        parselyTestTracker.trackPageView(url: testUrl)
        parselyTestTracker.trackPageView(url: testUrl, siteId: "another-site.com")
        expectParselyState(self.parselyTestTracker.eventQueue.length()).toEventually(equal(2))

        let eventSiteIds = self.parselyTestTracker.eventQueue.get().map { $0.idsite }
        XCTAssertEqual(eventSiteIds, [Parsely.testAPIKey, "another-site.com"])
    }

    // A helper method to safely inspect the tracker's internal state.
    private func expectParselyState<T>(file: FileString = #file, line: UInt = #line, _ expression: @autoclosure @escaping () -> T?) -> SyncExpectation<T> {
        expect(file: file, line: line) {
            var value: T? = nil
            // Calling `DispatchQueue.sync` here is not ideal, but this is a convenient way to take advantange
            // of Nimble's `expect(...).toEventually(..)` DSL.
            self.parselyTestTracker.eventProcessor.sync {
                value = expression()
            }
            return value
        }
    }
}
