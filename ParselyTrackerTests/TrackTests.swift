import XCTest
@testable import ParselyTracker

class TrackTests: ParselyTestCase {
    override func setUp() {
        super.setUp()
        parselyTestTracker.configure(siteId: testApikey)
    }
    
    func testTrackEvent() {
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 0, "eventQueue should be empty immediately after initialization")
        let dummyEvent = Event("pageview", url: "http://parsely-stuff.com", urlref: "", metadata: nil, extra_data: nil,
                               idsite: testApikey)
        parselyTestTracker.track.event(event: dummyEvent)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Parsely.track.event should add an event to eventQueue")
    }
}
