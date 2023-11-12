//
//  InputView.swift
//  JTerm
//
//  Created by James Brown on 11/6/23.
//

import SwiftUI

struct InputView: View {
    @ObservedObject var textViewModel: TextViewModel
    @ObservedObject var viewModel: TermWindowViewModel
    var body: some View {
        TextField("", text: $textViewModel.text)
            .textFieldStyle(.plain)
            .font(.custom("ComicCode-Medium", size: 20))
            .foregroundStyle(Color.green)
            .onSubmit {
                try? viewModel.zsh()
                textViewModel.clear()
            }
    }
}
