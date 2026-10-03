import Foundation
import os.log

class HttpClient {
    /// Short enough that a send started on backgrounding usually ends inside iOS's background time.
    static let timeout: TimeInterval = 20

    /// Reports the HTTP status (nil when no response arrived) and any error on `queue`.
    /// Returns a function that cancels the request.
    @discardableResult
    static func sendRequest(request: ParselyRequest, queue: DispatchQueue, completion: @escaping (Int?, Error?) -> Void) -> () -> Void {
        os_log("Sending request to %s", log: OSLog.tracker, type: .debug, request.url)

        guard let url = URL(string: request.url) else {
            os_log("Failed to create URL from %s", log: OSLog.tracker, type: .error, request.url)
            queue.async { completion(nil, URLError(.badURL)) }
            return {}
        }

        var urlRequest = URLRequest(url: url, timeoutInterval: timeout)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = request.body ?? (try? JSONSerialization.data(withJSONObject: request.params))
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.headers.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let task = URLSession.shared.dataTask(with: urlRequest) { _, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode
            if let err = error {
                os_log("Request failed: %s", log: OSLog.tracker, type: .error, err.localizedDescription)
            } else {
                os_log("Request finished with status %s", log: OSLog.tracker, type: .debug, String(describing: status))
            }

            queue.async {
                completion(status, error)
            }
        }
        task.resume()
        return { task.cancel() }
    }
}
