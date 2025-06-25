import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
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
            
            // Achievement unlock notifications
            if let unlockedAchievement = appState.achievementNotificationManager?.currentUnlockNotification {
                AchievementUnlockNotification(achievement: unlockedAchievement) {
                    appState.achievementNotificationManager?.hideUnlockNotification()
                }
                .zIndex(1000)
                .transition(.opacity.combined(with: .scale))
            }
            
            // Achievement progress notifications
            if let progressNotification = appState.achievementNotificationManager?.currentProgressNotification {
                VStack {
                    AchievementProgressNotification(
                        achievement: progressNotification.achievement,
                        previousProgress: progressNotification.previousProgress
                    ) {
                        appState.achievementNotificationManager?.hideProgressNotification()
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    Spacer()
                }
                .zIndex(999)
                .transition(.move(edge: .top))
            }
        }
        .sheet(item: Binding(get: { appState.matchProposal }, set: { appState.matchProposal = $0 })) { proposal in
            MatchProposalView(proposal: proposal)
        }
        .onReceive(NotificationCenter.default.publisher(for: .trophyUnlocked)) { notification in
            if let achievement = notification.object as? Trophy {
                appState.achievementNotificationManager?.showUnlockNotification(for: achievement)
            }
        }
    }
}

#Preview {
    let previewState = AppState()
    ContentView()
        .environmentObject(previewState)
} 