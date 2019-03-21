import XCTest
@testable import ParselyTracker

class ParselyTestCase: XCTestCase {
    internal var parselyTestTracker: Parsely!
    let testApikey: String = "examplesite.com"

    override func setUp() {
        super.setUp()
        parselyTestTracker = Parsely.getInstance()
    }
    
    override func tearDown() {
        parselyTestTracker.hardShutdown()
        super.tearDown()
    }
}
