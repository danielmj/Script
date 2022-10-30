//
//  ToolRunLoop.swift
//  cutjs
//
//  Created by Dan on 6/23/22.
//

import Foundation

class ToolRunLoop {
    
    private var cleanupTasks: [(() async throws -> Void)] = []
    
    let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
    
    func deferTask(_ cleanup: @escaping (() async throws -> Void)) {
        cleanupTasks.append(cleanup)
    }
    
    func run(_ block: @escaping () async throws -> Int32) {
        setupSignalHandler()
        Task {
            let code: Int32
            do {
                code = try await block()
            }
            catch let error {
                print("\n\(error)")
                code = 1
            }
            for cleanup in cleanupTasks {
                try await cleanup()
            }
            exit(code)
        }
        startRunLoop()
    }
    
    func performCleanup() {
        if cleanupTasks.count > 0 {
            print("\n\u{001B}[90mPerforming cleanup...")
            let semaphore = DispatchSemaphore(value: 0)
            Task {
                for cleanup in cleanupTasks {
                    try await cleanup()
                }
                semaphore.signal()
            }
            semaphore.wait()
        }
    }
    
    private func setupSignalHandler() {
        signal(SIGINT, SIG_IGN)
        sigintSrc.setEventHandler {
            self.performCleanup()
            exit(0)
        }
        sigintSrc.resume()
    }
    
    private func startRunLoop() {
        while true {
            autoreleasepool {
                let result = CFRunLoopRunInMode(.defaultMode, 0.5, false)
                switch result {
                case .finished, .stopped:
                    exit(0)
                case .timedOut, .handledSource:
                    return
                @unknown default:
                    fatalError("Unknown RunLoopMode: \(result)")
                }
            }
        }
    }
    
}
