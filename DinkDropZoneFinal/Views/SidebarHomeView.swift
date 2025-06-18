import SwiftUI

/// Root container -----------------------------------------------------------
struct SidebarHomeView: View {
    @State private var selected: SidebarItem = .dashboard
    @State private var showSidebar = false
    @Environment(\.horizontalSizeClass) private var hSize
    
    // A single source of truth for sidebar width
    private var sidebarWidth: CGFloat {
        hSize == .regular ? 300 : 280
    }
    
    var body: some View {
        NavigationStack {
            ZStack {               // Needed only for the dim‑background on phone
                // —— Main content + (optional) sidebar side‑by‑side ——
                HStack(spacing: 0) {
                    
                    if hSize == .regular || showSidebar {
                        ModernSidebarView(
                            selectedItem: $selected,
                            showSidebar: $showSidebar,
                            sidebarWidth: sidebarWidth
                        )
                        .frame(width: sidebarWidth)
                        .transition(AnyTransition.move(edge: .leading).combined(with: .opacity))
                    }
                    
                    // A divider is nice when the sidebar is permanently shown
                    if hSize == .regular { Divider() }
                    
                    // ---------------- Main pane ----------------
                    SelectedScreen(selected)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(DS.Color.background)
                        .ignoresSafeArea()          // background only
                }
                .animation(.easeOut(duration: 0.25), value: showSidebar)
                
                // Dimmed overlay for tap‑to‑dismiss on compact widths
                if showSidebar && hSize == .compact {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation { showSidebar = false } }
                        .transition(.opacity)
                }
            }
            .navigationTitle(selected.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Hamburger visible only when sidebar is hidden in compact size
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
        }
    }
}

/// Simple type‑erased router (keeps your original switch‑on‑enum logic)
@ViewBuilder
private func SelectedScreen(_ item: SidebarItem) -> some View {
    switch item {
    case .dashboard:    DashboardView()
    case .queue:        QueueView()
    case .social:       SocialView()
    case .courts:       CourtView()
    case .chat:         ChatView()
    case .leagues:      LeaguesHomeView()
    case .leaderboard:  LeaderboardView()
    case .achievements: AchievementsView()
    case .missions:     MissionsView()
    case .analytics:    XPAnalyticsView()
    case .profile:      ProfileView()
    }
}

// MARK: - Supporting types

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case queue = "Play Hub"
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

struct ModernSidebarView: View {
    @Binding var selectedItem: SidebarItem
    @Binding var showSidebar: Bool
    let sidebarWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App title / header
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
                        ModernSidebarItemView(item: item, isSelected: item == selectedItem) {
                            selectedItem = item
                            withAnimation { showSidebar = false }
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.surface)
    }
}

struct ModernSidebarItemView: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? item.color : DS.Color.secondary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? item.color.opacity(0.15) : Color.clear)
                    )

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
        .buttonStyle(PlainButtonStyle())
    }
}
