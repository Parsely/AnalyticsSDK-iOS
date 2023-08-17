import Foundation

class Event {
    let action: String
    let url: String
    let urlref: String
    let metadata: ParselyMetadata?
    let idsite: String
    let extra_data: Dictionary<String, Any>
    private(set) var session_id: Int?
    private(set) var session_timestamp: UInt64?
    private(set) var session_url: String?
    private(set) var session_referrer: String?
    private(set) var last_session_timestamp: UInt64?
    private(set) var parsely_site_uuid: String?
    let rand: UInt64
    
    init(_ action: String,
         url: String,
         urlref: String?,
         metadata: ParselyMetadata?,
         extra_data: Dictionary<String, Any>?,
         idsite: String = "",
         session_id: Int? = nil,
         session_timestamp: UInt64? = nil,
         session_url: String? = nil,
         session_referrer: String? = nil,
         last_session_timestamp: UInt64? = nil
    ) {
        self.action = action
        self.url = url
        self.urlref = urlref ?? ""
        self.idsite = idsite
        self.metadata = metadata
        self.extra_data = extra_data ?? [:]
        self.session_id = session_id
        self.session_timestamp = session_timestamp
        self.session_url = session_url
        self.session_referrer = session_referrer
        self.last_session_timestamp = last_session_timestamp
        // Note that, while this value will likely always be different at runtime, is not truly random.
        self.rand = Date().millisecondsSince1970
    }

    func setSessionInfo(session: Dictionary<String, Any?>) {
        self.session_id = session["session_id"] as? Int ?? 0
        self.session_timestamp = session["session_ts"] as? UInt64 ?? 0
        self.session_url = session["session_url"] as? String ?? ""
        self.session_referrer = session["session_referrer"] as? String ?? ""
        self.last_session_timestamp = session["last_session_ts"] as? UInt64 ?? 0
    }

    func setVisitorInfo(visitorInfo: Dictionary<String, Any>?) {
        guard let visitor = visitorInfo?["id"] as? String else {
            return
        }

        parsely_site_uuid = visitor
    }

    func toDict() -> Dictionary<String,Any> {
        var params: Dictionary<String, Any> = [
            "url": self.url,
            "urlref": self.urlref,
            "action": self.action,
            "idsite": self.idsite,
        ]
        
        var data: [String: Any] = extra_data
        data["ts"] = self.rand
        
        if let parsely_site_uuid {
            data["parsely_site_uuid"] = parsely_site_uuid
        }
        
        params["data"] = data

        if let metas = self.metadata {
            let metasDict = metas.toDict()
            if !metasDict.isEmpty {
                params["metadata"] = metasDict
            }
        }

        guard let session_id else {
            return params
        }

        params["sid"] = session_id
        params["sts"] = session_timestamp
        params["surl"] = session_url
        params["sref"] = session_referrer
        params["slts"] = last_session_timestamp

        return params
    }

    func toJSON() -> String {
        return ""
    }

}

class Heartbeat: Event {
    var tt: Int
    var inc: Int

    init(
        _ action: String,
        url: String,
        urlref: String?,
        inc: Int,
        tt: Int,
        metadata: ParselyMetadata?,
        extra_data: Dictionary<String, Any>?,
        idsite: String?
    ) {
        self.tt = tt
        self.inc = inc

        super.init(
            action,
            url: url,
            urlref: urlref,
            metadata: metadata,
            extra_data: extra_data,
            // empty string seems a weird default, but is what we had in the code before this comment was written
            idsite: idsite ?? ""
        )
    }

    override func toDict() -> Dictionary<String, Any> {
        var base = super.toDict()
        base["tt"] = self.tt
        base["inc"] = self.inc
        return base
    }
}
