public enum InputAction {
    case write(String)
}

public func inputReducer(_ value: inout String, action: InputAction) {
    switch action {
    case .write(let input):
        value = input
    }
}
