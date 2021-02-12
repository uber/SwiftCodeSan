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
import TSCUtility
import SwiftCodeSanKit

class Executor {
    // MARK: - Private
    private var loggingLevel: OptionArgument<Int>!
    private var logFilePath: OptionArgument<String>!
    private var fileLists: OptionArgument<[String]>!
    private var syslibLists: OptionArgument<[String]>!
    private var testFileLists: OptionArgument<[String]>!
    private var srcRoot: OptionArgument<String>!
    private var concurrencyLimit: OptionArgument<Int>!

    private var whitelistDecls: OptionArgument<[String]>!
    private var whitelistDeclsPrefix: OptionArgument<[String]>!
    private var whitelistDeclsSuffix: OptionArgument<[String]>!
    private var whitelistParents: OptionArgument<[String]>!
    private var whitelistModules: OptionArgument<[String]>!
    private var whitelistModulesPrefix: OptionArgument<[String]>!
    private var whitelistModulesSuffix: OptionArgument<[String]>!
    private var whitelistMembers: OptionArgument<[String]>!
    private var thresholdDays: OptionArgument<Int>!

    private var deleteDeadCode: OptionArgument<Bool>!
    private var deleteUnusedImports: OptionArgument<Bool>!
    private var shouldUpdateAccessLevels: OptionArgument<Bool>!
    private var deleteAnnotation: OptionArgument<String>!
    private var inplace: OptionArgument<Bool>!
    private var inplaceTests: OptionArgument<Bool>!
    private var topDeclsOnly: OptionArgument<Bool>!


    /// Initializer.
    ///
    /// - parameter name: The name used to check if this command should
    /// be executed.
    /// - parameter overview: The overview description of this command.
    /// - parameter parser: The argument parser to use.
    init(parser: ArgumentParser) {
        setupArguments(with: parser)
    }

