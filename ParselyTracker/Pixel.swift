//
//  pixel.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation
import SwiftHTTP
import os.log

class Pixel {
    var _baseURL: String?
    
    init() {
        self._baseURL = nil
    }
    
    func buildPixelURL(now: Date) -> String {
        if self._baseURL == nil {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd-HH"
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            let dateString = dateFormatter.string(from: now)
            self._baseURL = "https://srv-\(dateString).pixel.parsely.com/mobileproxy/"
        }
        return self._baseURL!
    }
    
    func beacon(data: Event) {
        os_log("Fired beacon", log: OSLog.default, type: .debug)
    }
}
