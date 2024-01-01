import ComposableArchitecture
import CasePath
import Output
import Input

@CasePathable
enum SessionAction {
    case output(OutputAction)
    case input(InputAction)
}

public struct SessionState {
    private let session = Session()
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
        value: \SessionState.input,
        action: SessionAction.cases.input
    ),
    pullback(
        outputReducer,
        value: \SessionState.output,
        action: SessionAction.cases.output
    )
)

func sessionStore(
    _ reducer: @escaping (
        inout SessionState,
        SessionAction
    ) -> Void
) -> Store<SessionState, SessionAction> {
    let store = Store(initialValue: SessionState(), reducer: reducer)
    Task { @MainActor [weak store] in
        for await data in Output(handle: store?.value.handle) {
            store?.send(.output(.output(data)))
        }
    }
    return store
}
