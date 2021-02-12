import Foundation

class DCETests: SwiftCodeSanTestCase {
    
    func testDCE() {
        verify(srcContent: klass,
               dstContent: klassMock,
               declType: .classType)
    }
    
    func testDC() {
        verify(srcContent: klass,
               mockContent: klassParentMock,
               dstContent: klassLongerMock,
               declType: .classType)
    }
}

