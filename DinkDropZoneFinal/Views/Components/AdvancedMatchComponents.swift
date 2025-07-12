import SwiftUI

// MARK: - Advanced Match Components

struct SpectatorMatchView: View {
    let match: TournamentMatch
    let tournament: Tournament
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var isFollowingMatch = false
    @State private var spectatorReactions: [SpectatorReaction] = []
    @State private var showReactionPicker = false
    @State private var selectedReaction = ""
    @State private var showShareSheet = false
    @State private var notifications: [SpectatorNotification] = []
    @State private var reactionListener: FirebaseService.ListenerHandle?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Match header
                spectatorMatchHeader
                
                // Live match view
                spectatorMatchContent
                
                // Spectator actions
                spectatorActionsBar
            }
            .navigationTitle("Spectator Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .onAppear {
                setupSpectatorMode()
            }
            .onDisappear {
                cleanupListeners()
            }
        }
        .sheet(isPresented: $showShareSheet) {
            SpectatorShareSheet(match: match, tournament: tournament)
        }
        .overlay(
            SpectatorNotificationOverlay(notifications: notifications)
        )
    }
    
    private func cleanupListeners() {
        reactionListener?.remove()
    }
    
    private var spectatorMatchHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.name)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Match \(match.matchNumber) - Round \(match.round)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Follow button
                Button(action: { isFollowingMatch.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: isFollowingMatch ? "bell.fill" : "bell")
                            .font(.caption)
                        
                        Text(isFollowingMatch ? "Following" : "Follow")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(isFollowingMatch ? .white : .blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(isFollowingMatch ? .blue : .blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            // Live indicator
            if match.status == "In Progress" {
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.2)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: true)
                        
                        Text("LIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Text("\(spectatorReactions.count) reactions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.quaternary.opacity(0.3))
    }
    
    private var spectatorMatchContent: some View {
        VStack(spacing: 16) {
            // Players display
            HStack(spacing: 20) {
                spectatorPlayerCard(
                    name: match.player1Name,
                    isWinner: match.winnerID == match.player1ID,
                    score: getPlayerScore(match.player1ID)
                )
                
                Text("VS")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                spectatorPlayerCard(
                    name: match.player2Name,
                    isWinner: match.winnerID == match.player2ID,
                    score: getPlayerScore(match.player2ID)
                )
            }
            
            // Live score
            if match.status == "In Progress" {
                spectatorScoreDisplay
            }
            
            // Recent reactions
            if !spectatorReactions.isEmpty {
                spectatorReactionsView
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func spectatorPlayerCard(name: String, isWinner: Bool, score: String) -> some View {
        VStack(spacing: 8) {
            Text(name.isEmpty ? "TBD" : name)
                .font(.headline)
                .fontWeight(isWinner ? .bold : .medium)
                .foregroundColor(isWinner ? .green : .primary)
            
            if isWinner {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    
                    Text("Winner")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            
            Text(score)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isWinner ? .green.opacity(0.1) : .gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var spectatorScoreDisplay: some View {
        VStack(spacing: 8) {
            Text("Current Score")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(match.finalScore.isEmpty ? "0-0" : match.finalScore)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding()
                .background(.blue.opacity(0.1))
                .cornerRadius(12)
        }
    }
    
    private var spectatorReactionsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Reactions")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(spectatorReactions.prefix(10)) { reaction in
                        SpectatorReactionBubble(reaction: reaction)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var spectatorActionsBar: some View {
        HStack(spacing: 20) {
            // Reaction buttons
            ForEach(["👏", "🔥", "⚡", "💪", "🎯"], id: \.self) { emoji in
                Button(action: { sendReaction(emoji) }) {
                    Text(emoji)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(.gray.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Spacer()
            
            // More reactions
            Button(action: { showReactionPicker = true }) {
                Image(systemName: "face.smiling")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 44, height: 44)
                    .background(.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(.white)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
    }
    
    private func setupSpectatorMode() {
        // Load existing reactions
        loadSpectatorReactions()
        
        // Setup real-time updates
        setupReactionUpdates()
    }
    
    private func loadSpectatorReactions() {
        // Load reactions from Firebase
        Task {
            do {
                spectatorReactions = try await appState.firebaseService.getSpectatorReactions(matchId: match.id.uuidString)
            } catch {
                print("Failed to load spectator reactions: \(error)")
            }
        }
    }
    
    private func setupReactionUpdates() {
        // Listen for new reactions
        reactionListener = appState.firebaseService.observeSpectatorReactions(matchId: match.id.uuidString) { reactions in
            spectatorReactions = reactions
        }
    }
    
    private func sendReaction(_ emoji: String) {
        guard let currentUser = appState.currentUser else { return }
        
        let reaction = SpectatorReaction(
            id: UUID().uuidString,
            userId: currentUser.id.uuidString,
            matchId: match.id.uuidString,
            reaction: emoji,
            timestamp: Date(),
            position: nil
        )
        
        // Add to local state immediately
        spectatorReactions.append(reaction)
        
        // Send to Firebase
        Task {
            try await appState.firebaseService.sendSpectatorReaction(
                matchId: match.id.uuidString,
                userId: currentUser.id.uuidString,
                reaction: emoji
            )
        }
        
        // Reaction sent successfully - no notification needed since this is a spectator action
    }
    
    private func getPlayerScore(_ playerId: String) -> String {
        let scores = match.finalScore.components(separatedBy: "-")
        if match.player1ID == playerId {
            return scores.first?.trimmingCharacters(in: .whitespaces) ?? "0"
        } else {
            return scores.last?.trimmingCharacters(in: .whitespaces) ?? "0"
        }
    }

    private func sendNotification(type: SpectatorNotification.NotificationType, matchId: String, message: String) {
        let notification = SpectatorNotification(
            type: type,
            title: "Match Update",
            message: message,
            timestamp: Date(),
            matchId: matchId,
            tournamentId: nil, // TournamentMatch doesn't have tournamentId property
            userId: "",
            isRead: false
        )
        notifications.append(notification)
    }
}

struct SpectatorReactionBubble: View {
    let reaction: SpectatorReaction
    
    var body: some View {
        VStack(spacing: 4) {
            Text(reaction.reaction)
                .font(.title2)
            
            Text(formatTime(reaction.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct SpectatorNotificationOverlay: View {
    let notifications: [SpectatorNotification]
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 8) {
                ForEach(notifications) { notification in
                    HStack {
                        Text(notification.message)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(colorForType(notification.type))
                            .cornerRadius(12)
                        
                        Spacer()
                    }
                }
            }
            .padding()
        }
        .allowsHitTesting(false)
    }
    
    private func colorForType(_ type: SpectatorNotification.NotificationType) -> Color {
        switch type {
        case .reaction: return .blue
        case .matchStart, .tournamentUpdate: return .green
        case .highlight: return .yellow
        case .matchEnd: return .red
        case .scoreUpdate: return .orange
        case .comment: return .purple
        }
    }
}

// MARK: - Advanced Match Statistics View

struct AdvancedMatchStatsView: View {
    let match: TournamentMatch
    let performanceMetrics: PerformanceMetrics
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab = 0
    @State private var showRealTimeStats = false
    @State private var animateCharts = false
    
    private let tabs = ["Overview", "Performance", "Rally Analysis", "Heat Map"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Stats View", selection: $selectedTab) {
                    ForEach(tabs.indices, id: \.self) { index in
                        Text(tabs[index]).tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // Content
                TabView(selection: $selectedTab) {
                    // Overview
                    matchOverviewStats
                        .tag(0)
                    
                    // Performance
                    performanceStatsView
                        .tag(1)
                    
                    // Rally Analysis
                    rallyAnalysisView
                        .tag(2)
                    
                    // Heat Map
                    courtHeatMapView
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Match Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showRealTimeStats.toggle() }) {
                        Image(systemName: showRealTimeStats ? "pause.circle" : "play.circle")
                    }
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animateCharts = true
                }
            }
        }
    }
    
    private var matchOverviewStats: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Match summary
                matchSummaryCard
                
                // Key stats
                keyStatsGrid
                
                // Performance comparison placeholder
                Text("Performance comparison coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding()
        }
    }
    
    private var matchSummaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Match Summary")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if match.status == "In Progress" {
                    Text("LIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatMatchDuration())
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Final Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(match.finalScore.isEmpty ? "In Progress" : match.finalScore)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var keyStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            StatCard(title: "Total Points", value: "\(performanceMetrics.totalPoints)", color: .blue)
            StatCard(title: "Winning Shots", value: "\(performanceMetrics.winningShots)", color: .green)
            StatCard(title: "Errors", value: "\(performanceMetrics.errors)", color: .red)
            StatCard(title: "Aces", value: "\(performanceMetrics.aces)", color: .orange)
            StatCard(title: "Win %", value: String(format: "%.1f%%", performanceMetrics.winPercentage), color: .purple)
            StatCard(title: "Error Rate", value: String(format: "%.1f%%", performanceMetrics.errorRate), color: .pink)
        }
    }
    
    private var performanceStatsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Performance metrics
                performanceMetricsView
                
                // Efficiency analysis placeholder
                Text("Efficiency analysis coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.gray.opacity(0.1))
                    .cornerRadius(12)
                
                // Shot distribution placeholder
                Text("Shot distribution coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding()
        }
    }
    
    private var performanceMetricsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                PerformanceBar(
                    title: "Court Coverage",
                    value: performanceMetrics.courtCoverage,
                    color: .blue,
                    animate: animateCharts
                )
                
                PerformanceBar(
                    title: "Efficiency",
                    value: performanceMetrics.efficiency,
                    color: .green,
                    animate: animateCharts
                )
                
                PerformanceBar(
                    title: "Time at Net",
                    value: performanceMetrics.timeAtNet / 100.0, // Normalize for display
                    color: .orange,
                    animate: animateCharts
                )
            }
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var rallyAnalysisView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Rally statistics
                rallyStatsCard
                
                // Rally length distribution placeholder
                Text("Rally distribution chart coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.gray.opacity(0.1))
                    .cornerRadius(12)
                
                // Average rally trends placeholder
                Text("Rally trends chart coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding()
        }
    }
    
    private var rallyStatsCard: some View {
        VStack(spacing: 12) {
            Text("Rally Analysis")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(Int(performanceMetrics.averageRallyLength))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Avg Rally")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(performanceMetrics.longestRally)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Longest")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(performanceMetrics.totalPoints)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                    
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var courtHeatMapView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Court Heat Map")
                    .font(.headline)
                    .fontWeight(.bold)
                
                // Heat map placeholder
                CourtHeatMapView(performanceMetrics: performanceMetrics)
                
                // Position analysis
                positionAnalysisView
            }
            .padding()
        }
    }
    
    private var positionAnalysisView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Position Analysis")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(performanceMetrics.netPoints)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Net Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(performanceMetrics.baselinePoints)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Baseline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // Helper methods
    private func formatMatchDuration() -> String {
        // Calculate duration based on match start time
        let duration = Date().timeIntervalSince(match.scheduledTime ?? Date())
        let hours = Int(duration) / 3600
        let minutes = Int(duration.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // Additional view components would go here...
}

// MARK: - Supporting Components

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PerformanceBar: View {
    let title: String
    let value: Double
    let color: Color
    let animate: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(value, specifier: "%.1f")%")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(color.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: animate ? geometry.size.width * (value / 100.0) : 0, height: 6)
                        .cornerRadius(3)
                        .animation(.easeInOut(duration: 1.0), value: animate)
                }
            }
            .frame(height: 6)
        }
    }
}

struct CourtHeatMapView: View {
    let performanceMetrics: PerformanceMetrics
    
    var body: some View {
        // Placeholder for court heat map
        Rectangle()
            .fill(.gray.opacity(0.1))
            .frame(height: 200)
            .cornerRadius(12)
            .overlay(
                VStack {
                    Image(systemName: "figure.tennis")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("Court Heat Map")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text("Coming Soon")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            )
    }
}

// MARK: - Social Sharing Components

struct SocialSharingView: View {
    let match: TournamentMatch
    let tournament: Tournament
    let highlights: [MatchHighlight]
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var shareText = ""
    @State private var selectedPlatforms: Set<String> = []
    @State private var includeScore = true
    @State private var includeHighlights = true
    @State private var customMessage = ""
    
    private let socialPlatforms = ["Twitter", "Instagram", "Facebook", "TikTok", "Snapchat"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Share preview
                sharePreviewCard
                
                // Platform selection
                platformSelectionView
                
                // Share options
                shareOptionsView
                
                // Custom message
                customMessageView
                
                Spacer()
                
                // Share button
                shareButton
            }
            .padding()
            .navigationTitle("Share Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var sharePreviewCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Share Preview")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                Text(generateShareText())
                    .font(.subheadline)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .background(.gray.opacity(0.1))
                    .cornerRadius(8)
                
                if includeHighlights && !highlights.isEmpty {
                    Text("+ \(highlights.count) highlights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var platformSelectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share To")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(socialPlatforms, id: \.self) { platform in
                    PlatformButton(
                        platform: platform,
                        isSelected: selectedPlatforms.contains(platform),
                        action: { togglePlatform(platform) }
                    )
                }
            }
        }
    }
    
    private var shareOptionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Include")
                .font(.subheadline)
                .fontWeight(.medium)
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Match Score", isOn: $includeScore)
                Toggle("Highlights", isOn: $includeHighlights)
            }
        }
    }
    
    private var customMessageView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Custom Message")
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField("Add your message...", text: $customMessage, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    private var shareButton: some View {
        Button(action: shareContent) {
            Text("Share")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedPlatforms.isEmpty ? .gray : .blue)
                .cornerRadius(12)
        }
        .disabled(selectedPlatforms.isEmpty)
    }
    
    private func generateShareText() -> String {
        var text = ""
        
        if !customMessage.isEmpty {
            text += customMessage + "\n\n"
        }
        
        text += "🏓 \(tournament.name)\n"
        text += "Match \(match.matchNumber): \(match.player1Name) vs \(match.player2Name)\n"
        
        if includeScore && !match.finalScore.isEmpty {
            text += "Score: \(match.finalScore)\n"
        }
        
        if match.status == "Completed" && match.winnerID != nil {
            let winner = match.winnerID == match.player1ID ? match.player1Name : match.player2Name
            text += "Winner: \(winner) 🏆\n"
        }
        
        text += "\n#DinkDrop #PickleballTournament #Pickleball"
        
        return text
    }
    
    private func togglePlatform(_ platform: String) {
        if selectedPlatforms.contains(platform) {
            selectedPlatforms.remove(platform)
        } else {
            selectedPlatforms.insert(platform)
        }
    }
    
    private func shareContent() {
        let shareContent = SocialShareContent(
            matchId: match.id.uuidString,
            tournamentId: tournament.id.uuidString,
            shareType: .score,
            content: generateShareText(),
            mediaUrl: nil,
            hashtags: ["DinkDrop", "PickleballTournament", "Pickleball"],
            mentions: [],
            timestamp: Date()
        )
        
        Task {
            do {
                try await appState.shareContent(shareContent, platforms: Array(selectedPlatforms))
                dismiss()
            } catch {
                print("Failed to share content: \(error)")
            }
        }
    }
}

