@testable import ParselyAnalytics
import XCTest

class MetadataTests: XCTestCase {

    let expected: Dictionary<String, Any> = [
        "canonical_url": "http://parsely-test.com",
        "pub_date": Date(),
        "save_date": Date(),
        "title": "a title.",
        "authors": ["Yogi Berra"],
        "image_url": "http://parsely-test.com/image2",
        "section": "Things my mother says",
        "tags": ["tag1", "tag2"],
        "duration": TimeInterval(100),
        "page_type": "post",
        "urls": "http://parsely-test.com",
        "post_id": "1",
        "pub_date_tmsp": Date(),
        "custom_metadata": "hedgehogs",
        "save_date_tmsp": Date(),
        "thumb_url": "http://parsely-test.com/image2",
        "full_content_word_count": 100,
        "share_urls": ["http://parsely-test.com"],
        "data_source": "the moon",
        "canonical_hash": "hash_browns",
        "canonical_hash64": "hash_browns64",
        "video_platform": "youtube",
        "language": "en",
        "full_content": "the full content of the article",
        "full_content_sha512": "what is this?",
        "network_id_str": "abc",
        "network_canonical": "network canonical"

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
            save_date: expected["save_date"] as? Date,
            title: expected["title"] as? String,
            authors: expected["authors"] as? Array<String>,
            image_url: expected["image_url"] as? String,
            section: expected["section"] as? String,
            tags: expected["tags"] as? Array<String>,
            duration: expected["duration"] as? TimeInterval,
            page_type: expected["page_type"] as? String,
            urls: expected["urls"] as? String,
            post_id: expected["post_id"] as? String,
            pub_date_tmsp: expected["pub_date_tmsp"] as? Date,
            custom_metadata: expected["custom_metadata"] as? String,
            save_date_tmsp: expected["save_date_tmsp"] as? Date,
            thumb_url: expected["thumb_url"] as? String,
            full_content_word_count: expected["full_content_word_count"] as? Int,
            share_urls: expected["share_urls"] as? Array<String>,
            data_source: expected["data_source"] as? String,
            canonical_hash: expected["canonical_hash"] as? String,
            canonical_hash64: expected["canonical_hash64"] as? String,
            video_platform: expected["video_platform"] as? String,
            language: expected["language"] as? String,
            full_content: expected["full_content"] as? String,
            full_content_sha512: expected["full_content_sha512"] as? String,
            network_id_str: expected["network_id_str"] as? String,
            network_canonical: expected["network_canonical"] as? String
        )
        let actual: Dictionary<String, Any> = metasUnderTest.toDict()
        let pubDateUnix: String = String(format:"%i", (expected["pub_date"]! as! Date).millisecondsSince1970)
        let saveDateUnix: String = String(format:"%i", (expected["save_date"]! as! Date).millisecondsSince1970)
        let pubDateTmspUnix: String = String(format:"%i", (expected["pub_date_tmsp"]! as! Date).millisecondsSince1970)
        let saveDateTmspUnix: String = String(format:"%i", (expected["save_date_tmsp"]! as! Date).millisecondsSince1970)
        XCTAssertFalse(actual.isEmpty, "Creating a ParselyMetadataobject with many parameters results in a " +
                       "non-empty object")
        XCTAssertEqual(actual["link"]! as! String, expected["canonical_url"]! as! String,
                       "The link field in the result of ParselyMetadata.toDict should match the canonical_url argument " +
                       "used at initialization")
        XCTAssertEqual(actual["pub_date"]! as! String, pubDateUnix,
                       "The pub_date field in the result of ParselyMetadata.toDict should match the pub_date argument " +
                       "used at initialization")
        XCTAssertEqual(actual["save_date"]! as! String, pubDateUnix,
                       "The save_date field in the result of ParselyMetadata.toDict should match the save_date argument " +
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
        XCTAssertEqual(actual["urls"]! as! String, expected["urls"]! as! String,
                        "The urls field in the result of ParselyMetadata.toDict should match the urls argument " +
                        "used at initialization")
        XCTAssertEqual(actual["post_id"]! as! String, expected["post_id"]! as! String,
                        "The post_id field in the result of ParselyMetadata.toDict should match the post_id argument " +
                        "used at initialization")
        XCTAssertEqual(actual["pub_date_tmsp"]! as! String, pubDateTmspUnix,
                        "The pub_date_tmsp field in the result of ParselyMetadata.toDict should match the pub_date_tmsp argument " +
                        "used at initialization")             
        XCTAssertEqual(actual["custom_metadata"]! as! String, expected["custom_metadata"]! as! String,
                        "The custom_metadata field in the result of ParselyMetadata.toDict should match the custom_metadata argument " +
                        "used at initialization")
        XCTAssertEqual(actual["save_date_tmsp"]! as! String, saveDateTmspUnix,
                        "The save_date_tmsp field in the result of ParselyMetadata.toDict should match the save_date_tmsp argument " +
                        "used at initialization")
        XCTAssertEqual(actual["thumb_url"]! as! String, expected["thumb_url"]! as! String,
                        "The thumb_url field in the result of ParselyMetadata.toDict should match the thumb_url argument " +
                        "used at initialization")
        XCTAssertEqual(actual["full_content_word_count"]! as! Int, expected["full_content_word_count"]! as! Int,
                        "The full_content_word_count field in the result of ParselyMetadata.toDict should match the full_content_word_count argument " +
                        "used at initialization")
        XCTAssertEqual(actual["share_urls"]! as! Array<String>, expected["share_urls"]! as! Array<String>,
                        "The share_urls field in the result of ParselyMetadata.toDict should match the share_urls argument " +
                        "used at initialization")
        XCTAssertEqual(actual["data_source"]! as! String, expected["data_source"]! as! String,
                        "The data_source field in the result of ParselyMetadata.toDict should match the data_source argument " +
                        "used at initialization")
        XCTAssertEqual(actual["canonical_hash"]! as! String, expected["canonical_hash"]! as! String,
                        "The canonical_hash field in the result of ParselyMetadata.toDict should match the canonical_hash argument " +
                        "used at initialization")
        XCTAssertEqual(actual["canonical_hash64"]! as! String, expected["canonical_hash64"]! as! String,
                        "The canonical_hash64 field in the result of ParselyMetadata.toDict should match the canonical_hash64 argument " +
                        "used at initialization")
        XCTAssertEqual(actual["video_platform"]! as! String, expected["video_platform"]! as! String,
                        "The video_platform field in the result of ParselyMetadata.toDict should match the video_platform argument " +
                        "used at initialization")
        XCTAssertEqual(actual["language"]! as! String, expected["language"]! as! String,
                        "The language field in the result of ParselyMetadata.toDict should match the language argument " +
                        "used at initialization")
        XCTAssertEqual(actual["full_content"]! as! String, expected["full_content"]! as! String,
                        "The full_content field in the result of ParselyMetadata.toDict should match the full_content argument " +
                        "used at initialization")
        XCTAssertEqual(actual["full_content_sha512"]! as! String, expected["full_content_sha512"]! as! String,
                        "The full_content_sha512 field in the result of ParselyMetadata.toDict should match the full_content_sha512 argument " +
                        "used at initialization")
        XCTAssertEqual(actual["network_id_str"]! as! String, expected["network_id_str"]! as! String,
                        "The network_id_str field in the result of ParselyMetadata.toDict should match the network_id_str argument " +
                        "used at initialization")
        XCTAssertEqual(actual["network_canonical"]! as! String, expected["network_canonical"]! as! String,
                        "The network_canonical field in the result of ParselyMetadata.toDict should match the network_canonical argument " +
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
