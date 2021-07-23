import XCTest
@testable import ParselyTracker

class EventTests: ParselyTestCase {
    let testInc: Int = 5
    let testTT: Int = 15
    let expectedVisitorID: String = "12345fdffff"
    let timestampInThePast: UInt64 = 1626963869621
    
    let expectedStrings: Dictionary<String, String> = [
        "action": "pageview",
        "url": "http://parsely-stuff.com",
        "urlref": "http://testt.com",
        "idsite": testApikey,
        "surl": "http://parsely-stuff.com",
        "sref": "http://parsely-test.com",
        ]
    let expectedInts: Dictionary<String, Int> = [
        "sid": 0,
    ]
    let expectedUInt64s: Dictionary<String, UInt64> = [
        "sts": 1626963869621,
        "slts": 1626963869621
    ]
    let extraData: Dictionary<String, String> = [
        "arbitraryParameter1": "testValue",
        "arbitraryParameter2": "testValue2"
    ]
    let testMetadata: ParselyMetadata = ParselyMetadata(
        canonical_url: "http://parsely-test.com", pub_date: Date.init(), title: "a title.", authors: ["Yogi Berra"],
        image_url: "http://parsely-test.com/image2", section: "Things my mother says", tags: ["tag1", "tag2"],
        duration: TimeInterval(100)
    )
    
    func testEvent() {
        let eventUnderTest = Event(expectedStrings["action"]!, url: expectedStrings["url"]!,
                                   urlref: expectedStrings["urlref"], metadata: testMetadata,
                                   extra_data: extraData, idsite: expectedStrings["idsite"]!,
                                   session_id: expectedInts["sid"], session_timestamp: expectedUInt64s["sts"],
                                   session_url: expectedStrings["surl"], session_referrer: expectedStrings["sref"],
                                   last_session_timestamp: expectedUInt64s["slts"])
        XCTAssertEqual(eventUnderTest.action, expectedStrings["action"],
                       "The action provided in Event initialization should be stored properly")
        XCTAssertEqual(eventUnderTest.url, expectedStrings["url"],
                       "The url provided in Event initialization should be stored properly")
        XCTAssertEqual(eventUnderTest.urlref, expectedStrings["urlref"],
                       "The urlref provided in Event initialization should be stored properly")
        XCTAssertEqual(eventUnderTest.idsite, expectedStrings["idsite"],
                       "The idsite provided in Event initialization should be stored properly")
        XCTAssertEqual(eventUnderTest.session_id, expectedInts["sid"],
                       "The sid provided in Event initialization should be stored properly")
        XCTAssertEqual(eventUnderTest.session_timestamp, expectedUInt64s["sts"],
                       "The sts provided in Event initialization should be stored properly")
        XCTAssertEqual(eventUnderTest.session_url, expectedStrings["surl"],
                       "The surl provided in Event initialization should be stored properly")
        XCTAssertEqual(eventUnderTest.session_referrer, expectedStrings["sref"],
                       "The sref provided in Event initialization should be stored properly")
        XCTAssertEqual(eventUnderTest.last_session_timestamp, expectedUInt64s["slts"],
                       "The slts provided in Event initialization should be stored properly")
        XCTAssert(eventUnderTest.rand > timestampInThePast,
                  "The rand of a newly-created Event should be a non-ancient timestamp")
        XCTAssert(eventUnderTest.metadata! === testMetadata,
                  "The metadata procided in Event initialization should be stored properly")
        let extraDataIsEquivalent: Bool = NSDictionary(dictionary: eventUnderTest.extra_data!).isEqual(to: extraData)
        XCTAssert(extraDataIsEquivalent, "The extra_data procided in Event initialization should be stored properly")
    }
    
    func testHeartbeatEvents() {
        let event = Heartbeat(
            "heartbeat",
            url: expectedStrings["url"]!,
            urlref: nil,
            inc: testInc,
            tt: testTT,
            metadata: nil,
            extra_data: nil,
            idsite: expectedStrings["idsite"]!
        )
        XCTAssertEqual(event.tt, testTT, "The tt parameter used to initialize a heartbeat event should be stored properly")
        XCTAssertEqual(event.url, expectedStrings["url"],
                       "The url used to initialize a heartbeat event should be stored properly")
        XCTAssertEqual(event.inc, testInc, "The inc parameter used to initialize a heartbeat event should be stored properly")
        XCTAssertEqual(event.idsite, ParselyTestCase.testApikey,
                       "The idsite parameter used to initialize a heartbeat event should be stored properly")
    }
    
