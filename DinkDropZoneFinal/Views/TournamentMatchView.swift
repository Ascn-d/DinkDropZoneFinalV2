import SwiftUI
import SwiftData
import Combine

struct TournamentMatchView: View {
    let match: TournamentMatch
    let tournament: Tournament
    let tournamentService: TournamentService?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var showScoreEntry = false
    @State private var player1Score = ""
    @State private var player2Score = ""
    @State private var selectedWinner: String? = nil
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showMatchTimer = false
    @State private var matchStartTime: Date?
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var showMatchHistory = false
    @State private var matchNotes = ""
    @State private var gameScores: [(String, String)] = []
    @State private var showGameScoreEntry = false
    
    // Enhanced features
    @State private var isSpectatorMode = false
    @State private var showSpectatorView = false
    @State private var spectatorCount = 0
    @State private var showLiveStream = false
    @State private var isStreamingEnabled = false
    @State private var showMatchStats = false
    @State private var showSocialSharing = false
    @State private var liveCommentary: [CommentaryEvent] = []
    @State private var showCommentaryPanel = false
    @State private var matchHighlights: [MatchHighlight] = []
    @State private var showInstantReplay = false
    @State private var replayEvent: ReplayEvent?
    
    // Real-time updates
    @State private var matchUpdateListener: FirebaseService.ListenerHandle?
    @State private var spectatorListener: FirebaseService.ListenerHandle?
    @State private var lastUpdateTime = Date()
    
    // Professional features
    @State private var enableProfessionalOverlay = false
    @State private var showAdvancedStats = false
    @State private var performanceMetrics = PerformanceMetrics()
    @State private var rallyTracking = RallyTracking()
    @State private var showCourtMapping = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Main match content
                mainMatchContent
                
                // Professional overlay
                if enableProfessionalOverlay {
                    professionalOverlay
                }
                
                // Spectator overlay
                if isSpectatorMode {
                    spectatorOverlay
                }
                
                // Live streaming overlay
                if showLiveStream {
                    liveStreamOverlay
                }
                
                // Commentary panel
                if showCommentaryPanel {
                    commentaryPanel
                }
                
