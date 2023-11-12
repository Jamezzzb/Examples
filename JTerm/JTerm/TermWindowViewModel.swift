//
//  TermWindowViewModel.swift
//  JTerm
//
//  Created by James Brown on 11/5/23.
//

import Foundation
import SwiftUI
import Combine
/// modified from https://stackoverflow.com/a/55230753
/// creates a pair of parent and child pseudo-terminal `FileHandle` objects
final class PseudoTTYSession: NSObject {
    // MARK: Publishers
    private var dataReader = CurrentValueSubject<[String], Never>([])
    private lazy var lines = CurrentValueSubject<String, Never>("")
    lazy var dataPublisher = dataReader.eraseToAnyPublisher()
    lazy var dataHistory = dataBuffer.collect(100)
    lazy var dataBuffer = dataReader.buffer(size: 100, prefetch: .keepFull, whenFull: .dropOldest)
    lazy var pwdPublisher = CurrentValueSubject<String, Never>("")
    
    private var task: Process?
    private var childHandle: FileHandle?
    private var parentHandle: FileHandle?
    
    enum Constants {
        private static let user: String = FileManager.default.homeDirectoryForCurrentUser.lastPathComponent
        static let pwdRegex: Regex? = { try? Regex("\(user).+?%\\s") }()
    }
    
    override init() {
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
    
    func pollData() async {
        while task?.isRunning == .some(true) {
            guard
                let data = (parentHandle?.availableData).flatMap({
                    String.init(decoding: $0, as: UTF8.self)
                }), !data.isEmpty else { continue }
            guard
                let pwdRegex = Constants.pwdRegex,
                let range = data.ranges(of: pwdRegex).first
            else {
                dataReader.value
                    .append(contentsOf: data
                        .split(whereSeparator: \.isNewline)
                        .map(String.init))
                continue
            }
            pwdPublisher.value = String(data[range])
            var mutdata = data
            mutdata.removeSubrange(range)
            dataReader.value
                .append(contentsOf: mutdata
                        .split(whereSeparator: \.isNewline)
                        .map(String.init))
        }
    }
    
    func write(_ command: String) {
        parentHandle?.write(Data(command.utf8))
    }
    
    func run() async {
        do {
            try task?.run()
            await pollData()
        } catch {
            fatalError("PseudoTTY Failed To Start")
        }
    }
}

@MainActor final class TextViewModel: ObservableObject {
    @Published var text: String = ""
    func clear() {
        self.text = ""
    }
}

@MainActor final class TermWindowViewModel: ObservableObject {
    enum Constants {
        static let maxLength = 20
    }
    lazy var session: PseudoTTYSession = PseudoTTYSession()
    var textViewModel = TextViewModel()
    var outputSubscriber: AnyCancellable?
    var pwdSubscriber: AnyCancellable?
    var lineCountSubcriber: AnyCancellable?
    var lineOffset: Int {
        set { 
            guard abs(newValue) <= output.count else { return }
            _lineOffset = newValue
        }
        get { _lineOffset }
    }
    // WORK IN PROGRESS SUPPOSED TO PAGE UP/PAGE DOWN
    var _lineOffset: Int = 0 {
        willSet {
            guard lineRange.count >= 100 else { return }
            let lower = newValue < 0 ? max(lineRange.lowerBound + newValue, 0) :
            max(lineRange.lowerBound - newValue, 0)
            let upper = min(max(lineRange.upperBound + newValue, 0), max(lineRange.upperBound - newValue, 0))
            if !(lower..<upper).isEmpty {
                visibleOutput = Array(output[(lower..<upper)])
            }
        }
    }
    @Published var pwd = ""
    var lineRange: Range<Int> = (0..<0)
    init() {
        Task {
            await session.run()
        }
        outputSubscriber = session
            .dataPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.output, on: self)
        pwdSubscriber = session
            .pwdPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.pwd, on: self)
        lineCountSubcriber = session
            .dataPublisher
            .receive(on: DispatchQueue.main)
            .map(\.count)
            .sink { [weak self] in
                let upper = max($0, 0)
                let lower = max(upper - 100, 0)
                self?.lineRange = (lower..<upper)
            }
        
    }
    
    private var output: [String] = [] {
        willSet {
            guard !lineRange.isEmpty else {
                visibleOutput = output
                return
            }
            visibleOutput = Array(newValue[lineRange])
        }
    }
    @Published var visibleOutput: [String] = []
        
    // FIXME: Currently keep/render ALL of the output text, should have only the most recent
    // To see why this is a problem, do some commands that generate a bunch of output.
    // new commands will start to take longer, this is because every time we receive new output,
    // Our view gets updated and we have to re render everything (lol).
    // What "most recent" is is what makes this difficult.
    // For example - if we do: output = outputData.suffix(maxLength: 1000) this will make
    // it so we are only displayting the last 1000 chars received, but that seems kind of arbitrary.
    // Sometimes things generate a lot of output and you might want to go back and read it.
    func zsh() throws {
        session.write(textViewModel.text + "\r")
    }
}

