#if TESTFILE

import Foundation
import Test1


private let deserializeError = NSError(domain: MobileStudioStorageErrorDomain, code: MobileStudioStorageInvalidData, userInfo: nil)

extension String: MobileStudioStorable {

    static func instance(fromData data: Data) throws -> String {
        let result = self.init(data: data, encoding: .utf8)
        if let result = result {
            return result
        } else {
            throw deserializeError
        }
    }
}

let NoopTraceSingleton = NoopTraceObject()

// This is a comment
// doc comment
// asdf
public  protocol Bar: P1, P2 {
}

public typealias P1 = Cat.P1

public protocol XAB {
    subscript(key: Int) -> String? { get }
}

class KEX {}

extension KEX: XAB {
    public subscript(key: Int) -> String? {
        return nil
    }

    func bar() {

    }

    var debugDescription: String {
        return "this is P1"
    }
}



public protocol ObjectReference {

}

public protocol P {
    func iteratedObjects(_ object: Any) -> [ObjectReference]
}

public final class SynchronousKeyValueStoreWrapper<Key>: SynchronousKeyValueAssociating where Key: StoredKeying {
    var base: KeyValueStore<Key>?


    public subscript(key: T.Key) -> T.Value? {
        return nil
    }

}

#endif
