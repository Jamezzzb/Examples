import SwiftUI
import ComposableArchitecture

public struct InputView: View {
    @ObservedObject var store: Store<String, InputAction>
    
    public init(store: Store<String, InputAction>) {
        self.store = store
    }
    
    public var body: some View {
        TextEditor(text: binding())
            .textFieldStyle(.plain)
            .font(.custom("ComicCode-Medium", size: 20))
            .foregroundStyle(Color.green)
    }
    
    func binding() -> Binding<String> {
        Binding<String> {
            store.value
        } set: { newValue in
            guard let last = newValue.last else { return }
            store.send(.write(String(last)))
        }
    }
}
