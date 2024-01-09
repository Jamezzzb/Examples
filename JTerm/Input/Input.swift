import ComposableArchitecture

public enum InputAction {
    case writeToBuffer(String)
    case writeToFile
    case writeResult(Void?)
}

public let inputReducer: Reducer<
    (
        buffer: String,
        handle: FileHandle?
    ), InputAction> = { value, action in
    switch action {
    case .writeToBuffer(let input):
        value.buffer = input
        return []
    case .writeToFile:
        let result: Void? = try? value.handle?.write(
            contentsOf: Data(
                value.buffer.appending("\n").utf8
            )
        )
        return [ { InputAction.writeResult(result) } ]
    case .writeResult(let result):
        switch result {
        case .none:
            // In real life actually handle the error though
            fatalError("writing to the file failed")
        case .some:
            return []
        }
    }
}
