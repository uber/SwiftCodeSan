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

public final class AnnotationUpdater {

    public init() {}

    public func removeAnnotationsFromUnusedTypes(fileToModuleMap: [String: String],
                                                 whitelist: Whitelist?,
                                                 annotation: String,
                                                 declMap: DeclMap,
                                                 completion: @escaping (String, String) -> ()) {
        scan(fileToModuleMap) { (path, module, lock) in
            do {
                let node = try SyntaxParser.parse(path)
                let remover = AnnotationRewriter(path, annotation: annotation, whitelist: whitelist, declMap: declMap)
                let ret = remover.visit(node)

                lock?.lock()
                completion(path, ret.description)
                lock?.unlock()
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }


    public func logUnusedTypes(_ unusedTypeMap: DeclMap,
                                _ resolvedUsedTypeMap: DeclMap,
                                _ outputFilePath: String?) {

        let unusedListStr = unusedTypeMap.map { (k, vs) -> [String] in
            return vs.map { k + ": " + $0.module + "\n -- " + $0.path }
        }.flatMap{$0}.joined(separator: "\n")

        let usedListStr = resolvedUsedTypeMap.map { (k, v) -> String in
            return k + ": " + v.map{$0.module}.joined(separator: ", ")
        }
        let usedList = usedListStr.joined(separator: "\n")

        log("Unused annotations", unusedTypeMap.count, "Used annotations ", resolvedUsedTypeMap.count)

        if let outputFilePath = outputFilePath {
            try? unusedListStr.write(toFile: outputFilePath, atomically: true, encoding: .utf8)
            log("Saving to", outputFilePath)
            try? usedList.write(toFile: outputFilePath + "-used", atomically: true, encoding: .utf8)
            log("Saving to", outputFilePath + "-used")
        }
    }
}
