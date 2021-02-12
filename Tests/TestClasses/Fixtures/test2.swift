//
//  Copyright © Uber Technologies, Inc. All rights reserved.
//
#if TESTFILE

import Foundation
import ResumableAssert

@_transparent public func uberAssert(_ resumable: Bool) {
    let x = AssertStaticString()
    print(x)
    
    if uberAssertionDisabled {
        // skip condition check if assertion is disabled
        return
    }
    resumableAssert(message(), file: unsafeBitCast(assertStaticString, to: StaticString.self), function: function, line: line)
    
    
    let handler = AssertionHandlers.assertionFailure
    print(handler)
}

class AssertionHandlers {
}


public struct AssertStaticString {
    public init() {}
    public func omg() -> Int {
        return 5
    }
}

public extension String {
    func someAssert(_ assertStaticString: AssertStaticString) {
    }
}


public typealias AssertionHandler = (String?, data: LogModelMetadata?, line: UInt)


public let uberAssertionDisabled: Bool = {
    return false
}()

public func resumableAssert(_ message: String, file: StaticString, function: String, line: UInt) {
}



public class Synchronized {
    
}

public protocol KeyValueSubscripting {
    associatedtype Key
    associatedtype Value
    
    /// Accesses the value associated with the given key for reading and writing.
    subscript(key: Key) -> Value? { get set }
}

public extension Synchronized: KeyValueSubscripting where T: KeyValueSubscripting {
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
        return "asdf"
    }

}
#endif
