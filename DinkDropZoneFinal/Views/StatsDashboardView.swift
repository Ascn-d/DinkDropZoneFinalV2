import SwiftUI
import Charts

// MARK: - Tournament v2 Statistics Dashboard

struct StatsDashboardView: View {
    @StateObject private var analyticsService = AnalyticsService()
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMetric: MetricType = .tournaments
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground).opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Header with time range selector
                        dashboardHeader
                        
                        // Key metrics overview
                        keyMetricsGrid
                        
                        // Main chart section
                        mainChartSection
                        
                        // Tournament format distribution
                        formatDistributionChart
                        
                        // Performance metrics
                        performanceMetricsSection
                        
                        // User engagement insights
                        userEngagementSection
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Analytics Dashboard")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            analyticsService.trackScreenView("StatsDashboard")
        }
    }
    
    // MARK: - Dashboard Header
    
    private var dashboardHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tournament Analytics")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Real-time insights and performance metrics")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Refresh indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Time range selector
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Key Metrics Grid
    
    private var keyMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Total Tournaments",
                value: "\(analyticsService.tournamentStats.totalTournamentsCreated)",
                change: "+12%",
                changeType: .positive,
                icon: "trophy.fill",
                color: .brown
            )
            
            MetricCard(
                title: "Completion Rate",
                value: "\(Int(analyticsService.tournamentStats.completionRate * 100))%",
                change: "+5%",
                changeType: .positive,
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            MetricCard(
                title: "Avg Match Time",
                value: "\(Int(analyticsService.tournamentStats.avgMatchDuration / 60))m",
                change: "-2m",
                changeType: .positive,
                icon: "clock.fill",
                color: .blue
            )
            
            MetricCard(
                title: "Upset Rate",
                value: "\(Int(analyticsService.tournamentStats.upsetRate * 100))%",
                change: "+3%",
                changeType: .neutral,
                icon: "bolt.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - Main Chart Section
    
    private var mainChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Trends")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(MetricType.allCases, id: \.self) { metric in
                        Text(metric.rawValue).tag(metric)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Placeholder for chart
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.brown.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.brown.opacity(0.5))
                        Text("Chart Data")
                            .font(.headline)
                            .foregroundColor(.brown.opacity(0.7))
                    }
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Format Distribution Chart
    
    private var formatDistributionChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournament Format Distribution")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Placeholder for pie chart
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "chart.pie.fill")
                            .font(.largeTitle)
                            .foregroundColor(.green.opacity(0.5))
                        Text("Format Distribution")
                            .font(.headline)
                            .foregroundColor(.green.opacity(0.7))
                    }
                )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Performance Metrics Section
    
    private var performanceMetricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Insights")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                PerformanceCard(
                    title: "Total Matches",
                    value: "\(analyticsService.performanceMetrics.totalMatches)",
                    icon: "gamecontroller.fill",
                    color: .blue
                )
                
                PerformanceCard(
                    title: "Upsets",
                    value: "\(analyticsService.performanceMetrics.upsetCount)",
                    icon: "bolt.fill",
                    color: .orange
                )
                
                PerformanceCard(
                    title: "Errors",
                    value: "\(analyticsService.performanceMetrics.errorCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - User Engagement Section
    
    private var userEngagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("User Engagement")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                EngagementRow(
                    title: "Screen Views",
                    value: analyticsService.userEngagement.totalScreenViews,
                    icon: "eye.fill",
                    color: .blue
                )
                
                EngagementRow(
                    title: "User Actions",
                    value: analyticsService.userEngagement.totalActions,
                    icon: "hand.tap.fill",
                    color: .green
                )
                
                EngagementRow(
                    title: "Session Duration",
                    value: Int(analyticsService.userEngagement.sessionDuration / 60),
                    unit: "min",
                    icon: "clock.fill",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    let title: String
    let value: String
    let change: String
    let changeType: ChangeType
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
                
                Text(change)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(changeType.backgroundColor)
                    )
                    .foregroundColor(changeType.textColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

struct PerformanceCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct EngagementRow: View {
    let title: String
    let value: Int
    var unit: String = ""
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(value)\(unit.isEmpty ? "" : " \(unit)")")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Supporting Types

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case quarter = "Quarter"
    case year = "Year"
}

enum MetricType: String, CaseIterable {
    case tournaments = "Tournaments"
    case matches = "Matches"
    case users = "Users"
    case engagement = "Engagement"
}

enum ChangeType {
    case positive
    case negative
    case neutral
    
    var backgroundColor: Color {
        switch self {
        case .positive: return .green.opacity(0.2)
        case .negative: return .red.opacity(0.2)
        case .neutral: return .gray.opacity(0.2)
        }
    }
    
    var textColor: Color {
        switch self {
        case .positive: return .green
        case .negative: return .red
        case .neutral: return .gray
        }
    }
}

#Preview {
    StatsDashboardView()
}
