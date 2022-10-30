//
//  Dictionary+Common.swift
//  cutjs
//
//  Created by Dan on 6/23/22.
//

import Foundation

extension Dictionary where Key == String {

    subscript(caseInsensitive key: Key) -> Value? {
        get {
            if let k = keys.first(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                return self[k]
            }
            return nil
        }
        set {
            if let k = keys.first(where: { $0.caseInsensitiveCompare(key) == .orderedSame }) {
                self[k] = newValue
            } else {
                self[key] = newValue
            }
        }
    }
    
    func asyncMap<T>(_ block: (_ key: Key, _ value: Value) async throws -> T) async rethrows -> [T] {
        var result = [T]()
        for (key, value) in self {
            result.append(try await block(key,value))
        }
        return result
    }
    
    func invert() -> [Value: Key] where Value: Hashable {
        var result = [Value: Key]()
        for (key, value) in self {
            result[value] = key
        }
        return result
    }

}
