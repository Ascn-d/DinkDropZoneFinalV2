import SwiftUI

struct SidebarHomeView: View {
    @State private var selectedView: SidebarItem = .dashboard
    @State private var showSidebar = false
    @State private var sidebarWidth: CGFloat = 280
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main content area
                Group {
                    switch selectedView {
                    case .dashboard:
                        EnhancedDashboardView()
                    case .queue:
                        QueueView()
                    case .social:
                        SocialView()
                    case .chat:
                        ChatView()
                    case .leagues:
                        LeaguesHomeView()
                    case .leaderboard:
                        LeaderboardView()
                    case .achievements:
                        AchievementsView()
                    case .profile:
                        ProfileView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: showSidebar ? sidebarWidth : 0)
                .scaleEffect(showSidebar ? 0.9 : 1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSidebar)
                .overlay(
                    // Overlay to close sidebar when tapping main content
                    Color.black.opacity(showSidebar ? 0.3 : 0)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                showSidebar = false
                            }
                        }
                        .allowsHitTesting(showSidebar)
                )
                
                // Sidebar
                HStack {
                    SidebarView(
                        selectedItem: $selectedView,
                        showSidebar: $showSidebar,
                        sidebarWidth: sidebarWidth
                    )
                    .offset(x: showSidebar ? 0 : -sidebarWidth)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSidebar)
                    
                    Spacer()
                }
                
                // Floating menu button
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation {
                                showSidebar.toggle()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: showSidebar ? "xmark" : "figure.pickleball")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(showSidebar ? 180 : 0))
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSidebar)
                            }
                        }
                        .padding(.leading, 20)
                        .padding(.top, 10)
                        
                        Spacer()
                    }
                    
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(.container, edges: .top)
    }
}

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem
    @Binding var showSidebar: Bool
    let sidebarWidth: CGFloat
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section
            VStack(spacing: 20) {
                // App logo and title
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue.opacity(0.2), .purple.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    
                    VStack(spacing: 4) {
                        Text("DinkDropZone")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Text("Champion's Hub")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // User info section
                if let user = appState.currentUser {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(user.displayName.prefix(1)).uppercased())
                                    .font(.headline.bold())
                                    .foregroundColor(.blue)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(user.displayName.isEmpty ? "Player" : user.displayName)
                                .font(.subheadline.bold())
                                .foregroundColor(.primary)
                            
                            Text("Level \(XPManager.calculateLevel(from: user.xp))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemBackground))
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 30)
            
            // Navigation items
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(SidebarItem.allCases, id: \.self) { item in
                        SidebarItemView(
                            item: item,
                            isSelected: selectedItem == item
                        ) {
                            selectedItem = item
                            withAnimation {
                                showSidebar = false
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            
            Spacer()
            
            // Footer section
            VStack(spacing: 16) {
                Divider()
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quick Stats")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        if let user = appState.currentUser {
                            HStack(spacing: 16) {
                                VStack(spacing: 2) {
                                    Text("\(user.wins)")
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                    Text("Wins")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(spacing: 2) {
                                    Text("\(user.elo)")
                                        .font(.caption.bold())
                                        .foregroundColor(.blue)
                                    Text("ELO")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                VStack(spacing: 2) {
                                    Text("\(user.winStreak)")
                                        .font(.caption.bold())
                                        .foregroundColor(.orange)
                                    Text("Streak")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 30)
        }
        .frame(width: sidebarWidth)
        .background(
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .fill(Color.primary.opacity(0.1))
                .frame(width: 1),
            alignment: .trailing
        )
    }
}

struct SidebarItemView: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? item.color.opacity(0.2) : Color.clear)
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? item.color : .secondary)
                }
                
                Text(item.title)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(item.color)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? item.color.opacity(0.1) : Color.clear)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

enum SidebarItem: String, CaseIterable {
    case dashboard = "Dashboard"
    case queue = "Play Hub"
    case social = "Social"
    case chat = "Chat"
    case leagues = "Leagues"
    case leaderboard = "Leaderboard"
    case achievements = "Achievements"
    case profile = "Profile"
    
    var title: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .queue: return "timer.circle.fill"
        case .social: return "person.3.fill"
        case .chat: return "message.fill"
        case .leagues: return "flag.2.crossed.fill"
        case .leaderboard: return "trophy.fill"
        case .achievements: return "rosette"
        case .profile: return "person.crop.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .dashboard: return .blue
        case .queue: return .green
        case .social: return .purple
        case .chat: return .orange
        case .leagues: return .red
        case .leaderboard: return .yellow
        case .achievements: return .pink
        case .profile: return .indigo
        }
    }
}

// Enhanced Dashboard View (placeholder for now - we'll enhance this next)
struct EnhancedDashboardView: View {
    var body: some View {
        NavigationStack {
            DashboardView() // Using existing DashboardView for now
        }
    }
}

#Preview {
    SidebarHomeView()
        .environment(AppState())
} 