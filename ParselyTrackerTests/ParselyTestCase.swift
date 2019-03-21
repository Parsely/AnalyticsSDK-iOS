import XCTest
@testable import ParselyTracker

class ParselyTestCase: XCTestCase {
    internal var parselyTestTracker: Parsely!

    override func setUp() {
        super.setUp()
        parselyTestTracker = Parsely.getInstance()
    }
    
    override func tearDown() {
        super.tearDown()
    }
}
