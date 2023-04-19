import XCTest
@testable import ParselyAnalytics

class ParselyTestCase: XCTestCase {
    internal var parselyTestTracker: Parsely!
    static let testApikey: String = "examplesite.com"

    override func setUp() {
        super.setUp()
        parselyTestTracker = Parsely.getInstance()
    }
    
    override func tearDown() {
        parselyTestTracker.hardShutdown()
        super.tearDown()
    }
}
