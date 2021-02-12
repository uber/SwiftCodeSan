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
 Updates access levels in the source code
 */
public final class AccessLevelRewriter: SyntaxRewriter {
    var decls: [DeclMetadata]
    let path: String
    let module: String
    public init(_ path: String, module: String?, decls: [DeclMetadata]) {
        self.path = path
        self.module = module ?? ""
        self.decls = decls
    }

    private func updateModifiers(_ name: String, fullName: String, description: String, declType: DeclType, modifiers: ModifierListSyntax?) -> (ModifierListSyntax, Bool)? {
        let contains = decls.contains(where: { (d: DeclMetadata) -> Bool in
            return d.name == name && d.fullName == fullName && d.declDescription == description && d.declType == declType
        })

        if contains {
            var isModified = false
            var list = [DeclModifierSyntax]()
            if let modifiers = modifiers {

                for modifier in modifiers {
                    if modifier.name.text == String.public || modifier.name.text == String.open {
                        let updatedAcl = modifier.name.withKind(.stringLiteral("")).withoutTrailingTrivia()
                        let updatedModifier = SyntaxFactory.makeDeclModifier(name: updatedAcl, detailLeftParen: modifier.detailLeftParen, detail: modifier.detail, detailRightParen: modifier.detailRightParen)
                        isModified = true
                        list.append(updatedModifier)
                    } else {

                        if isModified, modifier.name.text == "internal", modifier.detail?.text == "set" {
                            let updatedAcl = modifier.name.withKind(.stringLiteral("")).withoutTrailingTrivia()
                            let updatedModifier = SyntaxFactory.makeDeclModifier(name: updatedAcl, detailLeftParen: nil, detail: nil, detailRightParen: nil)
                            list.append(updatedModifier)
                        } else {
                            list.append(modifier)
                        }
                    }
                }
            }
            return (SyntaxFactory.makeModifierList(list), isModified)
        }
        return nil
    }

    override public func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        if let (updatedModifier, isModified) = updateModifiers(node.name, fullName: node.fullName, description: node.description, declType: node.declType, modifiers: node.modifiers) {
            if isModified {
                mutableNode.modifiers = updatedModifier
            }
            return DeclSyntax(mutableNode)
        }
        return super.visit(node)
    }

    override public func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        if let (updatedModifier, isModified) = updateModifiers(node.name, fullName: node.fullName, description: node.description, declType: node.declType, modifiers: node.modifiers) {
            if isModified {
                mutableNode.modifiers = updatedModifier
            }
            return DeclSyntax(mutableNode)
        }

        return super.visit(node)
    }

    override public func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        if let (updatedModifier, isModified) = updateModifiers(node.name, fullName: node.fullName, description: node.description, declType: node.declType, modifiers: node.modifiers) {
            if isModified {
                mutableNode.modifiers = updatedModifier
            }

            return DeclSyntax(mutableNode)
        }
        return super.visit(node)
    }

    override public func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        if let (updatedModifier, isModified) = updateModifiers(node.name, fullName: node.fullName, description: node.description, declType: node.declType, modifiers: node.modifiers) {
            if isModified {
                mutableNode.modifiers = updatedModifier
            }
            return DeclSyntax(mutableNode)
        }
        return super.visit(node)
    }

    override public func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        if let (updatedModifier, isModified) = updateModifiers(node.name, fullName: node.fullName, description: node.description, declType: node.declType, modifiers: node.modifiers) {
            if isModified {
                mutableNode.modifiers = updatedModifier
            }

            return DeclSyntax(mutableNode)
        }
        return super.visit(node)
    }

    override public func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        if let (updatedModifier, isModified) = updateModifiers(node.name, fullName: node.fullName, description: node.description, declType: node.declType, modifiers: node.modifiers) {
            if isModified {
                mutableNode.modifiers = updatedModifier
            }
            return DeclSyntax(mutableNode)
        }
        return super.visit(node)
    }

    override public func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        if let (updatedModifier, isModified) = updateModifiers(node.name, fullName: node.fullName, description: node.description, declType: node.declType, modifiers: node.modifiers) {
            if isModified {
                mutableNode.modifiers = updatedModifier
            }
            return DeclSyntax(mutableNode)
        }
        return super.visit(node)
    }
    
    override public func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        if let (updatedModifier, isModified) = updateModifiers(node.name, fullName: node.fullName, description: node.description, declType: node.declType, modifiers: node.modifiers) {
            if isModified {
                mutableNode.modifiers = updatedModifier
            }
            return DeclSyntax(mutableNode)
        }
        return super.visit(node)
    }

    override public func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        var mutableNode = node
        if let (updatedModifier, isModified) = updateModifiers(node.name, fullName: node.fullName, description: node.description, declType: node.declType, modifiers: node.modifiers) {
            if isModified {
                mutableNode.modifiers = updatedModifier
            }
            return DeclSyntax(mutableNode)
        }
        return super.visit(node)
    }

    override public func visit(_ node: TypealiasDeclSyntax) -> DeclSyntax {
           var mutableNode = node
           if let (updatedModifier, isModified) = updateModifiers(node.name, fullName: node.fullName, description: node.description, declType: node.declType, modifiers: node.modifiers) {
               if isModified {
                   mutableNode.modifiers = updatedModifier
               }
               return DeclSyntax(mutableNode)
           }
           return super.visit(node)
       }
}
