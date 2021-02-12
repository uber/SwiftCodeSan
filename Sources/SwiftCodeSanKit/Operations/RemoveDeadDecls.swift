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

public func removeDeadDecls(filesToModules: [String: String],
                            whitelist: Whitelist?,
                            topDeclsOnly: Bool,
                            inplace: Bool,
                            testFiles: [String]?,
                            inplaceTests: Bool,
                            logFilePath: String? = nil,
                            concurrencyLimit: Int? = nil,
                            onCompletion: @escaping () -> ()) {
    
    log("Start of removing dead code: topDeclsOnly", topDeclsOnly)
    scanConcurrencyLimit = concurrencyLimit
    let p = DeclParser()
    var pathToDeclsUpdate = [String: [DeclMetadata]]()
    
    log("Scan and map top-level decls...")
    logTime()
    let declMap = p.scanAndMapDecls(fileToModuleMap: filesToModules,
                                    topDeclsOnly: false,
                                    whitelist: whitelist)
    logTime()
    print("WWW: ", p.npaths, p.wpaths)
    
    log("Check references, look up their source modules, and mark used...")
    let flatDeclMap = flatten(declMap: declMap)
    var nref = 0
    p.checkRefs(fileToModuleMap: filesToModules, declMap: flatDeclMap) { (path, refs, imports) in
        if let refModule = filesToModules[path] {
            markUsed(refs, in: refModule, imports: imports, with: flatDeclMap, updateMembers: true)
        }

        log("#Checked refs", counter: &nref, interval: 1000, timed: true)
    }
    logTime()
    
    repeat {
        log("Look up interface members and mark used if any...")
        shouldRetry = false
        markInterfaceMembersUsed(declMap: declMap)
        logTime()
    } while shouldRetry
    var i = flatDeclMap.values.flatMap{$0}.filter{$0.used}.count

    log("Mark bound types used...")
    markBoundTypesUsed(declMap: flatDeclMap)
    resetVisited(declMap: declMap)
    var j = flatDeclMap.values.flatMap{$0}.filter{$0.used}.count
    logTime()
    
    while i != j {
        log("#Remaining decls to mark used", j-i, j, i)
        log("Repeat: Look up interface members and mark used if any...")
        markInterfaceMembersUsed(declMap: declMap)
        i = flatDeclMap.values.flatMap{$0}.filter{$0.used}.count
        logTime()
        
        log("Repeat: Mark bound types used...")
        markBoundTypesUsed(declMap: flatDeclMap)
        resetVisited(declMap: flatDeclMap)
        j = flatDeclMap.values.flatMap{$0}.filter{$0.used}.count
        logTime()
    }
    
    log("Filter out used decls...")
    for (_, decls) in flatDeclMap {
        for decl in decls {
            if !decl.used {
                if pathToDeclsUpdate[decl.path] == nil {
                    pathToDeclsUpdate[decl.path] = []
                }
                pathToDeclsUpdate[decl.path]?.append(decl)
            }
        }
    }
    
    let totalUnused = pathToDeclsUpdate.values.flatMap{$0}.count
    let totalUsed = flatDeclMap.values.flatMap{$0}.filter{$0.used}.count
    logTime()
    log("#Total top-level decls: ", declMap.values.flatMap{$0}.count,
        "#Total decls", flatDeclMap.values.flatMap{$0}.count,
        "#Decls Unused", totalUnused,
        "#Decls Used", totalUsed,
        "#Files to update", pathToDeclsUpdate.count)
    
    if let logfile = logFilePath {
        log("Save results to", logfile)

        let ret = pathToDeclsUpdate.map { arg in
            let vals = arg.value.map{ ObjectIdentifier($0).debugDescription  + ", " + $0.fullName + ", " + $0.encloser }
            let valStr = vals.joined(separator: "\n")
            return "\(arg.key)\n--- \(valStr)\n"
        }.joined(separator: "\n")
        try? ret.write(toFile: logfile, atomically: true, encoding: .utf8)
        logTime()
    }
    
    if inplace {
        log("Remove unused decls from files...", pathToDeclsUpdate.count)
        let updater = DeclUpdater()
        updater.removeDeadDecls(filesToDecls: pathToDeclsUpdate) { (path, content) in
            try? content.write(toFile: path, atomically: true, encoding: .utf8)
        }
        logTime()
    }
    
    logTotalElapsed("Done")
    
    onCompletion()
}


