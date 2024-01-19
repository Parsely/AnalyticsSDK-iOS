import Foundation

public class ParselyMetadata {
    var canonical_url: String?
    var pub_date: Date?
    var title: String?
    var authors: Array<String>?
    var image_url: String?
    var section: String?
    var tags: Array<String>?
    var duration: TimeInterval?
    var page_type: String?
    
    /**
     A class to manage and re-use metadata. Metadata contained in an instance of this
     class will conform to Parsely's schema.
     
     - Parameter canonical_url: A post's canonical url. For videos, it is overridden with the vId and thus can be omitted.
     - Parameter pub_date: Date this piece of content was published.
     - Parameter title: Title of the content.
     - Parameter authors: Up to 10 authors are accepted.
     - Parameter image_url: Where the main image for this post is hosted.
     - Parameter section: Same as section for website integration.
     - Parameter tags: Up to 20 tags on an event are allowed.
     - Parameter duration: Durations passed explicitly to trackVideoStart take precedence over any in metadata.
     - Parameter page_type: The type of page being tracked
    */
    public init(canonical_url: String? = nil,
         pub_date: Date? = nil,
         save_date: Date? = nil,
         title: String? = nil,
         authors: Array<String>? = nil,
         image_url: String? = nil,
         section: String? = nil,
         tags: Array<String>? = nil,
         duration: TimeInterval? = nil,
         page_type: String? = nil
         urls: String? = nil,
         post_id: String? = nil,
         pub_date_tmsp: Date? = nil,
         custom_metadata: String? = nil,
         save_date_tmsp: Date? = nil,
         thumb_url: String? = nil,
         full_content_word_count: Int? = nil,
         share_urls: Array<String>? = nil,
         data_source: String? = nil,
         canonical_hash: String? = nil,
         canonical_hash64: String? = nil,
         video_platform: String? = nil,
         language: String? = nil,
         full_content: String? = nil,
         full_content_sha512: String? = nil,
         network_id_str: String? = nil,
         network_canonical: String? = nil,
         content_enrichments: Dictionary<String, Any>? = nil) {
        self.canonical_url = canonical_url
        self.pub_date = pub_date
        self.save_date = save_date
        self.title = title
        self.authors = authors
        self.image_url = image_url
        self.section = section
        self.tags = tags
        self.duration = duration
        self.page_type = page_type
        self.urls = urls
        self.post_id = post_id
        self.pub_date_tmsp = pub_date_tmsp
        self.custom_metadata = custom_metadata
        self.save_date_tmsp = save_date_tmsp
        self.thumb_url = thumb_url
        self.full_content_word_count = full_content_word_count
        self.share_urls = share_urls
        self.data_source = data_source
        self.canonical_hash = canonical_hash
        self.canonical_hash64 = canonical_hash64
        self.video_platform = video_platform
        self.language = language
        self.full_content = full_content
        self.full_content_sha512 = full_content_sha512
        self.network_id_str = network_id_str
        self.network_canonical = network_canonical
        self.content_enrichments = content_enrichments
    }
    
    func toDict() -> Dictionary<String, Any> {
        var metas: Dictionary<String, Any> = [:]
        
        if let canonical_url {
            metas["link"] = canonical_url
        }
        if let pub_date {
            metas["pub_date"] = String(format:"%i", pub_date.millisecondsSince1970)
        }
        if let save_date {
            metas["save_date"] = String(format:"%i", save_date.millisecondsSince1970)
        }        
        if let title {
            metas["title"] = title
        }
        if let authors {
            metas["authors"] = authors
        }
        if let image_url {
            metas["image_url"] = image_url
        }
        if let section {
            metas["section"] = section
        }
        if let tags {
            metas["tags"] = tags
        }
        if let duration {
            metas["duration"] = duration
        }
        if let page_type {
            metas["page_type"] = page_type
        }
        if let urls {
            metas["urls"] = urls
        }
        if let post_id {
            metas["post_id"] = post_id
        }
        if let pub_date_tmsp {
            metas["pub_date_tmsp"] = String(format:"%i", pub_date_tmsp.millisecondsSince1970)
        }
        if let custom_metadata {
            metas["custom_metadata"] = custom_metadata
        }
        if let save_date_tmsp {
            metas["save_date_tmsp"] = String(format:"%i", save_date_tmsp.millisecondsSince1970)
        }
        if let thumb_url {
            metas["thumb_url"] = thumb_url
        }
        if let full_content_word_count {
            metas["full_content_word_count"] = full_content_word_count
        }
        if let share_urls {
            metas["share_urls"] = share_urls
        }
        if let data_source {
            metas["data_source"] = data_source
        }
        if let canonical_hash {
            metas["canonical_hash"] = canonical_hash
        }
        if let canonical_hash64 {
            metas["canonical_hash64"] = canonical_hash64
        }
        if let video_platform {
            metas["video_platform"] = video_platform
        }
        if let language {
            metas["language"] = language
        }
        if let full_content {
            metas["full_content"] = full_content
        }
        if let full_content_sha512 {
            metas["full_content_sha512"] = full_content_sha512
        }
        if let network_id_str {
            metas["network_id_str"] = network_id_str
        }
        if let network_canonical {
            metas["network_canonical"] = network_canonical
        }
        if let content_enrichments {
            metas["content_enrichments"] = content_enrichments
        }
        return metas
    }
}
