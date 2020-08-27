import XCTest
@testable import ParselyTracker

class StorageTests: ParselyTestCase {
    var storage = Storage()

    func testSetGetWithoutExpires() {
        let expected = Session(session_id: 0, session_url: "url", session_referrer: "ref", session_ts: 0, last_session_ts: 0)
        _ = storage.set(key: "baz", value: expected, expires: nil)
        let actual: Session? = storage.get(key: "baz")
        XCTAssertEqual(expected, actual,
                       "Sequential calls to Storage.set and Storage.get should preserve the stored object")
    }

    func testSetGetWithExpires() {
        let data = Session(session_id: 0, session_url: "url", session_referrer: "ref", session_ts: 0, last_session_ts: 0)
        let fifteenMinutes = Double(1000 * 15 * 60)
        let expires = Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes))
        _ = storage.set(key: "baz", value: data, expires: expires)
        let retrievedData: Session? = storage.get(key: "baz")
        var expected = data
        expected.expires = expires
        XCTAssertEqual(expected, retrievedData,
                       "Sequential calls to Storage.set and Storage.get should preserve the stored object and its " +
                       "expiry information")
    }

    func testGetSetWithNegativeExpires() {
        let data = Session(session_id: 0, session_url: "url", session_referrer: "ref", session_ts: 0, last_session_ts: 0)

        let fifteenMinutes = Double(1000 * 15 * 60) * -1.0
        let expires = Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes))
        _ = storage.set(key: "baz", value: data, expires: expires)
        let retrievedData: Session? = storage.get(key: "baz")
        XCTAssert(retrievedData == nil,
                  "After a call to Storage.set with a negative expires argument, calls to Storage.get for the set key " +
                  "should return nil")
    }

    func testWithVisitorInfo() {
        let expected = VisitorInfo(id: "thing", session_count: 0, last_session_ts: 23423524)
        _ = storage.set(key: "foo", value: expected, expires: nil)
        let actual: VisitorInfo? = storage.get(key: "foo")
        XCTAssertEqual(expected, actual)
    }

    func testExtendExpiry() {
        let data = Session(session_id: 0, session_url: "url", session_referrer: "ref", session_ts: 0, last_session_ts: 0)
        
        let fifteenMinutes = 15 * 60
        let expires = Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes))
        _ = storage.set(key: "shouldextend", value: data, expires: expires)
        let capturedOne: Session? = storage.get(key: "shouldextend")!
        let capturedExpiryOne: Date = (capturedOne?.expires!)!

        _ = storage.extendSessionExpiry(key: "shouldextend", expires: Date(timeIntervalSinceNow: TimeInterval(fifteenMinutes * 2)))
        
        let capturedTwo: Session? = storage.get(key: "shouldextend")!
        let capturedExpiryTwo: Date = (capturedTwo?.expires!)!
        
        XCTAssert(capturedExpiryOne < capturedExpiryTwo,
                  "Storage.extendExpiry should correctly set the expiry of a stored object")

    }

    func testExpire() {
        let data = Session(session_id: 0, session_url: "url", session_referrer: "ref", session_ts: 0, last_session_ts: 0)
        let expires = Date(timeIntervalSinceNow: TimeInterval(1))
        _ = storage.set(key: "shouldextend", value: data, expires: expires)
        sleep(2)
        let actual: Session? = storage.get(key: "shouldextend")
        XCTAssert(actual == nil, "Calls to Storage.get requesting expired keys should return empty objects")
    }
    
    func testStoredDataPersistsAcrossStorageInstances() {
        let expected = Session(session_id: 0, session_url: "url", session_referrer: "ref", session_ts: 0, last_session_ts: 0)
        _ = storage.set(key: "baz", value: expected, expires: nil)
        let newStorage: Storage = Storage()
        let actual: Session = newStorage.get(key: "baz")!
        XCTAssertEqual(expected, actual,
                       "Sequential calls to Storage.set and Storage.get from different instances should preserve the stored object")
    }
}
