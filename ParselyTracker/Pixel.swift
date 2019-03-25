import Foundation
import SwiftHTTP
import os.log

class Pixel {
    var sessionManager: SessionManager
    private let parselyTracker: Parsely
    
    public init(trackerInstance: Parsely) {
        parselyTracker = trackerInstance
        sessionManager = SessionManager(trackerInstance: parselyTracker)
    }

    func beacon(event: Event) {
        if event.idsite == "" {
            os_log("apikey not configured. call Parsely.configure before using tracking methods", log: OSLog.tracker,
                   type: .error)
            return
        }
        os_log("Fired beacon: action = %s", log: OSLog.tracker, type: .debug, event.action)
        let session: Dictionary<String, Any?> = sessionManager.get(url: event.url, urlref: event.urlref,
                                                              shouldExtendExisting: true)
        event.setSessionInfo(session: session)
        let visitorInfo = parselyTracker.visitorManager.getVisitorInfo(shouldExtendExisting: true)
        event.setVisitorInfo(visitorInfo: visitorInfo as Dictionary<String, Any>)
        parselyTracker.eventQueue.push(event)
    }
}
