@testable import ParselyTracker
import XCTest

class MetadataTests: ParselyTestCase {
    func testToDictEmpty() {
        let metas = ParselyMetadata()
        XCTAssert(metas.toDict().isEmpty, "Creating a ParselyMetadata object with no parameters results in an empty object")
    }
    
    func testToDictBasic() {
        let metas = ParselyMetadata(canonical_url: "http://test.com")
        let expected = ["link": "http://test.com"]
        let actual = metas.toDict()
        XCTAssertEqual(expected as NSObject, actual as NSObject,
                       "Creating a ParselyMetadata object with one parameter results in a valid object containing " +
                       "a representation of that parameter")
    }
    
    func testToDictFields() {
        let metas = ParselyMetadata(
            canonical_url: "http://parsely-test.com", pub_date: Date.init(), title: "a title.", authors: ["Yogi Berra"], image_url: "http://parsely-test.com/image2", section: "Things my mother says", tags: ["tag1", "tag2"], duration: TimeInterval(100)
        )
        XCTAssertFalse(metas.toDict().isEmpty, "Creating a ParselyMetadataobject with many parameters results in a " +
            "non-empty object")
        XCTAssert(false, "A metadata object should contain valid attributes after initialization")
    }
    
    func testMetadata() {
        XCTAssert(false, "not implemented")
    }
}
