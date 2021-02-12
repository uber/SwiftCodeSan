#if TESTFILE

import Test9
import Test10
import Foundation

class Foo: ProtocolX {
    func ticketWalletResultFilterBy(agencyId: String) -> Int? {
        return nil
    }

    var bar: Bool {
//        let found = FooKlass.sharedInstance.asdf(arg)
        let notFound = PromoListInteractor.application

        if found, !notFound {
            return true
        }
    }

//    var baz: String {
//        if case let .someCase = BarType.current {
//            return !(Klass().isActive() ||
//                Klass().isApplicable() ||
//                OtherKlass.sharedInstance.shouldRun)
//        }
//        return ""
//    }
}

let foo = Foo()
//print(foo.bar, foo.baz)

#endif
