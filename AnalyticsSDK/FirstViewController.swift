//
//  FirstViewController.swift
//  AnalyticsSDK
//
//  Created by Chris Wisecarver on 7/6/18.
//  Copyright © 2018 Parse.ly. All rights reserved.
//

import UIKit
import os.log

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
        delegate.parsely.trackPageView(url: "http://parsely.com/path/cool-blog-post/1?qsarg=nawp&anotherone=yup", metadata: ["Author": "Yogi Berra"])
    }
    
    @IBAction func didStartEngagement(_ sender: Any) {
        os_log("didStartEngagement", log: OSLog.default, type: .debug)
        delegate.parsely.startEngagement(url: "parsely-page", metadata: ["Author":"Yogi Berra"])
    }
    
    @IBAction func didStopEngagement(_ sender: Any) {
        os_log("didStopEngagement", log: OSLog.default, type: .debug)
        delegate.parsely.stopEngagement(url: "parsely-page")
    }
    @IBAction func didStartVideo(_ sender: Any) {
        os_log("didStartVideo", log: OSLog.default, type: .debug)
        delegate.parsely.trackPlay(url: "http://parsely.com/path/cool-blog-post/1?qsarg=nawp&anotherone=yup", urlref: "not-a-real-urlref", videoID: "videoOne", metadata: ["section": "testsection", "duration": 420])
    }
    @IBAction func didPauseVideo(_ sender: Any) {
        os_log("didStopVideo", log: OSLog.default, type: .debug)
        delegate.parsely.trackPause(url: "http://parsely.com/path/cool-blog-post/1?qsarg=nawp&anotherone=yup", urlref: "not-a-real-urlref", videoID: "videoOne", metadata: [:])
    }
}

