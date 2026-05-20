import UIKit
import os.log
import ParselyAnalytics

class FirstViewController: UIViewController {
    let delegate = UIApplication.shared.delegate as! AppDelegate

    // Sandbox test URL for the conversion-tracking smoke flow. Both the pageview and
    // the conversion buttons fire against this URL on the `sandbox.joshhanson.io` apikey
    // so pageview history and conversion events share a visitor session in the backend.
    private let sandboxUrl = "https://sandbox.joshhanson.io/path/test-conversion2"
    private let sandboxSiteId = "sandbox.joshhanson.io"

    @IBAction func didTouchButton(_ sender: Any) {
        log("didTouchButton")
        let demoMetas = ParselyMetadata(authors: ["Yogi Berr"])
        delegate.parsely.trackPageView(url: "http://parsely.com/path/cool-blog-post/1?qsarg=nawp&anotherone=yup", metadata: demoMetas, extraData: ["product-id": "12345"], siteId: "subdomain.parsely-test.com")
    }

    @IBAction func didTouchSandboxPageview(_ sender: Any) {
        log("didTouchSandboxPageview")
        delegate.parsely.trackPageView(
            url: sandboxUrl,
            extraData: ["source": "ios_demo_app"],
            siteId: sandboxSiteId
        )
    }

    @IBAction func didTouchSandboxConversion(_ sender: Any) {
        log("didTouchSandboxConversion")
        delegate.parsely.trackConversion(
            url: sandboxUrl,
            conversionType: .subscription,
            conversionLabel: "ios_smoke_test_v2",
            extraData: ["plan": "weekly", "source": "ios_demo_app"],
            siteId: sandboxSiteId
        )
    }

    @IBAction func didStartEngagement(_ sender: Any) {
        log("didStartEngagement")
        delegate.parsely.startEngagement(url: "http://parsely.com/very-not-real", urlref: "http://parsely.com/not-real", extraData: ["product-id": "12345"], siteId: "engaged.parsely-test.com")
    }

    @IBAction func didStopEngagement(_ sender: Any) {
        log("didStopEngagement")
        delegate.parsely.stopEngagement()
    }
    @IBAction func didStartVideo(_ sender: Any) {
        log("didStartVideo")
        let demoMetas = ParselyMetadata(authors: ["Yogi Berr"], duration: TimeInterval(10))
        delegate.parsely.trackPlay(url: "http://parsely.com/path/cool-blog-post/1?qsarg=nawp&anotherone=yup", urlref: "not-a-real-urlref", videoID: "videoOne", duration: TimeInterval(6000), metadata: demoMetas, extraData: ["product-id": "12345", "ts": "should be overwritten"])
    }
    @IBAction func didPauseVideo(_ sender: Any) {
        log("didStopVideo")
        delegate.parsely.trackPause()
    }

    private func log(_ message: String) {
        os_log("[Parsely Demo App] %@", log: OSLog.default, type: .debug, message)
    }
}
