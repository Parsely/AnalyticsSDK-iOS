//
//  Tracker.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 5/17/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import Foundation

public class Parsely {
    let apikey: String
    var config: [String: Any]
    var default_config = [String: Any]()
    var beacon: Beacon
    
    
    public init(apikey: String, options: [String: Any]) {
        self.apikey = apikey
        self.default_config = [
            "interval": 10,
            "track_ip_addresses": true
        ]
        self.config = self.default_config.merging(
                options, uniquingKeysWith: { (_old, new) in new }
        )
        self.beacon = Beacon()
    }
    
    public func trackPageView() {
        print("Hello World!")
    }
}
