import Foundation

let dict: [String: Any] = ["idsite": "example.com", "ts": 13123123.13123, "data": ["tags": ["tag1", "tag2", "tag3"], "cust_ts": 13132123123]]

func mkJSON(dic: [String: Any]) -> String {
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
        let jsonText = String(data: jsonData, encoding: .ascii)
        return jsonText!
    } catch {
        print(error.localizedDescription)
    }
    return ""
}
let jsonString = mkJSON(dic: dict)

//func tests() -> String{
//    do {
//        let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted)
//        let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
//        if let dictFromJSON = decoded as? [String:Any] {
//            print(dictFromJSON)
//        }
//    } catch {
//        print(error.localizedDescription)
//    }
//    return ""
//}
//
//let NOTHING = tests()
