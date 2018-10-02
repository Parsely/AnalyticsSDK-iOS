//
// Created by Chris Wisecarver on 7/31/18.
// Copyright (c) 2018 Parse.ly. All rights reserved.
//

import Foundation

extension Date {
    var millisecondsSince1970:Int {
        return Int((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

class Storage {
    let defaults = UserDefaults.standard
    let expiryDateKey = "expires"

    func get(key: String) -> Dictionary<String, Any>? {
        if var data = self.defaults.dictionary(forKey: key) {
            if let expiryDate = data[self.expiryDateKey] as? Date {
                let savedExpiryDate = expiryDate
                let now = Date()
                if savedExpiryDate <= now {
                    self.defaults.removeObject(forKey: key)
                    return nil
                }
                data.removeValue(forKey: self.expiryDateKey)
            }
            return data
        }
        return nil
    }

    func set(key: String, value: Dictionary<String, Any>, expires: Date?) {
        var data = value
        if expires != nil {
           data[self.expiryDateKey] = expires
        }
        self.defaults.set(data, forKey: key)
    }

    func extendExpiry(key: String, expires: Date) {
        if let data = self.get(key: key) {
            self.set(key: key, value: data, expires: expires)
        }
    }

    func expire(key: String) {
        self.defaults.removeObject(forKey: key)
    }
}
