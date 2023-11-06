//
//  CommandViewModel.swift
//  JTerm
//
//  Created by James Brown on 11/5/23.
//

import Foundation
class TermSession: NSObject {
    var task: Process?
    var pty: FileHandle?
    var tty: FileHandle?
    var data: String = ""
    var cachedOutput: String = ""
    var dataBuffer: String = ""
    weak var observed: CommandViewModel?
    
    init(observed: CommandViewModel) {
        self.observed = observed
        self.task = Process()
        var ttyFD: Int32 = 0
        ttyFD = posix_openpt(O_RDWR)
        grantpt(ttyFD)
        unlockpt(ttyFD)
        self.tty = FileHandle.init(fileDescriptor: ttyFD, closeOnDealloc: true)
        let ptyPath = String.init(cString: ptsname(ttyFD))
        self.pty = FileHandle.init(forUpdatingAtPath: ptyPath)
        self.task?.executableURL = URL(fileURLWithPath: "/bin/zsh")
        //MARK: make interactive
        self.task?.arguments = ["-i"]
        self.task?.standardOutput = pty
        self.task?.standardInput = pty
        self.task?.standardError = pty
    }
    
    func pollData() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            while self?.task?.isRunning == .some(true) {
                if let data = (self?.tty?.availableData).flatMap({ String(data: $0, encoding: .utf8) }
                ), !data.isEmpty {
                    DispatchQueue.main.async {
                        if let range = data.ranges(of: /jbrown574.+?%\s/).first {
                            let suffix = data[range]
                            self?.observed?.pwd = String(suffix)
                            var mutData = data
                            mutData.removeSubrange(range)
                            self?.observed?.outPutBuffer.append(mutData)
                        } else {
                            self?.observed?.outPutBuffer.append(data)
                        }
                    }
                }
            }
        }
    }
    
    func flushOutput() {
        cachedOutput = ""
    }
    
    func write(_ command: String) {
        guard let command = command.data(using: .utf8) else { return }
        tty?.write(command)
    }
    
    func run() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try self?.task?.run()
                self?.pollData()
            } catch {
                fatalError("failed to start task")
            }
        }
    }
}

class TextViewModel: ObservableObject {
    @Published var text: String = ""
}
class CommandViewModel: ObservableObject {
    enum Constants {
        static let maxLength = 20
    }
    lazy var session: TermSession = TermSession(observed: self)
    var textViewModel = TextViewModel()
    @Published var pwd = ""
    init() {
        session.run()
    }
    
    @Published var output: String = ""
    var outPutBuffer: String = "" {
        didSet {
            if let range = outPutBuffer.ranges(of: "sys-clrAll").last {
                output = String(outPutBuffer.suffix(from: range.lowerBound))
            } else {
                output = outPutBuffer
            }
        }
    }
    
    func zsh() throws {
        session.write(textViewModel.text + "\n")
    }
}

