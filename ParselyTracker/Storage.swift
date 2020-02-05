import Foundation

extension Date {
    var millisecondsSince1970:UInt64 {
        return UInt64(floor(self.timeIntervalSince1970 * 1000))
    }
    
    init(milliseconds:UInt64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

class Storage {
    let defaults = UserDefaults.standard
    let expiryDateKey = "expires"

    func get(key: String) -> Dictionary<String, Any?>? {
        if var data = self.defaults.dictionary(forKey: key) {
            if let expiryDate = data[self.expiryDateKey] as? Date {
                let savedExpiryDate = expiryDate
                let now = Date()
                if savedExpiryDate <= now {
                    self.defaults.removeObject(forKey: key)
                    return nil
                }
            }
            return data
        }
        return nil
    }

    func set(key: String, value: Dictionary<String, Any?>, expires: Date?) -> Dictionary<String, Any?> {
        var data = value
        if expires != nil {
           data[self.expiryDateKey] = expires
        }
        self.defaults.set(data, forKey: key)
        return data
    }

    func extendExpiry(key: String, expires: Date) -> Dictionary<String, Any?>? {
        if let data = self.get(key: key) {
            return set(key: key, value: data, expires: expires)
        } else {
            return nil
        }
    }

    func expire(key: String) {
        self.defaults.removeObject(forKey: key)
    }
}