    /// Setup the arguments using the given parser.
    ///
    /// - parameter parser: The argument parser to use.
    private func setupArguments(with parser: ArgumentParser) {
        loggingLevel = parser.add(option: "--logging-level",
                                  shortName: "-v",
                                  kind: Int.self,
                                  usage: "The logging level to use. Default is set to 0 (info only). Set 1 for verbose, 2 for warning, and 3 for error.")
        logFilePath = parser.add(option: "--logfile",
                                 kind: String.self,
                                 usage: "Log file path containing the analysis results. If no value is given, it will be saved to a tmp file.",
                                 completion: .filename)
        fileLists = parser.add(option: "--files-to-mouldes",
                               shortName: "-f",
                               kind: [String].self,
                               usage: "File paths each containing a map of source files and corresponding module names.",
                               completion: .filename)
        syslibLists = parser.add(option: "--syslib-list",
                                 kind: [String].self,
                                 usage: "File paths each containing a list of (weak) system frameworks.",
                                 completion: .filename)
        testFileLists = parser.add(option: "--test-list",
                                   kind: [String].self,
                                   usage: "File paths each containing a list of test files.",
                                   completion: .filename)
        srcRoot = parser.add(option: "--root",
                             shortName: "-r",
                             kind: String.self,
                             usage: "The root path. If given, it will be prepended to the source file paths.",
                             completion: .filename)
        topDeclsOnly = parser.add(option: "--top-decls-only",
                                  kind: Bool.self,
                                  usage: "If set, only top level decls will be parsed/used for analysis.",
                                  completion: .filename)
        inplace = parser.add(option: "--in-place",
                             shortName: "-i",
                             kind: Bool.self,
                             usage: "If set, given source files will be modified with results.",
                             completion: .filename)
        inplaceTests = parser.add(option: "--in-place-tests",
                                  kind: Bool.self,
                                  usage: "If set, given test files will be modified with results.",
                                  completion: .filename)
        whitelistDecls = parser.add(option: "--whitelist-decls",
                                    shortName: "-w",
                                    kind: [String].self,
                                    usage: "List of declarations to whitelist (separated by a comma or a space).",
                                    completion: .filename)
        whitelistDeclsPrefix = parser.add(option: "--whitelist-decls-prefix",
                                          kind: [String].self,
                                          usage: "List of declarations with given prefixes to whitelist (separated by a comma or a space).",
                                          completion: .filename)
        whitelistDeclsSuffix = parser.add(option: "--whitelist-decls-suffix",
                                          kind: [String].self,
                                          usage: "List of declarations with given suffixes to whitelist (separated by a comma or a space).",
                                          completion: .filename)
        whitelistParents = parser.add(option: "--whitelist-parents",
                                      kind: [String].self,
                                      usage: "List of declarations with given parent types to whitelist (separated by a comma or a space).",
                                      completion: .filename)
        whitelistModules = parser.add(option: "--whitelist-modules",
                                      kind: [String].self,
                                      usage: "List of declarations in the given modules to whitelist (separated by a comma or a space).",
                                      completion: .filename)
        whitelistModulesPrefix = parser.add(option: "--whitelist-modules-prefix",
                                            kind: [String].self,
                                            usage: "List of declarations in the modules with given prefixes to whitelist (separated by a comma or a space).",
                                            completion: .filename)
        whitelistModulesSuffix = parser.add(option: "--whitelist-modules-suffix",
                                            kind: [String].self,
                                            usage: "List of declarations in the modules with given suffixes to whitelist (separated by a comma or a space).",
                                            completion: .filename)

        whitelistMembers = parser.add(option: "--whitelist-members",
                                      kind: [String].self,
                                      usage: "List of member declarations with given names to whitelist (separated by a comma or a space).",
                                      completion: .filename)
        thresholdDays = parser.add(option: "--threshold-days",
                                   shortName: "-t",
                                   kind: Int.self,
                                   usage: "If set, files modified within the set number of days (leading up to today) will be whitelisted, i.e. all declarations in such files will be whitelisted.")

        deleteDeadCode = parser.add(option: "--remove-deadcode",
                                    kind: Bool.self,
                                    usage: "If set, it will remove dead code and generate a report in the logfile. If an --in-place option is set, files will be modified directly. ")
        deleteUnusedImports = parser.add(option: "--remove-unused-imports",
                                         kind: Bool.self,
                                         usage: "If set, it will remove unused import statements and generate a report in the logfile. If an --in-place option is set, files will be modified directly. ")
        shouldUpdateAccessLevels = parser.add(option: "--update-access-levels",
                                              kind: Bool.self,
                                              usage: "If set, it will remove unnecessary public or open access levels from decls and generate a report in the logfile. If an --in-place option is set, files will be modified directly. ")
        deleteAnnotation = parser.add(option: "--remove-annotation",
                                      kind: String.self,
                                      usage: "If set, it will remove the annotation passed in from decls and generate a report in the logfile. If an --in-place option is set, files will be modified directly. ")
        concurrencyLimit = parser.add(option: "--concurrency-limit",
                                      shortName: "-j",
                                      kind: Int.self,
                                      usage: "Maximum number of threads to execute concurrently (default = number of cores on the running machine).")
    }

    private func fullPath(_ path: String) -> String {
        if path.hasPrefix("/") {
            return path
        }
        if path.hasPrefix("~") {
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            return path.replacingOccurrences(of: "~", with: home, range: path.range(of: "~"))
        }
        return FileManager.default.currentDirectoryPath + "/" + path
    }

    /// Execute the command.
    ///
    /// - parameter arguments: The command line arguments to execute the command with.

