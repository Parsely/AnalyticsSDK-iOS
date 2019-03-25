import Foundation

class VisitorManager {
    private let VISITOR_TIMEOUT: TimeInterval = 60 * 60 * 24 * 365  / 12 * 13 // 13 months
    private let storage = Parsely.sharedStorage
    private let visitorKey = "_parsely_visitor_uuid"

    internal func getVisitorInfo(shouldExtendExisting: Bool = false) -> Dictionary<String, Any?> {
        var visitorInfo = self.storage.get(key: self.visitorKey) ?? [:]
        if (visitorInfo.isEmpty) {
            visitorInfo = self.initVisitor(visitorId: UUID().uuidString)
        } else if (shouldExtendExisting) {
            visitorInfo = extendVisitorExpiry()
        }
        return visitorInfo
    }

    private func initVisitor(visitorId: String) -> Dictionary<String, Any?> {
       return self.setVisitorInfo(visitorInfo: [
        "id": visitorId,
        "session_count": 0,
        "last_session_ts": 0
       ])
    }
    
    internal func setVisitorInfo(visitorInfo: Dictionary<String, Any?>) -> Dictionary<String, Any?> {
        return storage.set(key: visitorKey, value: visitorInfo, expires: Date.init(timeIntervalSinceNow: self.VISITOR_TIMEOUT))
    }
    
    private func extendVisitorExpiry() -> Dictionary<String, Any?> {
        return storage.extendExpiry(key: visitorKey, expires: Date.init(timeIntervalSinceNow: self.VISITOR_TIMEOUT)) ?? [:]
    }
}
