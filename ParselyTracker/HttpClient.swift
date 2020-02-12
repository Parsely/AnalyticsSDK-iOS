import Foundation
import os.log

import Alamofire

class HttpClient {
    static func sendRequest(request: ParselyRequest) {
        os_log("Sending request to %s", log: OSLog.tracker, type: .debug, request.url)
        
        Alamofire.request(request.url, method: .post, parameters: request.params, encoding: JSONEncoding.default, headers: request.headers as? HTTPHeaders).responseJSON {
            (response) in
            if let err = response.error {
                os_log("Request failed: %s", log: OSLog.tracker, type: .error, err.localizedDescription)
                // TODO retry in response to specific errors here
                // retry only needs to happen on timeouts or similar connection failures, not 500 or 404
            } else {
                os_log("Request succeeded", log: OSLog.tracker, type: .debug)
            }
        }
    }
}