// MARK - private functions

private func markBoundTypesUsed(declMap: DeclMap) {
    for (k, decls) in declMap {
        if !k.isEmpty {  // Empty means expr or stmt
            for decl in decls {
                if decl.used {
                    decl.visited = true
                    markBoundTypesUsed(decl, level: 0, declMap: declMap)
                }
            }
        }
    }
}

private func markBoundTypesUsed(_ decl: DeclMetadata, level: Int, declMap: DeclMap) {
    
    for boundType in decl.boundTypes {
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
                    if boundDecl.visited, boundDecl.used {
                        continue
                    }
                    boundDecl.visited = true
                    if decl.module == boundDecl.module || decl.imports.contains(boundDecl.module) {
                        boundDecl.used = true
                        markBoundTypesUsed(boundDecl, level: level + 1, declMap: declMap)
                    }
                }
            }
        }
    }
}


var shouldRetry = false
private func markInterfaceMembersUsed(declMap: DeclMap) {
    var ndecls = 0
    scan(declMap) { (key, vals, lock) in
        for cur in vals {
            var members = [DeclMetadata]()
            var interfaceMembers = [DeclMetadata]()
            var userDefinedTypes = [String]()
            var stdlibTypes = [String]()
            let level = 0
            markBoundMembersUsed(key: cur, declMap: declMap, level: level, members: &members, interfaceMembers: &interfaceMembers,  userDefinedTypes: &userDefinedTypes, stdlibTypes: &stdlibTypes)
            log("#Marked used members", counter: &ndecls, interval: 10000, timed: true)
        }
    }

}

private func markBoundMembersUsed(key cur: DeclMetadata,
                                  declMap: DeclMap,
                                  level: Int,
                                  members: inout [DeclMetadata],
                                  interfaceMembers: inout [DeclMetadata],
                                  userDefinedTypes: inout [String],
                                  stdlibTypes: inout [String]) {

    // First resolve inheritance (loop up protocol conformance, subclassing, and update member ALs)
    var parents = cur.inheritedTypes
    let curIsExtension = cur.declType == .extensionType
    if curIsExtension {
        parents.append(cur.name)
    }
    resolveInheritance(key: cur, inheritedTypes: parents, declMap: declMap, level: level, members: &members, interfaceMembers: &interfaceMembers, userDefinedTypes: &userDefinedTypes, stdlibTypes: &stdlibTypes)

    let stdTypes = stdlibTypes.filter{!userDefinedTypes.contains($0)}

//    let should = cur.name == "TripInteractor" && cur.declType == .extensionType &&  cur.inheritedTypes.contains("TripActionableItem")
//    let should = cur.name == "RideInteractor" && cur.declType == .classType
    //    let should = (cur.name == "TransitTicketStreaming" && cur.declType == .protocolType) ||
    //                    (cur.name == "TransitTicketStream" && cur.declType == .classType)

    let x = cur.name == "CreditsAutoReloadSettingsPresentable" && (cur.declType == .protocolType || cur.declType == .extensionType)
    let y = cur.name == "ImageViewLoading"
    let should = x || y

    if should {
        print(cur.name, cur.declType, cur.used)
        let x = interfaceMembers.map{$0.fullName + ObjectIdentifier($0).debugDescription }
        let y = members.map{$0.fullName + ObjectIdentifier($0).debugDescription }
        print("-- INTERFACE members:", x)
        print("-- MEMBERS:", y)
    }


    for member in members {
        let matchingMembers = interfaceMembers.filter {$0.name == member.name}
        for matched in matchingMembers {
            if matched.used {
                member.used = true
            } else if member.used || member.isOverride {
                if !matched.used {
                    matched.used = true
                    shouldRetry = true
                }
            } else if !stdTypes.isEmpty {
                if !matched.used {
                    matched.used = true
                    shouldRetry = true
                }
                member.used = true
            }

            if should {
                print(cur.name, cur.declType)

                print("-- MATCHED:", matched.fullName, matched.used, ObjectIdentifier(matched))
                print("-- Member:", member.fullName, member.used, ObjectIdentifier(member))
            }
        }
        
        if matchingMembers.isEmpty, member.isOverride {
            // This might be a member overriding stdlib api
            member.used = true
        }
    }

    // For the following decl types, check bound types and update member ALs.
    if cur.declType == .extensionType || cur.declType == .enumType {
        if !cur.used {
            for m in cur.members {
                if m.used {
                    cur.used = true
                    break
                }
            }
        }
        
        if !cur.used {
            let boundTypes = cur.boundTypes.filter{!cur.inheritedTypes.contains($0)}
            for boundType in boundTypes {
                if boundType.isEmpty {
                    continue
                }
                if cur.name != boundType, let boundTypeVals = declMap[boundType] {
                    // even if boundtype is used, cur might not be used
                } else if cur.inheritedTypes.contains(boundType) {
                    // If parent is not in declMap, assume it's in stdlib.
                    for member in cur.members {
                        member.used = true
                        cur.used = true
                    }
                    if cur.used {
                        break
                    }
                }
            }
        }
    }
}

