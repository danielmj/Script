//
//  Input.swift
//  cutjs
//
//  Created by Dan on 6/23/22.
//

import Foundation

enum InputError: Swift.Error {
    case invalidEntry
}

func readInput(prompt: LogMessage? = nil) -> String? {
    if let prompt = prompt {
        logf(prompt)
    }
    let handle = FileHandle.standardInput;
    let data = handle.availableData;
    let input = String(data: data, encoding: .utf8)
    return input?.trimmingCharacters(in: .whitespacesAndNewlines)
}

func promptConfirm(instruction: LogMessage, defaultYes: Bool = false) -> Bool {
    if defaultYes {
        logf("\(instruction) (Y/n)? ")
        if let selection = readInput(), selection.lowercased() == "n" {
            return false
        }
        return true
    }
    else {
        logf("\(instruction) (y/N)? ")
        if let selection = readInput(), selection.lowercased() == "y" {
            return true
        }
        return false
    }
}

func promptSelection(instruction: String, items: [String]) throws -> String? {
    log("\n\(instruction) [^d when finished]):")
    for i in 0..<items.count {
        log("\(i+1). \(items[i])")
    }
    logf("> ")
    
    guard let selection = readInput(), selection.count > 0 else {
        return nil
    }
    
    guard var index = Int(selection) else {
        throw InputError.invalidEntry
    }
    
    index -= 1
    if index >= 0, index < items.count {
        return items[index]
    }
    else {
        throw InputError.invalidEntry
    }
}
