# ![](Images/logo.png)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/2964/badge)](https://bestpractices.coreinfrastructure.org/projects/2964)
[![Build Status](https://github.com/uber/SwiftCodeSan/workflows/CI/badge.svg)](https://github.com/uber/SwiftCodeSan/actions)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fuber%2FSwiftCodeSan.svg?type=shield)](https://app.fossa.com/projects/git%2Bgithub.com%2Fuber%2FSwiftCodeSan?ref=badge_shield)

# Welcome to SwiftCodeSan

**SwiftCodeSan** is a tool that "sanitizes" code written in Swift.  It has support for removing dead code (unreferenced decls) and unused imports, and narrowing access levels (public to internal), which will not only help clean up the codebase but also reduce the build time and the binary size. 

It uses `SwiftSyntax` for parsing and uses concurrency for faster performance.  Unlike other tools, `SwiftCodeSan` does not involve compiling; it handles reference checks directly. This eliminates the need to compile the entire project before running an analysis, which can take a long time for codebases like Uber's (~3M LoC).

Main objectives of `SwiftCodeSan` are accuracy, performance, and ease of use.  It's a lightweight commandline tool, which uses the `SwiftCodeSanKit` framework underneath. It can be used as a standalone tool or integrated into other tools such as a linter.  Try `SwiftCodeSan` and clean up your codebase, and see an improvement in the code quality and the build time.


## Motivation

Main objectives of `SwiftCodeSan` are accuracy, performance, flexibility, and ease of use. There aren't many 3rd party tools that perform fast on a large codebase containing, for example, over 3M LoC.  They require building the entire projects on Xcode (for index stores), and take several hours to run analyses. The results contain false postives and negatives. They don't provide support to modify files directly with the results, and lack features such as finding unused imports or redundant access levels.  

`SwiftCodeSan` was built for scalability and performance so running analyses takes a few minutes instead of hours. Since it does not require compiling the codebase, it can also run on code being developed with any IDEs (not just Xcode). It's a lightweight commandline tool, and uses a minimal set of frameworks necessary (see the Used Libraries below) to keep the code lean and efficient. It provides an input option to directly modify files with results, and features other than removing dead code, such as updating access levels and removing unused import statments. 


## Disclaimer
This project may contain unstable APIs which may not be ready for general use. Support and/or new releases may be limited.


## System Requirements

* Swift 5.3 or later
* Xcode 12.0 or later
* MacOS 10.15.4 or later
* Support is included for the Swift Package Manager


## Build / Install

Option 1: Clone and build 

```
$ git clone https://github.com/uber/SwiftCodeSan.git
$ cd SwiftCodeSan
$ swift build -c release
$ .build/release/SwiftCodeSan -h  // see commandline input options below 
```

Instead of calling the binary `SwiftCodeSan` built in `.build/release`, you can copy the executable into a directory that is part of your `PATH` environment variable and call `SwiftCodeSan`.

Or use Xcode, via following.

```
$ swift package generate-xcodeproj
```

## Run

`SwiftCodeSan` is a commandline executable. To run it, pass in a list of the source file directories or file paths of a build target, and the destination filepath for the mock output. To see other arguments to the commandline, run `SwiftCodeSan --help`.

```
./SwiftCodeSan --files-to-modules [file_to_module_list] --remove-deadcode --in-place
```
The `file_to_module_list` contains a map of source file paths to corresponding module names.  Other input options are `--remove-unused-imports` and `--update-access-levels`.  If `--in-place` is set, files will be modified directly. 

Use --help to see the complete list of argument options.


## Add SwiftCodeSanKit to your project

Option 1: SPM 
```swift

dependencies: [
    .package(url: "https://github.com/uber/SwiftCodeSan.git", from: "0.0.1"),
],
targets: [
    .target(name: "MyTarget", dependencies: ["SwiftCodeSanKit"]),
]

```


## Distribution 

The `install-script.sh` will build and package up the `SwiftCodeSan` binary and other necessary resources in the same bundle. 

```
$ ./install-script.sh -h  // see input options 
$ ./install-script.sh -s [source dir] -t SwiftCodeSan -d [destination dir] -o [output filename]
```

This will create a tarball for distribution, which contains the `SwiftCodeSan` executable along with a necessary SwiftSyntax parser dylib (lib_InternalSwiftSyntaxParser.dylib). This allows running `SwiftCodeSan` without depending on where the dylib lives. 




## Used libraries

[SwiftSyntax](https://github.com/apple/swift-syntax) | 
[SPM](https://github.com/swift-package-manager)


## How to contribute to SwiftCodeSan

See [CONTRIBUTING](CONTRIBUTING.md) for more info.

## Report any issues

If you run into any problems, please file a git issue. Please include:

* The OS version (e.g. macOS 10.15.6)
* The Swift version installed on your machine (from `swift --version`)
* The Xcode version
* The specific release version of this source code (you can use `git tag` to get a list of all the release versions or `git log` to get a specific commit sha)
* Any local changes on your machine



## License

SwiftCodeSan is licensed under Apache License 2.0. See [LICENSE](LICENSE.txt) for more information.

    Copyright (C) 2017 Uber Technologies

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
