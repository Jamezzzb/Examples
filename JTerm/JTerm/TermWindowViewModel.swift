//
//  TermWindowViewModel.swift
//  JTerm
//
//  Created by James Brown on 11/5/23.
//

import Foundation
/// modified from https://stackoverflow.com/a/55230753
/// creates a pair of parent and child pseudo-terminal `FileHandle` objects
class PseudoTTYSession: NSObject {
    private var task: Process?
    private var childHandle: FileHandle?
    private var parentHandle: FileHandle?
    // TODO: not currently using this
    private var cachedOutput: String = ""
    private weak var observed: TermWindowViewModel?
    
    enum Constants {
        static let user: String = FileManager.default.homeDirectoryForCurrentUser.lastPathComponent
        static let pwdRegex: Regex? = { try? Regex("\(user).+?%\\s") }()
    }
    
    init(observed: TermWindowViewModel) {
        self.observed = observed
        self.task = Process()
        var parentFD: Int32 = 0
        parentFD = posix_openpt(O_RDWR)
        grantpt(parentFD)
        unlockpt(parentFD)
        self.parentHandle = FileHandle.init(fileDescriptor: parentFD, closeOnDealloc: true)
        let childPath = String.init(cString: ptsname(parentFD))
        self.childHandle = FileHandle.init(forUpdatingAtPath: childPath)
        self.task?.executableURL = URL(fileURLWithPath: "/bin/zsh")
        // set "-i" for interactive
        self.task?.arguments = ["-i"]
        self.task?.standardOutput = childHandle
        self.task?.standardInput = childHandle
        self.task?.standardError = childHandle
    }
    
    // TODO: This won't scale well, find better way to do or at least absract
    func pollData() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            while self?.task?.isRunning == .some(true) {
                if let data = (self?.parentHandle?.availableData).flatMap({ String(data: $0, encoding: .utf8) }
                ), !data.isEmpty {
                    DispatchQueue.main.async {
                        if let pwdRegex = Constants.pwdRegex, let range = data.ranges(of: pwdRegex).first {
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
    // Not using currently
    func flushOutput() {
        cachedOutput = ""
    }
    
    func write(_ command: String) {
        guard let command = command.data(using: .utf8) else { return }
        parentHandle?.write(command)
    }
    
    func run() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try self?.task?.run()
                self?.pollData()
            } catch {
                fatalError("PseudoTTY Failed To Start")
            }
        }
    }
}

class TextViewModel: ObservableObject {
    @Published var text: String = ""
    func clear() {
        self.text = ""
    }
}

class TermWindowViewModel: ObservableObject {
    enum Constants {
        static let maxLength = 20
    }
    lazy var session: PseudoTTYSession = PseudoTTYSession(observed: self)
    var textViewModel = TextViewModel()
    @Published var pwd = ""
    init() {
        session.run()
    }
    
    @Published var output: String = ""
    var outPutBuffer: String = "" {
        //FIXME: not how this should be implemented, just an example
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

