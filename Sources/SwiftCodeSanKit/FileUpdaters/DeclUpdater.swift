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
}

