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

public func removeUnusedAnnotations(annotation: String,
                                    filesToModules: [String: String],
                                    whitelist: Whitelist?,
                                    inplace: Bool,
                                    testFiles: [String]?,
                                    statsFile: String? = nil,
                                    concurrencyLimit: Int? = nil) {

    guard let testFiles = testFiles else { return }
    
    scanConcurrencyLimit = concurrencyLimit

    let p = AnnotatedDeclParser()
    var declMap = DeclMap()
    var annotatedDeclMap = DeclMap()

    log("Scan all mockables...")
    logTime()

    p.scanAnnotatedDecls(fileToModuleMap: filesToModules, annotation: annotation) { (filePath, initialUsedTypes, argProtocolMap) in
        for (k, vals) in argProtocolMap {
            if declMap[k] == nil {
                declMap[k] = []
            }
            declMap[k]?.append(contentsOf: vals)

            for v in vals {
                if v.annotated {
                    if annotatedDeclMap[k] == nil {
                        annotatedDeclMap[k] = []
                    }
                    annotatedDeclMap[k]?.append(v)
                }
            }
        }
    }
    logTime()

    log("Scan used types...") // in tests or manual mocks
    var mockedDecls = [String: Bool]()

    p.scanAnnotatedDeclRefs(paths: testFiles, exclusionSuffixes: nil, declMap: declMap) { (filePath, argUsedTypes) in
        let usedSet = Set(argUsedTypes)
        for usedType in usedSet {
            if usedType.hasSuffix("Mock") {
                let mockedDecl = String(usedType.dropLast("Mock".count))
                mockedDecls[mockedDecl] = true
            }
        }
    }
    logTime()

    log("Filter out unused types...")
    var unusedTypeMap = DeclMap()
    var declsToAnnotate = DeclMap()
    for (k, vals) in annotatedDeclMap {
        p.resolveRefChains(k, vals, nil, declMap, mockedDecls, &declsToAnnotate)
    }

    for (k, v) in annotatedDeclMap {
        if declsToAnnotate[k] == nil {
            unusedTypeMap[k] = v
        }
    }
    
    log("Save unused types...")
    let updater = AnnotationUpdater()
    updater.logUnusedTypes(unusedTypeMap, declsToAnnotate, statsFile)

    if inplace {
        log("Remove unused annotations from files...")
        updater.removeAnnotationsFromUnusedTypes(fileToModuleMap: filesToModules,
                                                 whitelist: whitelist,
                                                 annotation: annotation,
                                                 declMap: unusedTypeMap) { (path, content) in
            try? content.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }

    logTime()
    log("#Protocols", declMap.count, "#Annotated", annotatedDeclMap.count, "#Used Types", declsToAnnotate.count, "#Unused Types", unusedTypeMap.count)
    logTotalElapsed("Done")
}


