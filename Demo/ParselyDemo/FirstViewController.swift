import UIKit
import os.log
import ParselyAnalytics

class FirstViewController: UIViewController {
    let delegate = UIApplication.shared.delegate as! AppDelegate

    @IBAction func didTouchButton(_ sender: Any) {
        os_log("didTouchButton", log: OSLog.default, type: .debug)
        let demoMetas = ParselyMetadata(authors: ["Yogi Berr"])
        delegate.parsely.trackPageView(url: "http://parsely.com/path/cool-blog-post/1?qsarg=nawp&anotherone=yup", metadata: demoMetas, extraData: ["product-id": "12345"], siteId: "subdomain.parsely-test.com")
    }

    @IBAction func didStartEngagement(_ sender: Any) {
        os_log("didStartEngagement", log: OSLog.default, type: .debug)
        delegate.parsely.startEngagement(url: "http://parsely.com/very-not-real", urlref: "http://parsely.com/not-real", extraData: ["product-id": "12345"], siteId: "engaged.parsely-test.com")
    }

    @IBAction func didStopEngagement(_ sender: Any) {
        os_log("didStopEngagement", log: OSLog.default, type: .debug)
        delegate.parsely.stopEngagement()
    }
    @IBAction func didStartVideo(_ sender: Any) {
        os_log("didStartVideo", log: OSLog.default, type: .debug)
        let demoMetas = ParselyMetadata(authors: ["Yogi Berr"], duration: TimeInterval(10))
        delegate.parsely.trackPlay(url: "http://parsely.com/path/cool-blog-post/1?qsarg=nawp&anotherone=yup", urlref: "not-a-real-urlref", videoID: "videoOne", duration: TimeInterval(6000), metadata: demoMetas, extraData: ["product-id": "12345", "ts": "should be overwritten"])
    }
    @IBAction func didPauseVideo(_ sender: Any) {
        os_log("didStopVideo", log: OSLog.default, type: .debug)
        delegate.parsely.trackPause()
    }
}
