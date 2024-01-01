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
    private let session = TerminalSession()
    func run() { session.run() }
    var handle: FileHandle? { session.parentHandle }
    var output: Output.Element = (tty: "", pwd: "")
    var input = "" {
        didSet { session.write(input) }
    }
    var task: Task<Void, Never>?
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
    _ reducer: @escaping (
        inout TerminalSessionState,
        TerminalSessionAction
    ) -> Void
) -> Store<TerminalSessionState, TerminalSessionAction> {
    let store = Store(initialValue: TerminalSessionState(), reducer: reducer)
    Task { @MainActor [weak store] in
        for await data in Output(handle: store?.value.handle) {
            store?.send(.output(.output(data)))
        }
    }
    return store
}
