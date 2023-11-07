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
