import SwiftUI
import Combine

// ─────────────────────────────────────────────────────────────
// Root container
struct SidebarHomeView: View {
    @State private var selected: SidebarItem = .dashboard
    @State private var showSidebar = false
    @Environment(\.horizontalSizeClass) private var hSize
    @EnvironmentObject private var analyticsService: AnalyticsService
    
    private var sidebarWidth: CGFloat { hSize == .regular ? 300 : 280 }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // —— Main content + (optional) sidebar side-by-side ——
                HStack(spacing: 0) {
                    
                    if hSize == .regular || showSidebar {
                        ModernSidebarView(
                            selectedItem: $selected,
                            showSidebar: $showSidebar,
                            sidebarWidth: sidebarWidth,
                            hSize: hSize            // pass size class
                        )
                        .frame(width: sidebarWidth)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    if hSize == .regular { Divider() }
                    
                    // ---------------- Main pane ----------------
                    selectedScreen
                        .id(selected)                      // ← key fix
                        .frame(maxWidth: .infinity,
                               maxHeight: .infinity)
                        .background(DS.Color.background)
                        .ignoresSafeArea()                 // background only
                }
                .animation(.easeOut(duration: 0.25), value: showSidebar)
                .animation(.easeInOut(duration: 0.2), value: selected) // polish
                
                // Dim overlay that covers only the main-content area (not the sidebar) on phones
                if showSidebar && hSize == .compact {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        // Leave the sidebar region untouchable so taps pass through
                        .padding(.leading, sidebarWidth)
                        .onTapGesture { withAnimation { showSidebar = false } }
                        .transition(.opacity)
                }
            }
            .navigationTitle(selected.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if hSize == .compact {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            withAnimation { showSidebar.toggle() }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            HamburgerButton(
                                isActive: $showSidebar,
                                size: 18,
                                color: DS.Color.primary
                            )
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToQueue)) { _ in
                print("🔥 SidebarHomeView: Received navigateToQueue notification - switching to queue")
                withAnimation {
                    selected = .queue
                    // Close sidebar on phones after navigation
                    if hSize == .compact {
                        showSidebar = false
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToTournaments)) { _ in
                print("🏆 SidebarHomeView: Received navigateToTournaments notification - switching to tournaments")
                withAnimation {
                    selected = .tournaments
                    // Close sidebar on phones after navigation
                    if hSize == .compact {
                        showSidebar = false
                    }
                }
            }
        }
    }
    
    // ─────────────────────────────────────────────────────────────
    // Simple router - moved inside struct to access environment objects
    @ViewBuilder
    private var selectedScreen: some View {
        switch selected {
        case .dashboard:    DashboardView()
        case .queue:        QueueView()
        case .tournaments:  TournamentTabView()
        case .social:       SocialView()
        case .courts:       CourtView()
        case .chat:         ChatView()
        case .leagues:      LeaguesHomeView()
        case .leaderboard:  LeaderboardView()
        case .achievements: AchievementsView()
        case .missions:     MissionsView()
        case .analytics:    XPAnalyticsView(analyticsService: analyticsService)
        case .profile:      ProfileView()
        }
    }
}

// ─────────────────────────────────────────────────────────────
// Sidebar + items (unchanged except for compact-only close)

struct ModernSidebarView: View {
    @Binding var selectedItem: SidebarItem
    @Binding var showSidebar: Bool
    let sidebarWidth: CGFloat
    let hSize: UserInterfaceSizeClass?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sportscourt.fill")
                    .font(.title2)
                    .foregroundColor(DS.Color.accent)
                Text("DinkDropZone")
                    .font(DS.Font.title2).bold()
            }
            .padding(.top, 60)
            .padding(.horizontal, 20)
            
            // Menu list
            ScrollView(showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(SidebarItem.allCases) { item in
                        ModernSidebarItemView(
                            item: item,
                            isSelected: item == selectedItem
                        ) {
                            selectedItem = item
                            // Close only on phones
                            if hSize == .compact {
                                withAnimation { showSidebar = false }
                            }
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(alignment: .center) {
            if hSize == .compact {
                Rectangle().fill(.ultraThinMaterial)
            } else {
                DS.Color.surface
            }
        }
    }
}

struct ModernSidebarItemView: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void

    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? item.color : DS.Color.secondary)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected ? item.color.opacity(0.15) : Color.clear)
                        )

                    // Unread badge for Social item
                    if item == .social && appState.unreadNotifications.count > 0 {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                            .transition(.scale)
                    }
                }
                
                Text(item.title)
                    .font(DS.Font.body)
                    .foregroundColor(isSelected ? DS.Color.primary : DS.Color.secondary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? item.color.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// ─────────────────────────────────────────────────────────────
// Enum + preview remain as before

// MARK: - Sidebar metadata

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case queue = "Play Hub"
    case tournaments = "Tournaments"
    case social = "Social"
    case courts = "Courts"
    case chat = "Chat"
    case leagues = "Leagues"
    case leaderboard = "Leaderboard"
    case achievements = "Achievements"
    case missions = "Missions"
    case analytics = "Analytics"
    case profile = "Profile"

    var id: String { rawValue }

    var title: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "chart.bar.fill"
        case .queue: return "timer.circle.fill"
        case .tournaments: return "trophy.circle"
        case .social: return "person.3.fill"
        case .courts: return "sportscourt"
        case .chat: return "message.fill"
        case .leagues: return "flag.2.crossed.fill"
        case .leaderboard: return "trophy.fill"
        case .achievements: return "rosette"
        case .missions: return "target"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .profile: return "person.crop.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .dashboard: return .blue
        case .queue: return .green
        case .tournaments: return .brown
        case .social: return .purple
        case .courts: return .mint
        case .chat: return .orange
        case .leagues: return .red
        case .leaderboard: return .yellow
        case .achievements: return .pink
        case .missions: return .cyan
        case .analytics: return .teal
        case .profile: return .indigo
        }
    }
}

// MARK: - Preview

#Preview {
    SidebarHomeView()
        .environmentObject(AppState())
}
