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
Checks for referenced decls
*/

final class RefChecker: SyntaxVisitor {
    var imports = [String]()
    private var declMap = DeclMap()
    private var path: String
    private var module: String
    private var reflist = [String]()
    var refs: Set<String> {
        return Set(reflist)
    }
    
    init(_ path: String, module: String, declMap: DeclMap) {
        self.path = path
        self.module = module
        self.declMap = declMap
    }

    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        if node.item.is(ExprSyntax.self) || node.item.is(StmtSyntax.self) {
            reflist.append(contentsOf: node.item.refTypes(with: declMap))
            return .skipChildren
        }

        return .visitChildren
    }

    override func visit(_ node: VariableDeclSyntax) -> SyntaxVisitorContinueKind {
        reflist.append(contentsOf: node.refTypes(with: declMap))
        if node.isOverride {
            reflist.append(node.name)
        }

        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        reflist.append(contentsOf: node.refTypes(with: declMap))
        if node.isOverride {
            reflist.append(node.name)
        }
        return .visitChildren
    }

    override func visit(_ node: SubscriptDeclSyntax) -> SyntaxVisitorContinueKind {
        reflist.append(contentsOf: node.refTypes(with: declMap))
        return .visitChildren
    }

    override func visit(_ node: InitializerDeclSyntax) -> SyntaxVisitorContinueKind {
        reflist.append(contentsOf: node.refTypes(with: declMap))
        if node.isOverride {
            reflist.append(node.name)
        }
        return .visitChildren
    }

    override func visit(_ node: EnumCaseDeclSyntax) -> SyntaxVisitorContinueKind {
         reflist.append(contentsOf: node.refTypes(with: declMap))
         return .visitChildren
     }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        reflist.append(contentsOf: node.refTypes(with: declMap))
        return .visitChildren
    }
    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        reflist.append(contentsOf: node.refTypes(with: declMap))
        return .visitChildren
    }
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        reflist.append(contentsOf: node.refTypes(with: declMap))
        reflist.append(node.name)
        return .visitChildren
    }
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        reflist.append(contentsOf: node.refTypes(with: declMap))
        return .visitChildren
    }
    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        reflist.append(contentsOf: node.refTypes(with: declMap))
        return .visitChildren
    }

    override func visit(_ node: TypealiasDeclSyntax) -> SyntaxVisitorContinueKind {
        reflist.append(contentsOf: node.refTypes(with: declMap))
        return .visitChildren
    }

    override func visit(_ node: AssociatedtypeDeclSyntax) -> SyntaxVisitorContinueKind {
        reflist.append(contentsOf: node.refTypes(with: declMap))
        return .visitChildren
    }

    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.attributes == nil, node.importKind == nil {
            let str = node.path.description.trimmed
            imports.append(str)
        }
        return .skipChildren
    }
}