struct PlatformButton: View {
    let platform: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: platformIcon(platform))
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : platformColor(platform))
                
                Text(platform)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? platformColor(platform) : .gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private func platformIcon(_ platform: String) -> String {
        switch platform {
        case "Twitter": return "link"
        case "Instagram": return "camera"
        case "Facebook": return "link.circle"
        case "TikTok": return "video"
        case "Snapchat": return "camera.circle"
        default: return "square.and.arrow.up"
        }
    }
    
    private func platformColor(_ platform: String) -> Color {
        switch platform {
        case "Twitter": return .blue
        case "Instagram": return .pink
        case "Facebook": return .blue
        case "TikTok": return .black
        case "Snapchat": return .yellow
        default: return .gray
        }
    }
}

struct SpectatorShareSheet: View {
    let match: TournamentMatch
    let tournament: Tournament
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Share this live match with friends!")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                // Quick share buttons
                VStack(spacing: 12) {
                    ShareableMatchCard(match: match, tournament: tournament)
                    
                    HStack(spacing: 12) {
                        Button("Copy Link") {
                            copyMatchLink()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Share") {
                            shareMatch()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Share Live Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func copyMatchLink() {
        let matchLink = "https://dinkdrop.app/match/\(match.id.uuidString)"
        UIPasteboard.general.string = matchLink
        dismiss()
    }
    
    private func shareMatch() {
        let shareText = "🏓 Watch this live match: \(match.player1Name) vs \(match.player2Name)\n\nhttps://dinkdrop.app/match/\(match.id.uuidString)"
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
}

struct ShareableMatchCard: View {
    let match: TournamentMatch
    let tournament: Tournament
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(tournament.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if match.status == "In Progress" {
                    Text("LIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            HStack(spacing: 20) {
                Text(match.player1Name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("VS")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(match.player2Name)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            if !match.finalScore.isEmpty {
                Text(match.finalScore)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CommentaryEventView: View {
    let event: CommentaryEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time indicator
            Text(formatTime(event.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
            
            // Event icon
            Image(systemName: eventIcon(event.type))
                .font(.caption)
                .foregroundColor(eventColor(event.type))
                .frame(width: 16)
            
            // Event content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.message)
                    .font(.caption)
                    .foregroundColor(.primary)
                
                if !event.isSystemGenerated {
                    Text("User comment")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(event.isSystemGenerated ? .clear : .blue.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func eventIcon(_ type: CommentaryEvent.CommentaryType) -> String {
        switch type {
        case .matchStart: return "play.fill"
        case .scoreUpdate: return "plus.circle"
        case .statusChange: return "info.circle"
        case .userComment: return "bubble.left"
        case .highlight: return "star.fill"
        case .matchEnd: return "checkmark.circle"
        }
    }
    
    private func eventColor(_ type: CommentaryEvent.CommentaryType) -> Color {
        switch type {
        case .matchStart: return .green
        case .scoreUpdate: return .blue
        case .statusChange: return .orange
        case .userComment: return .purple
        case .highlight: return .yellow
        case .matchEnd: return .red
        }
    }
} 