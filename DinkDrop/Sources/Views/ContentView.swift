import SwiftUI
import Observation

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.currentUser == nil {
                WelcomeView()
            } else {
                HomeTabView()
            }
        }
        .animation(.easeInOut, value: appState.currentUser)
    }
}

#Preview {
    let previewState = AppState()
    return ContentView()
        .environment(previewState)
} 