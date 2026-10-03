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

class QueueStoreTests: XCTestCase {

    func testQueueSurvivesReopening() {
        let directory = makeDirectory()
        let lines = [line(1), line(2)]
        QueueStore(directory: directory).append(lines)
        XCTAssertEqual(QueueStore(directory: directory).oldest(limit: 10, maxBytes: .max), lines)
    }

    func testFullQueueDropsOldestEvents() {
        let store = QueueStore(directory: nil)
        let lines = (0..<(QueueStore.maxEvents + 5)).map { line($0) }
        store.append(lines)
        XCTAssertEqual(store.count, QueueStore.maxEvents)
        XCTAssertEqual(store.oldest(limit: 1, maxBytes: .max), [lines[5]])
    }

    func testDropsEventsOlderThan23Hours() {
        let directory = makeDirectory()
        let now = Date()
        let stale = line(1, ts: now.addingTimeInterval(-QueueStore.maxEventAge - 60).millisecondsSince1970)
        let fresh = line(2, ts: now.addingTimeInterval(-60).millisecondsSince1970)
        let store = QueueStore(directory: directory)
        store.append([stale, fresh])
        store.dropEvents(olderThan: now.addingTimeInterval(-QueueStore.maxEventAge))
        XCTAssertEqual(QueueStore(directory: directory).oldest(limit: 10, maxBytes: .max), [fresh])
    }

    func testBatchesRespectEventAndByteLimits() {
        let store = QueueStore(directory: nil)
        let lines = (0..<5).map { line($0) }
        store.append(lines)
        XCTAssertEqual(store.oldest(limit: 2, maxBytes: .max), Array(lines[0..<2]))
        let twoLines = lines[0].utf8.count + lines[1].utf8.count + 2
        XCTAssertEqual(store.oldest(limit: 10, maxBytes: twoLines), Array(lines[0..<2]))
        XCTAssertEqual(store.oldest(limit: 10, maxBytes: 1), [lines[0]], "A line over the byte cap should go on its own")
    }

    func testRemoveTakesOneCopyOfEachSentLine() {
        let store = QueueStore(directory: nil)
        let (first, second, third) = (line(1), line(2), line(3))
        store.append([first, second, first, third])
        store.remove([first, second])
        XCTAssertEqual(store.oldest(limit: 10, maxBytes: .max), [first, third])
    }

    func testLoadSkipsLinesThatAreNotJSONObjects() throws {
        let directory = makeDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let good = line(1)
        try Data((good + "\n{\"truncated\n[1]").utf8).write(to: directory.appendingPathComponent("parsely-events.jsonl"))
        XCTAssertEqual(QueueStore(directory: directory).oldest(limit: 10, maxBytes: .max), [good])
    }

    func testSerializeSkipsEventsThatAreNotJSON() throws {
        let good = Event("pageview", url: "http://example.com", urlref: nil, metadata: nil, extra_data: ["n": 1],
                         idsite: "example.com")
        let bad = Event("pageview", url: "http://example.com", urlref: nil, metadata: nil, extra_data: ["when": Date()],
                        idsite: "example.com")
        let line = try XCTUnwrap(QueueStore.serialize(good))
        let decoded = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any])
        XCTAssertEqual(decoded["url"] as? String, "http://example.com")
        XCTAssertNil(QueueStore.serialize(bad), "An event JSON can't encode should be dropped, not crash the flush")
    }

    private func line(_ number: Int, ts: UInt64 = Date().millisecondsSince1970) -> String {
        "{\"action\":\"pageview\",\"url\":\"http://example.com/\(number)\",\"data\":{\"ts\":\(ts)}}"
    }

    private func makeDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("parsely-tests-\(UUID().uuidString)")
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory
    }
}
