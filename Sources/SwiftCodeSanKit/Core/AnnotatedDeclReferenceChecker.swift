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
Checks annotations of the referenced decls
*/
final class AnnotatedReferenceChecker: SyntaxVisitor {
    let path: String
    var usedTypes = [String]()
    let declMap: DeclMap
    init(path: String, declMap: DeclMap) {
        self.path = path
        self.declMap = declMap
    }
    
    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        usedTypes.append(contentsOf: node.item.refTypes(with: declMap, filterKey: "Mock"))
        return .skipChildren
    }
}
