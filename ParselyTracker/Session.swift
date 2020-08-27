import Foundation
import UIKit

struct Session : Storable {
    var session_id: Int
    var session_url: String?
    var session_referrer: String?
    var session_ts: UInt64
    var last_session_ts: UInt64?
    var expires: Date?
    
    static func ==(lhs: Session, rhs: Session) -> Bool {
        return lhs.session_id == rhs.session_id && lhs.session_url == rhs.session_url && lhs.session_referrer == rhs.session_referrer && lhs.session_ts == rhs.session_ts && lhs.last_session_ts == rhs.last_session_ts && lhs.expires == rhs.expires
    }
}

class SessionManager {
    private let SESSION_TIMEOUT: TimeInterval = 30 * 60.0
    private let storage = Parsely.sharedStorage
    private let sessionKey = "_parsely_session_identifier"
    private let visitorManager: VisitorManager
    private let parselyTracker: Parsely
    // knows how to start, stop, store, and restore a session
    // - sid — session ID == session_count
    // - surl  — initial URL (postID?) of the session
    // - sref — initial referrer of the session
    // - sts — Unix timestamp (millis) of when the session was created
    // - slts — Unix timestamp (millis) of the last session the user had, 0 if this is the user’s first session
    init(trackerInstance: Parsely) {
        parselyTracker = trackerInstance
        visitorManager = parselyTracker.visitorManager
    }

    internal func get(url: String, urlref: String, shouldExtendExisting: Bool = false) -> Session {
        if var session: Session = self.storage.get(key: self.sessionKey) {
            if shouldExtendExisting {
                session = extendExpiry()
            }
            return session
        } else {
            var visitorInfo = visitorManager.getVisitorInfo()
            visitorInfo.session_count = visitorInfo.session_count + 1
            var session = Session(session_id: visitorInfo.session_count, session_url: url, session_referrer: urlref, session_ts: Date().millisecondsSince1970, last_session_ts: visitorInfo.last_session_ts)
            visitorInfo.last_session_ts = session.session_ts
            let _ = visitorManager.setVisitorInfo(visitorInfo: visitorInfo)
            session = storage.set(key: sessionKey, value: session, expires: Date.init(timeIntervalSinceNow: SESSION_TIMEOUT))
            return session
        }

    }
    
    internal func extendExpiry() -> Session {
        let expiry = Date.init(timeIntervalSinceNow: self.SESSION_TIMEOUT)
        let result = storage.extendSessionExpiry(key: self.sessionKey, expires: expiry) ?? Session(session_id: 0, session_url: nil, session_referrer: nil, session_ts: 0, last_session_ts: nil, expires: nil)
        return result 
    }
}
