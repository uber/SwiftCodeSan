#if TESTFILE


import Foundation

public protocol ProtocolY {
    func filterBy(uuid: String) -> Int?
}
public protocol ProtocolX: ProtocolY {
}


public final class FooKlass {
    public static var sharedInstance = FooKlass()

    func bar(arg: String) -> Int {
        let (lhs, rhs) = arg

        let ret = Double()
        ret.listener = lhs
        return ret
    }
}

final class ListInteractor {
    public var x: String = "", y: Int, z: Double

    public var (v, w): (String, Int) = ("", 0)

    public let
   application: UIApplicationProtocol,
   cachedExperiments: CachedExperimenting,
   deepLinkBuilder: (_ url: URL) -> DetailsDeeplink?,
   detailsBuilder: DetailsBuildable,
   listStream: Observable<[DetailsListStreaming]>
}

#endif
