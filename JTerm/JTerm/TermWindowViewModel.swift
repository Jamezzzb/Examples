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
    private var pwdReader = CurrentValueSubject<String, Never>("")
    lazy var dataPublisher = dataReader.eraseToAnyPublisher()
    lazy var pwdPublisher = pwdReader.eraseToAnyPublisher()
    
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
            pwdReader.value = String(data[range])
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
    private lazy var session: PseudoTTYSession = PseudoTTYSession()
    private var cancelables: [AnyCancellable] = []
    private (set) var textViewModel = TextViewModel()
    var lineOffset: Int {
        set {
            guard 
                abs(newValue) <= output.count,
                newValue <= 0
            else { return }
            _lineOffset.value = newValue
        }
        get { _lineOffset.value }
    }
    // MARK: Scrolling with arrows
    private var _lineOffset = CurrentValueSubject<Int, Never>(0) {
        willSet {
            guard lineRange.count >= 100 else { return }
            let lower = max(lineRange.lowerBound + newValue.value, 0)
            let upper = max(lineRange.upperBound + newValue.value, 0)
            if !(lower..<upper).isEmpty {
                visibleOutput = Array(output[(lower..<upper)])
            }
        }
    }
    @Published var pwd = ""
    private var lineRange: Range<Int> = (0..<0)
    init() {
        Task {
            await session.run()
        }
        subscribe()
    }
    
    private func subscribe() {
        session
            .dataPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.output, on: self)
            .store(in: &cancelables)
        session
            .pwdPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.pwd, on: self)
            .store(in: &cancelables)
        session
            .dataPublisher
            .receive(on: DispatchQueue.main)
            .map(\.count)
            .sink { [weak self] in
                let upper = max($0, 0)
                let lower = max(upper - 100, 0)
                self?.lineRange = (lower..<upper)
            }
            .store(in: &cancelables)
        _lineOffset
            .sink { [weak self] newValue in
                guard 
                    self?.lineRange.count ?? 0 >= 100,
                    let lowerBound = self?.lineRange.lowerBound,
                    let upperBound = self?.lineRange.upperBound
                else {
                    return
                }
                let lower = max(lowerBound + newValue, 0)
                let upper = max(upperBound + newValue, 0)
                if !(lower..<upper).isEmpty {
                    self?.visibleOutput = Array(self?.output[(lower..<upper)] ?? [])
                }
            }
            .store(in: &cancelables)

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
    func zsh() throws {
        session.write(textViewModel.text + "\r")
    }
}

