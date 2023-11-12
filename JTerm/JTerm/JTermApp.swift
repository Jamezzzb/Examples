//
//  JTermApp.swift
//  JTerm
//
//  Created by James Brown on 11/5/23.
//

import SwiftUI

@main
struct JTermApp: App {
    @StateObject var viewModel = TermWindowViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }.commands {
            TerminalCommands(viewModel: viewModel)
        }
    }
}

struct TerminalCommands: Commands {
    @ObservedObject var viewModel: TermWindowViewModel
    var body: some Commands {
        CommandMenu("JTermCommands") {
            Button("pageUp") {
                viewModel.lineOffset -= 20
            }.keyboardShortcut(.upArrow, modifiers: [])
            Button("pageDown") {
                viewModel.lineOffset += 20
            }.keyboardShortcut(.downArrow, modifiers: [])
        }
    }
    
    
}
