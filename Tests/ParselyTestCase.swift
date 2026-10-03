import XCTest
@testable import ParselyAnalytics

class ParselyTestCase: XCTestCase {
    internal var parselyTestTracker: Parsely!

    override func setUp() {
        super.setUp()
        parselyTestTracker = makePareslyTracker()
    }

    func makePareslyTracker() -> Parsely {
        let tracker = Parsely.getInstance()
        // Each tracker gets its own queue file, so trackers left running by other tests can't send its events.
        tracker.queueStore = QueueStore(directory: makeQueueDirectory())

        // Note that because we call addTeardownBlock, this method needs to be defined within an
        // XCTestCase
        addTeardownBlock {
            tracker.hardShutdown()
        }

        return tracker
    }

    func makeQueueDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("parsely-tests-\(UUID().uuidString)")
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory
    }
}

extension Parsely {

    static let testAPIKey = "examplesite.com"
}
