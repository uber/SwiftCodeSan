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
import ArgumentParser
import SwiftCodeSanKit

struct Executor: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "SwiftCodeSan", abstract: "SwiftCodeSan: Code Sanitizer for Swift.")

    private enum Operation: EnumerableFlag {
        case removeDeadcode
        case removeUnusedImports
        case updateAccessLevels

        static func help(for value: Executor.Operation) -> ArgumentHelp? {
            switch value {
            case .removeDeadcode:
                return "If set, it will remove dead code and generate a report in the logfile. If an --in-place option is set, files will be modified directly."
            case .removeUnusedImports:
                return "If set, it will remove unused import statements and generate a report in the logfile. If an --in-place option is set, files will be modified directly."
            case .updateAccessLevels:
                return "If set, it will remove unnecessary public or open access levels from decls and generate a report in the logfile. If an --in-place option is set, files will be modified directly."
            }
        }
    }

    // MARK: - Private
    @Option(name: [.long, .customShort("v")],
            help: "The logging level to use. Default is set to 0 (info only). Set 1 for verbose, 2 for warning, and 3 for error.")
    private var loggingLevel: Int = 0
    @Option(name: .customLong("logfile"),
            help: "Log file path containing the analysis results. If no value is given, it will be saved to a tmp file.",
            completion: .file())
    private var logFilePath: String?
    @Option(name: [.customLong("files-to-modules"), .short],
            parsing: .upToNextOption,
            help: "File paths each containing a map of source files and corresponding module names.",
            completion: .file())
    private var fileLists: [String] = []
    @Option(name: .customLong("syslib-list"),
            parsing: .upToNextOption,
            help: "File paths each containing a list of (weak) system frameworks.",
            completion: .file())
    private var syslibLists: [String] = []
    @Option(name: .customLong("test-list"),
            parsing: .upToNextOption,
            help: "File paths each containing a list of test files.",
            completion: .file())
    private var testFileLists: [String] = []
    @Option(name: [.long, .short],
            help: "The root path. If given, it will be prepended to the source file paths.",
            completion: .file())
    private var root: String?
    @Option(name: [.long, .customShort("j")],
            help: "Maximum number of threads to execute concurrently (default = number of cores on the running machine)")
    private var concurrencyLimit: Int?

    @Option(name: [.long, .short],
            parsing: .upToNextOption,
            help: "List of declarations to whitelist (separated by a comma or a space)",
            completion: .file())
    private var whitelistDecls: [String] = []
    @Option(name: .long,
            parsing: .upToNextOption,
            help: "List of declarations with given prefixes to whitelist (separated by a comma or a space)",
            completion: .file())
    private var whitelistDeclsPrefix: [String] = []
    @Option(name: .long,
            parsing: .upToNextOption,
            help: "List of declarations with given suffixes to whitelist (separated by a comma or a space).",
            completion: .file())
    private var whitelistDeclsSuffix: [String] = []
    @Option(name: .long,
            parsing: .upToNextOption,
            help: "List of declarations with given parent types to whitelist (separated by a comma or a space).",
            completion: .file())
    private var whitelistParents: [String] = []
    @Option(name: .long,
            parsing: .upToNextOption,
            help: "List of declarations in the given modules to whitelist (separated by a comma or a space).",
            completion: .file())
    private var whitelistModules: [String] = []
    @Option(name: .long,
            parsing: .upToNextOption,
            help: "List of declarations in the modules with given prefixes to whitelist (separated by a comma or a space).",
            completion: .file())
    private var whitelistModulesPrefix: [String] = []
    @Option(name: .long,
            parsing: .upToNextOption,
            help: "List of declarations in the modules with given suffixes to whitelist (separated by a comma or a space).",
            completion: .file())
    private var whitelistModulesSuffix: [String] = []
    @Option(name: .long,
            parsing: .upToNextOption,
            help: "List of member declarations with given names to whitelist (separated by a comma or a space).",
            completion: .file())
    private var whitelistMembers: [String] = []
    @Option(name: [.long, .short],
            help: "If set, files modified within the set number of days (leading up to today) will be whitelisted, i.e. all declarations in such files will be whitelisted.")
    private var thresholdDays: Int?

    @Flag private var operation: Operation
    @Option(name: .customLong("remove-annotation"),
            help: "If set, it will remove the annotation passed in from decls and generate a report in the logfile. If an --in-place option is set, files will be modified directly. ")
    private var deleteAnnotation: String?
    @Flag(name: [.customLong("in-place"), .short],
          help: "If set, given source files will be modified with results.")
    private var inplace: Bool = false
    @Flag(name: .customLong("in-place-tests"),
          help: "If set, given test files will be modified with results.")
    private var inplaceTests: Bool = false
    @Flag(name: .long,
          help: "If set, only top level decls will be parsed/used for analysis.")
    private var topDeclsOnly: Bool = false

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

    mutating func run() throws {
        minLogLevel = loggingLevel

        var filesToModules = [String: String]()
        fileLists.forEach { arg in
            let line = arg.components(separatedBy: ":")
            if let key = line.first, let val = line.last {
                filesToModules[key] = val
            }
        }
        
        let whitelist = Whitelist(thresholdDays: thresholdDays,
                                  decls: whitelistDecls,
                                  declsPrefix: whitelistDeclsPrefix,
                                  declsSuffix: whitelistDeclsSuffix,
                                  modules: [whitelistModules, syslibLists].compactMap{$0}.flatMap{$0},
                                  modulesPrefix: whitelistModulesPrefix,
                                  modulesSuffix: whitelistModulesSuffix,
                                  inheritedTypes: whitelistParents,
                                  members: whitelistMembers)

        execute(with: filesToModules,
                nil,
                root,
                logFilePath,
                inplace,
                inplaceTests,
                topDeclsOnly,
                concurrencyLimit,
                whitelist,
                operation,
                deleteAnnotation)
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
                         _ operation: Operation,
                         _ deleteAnnotation: String?) {

        switch operation {
        case .removeUnusedImports:
            removeUnusedImports(fileToModuleMap: filesToModules,
                                whitelist: whitelist,
                                topDeclsOnly: topDeclsOnly,
                                inplace: inplace,
                                logFilePath: logfile,
                                concurrencyLimit: jobs)
        case .removeDeadcode:
            removeDeadDecls(filesToModules: filesToModules,
                            whitelist: whitelist,
                            topDeclsOnly: topDeclsOnly,
                            inplace: inplace,
                            testFiles: testfiles,
                            inplaceTests: inplaceTests,
                            logFilePath: logfile,
                            concurrencyLimit: jobs,
                            onCompletion: {})
        case .updateAccessLevels:
            updateAccessLevels(filesToModules: filesToModules,
                               whitelist: whitelist,
                               inplace: inplace,
                               concurrencyLimit: jobs,
                               onCompletion: {})
        }
    }
}
