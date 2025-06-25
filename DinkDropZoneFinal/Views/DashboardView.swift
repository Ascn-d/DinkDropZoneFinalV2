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
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var selectedMetric: PerformanceChartView.PerformanceMetric = .elo
    @State private var isRefreshing = false
    @State private var performanceData: [PerformanceData] = []
    @State private var showingMatchmaking = false
    @State private var showingNearbyPlayers = false
    @State private var showingStatistics = false
    @State private var showingProfile = false
    @State private var showingMissions = false
    
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Welcome Header with enhanced styling
                    welcomeHeaderEnhanced
                    
                    // Main content with modern sections
                    VStack(spacing: DS.Layout.sectionSpacing) {
                        // Enhanced Stats Overview
                        if let user = appState.currentUser {
                            DSModernSectionContainer(
                                title: "Your Performance",
                                subtitle: "Track your progress and achievements",
                                action: { showingStatistics = true }
                            ) {
                                enhancedStatsGridModern(user: user)
                            }
                        }
                        
                        // Quick Actions with modern cards
                        DSModernSectionContainer(
                            title: "Quick Actions",
                            subtitle: "Find matches and connect with players"
                        ) {
                            quickActionsModernGrid
                        }
                        
                        // Nearby Players Section with enhanced design
                        DSModernSectionContainer(
                            title: "Nearby Players",
                            subtitle: "\(appState.nearbyPlayers.count) players in your area",
                            action: { showingNearbyPlayers = true }
                        ) {
                            nearbyPlayersModernView
                        }
                        
                        // Performance Chart with enhanced styling
                        DSModernSectionContainer(
                            title: "Performance Analytics",
                            subtitle: "Your game statistics over time"
                        ) {
                            performanceChartModernContent
                        }
                        
                        // Daily Challenges with modern design
                        DSModernSectionContainer(
                            title: "Daily Missions",
                            subtitle: "Complete challenges to earn XP",
                            action: { showingMissions = true }
                        ) {
                            dailyChallengesModernContent
                        }
                        
                        // Recent Activity with enhanced cards
                        DSModernSectionContainer(
                            title: "Recent Activity",
                            subtitle: "Your latest matches and achievements"
                        ) {
                            recentActivityModernContent
                        }
                    }
                    .dsHorizontalPadding()
                    .padding(.bottom, 100) // Extra padding for tab bar
                }
            }
            .refreshable {
                await refreshData()
            }
            .sheet(isPresented: $showingMatchmaking) {
                MatchmakingView()
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
                animateOnAppear()
            }
        }
    }
    
    // MARK: - Enhanced Welcome Header
    
    private var welcomeHeaderEnhanced: some View {
        ZStack {
            // Enhanced gradient background
            LinearGradient(
                colors: [
                    DS.Color.accent.opacity(0.8),
                    DS.Color.accentAlt.opacity(0.6),
                    DS.Color.accent.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 200)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 24,
                    bottomTrailingRadius: 24,
                    topTrailingRadius: 0
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
            
            VStack(spacing: 20) {
                // Top section with greeting and profile
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(getGreeting())
                            .font(DS.Font.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                        
                        if let user = appState.currentUser {
                            Text(user.displayName.isEmpty ? "Player" : user.displayName)
                                .font(DS.Font.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        // Status indicators
                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                
                                Text("Online")
                                    .font(DS.Font.caption2)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                            
                            if let user = appState.currentUser {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                    Text("Level \(XPManager.calculateLevel(from: user.xp))")
                                        .font(DS.Font.caption2)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Enhanced profile button
                    Button {
                        showingProfile = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 60, height: 60)
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
                                }
                                .frame(width: 56, height: 56)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Layout.horizontalPadding)
                .padding(.top, 20)
                
                // Quick stats summary
                if let user = appState.currentUser {
                    HStack(spacing: 20) {
                        ForEach([
                            ("ELO", "\(user.elo)", "chart.line.uptrend.xyaxis"),
                            ("Matches", "\(user.totalMatches)", "gamecontroller.fill"),
                            ("Win Rate", String(format: "%.0f%%", user.winRate * 100), "trophy.fill")
                        ], id: \.0) { stat in
                            VStack(spacing: 4) {
                                Image(systemName: stat.2)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text(stat.1)
                                    .font(DS.Font.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(stat.0)
                                    .font(DS.Font.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, DS.Layout.horizontalPadding)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    // MARK: - Modern Stats Grid
    
    private func enhancedStatsGridModern(user: User) -> some View {
        VStack(spacing: 16) {
            // Featured stat card
            FeaturedStatsCard(
                title: "Current Rating",
                primaryValue: "\(user.elo)",
                primaryLabel: "ELO Points",
                secondaryStats: [
                    ("\(user.wins)", "Wins"),
                    ("\(user.losses)", "Losses"),
                    (String(format: "%.0f%%", user.winRate * 100), "Win Rate")
                ],
                icon: "chart.bar.fill",
                color: DS.Color.accent
            )
            
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
    
    // MARK: - Modern Quick Actions
    
    private var quickActionsModernGrid: some View {
        VStack(spacing: 12) {
            // Primary actions
            HStack(spacing: 12) {
                QuickActionCard(
                    title: "Find Match",
                    subtitle: "Join matchmaking queue",
                    icon: "person.2.fill",
                    color: .blue,
                    badge: appState.queueCount > 0 ? "\(appState.queueCount)" : nil
                ) {
                    showingMatchmaking = true
                }
                
                QuickActionCard(
                    title: "Nearby Players",
                    subtitle: "Find local players",
                    icon: "location.fill",
                    color: .green,
                    badge: appState.nearbyPlayers.count > 0 ? "\(appState.nearbyPlayers.count)" : nil
                ) {
                    showingNearbyPlayers = true
                }
            }
            
            // Secondary actions
            HStack(spacing: 12) {
                EnhancedQuickActionCard(
                    title: "Tournament",
                    subtitle: "Join competitive play",
                    icon: "trophy.fill",
                    color: .orange,
                    badge: "NEW",
                    showChevron: true
                ) {
                    // Tournament action
                }
                
                EnhancedQuickActionCard(
                    title: "Practice",
                    subtitle: "Improve your skills",
                    icon: "target",
                    color: .purple,
                    isEnabled: false
                ) {
                    // Practice action
                }
            }
        }
    }
    
    // MARK: - Modern Nearby Players
    
    private var nearbyPlayersModernView: some View {
        VStack(alignment: .leading, spacing: 12) {
            if appState.nearbyPlayers.isEmpty {
                DSEmptyStateView(
                    icon: "location.slash",
                    title: "No nearby players",
                    message: "Enable location services to find players near you"
                )
                .frame(height: 120)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(appState.nearbyPlayers.prefix(5), id: \.id) { player in
                            NearbyPlayerModernCard(player: player)
                        }
                    }
                    .padding(.horizontal, DS.Layout.horizontalPadding)
                }
                .padding(.horizontal, -DS.Layout.horizontalPadding)
            }
        }
    }
    
    // MARK: - Modern Performance Chart
    
    private var performanceChartModernContent: some View {
        DSModernCard(style: .standard) {
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
                    .frame(height: 160)
                } else {
                    PerformanceChartView(
                        data: performanceData.map { (date: $0.date, elo: $0.elo, winRate: $0.winRate) },
                        selectedMetric: selectedMetric
                    )
                    .frame(height: 200)
                }
            }
        }
    }
    
    // MARK: - Modern Daily Challenges
    
         private var dailyChallengesModernContent: some View {
         let dailyMissions = xpManager.getMissionsForDisplay().filter { $0.type.isDaily }.prefix(3)
         
         return Group {
             if dailyMissions.isEmpty {
                 DSModernCard(style: .gradient) {
                     VStack(spacing: 12) {
                         Image(systemName: "checkmark.circle.fill")
                             .font(.system(size: 40))
                             .foregroundColor(.green)
                         
                         Text("All daily missions completed!")
                             .font(DS.Font.subheadline)
                             .fontWeight(.semibold)
                             .foregroundColor(DS.Color.primary)
                         
                         Text("Great job! Check back tomorrow for new missions.")
                             .font(DS.Font.caption)
                             .foregroundColor(DS.Color.secondary)
                             .multilineTextAlignment(.center)
                     }
                     .frame(maxWidth: .infinity)
                     .padding(.vertical, 20)
                 }
             } else {
                 VStack(spacing: 12) {
                     ForEach(Array(dailyMissions)) { mission in
                         ModernMissionCard(mission: mission)
                     }
                 }
             }
         }
     }
    
    // MARK: - Modern Recent Activity
    
         private var recentActivityModernContent: some View {
         return Group {
             if let recentMatches = appState.recentMatches, !recentMatches.isEmpty {
                 VStack(spacing: 12) {
                     ForEach(recentMatches.prefix(3)) { match in
                         ModernRecentMatchCard(match: GameMatchWrapper(gameMatch: match))
                     }
                 }
             } else {
                 DSModernCard(style: .minimal) {
                     VStack(spacing: 12) {
                         Image(systemName: "sportscourt")
                             .font(.system(size: 36))
                             .foregroundColor(DS.Color.secondary.opacity(0.6))
                         
                         VStack(spacing: 4) {
                             Text("No recent matches")
                                 .font(DS.Font.subheadline)
                                 .fontWeight(.medium)
                                 .foregroundColor(DS.Color.secondary)
                             
                             Text("Join a match to see your activity here")
                                 .font(DS.Font.caption)
                                 .foregroundColor(DS.Color.secondary)
                                 .multilineTextAlignment(.center)
                         }
                         
                         DSPrimaryButton("Find Match", icon: "person.2.fill") {
                             showingMatchmaking = true
                         }
                         .padding(.top, 8)
                     }
                     .frame(maxWidth: .infinity)
                     .padding(.vertical, 20)
                 }
             }
         }
     }
    
    // MARK: - Helper Functions
    
    private func animateOnAppear() {
        // Add entrance animations for elements
        withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
            // Trigger any entrance animations
        }
    }
    
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
            // In a real app, we'd fetch this from a service
            // For now, generate sample data based on the user's actual stats
            var data: [PerformanceData] = []
            let calendar = Calendar.current
            let today = Date()
            
            var currentElo = max(1000, user.elo - Int(Double(user.elo - 1000) * 0.3))
            var totalMatches = max(0, user.totalMatches - Int(Double(user.totalMatches) * 0.8))
            var totalWins = max(0, user.wins - Int(Double(user.wins) * 0.8))
            
            for day in (0..<selectedTimeFrame.days).reversed() {
                let date = calendar.date(byAdding: .day, value: -day, to: today)!
                
                // Generate random matches for the day (0-3 matches)
                let matchesToday = Int.random(in: 0...3)
                let winsToday = Int.random(in: 0...matchesToday)
                
                // Update totals
                totalMatches += matchesToday
                totalWins += winsToday
                
                // Calculate ELO change (trending upward toward current ELO)
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
        // Refresh nearby players
        if let locationService = appState.locationService {
            if let loc = locationService.currentLocation {
                try? await FirebaseService.shared.updateLocation(
                    lat: loc.coordinate.latitude,
                    lon: loc.coordinate.longitude
                )
                
                if let nearbyService = appState.nearbyPlayersService {
                    // This will update appState.nearbyPlayers
                    await nearbyService.fetchNearby(center: loc)
                }
            }
        }
        
        // Refresh performance data
        loadPerformanceData()
        
        // Refresh missions
        xpManager.checkMissionUpdates()
        
        isRefreshing = false
    }
}

// MARK: - Supporting Views

struct RecentMatchCard: View {
    let match: GameMatch
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: match.date, relativeTo: Date())
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(match.opponentName)
                    .font(DS.Font.headline)
                Text(formattedDate)
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(match.result)
                    .font(DS.Font.headline)
                    .foregroundColor(match.result == "Win" ? .green : .red)
                Text(match.score)
                    .font(DS.Font.subheadline)
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
}

// MARK: - View Extensions

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environmentObject(AppState())
            .environment(XPManager())
    }
} 