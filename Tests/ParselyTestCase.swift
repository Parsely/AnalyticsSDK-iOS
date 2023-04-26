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

        // Note that because we call addTeardownBlock, this method needs to be defined within an
        // XCTestCase
        addTeardownBlock {
            tracker.hardShutdown()
        }

        return tracker
    }
}

extension Parsely {

    static let testAPIKey = "examplesite.com"
}
