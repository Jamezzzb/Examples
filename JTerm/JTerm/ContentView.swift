//
//  ContentView.swift
//  JTerm
//
//  Created by James Brown on 11/5/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: TermWindowViewModel
    var body: some View {
        TermWindowView(viewModel: viewModel)
    }
}

#Preview {
    ContentView(viewModel: TermWindowViewModel())
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
