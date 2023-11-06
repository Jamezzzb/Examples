//
//  JTermApp.swift
//  JTerm
//
//  Created by James Brown on 11/5/23.
//

import SwiftUI

@main
struct JTermApp: App {
    let commandViewModel: CommandViewModel = CommandViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView(commandViewModel: commandViewModel)
        }
    }
}
