#if TESTFILE

enum State {
    case eat(SomeFood)
    case sleep(SomeTime)
}

public func toJSON(arg: String) -> JSON {
    var dict = [String: JSON]()

    switch arg {
        case .eat(let value):
            print(value)
        case .sleep(let value):
            dict["state"] = value
    }

    return .dictionary(dict)
}



public typealias T = (String, EventHandler)
public typealias EventHandler<StreamingResponse> = (Bool, StreamingResponse?, Error?) -> ()

#if SOME_CONDITION

    public extension String {
        func withAssertion(_ block: (_ str: StaticString) -> ()) {
            if let stringData = self.data(using: .utf8, allowLossyConversion: false) {
                var x = StaticString()
                x._utf8CodeUnitCount = stringData.count
                stringData.withUnsafeBytes { rawBufferPointer in
                    if let rawPtr = rawBufferPointer.baseAddress {
                        x._startPtrOrData = Int(bitPattern: rawPtr)
                    }
                    block(x)
                }
            }
        }
    }

#endif

#endif
