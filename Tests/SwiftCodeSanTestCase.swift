import XCTest
import SwiftCodeSanKit

class SwiftCodeSanTestCase: XCTestCase {
    var srcFilePathsCount = 1
    var mockFilePathsCount = 1
    
    let bundle = Bundle(for: SwiftCodeSanTestCase.self)
    
    lazy var dstFilePath: String = {
        return bundle.bundlePath + "/Dst.swift"
    }()
    
    lazy var srcFilePaths: [String] = {
        var idx = 0
        var paths = [String]()
        let prefix = bundle.bundlePath + "/Src"
        let suffix = ".swift"
        while idx < srcFilePathsCount {
            let path = prefix + "\(idx)" + suffix
            paths.append(path)
            idx += 1
        }
        return paths
    }()
    
    lazy var mockFilePaths: [String] = {
        var idx = 0
        var paths = [String]()
        let prefix = bundle.bundlePath + "/Mocks"
        let suffix = ".swift"
        while idx < mockFilePathsCount {
            let path = prefix + "\(idx)" + suffix
            paths.append(path)
            idx += 1
        }
        return paths
    }()
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let created = FileManager.default.createFile(atPath: dstFilePath, contents: nil, attributes: nil)
        XCTAssert(created)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        try? FileManager.default.removeItem(atPath: dstFilePath)
        for srcpath in srcFilePaths {
            try? FileManager.default.removeItem(atPath: srcpath)
        }
    }
    
    func verify(srcContent: String, dstContent: String, header: String = "", declType: DeclType = .protocolType, useTemplateFunc: Bool = false, testableImports: [String]? = [], concurrencyLimit: Int? = 1) {
        verify(srcContents: [srcContent], dstContent: dstContent, header: header, declType: declType, useTemplateFunc: useTemplateFunc, testableImports: testableImports, concurrencyLimit: concurrencyLimit)
    }
    
    func verify(srcContents: [String], dstContent: String, header: String, declType: DeclType, useTemplateFunc: Bool, testableImports: [String]?, concurrencyLimit: Int?) {
        var index = 0
        srcFilePathsCount = srcContents.count
        
        for src in srcContents {
            if index < srcContents.count {
                let srcCreated = FileManager.default.createFile(atPath: srcFilePaths[index], contents: src.data(using: .utf8), attributes: nil)
                index += 1
                XCTAssert(srcCreated)
            }
        }
        // TODO: Pass in srcfile path - module list
        removeDeadDecls(filesToModules: ["test1.swift": "test1"],
                        whitelist: nil,
                        topDeclsOnly: true,
                        inplace: true,
                        testFiles: [],
                        inplaceTests: false,
                        logFilePath: nil,
                        concurrencyLimit: nil,
                        onCompletion: {
                            let output = (try? String(contentsOf: URL(fileURLWithPath: self.dstFilePath), encoding: .utf8)) ?? ""
                            let outputContents = output.components(separatedBy:  .whitespacesAndNewlines).filter{!$0.isEmpty}
                            XCTAssert(outputContents.count > 0)
                        })
    }
}

