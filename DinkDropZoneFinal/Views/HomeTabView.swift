import SwiftUI

struct HomeTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }

            QueueView()
                .tabItem {
                    Label("Queue", systemImage: "timer")
                }
            
            SocialView()
                .tabItem {
                    Label("Social", systemImage: "person.3.fill")
                }
            
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }

            LeaguesHomeView()
                .tabItem {
                    Label("Leagues", systemImage: "flag.2.crossed")
                }

            LeaderboardView()
                .tabItem {
                    Label("Leaderboard", systemImage: "trophy.fill")
                }

            AchievementsView()
                .tabItem {
                    Label("Achievements", systemImage: "rosette")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    HomeTabView()
        .environment(AppState())
} 