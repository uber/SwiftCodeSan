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
Updates source code containing annotations
*/

public final class AnnotationRewriter: SyntaxRewriter {
    let declMap: DeclMap
    let annotation: String
    let whitelist: Whitelist?
    let path: String
    public init(_ path: String,
                annotation: String,
                whitelist: Whitelist?,
                declMap: DeclMap) {
        self.path = path
        self.declMap = declMap
        self.whitelist = whitelist
        self.annotation = annotation
    }

    private func updateTrivia(with trivia: Trivia?) -> Trivia? {
        guard let trivia = trivia else { return nil }
        var pieces = [TriviaPiece]()

        for i in 0..<trivia.count {
            let piece = trivia[i]
            switch piece {
            case .docLineComment(let val):
                if val.contains(annotation) {
                    let ret = val.filtered(with: "/// " + annotation)
                    if !ret.isEmpty {
                        pieces.append(TriviaPiece.docLineComment(ret))
                    }
                } else {
                    pieces.append(piece)
                }
            case .docBlockComment(let val):
                if val.contains(annotation) {
                    let ret = val.filtered(with: "/// " + annotation)
                    if !ret.isEmpty {
                        pieces.append(TriviaPiece.docBlockComment(ret))
                    }
                } else {
                    pieces.append(piece)
                }
            default:
                pieces.append(piece)
            }
        }
        return Trivia(pieces: pieces)
    }

    override public func visit(_ node: CodeBlockItemSyntax) -> Syntax {
        if let item = node.item.as(ProtocolDeclSyntax.self), let _ = declMap[item.name] {
            if let whitelist = whitelist, whitelist.declWhitelisted(name: item.name, isMember: false, module: nil, parents: item.inheritedTypes, path: path) {
                return super.visit(node)
            }
            if let trimmedTrivia = updateTrivia(with: item.leadingTrivia) {
                var updatedNode = node
                updatedNode.leadingTrivia = trimmedTrivia
                return Syntax(updatedNode)
            }
        } else if let item = node.item.as(ProtocolDeclSyntax.self), let val = declMap[item.name] {
            #if CLASS_MOCKING
            // copy above here
            #endif
        }

        return super.visit(node)
    }
}


