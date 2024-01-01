import SwiftUI
import ComposableArchitecture

struct TermWindowView: View {
    @ObservedObject var store: Store<SessionState, SessionAction>
    var body: some View {
        ScrollView {
            Text(store.value.output)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.custom("ComicCode-Medium", size: 20))
                .foregroundStyle(Color.pink)
            HStack(spacing: .zero) {
                Text(store.value.pwd)
                    .font(.custom("ComicCode-Medium", size: 20))
                    .foregroundStyle(.cyan)
                InputView(
                    store: store.view(
                        value: \.command,
                        action: SessionAction.cases.commandAction
                    )
                )
            }
        }
        .background {
            Color(red: 0, green: 0, blue: 0)
        }
        .onAppear {
            store.value.session.run()
        }
    }
}