    func execute(with arguments: ArgumentParser.Result) {

        minLogLevel = arguments.get(self.loggingLevel) ?? 0

        let logfile = arguments.get(self.logFilePath)
        let jobs = arguments.get(self.concurrencyLimit)
        let root = arguments.get(self.srcRoot)
        let inplace = arguments.get(self.inplace) ?? false
        let inplaceTests = arguments.get(self.inplaceTests) ?? false
        let topDeclsOnly = arguments.get(self.topDeclsOnly) ?? false

        let deleteUnusedImports = arguments.get(self.deleteUnusedImports) ?? false
        let shouldUpdateAccessLevels = arguments.get(self.shouldUpdateAccessLevels) ?? false
        let deleteDeadCode = arguments.get(self.deleteDeadCode) ?? false
        let deleteAnnotation = arguments.get(self.deleteAnnotation)

        let whitelistDecls = arguments.get(self.whitelistDecls)
        let whitelistDeclsPrefix = arguments.get(self.whitelistDeclsPrefix)
        let whitelistDeclsSuffix = arguments.get(self.whitelistDeclsSuffix)
        let whitelistModules = arguments.get(self.whitelistModules)
        let whitelistModulesPrefix = arguments.get(self.whitelistModulesPrefix)
        let whitelistModulesSuffix = arguments.get(self.whitelistModulesSuffix)
        let whitelistParents = arguments.get(self.whitelistParents)
        let whitelistMembers = arguments.get(self.whitelistMembers)
//        let whitelistPathsInfix = arguments.get(self.whitelistPathsInfix)
        let thresholdDays = arguments.get(self.thresholdDays)

        let deps = arguments.get(self.fileLists) ?? []
        let syslibs = arguments.get(self.syslibLists) ?? []
        let testLists = arguments.get(self.testFileLists) ?? []

        // nonUserModules: syslib, objc, vendor modules
        guard let (filesToModules, nonUserModules) = parseDeps(root, deps, syslibs) else { return }
        let testfiles = parseTestFiles(root, testLists)

        let whitelist = Whitelist(thresholdDays: thresholdDays,
                                  pathsInfix: nil,
                                  decls: whitelistDecls,
                                  declsPrefix: whitelistDeclsPrefix,
                                  declsSuffix: whitelistDeclsSuffix,
                                  modules: [whitelistModules, nonUserModules].compactMap{$0}.flatMap{$0},
                                  modulesPrefix: whitelistModulesPrefix,
                                  modulesSuffix: whitelistModulesSuffix,
                                  inheritedTypes: whitelistParents,
                                  members: whitelistMembers)

        execute(with: filesToModules, testfiles,
                root, logfile, inplace, inplaceTests,
                topDeclsOnly, jobs, whitelist,
                deleteUnusedImports, shouldUpdateAccessLevels, deleteDeadCode, deleteAnnotation)
    }



    private func execute(with filesToModules: [String: String],
                         _ testfiles: [String]?,
                         _ root: String?,
                         _ logfile: String?,
                         _ inplace: Bool,
                         _ inplaceTests: Bool,
                         _ topDeclsOnly: Bool,
                         _ jobs: Int?,
                         _ whitelist: Whitelist?,
                         _ deleteUnusedImports: Bool,
                         _ shouldUpdateAccessLevels: Bool,
                         _ deleteDeadCode: Bool,
                         _ deleteAnnotation: String?) {

        if deleteUnusedImports {
            removeUnusedImports(fileToModuleMap: filesToModules,
                                whitelist: whitelist,
                                topDeclsOnly: topDeclsOnly,
                                inplace: inplace,
                                logFilePath: logfile,
                                concurrencyLimit: jobs)

        } else if deleteDeadCode {
            removeDeadDecls(filesToModules: filesToModules,
                            whitelist: whitelist,
                            topDeclsOnly: topDeclsOnly,
                            inplace: inplace,
                            testFiles: testfiles,
                            inplaceTests: inplaceTests,
                            logFilePath: logfile,
                            concurrencyLimit: jobs,
                            onCompletion: {})

        } else if shouldUpdateAccessLevels {
            updateAccessLevels(filesToModules: filesToModules,
                               whitelist: whitelist,
                               inplace: inplace,
                               concurrencyLimit: jobs,
                               onCompletion: {})

        } else if let annotation = deleteAnnotation {
            removeUnusedAnnotations(annotation: annotation,
                                    filesToModules: filesToModules,
                                    whitelist: whitelist,
                                    inplace: inplace,
                                    testFiles: testfiles,
                                    statsFile: logfile,
                                    concurrencyLimit: jobs)
        }
    }
}

