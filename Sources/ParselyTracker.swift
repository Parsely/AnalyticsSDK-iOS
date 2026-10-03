import Foundation
import Combine
import UIKit
import os.log

/**
 The category of a conversion event. The raw value of each case is the string sent to Parse.ly
 over the wire and must match the values accepted by the Parse.ly conversions backend.
 Use `.custom` for conversions that don't fit one of the named categories.
 
 @See: https://docs.parse.ly/api/api-endpoints/api-conversions-endpoint/
 */
public enum ConversionType: String {
    case newsletterSignup = "newsletter_signup"
    case leadCapture      = "lead_capture"
    case linkClick        = "link_click"
    case subscription     = "subscription"
    case purchase         = "purchase"
    case custom           = "custom"
}

public class Parsely {

    public var apikey = ""
    public var secondsBetweenHeartbeats: TimeInterval? {
        get {
            config["secondsBetweenHeartbeats"] as? TimeInterval
        }
    }
    public static let sharedInstance = Parsely()

    var config: [String: Any] = [:]
    var track: Track {
        return _track
    }
    var eventQueue: EventQueue<Event> = EventQueue()
    /// Events move here from `eventQueue` on each flush and leave once the server accepts or rejects them.
    var queueStore = QueueStore()
    // All tracker related state should be modified in this serial queue, to ensure thread-safty.
    // This property is declared as internal rather than private, because we need to use it to make sure
    // unit tests that inspect tracker's internal state can pass reliably.
    var eventProcessor: DispatchQueue
    internal static let sharedStorage = Storage()
    lazy var visitorManager = VisitorManager()
    internal static func getInstance() -> Parsely {
        return Parsely()
    }

