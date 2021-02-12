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
import SwiftSyntax

final class DeclUpdater {

    func updateAccessLevels(filesToDecls: [String: [DeclMetadata]],
                            filesToModules: [String: String],
                            completion: @escaping (String, String) -> ()) {

        scan(filesToDecls) { (path, decls, lock) in
            do {
                let node = try SyntaxParser.parse(path)
                let rewriter = AccessLevelRewriter(path, module: filesToModules[path], decls: decls)
                let ret = rewriter.visit(node)
                lock?.lock()
                completion(path, ret.description)
                lock?.unlock()
            }  catch {
                fatalError(error.localizedDescription)
            }
        }
    }

    func removeDeadDecls(filesToDecls: [String: [DeclMetadata]],
                         completion: @escaping (String, String) -> ()) {
        scan(filesToDecls) { (path, decls, lock) in
            do {
                let node = try SyntaxParser.parse(path)
                let remover = DeclRemover(path, decls: decls)
                let ret = remover.visit(node)

                lock?.lock()
                completion(path, ret.description)
                lock?.unlock()
            }  catch {
                fatalError(error.localizedDescription)
            }
        }
    }

    func removeUnusedImports(paths: [String],
                             isDirs: Bool,
                             unusedImports: [String: [String]],
                             completion: @escaping (String, String) -> ()) {
        if isDirs {
            scan(dirs: paths) { (path, lock) in
                self.updateSrcs(path: path, module: "", lock: lock, unusedImports: unusedImports, completion: completion)
            }
        } else {
            scan(paths) { (path, lock) in
                self.updateSrcs(path: path, module: "", lock: lock, unusedImports: unusedImports, completion: completion)
            }
        }
    }

    func removeUnusedImports(fileToModuleMap: [String: String],
                             unusedImports: [String: [String]],
                             completion: @escaping (String, String) -> ()) {
        scan(fileToModuleMap) { (path, module, lock) in
            self.updateSrcs(path: path, module: module, lock: lock, unusedImports: unusedImports, completion: completion)
        }
    }

    private func updateSrcs(path: String,
                            module: String,
                            lock: NSLock?,
                            unusedImports: [String: [String]],
                            completion: @escaping (String, String) -> ()) {
        //        guard path.shouldParse(with: filterPaths) else { return }
        do {
            let node = try SyntaxParser.parse(path)
            let remover = ImportRewriter(path, unusedModules: unusedImports[path])
            let ret = remover.visit(node)

            lock?.lock()
            completion(path, ret.description)
            lock?.unlock()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    func updateTests(paths: [String],
                     unusedMap: DeclMap,
                     completion: @escaping (String, String, Bool) -> ()) {
        scan(paths) { (path, lock) in
            do {
                let node = try SyntaxParser.parse(path)
                let keyed = { (name: String) -> String in
                    if name.hasSuffix("SnapshotTests") {
                        return String(name.dropLast("SnapshotTests".count))
                    } else if name.hasSuffix("SnapshotTest") {
                        return  String(name.dropLast("SnapshotTest".count))
                    } else if name.hasSuffix("Tests") {
                        return String(name.dropLast("Tests".count))
                    } else if name.hasSuffix("Test") {
                        return String(name.dropLast("Test".count))
                    }
                    return name
                }
                let remover = DeclRemover(path, decls: [])
                let ret = remover.visit(node)
                // only remove part of this file, else delete the whole file in completion
                let shouldDeleteFile = false // declsInFile == unusedDecls && declsInFile > 0

                lock?.lock()
                completion(path, ret.description, shouldDeleteFile)
                lock?.unlock()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }

    #if REPORT_NO_MODIFY_BODY
    // If within a test body, var decls, func bodies, exprs, return val,
    // remove the whole function or class or lines:
    // let x = UnusedClass()  // need to remove occurrences of x (expr itself), replace w subst.
    // let x: UnusedClass    // remove above and assignment to x
    //   updateBody(current, unusedMap: unusedMap, content: &content)
    private func updateBody(_ current: Structure,
                            unusedMap: DeclMap,
                            content: inout Data) {
        for sub in current.substructures {
            let types = [sub.name.typeComponents, sub.typeName.typeComponents].flatMap{$0}
            for t in types {
                var tname = t
                if t.hasSuffix("Mock") {
                    tname = String(t.dropLast("Mock".count))
                }
                if unusedMap[tname] != nil {
                    replace(&content, start: sub.startOffset, end: sub.endOffset, with: space)
                }
            }
            updateBody(sub, unusedMap: unusedMap, content: &content)
        }
    }
    #endif


}

