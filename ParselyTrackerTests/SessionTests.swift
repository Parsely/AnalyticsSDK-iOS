import XCTest
@testable import ParselyTracker

class SessionTests: ParselyTestCase {
    var sessions: SessionManager!
    let sessionStorageKey = "_parsely_session_identifier"
    let testInitialUrl = "http://parsely-test.com/123"
    let testSubsequentUrl = "http://parsely-test.com/"
    let epochTimeInThePast = 1553459222
    
    override func setUp() {
        super.setUp()
        sessions = SessionManager(trackerInstance: parselyTestTracker)
        // XXX slight hack, ideally this functionality should be a method on SessionManager
        Storage().expire(key: sessionStorageKey)
    }
    
    func testGet() {
        let session = sessions.get(url: testInitialUrl, urlref: testSubsequentUrl)
        XCTAssertGreaterThanOrEqual(session.session_id , 0,
                                    "The session_id of a newly-created session should be greater than or equal to 0")
        XCTAssertEqual(session.session_url!, testInitialUrl,
                       "The session_url of a newly-created session should be the url it was initialized with")
        XCTAssertEqual(session.session_referrer!, testSubsequentUrl,
                       "The session_referrer of a newly-created session should be the urlref it was initialized with")
        XCTAssertGreaterThan(session.session_ts , UInt64(epochTimeInThePast),
                             "The session_ts of a newly-created session should be non-ancient")
        XCTAssertGreaterThan(session.last_session_ts!, UInt64(epochTimeInThePast),
                             "The last_session_ts of a newly-created session should be non-ancient")
    }

    func testIDPersists() {
        let session = sessions.get(url: testInitialUrl, urlref: "")
        XCTAssertEqual(session.session_id, 0, "The first call to SessionManager.get should create a session object")
        let subsequentSession = sessions.get(url: testSubsequentUrl, urlref: testInitialUrl, shouldExtendExisting: true)
        XCTAssertEqual(session.session_id , subsequentSession.session_id,
                       "Sequential calls to SessionManager.get within the session timeout that have " +
                       "shouldExtendExisting:true should return a session object with the same session ID as the " +
                       "preexisting session object")
        XCTAssertEqual(session.session_url!, testInitialUrl,
                       "The url of a session that has been extended with a different url should not have changed")
    }
    
    func testGetCorrectlyMutatesVisitor() {
        let visitorManager = VisitorManager()
        let visitorInfo = visitorManager.getVisitorInfo()
        let initialSessionCount: Int = visitorInfo.session_count
        let session = sessions.get(url: testInitialUrl, urlref: testSubsequentUrl)
        let mutatedVisitor = visitorManager.getVisitorInfo()
        let expectedSessionCount = initialSessionCount + 1
        let expectedLastSessionTs: UInt64 = session.session_ts
        XCTAssertEqual(mutatedVisitor.session_count , expectedSessionCount,
                       "The visitor's session_count should have been incremented after a call to SessionManager.get")
        XCTAssertEqual(mutatedVisitor.last_session_ts , UInt64(expectedLastSessionTs),
                       "The visitor's last_session_ts should have been set to the session's session_ts after a call to " +
                       "SessionManager.get")
    }

    func testShouldExtendExisting() {
        let session = sessions.get(url: testInitialUrl, urlref: "")
        let subsequentSession = sessions.get(url: testInitialUrl, urlref: "", shouldExtendExisting: true)
        XCTAssert(subsequentSession.expires! > session.expires!,
                  "Sequential calls to SessionManager.get within the session timeout that have " +
                  "shouldExtendExisting:true should return a session object with an extended expiry value " +
                  "compared to the original expiry of the session")
    }
    
    func testExtendExpiry() {
        let initialSession = sessions.get(url: testInitialUrl, urlref: "")
        let initialSessionExpiry: Date = initialSession.expires!
        let extendSessionExpiryResult = sessions.extendExpiry()
        let sessionUnderTest = sessions.get(url: testInitialUrl, urlref: "")
        XCTAssertGreaterThan(extendSessionExpiryResult.expires!, initialSessionExpiry,
                             "A call to extendSessionExpiry after a call to SessionManager.get should extend the session's " +
                             "expiry by the expected amount and return the corresponding value.")
        XCTAssertGreaterThan(sessionUnderTest.expires!, initialSessionExpiry,
                             "A call to extendSessionExpiry after a call to SessionManager.get should extend the session's " +
                             "expiry by the expected amount.")
    }
}
