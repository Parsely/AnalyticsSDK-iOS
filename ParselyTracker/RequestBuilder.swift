//
//  RequestBuilder.swift
//  ParselyTracker
//
//  Created by Ashley Drake on 2/7/19.
//  Copyright © 2019 Parse.ly. All rights reserved.
//

import Foundation

struct ParselyRequest {
    var url: String
    var headers: ParselyHeaders
    var params: ParselyParams
}

struct ParselyHeaders {
    var userAgent: String
    var userIP: String
}

struct ParselyParams {
    var key: String
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

    static func getUserIP() -> String {
        return "0.0.0.0" // TODO: FIX
    }
    
    static func buildRequest(events: Array<Event>) -> ParselyRequest? {
        dump(getDeviceInfo())
        return ParselyRequest.init(
            url: buildPixelEndpoint(now: nil),
            headers: buildHeaders(events: events),
            params: buildParams(events: events)
        )
    }

    static func buildPixelEndpoint(now: Date?) -> String {
        if self._baseURL == nil || now != nil {
            let now: Date = now ?? Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HH"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            let dateString = dateFormatter.string(from: now)
            self._baseURL = "https://srv-\(dateString).pixel.parsely.com/mobileproxy/"
        }
        return self._baseURL!
    }
    
    static func buildHeaders(events: Array<Event>) -> ParselyHeaders {
        let userAgent: String = "blarg"
        let userIP: String = "0.0.0.0"
        return ParselyHeaders.init(userAgent: userAgent, userIP: userIP)
    }
    static func buildParams(events: Array<Event>) -> ParselyParams {
        return ParselyParams.init(key: "stuff")
    }

    static private func getDeviceInfo() -> Dictionary<String, Any> {
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
