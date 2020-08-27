import Foundation

struct VisitorInfo : Storable {
    var id: String
    var session_count: Int = 0
    var last_session_ts: UInt64 = 0
    var expires: Date?
    
    static func ==(lhs: VisitorInfo, rhs: VisitorInfo) -> Bool {
        return lhs.id == rhs.id && lhs.session_count == rhs.session_count && lhs.last_session_ts == rhs.last_session_ts && lhs.expires == rhs.expires
    }
}

class VisitorManager {
    private let VISITOR_TIMEOUT: TimeInterval = 60 * 60 * 24 * 365  / 12 * 13 // 13 months
    private let storage = Parsely.sharedStorage
    private let visitorKey = "_parsely_visitor_uuid"

    internal func getVisitorInfo(shouldExtendExisting: Bool = false) -> VisitorInfo {
        var visitorInfo: VisitorInfo = self.storage.get(key: self.visitorKey) ?? self.initVisitor(visitorId: UUID().uuidString)

        if (shouldExtendExisting) {
            visitorInfo = extendVisitorExpiry()
        }
        return visitorInfo
    }

    private func initVisitor(visitorId: String) -> VisitorInfo {
        let visitorInfo = VisitorInfo(id: visitorId, session_count: 0, last_session_ts: 0)
        return self.setVisitorInfo(visitorInfo: visitorInfo)
    }
    
    internal func setVisitorInfo(visitorInfo: VisitorInfo) -> VisitorInfo {
        return storage.set(key: visitorKey, value: visitorInfo, expires: Date.init(timeIntervalSinceNow: self.VISITOR_TIMEOUT))
    }
    
    private func extendVisitorExpiry() -> VisitorInfo {
        let result = storage.extendVisitorInfoExpiry(key: visitorKey, expires: Date.init(timeIntervalSinceNow: self.VISITOR_TIMEOUT))
        return result!
    }
}
