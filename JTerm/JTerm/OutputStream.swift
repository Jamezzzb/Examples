import Foundation
struct OutputStream: AsyncSequence {
    typealias Element = (output: String, pwd: String)
    let handle: FileHandle?
    
    struct AsyncIterator : AsyncIteratorProtocol {
        let handle: FileHandle?
        mutating func next() async -> Element? {
            guard let handle else { return nil }
            let output = String(
                decoding: handle.availableData,
                as: UTF8.self
            )
            let pwd = output
                .firstRange(of: Constants.pwdRegex)
                .map { String(output[$0]) }
            return (output: output, pwd: pwd ?? "")
        }
    }
    
    func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(handle: handle)
    }
}

extension OutputStream {
    enum Constants {
        private static let user: String = FileManager.default.homeDirectoryForCurrentUser.lastPathComponent
        static let pwdRegex: Regex! = { try? Regex("\(user).+?%\\s") }()
    }
}
