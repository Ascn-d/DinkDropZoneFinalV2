import SwiftUI
import Observation

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            if appState.currentUser == nil {
                AuthView()
            } else if appState.needsProfileSetup {
                ProfileWizardView()
            } else {
                HomeTabView()
            }
        }
        .animation(.easeInOut, value: appState.currentUser)
        .sheet(item: Binding(get: { appState.matchProposal }, set: { appState.matchProposal = $0 })) { proposal in
            MatchProposalView(proposal: proposal)
        }
    }
}

#Preview {
    let previewState = AppState()
    return ContentView()
        .environment(previewState)
} 