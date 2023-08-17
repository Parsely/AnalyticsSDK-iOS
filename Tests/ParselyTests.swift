import Nimble
@testable import ParselyAnalytics
import XCTest

class ParselyTests: ParselyTestCase {

    func testSecondsBetweenHeartbeatsNilByDefault() {
        XCTAssertNil(makePareslyTracker().secondsBetweenHeartbeats)
    }

    func testSecondsBetweenHeartbeatsNilWhenNotInConfigDict() {
        let parsely = makePareslyTracker()
        parsely.config = ["key": "value"]

        XCTAssertNil(parsely.secondsBetweenHeartbeats)
    }

    func testSecondsBetweenHeartbeatsNilWhenInConfigDictButNotTimeInterval() {
        let parsely = makePareslyTracker()
        parsely.config = ["secondsBetweenHeartbeats": "not seconds"]

        XCTAssertNil(parsely.secondsBetweenHeartbeats)

        // Notice that Int doesn't cast to TimeInterval
        let parsely2 = makePareslyTracker()
        parsely2.config = ["secondsBetweenHeartbeats": 123]

        XCTAssertNil(parsely2.secondsBetweenHeartbeats)
    }

    func testSecondsBetweenHeartbeatsParsesValueFromConfigDict() {
        let parsely = makePareslyTracker()
        parsely.config = ["secondsBetweenHeartbeats": 123.0]

        XCTAssertEqual(parsely.secondsBetweenHeartbeats, TimeInterval(123))
    }
}
