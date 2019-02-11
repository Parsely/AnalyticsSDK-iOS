//
//  RequestBuilder.swift
//  ParselyTracker
//
//  Created by Ashley Drake on 2/7/19.
//  Copyright © 2019 Parse.ly. All rights reserved.
//

import Foundation
import UIKit
import os.log

struct ParselyRequest {
    var url: String
    var headers: Dictionary<String, Any>
    var params: Dictionary<String, Any>
}

class RequestBuilder {
    
    static var _baseURL: String? = nil
    static var userAgent: String = "parsely-analytics-ios/3.0.0"
    // TODO: should refresh every few hours to avoid sending events
    // to an out-of-date pixel server
    // TODO: implement correct user agent string

    static func getUserAgent() -> String {
        return userAgent
    }
    
    static func buildRequest(events: Array<Event>) -> ParselyRequest? {
        let request = ParselyRequest.init(
            url: buildPixelEndpoint(now: nil),
            headers: buildHeadersDict(events: events),
            params: buildParamsDict(events: events)
        )
        os_log("Built request")
        dump(request)
        return request
    }

    static func buildPixelEndpoint(now: Date?) -> String {
        if self._baseURL == nil || now != nil {
            let now: Date = now ?? Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HH"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            let dateString = dateFormatter.string(from: now)
            self._baseURL = "https://srv-\(dateString).pixel.parsely.com/mobileproxy"
        }
        return self._baseURL!
    }
    
    static func buildHeadersDict(events: Array<Event>) -> Dictionary<String, Any> {
        // return headers as a Dictionary
        let userAgent: String = getUserAgent()
        return ["User-Agent": userAgent]
    }

    static func buildParamsDict(events: Array<Event>) -> Dictionary<String, Any> {
        // return a Dictionary with one key, 'events', to pass to the client
        var eventDicts: Array<Dictionary<String, Any>> = Array<Dictionary<String, Any>>.init()
        for event in events {
            eventDicts.append(event.toDict())
        }
        return ["events": eventDicts]
    }

    static private func getDeviceInfo() -> Dictionary<String, Any> {
        // will be used in getUserAgent()
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
}
