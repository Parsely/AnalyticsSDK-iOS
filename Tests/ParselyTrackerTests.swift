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

    func testFlushTimerKeepsFlushingWhileActive() {
        URLProtocol.registerClass(StubPixelURLProtocol.self)
        addTeardownBlock { URLProtocol.unregisterClass(StubPixelURLProtocol.self) }
        // A unique id keeps flushes from other tests' trackers out of the count. The JSON body
        // escapes "/", so match on the id rather than the whole URL.
        let id = UUID().uuidString
        let url = "http://example.com/flush-timer-\(id)"
        parselyTestTracker.eventProcessor.sync { parselyTestTracker.flushInterval = 0.5 }

        parselyTestTracker.trackPageView(url: url, urlref: url, metadata: nil, extraData: nil)
        expect(StubPixelURLProtocol.requestCount(containing: id)).toEventually(equal(1), timeout: .seconds(3))

        // An event tracked later in the same foreground stint should go out on the next tick,
        // not wait until the app is backgrounded
        parselyTestTracker.trackPageView(url: url, urlref: url, metadata: nil, extraData: nil)
        expect(StubPixelURLProtocol.requestCount(containing: id)).toEventually(equal(2), timeout: .seconds(3))
    }

    func testEachFlushTickIsScaledByItsOwnJitter() {
        URLProtocol.registerClass(StubPixelURLProtocol.self)
        addTeardownBlock { URLProtocol.unregisterClass(StubPixelURLProtocol.self) }
        let tracker: Parsely = parselyTestTracker
        let id = UUID().uuidString
        let url = "http://example.com/flush-jitter-\(id)"
        var draws = 0
        tracker.eventProcessor.sync {
            tracker.flushInterval = 10
            // A tick that skipped the jitter would wait 10 s and miss the 2 s deadlines below.
            tracker.flushJitter = {
                draws += 1
                return 0.02
            }
        }
        addTeardownBlock { tracker.eventProcessor.sync { tracker.flushJitter = { 1_000 } } }

        tracker.trackPageView(url: url, urlref: url, metadata: nil, extraData: nil)
        expect(StubPixelURLProtocol.requestCount(containing: id)).toEventually(equal(1), timeout: .seconds(2))
        tracker.trackPageView(url: url, urlref: url, metadata: nil, extraData: nil)
        expect(StubPixelURLProtocol.requestCount(containing: id)).toEventually(equal(2), timeout: .seconds(2))

        XCTAssertGreaterThanOrEqual(tracker.eventProcessor.sync { draws }, 2,
                                    "Every tick should draw a new jitter factor, not reuse the first one")
    }

    func testFlushJitterSpreadsDelaysAroundTheInterval() {
        let factors = (0..<200).map { _ in parselyTestTracker.flushJitter() }
        XCTAssert(factors.allSatisfy { (0.8...1.2).contains($0) }, "Jitter should stay within 20% of the interval")
        XCTAssertGreaterThan(Set(factors).count, 1, "Jitter should vary between ticks")
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

/// Answers every request with a 200 and records its body, so tests that flush never reach p1.parsely.com.
final class StubPixelURLProtocol: URLProtocol {
    private static let lock = NSLock()
    private static var bodies: [String] = []

    static func requestCount(containing text: String) -> Int {
        lock.withLock { bodies.filter { $0.contains(text) }.count }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let body = String(decoding: request.httpBody ?? Self.read(request.httpBodyStream), as: UTF8.self)
        Self.lock.withLock { Self.bodies.append(body) }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func read(_ stream: InputStream?) -> Data {
        guard let stream else { return Data() }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
            let n = stream.read(&buffer, maxLength: buffer.count)
            if n <= 0 { break }
            data.append(buffer, count: n)
        }
        return data
    }
}
