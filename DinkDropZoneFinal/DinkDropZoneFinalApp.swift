//
//  DinkDropZoneFinalApp.swift
//  DinkDropZoneFinal
//
//  Created by Marco on 6/4/25.
//

import SwiftUI
import SwiftData

@main
struct DinkDropZoneFinalApp: App {
    private let container: ModelContainer = {
        let schema = Schema([User.self, Match.self])
        return try! ModelContainer(for: schema)
    }()

    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(appState)
        }
    }
}
