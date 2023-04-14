import Foundation
import UIKit
import os.log

public class Parsely {

    public var apikey = ""
    public var secondsBetweenHeartbeats: TimeInterval? {
        get {
            if let secondsBtwnHeartbeats = config["secondsBetweenHeartbeats"] as! TimeInterval? {
                return secondsBtwnHeartbeats
            }
            return nil
        }
    }
    public static let sharedInstance = Parsely()

    var config: [String: Any] = [:]
    var track: Track {
        return _track
    }
    var eventQueue: EventQueue<Event> = EventQueue()
    internal static let sharedStorage = Storage()
    lazy var visitorManager = VisitorManager()
    internal static func getInstance() -> Parsely {
        return Parsely()
    }

    private var _track: Track!
    private var configured = false
    private var flushTimer: Timer?
    private var flushInterval: TimeInterval = 30
    private var backgroundFlushTask: UIBackgroundTaskIdentifier = .invalid
    private var active: Bool = true
    private var eventProcessor: DispatchQueue

    private init() {
        os_log("Initializing ParselyTracker", log: OSLog.tracker, type: .info)
        eventProcessor = DispatchQueue(label: "ly.parse.event-processor")
        _track = Track(trackerInstance: self)
    }

    /**
     Configure the Parsely tracking SDK. Should be called once per application load, before other Parsely SDK functions
     are called
     
     - Parameter siteId: The Parsely site ID for which the pageview event should be counted. Can be overridden
                         on individual tracking method calls.
     - Parameter handleLifecycle: If true, set up listeners to handle tracking across application lifecycle events.
                                  Defaults to true.
     */
    public func configure(siteId: String, handleLifecycle: Bool = true) {
        os_log("Configuring ParselyTracker", log: OSLog.tracker, type: .debug)
        apikey = siteId
        config = ["secondsBetweenHeartbeats": TimeInterval(10)]
        if handleLifecycle {
            addApplicationObservers()
        }
        configured = true
    }

    /**
     Track a pageview event
     
     - Parameter url: The url of the page that was viewed
     - Parameter urlref: The url of the page that linked to the viewed page
     - Parameter metadata: Metadata for the viewed page
     - Parameter extraData: A dictionary of additional information to send with the generated pageview event
     - Parameter siteId: The Parsely site ID for which the pageview event should be counted
     */
    public func trackPageView(
        url: String,
        urlref: String = "",
        metadata: ParselyMetadata? = nil,
        extraData: Dictionary<String, Any>? = nil,
        siteId: String = ""
    ) {
        eventProcessor.async {
            self._trackPageView(url: url, urlref: urlref, metadata: metadata, extraData: extraData, siteId: siteId)
        }
    }

    private func _trackPageView(
        url: String,
        urlref: String,
        metadata: ParselyMetadata?,
        extraData: Dictionary<String, Any>?,
        siteId: String
    ) {
        var _siteId = siteId
        if (_siteId == "") {
            _siteId = self.apikey
        }
        os_log("Tracking PageView", log: OSLog.tracker, type: .debug)
        track.pageview(url: url, urlref: urlref, metadata: metadata, extra_data: extraData, idsite: _siteId)
    }

    /**
     Start tracking engaged time for a given url. Once called, heartbeat events will be sent periodically for this url
     until engaged time tracking is stopped. Stops tracking engaged time for any urls currently being tracked for engaged
     time.
     
     - Parameter url: The url of the page being engaged with
     - Parameter urlref: The url of the page that linked to the page being engaged with
     - Parameter extraData: A dictionary of additional information to send with generated heartbeat events
     - Parameter siteId: The Parsely site ID for which the heartbeat events should be counted
     */
    public func startEngagement(
        url: String,
        urlref: String = "",
        extraData: Dictionary<String, Any>? = nil,
        siteId: String = ""
    ) {
        eventProcessor.async {
            self._startEngagement(url: url, urlref: urlref, extraData: extraData, siteId: siteId)
        }
    }

    private func _startEngagement(
        url: String,
        urlref: String,
        extraData: Dictionary<String, Any>?,
        siteId: String
    ) {
        var _siteId = siteId
        if (_siteId == "") {
            _siteId = self.apikey
        }
        track.startEngagement(url: url, urlref: urlref, extra_data: extraData, idsite: _siteId)
    }

    /**
     Stop tracking engaged time for any currently engaged urls. Once called, one additional heartbeat event may be sent per
     previously-engaged url, after which heartbeat events will stop being sent.
     */
    public func stopEngagement() {
        eventProcessor.async {
            self.track.stopEngagement()
        }
    }

