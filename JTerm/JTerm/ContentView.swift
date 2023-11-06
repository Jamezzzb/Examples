//
//  ContentView.swift
//  JTerm
//
//  Created by James Brown on 11/5/23.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var commandViewModel: CommandViewModel
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack {
                    Text(commandViewModel.output)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.custom("ComicCode-Medium", size: 20))
                        .foregroundStyle(Color.green)
                    HStack(spacing: .zero) {
                        Text(commandViewModel.pwd)
                            .font(.custom("ComicCode-Medium", size: 20))
                            .foregroundStyle(.cyan)
                        InputView(viewModel: commandViewModel.textViewModel, commandViewModel: commandViewModel)
                            .id(1)
                    }
                }.onReceive(commandViewModel.output.publisher) { _ in
                    scrollProxy.scrollTo(1)
                }
            }
        }.background {
            Color(red: 0, green: 0, blue: 0.25)
        }
    }
}

struct InputView: View {
    @ObservedObject var viewModel: TextViewModel
    @ObservedObject var commandViewModel: CommandViewModel
    var body: some View {
        TextField("", text: $viewModel.text)
            .font(.custom("ComicCode-Medium", size: 20))
            .foregroundStyle(Color.green)
            .onSubmit {
                try? commandViewModel.zsh()
            }
    }
}

#Preview {
    ContentView(commandViewModel: CommandViewModel())
}
