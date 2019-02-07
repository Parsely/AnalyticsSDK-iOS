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
    var headers: Dictionary<String, Any?>
    var params: Dictionary<String, Any?>
}


class RequestBuilder {
    
    static var _baseURL: String? = nil
    // TODO: should refresh every few hours to avoid sending events
    // to an out-of-date pixel server
    
    static func buildRequest(events: Array<Event>) -> ParselyRequest? {
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
    
    static func buildHeaders(events: Array<Event>) -> Dictionary<String, Any?> {
        return [:]
    }
    static func buildParams(events: Array<Event>) -> Dictionary<String, Any?> {
        return [:]
    }
}
