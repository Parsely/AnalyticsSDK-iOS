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
    let visitorKey = "parsely_uuid"
    
    init () {
        self.storage = Storage()
    }
    
    func getVisitorInfo(shouldExtendExisting: Bool = false) -> Dictionary<String, Any?> {
        var visitorInfo = self.storage.get(key: self.visitorKey) ?? [:]
        if (visitorInfo.isEmpty) {
            visitorInfo = self.initVisitor(visitorId: UUID().uuidString)
        } else if (shouldExtendExisting) {
            self.extendVisitorExpiry()
        }
        return visitorInfo
    }
    
    func initVisitor(visitorId: String) -> Dictionary<String, Any?> {
       return self.setVisitorInfo(visitorInfo: [
        "id": visitorId,
        "session_count": 0,
        "last_session_ts": 0
       ])
    }
    
    func setVisitorInfo(visitorInfo: Dictionary<String, Any?>) -> Dictionary<String, Any?> {
        self.storage.set(key: visitorKey, value: visitorInfo, expires: Date.init(timeIntervalSinceNow: self.VISITOR_TIMEOUT))
        return visitorInfo
    }
    
    func extendVisitorExpiry() {
        self.storage.extendExpiry(key: visitorKey, expires: Date.init(timeIntervalSinceNow: self.VISITOR_TIMEOUT))
    }
}
