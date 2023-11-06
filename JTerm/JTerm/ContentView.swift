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
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack {
                    Text(viewModel.output)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.custom("ComicCode-Medium", size: 20))
                        .foregroundStyle(Color.green)
                    HStack(spacing: .zero) {
                        Text(viewModel.pwd)
                            .font(.custom("ComicCode-Medium", size: 20))
                            .foregroundStyle(.cyan)
                        InputView(textViewModel: viewModel.textViewModel, viewModel: viewModel)
                            .id(1)
                    }
                }.onReceive(viewModel.output.publisher) { _ in
                    scrollProxy.scrollTo(1)
                }
            }
        }.background {
            Color(red: 0, green: 0, blue: 0.25)
        }
    }
}

struct InputView: View {
    @ObservedObject var textViewModel: TextViewModel
    @ObservedObject var viewModel: TermWindowViewModel
    var body: some View {
        TextField("", text: $textViewModel.text)
            .font(.custom("ComicCode-Medium", size: 20))
            .foregroundStyle(Color.green)
            .onSubmit {
                try? viewModel.zsh()
            }
    }
}

#Preview {
    ContentView(viewModel: TermWindowViewModel())
}
