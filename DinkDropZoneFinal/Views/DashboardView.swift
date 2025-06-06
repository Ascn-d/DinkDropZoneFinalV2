import SwiftUI
import Observation

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var selectedMetric: PerformanceChartView.PerformanceMetric = .elo
    @State private var isRefreshing = false
    @State private var performanceData: [PerformanceData] = []
    @State private var showingMatchmaking = false
    @State private var showingPractice = false
    @State private var showingTournament = false
    
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
            VStack(spacing: 20) {
                // Stats Overview
                if let user = appState.currentUser {
                    statsOverview(user: user)
                }
                
                // Quick Actions
                quickActions
                
                // Recent Activity
                recentActivity
                
                // Performance Chart
                performanceChart
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
        .onAppear {
            loadPerformanceData()
        }
    }
    
    private func statsOverview(user: User) -> some View {
        VStack(spacing: 16) {
            // ELO and XP Cards
            HStack(spacing: 16) {
                // ELO Card
                StatCard(
                    title: "ELO Rating",
                    value: "\(user.elo)",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue,
                    change: calculateEloChange()
                )
                
                // XP Card
                StatCard(
                    title: "Experience",
                    value: "\(user.xp)",
                    icon: "star.fill",
                    color: .orange,
                    change: calculateXPChange()
                )
            }
            
            // Win Rate and Matches Cards
            HStack(spacing: 16) {
                // Win Rate Card
                StatCard(
                    title: "Win Rate",
                    value: "\(calculateWinRate())%",
                    icon: "trophy.fill",
                    color: .green,
                    change: calculateWinRateChange()
                )
                
                // Matches Card
                StatCard(
                    title: "Matches",
                    value: "\(calculateTotalMatches())",
                    icon: "gamecontroller.fill",
                    color: .purple,
                    change: calculateMatchesChange()
                )
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
        performanceData.last?.matches ?? 0
    }
    
    private func calculateMatchesChange() -> String {
        guard performanceData.count >= 2 else { return "+0" }
        let change = performanceData.last!.matches - performanceData[performanceData.count - 2].matches
        return change >= 0 ? "+\(change)" : "\(change)"
    }
    
    private func getRecentMatches() -> [RecentMatch] {
        // Simulate recent matches
        return [
            RecentMatch(opponent: "John Doe", result: "Win", score: "11-8", eloChange: "+15", date: "2 hours ago"),
            RecentMatch(opponent: "Jane Smith", result: "Loss", score: "9-11", eloChange: "-12", date: "5 hours ago"),
            RecentMatch(opponent: "Mike Johnson", result: "Win", score: "11-7", eloChange: "+18", date: "1 day ago")
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
    let date: String
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let change: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(change)
                .font(.caption)
                .foregroundColor(change.hasPrefix("+") ? .green : .red)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            )
        }
    }
}

struct RecentMatchCard: View {
    let opponent: String
    let result: String
    let score: String
    let eloChange: String
    let date: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(opponent)
                    .font(.headline)
                Text(date)
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