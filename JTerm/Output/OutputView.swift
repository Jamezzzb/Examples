import SwiftUI
import ComposableArchitecture

public enum OutputAction {
    case output(Output.Element)
}

public let outputReducer: Reducer<
    Output.Element,
    OutputAction
> = { value, action in
    switch action {
    case .output(let output):
        value.tty.append(output.tty)
        value.pwd = output.pwd
        return []
    }
}

public struct OutputView: View {
    @ObservedObject var store: Store<Output.Element, OutputAction>
    public init(store: Store<Output.Element, OutputAction>) {
        self.store = store
    }
    public var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Text(store.value.tty)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.custom("ComicCode-Medium", size: 20))
                .foregroundStyle(Color.pink)
            Text(store.value.pwd)
                .font(.custom("ComicCode-Medium", size: 20))
                .foregroundStyle(.cyan)
        }
    }
}
