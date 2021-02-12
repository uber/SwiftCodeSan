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

var alphanumericSet = CharacterSet.alphanumerics

extension String {
    static public let `final` = "final"
    static let override = "override"
    static let unknownVal = "Unknown"
    static let prefix = "prefix"
    static let `public` = "public"
    static let `open` = "open"
    static let `internal` = "internal"
    static let `required` = "required"
    static let `convenience` = "convenience"
    static let moduleColon = "module:"
    static let typealiasColon = "typealias:"
    static let rxColon = "rx:"
    static let varColon = "var:"
    static let annotationArgDelimiter = ";"
    static let transparent = "@_transparent"
    static let propertyWrapper = "propertyWrapper"
    
    var raw: String {
        if hasPrefix("`"), hasSuffix("`") {
            var val = dropFirst()
            val = val.dropLast()
            return String(val)
        }
        return self
    }
    
    func arguments(with delimiter: String) -> [String: String]? {
        let argstr = self
        let args = argstr.components(separatedBy: delimiter)
        var argsMap = [String: String]()
        for item in args {
            let keyVal = item.components(separatedBy: "=").map{$0.trimmed}
            
            if let k = keyVal.first {
                if k.contains(":") {
                    break
                }
                
                if let v = keyVal.last {
                    argsMap[k] = v
                }
            }
        }
        return !argsMap.isEmpty ? argsMap : nil
    }
    
    public var trimmed: String {
        return self.trimmingCharacters(in: .whitespaces)
    }
    
    var isAlphanumeric: Bool {
        let ret = self.unicodeScalars.filter {alphanumericSet.contains($0) || $0 == "_"}
        return !ret.isEmpty
    }
    
    var isPublicOrOpen: Bool {
        return self == .public || self == .open
    }
}

