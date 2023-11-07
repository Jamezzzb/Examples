//
//  JTermApp.swift
//  JTerm
//
//  Created by James Brown on 11/5/23.
//

import SwiftUI

@main
struct JTermApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: TermWindowViewModel())
        }
    }
}
