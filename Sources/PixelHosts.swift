import Foundation
import os.log

/// The apikey-to-host map baked into the app at build time.
///
/// There is deliberately no default host. An apikey that is not in the map does not resolve,
/// and its events are dropped rather than sent somewhere that might be the wrong region.
struct PixelHosts {

    /// The artifact version this SDK understands. A different version fails closed.
    private static let supportedVersion = 1

    /// Basename of the generated resource in the app bundle.
    static let resourceName = "ParselyHosts"

    private let hosts: [String: String]

    init(hosts: [String: String]) {
        self.hosts = hosts
    }

    var isEmpty: Bool {
        hosts.isEmpty
    }

    func host(for apikey: String) -> String? {
        guard !apikey.isEmpty else {
            return nil
        }
        return hosts[apikey]
    }

    /// Partition events by the host they must be sent to.
    ///
    /// Grouping is by host rather than by apikey so that several apikeys in the same region
    /// share a single request, as they did before hosts were configurable.
    func group(events: [Event]) -> (byHost: [String: [Event]], unresolved: [Event]) {
        var byHost: [String: [Event]] = [:]
        var unresolved: [Event] = []

        for event in events {
            if let host = host(for: event.idsite) {
                byHost[host, default: []].append(event)
            } else {
                unresolved.append(event)
            }
        }

        return (byHost, unresolved)
    }

    static func decode(from data: Data) -> PixelHosts {
        struct Artifact: Decodable {
            let version: Int
            let hosts: [String: String]?
        }

        guard let artifact = try? JSONDecoder().decode(Artifact.self, from: data) else {
            os_log("Could not read %{public}s.json. No events will be sent.",
                   log: OSLog.tracker, type: .error, resourceName)
            return PixelHosts(hosts: [:])
        }

        guard artifact.version == supportedVersion else {
            os_log("%{public}s.json has unsupported version %d. No events will be sent.",
                   log: OSLog.tracker, type: .error, resourceName, artifact.version)
            return PixelHosts(hosts: [:])
        }

        return PixelHosts(hosts: artifact.hosts ?? [:])
    }

    static func loadFromMainBundle() -> PixelHosts {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            os_log("%{public}s.json is missing from the app bundle. No events will be sent. Add the Parse.ly build phase to generate it.",
                   log: OSLog.tracker, type: .error, resourceName)
            return PixelHosts(hosts: [:])
        }

        return decode(from: data)
    }
}
