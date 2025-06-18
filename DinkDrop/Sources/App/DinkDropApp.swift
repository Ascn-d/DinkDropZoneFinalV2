import SwiftUI
import SwiftData

@main
struct DinkDropApp: App {
    private let container: ModelContainer = {
        let schema = Schema([User.self, Match.self])
        return try! ModelContainer(for: schema)
    }()

    @State private var appState = AppState()
        @AppStorage("hasOnboarded") private var hasOnboarded = false


    var body: some Scene {
        WindowGroup {
            if hasOnboarded {
                ContentView()
            } else {
                OnboardingView()
            }()
                .modelContainer(container)
                .environment(appState)
        }
    }
} 