// MARK - following should be in python

func parseSystemLibs(_ syslibLists: [String]) -> [String] {
    do {
        var list = [String]()
        for syslibList in syslibLists {
            let content = try String(contentsOfFile: syslibList)
            let comps = content.components(separatedBy: "\n").map{$0.trimmed}.filter{!$0.isEmpty}
            list.append(contentsOf: comps)
        }
        let sortedList = Set(list).sorted()
        return sortedList
    } catch {
        fatalError(error.localizedDescription)
    }
}

func parseTestFiles(_ rootPath: String?, _ files: [String]) -> [String] {
    do {
        let root = rootPath ?? ""
        var list = [String]()
        for f in files {
            let data = try Data(contentsOf: URL(fileURLWithPath: f))
            guard !data.isEmpty else { return [] }

            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let moduleToFiles = json as? [String: [String: [String]]] {
                for (prefix, val) in moduleToFiles {
                    if let filelist = val["srcs"] {
                        if let first = prefix.components(separatedBy: ":").first {
                            let files = filelist.filter{$0.hasSuffix(".swift")}.map { root + first.dropFirst(1) + "/" + $0 }
                            list.append(contentsOf: files)
                        }
                    }
                }
            }
        }
        return list
    } catch {
        fatalError(error.localizedDescription)
    }
}

func parseFileToModuleMap(_ path: String) -> ([String: String], [String]) {

    do {
        var src2modules = [String: String]()
        var whitelist = [String]()
        let content = try String(contentsOfFile: path)
        let comps = content.components(separatedBy: "\n")
        for c in comps {
            let cs = c.components(separatedBy: ": ")
            if let f = cs.first, let m = cs.last {
                src2modules[f] = m
                if f.contains("/vendor/") {
                    whitelist.append(m)
                } else if !f.hasSuffix(".swift") {
                    whitelist.append(m)
                }
            }
        }
        let whitelistModules = Set(whitelist).sorted()
        return (src2modules, whitelistModules)
    } catch {
        fatalError(error.localizedDescription)
    }
}

func parseDeps(_ root: String?, _ depsFiles: [String], _ syslibFiles: [String]) -> ([String: String], [String])? {

    do {
        let rootPath = root ?? ""
        var filesToModules = [String: String]()
        var whitelist = [String]()

        for f in depsFiles {
            let data = try Data(contentsOf: URL(fileURLWithPath: f))
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let m2f = json as? [String: [String]] {
                for (m, files) in m2f {
                    if files.isEmpty {  // srcs are null, the module could contain .h files with implementations
                        whitelist.append(m)
                        continue
                    }
                    for f in files {
                        if f.contains("/vendor/") {
                            whitelist.append(m)
                        } else if f.hasSuffix(".swift") {
                            let fbase = f.withoutExt

                            if fbase.hasSuffix("Mocks") {
                                if fbase.contains("ManualIdentityVerification") {
                                    //                                    mockFiles.append(root + "/" + f)
                                } else if fbase.contains("TestMocks") || fbase.contains("Manual") {
                                    filesToModules[rootPath + f] = m
                                } else {
                                    //                                    mockFiles.append(root + "/" + f)
                                }
                            } else if fbase.hasSuffix("VectorDrawables") || fbase.hasSuffix("Images") || fbase.hasSuffix("Strings") || f.contains("AnalyticsCodegen") || fbase.hasSuffix("Needle") {
                                // filter out
                            } else {
                                filesToModules[rootPath + f] = m
                            }
                        } else {
                            whitelist.append(m)
                        }
                    }
                }

                let syslibs = parseSystemLibs(syslibFiles)
                whitelist.append(contentsOf: syslibs)
            }
        }
        let whitelistedModuls = Set(whitelist).compactMap{$0}
        return (filesToModules, whitelistedModuls)
    } catch {
        fatalError(error.localizedDescription)
    }
}

