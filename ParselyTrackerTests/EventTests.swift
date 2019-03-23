import XCTest
@testable import ParselyTracker

class EventTests: ParselyTestCase {
    let testInc: Int = 5
    let testTT: Int = 15
    
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
        "sts": 1553295726,
        "slts": 1553295726
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
                                   session_id: expectedInts["sid"], session_timestamp: expectedInts["sts"],
                                   session_url: expectedStrings["surl"], session_referrer: expectedStrings["sref"],
                                   last_session_timestamp: expectedInts["slts"])
        XCTAssert(false, "Fields used in Event initialization should be stored properly")
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
                                   session_id: expectedInts["sid"], session_timestamp: expectedInts["sts"],
                                   session_url: expectedStrings["surl"], session_referrer: expectedStrings["sref"],
                                   last_session_timestamp: expectedInts["slts"])
        let expectedVisitorID: String = "12345fdffff"
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
        if (idKeyExists) {
            XCTAssertEqual(actualExtraData["parsely_site_uuid"] as! String, expectedVisitorID,
                           "A visitor ID provided via Event.setVisitorInfo should be accessible in the result of " +
                           "Event.toDict as data[\"parsely_site_uuid\"]")
        }
    }
    
    func testSetVisitorInfo() { XCTAssert(false, "not implemented") }
    func testSetSessionInfo() { XCTAssert(false, "not implemented") }
}
