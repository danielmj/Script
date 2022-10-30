//
//  Defaults.swift
//  cutjs
//
//  Created by Dan on 6/23/22.
//

import Foundation

enum AssertionError: Error {
    case invalidUser
}

func assertNotRoot() throws {
    guard getuid() != 0 else {
        print("Error: Cannot run as root user")
        throw AssertionError.invalidUser
    }
}

struct Defaults {
    
    enum Domain: String {
        case cutjs = "com.apple.cutjs"
    }
    
    enum Key: String {
        case lastUsername
    }
    
    static func getBool(key: Key, domain: Domain) throws -> Bool? {
        try assertNotRoot()
        var exists: DarwinBoolean = false
        let value = CFPreferencesGetAppBooleanValue(key.rawValue as CFString, domain.rawValue as CFString, &exists)
        if !exists.boolValue {
            return nil
        }
        return value
    }
    
    static func getInt(key: Key, domain: Domain) throws -> Int? {
        try assertNotRoot()
        var exists: DarwinBoolean = false
        let value = CFPreferencesGetAppIntegerValue(key.rawValue as CFString, domain.rawValue as CFString, &exists)
        if !exists.boolValue {
            return nil
        }
        return value
    }
    
    static func getObject(key: Key, domain: Domain) throws -> AnyObject? {
        try assertNotRoot()
        return CFPreferencesCopyAppValue(key.rawValue as CFString, domain.rawValue as CFString)
    }
    
    static func setBool(key: Key, value: Bool, domain: Domain) throws {
        try assertNotRoot()
        CFPreferencesSetAppValue(key.rawValue as CFString, value ? kCFBooleanTrue : kCFBooleanFalse, domain.rawValue as CFString)
        CFPreferencesAppSynchronize(domain.rawValue as CFString)
    }
    
    static func setInt(key: Key, value: Int, domain: Domain) throws {
        try assertNotRoot()
        CFPreferencesSetAppValue(key.rawValue as CFString, NSNumber(value: value), domain.rawValue as CFString)
        CFPreferencesAppSynchronize(domain.rawValue as CFString)
    }
        
    static func setObject(key: Key, value: Any?, domain: Domain) throws {
        try assertNotRoot()
        CFPreferencesSetAppValue(key.rawValue as CFString, value as CFPropertyList, domain.rawValue as CFString)
        CFPreferencesAppSynchronize(domain.rawValue as CFString)
    }
    
}
