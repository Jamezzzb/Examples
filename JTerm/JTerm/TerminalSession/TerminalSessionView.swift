import SwiftUI
import ComposableArchitecture
import Output
import Input

public struct TerminalSessionView: View {
    @ObservedObject var store: Store<TerminalSessionState, TerminalSessionAction>
    
    init() {
        self.store = sessionStore(sessionReducer)
    }
    
    public var body: some View {
        ScrollView {
            OutputView(
                store: store.view(
                    value: \.output,
                    action: TerminalSessionAction.cases.output
                )
            )
            InputView(
                store: store.view(
                    value: \.input,
                    action: TerminalSessionAction.cases.input
                )
            )
        }
        .background {
            Color(red: 0, green: 0, blue: 0)
        }
        .onAppear {
            store.value.run()
        }
    }
}
