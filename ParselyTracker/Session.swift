import Foundation
import UIKit

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

    internal func get(url: String, urlref: String, shouldExtendExisting: Bool = false) -> Dictionary<String, Any?> {
        var session = self.storage.get(key: self.sessionKey) ?? [:]

        if session.isEmpty {
            var visitorInfo = visitorManager.getVisitorInfo()
            visitorInfo["session_count"] = visitorInfo["session_count"] as! Int + 1
            
            session = [:]
            session["session_id"] = visitorInfo["session_count"]
            session["session_url"] = url
            session["session_referrer"] = urlref
            session["session_ts"] = Date().millisecondsSince1970
            session["last_session_ts"] = visitorInfo["last_session_ts"]
            
            visitorInfo["last_session_ts"] = session["session_ts"]
            let _ = visitorManager.setVisitorInfo(visitorInfo: visitorInfo)
            session = storage.set(key: sessionKey, value: session as Dictionary<String, Any>, expires: Date.init(timeIntervalSinceNow: SESSION_TIMEOUT))
        } else if shouldExtendExisting {
            session = extendExpiry()
        }
        return session
    }
    
    internal func extendExpiry() -> Dictionary<String, Any> {
        let expiry = Date.init(timeIntervalSinceNow: self.SESSION_TIMEOUT)
        let result = storage.extendExpiry(key: self.sessionKey, expires: expiry) ?? [:]
        return result as Dictionary<String, Any>
    }
}
