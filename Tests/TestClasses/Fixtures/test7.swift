#if TESTFILE

extension Foo {
    #if DEBUG
        var baz: Bool {
            if case .test = RunType.current {
                return !(Handler.isHandlerActive() || runner.sharedInstance.isActive)
            }
            return false
        }

        var zmock: ZMock { shared { ZMock() } }
        fileprivate var zvar: Z { shared { Z(with: self) } }
    #else
        fileprivate var cat: Z { shared { Z(with: self) } }
    #endif
}

import Test6

let k = Klass()

class Klass: P {
    public func iteratedObjects(_ object: Any) -> [Result] {
        return []
    }

    private static var loadedFonts: Synchronized<[String: UIFont]> = Synchronized()

    public init() {
        testAssert(true)
    }

    public init(store: KeyValueStore<Key>,
                storeKey: Key,
                target: Int,
                initialHitTargetValue: Bool? = nil) {
        self.store = store
        self.storeKey = storeKey
        self.target = target + 1
        self.hitTargetSubject = ReplaySubject<Bool>.create(bufferSize: 1)

        queue.async {
            let count = store.synchronously(operate: { (container: SynchronousKeyValueStoreContainer<Key>?) -> Int? in
                return container?.item(for: storeKey)
            })
            print(count)
        }
    }
}

public final class KeyValueStore<Key> where Key: StoredKeying {
    public func synchronously<T>(operations: (SynchronousKeyValueStoreContainer<Key>?) -> T) -> T {
        let container = SynchronousKeyValueStoreContainer(self)
        let result = operations(container)
        container.invalidate()
        return result
    }
}

#endif
