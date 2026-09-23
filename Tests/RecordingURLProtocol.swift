import Foundation

/// Intercepts requests made through `URLSession.shared` so tests can assert what `flush()` sent.
final class RecordingURLProtocol: URLProtocol {

    static var capturedURLs: [String] = []
    /// Hosts that should fail as if the device had no connection.
    static var offlineHosts: Set<String> = []

    static func reset() {
        capturedURLs = []
        offlineHosts = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        RecordingURLProtocol.capturedURLs.append(request.url?.absoluteString ?? "")

        if let host = request.url?.host, RecordingURLProtocol.offlineHosts.contains(host) {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }

        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
