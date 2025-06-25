import SwiftUI
import SwiftData

struct XPAnalyticsView: View {
    @Environment(XPManager.self) private var xpManager
    @State private var selectedTimeframe: AnalyticsTimeframe = .week
    @State private var selectedMetric: AnalyticsMetric = .xp
    
    enum AnalyticsTimeframe: String, CaseIterable {
        case day = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
    }
    
    enum AnalyticsMetric: String, CaseIterable {
        case xp = "XP Earned"
        case missions = "Missions"
        case trophies = "Trophies"
        case level = "Level Progress"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Stats
                    headerStatsSection
                    
                    // Time Selector
                    timeframePicker
                    
                    // Main Chart
                    chartSection
                    
                    // Detailed Breakdown
                    detailedBreakdownSection
                    
                    // Mission Analytics
                    missionAnalyticsSection
                    
                    // Trophy Progress
                    trophyProgressSection
                    
                    // Achievement Timeline
                    achievementTimelineSection
                }
                .padding()
            }
            .navigationTitle("XP Analytics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header Stats
    
    private var headerStatsSection: some View {
        VStack(spacing: 16) {
            Text("Your Progress Overview")
                .font(.headline)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                AnalyticsStatCard(
                    title: "Current Level",
                    value: "\(xpManager.currentLevel)",
                    subtitle: "Level \(xpManager.currentLevel + 1) in \(xpManager.xpToNextLevel) XP",
                    icon: "star.fill",
                    color: .orange,
                    progress: xpManager.getProgressToNextLevel()
                )
                
                AnalyticsStatCard(
                    title: "Total XP",
                    value: "\(xpManager.totalXPEarned)",
                    subtitle: "Lifetime earned",
                    icon: "bolt.fill",
                    color: .blue
                )
                
                AnalyticsStatCard(
                    title: "Active Missions",
                    value: "\(xpManager.getMissionsForDisplay().count)",
                    subtitle: "In progress",
                    icon: "target",
                    color: .purple
                )
                
                AnalyticsStatCard(
                    title: "Trophies",
                    value: "\(xpManager.unlockedTrophies.count)",
                    subtitle: "of \(20) unlocked", // Approximate total achievements
                    icon: "trophy.fill",
                    color: .yellow,
                    progress: Double(xpManager.unlockedTrophies.count) / Double(20)
                )
            }
        }
    }
    
    // MARK: - Timeframe Picker
    
    private var timeframePicker: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Analytics Period")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Chart Section
    
    private var chartSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Performance Chart")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(AnalyticsMetric.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Chart placeholder (would use real Charts framework in production)
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(getChartTitle())
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(getChartSubtitle())
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(getChartValue())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(getChartColor())
                }
                
                // Mock chart visualization
                GeometryReader { geometry in
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(0..<7, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [getChartColor().opacity(0.8), getChartColor()],
                                        startPoint: .bottom,
                                        endPoint: .top
                                    )
                                )
                                .frame(height: CGFloat.random(in: 20...geometry.size.height))
                        }
                    }
                }
                .frame(height: 120)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Detailed Breakdown
    
    private var detailedBreakdownSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Detailed Breakdown")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                BreakdownRow(
                    title: "Daily XP",
                    value: "\(xpManager.dailyStats.xpEarned)",
                    change: "+\(Int.random(in: 10...50))",
                    isPositive: true
                )
                
                BreakdownRow(
                    title: "Weekly XP",
                    value: "\(xpManager.weeklyStats.xpEarned)",
                    change: "+\(Int.random(in: 100...300))",
                    isPositive: true
                )
                
                BreakdownRow(
                    title: "Missions Completed",
                    value: "\(xpManager.completedMissions.count)",
                    change: "+\(Int.random(in: 1...5))",
                    isPositive: true
                )
                
                BreakdownRow(
                    title: "Current Streak",
                    value: "\(xpManager.lifetimeStats.consecutiveDays)",
                    change: "days",
                    isPositive: true
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Mission Analytics
    
    private var missionAnalyticsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Mission Analytics")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MissionTypeCard(
                    title: "Daily",
                    completed: xpManager.completedMissions.filter { $0.type.isDaily }.count,
                    total: MissionType.dailyMissions.count * 7, // Week's worth
                    color: .blue
                )
                
                MissionTypeCard(
                    title: "Weekly",
                    completed: xpManager.completedMissions.filter { $0.type.isWeekly }.count,
                    total: MissionType.weeklyMissions.count * 4, // Month's worth
                    color: .purple
                )
                
                MissionTypeCard(
                    title: "Achievement",
                    completed: xpManager.completedMissions.filter { $0.type.isAchievement }.count,
                    total: MissionType.achievementMissions.count,
                    color: .orange
                )
            }
        }
    }
    
    // MARK: - Trophy Progress
    
    private var trophyProgressSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Trophy Collection")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(xpManager.unlockedTrophies.count)/20") // Approximate total achievements
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 12) {
                ForEach(AchievementTier.allCases, id: \.self) { tier in
                    let trophiesOfTier = xpManager.unlockedTrophies.filter { $0.tier == tier }
                    let totalOfTier = 4 // Approximate count per tier
                    
                    TrophyTierRow(
                        tier: tier,
                        unlocked: trophiesOfTier.count,
                        total: totalOfTier
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Achievement Timeline
    
    private var achievementTimelineSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Achievements")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(xpManager.getRecentTrophies()) { trophy in
                    AchievementTimelineRow(trophy: trophy)
                }
                
                if xpManager.getRecentTrophies().isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("No recent achievements")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Complete missions and play matches to unlock trophies!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func getChartTitle() -> String {
        switch selectedMetric {
        case .xp: return "XP Progress"
        case .missions: return "Mission Completion"
        case .trophies: return "Trophy Unlocks"
        case .level: return "Level Progression"
        }
    }
    
    private func getChartSubtitle() -> String {
        switch selectedTimeframe {
        case .day: return "Last 24 hours"
        case .week: return "Last 7 days"
        case .month: return "Last 30 days"
        case .all: return "All time"
        }
    }
    
    private func getChartValue() -> String {
        switch selectedMetric {
        case .xp: return "\(xpManager.totalXPEarned)"
        case .missions: return "\(xpManager.completedMissions.count)"
        case .trophies: return "\(xpManager.unlockedTrophies.count)"
        case .level: return "\(xpManager.currentLevel)"
        }
    }
    
    private func getChartColor() -> Color {
        switch selectedMetric {
        case .xp: return .blue
        case .missions: return .purple
        case .trophies: return .yellow
        case .level: return .orange
        }
    }
}

// MARK: - Supporting Views

struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    var progress: Double?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let progress = progress {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: color))
                        .scaleEffect(x: 1, y: 0.5)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct BreakdownRow: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(change)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isPositive ? .green : .red)
        }
    }
}

struct MissionTypeCard: View {
    let title: String
    let completed: Int
    let total: Int
    let color: Color
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("\(completed)/\(total)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            CircularProgressView(progress: progress, color: color)
                .frame(width: 40, height: 40)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: 4)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
        }
    }
}

struct TrophyTierRow: View {
    let tier: AchievementTier
    let unlocked: Int
    let total: Int
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(unlocked) / Double(total)
    }
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(tier.color)
                    .frame(width: 12, height: 12)
                
                Text(tier.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("\(unlocked)/\(total)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: tier.color))
                .frame(width: 60)
                .scaleEffect(x: 1, y: 0.5)
        }
    }
}

struct AchievementTimelineRow: View {
    let trophy: Trophy
    
    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: trophy.unlockedAt ?? Date(), relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(trophy.tier.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: trophy.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(trophy.tier.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(trophy.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(trophy.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(timeAgo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(trophy.tier.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(trophy.tier.color)
            }
        }
    }
}

#Preview {
    XPAnalyticsView()
        .environment(XPManager(modelContext: ModelContext(try! ModelContainer(for: User.self))))
}