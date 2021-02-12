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
Removes unused decls
*/

public final class DeclRemover: SyntaxRewriter {
    let path: String
    let decls: [DeclMetadata]

    public init(_ path: String, decls: [DeclMetadata]) {
        self.path = path
        self.decls = decls

        if path.contains("RideInteractor.swift") ||
            path.contains("TripInteractor.swift") ||
            path.contains("TransitTicketStream.swift") {
            print("PATH", path)
            print("REMOVE decls", decls.map{ ObjectIdentifier($0)})
        }
    }

    override public func visit(_ node: ExtensionDeclSyntax) -> DeclSyntax {
        if shouldRemove(node.name, fullName: node.fullName, description: node.description, declType: node.declType) {
            return DeclSyntax(SyntaxFactory.makeBlankExtensionDecl())
        }
        return super.visit(node)
    }
    override public func visit(_ node: EnumDeclSyntax) -> DeclSyntax {
        if shouldRemove(node.name, fullName: node.fullName, description: node.description, declType: node.declType) {
            return DeclSyntax(SyntaxFactory.makeBlankEnumDecl())
        }
        return super.visit(node)
    }
    override public func visit(_ node: StructDeclSyntax) -> DeclSyntax {
        if shouldRemove(node.name, fullName: node.fullName, description: node.description, declType: node.declType) {
            return DeclSyntax(SyntaxFactory.makeBlankStructDecl())
        }
        return super.visit(node)
    }
    override public func visit(_ node: ProtocolDeclSyntax) -> DeclSyntax {
        if shouldRemove(node.name, fullName: node.fullName, description: node.description, declType: node.declType) {
            return DeclSyntax(SyntaxFactory.makeBlankProtocolDecl())
        }
        return super.visit(node)
    }
    override public func visit(_ node: ClassDeclSyntax) -> DeclSyntax {
        if shouldRemove(node.name, fullName: node.fullName, description: node.description, declType: node.declType) {
            return DeclSyntax(SyntaxFactory.makeBlankClassDecl())
        }
        return super.visit(node)
    }
    override public func visit(_ node: FunctionDeclSyntax) -> DeclSyntax {
        if shouldRemove(node.name, fullName: node.fullName, description: node.description, declType: node.declType) {
            return DeclSyntax(SyntaxFactory.makeBlankFunctionDecl())
        }
        return super.visit(node)
    }
    override public func visit(_ node: SubscriptDeclSyntax) -> DeclSyntax {
        if shouldRemove(node.name, fullName: node.fullName, description: node.description, declType: node.declType) {
            return DeclSyntax(SyntaxFactory.makeBlankSubscriptDecl())
        }
        return super.visit(node)
    }
    override public func visit(_ node: InitializerDeclSyntax) -> DeclSyntax {
        if shouldRemove(node.name, fullName: node.fullName, description: node.description, declType: node.declType) {
            return DeclSyntax(SyntaxFactory.makeBlankInitializerDecl())
        }
        return super.visit(node)
    }
    override public func visit(_ node: VariableDeclSyntax) -> DeclSyntax {
        if shouldRemove(node.name, fullName: node.fullName, description: node.description, declType: node.declType) {
            return DeclSyntax(SyntaxFactory.makeBlankVariableDecl())
        }
        return super.visit(node)
    }
    override public func visit(_ node: TypealiasDeclSyntax) -> DeclSyntax {
        if shouldRemove(node.name, fullName: node.fullName, description: node.description, declType: node.declType) {
            return DeclSyntax(SyntaxFactory.makeBlankTypealiasDecl())
        }
        return super.visit(node)
    }
    override public func visit(_ node: AssociatedtypeDeclSyntax) -> DeclSyntax {
        if shouldRemove(node.name, fullName: node.fullName, description: node.description, declType: node.declType) {
            return DeclSyntax(SyntaxFactory.makeBlankAssociatedtypeDecl())
        }
        return super.visit(node)
    }
    override public func visit(_ node: EnumCaseDeclSyntax) -> DeclSyntax {
        if shouldRemove(node.name, fullName: node.fullName, description: node.description, declType: node.declType) {
            return DeclSyntax(SyntaxFactory.makeBlankEnumCaseDecl())
        }
        return super.visit(node)
    }

    private func shouldRemove(_ name: String, fullName: String, description: String, declType: DeclType) -> Bool {
        let inList = decls.contains(where: { (d: DeclMetadata) -> Bool in
            return d.name == name && d.fullName == fullName && d.declDescription == description && d.declType == declType
        })
        return inList
    }
}
