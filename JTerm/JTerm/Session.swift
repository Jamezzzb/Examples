import SwiftUI
import ComposableArchitecture
import CasePath

struct SessionState {
    let session = PseudoTTYSession()
    var output = ""
    var pwd = ""
    var command = ""
    var task: Task<Void, Never>?
}

func sessionReducer(_ value: inout SessionState, action: SessionAction) {
    switch action {
    case .readData(let data):
        value.output.append(data.output)
        value.pwd = data.pwd
    case .commandAction(let command):
        switch command {
        case .write(let command):
            value.command = command
        case .submit:
            value.session.write(value.command + "\r")
        }
    }
}

enum CommandAction {
    case write(String)
    case submit
}

func sessionStore(
    _ reducer: @escaping (
        inout SessionState,
        SessionAction
    ) -> Void
) -> Store<SessionState, SessionAction> {
    let store = Store(initialValue: SessionState(), reducer: reducer)
    Task { @MainActor [weak store] in
        for await data in OutputStream(handle: store?.value.session.parentHandle) {
            store?.send(.readData(data: data))
        }
    }
    return store
}

@CasePathable
enum SessionAction {
    case readData(data: OutputStream.Element)
    case commandAction(CommandAction)
}
