//
//  Array+Common.swift
//  cutjs
//
//  Created by Dan on 6/23/22.
//

import Foundation

extension Array where Element: Hashable {
    
    func makeSet() -> Set<Element> {
        var result = Set<Element>()
        for item in self {
            result.insert(item)
        }
        return result
    }
    
    func asyncMap<T>(_ block: (Element) async throws -> T) async rethrows -> [T] {
        var result = [T]()
        for element in self {
            result.append(try await block(element))
        }
        return result
    }
    
}

extension Array {
    
    func mapDictionary<T,K>(block: (Element) -> [T: K]) -> [T:K] {
        var result = [T:K]()
        for element in self {
            let blockResult = block(element)
            for item in blockResult {
                result[item.key] = item.value
            }
        }
        return result
    }
    
    func joinDictionary<T,K>(block: (Element) -> (key:T, value:K)) -> [T:[K]] {
        var result = [T:[K]]()
        for element in self {
            let blockResult = block(element)
            var newElem = result[blockResult.key] ?? []
            newElem.append(blockResult.value)
            result[blockResult.key] = newElem
        }
        return result
    }
    
    func safe(_ index: Int) -> Element? {
        if index >= 0 && index < self.count {
            return self[index]
        }
        return nil
    }
    
}
