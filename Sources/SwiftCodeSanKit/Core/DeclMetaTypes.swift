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
Decl metadata needed for decls in source code being parsed
*/

public typealias DeclMap = [String: [DeclMetadata]]

public enum DeclType {
    case protocolType, classType, extensionType, structType, enumType
    case typealiasType, patType
    case varType, subscriptType, funcType, initType, operatorType, enumCaseType
    case other
}

extension DeclType {
    var isEncloserType: Bool {
        if self == .protocolType ||
            self == .classType ||
            self == .extensionType ||
            self == .structType ||
            self == .enumType {
            return true
        }
        return false
    }
}

public final class DeclMetadata: Hashable {
    let name: String
    var type: String
    let fullName: String
    let declType: DeclType
    var inheritedTypes: [String]
    let boundTypes: [String]
    let boundTypesAL: [String]
    var members: [DeclMetadata] = []

    let path: String
    let module: String
    let imports: [String]
    var encloser: String
    var declDescription: String
    var annotated: Bool = false

    var isOverride: Bool
    var isExtensionMember: Bool = false
    var isPublicOrOpen: Bool
    var shouldExpose: Bool = false
    var visited: Bool = false
    var used: Bool = false

    public func hash(into hasher: inout Hasher) {
        hasher.combine(fullName)
        hasher.combine(declType)
        hasher.combine(encloser)
        hasher.combine(path)
        hasher.combine(module)
    }

    public static func == (lhs: DeclMetadata, rhs: DeclMetadata) -> Bool {
        if lhs.name == rhs.name,
            lhs.type == rhs.type,
            lhs.fullName == rhs.fullName,
            lhs.declType == rhs.declType,
            lhs.encloser == rhs.encloser,
            lhs.path == rhs.path,
            lhs.module == rhs.module {
            return true
        }
        return false
    }

    public init(path: String,
                module: String,
                imports: [String],
                encloser: String,
                name: String,
                type: String, 
                fullName: String,
                description: String,
                declType: DeclType,
                inheritedTypes: [String],
                boundTypes: [String],
                boundTypesAL: [String],
                isPublicOrOpen: Bool,
                isOverride: Bool,
                annotated: Bool = false,
                used: Bool) {
        self.path = path
        self.module = module
        self.imports = imports
        self.encloser = encloser
        self.name = name
        self.type = type
        self.fullName = fullName
        self.declDescription = description
        self.declType = declType
        self.inheritedTypes = inheritedTypes
        self.boundTypes = boundTypes
        self.boundTypesAL = boundTypesAL
        self.annotated = annotated
        self.isPublicOrOpen = isPublicOrOpen
        self.isOverride = isOverride
    }
}

struct AnnotationMetadata {
    var module: String?
    var typeAliases: [String: String]?
    var varTypes: [String: String]?
}


public struct Whitelist {
    public let thresholdDays: Int?
    public let decls: [String]?
    public let declsPrefix: [String]?
    public let declsSuffix: [String]?
    public let modules: [String]?
    public let modulesPrefix: [String]?
    public let modulesSuffix: [String]?
    public let inheritedTypes: [String]?
    public let members: [String]?

    public init(thresholdDays: Int?,
                decls: [String]?,
                 declsPrefix: [String]?,
                 declsSuffix: [String]?,
                 modules: [String]?,
                 modulesPrefix: [String]?,
                 modulesSuffix: [String]?,
                 inheritedTypes: [String]?,
                 members: [String]?) {
        self.thresholdDays = thresholdDays
        self.decls = decls
        self.declsPrefix = declsPrefix
        self.declsSuffix = declsSuffix
        self.modules = modules
        self.modulesPrefix = modulesPrefix
        self.modulesSuffix = modulesSuffix
        self.inheritedTypes = inheritedTypes
        self.members = members
    }

    func declWhitelisted(name: String, isMember: Bool, module: String?, parents: [String]?, path: String?) -> Bool {
        if let module = module {
            if let list = modules, list.contains(module) {
                return true
            }

            if let list = modulesPrefix {
                let moduleHasPrefix = !list.filter{module.hasPrefix($0)}.isEmpty
                if moduleHasPrefix { return true }
            }

            if let list = modulesSuffix {
                let moduleHasSuffix = !list.filter{module.hasSuffix($0)}.isEmpty
                if moduleHasSuffix { return true }
            }
        }

        if let parents = parents, let list = inheritedTypes {
            let inParentsList = !list.filter{ parents.contains($0) }.isEmpty
            if inParentsList { return true }
        }

        if isMember {
            if let list = members, list.contains(name) { return true }
        } else {
            if let list = decls, list.contains(name) { return true }
            if let list = declsPrefix {
                let declHasPrefix = !list.filter { name.hasPrefix($0) }.isEmpty
                if declHasPrefix { return true }
            }

            if let list = declsSuffix {
                let declHasSuffix = !list.filter { name.hasSuffix($0) }.isEmpty
                if declHasSuffix { return true }
            }
        }

        return false
    }
}


public func flatten(declMap: DeclMap) -> DeclMap {
    var flatDeclMap = DeclMap()

    for (k, vals) in declMap {
        for v in vals {
            if flatDeclMap[k] == nil {
                flatDeclMap[k] = []
            }

            if flatDeclMap[k]?.contains(v) ?? false {
            } else {
                flatDeclMap[k]?.append(v)
            }

            for m in v.members {
                if flatDeclMap[m.name] == nil {
                    flatDeclMap[m.name] = []
                }
                flatDeclMap[m.name]?.append(m)
            }
        }
    }
    return flatDeclMap
}
