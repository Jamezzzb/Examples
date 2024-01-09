import Foundation
import ComposableArchitecture
import CasePath
import Output
import Input

@CasePathable
enum TerminalSessionAction {
    case output(OutputAction)
    case input(InputAction)
}

public struct TerminalSessionState {
    private let session: TerminalSession
    var handle: FileHandle?
    var output: Output.Element = (tty: "", pwd: "")
    var input: (buffer: String, handle: FileHandle?)
    init() {
        let session = TerminalSession()
        self.session = session
        self.handle = session.parentHandle
        self.output = (tty: "", pwd: "")
        self.input = (buffer: "", handle: session.parentHandle)
        session.run()
    }
}

let sessionReducer = combine(
    pullback(
        inputReducer,
        value: \TerminalSessionState.input,
        action: TerminalSessionAction.cases.input
    ),
    pullback(
        outputReducer,
        value: \TerminalSessionState.output,
        action: TerminalSessionAction.cases.output
    )
)

func sessionStore(
    _ reducer: @escaping Reducer<TerminalSessionState, TerminalSessionAction>
) -> Store<TerminalSessionState, TerminalSessionAction> {
    let store = Store(
        initialValue: TerminalSessionState(),
        reducer: reducer
    )
    Task { @MainActor [weak store] in
        for await data in Output(handle: store?.value.handle) {
            store?.send(.cases.output.embed(.output(data)))
        }
    }
    return store
}
