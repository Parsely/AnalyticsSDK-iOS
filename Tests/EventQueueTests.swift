import Nimble
@testable import ParselyAnalytics
import XCTest

class EventQueueTests: XCTestCase {

    func testPush() {
        var queue = makeQueue(loadedWithNumberOfItems: 30)
        queue.push(1)
        expect(queue.list).to(haveCount(31))
    }

    func testPushContentsOf() {
        var queue = makeQueue(loadedWithNumberOfItems: 0)
        queue.push(contentsOf: [1])
        expect(queue.list).to(haveCount(1))

        queue.push(contentsOf: [2, 3])
        expect(queue.list).to(haveCount(3))

        queue.push(contentsOf: [4, 5].prefix(1))
        expect(queue.list).to(haveCount((4)))

        expect(queue.list.suffix(3)) == [2, 3, 4]
    }

    func testPop() {
        var queue = makeQueue(loadedWithNumberOfItems: 2)
        expect(queue.pop()) == 0
        expect(queue.list).to(haveCount(1))
    }

    func testGet() {
        var queue = makeQueue(loadedWithNumberOfItems: 30)

        expect(queue.get(count: 5)) == [0, 1, 2, 3, 4]
        expect(queue.list).to(haveCount(25))

        expect(queue.get(count: 5)) == [5, 6, 7, 8, 9]
        expect(queue.list).to(haveCount(20))

        expect(queue.get(count: 21)) == (10...29).map { $0 }
        expect(queue.list).to(beEmpty())

        expect(queue.get(count: 5)) == []
    }

    func testGetAll() {
        var queue = makeQueue(loadedWithNumberOfItems: 5)
        expect(queue.get()) == [0, 1, 2, 3, 4]
    }

    func testGetTooMany() {
        var queue = makeQueue(loadedWithNumberOfItems: 5)
        expect(queue.get(count: 1_000)) == [0, 1, 2, 3, 4]
    }

    func testNegativeCount() {
        var queue = makeQueue(loadedWithNumberOfItems: 5)
        expect(queue.get(count: -1)) == []
    }

    func makeQueue(loadedWithNumberOfItems numberOfItem: Int = 30) -> EventQueue<Int> {
        var queue = EventQueue<Int>()
        (0..<numberOfItem).forEach { queue.push($0) }
        return queue
    }
}
