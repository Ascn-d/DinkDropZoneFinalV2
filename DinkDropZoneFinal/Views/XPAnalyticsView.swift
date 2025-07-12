import SwiftUI
import Charts

struct XPAnalyticsView: View {
    @ObservedObject var analyticsService: AnalyticsService
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTimeframe: AnalyticsTimeframe = .month
    @State private var selectedMetric: AnalyticsMetric = .performance
    @State private var showingAIInsights = false
    @State private var showingPredictiveAnalysis = false
    @State private var isGeneratingInsights = false
    @State private var aiInsights: AIAnalyticsInsights?
    @State private var predictiveData: PredictiveAnalysisData?
    @State private var selectedSegment: AnalyticsSegment = .overview
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with timeframe selector
                    headerSection
                    
                    // Segment control
                    segmentedControl
                    
                    // Content based on selected segment
                    switch selectedSegment {
                    case .overview:
                        overviewSection
                    case .performance:
                        performanceSection
                    case .tournaments:
                        tournamentSection
                    case .aiInsights:
                        aiInsightsSection
                    case .predictive:
                        predictiveSection
                    }
                }
                .padding()
            }
            .navigationTitle("Advanced Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            await loadAnalyticsData()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Real-time metrics bar
            realtimeMetricsBar
            
            // Timeframe selector
            timeframeSelector
        }
    }
    
    private var realtimeMetricsBar: some View {
        HStack(spacing: 20) {
            RealtimeMetricCard(
                title: "Active Users",
                value: "\(analyticsService.realtimeMetrics.activeUsers)",
                icon: "person.fill",
                color: .blue
            )
            
            RealtimeMetricCard(
                title: "Live Tournaments",
                value: "\(analyticsService.realtimeMetrics.activeTournaments)",
                icon: "trophy.fill",
                color: .green
            )
            
            RealtimeMetricCard(
                title: "Active Matches",
                value: "\(analyticsService.realtimeMetrics.liveMatches)",
                icon: "gamecontroller.fill",
                color: .orange
            )
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private var timeframeSelector: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(AnalyticsTimeframe.allCases, id: \.self) { timeframe in
                Text(timeframe.displayName).tag(timeframe)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedTimeframe) {
            Task { await loadAnalyticsData() }
        }
    }
    
    // MARK: - Segmented Control
    
    private var segmentedControl: some View {
        Picker("Analytics Segment", selection: $selectedSegment) {
            ForEach(AnalyticsSegment.allCases, id: \.self) { segment in
                Text(segment.displayName).tag(segment)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Overview Section
    
    private var overviewSection: some View {
        VStack(spacing: 20) {
            // Key performance indicators
            kpiGrid
            
            // Activity trends chart
            activityTrendsChart
            
            // Engagement metrics
            engagementMetricsCard
        }
    }
    
    private var kpiGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            KPICard(
                title: "Total Tournaments",
                value: "\(analyticsService.tournamentStats.totalTournamentsCreated)",
                change: calculateChange(current: Double(analyticsService.tournamentStats.totalTournamentsCreated), previous: getPreviousValue(.tournaments)),
                icon: "trophy.fill",
                color: .blue
            )
            
            KPICard(
                title: "Completion Rate",
                value: String(format: "%.1f%%", analyticsService.tournamentStats.completionRate * 100),
                change: calculateChange(current: analyticsService.tournamentStats.completionRate, previous: getPreviousValue(.completionRate)),
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            KPICard(
                title: "Avg Duration",
                value: formatDuration(analyticsService.tournamentStats.avgTournamentDuration),
                change: calculateChange(current: analyticsService.tournamentStats.avgTournamentDuration, previous: getPreviousValue(.duration)),
                icon: "clock.fill",
                color: .orange
            )
            
            KPICard(
                title: "Upset Rate",
                value: String(format: "%.1f%%", analyticsService.tournamentStats.upsetRate * 100),
                change: calculateChange(current: analyticsService.tournamentStats.upsetRate, previous: getPreviousValue(.upsetRate)),
                icon: "bolt.fill",
                color: .red
            )
        }
    }
    
    private var activityTrendsChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Trends")
                .font(.title2)
                .fontWeight(.bold)
            
            Chart {
                ForEach(generateTrendData(), id: \.date) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(.blue)
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Value", dataPoint.value)
                    )
                    .foregroundStyle(.blue.opacity(0.1))
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private var engagementMetricsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("User Engagement")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                EngagementMetric(
                    title: "Screen Views",
                    value: "\(analyticsService.userEngagement.totalScreenViews)",
                    icon: "eye.fill"
                )
                
                EngagementMetric(
                    title: "User Actions",
                    value: "\(analyticsService.userEngagement.totalActions)",
                    icon: "hand.tap.fill"
                )
                
                EngagementMetric(
                    title: "Session Time",
                    value: formatDuration(analyticsService.userEngagement.sessionDuration),
                    icon: "timer.fill"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Performance Section
    
    private var performanceSection: some View {
        VStack(spacing: 20) {
            // Performance overview
            performanceOverviewCard
            
            // Performance charts
            performanceChartsGrid
            
            // Performance insights
            performanceInsightsCard
        }
    }
    
    private var performanceOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Overview")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                PerformanceStatCard(
                    title: "Win Rate",
                    value: String(format: "%.1f%%", analyticsService.performanceMetrics.winPercentage * 100),
                    color: .green
                )
                
                PerformanceStatCard(
                    title: "Error Rate",
                    value: String(format: "%.1f%%", analyticsService.performanceMetrics.errorRate * 100),
                    color: .red
                )
                
                PerformanceStatCard(
                    title: "Efficiency",
                    value: String(format: "%.1f%%", analyticsService.performanceMetrics.efficiency * 100),
                    color: .blue
                )
                
                PerformanceStatCard(
                    title: "Avg Rally",
                    value: String(format: "%.1f", analyticsService.performanceMetrics.averageRallyLength),
                    color: .orange
                )
                
                PerformanceStatCard(
                    title: "Court Coverage",
                    value: String(format: "%.1f%%", analyticsService.performanceMetrics.courtCoverage * 100),
                    color: .purple
                )
                
                PerformanceStatCard(
                    title: "Net Points",
                    value: "\(analyticsService.performanceMetrics.netPoints)",
                    color: .pink
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private var performanceChartsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            // Win/Loss chart
            winLossChart
            
            // Shot distribution chart
            shotDistributionChart
        }
    }
    
    private var winLossChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Win/Loss Distribution")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart {
                SectorMark(
                    angle: .value("Wins", analyticsService.performanceMetrics.winningShots),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(.green)
                .opacity(0.8)
                
                SectorMark(
                    angle: .value("Losses", analyticsService.performanceMetrics.errors),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(.red)
                .opacity(0.8)
            }
            .frame(height: 150)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private var shotDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shot Types")
                .font(.headline)
                .fontWeight(.semibold)
            
            Chart {
                BarMark(
                    x: .value("Type", "Aces"),
                    y: .value("Count", analyticsService.performanceMetrics.aces)
                )
                .foregroundStyle(.blue)
                
                BarMark(
                    x: .value("Type", "Winners"),
                    y: .value("Count", analyticsService.performanceMetrics.winners)
                )
                .foregroundStyle(.green)
                
                BarMark(
                    x: .value("Type", "Errors"),
                    y: .value("Count", analyticsService.performanceMetrics.errors)
                )
                .foregroundStyle(.red)
            }
            .frame(height: 150)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private var performanceInsightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Insights")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                InsightRow(
                    icon: "arrow.up.circle.fill",
                    text: "Your win rate has improved by 12% this month",
                    color: .green
                )
                
                InsightRow(
                    icon: "target",
                    text: "Focus on reducing unforced errors to boost performance",
                    color: .orange
                )
                
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    text: "Your court coverage is above average",
                    color: .blue
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - Tournament Section
    
    private var tournamentSection: some View {
        VStack(spacing: 20) {
            // Tournament overview
            tournamentOverviewCard
            
            // Format distribution
            formatDistributionChart
            
            // Tournament insights
            tournamentInsightsCard
        }
    }
    
    private var tournamentOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournament Analytics")
                .font(.title2)
                .fontWeight(.bold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                TournamentStatCard(
                    title: "Created",
                    value: "\(analyticsService.tournamentStats.totalTournamentsCreated)",
                    subtitle: "Total tournaments",
                    color: .blue
                )
                
                TournamentStatCard(
                    title: "Completed",
                    value: "\(analyticsService.tournamentStats.totalTournamentsCompleted)",
                    subtitle: "Finished events",
                    color: .green
                )
                
                TournamentStatCard(
                    title: "Participants",
                    value: "\(calculateTotalParticipants())",
                    subtitle: "Total players",
                    color: .orange
                )
                
                TournamentStatCard(
                    title: "Avg Size",
                    value: "\(calculateAverageSize())",
                    subtitle: "Players per event",
                    color: .purple
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private var formatDistributionChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Format Distribution")
                .font(.title2)
                .fontWeight(.bold)
            
            Chart {
                ForEach(Array(analyticsService.tournamentStats.formatDistribution.keys.sorted()), id: \.self) { format in
                    let count = analyticsService.tournamentStats.formatDistribution[format] ?? 0
                    BarMark(
                        x: .value("Format", format),
                        y: .value("Count", count)
                    )
                    .foregroundStyle(.blue.gradient)
                }
            }
            .frame(height: 200)
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(date, format: .dateTime.weekday(.abbreviated))
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private var tournamentInsightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tournament Insights")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                InsightRow(
                    icon: "trophy.fill",
                    text: "Double Elimination is your most popular format",
                    color: .gold
                )
                
                InsightRow(
                    icon: "calendar",
                    text: "Weekend tournaments have 40% higher participation",
                    color: .blue
                )
                
                InsightRow(
                    icon: "person.3.fill",
                    text: "Optimal tournament size is 16-32 participants",
                    color: .green
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    // MARK: - AI Insights Section
    
    private var aiInsightsSection: some View {
        VStack(spacing: 20) {
            // AI insights header
            aiInsightsHeader
            
            // Generated insights
            if let insights = aiInsights {
                generatedInsightsView(insights)
            } else if isGeneratingInsights {
                aiLoadingView
            } else {
                generateInsightsPrompt
            }
        }
    }
    
    private var aiInsightsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                Text("AI-Powered Insights")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { Task { await generateAIInsights() } }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.caption)
                    .foregroundColor(.purple)
                }
                .disabled(isGeneratingInsights)
            }
            
            Text("Advanced machine learning analysis of your tournament data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private var generateInsightsPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.purple)
            
            Text("Generate AI Insights")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Get personalized recommendations and insights based on your tournament data")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Generate Insights") {
                Task { await generateAIInsights() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    private var aiLoadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .purple))
                .scaleEffect(1.5)
            
            Text("AI is analyzing your data...")
                .font(.headline)
                .foregroundColor(.purple)
            
            Text("This may take a few moments")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    private func generatedInsightsView(_ insights: AIAnalyticsInsights) -> some View {
        VStack(spacing: 16) {
            // Performance insights
            AIInsightCard(
                title: "Performance Analysis",
                insights: insights.performanceInsights,
                icon: "chart.line.uptrend.xyaxis",
                color: .blue
            )
            
            // Strategic recommendations
            AIInsightCard(
                title: "Strategic Recommendations",
                insights: insights.strategicRecommendations,
                icon: "lightbulb.fill",
                color: .yellow
            )
            
            // Tournament optimization
            AIInsightCard(
                title: "Tournament Optimization",
                insights: insights.tournamentOptimization,
                icon: "gear.badge.checkmark",
                color: .green
            )
            
            // Competitive intelligence
            AIInsightCard(
                title: "Competitive Intelligence",
                insights: insights.competitiveIntelligence,
                icon: "eye.fill",
                color: .purple
            )
        }
    }
    
    // MARK: - Predictive Section
    
    private var predictiveSection: some View {
        VStack(spacing: 20) {
            // Predictive header
            predictiveHeader
            
            // Predictions
            if let data = predictiveData {
                predictiveAnalysisView(data)
            } else {
                generatePredictionsPrompt
            }
        }
    }
    
    private var predictiveHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "crystal.ball")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Predictive Analysis")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { Task { await generatePredictiveAnalysis() } }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            Text("Machine learning predictions based on historical data")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private var generatePredictionsPrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Generate Predictions")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Get AI-powered predictions for tournament outcomes, player performance, and optimal strategies")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Generate Predictions") {
                Task { await generatePredictiveAnalysis() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
    
    private func predictiveAnalysisView(_ data: PredictiveAnalysisData) -> some View {
        VStack(spacing: 16) {
            // Performance predictions
            PredictionCard(
                title: "Performance Forecast",
                predictions: data.performancePredictions,
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
            
            // Tournament outcome predictions
            PredictionCard(
                title: "Tournament Outcomes",
                predictions: data.tournamentPredictions,
                icon: "trophy.fill",
                color: .gold
            )
            
            // Strategic recommendations
            PredictionCard(
                title: "Optimal Strategies",
                predictions: data.strategicPredictions,
                icon: "target",
                color: .blue
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadAnalyticsData() async {
        // Simulate loading analytics data
        // In a real implementation, this would fetch from the analytics service
        do {
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        } catch {
            // Handle sleep interruption
        }
    }
    
    private func generateAIInsights() async {
        isGeneratingInsights = true
        defer { isGeneratingInsights = false }
        
        // Simulate AI analysis
        do {
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 second delay
        } catch {
            // Handle sleep interruption
        }
        
        aiInsights = AIAnalyticsInsights(
            performanceInsights: [
                "Your win rate has improved 15% over the last month",
                "Serve accuracy is your strongest skill area",
                "Consider working on return consistency"
            ],
            strategicRecommendations: [
                "Focus on net play in doubles tournaments",
                "Practice serves under pressure",
                "Improve third shot drops for better positioning"
            ],
            tournamentOptimization: [
                "16-player double elimination is your optimal format",
                "Schedule tournaments on weekend mornings",
                "Intermediate skill level has highest engagement"
            ],
            competitiveIntelligence: [
                "Your top opponents struggle with net play",
                "Aggressive early game strategy shows 23% higher win rate",
                "Weather conditions favor your playing style"
            ]
        )
    }
    
    private func generatePredictiveAnalysis() async {
        // Simulate predictive analysis generation
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay
        } catch {
            // Handle sleep interruption
        }
        
        predictiveData = PredictiveAnalysisData(
            performancePredictions: [
                "85% chance of improving win rate next month",
                "Expected ELO increase: +45 points",
                "Optimal practice focus: consistency training"
            ],
            tournamentPredictions: [
                "72% probability of top-3 finish in next tournament",
                "Doubles format shows highest success potential",
                "Avoid tournaments with 32+ participants for better odds"
            ],
            strategicPredictions: [
                "Aggressive net play increases win probability by 28%",
                "Third shot drop strategy optimal against current field",
                "Weather forecast favors your playing style this weekend"
            ]
        )
    }
    
    private func calculateChange(current: Double, previous: Double) -> Double {
        guard previous != 0 else { return 0 }
        return ((current - previous) / previous) * 100
    }
    
    private func calculateChange(current: Int, previous: Int) -> Double {
        guard previous != 0 else { return 0 }
        return Double((current - previous)) / Double(previous) * 100
    }
    
    private func getPreviousValue(_ metric: AnalyticsMetricType) -> Double {
        // Simulate previous period data
        switch metric {
        case .tournaments: return Double(analyticsService.tournamentStats.totalTournamentsCreated) * 0.85
        case .completionRate: return analyticsService.tournamentStats.completionRate * 0.92
        case .duration: return analyticsService.tournamentStats.avgTournamentDuration * 1.08
        case .upsetRate: return analyticsService.tournamentStats.upsetRate * 1.15
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    private func generateTrendData() -> [TrendDataPoint] {
        let calendar = Calendar.current
        let today = Date()
        
        return (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) ?? today
            let value = Double.random(in: 10...50) // Simulate activity data
            return TrendDataPoint(date: date, value: value)
        }.reversed()
    }
    
    private func calculateTotalParticipants() -> Int {
        // Simulate calculation from tournament data
        return analyticsService.tournamentStats.totalTournamentsCreated * 18 // Average participants
    }
    
    private func calculateAverageSize() -> Int {
        guard analyticsService.tournamentStats.totalTournamentsCreated > 0 else { return 0 }
        return calculateTotalParticipants() / analyticsService.tournamentStats.totalTournamentsCreated
    }
}

// MARK: - Supporting Views

struct RealtimeMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct KPICard: View {
    let title: String
    let value: String
    let change: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                    Text(String(format: "%.1f%%", abs(change)))
                        .font(.caption)
                }
                .foregroundColor(change >= 0 ? .green : .red)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct EngagementMetric: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PerformanceStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct TournamentStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct InsightRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

struct AIInsightCard: View {
    let title: String
    let insights: [String]
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(insights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(color)
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        Text(insight)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct PredictionCard: View {
    let title: String
    let predictions: [String]
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("AI")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(predictions, id: \.self) { prediction in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(color)
                            .font(.caption)
                            .padding(.top, 2)
                        
                        Text(prediction)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Data Models

enum AnalyticsSegment: String, CaseIterable {
    case overview = "overview"
    case performance = "performance"
    case tournaments = "tournaments"
    case aiInsights = "ai_insights"
    case predictive = "predictive"
    
    var displayName: String {
        switch self {
        case .overview: return "Overview"
        case .performance: return "Performance"
        case .tournaments: return "Tournaments"
        case .aiInsights: return "AI Insights"
        case .predictive: return "Predictive"
        }
    }
}

enum AnalyticsMetric: String, CaseIterable {
    case performance = "performance"
    case engagement = "engagement"
    case tournaments = "tournaments"
    case predictions = "predictions"
    
    var displayName: String {
        switch self {
        case .performance: return "Performance"
        case .engagement: return "Engagement"
        case .tournaments: return "Tournaments"
        case .predictions: return "Predictions"
        }
    }
}

enum AnalyticsMetricType {
    case tournaments
    case completionRate
    case duration
    case upsetRate
}

struct TrendDataPoint {
    let date: Date
    let value: Double
}

struct AIAnalyticsInsights {
    let performanceInsights: [String]
    let strategicRecommendations: [String]
    let tournamentOptimization: [String]
    let competitiveIntelligence: [String]
}

struct PredictiveAnalysisData {
    let performancePredictions: [String]
    let tournamentPredictions: [String]
    let strategicPredictions: [String]
}