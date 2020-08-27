import Foundation

extension Date {
    var millisecondsSince1970:UInt64 {
        return UInt64(floor(self.timeIntervalSince1970 * 1000))
    }
    
    init(milliseconds:UInt64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

protocol Storable: Codable, Equatable {
    var expires: Date? { get set }
}

class Storage {
    let defaults = UserDefaults.standard
    let expiryDateKey = "expires"
    
    func get<T: Storable>(key: String) -> T? {
        if let data = self.defaults.object(forKey: key) as? Data {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(T.self, from: data) {
                if let expiryDate = decoded.expires {
                    let savedExpiryDate = expiryDate
                    let now = Date()
                    if savedExpiryDate <= now {
                        self.defaults.removeObject(forKey: key)
                        return nil
                    }
                }
                return decoded
            }
        }
        return nil
    }

    func set(key: String, value: Session, expires: Date?) -> Session {
        let encoder = JSONEncoder()
        var session = value
        if expires != nil {
            session.expires = expires
        }
        if let encoded = try? encoder.encode(session) {
            self.defaults.set(encoded, forKey: key)
        }
        return session
    }
    
    func set(key: String, value: VisitorInfo, expires: Date?) -> VisitorInfo {
        let encoder = JSONEncoder()
        var visitorInfo = value
        if expires != nil {
            visitorInfo.expires = expires
        }
        if let encoded = try? encoder.encode(visitorInfo) {
            self.defaults.set(encoded, forKey: key)
        }
        return visitorInfo
    }
    
    func extendSessionExpiry(key: String, expires: Date) -> Session? {
        if let data: Session = self.get(key: key) {
            return self.set(key: key, value: data, expires: expires)
        } else {
            return nil
        }
    }
    
    func extendVisitorInfoExpiry(key: String, expires: Date) -> VisitorInfo? {
        if let data: VisitorInfo = self.get(key: key) {
            return self.set(key: key, value: data, expires: expires)
        } else {
            return nil
        }
    }

    func expire(key: String) {
        self.defaults.removeObject(forKey: key)
    }
}