    private var _track: Track!
    private var configured = false
    private var flushTimer: Cancellable?
    internal var flushInterval: TimeInterval = 30
    /// Scales each flush delay, so devices that start together (after a push, say) drift apart.
    internal var flushJitter: () -> Double = { Double.random(in: 0.8...1.2) }
    private static let maxFlushBackoff: TimeInterval = 900
    private var active: Bool = true
    private var sending = false
    private var consecutiveRetries = 0
    /// Events per batch: halved after a 413, back to the full size after a 2xx.
    private var batchLimit = RequestBuilder.maxBatchEvents

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
        eventProcessor.async {
            // Sends events left over from an earlier launch.
            if self.queueStore.count > 0 {
                self.startFlushTimer()
            }
        }
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
        if _siteId == "" {
            _siteId = self.apikey
        }
        os_log("Tracking PageView", log: OSLog.tracker, type: .debug)
        track.pageview(url: url, urlref: urlref, metadata: metadata, extra_data: extraData, idsite: _siteId)
    }

    /**
     Track a conversion event (e.g. newsletter signup, subscription, purchase).

     - Parameter url: The url at which the conversion occurred
     - Parameter conversionType: One of the supported conversion categories. Use `.custom` for
     conversions that don't fit the named categories.
     - Parameter conversionLabel: A customer-defined identifier for this conversion
     (e.g. "weekly_plan", "homepage_cta"). Required and must be non-empty — the Parse.ly
     conversions backend drops events without a label, so calls with an empty label are
     skipped before they are enqueued and an error is logged.
     - Parameter urlref: The url of the page that linked to the conversion page
     - Parameter metadata: Metadata for the page on which the conversion occurred
     - Parameter extraData: A dictionary of additional information to send with the event.
     Reserved keys `_conversion_type` and `_conversion_label` will be overwritten.
     - Parameter siteId: The Parsely site ID for which the conversion event should be counted
     */
    public func trackConversion(
        url: String,
        conversionType: ConversionType,
        conversionLabel: String,
        urlref: String = "",
        metadata: ParselyMetadata? = nil,
        extraData: Dictionary<String, Any>? = nil,
        siteId: String = ""
    ) {
        eventProcessor.async {
            self._trackConversion(
                url: url,
                conversionType: conversionType,
                conversionLabel: conversionLabel,
                urlref: urlref,
                metadata: metadata,
                extraData: extraData,
                siteId: siteId
            )
        }
    }

    private func _trackConversion(
        url: String,
        conversionType: ConversionType,
        conversionLabel: String,
        urlref: String,
        metadata: ParselyMetadata?,
        extraData: Dictionary<String, Any>?,
        siteId: String
    ) {
        guard !conversionLabel.isEmpty else {
            os_log("conversionLabel cannot be empty. Parse.ly's conversions backend drops events without a label, so this call is being skipped.",
                   log: OSLog.tracker, type: .error)
            return
        }
        var _siteId = siteId
        if _siteId == "" {
            _siteId = self.apikey
        }
        os_log("Tracking Conversion", log: OSLog.tracker, type: .debug)
        track.conversion(
            url: url,
            urlref: urlref,
            conversionType: conversionType.rawValue,
            conversionLabel: conversionLabel,
            metadata: metadata,
            extra_data: extraData,
            idsite: _siteId
        )
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
        if _siteId == "" {
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
        if _siteId == "" {
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
    public func resetVideo(url: String, videoID: String) {
        eventProcessor.async {
            self.track.videoReset(url: url, vId: videoID)
        }
    }

    /// After given `seconds`, invoke the given target-action in the event processor queue.
    func scheduleEventProcessing(inSeconds seconds: Double, target: AnyObject, selector: Selector) -> Cancellable {
        Just(0)
            // From the Apple documentation it's not clear what the default tolerance is.
            // They have an example with a .seconds(3) delay saying "3 seconds (±0.5 seconds)".
            // To say on the safe side, we specify a 1ms tolerance, meaning "the Delay publisher may
            // deliver elements this much sooner or later than the interval specifies."
            .delay(for: .seconds(seconds), tolerance: .milliseconds(1), scheduler: eventProcessor)
            .sink { _ in
                _ = target.perform(selector)
            }
    }

    /// Moves tracked events into the durable queue.
    private func storeQueuedEvents() {
        if eventQueue.length() > 0 {
            queueStore.append(eventQueue.get().compactMap(QueueStore.serialize))
        }
    }

    /// Sends the oldest stored batch, unless a send is already in flight.
    @objc private func flush() {
        storeQueuedEvents()
        guard !sending else {
            return
        }
        queueStore.dropEvents(olderThan: Date().addingTimeInterval(-QueueStore.maxEventAge))
        let batch = queueStore.oldest(limit: batchLimit, maxBytes: RequestBuilder.maxBatchBytes)
        if batch.isEmpty {
            return
        }

        sending = true
        var cancel: () -> Void = {}
        // If iOS runs out of background time, cancel the send. The batch stays stored for a retry.
        let task = BackgroundTask.begin { cancel() }
        os_log("Flushing %s events", log: OSLog.tracker, type: .debug, String(describing: batch.count))
        cancel = HttpClient.sendRequest(request: RequestBuilder.buildRequest(lines: batch), queue: eventProcessor) { status, error in
            self.sending = false
            switch SendOutcome(status: status) {
            case .sent:
                self.queueStore.remove(batch)
                self.consecutiveRetries = 0
                self.batchLimit = RequestBuilder.maxBatchEvents
            case .split where batch.count > 1:
                self.consecutiveRetries = 0
                self.batchLimit = max(1, batch.count / 2)
                os_log("Server refused %s events as too large. Sending %s at a time.", log: OSLog.tracker, type: .info,
                       String(describing: batch.count), String(describing: self.batchLimit))
            case .drop, .split:
                self.queueStore.remove(batch)
                self.consecutiveRetries = 0
                os_log("Server rejected %s events with status %s. Not resending them.", log: OSLog.tracker, type: .error,
                       String(describing: batch.count), String(describing: status ?? 0))
            case .retry:
                self.consecutiveRetries += 1
                os_log("Send failed (%s). Keeping %s events for a retry.", log: OSLog.tracker, type: .info,
                       status.map { "status \($0)" } ?? error?.localizedDescription ?? "no response",
                       String(describing: batch.count))
            }
            if self.active {
                self.scheduleFlush()
            }
            task.end()
        }
    }

    internal func startFlushTimer() {
        os_log("Flush timer starting", log: OSLog.tracker, type: .debug)
        if flushTimer == nil && active && !sending {
            scheduleFlush()
            os_log("Flush timer started", log: OSLog.tracker, type: .debug)
        }
    }

    /// Arms one tick at a time, rather than a repeating timer, so that each period gets its own jitter or backoff.
    private func scheduleFlush() {
        let delay = consecutiveRetries > 0
            ? Self.backoffDelay(afterRetries: consecutiveRetries, interval: flushInterval)
            : flushInterval
        flushTimer = scheduleEventProcessing(inSeconds: delay * flushJitter(), target: self, selector: #selector(flushTimerFired))
    }

    /// Doubles the interval after each consecutive failed send, up to 15 minutes.
    static func backoffDelay(afterRetries retries: Int, interval: TimeInterval) -> TimeInterval {
        min(interval * pow(2, Double(retries)), maxFlushBackoff)
    }

    @objc private func flushTimerFired() {
        flushTimer = nil
        flush()
        // A send in flight re-arms the timer when it finishes, with a backoff if it failed.
        if active && !sending {
            scheduleFlush()
        }
    }

    internal func pauseFlushTimer() {
        os_log("Flush timer stopping", log: OSLog.tracker, type: .debug)
        if flushTimer != nil && !active {
            flushTimer?.cancel()
            flushTimer = nil
            os_log("Flush timer stopped", log: OSLog.tracker, type: .debug)
        }
    }

    private func addApplicationObservers() {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.underlyingQueue = eventProcessor
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: queue, using: self.resumeExecution(_:))
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: queue, using: self.resumeExecution(_:))
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: queue, using: self.suspendExecution(_:))
        NotificationCenter.default.addObserver(forName: UIScene.didEnterBackgroundNotification, object: nil, queue: queue, using: self.suspendExecution(_:))
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: queue, using: self.suspendExecution(_:))
    }

    @objc private func resumeExecution(_ notification: Notification) {
        if active {
            return
        }
        self.active = true
        os_log("Resuming execution after foreground/active", log: OSLog.tracker, type: .info)
        startFlushTimer()
        track.resume()
    }

    @objc private func suspendExecution(_ notification: Notification) {
        if !active {
            return
        }
        self.active = false
        os_log("Stopping execution before background/inactive/terminate", log: OSLog.tracker, type: .info)
        hardShutdown()

        self.track.sendHeartbeats()
        // During a backoff, store events for later rather than retry early against a failing proxy.
        if consecutiveRetries == 0 {
            os_log("Flushing queue in background", log: OSLog.tracker, type: .info)
            self.flush()
        } else {
            storeQueuedEvents()
        }
    }

    internal func hardShutdown() {
        pauseFlushTimer()
        track.pause()
    }

}

extension OSLog {
    private static var logger = "ParselyTracker"
    static let tracker = OSLog(subsystem: "ParselyTracker", category: "parsely_tracker")
}

private final class BackgroundTask {
    static func begin(onExpire: @escaping () -> Void) -> Self {
        let task = Self()
        task.taskIdentifier = UIApplication.shared.beginBackgroundTask {
            onExpire()
            task.end()
        }
        return task
    }

    private var taskIdentifier: UIBackgroundTaskIdentifier!

    private init() {
        // Use `begin` to create an instance.
    }

    func end() {
        guard taskIdentifier != .invalid else {
            return
        }

        UIApplication.shared.endBackgroundTask(taskIdentifier)
        taskIdentifier = .invalid
    }
}
