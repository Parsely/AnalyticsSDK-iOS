import Foundation
import os.log

class HttpClient {
    static func sendRequest(request: ParselyRequest) {
        os_log("Sending request to %s", log: OSLog.tracker, type: .debug, request.url)
        
        guard let url = URL(string: request.url) else {
            os_log("Failed to create URL from %s", log: OSLog.tracker, type: .error, request.url)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = try? JSONSerialization.data(withJSONObject: request.params)
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
                
        URLSession.shared.dataTask(with: urlRequest) { _, _, error in
            if let err = error {
                os_log("Request failed: %s", log: OSLog.tracker, type: .error, err.localizedDescription)
                // TODO retry in response to specific errors here
                // retry only needs to happen on timeouts or similar connection failures, not 500 or 404
            } else {
                os_log("Request succeeded", log: OSLog.tracker, type: .debug)
            }
        }.resume()
    }
}
