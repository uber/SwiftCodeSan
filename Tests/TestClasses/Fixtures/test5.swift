#if TESTFILE

enum OMG {
    case eat(SomeFood)
    case sleep
}

public func toJSON(arg: OMG) -> JSON {
    var dict = [String: JSON]()

    switch arg {
        case .eat(let value):
            print(value)
        case .Disclaimer(let value):
            dict["type"] = "disclaimer"
    }

    return .dictionary(dict)
}



public typealias T = (String, GrpcStreamingEventHandler)
public typealias GrpcStreamingEventHandler<StreamingResponse> = (Bool, StreamingResponse?, Error?) -> ()

#if CRASH_ON_ASSERT

    public extension String {
        func withFakeStaticStringForAssertion(_ block: (_ assertStaticString: AssertStaticString) -> ()) {
            if let stringData = self.data(using: .utf8, allowLossyConversion: false) {
                var assertStaticString = AssertStaticString()
                assertStaticString._utf8CodeUnitCount = stringData.count
                stringData.withUnsafeBytes { rawBufferPointer in
                    if let rawPtr = rawBufferPointer.baseAddress {
                        assertStaticString._startPtrOrData = Int(bitPattern: rawPtr)
                    }
                    block(assertStaticString)
                }
            }
        }
    }

#endif

#endif
