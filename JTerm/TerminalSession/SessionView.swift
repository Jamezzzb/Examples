import SwiftUI
import ComposableArchitecture
import Output
import Input

public struct SessionView: View {
    @ObservedObject var store: Store<SessionState, SessionAction>
    
    public init() {
        self.store = sessionStore(sessionReducer)
    }
    
    public var body: some View {
        ScrollView {
            OutputView(
                store: store.view(
                    value: \.output,
                    action: SessionAction.cases.output
                )
            )
            InputView(
                store: store.view(
                    value: \.input,
                    action: SessionAction.cases.input
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
