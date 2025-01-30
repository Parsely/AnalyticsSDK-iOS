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
     */
    public init(canonical_url: String? = nil,
                pub_date: Date? = nil,
                title: String? = nil,
                authors: Array<String>? = nil,
                image_url: String? = nil,
                section: String? = nil,
                tags: Array<String>? = nil,
                duration: TimeInterval? = nil) {
        self.canonical_url = canonical_url
        self.pub_date = pub_date
        self.title = title
        self.authors = authors
        self.image_url = image_url
        self.section = section
        self.tags = tags
        self.duration = duration
    }

    func toDict() -> Dictionary<String, Any> {
        var metas: Dictionary<String, Any> = [:]

        if let canonical_url {
            metas["link"] = canonical_url
        }
        if let pub_date {
            metas["pub_date"] = String(format: "%i", pub_date.millisecondsSince1970)
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

        return metas
    }
}
