import XCTest
@testable import ParselyTracker

class VisitorTests: ParselyTestCase {
    let visitors: VisitorManager = VisitorManager()

    func testGetVisitorInfo() {
        let visitor = visitors.getVisitorInfo()
        XCTAssertFalse(visitor.id != "", "The first call to VisitorManager.getVisitorInfo should return a non-empty object")
        // FIXME: Visitor should have a way to expire visitors, at least for testing. Otherwise the first
        // visitor created in the tests persists.
        // let thirtyDaysFromNow = Date.init(timeIntervalSinceNow: (60 * 60 * 24 * 365  / 12) * 13)
        // XCTAssertEqual(visitor["expires"] as? Date, thirtyDaysFromNow, "Should expire thirty days from now.")
        let subsequentVisitor = visitors.getVisitorInfo()
        XCTAssertEqual(visitor.id , subsequentVisitor.id ,
                       "Sequential calls to VisitorManager.getVisitorInfo within the default expiry should return objects " +
                       "with the same visitor ID")
        XCTAssertEqual(visitor.session_count, subsequentVisitor.session_count,
                       "Sequential calls to VisitorManager.getVisitorInfo within the default expiry should return objects " +
                       "with the same session count")
        XCTAssertEqual(visitor.last_session_ts, subsequentVisitor.last_session_ts,
                       "Sequential calls to VisitorManager.getVisitorInfo within the default expiry should return objects " +
                       "with the same last session timestamp")
    }
    func testExtendVisitorExpiry() {
        let visitor = visitors.getVisitorInfo()
        let capturedExpiryOne = visitor.expires!
        let subsequentVisitor = visitors.getVisitorInfo(shouldExtendExisting: true)
        let capturedExpiryTwo = subsequentVisitor.expires!
        XCTAssert(capturedExpiryOne < capturedExpiryTwo,
                  "Given an existing visitor, a call to VisitorManager.getVisitorInfo with shouldExtendExisting:true " +
                  "should return an object with a later expiry than the preexisting one")
    }
}
