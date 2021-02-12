#if TESTFILE
extension Integration {
    var isUnitTest: Bool {
        #if TEST
        if case .test = RunType.current {
            return !(Handler.isHandlerActive() || runner.sharedInstance.isActive)
        }
        #else
        let x = SomeType().someMethod()
        return x
        #endif
    }

    var workersProviderMock: IntegrationProviderMock { shared { IntegrationProviderMock() } }
}


let s = SwipeTransitionController()

#endif