private func resolveInheritance(key cur: DeclMetadata,
                                inheritedTypes: [String]?,
                                declMap: DeclMap,
                                level: Int,
                                members: inout [DeclMetadata],
                                interfaceMembers: inout [DeclMetadata],
                                userDefinedTypes: inout [String],
                                stdlibTypes: inout [String]) {
    
    let parents = inheritedTypes ?? cur.inheritedTypes

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
//                    if parentDecl.used {
                        if parentDecl.declType == .protocolType {
                            interfaceMembers.append(contentsOf: parentDecl.members)
                        } else if parentDecl.declType == .classType, cur.declType == .classType {
                            interfaceMembers.append(contentsOf: parentDecl.members)
                        }
//                    }
                    
                    userDefinedTypes.append(parentDecl.name)
                    members.append(contentsOf: cur.members)
                    
                    let optionalInitialTypes = parentDecl.declType == .typealiasType ? parentDecl.boundTypes : nil
                    
                    resolveInheritance(key: parentDecl, inheritedTypes: optionalInitialTypes, declMap: declMap, level: level+1, members: &members,  interfaceMembers: &interfaceMembers, userDefinedTypes: &userDefinedTypes, stdlibTypes: &stdlibTypes)
                    
                } else if parentDecl.declType == .extensionType {
                    // Parent could be a user defined type or a stdlib type. Add to a list for now and filter out below.
                    stdlibTypes.append(parentDecl.name)
                    members.append(contentsOf: cur.members)
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

        interfaceMembers.append(contentsOf: cur.members)
        members.append(contentsOf: cur.members)
        break
    }
}

private func accessMembers(_ bases: [String], _ i: Int, _ refModule: String,  _ imports: [String], declMap: DeclMap) -> Bool {
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
                    
                    let accessed = accessMembers(bases, i + 1, refModule, imports, declMap: declMap)
                    
                    if accessed, (refModule == prefixDecl.module || imports.contains(prefixDecl.module)) {
                        for member in list {
                            member.used = true
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

private func markUsed(_ refs: Set<String>, in refModule: String, imports: [String], with declMap: DeclMap, updateMembers: Bool) {
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
            accessedMembers = accessMembers(bases, 0, refModule, imports, declMap: declMap)
        }
        if accessedMembers {
            continue
        }
        
        leaf = bases?.removeLast()
        let refKey = leaf ?? r
        
        // If above fails (e.g. encloser type is not found), or non-member access, try following
        if let refDecls = declMap[refKey] {
            for refDecl in refDecls {
                if refModule == refDecl.module || imports.contains(refDecl.module) || refDecl.isOverride {
                    refDecl.used = true
               }
            }

        }
    }
}

private func resetVisited(declMap: DeclMap) {
    for (_, decls) in declMap {
        for decl in decls {
            decl.visited = false
        }
    }
}
