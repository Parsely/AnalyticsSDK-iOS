import Foundation

class Event {
    var action: String
    var url: String
    var urlref: String
    var data: Dictionary<String, Any>!
    var metadata: ParselyMetadata?
    var idsite: String
    var extra_data: Dictionary<String, Any>?
    var session_id: Int?
    var session_timestamp: UInt64?
    var session_url: String?
    var session_referrer: String?
    var last_session_timestamp: UInt64?
    var parsely_site_uuid: String?
    var rand: UInt64!
    
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
        self.extra_data = extra_data
        self.session_id = session_id
        self.session_timestamp = session_timestamp
        self.session_url = session_url
        self.session_referrer = session_referrer
        self.last_session_timestamp = last_session_timestamp
        self.rand = Date().millisecondsSince1970

    }

    func setSessionInfo(session: Session) {
        self.session_id = session.session_id
        self.session_timestamp = session.session_ts
        self.session_url = session.session_url ?? ""
        self.session_referrer = session.session_referrer ?? ""
        self.last_session_timestamp = session.last_session_ts ?? 0
    }

    func setVisitorInfo(visitorId: String) {
        self.parsely_site_uuid = visitorId
    }

    func toDict() -> Dictionary<String,Any> {
        var params: Dictionary<String, Any> = [
            "url": self.url,
            "urlref": self.urlref,
            "action": self.action,
            "idsite": self.idsite,
        ]
        
        data = extra_data ?? [:]
        data["ts"] = self.rand
        
        if parsely_site_uuid != nil {
            data["parsely_site_uuid"] = parsely_site_uuid!
        }
        
        params["data"] = data

        
        if let metas = self.metadata {
            let metasDict = metas.toDict()
            if !metasDict.isEmpty {
                params["metadata"] = metasDict
            }
        }
        
        if self.session_id != nil {
            params["sid"] = self.session_id
            params["sts"] = self.session_timestamp
            params["surl"] = self.session_url
            params["sref"] = self.session_referrer
            params["slts"] = self.last_session_timestamp
        }

        return params
    }

    func toJSON() -> String {
        return ""
    }

}

class Heartbeat: Event {
    var tt: Int
    var inc: Int

    init(_ action: String, url: String, urlref: String?, inc: Int, tt: Int, metadata: ParselyMetadata?, extra_data: Dictionary<String, Any>?, idsite: String = "") {
        self.tt = tt
        self.inc = inc
        super.init(action, url: url, urlref: urlref, metadata: metadata, extra_data: extra_data, idsite: idsite)
    }

    override func toDict() -> Dictionary<String, Any> {
        var base = super.toDict()
        base["tt"] = self.tt
        base["inc"] = self.inc
        return base
    }
}
