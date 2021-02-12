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
Visit decls in source code being parsed
*/

final class DeclVisitor: SyntaxVisitor {
    var declMap = DeclMap()
    let path: String
    let module: String
    let topDeclsOnly: Bool
    let whitelistPath: Bool
    let whitelist: Whitelist?
    var importedModules = [String]()

    init(_ path: String,
         module: String?,
         topDeclsOnly: Bool,
         whitelistPath: Bool,
         whitelist: Whitelist?) {
        self.whitelist = whitelist
        self.whitelistPath = whitelistPath
        self.path = path
        self.module = module ?? ""
        self.topDeclsOnly = topDeclsOnly
    }


    override func visit(_ node: ProtocolDeclSyntax) -> SyntaxVisitorContinueKind {
        updateDecl(node, description: node.description, members: topDeclsOnly ? nil : node.members.members)
        return .skipChildren
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.attributesDescription.contains(String.propertyWrapper) {
            return .skipChildren
        }

        updateDecl(node, description: node.description, members: topDeclsOnly ? nil : node.members.members)
        return .visitChildren
    }
    override func visit(_ node: StructDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.attributesDescription.contains(String.propertyWrapper) {
            return .skipChildren
        }

        updateDecl(node, description: node.description, members: topDeclsOnly ? nil : node.members.members)
        return .skipChildren
    }
    override func visit(_ node: EnumDeclSyntax) -> SyntaxVisitorContinueKind {
        updateDecl(node, description: node.description, members: topDeclsOnly ? nil : node.members.members)
        return .skipChildren
    }
    override func visit(_ node: ExtensionDeclSyntax) -> SyntaxVisitorContinueKind {
        updateDecl(node, description: node.description, members: topDeclsOnly ? nil : node.members.members)
        return .skipChildren
    }
    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        importedModules.append(node.path.description.trimmed)
        return .visitChildren
    }

    override func visit(_ node: CodeBlockItemSyntax) -> SyntaxVisitorContinueKind {
        if let item = node.item.as(FunctionDeclSyntax.self) {
            updateDecl(item, description: item.description, members: nil)
            return .skipChildren
        } else if let _ = node.item.as(OperatorDeclSyntax.self) {
            return .skipChildren
        } else if let item = node.item.as(VariableDeclSyntax.self) {
            updateDecl(item, description: item.description, members: nil)
            return .skipChildren
        } else if let item = node.item.as(TypealiasDeclSyntax.self) {
            updateDecl(item, description: item.description, members: nil)
            return .skipChildren
        }

        return .visitChildren
    }

    private func memberDecls(_ decl: DeclSyntax, encloser: String, encloserDeclType: DeclType, encloserWhitelisted: Bool) -> [DeclMetadata] {
        let mdecls = decl.declMetadatas(path: path, module: module, encloser: encloser, description: decl.description, imports: importedModules)

        for mdecl in mdecls {
            if encloserDeclType == .extensionType {
                mdecl.isExtensionMember = true
            }

            let memberWhitelisted = whitelist?.declWhitelisted(name: mdecl.name, isMember: true, module: nil, parents: nil, path: mdecl.path) ?? false
            if encloserWhitelisted ||
                memberWhitelisted ||
                mdecl.declType == .initType ||
                mdecl.declType == .subscriptType ||
                mdecl.declType == .operatorType {
                if mdecl.isPublicOrOpen {
                    mdecl.shouldExpose = true
                }
                mdecl.used = true
            }
        }
        return mdecls
    }

    private func updateDecl(_ item: DeclProtocol, description: String, members: MemberDeclListSyntax?) {
        let decls = item.declMetadatas(path: path, module: module, encloser: "", description: description, imports: importedModules)

        for decl in decls {
            var shouldWhitelist = (decl.declType == .operatorType)
            if !shouldWhitelist, !decl.name.isEmpty {
                if let whitelist = whitelist, whitelist.declWhitelisted(name: decl.name, isMember: false, module: module, parents: decl.inheritedTypes, path: decl.path) {
                    // whitelisted so don't add to declMap
                    shouldWhitelist = true
                }
            }

            if shouldWhitelist {
                if decl.isPublicOrOpen {
                    decl.shouldExpose = true
                }
                decl.used = true
            }

            if let members = members {
                var list = [DeclMetadata]()
                for m in members {
                    if let ifconfig = m.decl.as(IfConfigDeclSyntax.self) {
                        for clause in ifconfig.clauses {
                            if let clauseMembers = clause.elements.as(MemberDeclListSyntax.self) {
                                for el in clauseMembers {
                                    let mdecls = memberDecls(el.decl, encloser: decl.name, encloserDeclType: decl.declType, encloserWhitelisted: shouldWhitelist)
                                    list.append(contentsOf: mdecls)
                                }
                            }
                        }
                    } else {
                        let mdecls = memberDecls(m.decl, encloser: decl.name, encloserDeclType: decl.declType, encloserWhitelisted: shouldWhitelist)
                        list.append(contentsOf: mdecls)
                    }
                }
                decl.members = list
            }

            if !decl.name.isEmpty, declMap[decl.name] == nil {
                declMap[decl.name] = []
            }

            declMap[decl.name]?.append(decl)
        }
    }
}

