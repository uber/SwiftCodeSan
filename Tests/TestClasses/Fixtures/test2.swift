//
//  Copyright © Uber Technologies, Inc. All rights reserved.
//
#if TESTFILE

import Foundation

@_transparent public func testAssert(_ resumable: Bool) {
    let x = AssertStaticString()
    print(x)
    
    if testAssertionDisabled {
        return
    }
    reassert(message(), file: unsafeBitCast(assertStaticString, to: StaticString.self), function: function, line: line)
    
    
    let handler = AssertionHandlers.assertionFailure
    print(handler)
}

class AssertionHandlers {
}


public struct AssertStaticString {
    public init() {}
    public func check() -> Int {
        return 5
    }
}

public extension String {
    func someAssert(_ assertStaticString: AssertStaticString) {
    }
}


public typealias AssertionHandler = (String?, data: LogModelMetadata?, line: UInt)


public let testAssertionDisabled: Bool = {
    return false
}()

public func reassert(_ message: String, file: StaticString, function: String, line: UInt) {
}


public class SynchronizedFoo {
    
}

public protocol KeyValueSubscripting {
    associatedtype Key
    associatedtype Value
    subscript(key: Key) -> Value? { get set }
}

public extension SynchronizedFoo: KeyValueSubscripting where T: KeyValueSubscripting {
    public subscript(key: T.Key) -> T.Value? {
        get {
            return read { (collection) -> T.Value? in
                return collection[key]
            }
        }
        set {
            write { (collection) -> () in
                collection[key] = newValue
            }
        }
    }

    public func bar() -> String {
        return "bar"
    }

}
#endif
