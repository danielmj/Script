//
//  Shell.swift
//  cutjs
//
//  Created by Dan on 6/21/22.
//

import Foundation
#if os(OSX)
import Darwin.C
#else
import Glibc
#endif

public final class Shell {
    
    public enum SpawnError: Error {
        case CouldNotOpenPipe
        case CouldNotSpawn
    }
    
    private let command: String
    private var outputBlock: ((String) -> Void)
    private var outputPipe: [Int32] = [-1, -1]
    private(set) var pid: pid_t = 0
    private var thread: Thread? = nil
    private var lastWS: winsize = winsize()
    
    var completion: ((Int32) -> Void)? = nil
    
    public init(command: String, output: @escaping ((String) -> Void)) throws {
        self.outputBlock = output
        self.command = command
        
        guard pipe(&outputPipe) >= 0 else {
            throw SpawnError.CouldNotOpenPipe
        }
        
#if os(OSX)
        var childFDActions: posix_spawn_file_actions_t? = nil
#else
        var childFDActions = posix_spawn_file_actions_t()
#endif
        posix_spawn_file_actions_init(&childFDActions)
        posix_spawn_file_actions_adddup2(&childFDActions, outputPipe[1], STDOUT_FILENO)
        posix_spawn_file_actions_adddup2(&childFDActions, outputPipe[1], STDERR_FILENO)
        posix_spawn_file_actions_addclose(&childFDActions, outputPipe[0])
        posix_spawn_file_actions_addclose(&childFDActions, outputPipe[1])
        
        let args = ["/bin/sh", "-c", command]
        let argv: [UnsafeMutablePointer<CChar>?] = args.map{ $0.withCString(strdup) }
        defer {
            for case let arg? in argv {
                free(arg)
            }
        }
        
        if posix_spawn(&pid, argv[0], &childFDActions, nil, argv + [nil], environ) < 0 {
            throw SpawnError.CouldNotSpawn
        }
        
        watchStreams()
        updateWindowSize()
        monitorWindowSize()
    }
    
    deinit {
        thread?.cancel()
        _ = wait()
    }
    
    @discardableResult class func run(_ cmd: String, echoCommand: Bool = true, echoOutput: Bool = false) async -> (output: String, status: Int32) {
        var result = ""
        if echoCommand == true {
            log(.grey("\n" + cmd))
        }
        
        let status: Int32 = await withCheckedContinuation { continuation in
            do {
                let spawn = try Shell(command: cmd, output: { (text) in
                    if echoOutput == true, let data = text.data(using: .utf8) {
                        FileHandle.standardOutput.write(data)
                    }
                    result += text
                })
                
                spawn.completion = { status in
                    continuation.resume(returning: status)
                    _ = spawn
                }
            }
            catch let error {
                print("ERROR: \(error)")
            }
        }
        return (result, status)
    }
    
    func wait() -> Int32 {
        var status: Int32 = 0
        _ = waitpid(pid, &status, 0)
        return status
    }
    
    // MARK: Private
    
    private func monitorWindowSize() {
        watchSignals
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateWindowSize),
                                               name: kUpdateWindowSize,
                                               object: nil)
    }
    
    @objc func updateWindowSize(_ notification: Notification? = nil) {
        var clientWS: winsize = winsize()
        _ = ioctl(STDIN_FILENO, TIOCGWINSZ, &clientWS);
        
        // Did anything change?
        if (memcmp(&lastWS, &clientWS, MemoryLayout<winsize>.size) == 0) {
            return;
        }
        
        lastWS = clientWS;
        _ = ioctl(outputPipe[0], TIOCSWINSZ, &clientWS);
    }
    
    private func watchStreams() {
        weak var weakSelf = self
        thread = Thread {
            guard let self = weakSelf else {
                return
            }
            
            close(self.outputPipe[1])
            
            let bufferSize: size_t = 1024 * 8
            let dynamicBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            while true && !(self.thread?.isCancelled ?? true) {
                let amtRead = read(self.outputPipe[0], dynamicBuffer, bufferSize)
                guard amtRead > 0 else {
                    break
                }
                
                let array = Array(UnsafeBufferPointer(start: dynamicBuffer, count: amtRead))
                let tmp = array  + [UInt8(0)]
                tmp.withUnsafeBufferPointer { ptr in
                    let str = String(cString: unsafeBitCast(ptr.baseAddress, to: UnsafePointer<CChar>.self))
                    self.outputBlock(str)
                }
            }
            dynamicBuffer.deallocate()
            
            self.completion?(self.wait())
            self.completion = nil
        }
        thread?.start()
    }
}

private let kUpdateWindowSize: Notification.Name =  NSNotification.Name("ShellUpdateWinSize")
private let watchSignals: () = {
    signal(SIGINT) { _ in
        NotificationCenter.default.post(name: kUpdateWindowSize, object: nil)
    }
}()
