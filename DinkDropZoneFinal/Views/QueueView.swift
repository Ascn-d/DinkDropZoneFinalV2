import SwiftUI
import SwiftData
import CoreLocation

struct QueueView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Environment(NearbyPlayersService.self) private var nearbyService
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var users: [User]
    @State private var isInQueue = false
    @State private var queuePosition = 0
    @State private var estimatedWaitTime = 0
    @State private var selectedMatchType: MatchType = .singles
    @State private var selectedUser: User?
    @State private var showingMatchSetup = false
    @State private var showingTournamentDetails = false
    @State private var showingCourtBooking = false
    @State private var refreshTimer: Timer?
    @Query(sort: \LiveMatch.startTime, order: .reverse) private var liveMatches: [LiveMatch]
    @State private var showingNearbySheet = false
    @State private var animateContent = false
    @State private var showMatchProposal = false
    @State private var pendingMatch: LocalMatchmakingService.LocalMatch?
    
    // Enhanced state management
    @State private var playerPreferences = PlayerPreferences()
    @State private var queueStatistics = QueueStatistics()
    @State private var skillAnalysis = SkillAnalysis()
    @State private var matchHistory = MatchHistoryAnalyzer()
    @State private var queueOptimizer = QueueOptimizer()
    @State private var courtRecommendations: [CourtRecommendation] = []
    @State private var weatherAnalysis = WeatherAnalysis()
    @State private var showingPreferences = false
    @State private var showingSkillAnalysis = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    // Enhanced header with dynamic content
                    enhancedHeaderSection
                        .padding(.top, 20)
                    
                    // Smart recommendations section
                    if !isInQueue {
                        smartRecommendationsSection
                            .padding(.horizontal)
                    }
                    
                    // Main content based on queue state
                    if isInQueue {
                        // Enhanced queue status with real-time updates
                        enhancedQueueStatusCard
                            .padding(.horizontal)
                        
                        // Secondary content while in queue
                        enhancedSecondaryQueueContent
                            .padding(.horizontal)
                    } else {
                        // Enhanced match finding interface
                        enhancedMatchFindingContent
                            .padding(.horizontal)
                    }
                    
                    // Always visible sections
                    enhancedNearbyPlayersSection
                        .padding(.horizontal)
                    
                    // Court recommendations and conditions
                    courtRecommendationsSection
                        .padding(.horizontal)
                    
                    // Live activity and statistics
                    liveActivityAndStatsSection
                        .padding(.horizontal)
                    
                    // Spacer for bottom safe area
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 100)
                }
            }
            .refreshable {
                await refreshAllData()
            }
        }
        .background(DS.Color.backgroundGradient)
        .onAppear {
            setupEnhancedNotificationObservers()
            animateContent = true
            startEnhancedRefreshTimer()
            initializeSmartFeatures()
        }
        .onDisappear {
            removeNotificationObservers()
            animateContent = false
            stopRefreshTimer()
        }
        .alert("Match Proposal", isPresented: $showMatchProposal) {
            if let match = pendingMatch {
                Button("Accept") {
                    acceptMatchProposal(match)
                }
                Button("Decline", role: .cancel) {
                    declineMatchProposal(match)
                }
            }
        } message: {
            if let match = pendingMatch {
                Text("Do you want to play against \(match.player1.displayName)?")
            }
        }
        .sheet(isPresented: $showingMatchSetup) {
            if let user = selectedUser {
                let localMatch = createOptimizedLocalMatch(with: user)
                MatchSetupView(match: localMatch)
            }
        }
        .sheet(isPresented: $showingPreferences) {
            PlayerPreferencesView(preferences: $playerPreferences)
        }
        .sheet(isPresented: $showingSkillAnalysis) {
            SkillAnalysisView(analysis: skillAnalysis)
        }
        .sheet(isPresented: $showingTournamentDetails) {
            TournamentDetailsView()
        }
        .sheet(isPresented: $showingCourtBooking) {
            CourtBookingView()
        }
        .sheet(isPresented: $showingNearbySheet) {
            NearbyMatchSheet()
        }
        .fullScreenCover(item: Binding(
            get: { appState.activeMatchSetup },
            set: { appState.activeMatchSetup = $0 }
        )) { match in
            MatchSetupView(match: match)
        }
    }
    
    // MARK: - Enhanced Header Section
    
    private var enhancedHeaderSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(getContextualGreeting())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(getContextualSubtitle())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Enhanced action buttons
                HStack(spacing: 12) {
                    Button {
                        showingPreferences = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    
                    Button {
                        Task {
                            await refreshAllData()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                    
                    Button {
                        showingSkillAnalysis = true
                    } label: {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.title3)
                            .foregroundColor(.primary)
                    }
                }
            }
            
            // Real-time statistics bar
            HStack(spacing: 24) {
                QueueStatItem(
                    title: "Online", 
                    value: "\(queueStatistics.totalOnlinePlayers)", 
                    icon: "person.2.fill",
                    color: .green
                )
                
                QueueStatItem(
                    title: "Your ELO", 
                    value: "\(appState.currentUser?.elo ?? 1000)", 
                    icon: "star.fill",
                    color: .orange
                )
                
                QueueStatItem(
                    title: "Avg Wait", 
                    value: queueStatistics.averageWaitTimeString, 
                    icon: "clock.fill",
                    color: .blue
                )
                
                QueueStatItem(
                    title: "Success Rate", 
                    value: "\(Int(skillAnalysis.matchSuccessRate * 100))%", 
                    icon: "target",
                    color: .purple
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Smart Recommendations Section
    
    private var smartRecommendationsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🎯 Smart Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Optimal match type recommendation
                    RecommendationCard(
                        title: "Best Match Type",
                        subtitle: queueOptimizer.recommendedMatchType.rawValue,
                        reason: queueOptimizer.recommendationReason,
                        confidence: queueOptimizer.confidence,
                        icon: queueOptimizer.recommendedMatchType.icon,
                        color: queueOptimizer.recommendedMatchType.color
                    ) {
                        selectedMatchType = queueOptimizer.recommendedMatchType
                    }
                    
                    // Optimal time recommendation
                    RecommendationCard(
                        title: "Best Time to Play",
                        subtitle: queueStatistics.optimalPlayTime,
                        reason: "Based on your win rate",
                        confidence: 0.85,
                        icon: "clock.badge.checkmark",
                        color: .blue
                    ) {
                        // Action to schedule for optimal time
                    }
                    
                    // Skill improvement suggestion
                    RecommendationCard(
                        title: "Skill Focus",
                        subtitle: skillAnalysis.improvementArea,
                        reason: "Based on recent matches",
                        confidence: skillAnalysis.improvementConfidence,
                        icon: "target",
                        color: .purple
                    ) {
                        selectedMatchType = .practice
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Enhanced Queue Status Card
    
    private var enhancedQueueStatusCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                // Header with enhanced status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.green)
                                .frame(width: 12, height: 12)
                                .dsPulse(isActive: true, scale: 1.2)
                            
                            Text("In Queue")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            // Queue health indicator
                            Image(systemName: queueStatistics.healthIcon)
                                .foregroundColor(queueStatistics.healthColor)
                                .font(.caption)
                        }
                        
                        Text("Looking for \(selectedMatchType.rawValue.lowercased()) match")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Enhanced queue info
                        Text("Skill range: \(skillAnalysis.currentSkillRange)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Button("Leave") {
                            withAnimation(.spring()) {
                                leaveQueue()
                            }
                        }
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.red)
                        .clipShape(Capsule())
                        
                        // Expand search button
                        if queuePosition > 3 {
                            Button("Expand Search") {
                                expandMatchmakingCriteria()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
                
                // Enhanced queue metrics
                HStack(spacing: 0) {
                    // Position with trend
                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("#\(queuePosition)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            Image(systemName: queueStatistics.positionTrend >= 0 ? "arrow.up" : "arrow.down")
                                .foregroundColor(queueStatistics.positionTrend >= 0 ? .green : .red)
                                .font(.caption)
                        }
                        
                        Text("Position")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 60)
                    
                    // Wait time with accuracy
                    VStack(spacing: 8) {
                        Text(formatWaitTime(estimatedWaitTime))
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        HStack(spacing: 4) {
                            Text("Est. Time")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Circle()
                                .fill(queueStatistics.accuracyColor)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                        .frame(height: 60)
                    
                    // Match probability
                    VStack(spacing: 8) {
                        Text("\(Int(queueOptimizer.matchProbability * 100))%")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("Match Prob")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Enhanced progress section
                VStack(spacing: 12) {
                    HStack {
                        Text(queueOptimizer.currentSearchStatus)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Skill: \(skillAnalysis.displaySkillLevel)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Multi-stage progress bar
                    QueueProgressView(
                        position: queuePosition,
                        totalStages: 5,
                        currentStage: queueOptimizer.currentSearchStage
                    )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
                    .stroke(.separator, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Enhanced Secondary Queue Content
    
    private var enhancedSecondaryQueueContent: some View {
        VStack(spacing: 16) {
            // Dynamic tips while waiting
            VStack(alignment: .leading, spacing: 12) {
                Text("💡 \(queueOptimizer.currentTip.title)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(queueOptimizer.currentTip.suggestions, id: \.self) { suggestion in
                        Label(suggestion, systemImage: "checkmark.circle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.thinMaterial)
            )
            
            // Quick actions while waiting
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "View Stats",
                    icon: "chart.bar",
                    color: .blue
                ) {
                    showingSkillAnalysis = true
                }
                
                QuickActionButton(
                    title: "Find Courts",
                    icon: "mappin.circle",
                    color: .green
                ) {
                    showingCourtBooking = true
                }
                
                QuickActionButton(
                    title: "Adjust Prefs",
                    icon: "slider.horizontal.3",
                    color: .orange
                ) {
                    showingPreferences = true
                }
            }
        }
    }
    
    // MARK: - Enhanced Match Finding Content
    
    private var enhancedMatchFindingContent: some View {
        VStack(spacing: 20) {
            // Smart match type selection with AI insights
            VStack(spacing: 16) {
                HStack {
                    Text("Match Type")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Button("Auto-Select") {
                        selectedMatchType = queueOptimizer.recommendedMatchType
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(MatchType.allCases.prefix(4), id: \.self) { matchType in
                        EnhancedMatchTypeCard(
                            matchType: matchType,
                            isSelected: selectedMatchType == matchType,
                            statistics: queueStatistics.getStatistics(for: matchType),
                            recommendation: queueOptimizer.getRecommendation(for: matchType)
                        ) {
                            withAnimation(.spring()) {
                                selectedMatchType = matchType
                                updateMatchTypeAnalytics(matchType)
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            }
            
            // Enhanced Find Match Button with smart features
            VStack(spacing: 12) {
                Button {
                    joinQueueWithAnalytics()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: queueOptimizer.getOptimalIcon())
                            .font(.title2)
                        
                        VStack(spacing: 2) {
                            Text("Find \(selectedMatchType.rawValue) Match")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("Est. \(queueOptimizer.getEstimatedWaitTime(for: selectedMatchType)) wait")
                                .font(.caption)
                                .opacity(0.8)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [selectedMatchType.color, selectedMatchType.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: selectedMatchType.color.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(appState.currentUser == nil)
                .opacity(appState.currentUser == nil ? 0.6 : 1.0)
                .scaleEffect(appState.currentUser != nil ? 1.0 : 0.95)
                
                // Queue health indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(queueStatistics.getHealthColor(for: selectedMatchType))
                        .frame(width: 8, height: 8)
                    
                    Text(queueStatistics.getHealthDescription(for: selectedMatchType))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Enhanced Nearby Players Section
    
    private var enhancedNearbyPlayersSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Nearby Players")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Text("\(getNearbyPlayersCount()) online")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Circle()
                        .fill(queueStatistics.nearbyPlayersHealthColor)
                        .frame(width: 6, height: 6)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial)
                .clipShape(Capsule())
            }
            
            if let localService = appState.localMatchmakingService,
               !localService.nearbyPlayers.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(localService.nearbyPlayers) { player in
                        EnhancedLocalPlayerCard(
                            player: player,
                            compatibility: skillAnalysis.calculateCompatibility(with: player),
                            matchPrediction: queueOptimizer.predictMatchOutcome(against: player)
                        ) {
                            Task {
                                await proposeOptimizedMatch(to: player)
                            }
                        }
                    }
                }
            } else {
                DSEmptyStateView(
                    icon: "person.2.slash",
                    title: "No players nearby",
                    message: "Try joining the queue or expanding your search radius"
                )
            }
        }
    }
    
    // MARK: - Court Recommendations Section
    
    private var courtRecommendationsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🏟️ Court Recommendations")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("View All") {
                    showingCourtBooking = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(courtRecommendations) { court in
                        CourtRecommendationCard(court: court) {
                            showingCourtBooking = true
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    // MARK: - Live Activity and Statistics Section
    
    private var liveActivityAndStatsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("📊 Live Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Active matches
                QueueStatCard(
                    title: "Live Matches",
                    value: "\(queueStatistics.liveMatches)",
                    subtitle: "In progress",
                    icon: "dot.radiowaves.left.and.right",
                    color: .red
                )
                
                // Queue activity
                QueueStatCard(
                    title: "Queue Activity",
                    value: queueStatistics.queueActivityLevel,
                    subtitle: "Current level",
                    icon: "chart.line.uptrend.xyaxis",
                    color: .blue
                )
                
                // Success rate
                QueueStatCard(
                    title: "Your Win Rate",
                    value: "\(Int(skillAnalysis.recentWinRate * 100))%",
                    subtitle: "Last 10 games",
                    icon: "target",
                    color: .green
                )
            }
        }
    }
    
    // MARK: - Enhanced Helper Functions
    
    private func getContextualGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let userName = appState.currentUser?.displayName ?? "Player"
        
        switch hour {
        case 5..<12: return "Good Morning, \(userName)!"
        case 12..<17: return "Good Afternoon, \(userName)!"
        case 17..<22: return "Good Evening, \(userName)!"
        default: return "Ready for Night Play, \(userName)?"
        }
    }
    
    private func getContextualSubtitle() -> String {
        if isInQueue {
            return "Searching for the perfect match..."
        } else {
            let activity = queueStatistics.queueActivityLevel
            return "Queue activity: \(activity) • \(queueStatistics.totalOnlinePlayers) players online"
        }
    }
    
    private func getShortDescription(for matchType: MatchType) -> String {
        switch matchType {
        case .singles: return "1v1 competitive"
        case .doubles: return "2v2 team play"
        case .practice: return "Casual practice"
        case .tournament: return "Ranked matches"
        case .casual: return "Fun & relaxed"
        case .competitive: return "High stakes"
        case .league: return "League play"
        }
    }
    
    private func getStatusColor(for matchType: MatchType) -> Color {
        let playerCount = getPlayerCountForMatchType(matchType)
        switch playerCount {
        case 0...5: return .red
        case 6...15: return .orange
        case 16...30: return .green
        default: return .blue
        }
    }
    
    private func formatWaitTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
    
    // MARK: - Enhanced Queue Management
    
    private func joinQueueWithAnalytics() {
        // Record analytics
        matchHistory.recordQueueAttempt(matchType: selectedMatchType)
        
        // Update preferences based on selection
        playerPreferences.updatePreferences(
            preferredMatchType: selectedMatchType,
            preferredTime: Date()
        )
        
        // Use enhanced logic
        withAnimation(.spring()) {
            joinQueue(matchType: selectedMatchType)
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func expandMatchmakingCriteria() {
        // Expand ELO range and other criteria
        skillAnalysis.expandMatchmakingRange()
        queueOptimizer.relaxCriteria()
        
        // Provide haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func expandSearchRadius() {
        // Expand geographic search radius
        queueOptimizer.expandSearchRadius()
    }
    
    private func updateMatchTypeAnalytics(_ matchType: MatchType) {
        // Update analytics when user selects match type
        queueStatistics.recordMatchTypeSelection(matchType)
        skillAnalysis.updateMatchTypePreference(matchType)
    }
    
    private func createOptimizedLocalMatch(with user: User) -> LocalMatchmakingService.LocalMatch {
        return LocalMatchmakingService.LocalMatch(
            id: UUID().uuidString,
            player1: LocalMatchmakingService.NearbyPlayer(
                id: appState.currentUser?.id.uuidString ?? "current",
                displayName: appState.currentUser?.displayName ?? "You",
                elo: appState.currentUser?.elo ?? 1000,
                matchType: selectedMatchType.rawValue,
                distance: 0.0,
                peerID: "local"
            ),
            player2: LocalMatchmakingService.NearbyPlayer(
                id: user.id.uuidString,
                displayName: user.displayName,
                elo: user.elo,
                matchType: selectedMatchType.rawValue,
                distance: 0.1,
                peerID: "remote"
            ),
            matchType: selectedMatchType.rawValue,
            createdAt: Date()
        )
    }
    
    private func proposeOptimizedMatch(to player: LocalMatchmakingService.NearbyPlayer) async {
        do {
            // Record match proposal for analytics
            matchHistory.recordMatchProposal(to: player.displayName)
            
            try await appState.proposeLocalMatch(to: player)
            print("✅ Proposed optimized match to \(player.displayName)")
        } catch {
            print("❌ Failed to propose match: \(error)")
        }
    }
    
    // MARK: - Enhanced Data Management
    
    private func initializeSmartFeatures() {
        Task {
            await loadPlayerPreferences()
            await updateQueueStatistics()
            await analyzeSkillLevel()
            await loadCourtRecommendations()
            await updateWeatherAnalysis()
        }
    }
    
    private func loadPlayerPreferences() async {
        // Load saved preferences
        playerPreferences.loadFromUserDefaults()
    }
    
    private func updateQueueStatistics() async {
        // Update real-time queue statistics
        queueStatistics.refresh()
    }
    
    private func analyzeSkillLevel() async {
        // Analyze user's skill level and match history
        if let user = appState.currentUser {
            skillAnalysis.analyzeUser(user)
        }
    }
    
    private func loadCourtRecommendations() async {
        // Load recommended courts based on location and preferences
        courtRecommendations = CourtRecommendationEngine.getRecommendations(
            userLocation: nil as CLLocation?, // Would use actual location
            preferences: playerPreferences
        )
    }
    
    private func updateWeatherAnalysis() async {
        // Update weather conditions for outdoor play
        weatherAnalysis.updateCurrentConditions()
    }
    
    private func refreshAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.updateQueueStatistics() }
            group.addTask { await self.analyzeSkillLevel() }
            group.addTask { await self.loadCourtRecommendations() }
            group.addTask { await self.updateWeatherAnalysis() }
        }
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    // MARK: - Enhanced Notification Management
    
    private func setupEnhancedNotificationObservers() {
        setupNotificationObservers() // Call existing method
        
        // Add new enhanced observers
        NotificationCenter.default.addObserver(
            forName: .queueStatisticsUpdated,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.updateQueueStatistics()
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .skillAnalysisUpdated,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.analyzeSkillLevel()
            }
        }
    }
    
    private func startEnhancedRefreshTimer() {
        startRefreshTimer() // Call existing method
        
        // Add enhanced timer for real-time updates
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            Task {
                await self.updateQueueStatistics()
                await MainActor.run {
                    self.queueOptimizer.updateRecommendations()
                }
            }
        }
    }
    
    private func joinQueue(matchType: MatchType) {
        guard appState.currentUser != nil else {
            // Show error - user not authenticated
            return
        }
        
        Task {
            do {
                // Try local matchmaking first for immediate testing
                try await appState.startLocalMatchmaking(matchType: matchType)
                
                await MainActor.run {
                    withAnimation {
                        isInQueue = true
                        selectedMatchType = matchType
                        // Real values come from the local service
                        queuePosition = appState.queuePosition
                        estimatedWaitTime = Int(appState.estimatedWaitTime / 60) // Convert to minutes
                    }
                }
                
                // Show success message
                print("✅ Successfully joined local matchmaking queue!")
                
            } catch {
                print("❌ Failed to join queue: \(error)")
                
                // Fallback to Firebase if local fails (for production)
                // try await appState.joinRealtimeQueue(matchType: matchType)
            }
        }
    }
    
    private func leaveQueue() {
        appState.stopLocalMatchmaking()
        
        withAnimation {
            isInQueue = false
            selectedMatchType = .singles
            queuePosition = 0
            estimatedWaitTime = 0
        }
        
        print("✅ Successfully left local matchmaking queue!")
    }
    
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            refreshData()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func refreshData() {
        // Simulate data refresh
        if isInQueue && queuePosition > 1 {
            queuePosition = max(1, queuePosition - 1)
            estimatedWaitTime = max(1, estimatedWaitTime - 1)
        }
    }
    
    private func handleMatchResult(_ result: Result<Match, Error>) {
        switch result {
        case .success(_):
            // Handle successful match creation
            leaveQueue()
        case .failure(let error):
            // Handle error
            print("Match creation error: \(error)")
        }
    }
    
    // MARK: - Data Methods
    
    private func getPlayerCountForMatchType(_ matchType: MatchType) -> Int {
        switch matchType {
        case .singles: return Int.random(in: 15...25)
        case .doubles: return Int.random(in: 8...18)
        case .practice: return Int.random(in: 5...12)
        case .tournament: return Int.random(in: 20...35)
        case .casual: return Int.random(in: 10...20)
        case .competitive: return Int.random(in: 12...22)
        case .league: return Int.random(in: 8...16)
        }
    }
    
    private func getAverageWaitTime(_ matchType: MatchType) -> Int {
        switch matchType {
        case .singles: return Int.random(in: 2...5)
        case .doubles: return Int.random(in: 3...7)
        case .practice: return Int.random(in: 1...3)
        case .tournament: return Int.random(in: 5...10)
        case .casual: return Int.random(in: 2...4)
        case .competitive: return Int.random(in: 3...6)
        case .league: return Int.random(in: 4...8)
        }
    }
    
    private func getNearbyPlayersCount() -> Int {
        return nearbyService.nearbyPlayers.count
    }
    
    private func getNearbyPlayers() -> [User] {
        return Array(nearbyService.nearbyPlayers.prefix(4))
    }
    
    private func getNearbyCourts() -> [CourtAvailability] {
        // Get real court data from Firebase/API
        // For now, return empty array - implement real court data loading later
        // TODO: Implement real court availability from Firebase or external API
        return []
    }
    
    private func getActiveTournaments() async -> [Tournament] {
        do {
            // Get real tournaments from Firebase
            let allTournaments = try await FirebaseService.shared.getAllTournaments()
            
            // Filter for active/upcoming tournaments
            let activeTournaments = allTournaments.filter { tournament in
                tournament.status == "Registration Open" || 
                tournament.status == "Registration Closed" ||
                tournament.status == "In Progress"
            }.prefix(5) // Limit to 5 most relevant tournaments
            
            return Array(activeTournaments)
        } catch {
            print("Failed to load active tournaments: \(error)")
            return []
        }
    }
    
    private func getPracticePartners() -> [User] {
        return Array(users.prefix(2))
    }
    
    private func getRecentMatches() -> [QueueRecentMatch] {
        // Get real match history from Firebase
        guard appState.currentUser != nil else { return [] }
        
        // For now, return empty array - implement real match history loading later
        // TODO: Implement real match history from Firebase
        return []
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .localMatchProposalReceived,
            object: nil,
            queue: .main
        ) { notification in
            if let match = notification.object as? LocalMatchmakingService.LocalMatch {
                pendingMatch = match
                showMatchProposal = true
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .localMatchAccepted,
            object: nil,
            queue: .main
        ) { notification in
            if let match = notification.object as? LocalMatchmakingService.LocalMatch {
                print("✅ Match accepted! Starting match setup with \(match.player2.displayName)")
                Task { @MainActor in
                    appState.activeMatchSetup = match
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .localMatchDeclined,
            object: nil,
            queue: .main
        ) { _ in
            print("❌ Match proposal was declined")
        }
    }
    
    private func removeNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: .localMatchProposalReceived, object: nil)
        NotificationCenter.default.removeObserver(self, name: .localMatchAccepted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .localMatchDeclined, object: nil)
    }
    
    private func acceptMatchProposal(_ match: LocalMatchmakingService.LocalMatch) {
        Task {
            do {
                try await appState.respondToLocalProposal(accept: true)
                print("✅ Match proposal accepted!")
            } catch {
                print("❌ Failed to accept match: \(error)")
            }
        }
    }
    
    private func declineMatchProposal(_ match: LocalMatchmakingService.LocalMatch) {
        Task {
            do {
                try await appState.respondToLocalProposal(accept: false)
                print("❌ Match proposal declined")
            } catch {
                print("❌ Failed to decline match: \(error)")
            }
        }
    }
    
    // MARK: - Enhanced Activity Overview Section

    private var enhancedActivityOverviewSection: some View {
        VStack(spacing: 20) {
            // Live Activity
            liveActivityAndStatsSection
            
            // Active Tournaments (Real Data)
            activeTournamentsSection
            
            // Nearby Players
            enhancedNearbyPlayersSection
            
            // Court Recommendations
            courtRecommendationsSection
        }
    }
    
    // MARK: - Active Tournaments Section (Real Data)
    
    private var activeTournamentsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🏆 Active Tournaments")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Button("View All") {
                    // Switch to tournaments tab
                    NotificationCenter.default.post(name: .navigateToTournaments, object: nil)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Load tournaments asynchronously
            AsyncTournamentsView()
        }
    }
}

// MARK: - Supporting Views

struct QuickMatchCard: View {
    let matchType: MatchType
    let playerCount: Int
    let averageWaitTime: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [matchType.color, matchType.color.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: matchType.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text(matchType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(playerCount) players")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("~\(averageWaitTime) min wait")
                        .font(.caption2)
                        .foregroundColor(matchType.color)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? matchType.color.opacity(0.1) : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? matchType.color.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedNearbyPlayerCard: View {
    let player: User
    @Environment(UserLocationService.self) private var locationService
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Player avatar
                Group {
                    if let urlStr = player.profileImageURL, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            placeholderAvatar
                        }
                    } else {
                        placeholderAvatar
                    }
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 18, y: 18)
                )
                
                VStack(spacing: 2) {
                    Text(player.displayName.isEmpty ? 
                         player.email.components(separatedBy: "@").first ?? "Player" : 
                         player.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text("\(player.elo) ELO")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let distanceText = distanceString() {
                        Text(distanceText)
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(width: 80)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func distanceString() -> String? {
        guard let myLoc = locationService.currentLocation,
              let lat = player.lat, let lon = player.lon else { return nil }
        let other = CLLocation(latitude: lat, longitude: lon)
        let meters = myLoc.distance(from: other)
        let miles = meters * 0.000621371
        return String(format: "%.1f mi", miles)
    }

    private var placeholderAvatar: some View {
        Circle()
            .fill(Color.blue.opacity(0.2))
            .overlay(Text(String(player.displayName.isEmpty ? player.email.prefix(1) : player.displayName.prefix(1))).font(.headline).foregroundColor(.blue))
    }
}

// MARK: - Data Models

struct CourtAvailability: Identifiable {
    let id: String
    let name: String
    let distance: String
    let status: Status
    let courts: Int
    
    enum Status {
        case available, busy, full
        
        var color: Color {
            switch self {
            case .available: return .green
            case .busy: return .orange
            case .full: return .red
            }
        }
        
        var text: String {
            switch self {
            case .available: return "Available"
            case .busy: return "Busy"
            case .full: return "Full"
            }
        }
    }
}

struct TournamentCard: View {
    let tournament: Tournament
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(tournament.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("\(tournament.registeredCount)/\(tournament.maxParticipants)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(tournament.startDate.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
            }
            .padding()
            .frame(width: 100, height: 80)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PracticePartnerCard: View {
    let partner: User
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(partner.displayName.isEmpty ? partner.email.prefix(1) : partner.displayName.prefix(1)))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(partner.displayName.isEmpty ? "Practice Partner" : partner.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack {
                        Text("\(partner.elo) ELO")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("Available now")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QueueRecentMatchCard: View {
    let match: QueueRecentMatch
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("vs \(match.opponent)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(match.date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(match.result)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(match.result == "Win" ? .green : .red)
                    
                    Text(match.score)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Placeholder Views

struct TournamentDetailsView: View {
    var body: some View {
        Text("Tournament Details")
    }
}

struct CourtBookingView: View {
    var body: some View {
        CourtView()
    }
}

// MARK: - Original Views (kept for compatibility)
// Note: MatchSetupView is now defined in its own file

#Preview {
    PreviewHelper.queueViewPreview()
}

@MainActor
private struct PreviewHelper {
    static func queueViewPreview() -> some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: User.self, Match.self, configurations: config)
        
        // Create sample users
        let user1 = User(
            email: "player1@example.com",
            password: "password123",
            elo: 1000,
            xp: 0,
            totalMatches: 0,
            wins: 0,
            losses: 0,
            winStreak: 0
        )
        
        let user2 = User(
            email: "player2@example.com",
            password: "password123",
            elo: 1000,
            xp: 0,
            totalMatches: 0,
            wins: 0,
            losses: 0,
            winStreak: 0
        )
        
        container.mainContext.insert(user1)
        container.mainContext.insert(user2)
        
        return QueueView()
            .modelContainer(container)
        .environmentObject(AppState())
    }
}

// MARK: - Enhanced Supporting Views

struct EnhancedQuickMatchCard: View {
    let matchType: MatchType
    let playerCount: Int
    let averageWaitTime: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon and badge
                ZStack {
                    Circle()
                        .fill(matchType.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: matchType.icon)
                        .font(.title2)
                        .foregroundColor(matchType.color)
                    
                    // Player count badge
                    Text("\(playerCount)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: 25, y: -25)
                }
                
                VStack(spacing: 4) {
                    Text(matchType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(matchType.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text("~\(averageWaitTime)m")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isSelected ? 
                matchType.color.opacity(0.1) : 
                Color(.secondarySystemBackground)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? matchType.color : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Local Player Card Component
struct LocalPlayerCard: View {
    let player: LocalMatchmakingService.NearbyPlayer
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Player avatar placeholder
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Text(String(player.displayName.prefix(1)).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 18, y: 18)
                )
                
                VStack(spacing: 2) {
                    Text(player.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.primary)
                    
                    Text(player.eloRange)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        
                        Text("Very close")
                            .font(.caption2)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Data Models

@Observable
class PlayerPreferences {
    var preferredMatchTypes: [MatchType] = [.singles, .doubles]
    var preferredTimeRange: ClosedRange<Int> = 9...21 // 9 AM to 9 PM
    var maxTravelDistance: Double = 10.0 // miles
    var skillLevelPreference: String = "Similar"
    var playStyle: String = "Balanced"
    var availableDays: Set<Int> = [1, 2, 3, 4, 5, 6, 7] // All days
    
    func updatePreferences(preferredMatchType: MatchType, preferredTime: Date) {
        if !preferredMatchTypes.contains(preferredMatchType) {
            preferredMatchTypes.append(preferredMatchType)
        }
        
        let hour = Calendar.current.component(.hour, from: preferredTime)
        if !preferredTimeRange.contains(hour) {
            preferredTimeRange = min(preferredTimeRange.lowerBound, hour)...max(preferredTimeRange.upperBound, hour)
        }
        
        saveToUserDefaults()
    }
    
    func loadFromUserDefaults() {
        // Load saved preferences from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "playerPreferences"),
           let decoded = try? JSONDecoder().decode(PlayerPreferencesData.self, from: data) {
            self.preferredMatchTypes = decoded.preferredMatchTypes
            self.maxTravelDistance = decoded.maxTravelDistance
            self.skillLevelPreference = decoded.skillLevelPreference
            self.playStyle = decoded.playStyle
        }
    }
    
    private func saveToUserDefaults() {
        let data = PlayerPreferencesData(
            preferredMatchTypes: preferredMatchTypes,
            maxTravelDistance: maxTravelDistance,
            skillLevelPreference: skillLevelPreference,
            playStyle: playStyle
        )
        
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: "playerPreferences")
        }
    }
}

struct PlayerPreferencesData: Codable {
    let preferredMatchTypes: [MatchType]
    let maxTravelDistance: Double
    let skillLevelPreference: String
    let playStyle: String
}

@Observable
class QueueStatistics {
    var totalOnlinePlayers: Int = Int.random(in: 15...45)
    var averageWaitTime: TimeInterval = TimeInterval.random(in: 60...300)
    var queueActivityLevel: String = "High"
    var optimalPlayTime: String = "7:00 PM"
    var liveMatches: Int = Int.random(in: 3...12)
    var healthIcon: String = "checkmark.circle.fill"
    var healthColor: Color = .green
    var positionTrend: Int = 0
    var accuracyColor: Color = .green
    var nearbyPlayersHealthColor: Color = .green
    
    var averageWaitTimeString: String {
        let minutes = Int(averageWaitTime / 60)
        return "\(minutes)m"
    }
    
    func refresh() {
        totalOnlinePlayers = Int.random(in: 15...45)
        averageWaitTime = TimeInterval.random(in: 60...300)
        liveMatches = Int.random(in: 3...12)
        
        // Update activity level based on players
        queueActivityLevel = totalOnlinePlayers > 30 ? "High" : totalOnlinePlayers > 20 ? "Medium" : "Low"
        
        // Update health indicators
        healthColor = totalOnlinePlayers > 25 ? .green : totalOnlinePlayers > 15 ? .orange : .red
        healthIcon = totalOnlinePlayers > 25 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }
    
    func getStatistics(for matchType: MatchType) -> MatchTypeStatistics {
        return MatchTypeStatistics(
            playersInQueue: Int.random(in: 5...20),
            averageWaitTime: TimeInterval.random(in: 60...240),
            successRate: Double.random(in: 0.75...0.95)
        )
    }
    
    func getHealthColor(for matchType: MatchType) -> Color {
        let stats = getStatistics(for: matchType)
        return stats.playersInQueue > 10 ? .green : stats.playersInQueue > 5 ? .orange : .red
    }
    
    func getHealthDescription(for matchType: MatchType) -> String {
        let stats = getStatistics(for: matchType)
        if stats.playersInQueue > 10 {
            return "Excellent availability"
        } else if stats.playersInQueue > 5 {
            return "Good availability"
        } else {
            return "Limited availability"
        }
    }
    
    func recordMatchTypeSelection(_ matchType: MatchType) {
        // Record analytics for match type selection
    }
}

struct MatchTypeStatistics {
    let playersInQueue: Int
    let averageWaitTime: TimeInterval
    let successRate: Double
}

@Observable
class SkillAnalysis {
    var matchSuccessRate: Double = 0.78
    var recentWinRate: Double = 0.65
    var improvementArea: String = "Serve Accuracy"
    var improvementConfidence: Double = 0.82
    var currentSkillRange: String = "1200-1400"
    var displaySkillLevel: String = "Intermediate"
    
    func analyzeUser(_ user: User) {
        // Analyze user's performance and calculate metrics
        let elo = user.elo
        
        // Update skill level based on ELO
        if elo < 1000 {
            displaySkillLevel = "Beginner"
            currentSkillRange = "\(elo-100)-\(elo+200)"
        } else if elo < 1300 {
            displaySkillLevel = "Intermediate"
            currentSkillRange = "\(elo-150)-\(elo+150)"
        } else if elo < 1600 {
            displaySkillLevel = "Advanced"
            currentSkillRange = "\(elo-200)-\(elo+100)"
        } else {
            displaySkillLevel = "Expert"
            currentSkillRange = "\(elo-250)-\(elo+50)"
        }
        
        // Calculate success rate based on recent matches
        if user.totalMatches > 0 {
            recentWinRate = Double(user.wins) / Double(user.totalMatches)
            matchSuccessRate = min(0.95, recentWinRate + 0.1)
        }
        
        // Determine improvement area
        improvementArea = getImprovementArea(for: user)
    }
    
    func calculateCompatibility(with player: LocalMatchmakingService.NearbyPlayer) -> Double {
        // Calculate compatibility score (0.0 to 1.0)
        let playerElo = player.elo
        let eloDifference = abs(playerElo - 1200) // Assume current user ELO
        let compatibility = max(0.0, 1.0 - Double(eloDifference) / 500.0)
        return compatibility
    }
    
    func expandMatchmakingRange() {
        // Expand the skill range for wider matchmaking
        currentSkillRange = "1000-1600" // Expanded range
    }
    
    func updateMatchTypePreference(_ matchType: MatchType) {
        // Update preferences based on match type selection
    }
    
    private func getImprovementArea(for user: User) -> String {
        let areas = ["Serve Accuracy", "Return Strategy", "Net Play", "Positioning", "Mental Game"]
        return areas.randomElement() ?? "Overall Game"
    }
}

@Observable
class MatchHistoryAnalyzer {
    var recentMatches: [AnalyzedMatch] = []
    
    func recordQueueAttempt(matchType: MatchType) {
        // Record queue attempt for analytics
    }
    
    func recordMatchProposal(to opponent: String) {
        // Record match proposal for analytics
    }
}

struct AnalyzedMatch {
    let opponent: String
    let result: String
    let skillDifference: Int
    let duration: TimeInterval
}

@Observable
class QueueOptimizer {
    var recommendedMatchType: MatchType = .singles
    var recommendationReason: String = "Best win rate"
    var confidence: Double = 0.87
    var matchProbability: Double = 0.73
    var currentSearchStatus: String = "Analyzing skill compatibility..."
    var currentSearchStage: Int = 2
    var currentTip: QueueTip = QueueTip.defaultTip
    
    func updateRecommendations() {
        // Update recommendations based on current conditions
        currentSearchStage = min(5, currentSearchStage + 1)
        matchProbability = min(1.0, matchProbability + 0.05)
        
        // Update search status
        let statuses = [
            "Searching for players...",
            "Analyzing skill compatibility...",
            "Checking court availability...",
            "Optimizing match quality...",
            "Finalizing match proposal..."
        ]
        
        if currentSearchStage <= statuses.count {
            currentSearchStatus = statuses[currentSearchStage - 1]
        }
    }
    
    func getRecommendation(for matchType: MatchType) -> String {
        switch matchType {
        case .singles: return "Recommended • High success rate"
        case .doubles: return "Good option • Team play"
        case .practice: return "Learning focused"
        default: return "Available"
        }
    }
    
    func getOptimalIcon() -> String {
        return "target"
    }
    
    func getEstimatedWaitTime(for matchType: MatchType) -> String {
        let minutes = Int.random(in: 2...8)
        return "\(minutes)m"
    }
    
    func predictMatchOutcome(against player: LocalMatchmakingService.NearbyPlayer) -> QueueMatchPrediction {
        return QueueMatchPrediction(
            winProbability: Double.random(in: 0.4...0.8),
            confidence: Double.random(in: 0.7...0.9)
        )
    }
    
    func relaxCriteria() {
        // Relax matchmaking criteria for faster matches
    }
    
    func expandSearchRadius() {
        // Expand geographic search radius
    }
}

struct QueueTip {
    let title: String
    let suggestions: [String]
    
    static let defaultTip = QueueTip(
        title: "While You Wait",
        suggestions: [
            "Warm up with practice swings",
            "Check court conditions nearby",
            "Review your recent match stats"
        ]
    )
}

struct QueueMatchPrediction {
    let winProbability: Double
    let confidence: Double
}

@Observable
class WeatherAnalysis {
    var currentConditions: String = "Perfect for outdoor play"
    var temperature: Int = 72
    var windSpeed: Int = 5
    var rainChance: Int = 0
    
    func updateCurrentConditions() {
        // Update weather conditions
        temperature = Int.random(in: 65...85)
        windSpeed = Int.random(in: 0...15)
        rainChance = Int.random(in: 0...30)
        
        if rainChance > 20 {
            currentConditions = "Check indoor courts"
        } else if windSpeed > 10 {
            currentConditions = "Windy conditions"
        } else {
            currentConditions = "Perfect for outdoor play"
        }
    }
}



struct CourtRecommendation: Identifiable {
    let id = UUID()
    let name: String
    let distance: String
    let rating: Double
    let availability: String
    let price: String
    let features: [String]
}

class CourtRecommendationEngine {
    static func getRecommendations(userLocation: CLLocation?, preferences: PlayerPreferences) -> [CourtRecommendation] {
        return [
            CourtRecommendation(
                name: "Golden Gate Courts",
                distance: "0.8 mi",
                rating: 4.8,
                availability: "Available now",
                price: "$15/hour",
                features: ["Outdoor", "4 courts", "Parking"]
            ),
            CourtRecommendation(
                name: "Mission Recreation",
                distance: "1.2 mi",
                rating: 4.5,
                availability: "Available in 30 min",
                price: "$12/hour",
                features: ["Indoor", "2 courts", "Equipment rental"]
            )
        ]
    }
}

// MARK: - Enhanced Supporting View Components

struct QueueStatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecommendationCard: View {
    let title: String
    let subtitle: String
    let reason: String
    let confidence: Double
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
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Text(reason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Circle()
                            .fill(index < Int(confidence * 5) ? color : .secondary.opacity(0.3))
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .padding(12)
            .frame(width: 120, height: 140)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QueueProgressView: View {
    let position: Int
    let totalStages: Int
    let currentStage: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(1...totalStages, id: \.self) { stage in
                    Rectangle()
                        .fill(stage <= currentStage ? .blue : .secondary.opacity(0.3))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                }
            }
            .clipShape(Capsule())
            
            Text("Stage \(currentStage) of \(totalStages)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct EnhancedMatchTypeCard: View {
    let matchType: MatchType
    let isSelected: Bool
    let statistics: MatchTypeStatistics
    let recommendation: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: matchType.icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : matchType.color)
                
                Text(matchType.rawValue)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                VStack(spacing: 4) {
                    Text("\(statistics.playersInQueue) in queue")
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    
                    Text(recommendation)
                        .font(.caption2)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : .secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? 
                          matchType.color.gradient : 
                          Color(.systemGray6).gradient
                    )
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedLocalPlayerCard: View {
    let player: LocalMatchmakingService.NearbyPlayer
    let compatibility: Double
    let matchPrediction: QueueMatchPrediction
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Player avatar with compatibility indicator
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 50, height: 50)
                    
                    Text(String(player.displayName.prefix(1)).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Compatibility ring
                    Circle()
                        .stroke(compatibilityColor, lineWidth: 3)
                        .frame(width: 56, height: 56)
                }
                .overlay(
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .offset(x: 20, y: 20)
                )
                
                VStack(spacing: 4) {
                    Text(player.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(player.eloRange)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    // Match prediction
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.caption2)
                            .foregroundColor(compatibilityColor)
                        
                        Text("\(Int(matchPrediction.winProbability * 100))% win")
                            .font(.caption2)
                            .foregroundColor(compatibilityColor)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(compatibilityColor.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var compatibilityColor: Color {
        if compatibility > 0.8 {
            return .green
        } else if compatibility > 0.6 {
            return .orange
        } else {
            return .red
        }
    }
}

struct QueueEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(actionTitle, action: action)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CourtRecommendationCard: View {
    let court: CourtRecommendation
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(court.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(String(format: "%.1f", court.rating))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(court.distance)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(court.availability)
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                
                HStack {
                    Text(court.price)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(court.features.first ?? "")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(width: 150)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QueueStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Additional View Components

struct PlayerPreferencesView: View {
    @Binding var preferences: PlayerPreferences
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Match Preferences") {
                    // Placeholder for preferences UI
                    Text("Match type preferences")
                    Text("Skill level preferences")
                    Text("Time preferences")
                }
                
                Section("Location") {
                    // Placeholder for location preferences
                    Text("Max travel distance")
                    Text("Preferred courts")
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SkillAnalysisView: View {
    let analysis: SkillAnalysis
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Skill level overview
                    VStack(spacing: 12) {
                        Text("Current Skill Level")
                            .font(.headline)
                        
                        Text(analysis.displaySkillLevel)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        Text("ELO Range: \(analysis.currentSkillRange)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Performance metrics
                    HStack(spacing: 12) {
                        QueueStatCard(
                            title: "Win Rate",
                            value: "\(Int(analysis.recentWinRate * 100))%",
                            subtitle: "Last 10 games",
                            icon: "target",
                            color: .green
                        )
                        
                        QueueStatCard(
                            title: "Success Rate",
                            value: "\(Int(analysis.matchSuccessRate * 100))%",
                            subtitle: "Match completion",
                            icon: "checkmark.circle",
                            color: .blue
                        )
                    }
                    
                    // Improvement areas
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Focus Area")
                            .font(.headline)
                        
                        Text(analysis.improvementArea)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                        
                        Text("Confidence: \(Int(analysis.improvementConfidence * 100))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Skill Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let queueStatisticsUpdated = Notification.Name("queueStatisticsUpdated")
    static let skillAnalysisUpdated = Notification.Name("skillAnalysisUpdated")
}

// Add this async tournaments view
struct AsyncTournamentsView: View {
    @State private var tournaments: [Tournament] = []
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.secondarySystemBackground))
                            .frame(width: 100, height: 80)
                            .redacted(reason: .placeholder)
                    }
                }
            } else if tournaments.isEmpty {
                VStack(spacing: 8) {
                    Text("No active tournaments")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Create Tournament") {
                        NotificationCenter.default.post(name: .navigateToTournaments, object: nil)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(tournaments.prefix(5), id: \.id) { tournament in
                            TournamentCard(tournament: tournament) {
                                // Navigate to tournament details
                                NotificationCenter.default.post(name: .navigateToTournaments, object: nil)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .task {
            await loadTournaments()
        }
    }
    
    private func loadTournaments() async {
        do {
            let allTournaments = try await FirebaseService.shared.getAllTournaments()
            
            let activeTournaments = allTournaments.filter { tournament in
                tournament.status == "Registration Open" || 
                tournament.status == "Registration Closed" ||
                tournament.status == "In Progress"
            }
            
            await MainActor.run {
                self.tournaments = Array(activeTournaments.prefix(5))
                self.isLoading = false
            }
        } catch {
            print("Failed to load tournaments: \(error)")
            await MainActor.run {
                self.tournaments = []
                self.isLoading = false
            }
        }
    }
}

struct QueueRecentMatch: Identifiable {
    let id: String
    let opponent: String
    let result: String
    let score: String
    let date: String
}

