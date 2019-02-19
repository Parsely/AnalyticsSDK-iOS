//
//  visitor.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation

class VisitorManager {
    // represents a visitor
    private let VISITOR_TIMEOUT: TimeInterval = 60 * 60 * 24 * 365  / 12 * 13 // 13 months
    let storage: Storage
    // make this longer and random-er
    let visitorKey = "parsely_uuid"
    
    init () {
        self.storage = Storage()
    }
    
    func getVisitorInfo(shouldExtendExisting: Bool = false) -> Dictionary<String, Any?> {
        var visitorInfo = self.storage.get(key: self.visitorKey) ?? [:]
        if (visitorInfo.isEmpty) {
            visitorInfo = self.initVisitor(visitorId: UUID().uuidString)
        } else if (shouldExtendExisting) {
            visitorInfo = extendVisitorExpiry()
        }
        return visitorInfo
    }
    // use a visitor struct; avoids need for <String, Any?> type checking
    func initVisitor(visitorId: String) -> Dictionary<String, Any?> {
       return self.setVisitorInfo(visitorInfo: [
        "id": visitorId,
        "session_count": 0,
        "last_session_ts": 0
       ])
    }
    
    func setVisitorInfo(visitorInfo: Dictionary<String, Any?>) -> Dictionary<String, Any?> {
        return storage.set(key: visitorKey, value: visitorInfo, expires: Date.init(timeIntervalSinceNow: self.VISITOR_TIMEOUT))
    }
    
    func extendVisitorExpiry() -> Dictionary<String, Any?> {
        return storage.extendExpiry(key: visitorKey, expires: Date.init(timeIntervalSinceNow: self.VISITOR_TIMEOUT)) ?? [:]
    }
}
