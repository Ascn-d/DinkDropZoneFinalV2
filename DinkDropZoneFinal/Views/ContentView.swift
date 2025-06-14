import SwiftUI
import Observation

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("hasOnboarded") private var hasOnboarded: Bool = false
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView(isActive: $showSplash)
                    .transition(.opacity)
            } else {
                Group {
                    if appState.currentUser == nil {
                        AuthView()
                    } else if !hasOnboarded {
                        OnboardingView(isOnboardingComplete: $hasOnboarded)
                    } else {
                        SidebarHomeView()
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: appState.currentUser)
                .animation(.easeInOut(duration: 0.5), value: hasOnboarded)
                .transition(.opacity)
            }
        }
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