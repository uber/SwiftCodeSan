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

public func removeUnusedImports(fileToModuleMap: [String: String],
                                whitelist: Whitelist?,
                                topDeclsOnly: Bool,
                                inplace: Bool,
                                logFilePath: String? = nil,
                                concurrencyLimit: Int? = nil) {
    scanConcurrencyLimit = concurrencyLimit

    let p = DeclParser()
    
    log("Scan all decls and generate a decl map...")
    logTime()

    let allDeclMap = p.scanAndMapDecls(fileToModuleMap: fileToModuleMap,
                                       topDeclsOnly: topDeclsOnly)

    logTime()
    log("#Decls", allDeclMap.keys.count)

    var unusedImports = [String: [String]]()

    let whitelistModulesBlock = { (module: String) -> Bool in
        let moduleComps = module.components(separatedBy: ".").filter {!$0.isEmpty}
        for comp in moduleComps {
            if let list = whitelist?.modules, list.contains(comp) {
                return true
            }
            if let list = whitelist?.modulesSuffix {
                for suffix in list {
                    if comp.hasSuffix(suffix) {
                        return true
                    }
                }
            }
            if let list = whitelist?.modulesPrefix {
                for prefix in list {
                    if comp.hasPrefix(prefix) {
                        return true
                    }
                }
            }
        }
        return false
    }

    let resourceSuffixes = ["Strings", "Images"]
    let moduleFromResourceBlock = { (name: String) -> String? in
        return resourceSuffixes.compactMap { return name.hasSuffix($0) ? name.components(separatedBy: $0).first : nil }.first
    }

    log("Check referenced decls and compare their source modules against imported modules to filter out unused imports...")
    var total = 0
    p.checkRefs(fileToModuleMap: fileToModuleMap, declMap: allDeclMap) { (filepath, refs, imports) in
        var usedImportsInFile = [String: Bool]()
        for i in imports {
            usedImportsInFile[i] = whitelistModulesBlock(i)
        }
        for r in refs {
            if let m = moduleFromResourceBlock(r), imports.contains(m) {
                usedImportsInFile[m] = true
            }

            if let refDecls = allDeclMap[r] {
                for refDecl in refDecls {
                    let m = refDecl.module

                    if imports.contains(m) {
                        usedImportsInFile[m] = true
                    } else {
                        let refinedImports = imports.filter {$0.contains(".")}
                        for item in refinedImports {
                            let comps = item.components(separatedBy: ".")
                            if comps.contains(m) {
                                usedImportsInFile[item] = true
                            }
                        }
                    }
                }
            } else if imports.contains(r) {
                // Sometimes a module name can be used in code, e.g. CoreFoundation.Foo
                usedImportsInFile[r] = true
            }
        }

        var unusedListInFile = [String]()
        for (module, used) in usedImportsInFile {
            if !used {
                total += 1
                unusedListInFile.append(module)
            }
        }

        if !unusedListInFile.isEmpty {
            unusedImports[filepath] = Set(unusedListInFile).compactMap{$0}
        }

//        log(total, interval: 200)
    }

    logTime()
    log("#Unused imports", total)

    if let op = logFilePath {
        log("Save results...")

        var totalUnused = 0
        var ret = unusedImports.map { (path, unusedlist) -> String in
            totalUnused += unusedlist.count
            return path + "\n" + String(unusedlist.count) + "\n" + unusedlist.joined(separator: ", ")
        }
        assert(total == totalUnused)
        ret.append("Total unused: \(totalUnused)")
        let retStr = ret.joined(separator: "\n\n")

        let declstr = allDeclMap.map{ (k, v) -> String in
            let t = """
            \(k):  \(v.map { $0.path }.joined(separator: ", "))
            """
            return t
        }.joined(separator: "\n")

        try? retStr.write(toFile: op, atomically: true, encoding: .utf8)
        try? declstr.write(toFile: op+"-decls", atomically: true, encoding: .utf8)
    }

    if inplace {
        log("Remove unused imports from files...", unusedImports.keys.count)
        let updater = DeclUpdater()
        updater.removeUnusedImports(fileToModuleMap: fileToModuleMap,
                                    unusedImports: unusedImports) { (path, result) in
                                        try? result.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }

    logTime()

    logTotalElapsed("Done")
}
