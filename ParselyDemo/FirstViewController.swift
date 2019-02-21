//
//  FirstViewController.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 7/6/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import UIKit
import os.log
import ParselyTracker

class FirstViewController: UIViewController {
    @IBOutlet weak var trackPVButton: UIButton!
    let delegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    @IBAction func didTouchButton(_ sender: Any) {
        os_log("didTouchButton", log: OSLog.default, type: .debug)
        let demoMetas = ParselyMetadata(authors: ["Yogi Berr"])
        delegate.parsely.trackPageView(url: "http://parsely.com/path/cool-blog-post/1?qsarg=nawp&anotherone=yup", metadata: demoMetas, extraData: ["product-id": "12345"], idsite: "subdomain.parsely-test.com")
    }
    
    @IBAction func didStartEngagement(_ sender: Any) {
        os_log("didStartEngagement", log: OSLog.default, type: .debug)
        delegate.parsely.startEngagement(url: "http://parsely.com/very-not-real", urlref:"http://parsely.com/not-real", extraData: ["product-id": "12345"], idsite: "engaged.parsely-test.com")
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

