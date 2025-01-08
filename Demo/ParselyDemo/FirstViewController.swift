import UIKit
import os.log
import ParselyAnalytics

class FirstViewController: UIViewController {
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    @IBAction func didTouchButton(_ sender: Any) {
        log("didTouchButton")
        let demoMetas = ParselyMetadata(authors: ["Yogi Berr"])
        delegate.parsely.trackPageView(url: "http://parsely.com/path/cool-blog-post/1?qsarg=nawp&anotherone=yup", metadata: demoMetas, extraData: ["product-id": "12345"], siteId: "subdomain.parsely-test.com")
    }
    
    @IBAction func didStartEngagement(_ sender: Any) {
        log("didStartEngagement")
        delegate.parsely.startEngagement(url: "http://parsely.com/very-not-real", urlref:"http://parsely.com/not-real", extraData: ["product-id": "12345"], siteId: "engaged.parsely-test.com")
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
