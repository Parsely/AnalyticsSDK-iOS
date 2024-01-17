@testable import ParselyAnalytics
import XCTest

class MetadataTests: XCTestCase {

    let expected: Dictionary<String, Any> = [
        "canonical_url": "http://parsely-test.com",
        "pub_date": Date(),
        "title": "a title.",
        "authors": ["Yogi Berra"],
        "image_url": "http://parsely-test.com/image2",
        "section": "Things my mother says",
        "tags": ["tag1", "tag2"],
        "duration": TimeInterval(100),
        "page_type": "post"
    ]

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
        let metasUnderTest = ParselyMetadata(
            canonical_url: expected["canonical_url"] as? String,
            pub_date: expected["pub_date"] as? Date,
            title: expected["title"] as? String,
            authors: expected["authors"] as? Array<String>,
            image_url: expected["image_url"] as? String,
            section: expected["section"] as? String,
            tags: expected["tags"] as? Array<String>,
            duration: expected["duration"] as? TimeInterval,
            page_type: expected["page_type"] as? String
        )
        let actual: Dictionary<String, Any> = metasUnderTest.toDict()
        let pubDateUnix: String = String(format:"%i", (expected["pub_date"]! as! Date).millisecondsSince1970)
        XCTAssertFalse(actual.isEmpty, "Creating a ParselyMetadataobject with many parameters results in a " +
                       "non-empty object")
        XCTAssertEqual(actual["link"]! as! String, expected["canonical_url"]! as! String,
                       "The link field in the result of ParselyMetadata.toDict should match the canonical_url argument " +
                       "used at initialization")
        XCTAssertEqual(actual["pub_date"]! as! String, pubDateUnix,
                       "The pub_date field in the result of ParselyMetadata.toDict should match the pub_date argument " +
                       "used at initialization")
        XCTAssertEqual(actual["title"]! as! String, expected["title"]! as! String,
                       "The title field in the result of ParselyMetadata.toDict should match the title argument " +
                       "used at initialization")
        XCTAssertEqual(actual["authors"]! as! Array<String>, expected["authors"]! as! Array<String>,
                       "The authors field in the result of ParselyMetadata.toDict should match the authors argument " +
                       "used at initialization")
        XCTAssertEqual(actual["image_url"]! as! String, expected["image_url"]! as! String,
                       "The image_url field in the result of ParselyMetadata.toDict should match the image_url argument " +
                       "used at initialization")
        XCTAssertEqual(actual["section"]! as! String, expected["section"]! as! String,
                       "The section field in the result of ParselyMetadata.toDict should match the section argument " +
                       "used at initialization")
        XCTAssertEqual(actual["tags"]! as! Array<String>, expected["tags"]! as! Array<String>,
                       "The tags field in the result of ParselyMetadata.toDict should match the tags argument " +
                       "used at initialization")
        XCTAssertEqual(actual["duration"]! as! TimeInterval, expected["duration"]! as! TimeInterval,
                       "The duration field in the result of ParselyMetadata.toDict should match the duration argument " +
                       "used at initialization")
        XCTAssertEqual(actual["page_type"]! as! String, expected["page_type"]! as! String,
                       "The page_type field in the result of ParselyMetadata.toDict should match the page_type argument " +
                       "used at initialization")                       
    }

    func testMetadata() {
        let metasUnderTest = ParselyMetadata(
            canonical_url: expected["canonical_url"] as? String,
            pub_date: expected["pub_date"] as? Date,
            title: expected["title"] as? String,
            authors: expected["authors"] as? Array<String>,
            image_url: expected["image_url"] as? String,
            section: expected["section"] as? String,
            tags: expected["tags"] as? Array<String>,
            duration: expected["duration"] as? TimeInterval,
            page_type: expected["page_type"] as? String
        )
        XCTAssertEqual(metasUnderTest.canonical_url, expected["canonical_url"]! as? String,
                       "The canonical_url field on ParselyMetadata should match the canonical_url argument " +
                       "used at initialization")
        XCTAssertEqual(metasUnderTest.pub_date, expected["pub_date"]! as? Date,
                       "The pub_date field on ParselyMetadata should match the pub_date argument " +
                       "used at initialization")
        XCTAssertEqual(metasUnderTest.title, expected["title"]! as? String,
                       "The title field on ParselyMetadata should match the title argument " +
                       "used at initialization")
        XCTAssertEqual(metasUnderTest.authors, expected["authors"]! as? Array<String>,
                       "The authors field on ParselyMetadata should match the authors argument " +
                       "used at initialization")
        XCTAssertEqual(metasUnderTest.image_url, expected["image_url"]! as? String,
                       "The image_url field on ParselyMetadata should match the image_url argument " +
                       "used at initialization")
        XCTAssertEqual(metasUnderTest.section, expected["section"]! as? String,
                       "The section field on ParselyMetadata should match the section argument " +
                       "used at initialization")
        XCTAssertEqual(metasUnderTest.tags, expected["tags"]! as? Array<String>,
                       "The tags field on ParselyMetadata should match the tags argument " +
                       "used at initialization")
        XCTAssertEqual(metasUnderTest.duration, expected["duration"]! as? TimeInterval,
                       "The duration field on ParselyMetadata should match the duration argument " +
                       "used at initialization")
        XCTAssertEqual(metasUnderTest.page_type, expected["page_type"]! as? String,
                       "The page_type field on ParselyMetadata should match the page_type argument " +
                       "used at initialization")                       
    }
}
