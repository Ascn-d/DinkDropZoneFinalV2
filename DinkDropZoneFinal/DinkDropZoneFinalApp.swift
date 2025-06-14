//
//  DinkDropZoneFinalApp.swift
//  DinkDropZoneFinal
//
//  Created by Marco on 6/4/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct DinkDropZoneFinalApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    private let container: ModelContainer = {
        let schema = Schema([
            User.self
            // Temporarily removing UserSettings and other models to isolate the issue
            // UserSettings.self,
            // Match.self,
            // PickleLeague.self,
            // LeagueMatch.self,
            // Team.self,
            // Tournament.self,
            // TournamentMatch.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,  // Use in-memory storage to avoid migration issues
            allowsSave: true
        )
        
        do {
            LoggingService.shared.log("Initializing SwiftData container", level: .info)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: nil,
                configurations: [modelConfiguration]
            )
            LoggingService.shared.log("SwiftData container initialized successfully", level: .info)
            return container
        } catch {
            LoggingService.shared.logDataError(error, operation: "SwiftData initialization")
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }()

    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .environment(appState)
                .onAppear {
                    LoggingService.shared.log("App launched", level: .info)
                    appState.initialize(with: container.mainContext)
                }
        }
    }
}
