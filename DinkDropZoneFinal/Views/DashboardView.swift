import SwiftUI
import Observation

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @Environment(XPManager.self) private var xpManager
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var selectedMetric: PerformanceChartView.PerformanceMetric = .elo
    @State private var isRefreshing = false
    @State private var performanceData: [PerformanceData] = []
    @State private var showingMatchmaking = false
    @State private var showingPractice = false
    @State private var showingTournament = false
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
        ScrollView {
            VStack(spacing: 24) {
                // Welcome header
                welcomeHeader
                
                // Enhanced Stats Overview
                if let user = appState.currentUser {
                    enhancedStatsOverview(user: user)
                }
                
                // Live Activity Feed
                liveActivitySection
                
                // Quick Actions
                enhancedQuickActions
                
                // Performance Chart
                performanceChart
                
                // Recent Activity
                recentActivity
                
                // Daily Challenges
                dailyChallengesSection
            }
            .padding()
        }
        .navigationTitle("Dashboard")
        .refreshable {
            await refreshData()
        }
        .sheet(isPresented: $showingMatchmaking) {
            MatchmakingView()
        }
        .sheet(isPresented: $showingPractice) {
            PracticeView()
        }
        .sheet(isPresented: $showingTournament) {
            TournamentView()
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
        }
    }
    
    // MARK: - Welcome Header
    
    private var welcomeHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(getGreeting())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let user = appState.currentUser {
                        Text(user.displayName.isEmpty ? "Player" : user.displayName)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                Spacer()
                
                // Profile button
                Button {
                    showingProfile = true
                } label: {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.blue)
                        )
                }
            }
            
            // Online status
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("\(appState.onlineUsersCount) players online")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Text("Ready to play? 🏓")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Enhanced Stats Overview
    
    private func enhancedStatsOverview(user: User) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Performance")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("View Details") {
                    showingStatistics = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                AnimatedStatsCard(
                    title: "ELO Rating",
                    value: "\(user.elo)",
                    subtitle: getELORank(user.elo),
                    icon: "star.fill",
                    color: eloColor(for: user.elo),
                    animationDelay: 0.0
                )
                
                AnimatedStatsCard(
                    title: "Win Rate",
                    value: "\(calculateWinRate())%",
                    subtitle: "Last 30 days",
                    icon: "chart.line.uptrend.xyaxis",
                    color: winRateColor(for: Double(calculateWinRate()) / 100.0),
                    animationDelay: 0.1
                )
                
                AnimatedStatsCard(
                    title: "Experience",
                    value: "\(xpManager.currentXP)",
                    subtitle: "Level \(xpManager.currentLevel)",
                    icon: "bolt.fill",
                    color: .orange,
                    animationDelay: 0.2
                )
                
                AnimatedStatsCard(
                    title: "Win Streak",
                    value: "\(user.winStreak)",
                    subtitle: user.winStreak > 0 ? "wins" : "games",
                    icon: "flame.fill",
                    color: user.winStreak > 0 ? .red : .gray,
                    animationDelay: 0.3
                )
            }
        }
    }
    
    // MARK: - Live Activity Section
    
    private var liveActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Live Activity")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to full activity feed
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(getLiveActivities()) { activity in
                        LiveActivityCard(activity: activity)
                            .frame(width: 280)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Enhanced Quick Actions
    
    private var enhancedQuickActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    title: "Find Match",
                    subtitle: "Join queue",
                    icon: "person.2.fill",
                    color: .blue,
                    badge: "\(Int.random(in: 15...25))"
                ) {
                    showingMatchmaking = true
                }
                
                QuickActionCard(
                    title: "Practice",
                    subtitle: "Skill training",
                    icon: "figure.table.tennis",
                    color: .green,
                    badge: nil
                ) {
                    showingPractice = true
                }
                
                QuickActionCard(
                    title: "Tournament",
                    subtitle: "Compete",
                    icon: "trophy.fill",
                    color: .orange,
                    badge: "3 active"
                ) {
                    showingTournament = true
                }
            }
        }
    }
    
    // MARK: - Daily Challenges Section
    
    private var dailyChallengesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Missions")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("View All") {
                    showingMissions = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            let dailyMissions = xpManager.getMissionsForDisplay().filter { $0.type.isDaily }.prefix(3)
            
            if dailyMissions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("All daily missions completed!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Great job! Check back tomorrow for new missions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(dailyMissions)) { mission in
                        CompactMissionCard(mission: mission)
                    }
                }
            }
        }
    }
    
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                QuickActionButton(
                    title: "Find Match",
                    icon: "person.2.fill",
                    color: .blue
                ) {
                    showingMatchmaking = true
                }
                
                QuickActionButton(
                    title: "Practice",
                    icon: "figure.table.tennis",
                    color: .green
                ) {
                    showingPractice = true
                }
                
                QuickActionButton(
                    title: "Tournament",
                    icon: "trophy.fill",
                    color: .orange
                ) {
                    showingTournament = true
                }
                
                QuickActionButton(
                    title: "Missions",
                    icon: "target",
                    color: .purple
                ) {
                    showingMissions = true
                }
            }
        }
    }
    
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to full activity history
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 12) {
                ForEach(getRecentMatches()) { match in
                    RecentMatchCard(
                        opponent: match.opponent,
                        result: match.result,
                        score: match.score,
                        eloChange: match.eloChange,
                        date: match.date
                    )
                }
            }
        }
    }
    
    private var performanceChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Performance")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(PerformanceChartView.PerformanceMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Picker("Time Frame", selection: $selectedTimeFrame) {
                ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                    Text(timeFrame.rawValue).tag(timeFrame)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTimeFrame) { _, _ in
                loadPerformanceData()
            }
            
            PerformanceChartView(
                data: performanceData,
                selectedMetric: selectedMetric
            )
        }
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
    
    private func getELORank(_ elo: Int) -> String {
        switch elo {
        case 0..<1000: return "Bronze"
        case 1000..<1300: return "Silver"
        case 1300..<1600: return "Gold"
        case 1600..<1900: return "Platinum"
        case 1900..<2200: return "Diamond"
        case 2200..<2500: return "Master"
        default: return "Legend"
        }
    }
    
    private func eloColor(for elo: Int) -> Color {
        switch elo {
        case 0..<1000: return Color.orange.opacity(0.8)
        case 1000..<1300: return .gray
        case 1300..<1600: return .yellow
        case 1600..<1900: return .cyan
        case 1900..<2200: return .blue
        case 2200..<2500: return .purple
        default: return .red
        }
    }
    
    private func winRateColor(for winRate: Double) -> Color {
        switch winRate {
        case 0.0..<0.4: return .red
        case 0.4..<0.6: return .orange
        case 0.6..<0.8: return .blue
        default: return .green
        }
    }
    
    private func getLiveActivities() -> [LiveActivity] {
        return [
            LiveActivity(
                type: .match,
                title: "Sarah vs Mike",
                description: "Intense match at Golden Gate Park",
                isLive: true,
                metadata: ["Court": "1", "Score": "8-6"],
                pulseAnimation: true
            ),
            LiveActivity(
                type: .tournament,
                title: "Friday Championship",
                description: "Semi-finals starting now",
                isLive: true,
                metadata: ["Players": "8", "Round": "Semi"],
                pulseAnimation: true
            ),
            LiveActivity(
                type: .achievement,
                title: "Emma's Milestone",
                description: "Reached 1800 ELO rating!",
                timestamp: Date().addingTimeInterval(-300),
                isLive: false,
                metadata: ["ELO": "1800", "Rank": "Platinum"]
            )
        ]
    }
    
    private func loadPerformanceData() {
        performanceData = PerformanceData.generateSampleData(days: selectedTimeFrame.days)
    }
    
    private func refreshData() async {
        isRefreshing = true
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadPerformanceData()
        isRefreshing = false
    }
    
    private func calculateEloChange() -> String {
        guard performanceData.count >= 2 else { return "+0" }
        let change = performanceData.last!.elo - performanceData.first!.elo
        return change >= 0 ? "+\(change)" : "\(change)"
    }
    
    private func calculateXPChange() -> String {
        // Simulate XP change
        return "+\(Int.random(in: 50...150))"
    }
    
    private func calculateWinRate() -> Int {
        guard !performanceData.isEmpty else { return 0 }
        let latest = performanceData.last!
        return Int(latest.winRate * 100)
    }
    
    private func calculateWinRateChange() -> String {
        guard performanceData.count >= 2 else { return "+0%" }
        let current = performanceData.last!.winRate
        let previous = performanceData[performanceData.count - 2].winRate
        let change = Int((current - previous) * 100)
        return change >= 0 ? "+\(change)%" : "\(change)%"
    }
    
    private func calculateTotalMatches() -> Int {
        guard !performanceData.isEmpty else { return 0 }
        return performanceData.last!.matches
    }
    
    private func calculateMatchesChange() -> String {
        guard performanceData.count >= 2 else { return "+0" }
        let current = performanceData.last!.matches
        let previous = performanceData[performanceData.count - 2].matches
        let change = current - previous
        return change >= 0 ? "+\(change)" : "\(change)"
    }
    
    private func getRecentMatches() -> [RecentMatch] {
        // TODO: Implement actual recent matches fetching
        // Sample placeholder data
        return [
            RecentMatch(opponent: "Alex Turner", result: "Win", score: "11-8", eloChange: "+10", date: Date()),
            RecentMatch(opponent: "Emma Wilson", result: "Loss", score: "9-11", eloChange: "-8", date: Date().addingTimeInterval(-3600))
        ]
    }
}

