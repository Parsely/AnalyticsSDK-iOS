//
//  HttpClient.swift
//  ParselyTracker
//
//  Created by Emmett Butler on 2/11/19.
//  Copyright © 2019 Parse.ly. All rights reserved.
//

import Foundation
import os.log

import SwiftHTTP

class HttpClient {
    static func sendRequest(request: ParselyRequest) {
        os_log("Sending request to %s", log: OSLog.tracker, type: .debug, request.url)
        HTTP.POST(request.url, parameters: request.params, headers:request.headers as? [String: String],
                  requestSerializer: JSONParameterSerializer())
        { response in
            if let err = response.error {
                os_log("Request failed: %s", log: OSLog.tracker, type: .error,
                       err.localizedDescription)
                // TODO retry in response to specific errors here
                // retry only needs to happen on timeouts or similar connection failures, not 500 or 404
            } else {
                os_log("Request succeeded", log: OSLog.tracker, type: .debug)
            }
        }
    }
}
