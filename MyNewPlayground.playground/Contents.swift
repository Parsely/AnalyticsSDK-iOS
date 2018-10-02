import UIKit

let doIt: () -> String = {
    print("woo")
    return "hoo"
}

func doOtherThings(function: () -> String, otherThing: String) {
    let yasss: String = function()
    print(yasss)
    print(otherThing)
}

doOtherThings(function: doIt, otherThing: "HAHAHAHAHA")
