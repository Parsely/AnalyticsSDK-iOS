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

    func testServerErrorKeepsBatchAndResendsTheSameBytes() {
        let id = trackMarkedPageView(answering: [.status(503)])
        expect(StubPixelURLProtocol.requestCount(containing: id)).toEventually(equal(2), timeout: .seconds(3))
        let bodies = StubPixelURLProtocol.bodies(containing: id)
        XCTAssertEqual(bodies.first, bodies.last, "A retry should resend the stored events unchanged")
        expectParselyState(self.parselyTestTracker.queueStore.count).toEventually(equal(0))
    }

    func testConnectionFailuresAndTimeoutsKeepBatch() {
        let id = trackMarkedPageView(answering: [.failure(.cannotConnectToHost), .failure(.timedOut)])
        expect(StubPixelURLProtocol.requestCount(containing: id)).toEventually(equal(3), timeout: .seconds(3))
        expectParselyState(self.parselyTestTracker.queueStore.count).toEventually(equal(0))
    }

    func testRejectedBatchIsDroppedNotResent() {
        let id = trackMarkedPageView(answering: [.status(400)])
        expect(StubPixelURLProtocol.requestCount(containing: id)).toEventually(equal(1), timeout: .seconds(3))
        expectParselyState(self.parselyTestTracker.queueStore.count).toEventually(equal(0))
        expect(StubPixelURLProtocol.requestCount(containing: id)).toNever(beGreaterThan(1), until: .milliseconds(500))
    }

    func testFailedBatchIsStoredOnDisk() {
        let directory = makeQueueDirectory()
        parselyTestTracker.eventProcessor.sync { parselyTestTracker.queueStore = QueueStore(directory: directory) }
        let id = trackMarkedPageView(answering: Array(repeating: .failure(.cannotConnectToHost), count: 100))
        expect(StubPixelURLProtocol.requestCount(containing: id)).toEventually(beGreaterThanOrEqualTo(1), timeout: .seconds(3))

        // A new store reads only the file, as the next launch would.
        let stored = parselyTestTracker.eventProcessor.sync {
            QueueStore(directory: directory).oldest(limit: 10, maxBytes: .max)
        }
        XCTAssertEqual(stored.count, 1)
        XCTAssert(stored.first?.contains(id) ?? false, "The unsent pageview should be in the queue file")
        parselyTestTracker.eventProcessor.sync { parselyTestTracker.queueStore = QueueStore(directory: nil) }
    }

    func testConfigureSendsEventsLeftFromAnEarlierLaunch() throws {
        URLProtocol.registerClass(StubPixelURLProtocol.self)
        addTeardownBlock { URLProtocol.unregisterClass(StubPixelURLProtocol.self) }
        let directory = makeQueueDirectory()
        let id = UUID().uuidString
        let leftover = Event("pageview", url: "http://example.com/leftover-\(id)", urlref: nil, metadata: nil,
                             extra_data: nil, idsite: Parsely.testAPIKey)
        QueueStore(directory: directory).append([try XCTUnwrap(QueueStore.serialize(leftover))])

        let tracker = makePareslyTracker()
        tracker.queueStore = QueueStore(directory: directory)
        tracker.flushInterval = 0.1
        tracker.flushJitter = { 1 }
        addTeardownBlock { tracker.eventProcessor.sync { tracker.flushInterval = 3_600 } }
        tracker.configure(siteId: Parsely.testAPIKey, handleLifecycle: false)

        expect(StubPixelURLProtocol.requestCount(containing: id)).toEventually(equal(1), timeout: .seconds(3))
        expect(tracker.eventProcessor.sync { tracker.queueStore.count }).toEventually(equal(0))
    }

    func testSendOutcomeFollowsTheSpecTable() {
        XCTAssertEqual(SendOutcome(status: 200), .sent)
        XCTAssertEqual(SendOutcome(status: 204), .sent)
        XCTAssertEqual(SendOutcome(status: nil), .retry, "No response at all should keep the batch")
        XCTAssertEqual(SendOutcome(status: 502), .retry)
        XCTAssertEqual(SendOutcome(status: 503), .retry)
        XCTAssertEqual(SendOutcome(status: 504), .retry)
        XCTAssertEqual(SendOutcome(status: 400), .drop)
        XCTAssertEqual(SendOutcome(status: 413), .drop)
        XCTAssertEqual(SendOutcome(status: 429), .drop)
        XCTAssertEqual(SendOutcome(status: 500), .drop, "A repeating proxy error should not loop")
    }

    func testBackoffDoublesFromTheIntervalUpToFifteenMinutes() {
        let delays = [1, 2, 3, 4, 5, 40].map { Parsely.backoffDelay(afterRetries: $0, interval: 30) }
        XCTAssertEqual(delays, [60, 120, 240, 480, 900, 900])
    }

    /// Tracks a pageview whose url carries a new marker, scripts the stub's answers for it, and
    /// makes flush ticks fast and unjittered. Returns the marker.
    private func trackMarkedPageView(answering answers: [StubPixelURLProtocol.Answer]) -> String {
        URLProtocol.registerClass(StubPixelURLProtocol.self)
        addTeardownBlock { URLProtocol.unregisterClass(StubPixelURLProtocol.self) }
        let tracker: Parsely = parselyTestTracker
        let id = UUID().uuidString
        StubPixelURLProtocol.script(id, answers)
        tracker.eventProcessor.sync {
            tracker.flushInterval = 0.1
            tracker.flushJitter = { 1 }
        }
        addTeardownBlock { tracker.eventProcessor.sync { tracker.flushInterval = 3_600 } }
        let url = "http://example.com/send-outcome-\(id)"
        tracker.trackPageView(url: url, urlref: url, metadata: nil, extraData: nil)
        return id
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

/// Answers every request without the network and records its body, so tests that flush never reach
/// p1.parsely.com. Requests whose body contains a scripted marker get the scripted answers in order;
/// everything else gets a 200.
final class StubPixelURLProtocol: URLProtocol {
    enum Answer {
        case status(Int)
        case failure(URLError.Code)
    }

    private static let lock = NSLock()
    private static var bodies: [String] = []
    private static var scripts: [String: [Answer]] = [:]

    static func requestCount(containing text: String) -> Int {
        lock.withLock { bodies.filter { $0.contains(text) }.count }
    }

    static func bodies(containing text: String) -> [String] {
        lock.withLock { bodies.filter { $0.contains(text) } }
    }

    static func script(_ marker: String, _ answers: [Answer]) {
        lock.withLock { scripts[marker] = answers }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let body = String(decoding: request.httpBody ?? Self.read(request.httpBodyStream), as: UTF8.self)
        let answer: Answer = Self.lock.withLock {
            Self.bodies.append(body)
            guard let marker = Self.scripts.keys.first(where: { body.contains($0) }),
                  let next = Self.scripts[marker]?.first else {
                return .status(200)
            }
            Self.scripts[marker]?.removeFirst()
            return next
        }
        switch answer {
        case .status(let code):
            let response = HTTPURLResponse(url: request.url!, statusCode: code, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        }
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
