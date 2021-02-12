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

/**
Visit decls with annotations
*/

final class AnnotatedDeclVisitor: SyntaxVisitor {
    let annotation: String
    let path: String
    let module: String
    let root: SourceFileSyntax
    let converter: SourceLocationConverter
    let charset: CharacterSet
    var usedTypes = [String]()
    var declMap = DeclMap()
    
    init(annotation: String, path: String, module: String, root: SourceFileSyntax) {
        self.annotation = annotation
        self.path = path
        self.module = module
        
        self.root = root
        self.converter = SourceLocationConverter(file: path, tree: root)
        self.charset = CharacterSet(arrayLiteral: "!", "?").union(.whitespaces)
    }
    
    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        #if CLASS_MOCKING
        if let item = node.item.as(ClassDeclSyntax.self) {
            let metadata = item.leadingTrivia?.annotationMetadata(with: annotation)
            let annotated = metadata != nil
            let inheritedTypes = item.inheritedTypes.filter{$0 != "AnyObject" && $0 != "class" && $0 != "Any"}
            let ent = DeclMetadata(path: path, module: module, declType: .classType, inheritedTypes: inheritedTypes, boundTypes: [], isPublicOrOpen: item.accessLevel.isPublicOrOpen, annotated: annotated, used: false)
            if declMap[item.name] == nil {
                declMap[item.name] = []
            }
            declMap[item.name]?.append(ent)
            usedTypes.append(contentsOf: item.refTypes)
            return .skipChildren
        }
        #endif
        
        if let item = node.item.as(ProtocolDeclSyntax.self) {
            let metadata = item.leadingTrivia?.annotationMetadata(with: annotation)
            let annotated = metadata != nil
            let inheritedTypes = item.inheritedTypes.filter{$0 != "AnyObject" && $0 != "class" && $0 != "Any"}
            let ent = DeclMetadata(path: path,
                                   module: module,
                                   imports: [],
                                   encloser: "",
                                   name: item.name,
                                   type: item.type,
                                   fullName: item.fullName,
                                   description: item.description,
                                   declType: .protocolType,
                                   inheritedTypes: inheritedTypes,
                                   boundTypes: [],
                                   boundTypesAL: [],
                                   isPublicOrOpen: item.accessLevel.isPublicOrOpen,
                                   isOverride: false,
                                   annotated: annotated,
                                   used: false)
            if declMap[item.name] == nil {
                declMap[item.name] = []
            }
            declMap[item.name]?.append(ent)
            usedTypes.append(contentsOf: item.refTypes)
            return .skipChildren
        } else if let _ = node.item.as(ClassDeclSyntax.self) {
            return .skipChildren
        }
        
        return .visitChildren
    }
}
