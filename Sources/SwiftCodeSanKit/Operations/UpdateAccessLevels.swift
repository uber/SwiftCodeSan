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

public func updateAccessLevels(filesToModules: [String: String],
                               whitelist: Whitelist?,
                               inplace: Bool,
                               logFilePath: String? = nil,
                               concurrencyLimit: Int? = nil,
                               onCompletion: @escaping () -> ()) {
    
    scanConcurrencyLimit = concurrencyLimit
    let p = DeclParser()
    var pathToDeclsUpdate = [String: [DeclMetadata]]()
    
    log("Scan and map top-level decls...")
    logTime()
    let declMap = p.scanAndMapDecls(fileToModuleMap: filesToModules,
                                    topDeclsOnly: false,
                                    whitelist: whitelist)
    
    logTime()
    
    log("Check references, look up their source modules, and mark visibility...")
    p.checkRefs(fileToModuleMap: filesToModules, declMap: declMap) { (path, refs, imports) in
        if let refModule = filesToModules[path] {
            markVisiblity(refs, in: refModule, imports: imports, with: declMap, updateMembers: true)
        }
    }
    
    logTime()
    
    log("Update ALs (access levels) of top-level decls and their bound types...")
    updateBoundTypeALs(declMap: declMap)
    resetVisited(declMap: declMap)
    
    log("Update ALs of member decls of interfaces (protocol / base class)...")
    updateMemberALs(declMap: declMap)
    
    logTime()
    
    log("Flatten decls, and check references again, for member decls...")
    var nref = 0
    let flatDeclMap = flatten(declMap: declMap)
    p.checkRefs(fileToModuleMap: filesToModules, declMap: flatDeclMap) { (path, refs, imports) in
        if let refModule = filesToModules[path] {
            markVisiblity(refs, in: refModule, imports: imports, with: flatDeclMap, updateMembers: false)
        }
        log(counter: &nref, interval: 1000)
    }
    log(nref)
    
    logTime()
    
    log("Update ALs of all decls and their bound types...")
    updateBoundTypeALs(declMap: flatDeclMap)
    resetVisited(declMap: flatDeclMap)
    
    var i = -1
    var j = 0
    
    while i != j {
        log("If bound types are modified, update their member ALs as well...")
        updateMemberALs(declMap: declMap)
        i = flatDeclMap.values.flatMap{$0}.filter{$0.shouldExpose}.count
        
        log("Again, update ALs of of all decls and their bound types...")
        updateBoundTypeALs(declMap: flatDeclMap)
        resetVisited(declMap: flatDeclMap)
        j = flatDeclMap.values.flatMap{$0}.filter{$0.shouldExpose}.count
        
        log("#Remaining decls to update", i-j, i, j)
    }
    
    log("Save decls to update per files...")
    for (_, decls) in flatDeclMap {
        for decl in decls {
            if decl.isPublicOrOpen, !decl.shouldExpose {
                if pathToDeclsUpdate[decl.path] == nil {
                    pathToDeclsUpdate[decl.path] = []
                }
                pathToDeclsUpdate[decl.path]?.append(decl)
            }
        }
    }
    
    if let logfile = logFilePath {
        log("Save results to", logfile)
        let ret = pathToDeclsUpdate.map {"\($0.key): \($0.value.map{$0.name + ", " + $0.encloser}.joined(separator: "\n"))"}.joined(separator: "\n")
        try? ret.write(toFile: logfile, atomically: true, encoding: .utf8)
    }
    
    if inplace {
        log("Update decl ALs in files...")
        let updater  = DeclUpdater()
        updater.updateAccessLevels(filesToDecls: pathToDeclsUpdate, filesToModules: filesToModules) { (path, content) in
            try? content.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }
    logTime()
    
    let total = pathToDeclsUpdate.values.flatMap{$0}.count
    log("#Total top-level decls: ", declMap.count, "#Total decls", flatDeclMap.count, "#Decls updated", total, "#Files updated", pathToDeclsUpdate.count)
    logTotalElapsed("Done")
    
    onCompletion()
}


// MARK - private functions

private func updateBoundTypeALs(declMap: DeclMap) {
    for (k, decls) in declMap {
        if !k.isEmpty {  // Empty means expr or stmt
            for decl in decls {
                if (decl.isPublicOrOpen && decl.shouldExpose) ||
                    decl.declType == .extensionType ||
                    decl.isExtensionMember {
                    decl.visited = true
                    updateBoundTypeALs(decl, level: 0, declMap: declMap)
                }
            }
        }
    }
}

private func updateBoundTypeALs(_ decl: DeclMetadata, level: Int, declMap: DeclMap) {
    
    for boundType in decl.boundTypesAL {
        if !boundType.isEmpty {
            var bases: [String]?
            var leaf: String?
            if boundType.contains(".") {
                bases = boundType.components(separatedBy: ".")
                leaf = bases?.removeLast()
            }
            
            let key = leaf ?? boundType
            
            if let boundDecls = declMap[key] {
                for boundDecl in boundDecls {
                    if boundDecl.visited, boundDecl.shouldExpose {
                        continue
                    }
                    boundDecl.visited = true
                    if decl.module == boundDecl.module || decl.imports.contains(boundDecl.module) {
                        boundDecl.shouldExpose = true
                        updateBoundTypeALs(boundDecl, level: level + 1, declMap: declMap)
                    }
                }
            }
        }
    }
}

private func updateMemberALs(declMap: DeclMap) {
    for (_, vals) in declMap {
        for cur in vals {
            var members = [DeclMetadata]()
            var interfaceMembers = [DeclMetadata]()
            let level = 0
            
            updateBoundMemberALs(key: cur, declMap: declMap, level: level, members: &members, interfaceMembers: &interfaceMembers)
        }
    }
}

private func updateBoundMemberALs(key cur: DeclMetadata,
                                  declMap: DeclMap,
                                  level: Int,
                                  members: inout [DeclMetadata],
                                  interfaceMembers: inout [DeclMetadata]) {
    
    // First resolve inheritance (loop up protocol conformance, subclassing, and update member ALs)
    var parents = cur.inheritedTypes
    let curIsExtension = cur.declType == .extensionType
    if curIsExtension {
        parents.append(cur.name)
    }
    resolveInheritance(key: cur, inheritedTypes: parents, declMap: declMap, level: level, members: &members, interfaceMembers: &interfaceMembers)
    
    let interfaceMemberNames = interfaceMembers.map{$0.name}
    for member in members {
        if interfaceMemberNames.contains(member.name) {
            if member.isPublicOrOpen || (curIsExtension && cur.isPublicOrOpen) {
                member.shouldExpose = true
                
                // If encloser is extension, it should be also exposed since its member is public/exposed
                if curIsExtension, !cur.shouldExpose {
                    cur.shouldExpose = true
                }
            }
        } else if member.isPublicOrOpen, member.isOverride {
            // This might be a member overriding stdlib api
            member.shouldExpose = true
        }
    }
    
    // For the following decl types, check bound types and update member ALs.
    if cur.declType == .extensionType || cur.declType == .enumType {
        
        var visitedCurrent = false
        let boundTypesAL = cur.boundTypesAL.filter{!cur.inheritedTypes.contains($0)}
        
        for boundType in boundTypesAL {
            if !boundType.isEmpty, cur.name != boundType, let boundTypeVals = declMap[boundType] {
                for boundDecl in boundTypeVals {
                    if !visitedCurrent,
                       boundDecl.isPublicOrOpen,
                       boundDecl.shouldExpose {
                        
                        for member in cur.members {
                            if member.isPublicOrOpen {
                                member.shouldExpose = true
                            }
                        }
                        visitedCurrent = true
                    }
                }
            } else if !visitedCurrent, cur.inheritedTypes.contains(boundType) {
                // If parent is not in declMap, assume it's in stdlib.
                for member in cur.members {
                    if member.isPublicOrOpen {
                        member.shouldExpose = true
                    }
                }
                visitedCurrent = true
            }
        }
        
        if visitedCurrent, !cur.shouldExpose {
            cur.shouldExpose = true
        }
    }
}


private func resolveInheritance(key cur: DeclMetadata,
                                inheritedTypes: [String]?,
                                declMap: DeclMap,
                                level: Int,
                                members: inout [DeclMetadata],
                                interfaceMembers: inout [DeclMetadata]) {
    
    let parents = inheritedTypes ?? cur.inheritedTypes
    var stdlibTypes = [String]()
    var userDefinedTypes = [String]()
    
    for parent in parents {
        if parent.isEmpty {
            continue
        }
        if let parentDecls = declMap[parent] {
            for parentDecl in parentDecls {
                if parentDecl.name.isEmpty {
                    continue
                }
                if parentDecl.declType == .protocolType || parentDecl.declType == .classType || parentDecl.declType == .typealiasType {
                    if parentDecl.isPublicOrOpen, parentDecl.shouldExpose {
                        if parentDecl.declType == .protocolType {
                            interfaceMembers.append(contentsOf: parentDecl.members)
                        } else if parentDecl.declType == .classType, cur.declType == .classType {
                            interfaceMembers.append(contentsOf: parentDecl.members)
                        }
                    }
                    
                    userDefinedTypes.append(parentDecl.name)
                    members.append(contentsOf: cur.members)
                    
                    let optionalInitialTypes = parentDecl.declType == .typealiasType ? parentDecl.boundTypesAL : nil
                    
                    resolveInheritance(key: parentDecl, inheritedTypes: optionalInitialTypes, declMap: declMap, level: level+1, members: &members,  interfaceMembers: &interfaceMembers)
                    
                } else if parentDecl.declType == .extensionType {
                    // Parent could be a user defined type or a stdlib type. Add to a list for now and filter out below.
                    stdlibTypes.append(parentDecl.name)
                }
            }
        } else {
            // If parent is not in declMap, assume it's in stdlib.
            stdlibTypes.append(parent)
        }
    }
    
    for stdlibType in stdlibTypes {
        if userDefinedTypes.contains(stdlibType) {
            continue
        }
        
        for member in cur.members {
            if member.isPublicOrOpen {
                interfaceMembers.append(member)
                members.append(member)
            }
        }
        break
    }
}

private func traverseMembers(_ bases: [String], _ i: Int, _ refModule: String,  _ imports: [String], declMap: DeclMap) -> Bool {
    let j = i + 1
    
    if j < bases.count {
        let cur = bases[i]
        let next = bases[j]
        if let prefixDecls = declMap[cur] {
            for prefixDecl in prefixDecls {
                var list: [DeclMetadata]?
                if prefixDecl.declType == .funcType ||
                    prefixDecl.declType == .operatorType ||  // This is handled here but shouldn't be member-accessed
                    prefixDecl.declType == .varType {
                    if let typeDecls = declMap[prefixDecl.type] {
                        for t in typeDecls {
                            list = t.members.filter{$0.name == next}
                        }
                    }
                } else {
                    list = prefixDecl.members.filter{$0.name == next}
                }
                
                if let list = list, !list.isEmpty {
                    let checked = traverseMembers(bases, i + 1, refModule, imports, declMap: declMap)
                    if checked, refModule != prefixDecl.module, imports.contains(prefixDecl.module) {
                        for member in list {
                            member.shouldExpose = true
                        }
                    }
                    
                } else {
                    return false
                }
            }
        }
    }
    return true
}

private func markVisiblity(_ refs: Set<String>, in refModule: String, imports: [String], with declMap: DeclMap, updateMembers: Bool) {
    // Leaf level node checks
    for r in refs {
        
        var bases: [String]?
        var leaf: String?
        
        if r.contains(".") {
            bases = r.components(separatedBy: ".")
        }
        
        // First, traverse member access, and update visibility along the way
        var accessedMembers = false
        if let bases = bases {
            accessedMembers = traverseMembers(bases, 0, refModule, imports, declMap: declMap)
        }
        if accessedMembers {
            continue
        }
        
        leaf = bases?.removeLast()
        let refKey = leaf ?? r
        
        // If above fails (e.g. encloser type is not found), or non-member access, try following
        if let refDecls = declMap[refKey] {
            for refDecl in refDecls {
                if true ||
                    refDecl.isPublicOrOpen ||
                    refDecl.declType == .extensionType ||
                    refDecl.isExtensionMember {
                    
                    // multi modules w/ same decls (foo):
                    // 1. shadowing: if ref'd, it uses a decl in the same module even if the others are imported.
                    //      - if foo from another module should be called, it's required to use qualifier X.foo
                    // 2. if not decl's in the same module as ref, uses corresponding modules, so need to look up imports
                    // 3. if foo inits are the same for multi-modules:
                    //     - need qualifier X.foo
                    if refModule == refDecl.module {
                        // r is either declared internally
                        // so r should not be public, so add [decl.path: r] to pathToUpdateDecls
                    } else {
                        // look up imports and check decl.module is in the imports, then decl.shouldBePublic = true, so do nothing.
                        if imports.contains(refDecl.module) {
                            
                            if !refDecl.encloser.isEmpty {
                                // If it has an encloser (part of a class, protocol, etc),
                                // check if the encloser is in ref'd.
                                // Encloser type might not be listed, leakdetect.inst.accumulatedLeaksStream
                                refDecl.shouldExpose = true
                            } else {
                                // then r in decl.module should remain public
                                refDecl.shouldExpose = true
                            }
                        } else {
                            // r must be part of stdlib, handled in updateMemberALs above.
                        }
                    }
                    
                }
            }
        }
    }
}


private func shouldMatchACLForMembers(_ declType: DeclType) -> Bool {
    return declType == .protocolType ||
        declType == .extensionType ||
        declType == .enumType
}

private func resetVisited(declMap: DeclMap) {
    for (_, decls) in declMap {
        for decl in decls {
            decl.visited = false
        }
    }
}