    func testToDict() {
        let eventUnderTest = Event(expectedStrings["action"]!, url: expectedStrings["url"]!,
                                   urlref: expectedStrings["urlref"], metadata: testMetadata,
                                   extra_data: extraData, idsite: expectedStrings["idsite"]!,
                                   session_id: expectedInts["sid"], session_timestamp: expectedUInt64s["sts"],
                                   session_url: expectedStrings["surl"], session_referrer: expectedStrings["sref"],
                                   last_session_timestamp: expectedUInt64s["slts"])
        eventUnderTest.setVisitorInfo(visitorInfo: ["id": expectedVisitorID])
        let actual: Dictionary<String, Any> = eventUnderTest.toDict()
        for (key, value) in expectedStrings {
            XCTAssertEqual(actual[key]! as! String, value,
                           "The result of Event.toDict should have the correct " + key + " key")
        }
        for (key, value) in expectedInts {
            XCTAssertEqual(actual[key]! as! Int, value,
                           "The result of Event.toDict should have the correct " + key + " key")
        }
        let actualExtraData: Dictionary<String, Any> = actual["data"] as! Dictionary<String, Any>
        for (key, value) in extraData {
            XCTAssertEqual(actualExtraData[key]! as! String, value,
                           "The result of Event.toDict should have correct values passed via extra_data")
        }
        let actualMetadata: Dictionary<String, Any> = actual["metadata"] as! Dictionary<String, Any>
        let expectedMetadata: Dictionary<String, Any> = testMetadata.toDict()
        let result: Bool = NSDictionary(dictionary: actualMetadata).isEqual(to: expectedMetadata)
        XCTAssert(result, "The metadata field of the result of Event.toDict should be a dict representation of the " +
                          "given metadata")
        let idKeyExists: Bool = actualExtraData["parsely_site_uuid"] != nil
        XCTAssert(idKeyExists, "After a call to Event.setVisitorInfo that " +
                  "passes a visitor dictionary, the parsely_site_uuid key should exist in the extra_data dictionary.")
        XCTAssertEqual(actualExtraData["parsely_site_uuid"] as! String, expectedVisitorID,
                       "A visitor ID provided via Event.setVisitorInfo should be accessible in the result of " +
                       "Event.toDict as data[\"parsely_site_uuid\"]")
        XCTAssert((actualExtraData["ts"] as! UInt64) > timestampInThePast,
                  "The data.ts field of the result of Event.toDict should be a non-ancient timestamp")
    }
    
    func testSetSessionInfo() {
        let eventUnderTest = Event(expectedStrings["action"]!, url: expectedStrings["url"]!,
                                   urlref: expectedStrings["urlref"], metadata: testMetadata,
                                   extra_data: extraData, idsite: expectedStrings["idsite"]!)
        eventUnderTest.setSessionInfo(session:[
            "session_id": expectedInts["sid"],
            "session_ts": expectedUInt64s["sts"],
            "last_session_ts": expectedUInt64s["slts"],
            "session_referrer": expectedStrings["sref"],
            "session_url": expectedStrings["surl"]
        ])
        XCTAssertEqual(eventUnderTest.session_id, expectedInts["sid"],
                       "The sid set via setSessionInfo should be stored properly")
        XCTAssertEqual(eventUnderTest.session_timestamp, expectedUInt64s["sts"],
                       "The sts set via setSessionInfo should be stored properly")
        XCTAssertEqual(eventUnderTest.last_session_timestamp, expectedUInt64s["slts"],
                       "The slts set via setSessionInfo should be stored properly")
        XCTAssertEqual(eventUnderTest.session_referrer, expectedStrings["sref"],
                       "The sref set via setSessionInfo should be stored properly")
        XCTAssertEqual(eventUnderTest.session_url, expectedStrings["surl"],
                       "The surl set via setSessionInfo should be stored properly")
    }
    
    func testSetVisitorInfo() {
        let eventUnderTest = Event(expectedStrings["action"]!, url: expectedStrings["url"]!,
                                   urlref: expectedStrings["urlref"], metadata: testMetadata,
                                   extra_data: extraData, idsite: expectedStrings["idsite"]!)
        eventUnderTest.setVisitorInfo(visitorInfo: ["id": expectedVisitorID])
        XCTAssertEqual(eventUnderTest.parsely_site_uuid, expectedVisitorID,
                       "The parsely_site_uuid set via setVisitorInfo should be stored properly")
    }
}
