import SwiftUI
import ComposableArchitecture

public struct InputView: View {
    @ObservedObject var store: Store<String, InputAction>
    
    public init(store: Store<String, InputAction>) {
        self.store = store
    }
    
    public var body: some View {
        TextField("", text: buffer())
            .textFieldStyle(.plain)
            .font(.custom("ComicCode-Medium", size: 20))
            .foregroundStyle(Color.green)
            .onSubmit {
                store.send(.writeToFile)
            }
    }
    
    func buffer() -> Binding<String> {
        Binding<String> {
            store.value
        } set: { newValue in
            store.send(.writeToBuffer(newValue))
        }
    }
}
