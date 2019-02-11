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
        os_log("Sending request to %s", request.url)
        HTTP.POST(request.url, parameters: request.params, headers:request.headers as? [String: String], requestSerializer: JSONParameterSerializer()) { response in
            if let err = response.error {
                os_log("Request failed: %s", err.localizedDescription)
            } else {
                os_log("Request succeeded")
            }
        }
    }
}
