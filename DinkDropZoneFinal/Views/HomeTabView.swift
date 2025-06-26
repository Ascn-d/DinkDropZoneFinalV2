import SwiftUI
import Combine

struct HomeTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // Dashboard Tab
                DashboardView()
                    .tabItem {
                        Label {
                            Text("Dashboard")
                        } icon: {
                            EnhancedTabBarIcon(
                                systemName: "house.fill",
                                isSelected: selectedTab == 0,
                                badgeCount: nil
                            )
                        }
                    }
                    .tag(0)
                
                // Queue Tab
                QueueView()
                    .tabItem {
                        Label {
                            Text("Find Match")
                        } icon: {
                            EnhancedTabBarIcon(
                                systemName: "person.2.fill",
                                isSelected: selectedTab == 1,
                                badgeCount: appState.queueCount > 0 ? appState.queueCount : nil
                            )
                        }
                    }
                    .tag(1)
                
                // Leaderboard Tab
                LeaderboardView()
                    .tabItem {
                        Label {
                            Text("Leaderboard")
                        } icon: {
                            EnhancedTabBarIcon(
                                systemName: "trophy.fill",
                                isSelected: selectedTab == 2,
                                badgeCount: nil
                            )
                        }
                    }
                    .tag(2)

                // Profile Tab
                ProfileView()
                    .tabItem {
                        Label {
                            Text("Profile")
                        } icon: {
                            EnhancedTabBarIcon(
                                systemName: "person.fill",
                                isSelected: selectedTab == 3,
                                badgeCount: appState.unreadNotificationCount > 0 ? appState.unreadNotificationCount : nil
                            )
                        }
                    }
                    .tag(3)
            }
            .tint(DS.Color.accent)
            .accentColor(DS.Color.accent)
            .preferredColorScheme(appState.darkModeEnabled ? .dark : nil)
            .onChange(of: selectedTab) { oldValue, newValue in
                handleTabChange(from: oldValue, to: newValue)
            }
            
            // Floating notification overlay
            VStack {
                if appState.currentNotification != nil {
                    NotificationBannerContainer()
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appState.currentNotification != nil)
                }
                
                Spacer()
            }
        }
        .onAppear {
            setupTabBarAppearance()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToQueue)) { _ in
            print("🔥 HomeTabView: Received navigateToQueue notification - switching to tab 1")
            withAnimation {
                selectedTab = 1 // Switch to Queue tab
            }
        }
    }
    
    private func handleTabChange(from oldTab: Int, to newTab: Int) {
        // Haptic feedback based on tab
        let feedbackType: UIImpactFeedbackGenerator.FeedbackStyle = {
            switch newTab {
            case 0: return .light
            case 1: return .medium
            case 2: return .heavy
            case 3: return .light
            default: return .light
            }
        }()
        
        let generator = UIImpactFeedbackGenerator(style: feedbackType)
        generator.impactOccurred()
        
        // Log tab navigation
        LoggingService.shared.log("User navigated from \(tabName(for: oldTab)) to \(tabName(for: newTab))")
        
        // Tab-specific actions
        switch newTab {
        case 1: // Queue tab
            appState.refreshQueue()
        case 2: // Leaderboard tab
            appState.refreshLeaderboard()
        case 3: // Profile tab
            appState.markNotificationsAsRead()
        default:
            break
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        // Background styling
        appearance.backgroundColor = UIColor.systemBackground
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.3)
        
        // Item styling
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(DS.Color.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(DS.Color.accent),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func tabName(for index: Int) -> String {
        switch index {
        case 0: return "Dashboard"
        case 1: return "Find Match"
        case 2: return "Leaderboard"
        case 3: return "Profile"
        default: return "Unknown"
        }
    }
}

// Enhanced tab bar icon with animations and badges
struct EnhancedTabBarIcon: View {
    let systemName: String
    let isSelected: Bool
    let badgeCount: Int?
    @State private var bounceScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Image(systemName: systemName)
                .font(.system(size: isSelected ? 24 : 20, weight: isSelected ? .semibold : .medium))
                .foregroundStyle(isSelected ? DS.Color.accent : .gray)
                .scaleEffect(bounceScale)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            
            // Badge
            if let count = badgeCount, count > 0 {
                Text("\(count)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, count > 9 ? 4 : 0)
                    .frame(minWidth: 14, minHeight: 14)
                    .background(
                        Circle()
                            .fill(Color.red)
                            .shadow(color: .red.opacity(0.3), radius: 2, x: 0, y: 1)
                    )
                    .offset(x: 12, y: -10)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onChange(of: isSelected) { _, newValue in
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    bounceScale = 1.2
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
                    bounceScale = 1.0
                }
            }
        }
    }
}

// Custom tab bar icon that supports styling for selected state (keeping for compatibility)
struct TabBarIcon: View {
    let systemName: String
    let isSelected: Bool
    
    var body: some View {
        EnhancedTabBarIcon(
            systemName: systemName,
            isSelected: isSelected,
            badgeCount: nil
        )
    }
}

#Preview {
    HomeTabView()
        .environmentObject(AppState())
        .environment(XPManager())
} 