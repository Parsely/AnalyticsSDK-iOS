//
//  session.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation
import UIKit

class Session {

    private var session: Dictionary<String, Any?> = [:]
    private let SESSION_TIMEOUT: TimeInterval = 30 * 60.0 // 30 minutes
    // knows how to start, stop, store, and restore a session
    // struct should represent datatype
    // - sid — session ID == session_count
    // - surl  — initial URL (postID?) of the session
    // - sref — initial referrer of the session
    // - sts — Unix timestamp (milis) of when the session was created
    // - slts — Unix timestamp (milis) of the last session the user had, 0 if this is the user’s first session
    init() {
        
    }
    
    private func getDeviceInfo() -> Dictionary<String, Any> {
        var deviceInfo: [String: Any] = [:]
        let mainBundle = Bundle.main
        if let bundleName = mainBundle.object(forInfoDictionaryKey: "CFBundleDisplayName") {
            deviceInfo["appname"] = bundleName
        } else if let bundleName = mainBundle.object(forInfoDictionaryKey: "CFBundleName") {
            deviceInfo["appname"] = bundleName
        } else {
            deviceInfo["appname"] = ""
        }

        deviceInfo["manufacturer"] = "Apple"

        let currentDevice = UIDevice.current

        deviceInfo["os"] = currentDevice.systemName
        deviceInfo["os_version"] = currentDevice.systemVersion
        deviceInfo["model"] = currentDevice.model

        return deviceInfo
    }

    private func get(extendSession: Bool = false) -> Dictionary<String, Any?> {

        if !self.session.isEmpty {
           return self.session
        }
        // check local storage for a session
        let session = UserDefaults.standard.dictionary(forKey: "_parsely_session") ?? [:]
        self.session = session

        if self.session.isEmpty {
            var session: Dictionary<String, Any?> = [:]
            session["id"] = UUID().uuidString.lowercased()
            session["session_count"] = 0
            session["last_session_ts"] = 0
            UserDefaults.standard.set(session, forKey: "_parsely_session")
            self.session = session
        }
        return self.session
    }
}
