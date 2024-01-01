import SwiftUI
import ComposableArchitecture

struct ContentView: View {
    var body: some View {
        TermWindowView(store: sessionStore(sessionReducer))
    }
}

#Preview {
    ContentView()
}

struct FlippedUpsideDown: ViewModifier {
    func body(content: Content) -> some View {
        content
            .rotationEffect(.radians(.pi))
            .scaleEffect(x: -1, y: 1, anchor: .center)
    }
}
extension View{
    func flippedUpsideDown() -> some View{
        self.modifier(FlippedUpsideDown())
    }
}
