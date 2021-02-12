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
import os.signpost

fileprivate let perfLog = OSLog(subsystem: "SwiftCodeSan", category: "PointsOfInterest")
fileprivate var prevTime: CFAbsoluteTime?
fileprivate var startTime: CFAbsoluteTime?

public var minLogLevel = 0

/// Logs status and other messages depending on the level provided
public enum LogLevel: Int {
    case verbose
    case info
    case warning
    case error
}

public func logTotalElapsed(_ arg: Any...) {
    let cur = CFAbsoluteTimeGetCurrent()
    if let startTime = startTime {
        print(arg, cur-startTime)
    } else {
        print("0.00")
    }
}

public func logTime(_ arg: Any...) {
    let cur = CFAbsoluteTimeGetCurrent()
    if let prevTime = prevTime {
        var str = arg
        let delta = (cur-prevTime)
        str.append("Took \(delta)")
        print(str)
    }
    prevTime = cur
    if startTime == nil {
        startTime = cur
    }
}

public func log(_ arg: Int, level: LogLevel = .info, interval: Int) {
    if arg > 0, arg % interval == 0 {
        log(arg, level: level)
    }
}

public func log(_ arg: Any..., level: LogLevel = .info, counter: inout Int, interval: Int, timed: Bool = false) {
    if counter > 0, counter % interval == 0 {
        log(arg, counter, level: level)
        if timed {
            logTime()
        }
    }
    counter += 1
}

public func log(_ arg: Any..., level: LogLevel = .info) {
    guard level.rawValue >= minLogLevel else { return }
    switch level {
    case .info, .verbose:
        print(arg)
    case .warning:
        print("WARNING: \(arg)")
    case .error:
        print("ERROR: \(arg)")
    }
}

public func signpost_begin(name: StaticString) {
    if minLogLevel == LogLevel.verbose.rawValue {
        os_signpost(.begin, log: perfLog, name: name)
    }
}

public func signpost_end(name: StaticString) {
    if minLogLevel == LogLevel.verbose.rawValue {
        os_signpost(.end, log: perfLog, name: name)
    }
}
