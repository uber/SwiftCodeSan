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
Updates import statements in source code
*/

public final class ImportRewriter: SyntaxRewriter {
    let unused: [String]

    public init(_ path: String, unusedModules: [String]?) {
        self.unused = unusedModules ?? []
    }

    override public func visit(_ node: ImportDeclSyntax) -> DeclSyntax {
        var remove = false
        let str = node.path.description.trimmed
        if unused.contains(str) {
            remove = true
        } else {
            for t in node.path.tokens {
                if unused.contains(t.text) {
                    remove = true
                }
            }
        }

        if remove {
            if let trivia = node.importTok.leadingTrivia {
                let t = SyntaxFactory.makeUnknown("", leadingTrivia: trivia, trailingTrivia: Trivia(pieces: []))
                let ret = SyntaxFactory.makeImportDecl(attributes: nil, modifiers: nil, importTok: t, importKind: nil, path: SyntaxFactory.makeAccessPath([]))
                return DeclSyntax(ret)
            } else {
                let ret = SyntaxFactory.makeBlankImportDecl()
                return DeclSyntax(ret)
            }
        }

        return super.visit(node)
    }
}
