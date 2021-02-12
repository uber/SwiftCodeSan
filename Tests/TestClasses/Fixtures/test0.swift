#if TESTFILE
extension PaymentIntegration {
    var isUnitTest: Bool {
        #if UITEST
        if case .test = RunType.current {
            return !(Octopus.isOctopusActive() || TestRunner.sharedInstance.isActive)
        }
        #else
        let x = SomeType().someMethod()
        return x
        #endif
    }

    var workersProviderMock: PaymentIntegrationWorkersProvidingMock { shared { PaymentIntegrationWorkersProvidingMock() } }
}


let s = SwipeTransitionInteractionController()

#endif
