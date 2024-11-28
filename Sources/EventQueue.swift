import Foundation
import os.log

extension Array {
    mutating func take(_ elementsCount: Int) -> [Element] {
        if elementsCount <= 0 {
            return []
        }
        let min = Swift.min(elementsCount, count)
        let segment = Array(self[0..<min])
        self.removeFirst(min)
        return segment
    }
}

struct EventQueue<T> {
    var list = [T]()

    mutating func push(_ element: T) {
        os_log("Event pushed into queue", log: OSLog.tracker, type: .debug)
        list.append(element)
    }

    mutating func push<Collection>(contentsOf elements: Collection) where T == Collection.Element, Collection: Sequence {
        os_log("Events pushed into queue", log: OSLog.tracker, type: .debug)
        list.append(contentsOf: elements)
    }

    mutating func pop() -> T? {
        if list.isEmpty {
            return nil
        }
        os_log("Event popped from queue", log: OSLog.tracker, type: .debug)
        return list.removeFirst()
    }

    mutating func get(count: Int = 0) -> [T] {
        if count == 0 {
            os_log("Got %zd events from queue", log: OSLog.tracker, type: .debug, list.count)
            return list.take(list.count)
        }
        os_log("Got %zd events from queue", log: OSLog.tracker, type: .debug, count)
        return list.take(count)
    }

    func length() -> Int {
        return list.count
    }
}
