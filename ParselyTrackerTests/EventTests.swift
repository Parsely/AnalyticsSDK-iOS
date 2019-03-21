import XCTest
@testable import ParselyTracker

class EventTests: ParselyTestCase {
    func testHeartbeatEvents() {
        let event = Heartbeat(
            "heartbeat",
            url: "http://test.com",
            urlref: nil,
            inc: 5,
            tt: 15,
            metadata: nil,
            extra_data: nil,
            idsite: "parsely-test.com"
        )
        XCTAssert(event.url == "http://test.com",
                  "Heartbeat events should handle inc and tt.")
        XCTAssert(event.inc == 5,
                  "Should initialize and preserve subclass parameters.")
        XCTAssert(event.idsite == "parsely-test.com",
                  "Should initialize and preserve subclass parameters.")
    }
    
    func testValidity() {
        let event = Event("pageview", url: "http://test.com", urlref: nil, metadata: nil, extra_data: nil)
        XCTAssert(event.idsite == "parsely-configured-default.com", "Events should automatically know which apikey to use.")
    }
}

