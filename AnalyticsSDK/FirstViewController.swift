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
        delegate.parsely.trackPageView(params: ["action": "pageview"])
    }
    
    @IBAction func didStartEngagement(_ sender: Any) {
        os_log("didStartEngagement", log: OSLog.default, type: .debug)
        delegate.parsely.startEngagement(id: "parsely-page")
    }
    
    @IBAction func didStopEngagement(_ sender: Any) {
        os_log("didStopEngagement", log: OSLog.default, type: .debug)
        delegate.parsely.stopEngagement(id: "parsely-page")
    }
    @IBAction func didStartVideo(_ sender: Any) {
        os_log("didStartVideo", log: OSLog.default, type: .debug)
        delegate.parsely.trackPlay(videoID: "videoOne", metadata: [:], urlOverride: "")
    }
    @IBAction func didPauseVideo(_ sender: Any) {
        os_log("didStopVideo", log: OSLog.default, type: .debug)
        delegate.parsely.trackPause(videoID: "videoOne", metadata: [:], urlOverride: "")
    }
}

