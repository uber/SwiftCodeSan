#if TESTFILE


import Foundation

public enum BarType {
    case current
}


class Klass: P {
    private static var unusedP: SomeType = SomeType()


    public init() {
    }

    func isActive(_ arg: AmbProtocol?) -> Bool {
        arg?.usedFunc()
        return true
    }

    public override func isApplicable(context: SomeContext, with flag: Flag) -> Bool {
        return flag.isActive
    }

    func unusedFunc() {
        print("...")
    }
}


public final class OtherKlass {
    public static var sharedInstance = OtherKlass()

    public var shouldRun: Bool {
        let (lhs, mhs, rhs) = asdf()
        print(lhs, rhs)

        return false
    }
}

public protocol Flag {
}

public extension Flag {
    var isActive: Bool {
        return true
    }

    var isActiveLong: Bool {
        return isEnabled(for: "Exp1") || isEnabled(for: "Exp2")
    }
}

public protocol YProtocol {
    var unusedY: String { get }
}

public extension YProtocol {
    func usedZ() {
    }
}

protocol UnusedInternal {
}

extension UnusedInternal {
    func unusedX() {
    }
}

#endif
