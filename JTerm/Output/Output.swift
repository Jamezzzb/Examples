public struct Output: AsyncSequence {
    public typealias Element = (tty: String, pwd: String)
    private let handle: FileHandle?
    public init(handle: FileHandle?) {
        self.handle = handle
    }
    
    public struct AsyncIterator : AsyncIteratorProtocol {
        let handle: FileHandle?
        public mutating func next() async -> Element? {
            guard let handle else { return nil }
            let tty = String(
                decoding: handle.availableData,
                as: UTF8.self
            )
            let pwd = tty
                .firstRange(of: Constants.pwdRegex)
                .map { String(tty[$0]) }
            return (tty: tty, pwd: pwd ?? "")
        }
    }
    
    public func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(handle: handle)
    }
}

extension Output {
    enum Constants {
        private static let user: String = FileManager
            .default
            .homeDirectoryForCurrentUser
            .lastPathComponent
        fileprivate static let pwdRegex: Regex! = { try? Regex("\(user).+?%\\s") }()
    }
}


