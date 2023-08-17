import Foundation
import UIKit
import os.log

struct ParselyRequest {
    var url: String
    var headers: Dictionary<String, String>
    var params: Dictionary<String, Any>
}

class RequestBuilder {
    
    static var _baseURL: String? = nil
    static var userAgent: String? = nil
    
    internal static func getHardwareString() -> String {
        var mib  = [CTL_HW, HW_MACHINE]
        var len: size_t = 0
        sysctl(&mib, 2, nil, &len, nil, 0)
        let machine = UnsafeMutablePointer<Int8>.allocate(capacity:len)
        sysctl(&mib, 2, machine, &len, nil, 0)
        let platform: String = String(cString:machine, encoding:String.Encoding.ascii) ?? ""
        machine.deallocate()
        return platform
    }

    static func getUserAgent() -> String {
        guard let userAgent else {
            var appDescriptor: String = ""
            if let appName = Bundle.main.infoDictionary?["CFBundleName"] as? String,
               let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                appDescriptor = String(format: "%@/%@", appName, appVersion)
            }
            let osDescriptor = String(format: "iOS/%@", UIDevice.current.systemVersion)
            let hardwareString = getHardwareString()
            let userAgentString = String(format: "%@ %@ (%@)", appDescriptor, osDescriptor, hardwareString)
            // encode the user agent into latin1 in case there are utf8 characters
            let userAgentData = Data(userAgentString.utf8)

            return String(data: userAgentData, encoding: .isoLatin1) ?? "invalid user agent"
        }

        return userAgent
    }
    
    static func buildRequest(events: Array<Event>) -> ParselyRequest {
        let request = ParselyRequest.init(
            url: buildPixelEndpoint(),
            headers: buildHeadersDict(events: events),
            params: buildParamsDict(events: events)
        )
        os_log("Built request", log: OSLog.tracker, type:.debug)
        return request
    }

    internal static func buildPixelEndpoint() -> String {
        self._baseURL = "https://p1.parsely.com/mobileproxy"
        return self._baseURL!
    }
    
    internal static func buildHeadersDict(events: Array<Event>) -> Dictionary<String, String> {
        let userAgent: String = getUserAgent()
        return ["User-Agent": userAgent]
    }

    internal static func buildParamsDict(events: Array<Event>) -> Dictionary<String, Any> {
        var eventDicts: Array<Dictionary<String, Any>> = Array<Dictionary<String, Any>>.init()
        for event in events {
            eventDicts.append(event.toDict())
        }
        return ["events": eventDicts]
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
