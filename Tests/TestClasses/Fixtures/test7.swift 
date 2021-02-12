#if TESTFILE

extension Foo {
    #if DEBUG
        var omg: Bool {
            if case .test = RunType.current {
                return !(Octopus.isOctopusActive() || TestRunner.sharedInstance.isActive)
            }
            return false
        }

        var workersProviderMock: PaymentIntegrationWorkersProvidingMock { shared { PaymentIntegrationWorkersProvidingMock() } }
        fileprivate var workersProvider: PaymentIntegrationWorkersProviding { isUnitTest ? workersProviderMock : shared { PaymentIntegrationWorkersProvider(parent: self) } }
    #else
        fileprivate var brb: PaymentIntegrationWorkersProviding { shared { PaymentIntegrationWorkersProvider(parent: self) } }
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
        uberAssert(true)
        //        print(loadedFonts)
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
            let count = store.synchronously(performStorageOperations: { (storeWrapper: SynchronousKeyValueStoreWrapper<Key>?) -> Int? in
                return storeWrapper?.element(forKey: storeKey)
            })
            print(count)
        }
    }
}

public final class KeyValueStore<Key> where Key: StoredKeying {
    public func synchronously<T>(performStorageOperations operations: (SynchronousKeyValueStoreWrapper<Key>?) -> T) -> T {
        let wrapper = SynchronousKeyValueStoreWrapper(self)
        let result = operations(wrapper)
        wrapper.invalidate()
        return result
    }
}

//print(k)

#endif
