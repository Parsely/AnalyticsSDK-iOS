import XCTest
@testable import ParselyTracker

class ParselyTrackerTests: ParselyTestCase {
    func testConfigure() {
        let expected = "exampleparsely.com"
        // XXX this assertion failing indicates a lack of isolation between tests
        // this should be fixed by having each test set up and tear down its own Parsely object instead of having
        // all tests use the same Parsely.sharedInstance.
        XCTAssertEqual(parselyTestTracker.apikey, "",
                       "Before calls to Parsely.configure, Parsely.apikey should be the empty string")
        parselyTestTracker.configure(siteId: expected)
        XCTAssertEqual(parselyTestTracker.apikey, expected,
                       "After a call to Parsely.configure, Parsely.apikey should be the value used in the call's " +
                       "siteId argument")
    }
    
    func testTrackPageView() { XCTAssert(false, "not implemented") }
    func testStartEngagement() { XCTAssert(false, "not implemented") }
    func testStopEngagement() { XCTAssert(false, "not implemented") }
    func testTrackPlay() { XCTAssert(false, "not implemented") }
    func testTrackPause() { XCTAssert(false, "not implemented") }
}
