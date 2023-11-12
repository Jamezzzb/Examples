//
//  TermWindowView.swift
//  JTerm
//
//  Created by James Brown on 11/6/23.
//
import SwiftUI

struct TermWindowView: View {
    @ObservedObject var viewModel: TermWindowViewModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 5) {
                ForEach(0..<viewModel.visibleOutput.count, id: \.self) {
                    index in
                    Text(viewModel.visibleOutput[index])
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.custom("ComicCode-Medium", size: 20))
                        .foregroundStyle(Color.green)
                        .flippedUpsideDown()
                }.flippedUpsideDown()
                HStack(spacing: .zero) {
                    Text(viewModel.pwd)
                        .font(.custom("ComicCode-Medium", size: 20))
                        .foregroundStyle(.cyan)
                    InputView(textViewModel: viewModel.textViewModel, viewModel: viewModel)
                }
            }.flippedUpsideDown()
        }.flippedUpsideDown()
        .background {
            Color(red: 0, green: 0, blue: 0.25)
        }
    }
}

