import XCTest
@testable import ParselyAnalytics

class ParselyTestCase: XCTestCase {
    internal var parselyTestTracker: Parsely!
    static let testApikey: String = "examplesite.com"

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
