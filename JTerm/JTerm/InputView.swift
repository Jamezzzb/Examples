import SwiftUI
import ComposableArchitecture

struct InputView: View {
    @ObservedObject var store: Store<String, CommandAction>
    var body: some View {
        TextField("", text: binding())
            .textFieldStyle(.plain)
            .font(.custom("ComicCode-Medium", size: 20))
            .foregroundStyle(Color.green)
            .onSubmit {
                store.send(.submit)
            }
    }
    
    func binding() -> Binding<String> {
        Binding<String> {
            store.value
        } set: { newValue in
            store.send(.write(newValue))
        }
    }
}
