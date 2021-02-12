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

public class AnnotatedDeclParser {
    public init() {}
    public func scanAnnotatedDecls(fileToModuleMap: [String: String],
                                   annotation: String,
                                   completion: @escaping (String, [String], DeclMap) -> ()) {
        scan(fileToModuleMap) { (path, module, lock) in
            guard !path.contains("___"), path.shouldParse(with: ["Mock Mocks"]) else { return }
            
            do {
                let node = try SyntaxParser.parse(path)
                let visitor = AnnotatedDeclVisitor(annotation: annotation, path: path, module: module, root: node)
                visitor.walk(node)
                lock?.lock()
                defer {lock?.unlock()}
                completion(path, visitor.usedTypes, visitor.declMap)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    
    func scanAnnotatedDeclRefs(paths: [String],
                               exclusionSuffixes: [String]?,
                               declMap: DeclMap,
                               completion: @escaping (String, [String]) -> ()) {
        
        scan(paths) { (path, lock) in
            do {
                let node = try SyntaxParser.parse(path)
                let visitor = AnnotatedReferenceChecker(path: path, declMap: declMap)
                visitor.walk(node)
                lock?.lock()
                defer {lock?.unlock()}
                
                completion(path, visitor.usedTypes.filter{!$0.isEmpty})
            } catch {
                fatalError(error.localizedDescription)
            }
        }
    }

    func resolveRefChains(_ k: String, _ decls: [DeclMetadata]?, _ module: String?, _ declMap: DeclMap, _ mockedDecls: [String: Bool], _ declsToAnnotate: inout DeclMap) {

        guard let decls = decls else { return }
        if let _ = mockedDecls[k] {
            // used for mocking
            if declsToAnnotate[k] ==  nil {
                declsToAnnotate[k] = []
            }
            declsToAnnotate[k]?.append(contentsOf: decls)

        } else {
            if let module = module {
                for parentDecl in decls {
                    if parentDecl.annotated {
                        if parentDecl.module == module {
                            // within the same module, so no need to annotate
                        } else {
                            // cross module, so need to annotate
                            if declsToAnnotate[k] ==  nil {
                                declsToAnnotate[k] = []
                            }
                            declsToAnnotate[k]?.append(parentDecl)
                        }
                    }
                }
            }
        }

        for decl in decls {
            for parent in decl.inheritedTypes {
                resolveRefChains(parent, declMap[parent], decl.module, declMap, mockedDecls, &declsToAnnotate)
            }
        }
    }
}
