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

    public override func isApplicable(forContext context: MainWorkerPluginContext, with cachedExperiments: CachedExperimenting) -> Bool {
        cachedExperiments.isTreatedForRideCheck
    }

    func unusedQ() {
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

public protocol CachedExperimenting {
}

public extension CachedExperimenting {
    var isTreatedForRideCheckList: Bool {
        return true
    }

    var isTreatedForRideCheck: Bool {
        return isTreated(forExperiment: ExperimentNamesSafety.safety_rider_midway_dropoff_anomaly) ||
            isTreated(forExperiment: ExperimentNamesSafety.safety_rider_on_trip_crash_detection) ||
            isTreated(forExperiment: ExperimentNamesCoreShared.safety_rider_vehicle_crash) ||
            isTreated(forExperiment: ExperimentNamesCoreShared.safety_rider_long_stop_anomaly)
    }
}

public protocol AmbProtocol {
    var unusedZ: String { get }
}

public extension AmbProtocol {
    func usedY() {
    }
}

protocol UnusedInternalP {
}

extension UnusedInternalP {
    func unusedX() {
    }
}

#endif
