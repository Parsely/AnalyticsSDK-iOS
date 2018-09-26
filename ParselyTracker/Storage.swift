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
        if let data = self.defaults.dictionary(forKey: key) {
            if let expiryDate = data[self.expiryDateKey] as? Int {
                let savedExpiryDate = Date(milliseconds: expiryDate).timeIntervalSince1970
                if savedExpiryDate >= Date().timeIntervalSince1970 {
                    return nil
                }
            }
            return data
        }
        return nil
    }

    func set(key: String, value: Dictionary<String, Any>, options: Dictionary<String, Any>) {
        var data = value
        if let expiryDate = options[self.expiryDateKey] {
           data[self.expiryDateKey] = expiryDate
        }
        self.defaults.set(data, forKey: key)
    }

    func extendExpiry(key: String, expires: Double) {
        if let data = self.get(key: key) {
            self.set(key: key, value: data, options: [self.expiryDateKey: expires])
        }
    }

    func expire(key: String) {
        self.defaults.removeObject(forKey: key)
    }
}
