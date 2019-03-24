import XCTest
@testable import ParselyTracker

class SessionTests: ParselyTestCase {
    var sessions: SessionManager!
    let testInitialUrl = "http://parsely-test.com/123"
    let testSubsequentUrl = "http://parsely-test.com/"
    let epochTimeInThePast = 1553459222
    
    override func setUp() {
        super.setUp()
        sessions = SessionManager(trackerInstance: parselyTestTracker)
    }
    
    func testGet() {
        let session = sessions.get(url: testInitialUrl, urlref: testSubsequentUrl)
        XCTAssertGreaterThanOrEqual(session["session_id"] as! Int, 0,
                                    "The session_id of a newly-created session should be greater than or equal to 0")
        XCTAssertEqual(session["session_url"] as! String, testInitialUrl,
                       "The session_url of a newly-created session should be the url it was initialized with")
        XCTAssertEqual(session["session_referrer"] as! String, testSubsequentUrl,
                       "The session_referrer of a newly-created session should be the urlref it was initialized with")
        XCTAssertGreaterThan(session["session_ts"] as! Int, epochTimeInThePast,
                             "The session_ts of a newly-created session should be non-ancient")
        XCTAssertGreaterThan(session["last_session_ts"] as! Int, epochTimeInThePast,
                             "The last_session_ts of a newly-created session should be non-ancient")
    }

    func testIDPersists() {
        let session = sessions.get(url: testInitialUrl, urlref: "")
        XCTAssertFalse(session.isEmpty, "The first call to SessionManager.get should create a session object")
        let subsequentSession = sessions.get(url: testSubsequentUrl, urlref: testInitialUrl, shouldExtendExisting: true)
        XCTAssertEqual(session["session_id"] as! Int, subsequentSession["session_id"] as! Int,
                       "Sequential calls to SessionManager.get within the session timeout that have " +
                       "shouldExtendExisting:true should return a session object with the same session ID as the " +
                       "preexisting session object")
        XCTAssertEqual(session["session_url"] as! String, testInitialUrl,
                       "The url of a session that has been extended with a different url should not have changed")
    }
    
    func testGetCorrectlyMutatesVisitor() {
        XCTAssert(false, "not implemented")
    }

    func testShouldExtendExisting() {
        let url1 = "http://parsely-test.com/123"
        let session = sessions.get(url: url1, urlref: "")
        let subsequentSession = sessions.get(url: url1, urlref: "", shouldExtendExisting: true)
        XCTAssert(subsequentSession["expires"] as! Date > session["expires"] as! Date,
                  "Sequential calls to SessionManager.get within the session timeout that have " +
                  "shouldExtendExisting:true should return a session object with an extended expiry value " +
                  "compared to the original expiry of the session")

    }
    
    func testExtendExpiry() { XCTAssert(false, "not implemented") }
}
