import XCTest
@testable import ParselyTracker

class TrackTests: ParselyTestCase {
    override func setUp() {
        super.setUp()
        parselyTestTracker.configure(siteId: ParselyTestCase.testApikey)
    }
    
    func testTrackEvent() {
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 0, "eventQueue should be empty immediately after initialization")
        let dummyEvent = Event("pageview", url: "http://parsely-stuff.com", urlref: "", metadata: nil, extra_data: nil,
                               idsite: ParselyTestCase.testApikey)
        parselyTestTracker.track.event(event: dummyEvent)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Parsely.track.event should add an event to eventQueue")
    }
    
    func testPageview() { XCTAssert(false, "not implemented") }
    func testVideoStart() { XCTAssert(false, "not implemented") }
    func testVideoPause() { XCTAssert(false, "not implemented") }
    func testVideoReset() { XCTAssert(false, "not implemented") }
    func testStartEngagement() { XCTAssert(false, "not implemented") }
    func testStopEngagement() { XCTAssert(false, "not implemented") }
    func testPause() { XCTAssert(false, "not implemented") }
    func testResume() { XCTAssert(false, "not implemented") }
    func testSendHeartbeats() { XCTAssert(false, "not implemented") }
}