// MARK: - Supporting Types

struct RecentMatch: Identifiable {
    let id = UUID()
    let opponent: String
    let result: String
    let score: String
    let eloChange: String
    let date: Date
}

// MARK: - Supporting Views

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let badge: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    if let badge = badge {
                        Text(badge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 20, y: -20)
                    }
                }
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DailyChallengeCard: View {
    let challenge: DailyChallenge
    
    var body: some View {
        HStack(spacing: 12) {
            // Challenge icon
            ZStack {
                Circle()
                    .fill(challenge.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: challenge.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(challenge.type.color)
            }
            
            // Challenge info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(challenge.type.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if challenge.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Text("\(challenge.xpReward) XP")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
                
                Text(challenge.type.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Progress bar
                if !challenge.isCompleted {
                    ProgressView(value: Double(challenge.progress), total: Double(challenge.type.targetValue))
                        .progressViewStyle(LinearProgressViewStyle(tint: challenge.type.color))
                        .scaleEffect(x: 1, y: 0.5, anchor: .center)
                }
            }
        }
        .padding()
        .background(
            challenge.isCompleted ? 
            Color.green.opacity(0.1) : 
            Color(.secondarySystemBackground)
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    challenge.isCompleted ? 
                    Color.green.opacity(0.3) : 
                    Color.clear, 
                    lineWidth: 1
                )
        )
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RecentMatchCard: View {
    let opponent: String
    let result: String
    let score: String
    let eloChange: String
    let date: Date
    
    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(opponent)
                    .font(.headline)
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(result)
                    .font(.headline)
                    .foregroundColor(result == "Win" ? .green : .red)
                Text(score)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(eloChange)
                    .font(.caption)
                    .foregroundColor(eloChange.hasPrefix("+") ? .green : .red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Placeholder Views

struct PracticeView: View {
    var body: some View {
        Text("Practice View")
    }
}

struct TournamentView: View {
    var body: some View {
        Text("Tournament View")
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(AppState())
    }
} 