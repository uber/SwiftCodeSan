#if TESTFILE

import Test9
import Test10
import Foundation

class Foo: ProtocolX {
    func filterBy(uuid: String) -> Int? {
        return nil
    }

    var bar: Bool {
        let found = FooKlass.sharedInstance.bar(arg)
        let notFound = ListInteractor.application

        if found, !notFound {
            return true
        }
    }

    var baz: String {
        if case let .someCase = BarType.current {
            return !(Klass().isActive() ||
                Klass().isApplicable() ||
                OtherKlass.sharedInstance.shouldRun)
        }
        return ""
    }
}

let foo = Foo()

#endif
