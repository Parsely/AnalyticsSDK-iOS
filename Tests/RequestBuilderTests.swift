@testable import ParselyTracker
import XCTest

class RequestBuilderTests: ParselyTestCase {
    private func makeEvents() -> Array<Event> {
        let exampleMetadata: ParselyMetadata = ParselyMetadata(
            canonical_url:"http://parsely-test.com",
            pub_date: Date(timeIntervalSince1970: 3),
            title: "a title.",
            authors: ["Yogi Berra"],
            image_url: "http://parsely-test.com/image2",
            section: "Things my mother says",
            tags: ["tag1", "tag2"],
            duration: TimeInterval(100)
        )
        return [Event(
            "pageview",
            url: "http://test.com",
            urlref: nil,
            metadata: exampleMetadata,
            extra_data: nil
            )]
    }
    
    func testEndpoint() {
        let endpoint = RequestBuilder.buildPixelEndpoint()
        XCTAssert(endpoint != "", "buildPixelEndpoint should return a non-empty string")
    }
    
    func testBuildPixelEndpoint() {
        var expected: String = "https://p1.parsely.com/mobileproxy"
        var actual = RequestBuilder.buildPixelEndpoint()
        XCTAssert(actual == expected, "buildPixelEndpoint should return the correct URL for the given date")
        expected = "https://p1.parsely.com/mobileproxy"
        actual = RequestBuilder.buildPixelEndpoint()
        XCTAssert(actual == expected, "buildPixelEndpoint should return the correct URL for the given date")
    }
    
    func testHeaders() {
        let events: Array<Event> = makeEvents()
        let actual: Dictionary<String, Any?> = RequestBuilder.buildHeadersDict(events: events)
        XCTAssert(actual["User-Agent"] != nil, "buildHeadersDict should return a dictionary containing a non-nil " +
                  "user agent string")
    }

    func testBuildRequest() {
        let events = makeEvents()
        let request = RequestBuilder.buildRequest(events: events)
        XCTAssertNotNil(request, "buildRequest should return a non-nil value")
        XCTAssert(request!.url.contains("https://p1"),
                  "RequestBuilder.buildRequest should return a request with a valid-looking url attribute")
        XCTAssertNotNil(request!.headers,
                        "RequestBuilder.buildRequest should return a request with a non-nil headers attribute")
        XCTAssertNotNil(request!.headers["User-Agent"],
                        "RequestBuilder.buildRequest should return a request with a non-nil User-Agent header")
        XCTAssertNotNil(request!.params,
                        "RequestBuilder.buildRequest should return a request with a non-nil params attribute")
        let actualEvents: Array<Dictionary<String, Any>> = request!.params["events"] as! Array<Dictionary<String, Any>>
        XCTAssertEqual(actualEvents.count, events.count,
                       "RequestBuilder.buildRequest should return a request with an events array containing all " +
                       "relevant revents")
    }
    
    func testParamsJson() {
        let events = makeEvents()
        let request = RequestBuilder.buildRequest(events: events)
        var jsonData: Data? = nil
        do {
            jsonData = try JSONSerialization.data(withJSONObject: request!.params)
        } catch { }
        XCTAssertNotNil(jsonData, "Request params should serialize to JSON")
    }
    
    func testGetHardwareString() {
        let result = RequestBuilder.getHardwareString()
        let expected = Set(["x86_64", "arm64"])
        XCTAssertTrue(expected.contains(result),
                    "The result of RequestBuilder.getHardwareString should accurately represent the simulator hardware"
        )
    }
    
    func testGetUserAgent() {
        let result = RequestBuilder.getUserAgent()
        let expectedSubstring = "ParselyDemo/1.0 iOS"
        XCTAssert(result.contains(expectedSubstring),
                       "The result of RequestBuilder.getUserAgent should accurately represent the simulator agent"
        )
    }
}
