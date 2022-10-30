//
//  Print.swift
//  cutjs
//
//  Created by Dan on 6/21/22.
//

import Foundation

struct LogMessage: ExpressibleByStringInterpolation, CustomStringConvertible {
    
    private enum Color: String {
        case reset      = "\u{001B}[0m"
        case black      = "\u{001B}[30m"
        case red        = "\u{001B}[31m"
        case green      = "\u{001B}[32m"
        case yellow     = "\u{001B}[33m"
        case blue       = "\u{001B}[34m"
        case magenta    = "\u{001B}[35m"
        case cyan       = "\u{001B}[36m"
        case white      = "\u{001B}[37m"
        case grey       = "\u{001B}[90m"
        case underline  =  "\u{001B}[4m"
        case bold  =  "\u{001B}[1m"
    }
    
    private var color: Color
    
    private var value: Any?
 
    static func black(_ valueOrNil: Any?) -> Self {
        return LogMessage(.black, valueOrNil)
    }
    
    static func red(_ valueOrNil: Any?) -> Self {
        return LogMessage(.red, valueOrNil)
    }
    
    static func green(_ valueOrNil: Any?) -> Self {
        return LogMessage(.green, valueOrNil)
    }
    
    static func yellow(_ valueOrNil: Any?) -> Self {
        return LogMessage(.yellow, valueOrNil)
    }
    
    static func blue(_ valueOrNil: Any?) -> Self {
        return LogMessage(.blue, valueOrNil)
    }
    
    static func magenta(_ valueOrNil: Any?) -> Self {
        return LogMessage(.magenta, valueOrNil)
    }
    
    static func cyan(_ valueOrNil: Any?) -> Self {
        return LogMessage(.cyan, valueOrNil)
    }
    
    static func white(_ valueOrNil: Any?) -> Self {
        return LogMessage(.white, valueOrNil)
    }
    
    static func grey(_ valueOrNil: Any?) -> Self {
        return LogMessage(.grey, valueOrNil)
    }
    
    static func bold(_ valueOrNil: Any?) -> Self {
        return LogMessage(.bold, valueOrNil)
    }
    
    static func underline(_ valueOrNil: Any?) -> Self {
        return LogMessage(.underline, valueOrNil)
    }
    
    private init(_ color: Color, _ value: Any?) {
        self.value = value
        self.color = color
    }

    init(stringLiteral: StringLiteralType) {
        self.init(.reset, stringLiteral)
    }
    
    var description: String {
        return "\(self.color.rawValue)\(self.value ?? "<nil>")\(Color.reset.rawValue)"
    }
    
}

func logf(_ message: LogMessage...) {
    let components: [String] = (message as [LogMessage]).map { "\($0)" }
    let message = components.joined(separator: " ")
    if let data = message.data(using: .utf8) {
        try? FileHandle.standardOutput.write(contentsOf: data)
    }
}

func log(_ message: LogMessage...) {
    let components: [String] = (message as [LogMessage]).map { "\($0)" }
    print(components.joined(separator: " "))
}

