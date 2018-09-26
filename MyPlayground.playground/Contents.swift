struct EncodableWrapper: Encodable {
    let wrapped: Encodable
    
    func encode(to encoder: Encoder) throws {
        try self.wrapped.encode(to: encoder)
    }
}

let dict: [String: Encodable] = [
    "Int": 1,
    "Double": 3.14,
    "Bool": false,
    "String": "test"
]
let wrappedDict = dict.mapValues(EncodableWrapper.init(wrapped:))
let jsonEncoder = JSONEncoder()
jsonEncoder.outputFormatting = .prettyPrinted
let jsonData = try! jsonEncoder.encode(wrappedDict)
let json = String(decoding: jsonData, as: UTF8.self)
print(json)
