import XCTest
@testable import ParselyAnalytics

class PixelTests: ParselyTestCase {
    func testBeacon() {
        let dummyEvent = Event("pageview", url: "http://parsely-stuff.com", urlref: "", metadata: nil, extra_data: nil,
                               idsite: ParselyTestCase.testApikey)
        parselyTestTracker.track.pixel.beacon(event: dummyEvent)
        XCTAssertEqual(parselyTestTracker.eventQueue.length(), 1,
                       "A call to Parsely.track.pixel.beacon should add an event to eventQueue")
    }
}