                // Instant replay
                if showInstantReplay, let replay = replayEvent {
                    instantReplayView(replay)
                }
            }
            .navigationTitle("Tournament Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showSpectatorView.toggle() }) {
                            Label("Spectator Mode", systemImage: "eye")
                        }
                        
                        Button(action: { showLiveStream.toggle() }) {
                            Label("Live Stream", systemImage: "video")
                        }
                        
                        Button(action: { showMatchStats.toggle() }) {
                            Label("Match Stats", systemImage: "chart.bar")
                        }
                        
                        Button(action: { showSocialSharing.toggle() }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { showCommentaryPanel.toggle() }) {
                            Label("Commentary", systemImage: "text.bubble")
                        }
                        
                        if isUserInMatch {
                            Button(action: { enableProfessionalOverlay.toggle() }) {
                                Label("Pro Mode", systemImage: "star.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                    }
                }
            }
            .onAppear {
                setupRealTimeUpdates()
                checkSpectatorMode()
            }
            .onDisappear {
                cleanupRealTimeUpdates()
            }
        }
        .sheet(isPresented: $showSpectatorView) {
            SpectatorMatchView(match: match, tournament: tournament)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showMatchStats) {
            AdvancedMatchStatsView(match: match, performanceMetrics: performanceMetrics)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showSocialSharing) {
            SocialSharingView(match: match, tournament: tournament, highlights: matchHighlights)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showScoreEntry) {
            ScoreEntryView(match: match, tournament: tournament)
                .environmentObject(appState)
        }
    }
    
    // MARK: - Main Match Content
    
    private var mainMatchContent: some View {
        VStack(spacing: 24) {
            // Enhanced Match Header
            enhancedMatchHeader
            
            // Match Timer (if in progress)
            if showMatchTimer {
                matchTimerView
            }
            
            // Real-time spectator count
            if spectatorCount > 0 {
                spectatorCountView
            }
            
            // Players Section
            enhancedPlayersSection
            
            // Live Score Tracking
            if match.status == "In Progress" && !match.hasResult {
                liveScoreSection
            }
            
            // Match Status
            enhancedMatchStatus
            
            // Action Buttons
            enhancedActionButtons
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Enhanced Match Header
    
    private var enhancedMatchHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(tournament.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Match \(match.matchNumber) - Round \(match.round)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Live indicator
                if match.status == "In Progress" {
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.red.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            // Match importance indicator
            if match.bracket == "Finals" || match.round >= tournament.matches.map(\.round).max() ?? 0 {
                HStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                    
                    Text(match.bracket == "Finals" ? "Championship Match" : "Final Round")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.yellow.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .cornerRadius(16)
    }
    
    // MARK: - Enhanced Players Section
    
    private var enhancedPlayersSection: some View {
        VStack(spacing: 16) {
            // Player cards with enhanced information
            HStack(spacing: 16) {
                enhancedPlayerCard(
                    name: match.player1Name,
                    id: match.player1ID,
                    isWinner: match.winnerID == match.player1ID,
                    position: .leading
                )
                
                Text("VS")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                enhancedPlayerCard(
                    name: match.player2Name,
                    id: match.player2ID,
                    isWinner: match.winnerID == match.player2ID,
                    position: .trailing
                )
            }
            
            // Live score display
            if match.status == "In Progress" && !match.finalScore.isEmpty {
                liveScoreDisplay
            }
        }
    }
    
    private func enhancedPlayerCard(name: String, id: String, isWinner: Bool, position: HorizontalAlignment) -> some View {
        VStack(alignment: position, spacing: 8) {
            HStack {
                if isWinner {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                }
                
                Text(name.isEmpty ? "TBD" : name)
                    .font(.headline)
                    .fontWeight(isWinner ? .bold : .medium)
                    .foregroundColor(isWinner ? .green : .primary)
            }
            
            // Player stats if available
            if let playerStats = getPlayerStats(id: id) {
                VStack(alignment: position, spacing: 4) {
                    HStack {
                        Text("Rating:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(playerStats.rating, specifier: "%.0f")")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("W/L:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(playerStats.wins)-\(playerStats.losses)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isWinner ? .green.opacity(0.1) : .gray.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isWinner ? .green : .gray.opacity(0.3), lineWidth: isWinner ? 2 : 1)
        )
    }
    
    // MARK: - Live Score Display
    
    private var liveScoreDisplay: some View {
        VStack(spacing: 8) {
            Text("Current Score")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Text(getPlayerScore(match.player1ID))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("-")
                    .font(.title)
                    .foregroundColor(.secondary)
                
                Text(getPlayerScore(match.player2ID))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Professional Overlay
    
    private var professionalOverlay: some View {
        VStack {
            HStack {
                // Score overlay
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIVE")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(match.finalScore.isEmpty ? "0-0" : match.finalScore)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.7))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                // Match time
                if showMatchTimer {
                    Text(formatElapsedTime(elapsedTime))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.7))
                        .cornerRadius(6)
                }
            }
            
            Spacer()
            
            // Performance metrics overlay
            if showAdvancedStats {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rally Count: \(rallyTracking.totalRallies)")
                            .font(.caption2)
                            .foregroundColor(.white)
                        
                        Text("Avg Rally: \(rallyTracking.averageRallyLength, specifier: "%.1f")s")
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    .padding(8)
                    .background(.black.opacity(0.7))
                    .cornerRadius(6)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .allowsHitTesting(false)
    }
    
    // MARK: - Spectator Overlay
    
    private var spectatorOverlay: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Spectator actions
                    Button(action: { sendSpectatorReaction("👏") }) {
                        Image(systemName: "hands.clap")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.blue)
                            .clipShape(Circle())
                    }
                    
                    Button(action: { sendSpectatorReaction("🔥") }) {
                        Image(systemName: "flame")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.orange)
                            .clipShape(Circle())
                    }
                    
                    Button(action: { sendSpectatorReaction("⚡") }) {
                        Image(systemName: "bolt")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.yellow)
                            .clipShape(Circle())
                    }
                }
                .padding(.trailing, 20)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Supporting Views and Methods
    
    private var spectatorCountView: some View {
        HStack(spacing: 8) {
            Image(systemName: "eye")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("\(spectatorCount) watching")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var liveStreamOverlay: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                        
                        Text("STREAMING")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    Text("Live on DinkDrop")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showLiveStream = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(.black.opacity(0.8))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
    
    private var commentaryPanel: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 0) {
                // Commentary header
                HStack {
                    Text("Live Commentary")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { showCommentaryPanel = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(.white)
                
                // Commentary content
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(liveCommentary) { commentary in
                            CommentaryEventView(event: commentary)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 300)
                .background(.white)
            }
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
        }
    }
    
    private func instantReplayView(_ replay: ReplayEvent) -> some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                HStack {
                    Text("Instant Replay")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: { showInstantReplay = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(replay.description)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                
                // Replay content would go here
                Rectangle()
                    .fill(.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay(
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("Replay: \(replay.title)")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    )
            }
            .padding()
            .background(.white)
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
            
            Spacer()
        }
        .background(.black.opacity(0.5))
        .onTapGesture {
            showInstantReplay = false
        }
    }
    
    // MARK: - Real-time Updates
    
    private func setupRealTimeUpdates() {
        // Listen for match updates
        matchUpdateListener = appState.firebaseService.observeMatch(id: match.id.uuidString) { result in
            switch result {
            case .success(let updatedMatch):
                // Update match state
                handleMatchUpdate(updatedMatch)
            case .failure(let error):
                print("❌ Match update error: \(error)")
            }
        }
        
        // Listen for spectator updates
        spectatorListener = appState.firebaseService.observeSpectators(matchId: match.id.uuidString) { spectators in
            spectatorCount = spectators.count
        }
        
        // Setup commentary updates
        setupCommentaryUpdates()
    }
    
    private func cleanupRealTimeUpdates() {
        matchUpdateListener?.remove()
        spectatorListener?.remove()
        timer?.invalidate()
    }
    
    private func checkSpectatorMode() {
        guard let currentUser = appState.currentUser else { return }
        isSpectatorMode = match.player1ID != currentUser.id.uuidString && 
                          match.player2ID != currentUser.id.uuidString
    }
    
    private func handleMatchUpdate(_ updatedMatch: TournamentMatch) {
        // Update UI with new match data
        // This would typically update the match object
        lastUpdateTime = Date()
        
        // Add to commentary
        if updatedMatch.status != match.status {
            let commentary = CommentaryEvent(
                id: UUID().uuidString,
                timestamp: Date(),
                type: .statusChange,
                message: "Match status changed to \(updatedMatch.status)",
                isSystemGenerated: true,
                userId: nil
            )
            liveCommentary.append(commentary)
        }
        
        // Generate highlights for significant events
        if updatedMatch.finalScore != match.finalScore {
            generateHighlight(for: updatedMatch)
        }
    }
    
    private func setupCommentaryUpdates() {
        // Auto-generate commentary based on match events
        if match.status == "In Progress" {
            generateAutomaticCommentary()
        }
    }
    
    private func generateAutomaticCommentary() {
        let commentary = CommentaryEvent(
            id: UUID().uuidString,
            timestamp: Date(),
            type: .matchStart,
            message: "Match is underway! \(match.player1Name) vs \(match.player2Name)",
            isSystemGenerated: true,
            userId: nil
        )
        liveCommentary.append(commentary)
    }
    
    private func generateHighlight(for match: TournamentMatch) {
        let highlight = MatchHighlight(
            id: UUID().uuidString,
            timestamp: Date(),
            type: .scoreUpdate,
            title: "Score Update",
            description: "New score: \(match.finalScore)",
            matchId: match.id.uuidString,
            playerId: match.winnerID
        )
        matchHighlights.append(highlight)
    }
    
    private func sendSpectatorReaction(_ emoji: String) {
        // Send reaction to Firebase
        Task {
            try await appState.firebaseService.sendSpectatorReaction(
                matchId: match.id.uuidString,
                userId: appState.currentUser?.id.uuidString ?? "",
                reaction: emoji
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func getPlayerStats(id: String) -> PlayerStats? {
        // Get player statistics from AppState or Firebase
        return appState.getPlayerStats(id: id)
    }
    
    private func getPlayerScore(_ playerId: String) -> String {
        // Extract individual player score from final score
        let scores = match.finalScore.components(separatedBy: "-")
        if match.player1ID == playerId {
            return scores.first?.trimmingCharacters(in: .whitespaces) ?? "0"
        } else {
            return scores.last?.trimmingCharacters(in: .whitespaces) ?? "0"
        }
    }
    
    // MARK: - Match Status
    
    private var matchStatus: some View {
        VStack(spacing: 16) {
            if match.hasResult {
                // Show Result
                VStack(spacing: 8) {
                    Text("Final Score")
                        .font(.headline)
                    
                    Text(match.finalScore)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.opacity(0.1))
                )
            } else {
                // Show Match Instructions
                VStack(spacing: 12) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Ready to Play!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Play your match and enter the final score when complete.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue.opacity(0.1))
                )
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if match.hasResult {
                Text("Match Complete")
                    .font(.headline)
                    .foregroundColor(.green)
            } else if canEnterScore {
                Button("Enter Score") {
                    showScoreEntry = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSubmitting)
            } else {
                Text("Waiting for match to be played...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var canEnterScore: Bool {
        guard let user = appState.currentUser else { return false }
        let userID = user.id.uuidString
        return (match.player1ID == userID || match.player2ID == userID) && 
               (match.status == "Ready" || match.status == "In Progress")
    }
    
    private var canStartMatch: Bool {
        guard let user = appState.currentUser else { return false }
        let userID = user.id.uuidString
        return (match.player1ID == userID || match.player2ID == userID) && match.status == "Ready"
    }
    
    private var isUserInMatch: Bool {
        guard let user = appState.currentUser else { return false }
        let userID = user.id.uuidString
        return match.player1ID == userID || match.player2ID == userID
    }
    
    // MARK: - Score Entry View
    
    private var scoreEntryView: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Enter Match Result")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    // Player 1 Score
                    VStack(spacing: 8) {
                        Text(match.player1Name)
                            .font(.headline)
                        
                        TextField("Score", text: $player1Score)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                        
                        Button(selectedWinner == match.player1ID ? "✓ Winner" : "Select Winner") {
                            selectedWinner = match.player1ID
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(selectedWinner == match.player1ID ? .green : .primary)
                    }
                    
                    Text("VS")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    // Player 2 Score
                    VStack(spacing: 8) {
                        Text(match.player2Name)
                            .font(.headline)
                        
                        TextField("Score", text: $player2Score)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                        
                        Button(selectedWinner == match.player2ID ? "✓ Winner" : "Select Winner") {
                            selectedWinner = match.player2ID
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(selectedWinner == match.player2ID ? .green : .primary)
                    }
                }
                .padding()
                
                Button("Submit Result") {
                    submitScore()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedWinner == nil || player1Score.isEmpty || player2Score.isEmpty || isSubmitting)
                
                if isSubmitting {
                    ProgressView("Submitting...")
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Score Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showScoreEntry = false
                        resetScoreEntry()
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func submitScore() {
        guard let winnerID = selectedWinner,
              let service = tournamentService else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        let loserID = winnerID == match.player1ID ? match.player2ID : match.player1ID
        let finalScore = "\(player1Score) - \(player2Score)"
        
        Task {
            do {
                // Use AppState's centralized match result submission
                try await appState.submitMatchResult(
                    match: match,
                    winnerID: winnerID,
                    loserID: loserID,
                    score: finalScore,
                    tournament: tournament
                )
                
                await MainActor.run {
                    isSubmitting = false
                    showScoreEntry = false
                    resetScoreEntry()
                    
                    // Dismiss the match view after successful submission
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
    
    private func resetScoreEntry() {
        player1Score = ""
        player2Score = ""
        selectedWinner = nil
        errorMessage = nil
    }
    
    // MARK: - Enhanced Match Status
    
    private var enhancedMatchStatus: some View {
        VStack(spacing: 16) {
            if match.hasResult {
                // Show Result
                VStack(spacing: 8) {
                    Text("Final Score")
                        .font(.headline)
                    
                    Text(match.finalScore)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.opacity(0.1))
                )
            } else {
                // Show Match Instructions
                VStack(spacing: 12) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Ready to Play!")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Play your match and enter the final score when complete.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue.opacity(0.1))
                )
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Enhanced Action Buttons
    
    private var enhancedActionButtons: some View {
        VStack(spacing: 12) {
            if match.hasResult {
                Text("Match Complete")
                    .font(.headline)
                    .foregroundColor(.green)
            } else if canEnterScore {
                Button("Enter Score") {
                    showScoreEntry = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isSubmitting)
            } else {
                Text("Waiting for match to be played...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
         // MARK: - Match Timer
     
     private var matchTimerView: some View {
         VStack(spacing: 12) {
             HStack {
                 Image(systemName: "timer")
                     .foregroundColor(.orange)
                 
                 Text("Match Duration")
                     .font(.subheadline)
                     .fontWeight(.medium)
                 
                 Spacer()
                 
                 Text(formatElapsedTime(elapsedTime))
                     .font(.title2)
                     .fontWeight(.bold)
                     .foregroundColor(.orange)
             }
             
             // Timer controls
             HStack(spacing: 16) {
                 Button(timer == nil ? "Resume" : "Pause") {
                     if timer == nil {
                         timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                             elapsedTime += 1
                         }
                     } else {
                         timer?.invalidate()
                         timer = nil
                     }
                 }
                 .buttonStyle(.bordered)
                 .controlSize(.small)
                 
                 Button("Reset") {
                     timer?.invalidate()
                     timer = nil
                     elapsedTime = 0
                     matchStartTime = Date()
                 }
                 .buttonStyle(.bordered)
                 .controlSize(.small)
                 .foregroundColor(.red)
             }
         }
         .padding()
         .background(
             RoundedRectangle(cornerRadius: 12)
                 .fill(.orange.opacity(0.1))
                 .overlay(
                     RoundedRectangle(cornerRadius: 12)
                         .stroke(.orange.opacity(0.3), lineWidth: 1)
                 )
         )
         .transition(.move(edge: .top).combined(with: .opacity))
     }
     
     // MARK: - Live Score Tracking
     
     private var liveScoreSection: some View {
         VStack(spacing: 16) {
             HStack {
                 Text("Live Score")
                     .font(.headline)
                 
                 Spacer()
                 
                 Button("Add Game") {
                     showGameScoreEntry = true
                 }
                 .buttonStyle(.bordered)
                 .controlSize(.small)
             }
             
             if gameScores.isEmpty {
                 VStack(spacing: 8) {
                     Image(systemName: "plus.circle.dashed")
                         .font(.title2)
                         .foregroundColor(.secondary)
                     
                     Text("No games recorded yet")
                         .font(.subheadline)
                         .foregroundColor(.secondary)
                     
                     Text("Tap 'Add Game' to start tracking individual game scores")
                         .font(.caption)
                         .foregroundColor(.secondary)
                         .multilineTextAlignment(.center)
                 }
                 .padding()
             } else {
                 // Display game scores
                 VStack(spacing: 8) {
                     ForEach(Array(gameScores.enumerated()), id: \.offset) { index, score in
                         HStack {
                             Text("Game \(index + 1)")
                                 .font(.subheadline)
                                 .fontWeight(.medium)
                             
                             Spacer()
                             
                             Text("\(score.0) - \(score.1)")
                                 .font(.subheadline)
                                 .fontWeight(.bold)
                         }
                         .padding(.horizontal)
                         .padding(.vertical, 8)
                         .background(
                             RoundedRectangle(cornerRadius: 8)
                                 .fill(.ultraThinMaterial)
                         )
                     }
                 }
             }
         }
         .padding()
         .background(
             RoundedRectangle(cornerRadius: 12)
                 .fill(.blue.opacity(0.1))
                 .overlay(
                     RoundedRectangle(cornerRadius: 12)
                         .stroke(.blue.opacity(0.3), lineWidth: 1)
                 )
         )
     }
    
    // MARK: - Enhanced Score Entry View
    
    private var enhancedScoreEntryView: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Enter Match Result")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    // Player 1 Score
                    VStack(spacing: 8) {
                        Text(match.player1Name)
                            .font(.headline)
                        
                        TextField("Score", text: $player1Score)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                        
                        Button(selectedWinner == match.player1ID ? "✓ Winner" : "Select Winner") {
                            selectedWinner = match.player1ID
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(selectedWinner == match.player1ID ? .green : .primary)
                    }
                    
                    Text("VS")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    // Player 2 Score
                    VStack(spacing: 8) {
                        Text(match.player2Name)
                            .font(.headline)
                        
                        TextField("Score", text: $player2Score)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                        
                        Button(selectedWinner == match.player2ID ? "✓ Winner" : "Select Winner") {
                            selectedWinner = match.player2ID
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(selectedWinner == match.player2ID ? .green : .primary)
                    }
                }
                .padding()
                
                Button("Submit Result") {
                    submitScore()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectedWinner == nil || player1Score.isEmpty || player2Score.isEmpty || isSubmitting)
                
                if isSubmitting {
                    ProgressView("Submitting...")
                        .padding()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Score Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showScoreEntry = false
                        resetScoreEntry()
                    }
                }
            }
        }
    }
    
         // MARK: - Game Score Entry
     
     private var gameScoreEntryView: some View {
         NavigationView {
             VStack(spacing: 24) {
                 Text("Add Game Score")
                     .font(.title2)
                     .fontWeight(.bold)
                 
                 VStack(spacing: 16) {
                     Text("Game \(gameScores.count + 1)")
                         .font(.headline)
                         .foregroundColor(.secondary)
                     
                     HStack(spacing: 40) {
                         VStack(spacing: 12) {
                             Text(match.player1Name)
                                 .font(.subheadline)
                                 .fontWeight(.medium)
                             
                             TextField("Score", text: $player1Score)
                                 .textFieldStyle(.roundedBorder)
                                 .keyboardType(.numberPad)
                                 .multilineTextAlignment(.center)
                                 .frame(width: 80)
                         }
                         
                         Text(":")
                             .font(.title)
                             .fontWeight(.bold)
                         
                         VStack(spacing: 12) {
                             Text(match.player2Name)
                                 .font(.subheadline)
                                 .fontWeight(.medium)
                             
                             TextField("Score", text: $player2Score)
                                 .textFieldStyle(.roundedBorder)
                                 .keyboardType(.numberPad)
                                 .multilineTextAlignment(.center)
                                 .frame(width: 80)
                         }
                     }
                 }
                 .padding()
                 
                 HStack(spacing: 16) {
                     Button("Cancel") {
                         showGameScoreEntry = false
                         resetScoreEntry()
                     }
                     .buttonStyle(.bordered)
                     
                     Button("Add Game") {
                         addGameScore()
                     }
                     .buttonStyle(.borderedProminent)
                     .disabled(player1Score.isEmpty || player2Score.isEmpty)
                 }
                 
                 // Current games list
                 if !gameScores.isEmpty {
                     VStack(alignment: .leading, spacing: 12) {
                         Text("Games Recorded")
                             .font(.headline)
                         
                         ForEach(Array(gameScores.enumerated()), id: \.offset) { index, score in
                             HStack {
                                 Text("Game \(index + 1):")
                                     .font(.subheadline)
                                 
                                 Spacer()
                                 
                                 Text("\(score.0) - \(score.1)")
                                     .font(.subheadline)
                                     .fontWeight(.bold)
                                 
                                 Button {
                                     gameScores.remove(at: index)
                                 } label: {
                                     Image(systemName: "trash")
                                         .foregroundColor(.red)
                                 }
                                 .buttonStyle(.plain)
                             }
                             .padding(.horizontal)
                         }
                     }
                     .padding()
                     .background(
                         RoundedRectangle(cornerRadius: 12)
                             .fill(.gray.opacity(0.1))
                     )
                 }
                 
                 Spacer()
             }
             .padding()
             .navigationTitle("Game Score")
             .navigationBarTitleDisplayMode(.inline)
         }
     }
    
    // MARK: - Match History
    
    private var matchHistoryView: some View {
        // Implementation of matchHistoryView
        Text("Match History View")
    }
    
    // MARK: - Match Timer
    
    private func startMatch() {
        // Implementation of startMatch
        showMatchTimer = true
        matchStartTime = Date()
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
         private func stopTimer() {
         timer?.invalidate()
         timer = nil
         showMatchTimer = false
     }
     
     private func formatElapsedTime(_ seconds: TimeInterval) -> String {
         let hours = Int(seconds) / 3600
                 let minutes = Int(seconds.truncatingRemainder(dividingBy: 3600)) / 60
        let secondsOnly = Int(seconds.truncatingRemainder(dividingBy: 60))
         
                 if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secondsOnly)
        } else {
            return String(format: "%02d:%02d", minutes, secondsOnly)
        }
     }
     
     private func addGameScore() {
         guard !player1Score.isEmpty && !player2Score.isEmpty else { return }
         
         gameScores.append((player1Score, player2Score))
         
         // Reset for next game
         player1Score = ""
         player2Score = ""
         
         showGameScoreEntry = false
         
         // Provide haptic feedback
         UIImpactFeedbackGenerator(style: .light).impactOccurred()
     }
     
     private func calculateFinalScore() -> String {
         guard !gameScores.isEmpty else { return "" }
         
         var player1Wins = 0
         var player2Wins = 0
         
         for (p1Score, p2Score) in gameScores {
             if let p1 = Int(p1Score), let p2 = Int(p2Score) {
                 if p1 > p2 {
                     player1Wins += 1
                 } else if p2 > p1 {
                     player2Wins += 1
                 }
             }
         }
         
         return "\(player1Wins) - \(player2Wins)"
     }
}

#Preview {
    let tournament = Tournament(
        name: "Summer Championship",
        description: "Annual summer tournament",
        organizerID: "organizer1",
        organizerName: "Tournament Director"
    )
    
    let match = TournamentMatch(
        round: 1,
        bracket: "Winners",
        matchNumber: 1,
        player1ID: "user1",
        player1Name: "Alice Johnson",
        player2ID: "user2",
        player2Name: "Bob Smith"
    )
    
    let appState = AppState()
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, configurations: config)
    let tournamentService = TournamentService(firebaseService: FirebaseService.shared)
    
    TournamentMatchView(match: match, tournament: tournament, tournamentService: tournamentService)
        .modelContainer(container)
        .environmentObject(appState)
} 