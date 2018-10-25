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
    
}

