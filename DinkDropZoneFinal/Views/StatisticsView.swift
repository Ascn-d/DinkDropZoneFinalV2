import SwiftUI
import Charts

struct StatisticsView: View {
    let user: User
    @State private var selectedTimeframe: TimeFrame = .month
    @State private var showingDetailedMonth: String? = nil
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month" 
        case year = "Year"
        case allTime = "All Time"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time frame selector
                timeFramePicker
                
                // Quick stats cards
                quickStatsSection
                
                // Performance chart
                performanceChartSection
                
                // Win rate progression
                winRateProgressionSection
                
                // Monthly breakdown
                monthlyBreakdownSection
                
                // Detailed metrics
                detailedMetricsSection
            }
            .padding()
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var timeFramePicker: some View {
        HStack {
            Text("Time Period")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Picker("Time Frame", selection: $selectedTimeframe) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(.horizontal)
    }
    
    private var quickStatsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
            QuickStatCard(
                title: "Overall Win Rate",
                value: user.formattedWinRate,
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            QuickStatCard(
                title: "Current Streak",
                value: "\(user.winStreak)",
                subtitle: user.winStreak > 0 ? "wins" : "losses",
                icon: "flame.fill",
                color: user.winStreak > 0 ? .orange : .gray
            )
            
            QuickStatCard(
                title: "ELO Rating",
                value: "\(user.elo)",
                icon: "star.fill",
                color: eloColor(for: user.elo)
            )
            
            QuickStatCard(
                title: "Total Matches",
                value: "\(user.totalMatches)",
                icon: "gamecontroller.fill",
                color: .blue
            )
        }
    }
    
    private var performanceChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Overview")
                .font(.headline)
                .padding(.horizontal)
            
            GroupBox {
                Chart(getChartData()) { data in
                    BarMark(
                        x: .value("Month", data.month),
                        y: .value("Matches", data.matches)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var winRateProgressionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Win Rate Progression")
                .font(.headline)
                .padding(.horizontal)
            
            GroupBox {
                Chart(getWinRateData()) { data in
                    LineMark(
                        x: .value("Month", data.month),
                        y: .value("Win Rate", data.winRate)
                    )
                    .foregroundStyle(.green.gradient)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    .symbol(.circle)
                    .symbolSize(50)
                }
                .frame(height: 200)
                .chartYScale(domain: 0...1)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text("\(Int(doubleValue * 100))%")
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var monthlyBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Breakdown")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(getMonthlyBreakdown(), id: \.month) { monthData in
                    MonthlyStatRow(
                        monthData: monthData,
                        isExpanded: showingDetailedMonth == monthData.month
                    ) {
                        withAnimation {
                            showingDetailedMonth = showingDetailedMonth == monthData.month ? nil : monthData.month
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var detailedMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Detailed Metrics")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                DetailedMetricCard(
                    title: "Avg Points/Match",
                    value: String(format: "%.1f", user.averagePointsPerMatch),
                    icon: "target",
                    color: .purple
                )
                
                DetailedMetricCard(
                    title: "Points Differential",
                    value: "\(user.pointsDifferential > 0 ? "+" : "")\(user.pointsDifferential)",
                    icon: "chart.bar.fill",
                    color: user.pointsDifferential > 0 ? .green : .red
                )
                
                DetailedMetricCard(
                    title: "Longest Win Streak",
                    value: "\(user.longestWinStreak)",
                    icon: "bolt.fill",
                    color: .orange
                )
                
                DetailedMetricCard(
                    title: "Total Points Scored",
                    value: "\(user.totalPointsScored)",
                    icon: "plus.circle.fill",
                    color: .blue
                )
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    
    private func eloColor(for elo: Int) -> Color {
        switch elo {
        case 0...1200: return .gray
        case 1201...1600: return .blue
        case 1601...2000: return .purple
        case 2001...2400: return .orange
        default: return .red
        }
    }
    
    private func getChartData() -> [ChartData] {
        return user.monthlyStats.compactMap { (key, stats) in
            ChartData(month: formatMonthKey(key), matches: stats.matches)
        }.sorted { $0.month < $1.month }
    }
    
    private func getWinRateData() -> [WinRateData] {
        return user.monthlyStats.compactMap { (key, stats) in
            WinRateData(month: formatMonthKey(key), winRate: stats.winRate)
        }.sorted { $0.month < $1.month }
    }
    
    private func getMonthlyBreakdown() -> [MonthlyBreakdownData] {
        return user.monthlyStats.compactMap { (key, stats) in
            MonthlyBreakdownData(
                month: key,
                displayMonth: formatMonthKey(key),
                matches: stats.matches,
                wins: stats.wins,
                losses: stats.losses,
                winRate: stats.winRate,
                pointsScored: stats.pointsScored,
                pointsConceded: stats.pointsConceded,
                eloChange: stats.eloChange
            )
        }.sorted { $0.month > $1.month } // Most recent first
    }
    
    private func formatMonthKey(_ key: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        if let date = formatter.date(from: key) {
            formatter.dateFormat = "MMM yy"
            return formatter.string(from: date)
        }
        return key
    }
}

// MARK: - Supporting Views

struct QuickStatCard: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    
    var body: some View {
        GroupBox {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.title2)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .backgroundStyle(color.opacity(0.1))
    }
}

struct DetailedMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        GroupBox {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .backgroundStyle(color.opacity(0.1))
    }
}

struct MonthlyStatRow: View {
    let monthData: MonthlyBreakdownData
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        GroupBox {
            VStack(spacing: 12) {
                Button(action: onTap) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(monthData.displayMonth)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("\(monthData.matches) matches")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(monthData.wins)W - \(monthData.losses)L")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text(String(format: "%.1f%% WR", monthData.winRate * 100))
                                .font(.caption)
                                .foregroundColor(monthData.winRate > 0.5 ? .green : .red)
                        }
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if isExpanded {
                    Divider()
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        StatDetailItem(title: "Points Scored", value: "\(monthData.pointsScored)")
                        StatDetailItem(title: "Points Conceded", value: "\(monthData.pointsConceded)")
                        StatDetailItem(title: "ELO Change", value: "\(monthData.eloChange > 0 ? "+" : "")\(monthData.eloChange)")
                        StatDetailItem(title: "Point Differential", value: "\(monthData.pointsScored - monthData.pointsConceded)")
                    }
                }
            }
        }
    }
}

struct StatDetailItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Data Models

struct ChartData: Identifiable {
    let id = UUID()
    let month: String
    let matches: Int
}

struct WinRateData: Identifiable {
    let id = UUID()
    let month: String
    let winRate: Double
}

struct MonthlyBreakdownData {
    let month: String
    let displayMonth: String
    let matches: Int
    let wins: Int
    let losses: Int
    let winRate: Double
    let pointsScored: Int
    let pointsConceded: Int
    let eloChange: Int
}

// MARK: - Preview

#Preview {
    @MainActor
    struct PreviewHelper {
        static func createSampleUser() -> User {
            let user = User(email: "test@example.com", password: "password", elo: 1650, xp: 1200, totalMatches: 45, wins: 28, losses: 17, winStreak: 3)
            user.displayName = "John Doe"
            user.totalPointsScored = 312
            user.totalPointsConceded = 287
            user.longestWinStreak = 7
            
            // Note: monthlyStats is now a computed property that returns empty data
            // Sample monthly stats functionality removed for SwiftData compatibility
            
            return user
        }
    }
    
    return StatisticsView(user: PreviewHelper.createSampleUser())
} 