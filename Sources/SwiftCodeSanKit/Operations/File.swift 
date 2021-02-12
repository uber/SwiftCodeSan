//
//  Copyright (c) 2018. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation



final class PromoListInteractor {
  private var x: String = "", y: Int, z: Double
    private var (v, w): (String, Int) = ("", 0)

    init() {
        self.x = "0"
        self.y = 0
        self.z = 0.0
    }
}


/*

 First, scan all the classes declared
 Second, scan all the classes used, and generate a used_list of classes
 Third, go through first map, check if key and val (key's parents) are in used_map, if not, mark it unused.
 Fourth, go through unused_map, remove class decl for each entry.

 */


public func backup_removeDeadDecls(filesToModules: [String: String],
                            whitelist: Whitelist,
                            topDeclsOnly: Bool,
                            inplace: Bool,
                            testFiles: [String]?,
                            inplaceTests: Bool,
                            logFilePath: String? = nil,
                            concurrencyLimit: Int? = nil,
                            onCompletion: @escaping () -> ()) {

    scanConcurrencyLimit = concurrencyLimit
    let p = DeclParser()

    log("Scan all decls...")

    let t0 = CFAbsoluteTimeGetCurrent()
    let declMap = p.scanAndMapDecls(fileToModuleMap: filesToModules,
                                       topDeclsOnly: topDeclsOnly,
                                       whitelist: whitelist)

    let t1 = CFAbsoluteTimeGetCurrent()
    log("--", t1-t0)

    log("Scan used decls...")

    let allDeclMap = flatten(declMap: declMap)

    var usedMap = [String: Bool]()

    p.checkRefs(fileToModuleMap: filesToModules, declMap: allDeclMap) { (path, refs, imports) in
        for r in refs {
            usedMap[r] = true
        }
    }

    let t2 = CFAbsoluteTimeGetCurrent()
    log("--", t2-t1)


    log("Filter unused decls...")
    var unusedDeclMap = DeclMap()
    for (k, decls) in allDeclMap {
        if let _ = usedMap[k] {
            for decl in decls {
                for boundType in decl.boundTypes {
                    if let boundDecls = allDeclMap[boundType] {
                        for boundDecl in boundDecls {
                            boundDecl.used = true
                        }
                    }
                }
            }
        }
    }

    for (k, v)  in allDeclMap {
        if let _ = usedMap[k] {
            // used

        } else {
            // this checks if k's child is used, i.e. k is used
            //            let ret = v.filter(\.used)
            //            print(ret)
            let isUnused = v.filter{$0.used}.isEmpty
            if isUnused {
                unusedDeclMap[k] = v
            }
        }
    }

    if let outputFilePath = logFilePath {
        log("Save results...")
        let used = usedMap.map {"\($0.key)"}.joined(separator: ", ")
        let ret = unusedDeclMap.map {"\($0.key): \($0.value.map{$0.path}.joined(separator: ", "))"}.joined(separator: "\n")

        try? used.write(toFile: outputFilePath+"-used", atomically: true, encoding: .utf8)
        try? ret.write(toFile: outputFilePath+"-ret", atomically: true, encoding: .utf8)
        log(" to ", outputFilePath)
    }

    let unusedDeclFiles = unusedDeclMap.values.flatMap{$0}.map{$0.path}
    let unusedDeclFileSet = Set(unusedDeclFiles)

    let declFiles = allDeclMap.values.flatMap{$0}.map{$0.path}
    let declFileSet = Set(declFiles)
    log("#Declared", allDeclMap.count, "#Files with decls", declFileSet.count)
    log("#Used", usedMap.count)
    log("#Unused", unusedDeclMap.count, "#Files with unused decls", unusedDeclFileSet.count)

    let d = DeclUpdater()
    if inplace {
        log("Update source files...")
        let t3 = CFAbsoluteTimeGetCurrent()
//        d.removeDeadDecls(declMap: unusedDeclMap) { pathToContent in
//            for (path, content) in pathToContent {
//                try? content.write(toFile: path, atomically: true, encoding: .utf8)
//            }
//        }

        let t4 = CFAbsoluteTimeGetCurrent()
        log("Removed unused decls", t4-t3)
    }

    if inplaceTests, let testFiles = testFiles {
        log("Update test files...")
        let t5 = CFAbsoluteTimeGetCurrent()
        var testsDeleted = 0
        d.updateTests(paths: testFiles, unusedMap: unusedDeclMap) { (path, content, deleteFile) in
            testsDeleted += 1 //deleteCount
            if deleteFile {
                try? FileManager.default.removeItem(atPath: path)
            } else {
                try? content.write(toFile: path, atomically: true, encoding: .utf8)
            }
        }
        let t6 = CFAbsoluteTimeGetCurrent()
        log("Removed tests using unused classes", testsDeleted, t6-t5)
    }


    let t7 = CFAbsoluteTimeGetCurrent()
    log("Total (s)", t7-t0)

    onCompletion()
}


// uber
// filter out:
// keyedsyncpluginpoint,
// shouldmoveuber, func unfixatedatetimeproperties, func asyncUserInteractive
// models inheriting ResponseBody, Model, ubertable, uberphone, usnap, -fixture,
// things referenced by TestableComponents/TestablePlaceGeocoder.swift, not in srcs
