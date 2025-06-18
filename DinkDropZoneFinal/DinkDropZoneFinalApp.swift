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
            User.self,
            UserSettings.self,
            Match.self,
            LiveMatch.self,
            QueueTournament.self,
            PickleLeague.self,
            LeagueMatch.self,
            Team.self,
            Tournament.self,
            TournamentMatch.self,
            CourtLocation.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            // Persist data on disk so it survives app restarts
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            LoggingService.shared.log("Initializing SwiftData container", level: .info)
            do {
                let container = try ModelContainer(
                    for: schema,
                    migrationPlan: nil,
                    configurations: [modelConfiguration]
                )
                LoggingService.shared.log("SwiftData container initialized successfully", level: .info)
                return container
            } catch {
                LoggingService.shared.logDataError(error, operation: "SwiftData initialization (first attempt)")

                // Attempt recovery: delete the existing persistent store and retry once
                if let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                    let storeURL = supportURL.appendingPathComponent("SwiftDataStore", isDirectory: true)
                    try? FileManager.default.removeItem(at: storeURL)
                    LoggingService.shared.log("Deleted existing SwiftData store for recovery", level: .warning)
                    do {
                        let container = try ModelContainer(
                            for: schema,
                            migrationPlan: nil,
                            configurations: [modelConfiguration]
                        )
                        LoggingService.shared.log("SwiftData container initialized after recovery", level: .info)
                        return container
                    } catch {
                        LoggingService.shared.logDataError(error, operation: "SwiftData initialization (recovery attempt)")
                        LoggingService.shared.log("Falling back to in-memory SwiftData container", level: .warning)
                        do {
                            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, allowsSave: true)
                            let memoryContainer = try ModelContainer(for: schema, configurations: [memoryConfig])
                            return memoryContainer
                        } catch {
                            fatalError("Failed to initialize even in-memory SwiftData container: \(error)")
                        }
                    }
                } else {
                    fatalError("Failed to locate Application Support directory for SwiftData store recovery")
                }
            }
        }
    }()

    @State private var appState = AppState()
    @State private var xpManager: XPManager?
    @State private var xpNotificationManager = XPNotificationManager()
    @State private var nearbyService = NearbyMatchService()
    @State private var locationService = UserLocationService()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .modelContainer(container)
                    .environment(appState)
                    .environment(xpManager ?? XPManager(modelContext: container.mainContext))
                    .environment(xpNotificationManager)
                    .environment(nearbyService)
                    .environment(locationService)
                
                // XP Notification overlay
                XPNotificationContainer()
                    .environment(xpNotificationManager)
            }
                .onAppear {
                    LoggingService.shared.log("App launched", level: .info)
                    appState.initialize(with: container.mainContext)
                    setupXPManager()
                    SeedDataService.seedIfNeeded(modelContext: container.mainContext)
                    CourtDataSeeder.seedIfNeeded(modelContext: container.mainContext)
                }
        }
    }
    
    private func setupXPManager() {
        if xpManager == nil {
            xpManager = XPManager(modelContext: container.mainContext)
            
            // Track daily login
            xpManager?.trackDailyLogin()
            
            LoggingService.shared.log("XPManager initialized", level: .info)
        }
    }
}