    /**
     Start tracking view time for a given video being viewed at a given url. Sends a videostart event for the given
     url/video combination. Once called, vheartbeat events will be sent periodically for this url/video combination until video
     view tracking is stopped. Stops tracking view time for any url/video combinations currently being tracked for view time.
     
     - Parameter url: The url at which the video is being viewed. Equivalent to the url of the page on which the video is embedded
     - Parameter urlref: The url of the page that linked to the page on which the video is being viewed
     - Parameter videoID: A string uniquely identifying the video within your Parsely account
     - Parameter duration: The duration of the video
     - Parameter metadata: ParselyMetadata for the video being viewed
     - Parameter extraData: A dictionary of additional information to send with generated vheartbeat events
     - Parameter siteId: The Parsely site ID for which the vheartbeat events should be counted
     */
    public func trackPlay(
        url: String,
        urlref: String = "",
        videoID: String,
        duration: TimeInterval,
        metadata: ParselyMetadata? = nil,
        extraData: Dictionary<String, Any>? = nil,
        siteId: String = ""
    ) {
        eventProcessor.async {
            self._trackPlay(url: url, urlref: urlref, videoID: videoID, duration: duration, metadata: metadata, extraData: extraData, siteId: siteId)
        }
    }

    private func _trackPlay(
        url: String,
        urlref: String,
        videoID: String,
        duration: TimeInterval,
        metadata: ParselyMetadata?,
        extraData: Dictionary<String, Any>?,
        siteId: String
    ) {
        var _siteId = siteId
        if (_siteId == "") {
            _siteId = self.apikey
        }
        track.videoStart(url: url, urlref: urlref, vId: videoID, duration: duration, metadata: metadata, extra_data: extraData, idsite: _siteId)
    }

    /**
     Stop tracking video view time for any currently viewing url/video combinations. Once called, one additional vheartbeat
     event may be sent per previously-viewed url/video combination, after which vheartbeat events will stop being sent.
     */
    public func trackPause() {
        eventProcessor.async {
            self.track.videoPause()
        }
    }
    
    /**
     Unset tracking data for the given url/video combination. The next time trackPlay is called for that combination, it will
     behave as if it had never been tracked before during this run of the app.
     
     - Parameter url: The url at which the video wss being viewed. Equivalent to the url of the page on which the video is embedded
     - Parameter videoId: The video ID string for the video being reset
     */
    public func resetVideo(url:String, videoID:String) {
        eventProcessor.async {
            self.track.videoReset(url: url, vId: videoID)
        }
    }
    
    @objc private func flush() {
        if eventQueue.length() == 0 {
            return
        }

        os_log("Flushing event queue", log: OSLog.tracker, type:.debug)
        let events = eventQueue.get()
        os_log("Got %s events", log: OSLog.tracker, type:.debug, String(describing: events.count))
        let request = RequestBuilder.buildRequest(events: events)
        HttpClient.sendRequest(request: request!) { error in
            if let error = error as? URLError, error.code == .notConnectedToInternet {
                // When offline, return the events to the queue for the next flush().
                self.eventQueue.push(contentsOf: events)
                os_log("Network connection unavailable. Returning %s events to the queue.", String(describing: events.count))
            }
        }
    }
    
    internal func startFlushTimer() {
        os_log("Flush timer starting", log: OSLog.tracker, type:.debug)
        if flushTimer == nil && active {
            flushTimer = Timer.scheduledTimer(timeInterval: flushInterval, target: self, selector: #selector(flush), userInfo: nil, repeats: true)
            os_log("Flush timer started", log: OSLog.tracker, type:.debug)
        }
    }
    
    internal func pauseFlushTimer() {
        os_log("Flush timer stopping", log: OSLog.tracker, type:.debug)
        if flushTimer != nil && !active {
            flushTimer?.invalidate()
            flushTimer = nil
            os_log("Flush timer stopped", log: OSLog.tracker, type:.debug)
        }
    }

    private func addApplicationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(resumeExecution(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resumeExecution(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(suspendExecution(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(suspendExecution(_:)), name: UIScene.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(suspendExecution(_:)), name: UIApplication.willTerminateNotification, object: nil)
    }

    @objc private func resumeExecution(_ notification: Notification) {
        if active {
            return
        }
        self.active = true
        os_log("Resuming execution after foreground/active", log:OSLog.tracker, type:.info)
        startFlushTimer()
        track.resume()
    }
    
    @objc private func suspendExecution(_ notification: Notification) {
        if !active {
            return
        }
        self.active = false
        os_log("Stopping execution before background/inactive/terminate", log:OSLog.tracker, type:.info)
        hardShutdown()
        
        DispatchQueue.global(qos: .userInitiated).async{
            let _self = self
            _self.backgroundFlushTask = UIApplication.shared.beginBackgroundTask(expirationHandler:{
                _self.endBackgroundFlushTask()
            })
            os_log("Flushing queue in background", log:OSLog.tracker, type:.info)
            _self.track.sendHeartbeats()
            _self.flush()
            _self.endBackgroundFlushTask()
        }
    }
    
    internal func hardShutdown() {
        pauseFlushTimer()
        track.pause()
    }
    
    private func endBackgroundFlushTask() {
        UIApplication.shared.endBackgroundTask(backgroundFlushTask)
        backgroundFlushTask = UIBackgroundTaskIdentifier.invalid
    }
}

extension OSLog {
    private static var logger = "ParselyTracker"
    static let tracker = OSLog(subsystem: "ParselyTracker", category: "parsely_tracker")
}
