import Foundation
import os.log

/// The durable event queue: one JSON-encoded event per line, kept in memory and mirrored to a file,
/// so events the server has not accepted survive failed sends and app restarts.
final class QueueStore {
    static let maxEvents = 1_000
    /// mobileproxy strips `ts` from events over a day old, so older events would count at receipt time.
    static let maxEventAge: TimeInterval = 23 * 60 * 60

    private var fileURL: URL?
    private var directoryReady = false
    private lazy var lines: [String] = load()

    /// Pass a nil `directory` to keep the queue in memory only.
    init(directory: URL? = QueueStore.defaultDirectory) {
        fileURL = directory?.appendingPathComponent("parsely-events.jsonl")
    }

    static var defaultDirectory: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("com.parsely")
    }

    var count: Int {
        lines.count
    }

    /// The line to store for an event, or nil if it can't be encoded as JSON.
    static func serialize(_ event: Event) -> String? {
        let dict = event.toDict()
        // JSONSerialization raises an Objective-C exception, which Swift can't catch, on invalid input.
        guard JSONSerialization.isValidJSONObject(dict),
              let data = try? JSONSerialization.data(withJSONObject: dict) else {
            os_log("Dropping a %s event that can't be encoded as JSON", log: OSLog.tracker, type: .error, event.action)
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }

    /// Adds lines at the end, dropping the oldest past `maxEvents`.
    func append(_ newLines: [String]) {
        guard !newLines.isEmpty else {
            return
        }
        lines.append(contentsOf: newLines)
        if lines.count > Self.maxEvents {
            os_log("Event queue is full. Dropping the %s oldest events.", log: OSLog.tracker, type: .error,
                   String(describing: lines.count - Self.maxEvents))
            lines.removeFirst(lines.count - Self.maxEvents)
        }
        save()
    }

    /// The oldest lines that fit in one batch. A single line over `maxBytes` goes on its own.
    func oldest(limit: Int, maxBytes: Int) -> [String] {
        var batch: [String] = []
        var bytes = 0
        for line in lines.prefix(limit) {
            bytes += line.utf8.count + 1
            if bytes > maxBytes && !batch.isEmpty {
                break
            }
            batch.append(line)
        }
        return batch
    }

    func dropEvents(olderThan cutoff: Date) {
        let cutoffMs = cutoff.millisecondsSince1970
        let kept = lines.filter { (Self.timestamp(of: $0) ?? cutoffMs) >= cutoffMs }
        if kept.count != lines.count {
            os_log("Dropping %s queued events older than 23 hours", log: OSLog.tracker, type: .info,
                   String(describing: lines.count - kept.count))
            lines = kept
            save()
        }
    }

    /// Removes one stored copy of each line in `batch`. Matching by content stays right when the cap
    /// dropped lines while the batch was in flight.
    func remove(_ batch: [String]) {
        var pending = Dictionary(batch.map { ($0, 1) }, uniquingKeysWith: +)
        lines = lines.filter { line in
            guard let remaining = pending[line], remaining > 0 else {
                return true
            }
            pending[line] = remaining - 1
            return false
        }
        save()
    }

    private static func timestamp(of line: String) -> UInt64? {
        let event = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any]
        return ((event?["data"] as? [String: Any])?["ts"] as? NSNumber)?.uint64Value
    }

    private func load() -> [String] {
        guard let fileURL, FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        guard let data = try? Data(contentsOf: fileURL) else {
            // Most likely protected data that isn't available yet. Don't overwrite what we couldn't read.
            os_log("Could not read the event queue. Keeping events in memory only.", log: OSLog.tracker, type: .error)
            self.fileURL = nil
            return []
        }
        // A line that isn't a JSON object would make the whole request body invalid.
        let stored = String(decoding: data, as: UTF8.self).split(separator: "\n").map(String.init).filter { line in
            (try? JSONSerialization.jsonObject(with: Data(line.utf8))) is [String: Any]
        }
        return Array(stored.suffix(Self.maxEvents))
    }

    private func save() {
        guard let fileURL else {
            return
        }
        do {
            if !directoryReady {
                var directory = fileURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try? directory.setResourceValues(values)
                directoryReady = true
            }
            // Readable in the background once the device has been unlocked since boot.
            try Data(lines.joined(separator: "\n").utf8)
                .write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            os_log("Could not save the event queue: %s", log: OSLog.tracker, type: .error, error.localizedDescription)
        }
    }
}
