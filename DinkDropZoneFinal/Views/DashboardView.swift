import SwiftUI
import Charts
import SwiftData

// MARK: - GameMatch Wrapper

/// Wrapper to bridge GameMatch to Match interface
struct GameMatchWrapper {
    let gameMatch: GameMatch
    
    var id: UUID { gameMatch.id }
    var date: Date { gameMatch.date }
    var score: String { gameMatch.score }
    var eloChange: String { gameMatch.eloChange }
    
    func opponent(for user: User) -> String {
        return gameMatch.opponentName
    }
    
    func result(for user: User) -> String {
        return gameMatch.result
    }
}

// GameMatchWrapper provides a bridge between GameMatch and expected interface

struct DashboardView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(XPManager.self) private var xpManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var selectedMetric: PerformanceChartView.PerformanceMetric = .elo
    @State private var isRefreshing = false
    @State private var performanceData: [PerformanceData] = []

    @State private var showingNearbyPlayers = false
    @State private var showingStatistics = false
    @State private var showingProfile = false
    @State private var showingMissions = false
    @State private var animateContent = false
    
    enum TimeFrame: String, CaseIterable {
        case day = "24h"
        case week = "Week"
        case month = "Month"
        case all = "All Time"
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            case .all: return 90
            }
        }
    }
    
    private var shouldShowSidebarPadding: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Welcome Header - Properly positioned to avoid sidebar and navigation bar
                    welcomeHeaderWithSafeArea(safeAreaTop: safeAreaTop)
                    
                    // Main content with proper spacing and sidebar consideration
                    VStack(spacing: DS.Layout.sectionSpacing) {
                                            // Enhanced Stats Overview with staggered animation
                    if let user = appState.currentUser {
                        statsSection(user: user)
                            .dsStaggeredAppear(index: 0, total: 6)
                    }
                    
                    // Redesigned Quick Actions with staggered animation
                    enhancedQuickActionsSection
                        .dsStaggeredAppear(index: 1, total: 6)
                    
                    // Nearby Players with staggered animation
                    nearbyPlayersSection
                        .dsStaggeredAppear(index: 2, total: 6)
                    
                    // Performance Chart with staggered animation
                    performanceChartSection
                        .dsStaggeredAppear(index: 3, total: 6)
                    
                    // Daily Challenges with staggered animation
                    dailyChallengesSection
                        .dsStaggeredAppear(index: 4, total: 6)
                    
                    // Recent Activity with staggered animation
                    recentActivitySection
                        .dsStaggeredAppear(index: 5, total: 6)
                    }
                    .padding(.horizontal, DS.Layout.horizontalPadding)
                    .padding(.top, DS.Layout.sectionSpacing)
                    .padding(.bottom, max(safeAreaBottom, 20) + 60)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
                }
            }
            .refreshable {
                await refreshData()
            }
            .overlay(alignment: .bottomTrailing) {
                // Floating Action Button - Positioned for sidebar navigation with enhanced animations
                DSPremiumFloatingButton(
                    icon: "plus",
                    color: DS.Color.accent
                ) {
                    // Navigate to Queue tab
                    print("🔥 Dashboard: Floating Action Button tapped - posting navigateToQueue notification")
                    NotificationCenter.default.post(name: .navigateToQueue, object: nil)
                }
                .padding(.trailing, DS.Layout.horizontalPadding)
                .padding(.bottom, max(safeAreaBottom, 20) + 20)
                .scaleEffect(animateContent ? 1 : 0)
                .animation(DS.SpringPreset.bouncy.delay(0.8), value: animateContent)
                .dsPulse(isActive: animateContent, scale: 1.1)
                .dsBouncyPress()
            }
        }
        .background(DS.Color.backgroundGradient)
        .onReceive(NotificationCenter.default.publisher(for: .navigateToQueue)) { _ in
            // This will be handled by the parent HomeTabView
        }
        .sheet(isPresented: $showingNearbyPlayers) {
            if let sheet = appState.nearbyPlayersSheet {
                sheet
            }
        }
        .sheet(isPresented: $showingStatistics) {
            if let user = appState.currentUser {
                StatisticsView(user: user)
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        .sheet(isPresented: $showingMissions) {
            MissionsView()
        }
        .onAppear {
            loadPerformanceData()
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Safe Area Aware Welcome Header
    
    private func welcomeHeaderWithSafeArea(safeAreaTop: CGFloat) -> some View {
        ZStack {
            // Enhanced gradient background
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            DS.Color.accent.opacity(0.9),
                            DS.Color.accentAlt.opacity(0.7),
                            DS.Color.accent.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Subtle pattern overlay
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 300, height: 300)
                        .offset(x: 100, y: -50)
                        .blur(radius: 20)
                )
            
            VStack(spacing: 0) {
                // Dynamic Island/Notch safe area spacer
                // This accounts for:
                // - iPhone 14 Pro/Pro Max: Dynamic Island (59pt)
                // - iPhone X-13 series: Notch (47pt)
                // - iPhone SE/8 and older: Status bar (20pt) + minimum space
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: max(safeAreaTop + 10, 54)) // Extra 10pt buffer, minimum 54pt
                
                // Navigation bar space for sidebar navigation
                // The sidebar navigation still has a navigation title area
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 50) // Slightly more space for navigation title
                
                // Content area with proper padding
                VStack(spacing: 20) {
                    // Top section with greeting and profile
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(getGreeting())
                                .font(DS.Font.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                            
                            if let user = appState.currentUser {
                                Text(user.displayName.isEmpty ? "Player" : user.displayName)
                                    .font(DS.Font.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            
                            // Status indicators with proper spacing
                            HStack(spacing: 12) {
                                statusBadge(icon: "circle.fill", text: "Online", color: .green)
                                
                                if let user = appState.currentUser {
                                    statusBadge(
                                        icon: "star.fill", 
                                        text: "Level \(XPManager.calculateLevel(from: user.xp))", 
                                        color: .orange
                                    )
                                }
                            }
                        }
                        
                        Spacer()
                        
                                        // Enhanced profile button with bounce animation
                profileButton
                    .dsBouncyPress()
                    }
                    .padding(.horizontal, DS.Layout.horizontalPadding)
                    
                    // Quick stats summary with improved layout
                    if let user = appState.currentUser {
                        HStack(spacing: 24) {
                            quickStatItem("ELO", "\(user.elo)", "chart.line.uptrend.xyaxis")
                            quickStatItem("Matches", "\(user.totalMatches)", "gamecontroller.fill")
                            quickStatItem("Win Rate", String(format: "%.0f%%", user.winRate * 100), "trophy.fill")
                        }
                        .padding(.horizontal, DS.Layout.horizontalPadding)
                    }
                }
                .padding(.bottom, 24) // Bottom padding for content
            }
        }
        .frame(height: calculateHeaderHeight(safeAreaTop: safeAreaTop))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 24,
                bottomTrailingRadius: 24,
                topTrailingRadius: 0
            )
        )
    }
    
    // Calculate dynamic header height based on device safe area
    private func calculateHeaderHeight(safeAreaTop: CGFloat) -> CGFloat {
        let dynamicIslandSpace = max(safeAreaTop + 10, 54) // Safe area + buffer
        let navigationSpace: CGFloat = 50 // Navigation title space
        let contentSpace: CGFloat = 160 // Content area
        
        return dynamicIslandSpace + navigationSpace + contentSpace
    }
    
    private func statusBadge(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(color)
            
            Text(text)
                .font(DS.Font.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.2))
        .clipShape(Capsule())
    }
    
    private var profileButton: some View {
        Button {
            showingProfile = true
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                
                if let user = appState.currentUser, let imageURL = user.profileImageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func quickStatItem(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Text(value)
                .font(DS.Font.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(DS.Font.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Content Sections
    
    private func statsSection(user: User) -> some View {
        VStack(spacing: 16) {
            DSPremiumSectionHeader(
                title: "Your Performance",
                subtitle: "Track your progress and achievements",
                icon: "chart.bar.fill",
                action: { showingStatistics = true }
            )
            
            DSGlassMorphismCard {
                enhancedStatsGridModern(user: user)
            }
        }
    }
    
    private var enhancedQuickActionsSection: some View {
        VStack(spacing: 16) {
            DSPremiumSectionHeader(
                title: "Quick Actions",
                subtitle: "Find matches and connect with players",
                icon: "bolt.fill"
            )
            
            enhancedQuickActionsModernGrid
        }
    }
    
    private var nearbyPlayersSection: some View {
        VStack(spacing: 16) {
            DSPremiumSectionHeader(
                title: "Nearby Players",
                subtitle: "\(appState.nearbyPlayers.count) players in your area",
                icon: "location.fill",
                action: { showingNearbyPlayers = true }
            )
            
            DSGlassMorphismCard {
                nearbyPlayersModernView
            }
        }
    }
    
    private var performanceChartSection: some View {
        VStack(spacing: 16) {
            DSPremiumSectionHeader(
                title: "Performance Analytics",
                subtitle: "Your game statistics over time",
                icon: "chart.line.uptrend.xyaxis"
            )
            
            DSGlassMorphismCard {
                performanceChartModernContent
            }
        }
    }
    
    private var dailyChallengesSection: some View {
        VStack(spacing: 16) {
            DSPremiumSectionHeader(
                title: "Daily Missions",
                subtitle: "Complete challenges to earn XP",
                icon: "target",
                action: { showingMissions = true }
            )
            
            dailyChallengesModernContent
        }
    }
    
    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            DSPremiumSectionHeader(
                title: "Recent Activity",
                subtitle: "Your latest matches and achievements",
                icon: "clock.fill"
            )
            
            DSGlassMorphismCard {
                recentActivityModernContent
            }
        }
    }
    
    // MARK: - Enhanced Stats Grid
    
    private func enhancedStatsGridModern(user: User) -> some View {
        VStack(spacing: 20) {
            // Featured stat card
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Rating")
                            .font(DS.Font.headline)
                            .fontWeight(.bold)
                            .foregroundColor(DS.Color.primary)
                        
                        Text("\(user.elo)")
                            .font(DS.Font.displayLarge)
                            .fontWeight(.black)
                            .foregroundColor(DS.Color.accent)
                        
                        Text("ELO Points")
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 40))
                        .foregroundColor(DS.Color.accent.opacity(0.6))
                }
                
                HStack(spacing: 20) {
                    statDetail("\(user.wins)", "Wins")
                    statDetail("\(user.losses)", "Losses")
                    statDetail(String(format: "%.0f%%", user.winRate * 100), "Win Rate")
                }
            }
            .padding()
            .background(DS.Color.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
            
            // Compact stats grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                CompactStatsCard(
                    title: "Level",
                    value: "\(XPManager.calculateLevel(from: user.xp))",
                    icon: "star.fill",
                    color: .orange,
                    showRing: true,
                    ringProgress: Double(user.xp % 1000) / 1000.0
                )
                
                CompactStatsCard(
                    title: "Streak",
                    value: "\(user.winStreak)",
                    icon: "flame.fill",
                    color: user.winStreak > 0 ? .red : .gray
                )
                
                CompactStatsCard(
                    title: "XP",
                    value: "\(user.xp)",
                    icon: "bolt.fill",
                    color: .blue
                )
            }
        }
    }
    
    private func statDetail(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DS.Font.title3)
                .fontWeight(.bold)
                .foregroundColor(DS.Color.primary)
            
            Text(label)
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Enhanced Quick Actions Grid
    
    private var enhancedQuickActionsModernGrid: some View {
        VStack(spacing: 16) {
            // Featured action - Large card for primary action
            featuredQuickAction
            
            // Secondary actions - Two column grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                secondaryQuickAction(
                    title: "Nearby Players",
                    subtitle: "Find local opponents",
                    icon: "location.fill",
                    color: .green,
                    badge: appState.nearbyPlayers.count > 0 ? "\(appState.nearbyPlayers.count)" : nil,
                    action: { showingNearbyPlayers = true }
                )
                
                secondaryQuickAction(
                    title: "Tournament",
                    subtitle: "Compete for prizes",
                    icon: "trophy.fill",
                    color: .orange,
                    badge: "NEW",
                    action: {
                        // Tournament action - could navigate to tournament view
                        print("Tournament tapped")
                    }
                )
                
                secondaryQuickAction(
                    title: "Practice",
                    subtitle: "Skills training",
                    icon: "target",
                    color: .purple,
                    badge: nil,
                    action: {
                        // Practice action
                        print("Practice tapped")
                    }
                )
                
                secondaryQuickAction(
                    title: "Statistics",
                    subtitle: "View your stats",
                    icon: "chart.bar.fill",
                    color: .blue,
                    badge: nil,
                    action: { showingStatistics = true }
                )
            }
            
            // Quick stats banner
            quickStatsBanner
        }
    }
    
    // Featured primary action
    private var featuredQuickAction: some View {
        DSGlassMorphismCard {
            Button(action: { 
                // Navigate to Queue tab
                print("🔥 Dashboard: Find Match button tapped - posting navigateToQueue notification")
                NotificationCenter.default.post(name: .navigateToQueue, object: nil)
            }) {
                HStack(spacing: 20) {
                    // Enhanced icon with animations
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(DS.Color.accent.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .blur(radius: 12)
                            .scaleEffect(animateContent ? 1.0 : 0.8)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateContent)
                        
                        // Main circle
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DS.Color.accent, DS.Color.accent.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                            .shadow(color: DS.Color.accent.opacity(0.4), radius: 10, x: 0, y: 4)
                        
                        // Icon
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    // Content
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Find Match")
                                .font(DS.Font.title2)
                                .fontWeight(.bold)
                                .foregroundColor(DS.Color.primary)
                            
                            Spacer()
                            
                            // Queue count badge
                            if appState.queueCount > 0 {
                                Text("\(appState.queueCount)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 24, minHeight: 24)
                                    .background(
                                        Circle()
                                            .fill(Color.red)
                                            .shadow(color: .red.opacity(0.4), radius: 4, x: 0, y: 2)
                                    )
                            }
                        }
                        
                        Text("Join matchmaking queue and find opponents")
                            .font(DS.Font.body)
                            .foregroundColor(DS.Color.secondary)
                            .lineLimit(3)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Status indicator
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            
                            Text("Ready to play")
                                .font(DS.Font.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(DS.Color.accent)
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            .buttonStyle(.plain)
        }
    }
    
    // Secondary action cards
    private func secondaryQuickAction(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        badge: String?,
        action: @escaping () -> Void
    ) -> some View {
        DSGlassMorphismCard {
            Button(action: action) {
                VStack(spacing: 12) {
                    // Icon with badge
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(color.opacity(0.4), lineWidth: 1)
                            )
                        
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(color)
                        
                        // Badge
                        if let badge = badge, !badge.isEmpty {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(badge == "NEW" ? Color.orange : Color.red)
                                        .shadow(color: (badge == "NEW" ? Color.orange : Color.red).opacity(0.4), radius: 3, x: 0, y: 2)
                                )
                                .offset(x: 20, y: -20)
                        }
                    }
                    
                    // Text content
                    VStack(spacing: 4) {
                        Text(title)
                            .font(DS.Font.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(DS.Color.primary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(subtitle)
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.7)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Bottom accent
                    Rectangle()
                        .fill(color.opacity(0.3))
                        .frame(width: 30, height: 2)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .padding(.vertical, 16)
                .padding(.horizontal, 12)
            }
            .buttonStyle(.plain)
        }
    }
    
    // Quick stats banner
    private var quickStatsBanner: some View {
        DSModernCard(style: .minimal) {
            HStack {
                quickStatBadge("Active", "\(appState.queueCount)", "timer", .blue)
                
                Spacer()
                
                quickStatBadge("Nearby", "\(appState.nearbyPlayers.count)", "location.fill", .green)
                
                Spacer()
                
                if let user = appState.currentUser {
                    quickStatBadge("Level", "\(user.level)", "star.fill", .orange)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }
    
    private func quickStatBadge(_ title: String, _ value: String, _ icon: String, _ color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(DS.Font.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(DS.Color.primary)
                
                Text(title)
                    .font(DS.Font.caption2)
                    .foregroundColor(DS.Color.secondary)
            }
        }
    }
    
    // MARK: - Nearby Players View
    
    private var nearbyPlayersModernView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if appState.nearbyPlayers.isEmpty {
                DSEmptyStateView(
                    icon: "location.slash",
                    title: "No nearby players",
                    message: "Enable location services to find players near you"
                )
                .frame(height: 100)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(appState.nearbyPlayers.prefix(5), id: \.id) { player in
                            NearbyPlayerModernCard(player: player)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    // MARK: - Performance Chart
    
    private var performanceChartModernContent: some View {
        VStack(spacing: 16) {
            // Chart controls
            VStack(spacing: 12) {
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(PerformanceChartView.PerformanceMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("Time Frame", selection: $selectedTimeFrame) {
                    ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                        Text(timeFrame.rawValue).tag(timeFrame)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedTimeFrame) { _, _ in
                    loadPerformanceData()
                }
            }
            
            // Chart content
            if performanceData.isEmpty {
                DSEmptyStateView(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "No performance data yet",
                    message: "Play more matches to see your progress"
                )
                .frame(height: 140)
            } else {
                PerformanceChartView(
                    data: performanceData.map { (date: $0.date, elo: $0.elo, winRate: $0.winRate) },
                    selectedMetric: selectedMetric
                )
                .frame(height: 180)
            }
        }
    }
    
    // MARK: - Daily Challenges
    
    private var dailyChallengesModernContent: some View {
        let dailyMissions = xpManager.getMissionsForDisplay().filter { $0.type.isDaily }.prefix(3)
        
        return Group {
            if dailyMissions.isEmpty {
                DSGlassMorphismCard {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 8) {
                            Text("All daily missions completed!")
                                .font(DS.Font.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(DS.Color.primary)
                            
                            Text("Great job! Check back tomorrow for new missions.")
                                .font(DS.Font.caption)
                                .foregroundColor(DS.Color.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(dailyMissions)) { mission in
                        missionCard(mission: mission)
                    }
                }
            }
        }
    }
    
    private func missionCard(mission: Mission) -> some View {
        DSGlassMorphismCard {
            HStack(spacing: 12) {
                Image(systemName: mission.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(mission.isCompleted ? .green : DS.Color.accent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(mission.type.title)
                        .font(DS.Font.body)
                        .fontWeight(.medium)
                        .foregroundColor(DS.Color.primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if !mission.isCompleted {
                        DSProgressBar(value: mission.progressPercentage, color: DS.Color.accent)
                            .frame(height: 4)
                        
                        Text("\(mission.progress)/\(mission.type.targetValue)")
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                    }
                    
                    Text("+\(mission.xpReward) XP")
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.warning)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Mission icon
                Image(systemName: mission.type.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(missionColor(mission.type.color))
                    .frame(width: 32, height: 32)
                    .background(missionColor(mission.type.color).opacity(0.2))
                    .clipShape(Circle())
            }
        }
    }
    
    private func missionColor(_ colorString: String) -> Color {
        switch colorString {
        case "blue": return .blue
        case "gold": return .orange
        case "purple": return .purple
        default: return DS.Color.accent
        }
    }
    
    // MARK: - Recent Activity
    
    private var recentActivityModernContent: some View {
        Group {
            if let recentMatches = appState.recentMatches, !recentMatches.isEmpty {
                VStack(spacing: 12) {
                    ForEach(recentMatches.prefix(3)) { match in
                        recentMatchCard(match: GameMatchWrapper(gameMatch: match))
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "sportscourt")
                        .font(.system(size: 40))
                        .foregroundColor(DS.Color.secondary.opacity(0.6))
                    
                    VStack(spacing: 8) {
                        Text("No recent matches")
                            .font(DS.Font.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(DS.Color.secondary)
                        
                        Text("Join a match to see your activity here")
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    Button("Find Match") {
                        // Navigate to Queue tab
                        print("🔥 Dashboard: Recent Activity Find Match button tapped - posting navigateToQueue notification")
                        NotificationCenter.default.post(name: .navigateToQueue, object: nil)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
    }
    
    private func recentMatchCard(match: GameMatchWrapper) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("vs \(match.opponent(for: appState.currentUser!))")
                    .font(DS.Font.body)
                    .fontWeight(.medium)
                    .foregroundColor(DS.Color.primary)
                
                Text(RelativeDateTimeFormatter().localizedString(for: match.date, relativeTo: Date()))
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(match.result(for: appState.currentUser!))
                    .font(DS.Font.body)
                    .fontWeight(.semibold)
                    .foregroundColor(match.result(for: appState.currentUser!) == "Win" ? .green : .red)
                
                Text(match.score)
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
                
                Text(match.eloChange)
                    .font(DS.Font.caption)
                    .foregroundColor(match.eloChange.hasPrefix("+") ? .green : .red)
            }
        }
        .padding()
        .background(DS.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
    }
    
    // MARK: - Helper Functions
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    private func loadPerformanceData() {
        if let user = appState.currentUser {
            var data: [PerformanceData] = []
            let calendar = Calendar.current
            let today = Date()
            
            var currentElo = max(1000, user.elo - Int(Double(user.elo - 1000) * 0.3))
            var totalMatches = max(0, user.totalMatches - Int(Double(user.totalMatches) * 0.8))
            var totalWins = max(0, user.wins - Int(Double(user.wins) * 0.8))
            
            for day in (0..<selectedTimeFrame.days).reversed() {
                let date = calendar.date(byAdding: .day, value: -day, to: today)!
                
                let matchesToday = Int.random(in: 0...3)
                let winsToday = Int.random(in: 0...matchesToday)
                
                totalMatches += matchesToday
                totalWins += winsToday
                
                let eloTarget = user.elo
                let eloChange = min(20, max(-20, (eloTarget - currentElo) / 10))
                currentElo += Int(eloChange)
                
                data.append(PerformanceData(
                    date: date,
                    elo: currentElo,
                    matches: totalMatches,
                    wins: totalWins
                ))
            }
            
            performanceData = data
        } else {
            performanceData = []
        }
    }
    
    private func refreshData() async {
        isRefreshing = true
        
        if let locationService = appState.locationService {
            if let loc = locationService.currentLocation {
                try? await FirebaseService.shared.updateLocation(
                    lat: loc.coordinate.latitude,
                    lon: loc.coordinate.longitude
                )
                
                if let nearbyService = appState.nearbyPlayersService {
                    await nearbyService.fetchNearby(center: loc)
                }
            }
        }
        
        loadPerformanceData()
        xpManager.checkMissionUpdates()
        
        isRefreshing = false
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environmentObject(AppState())
            .environment(XPManager())
    }
} 