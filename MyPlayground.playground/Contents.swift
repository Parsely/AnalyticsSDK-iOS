//: Playground - noun: a place where people can play

import UIKit

extension Array {
    mutating func take(_ elementsCount: Int) -> [Element] {
        let min = Swift.min(elementsCount, count)
        let segment = Array(self[0..<min])
        self.removeFirst(min)
        return segment
    }
}

var list:[Int] = [1,2,3,4,5,6,7,8,9,10]

var babby_list:[Int] = Array(list.take(4))

print(list)

