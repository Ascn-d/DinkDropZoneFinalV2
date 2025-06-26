import SwiftUI
import MultipeerConnectivity

struct LiveMatchView: View {
    let match: LocalMatchmakingService.LocalMatch
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var player1Score: Int = 0
    @State private var player2Score: Int = 0
    @State private var gameTime: TimeInterval = 0
    @State private var gameTimer: Timer?
    @State private var matchStatus: MatchPhase = .starting
    @State private var showingEndMatch = false
    @State private var showingResults = false
    @State private var countdown: Int = 3
    
    enum MatchPhase {
        case starting
        case active
        case paused
        case completed
    }
    
    private var isPlayer1: Bool {
        guard let currentUser = appState.currentUser else { return true }
        return match.player1.id == currentUser.id.uuidString
    }
    
    private var currentPlayer: LocalMatchmakingService.NearbyPlayer {
        return isPlayer1 ? match.player1 : match.player2
    }
    
    private var opponentPlayer: LocalMatchmakingService.NearbyPlayer {
        return isPlayer1 ? match.player2 : match.player1
    }
    
    private var currentScore: Int {
        return isPlayer1 ? player1Score : player2Score
    }
    
    private var opponentScore: Int {
        return isPlayer1 ? player2Score : player1Score
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [DS.Color.accent.opacity(0.1), DS.Color.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Match Header
                    matchHeader
                    
                    // Main Score Display
                    scoreDisplay
                    
                    // Game Controls
                    if matchStatus == .active {
                        gameControls
                    }
                    
                    // Match Timer
                    timerDisplay
                    
                    Spacer()
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
                
                // Starting Countdown Overlay
                if matchStatus == .starting && countdown > 0 {
                    startingCountdownOverlay
                }
                
                // Match Completion Overlay
                if showingResults {
                    matchResultsOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startMatch()
            setupScoreUpdateListener()
        }
        .onDisappear {
            gameTimer?.invalidate()
            NotificationCenter.default.removeObserver(self, name: .localScoreUpdated, object: nil)
        }
        .alert("End Match?", isPresented: $showingEndMatch) {
            Button("Cancel", role: .cancel) { }
            Button("End Match", role: .destructive) {
                endMatch()
            }
        } message: {
            Text("Are you sure you want to end this match? The current score will be recorded.")
        }
    }
    
    // MARK: - Match Header
    
    private var matchHeader: some View {
        VStack(spacing: 12) {
            HStack {
                Button("Exit") {
                    showingEndMatch = true
                }
                .foregroundColor(.red)
                
                Spacer()
                
                Text(match.matchType.capitalized)
                    .font(DS.Font.headline)
                    .fontWeight(.bold)
                    .foregroundColor(DS.Color.primary)
                
                Spacer()
                
                Circle()
                    .fill(matchStatus == .active ? .green : .orange)
                    .frame(width: 12, height: 12)
            }
            
            // Players Display
            HStack {
                playerCard(currentPlayer, score: currentScore, isCurrentUser: true)
                
                Text("VS")
                    .font(DS.Font.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DS.Color.secondary)
                
                playerCard(opponentPlayer, score: opponentScore, isCurrentUser: false)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
    }
    
    private func playerCard(_ player: LocalMatchmakingService.NearbyPlayer, score: Int, isCurrentUser: Bool) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(LinearGradient(
                    colors: isCurrentUser ? [DS.Color.accent, DS.Color.accent.opacity(0.7)] : [.gray, .gray.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(player.displayName.prefix(1)).uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .stroke(isCurrentUser ? DS.Color.accent : .gray, lineWidth: 3)
                        .frame(width: 66, height: 66)
                )
            
            VStack(spacing: 2) {
                Text(player.displayName)
                    .font(DS.Font.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("\(player.elo) ELO")
                    .font(DS.Font.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Score Display
    
    private var scoreDisplay: some View {
        HStack(spacing: 40) {
            // Current Player Score
            VStack(spacing: 8) {
                Text("\(currentScore)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(DS.Color.accent)
                
                Text("You")
                    .font(DS.Font.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DS.Color.secondary)
            }
            
            Rectangle()
                .fill(DS.Color.secondary.opacity(0.3))
                .frame(width: 2, height: 100)
            
            // Opponent Score
            VStack(spacing: 8) {
                Text("\(opponentScore)")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(.gray)
                
                Text("Opponent")
                    .font(DS.Font.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(DS.Color.secondary)
            }
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - Game Controls
    
    private var gameControls: some View {
        VStack(spacing: 20) {
            Text("Update Your Score")
                .font(DS.Font.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 24) {
                // Subtract Point Button
                Button(action: {
                    if currentScore > 0 {
                        updateScore(currentScore - 1)
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(currentScore > 0 ? .red : .gray.opacity(0.5))
                }
                .disabled(currentScore <= 0)
                
                // Current Score Display
                Text("\(currentScore)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(DS.Color.primary)
                    .frame(minWidth: 80)
                
                // Add Point Button
                Button(action: {
                    updateScore(currentScore + 1)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(DS.Color.accent)
                }
            }
            
            Text("Tap to update your score in real-time")
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        VStack(spacing: 8) {
            Text("Match Time")
                .font(DS.Font.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DS.Color.secondary)
            
            Text(formatTime(gameTime))
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .foregroundColor(DS.Color.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 16) {
            if matchStatus == .active {
                Button("Finish Match") {
                    showingEndMatch = true
                }
                .font(DS.Font.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(DS.Color.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Overlays
    
    private var startingCountdownOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Match Starting In...")
                    .font(DS.Font.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("\(countdown)")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(DS.Color.accent)
                    .scaleEffect(countdown > 0 ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: countdown)
            }
        }
    }
    
    private var matchResultsOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Match Complete!")
                    .font(DS.Font.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    Text("Final Score")
                        .font(DS.Font.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(currentScore)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(currentScore > opponentScore ? .green : .white)
                            Text("You")
                                .font(DS.Font.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Text("-")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        VStack {
                            Text("\(opponentScore)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(opponentScore > currentScore ? .green : .white)
                            Text("Opponent")
                                .font(DS.Font.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    let resultText = currentScore > opponentScore ? "Victory!" : 
                                    currentScore < opponentScore ? "Defeat" : "Draw"
                    Text(resultText)
                        .font(DS.Font.title2)
                        .fontWeight(.bold)
                        .foregroundColor(currentScore > opponentScore ? .green : 
                                       currentScore < opponentScore ? .red : .orange)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground).opacity(0.9))
                )
                
                Button("Return to Dashboard") {
                    completeMatch()
                }
                .font(DS.Font.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(DS.Color.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            .padding()
        }
    }
    
    // MARK: - Match Logic
    
    private func startMatch() {
        // Start countdown
        startCountdown()
    }
    
    private func setupScoreUpdateListener() {
        NotificationCenter.default.addObserver(
            forName: .localScoreUpdated,
            object: nil,
            queue: .main
        ) { notification in
            guard let scoreUpdate = notification.object as? ScoreUpdate,
                  scoreUpdate.matchId == match.id else { return }
            
            // Update scores from opponent
            player1Score = scoreUpdate.player1Score
            player2Score = scoreUpdate.player2Score
            
            print("📊 Received score update: \(scoreUpdate.player1Score)-\(scoreUpdate.player2Score)")
        }
    }
    
    private func startCountdown() {
        countdown = 3
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdown -= 1
            
            if countdown <= 0 {
                timer.invalidate()
                matchStatus = .active
                startGameTimer()
            }
        }
    }
    
    private func startGameTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            gameTime += 1
        }
    }
    
    private func updateScore(_ newScore: Int) {
        if isPlayer1 {
            player1Score = newScore
        } else {
            player2Score = newScore
        }
        
        // Send score update to opponent via MultipeerConnectivity
        sendScoreUpdate()
    }
    
    private func sendScoreUpdate() {
        // Send real-time score update via MultipeerConnectivity
        do {
            try appState.localMatchmakingService?.sendScoreUpdate(
                matchId: match.id,
                player1Score: player1Score,
                player2Score: player2Score
            )
            print("📊 Sent score update: \(player1Score)-\(player2Score)")
        } catch {
            print("❌ Failed to send score update: \(error)")
        }
    }
    
    private func endMatch() {
        gameTimer?.invalidate()
        matchStatus = .completed
        showingResults = true
    }
    
    private func completeMatch() {
        // Calculate results
        let isWin = currentScore > opponentScore
        let eloChange = calculateEloChange(isWin: isWin)
        let matchResult: DinkDropZoneFinal.MatchResult
        if isWin {
            matchResult = .win(pointsScored: currentScore, pointsConceded: opponentScore, eloChange: eloChange)
        } else {
            matchResult = .loss(pointsScored: currentScore, pointsConceded: opponentScore, eloChange: eloChange)
        }
        
        // Create GameMatch object
        let gameMatch = GameMatch(
            opponentName: opponentPlayer.displayName,
            result: isWin ? "Win" : "Loss",
            score: "\(currentScore)-\(opponentScore)",
            eloChange: isWin ? "+\(matchResult.eloChange)" : "\(matchResult.eloChange)",
            date: Date()
        )
        
        // Update user stats
        Task {
            await appState.completeMatch(gameMatch, result: matchResult)
        }
        
        // Clear the active match setup
        appState.activeMatchSetup = nil
        
        // Post completion notification
        NotificationCenter.default.post(name: .localMatchCompleted, object: match)
        
        // Return to main app
        dismiss()
    }
    
    private func calculateEloChange(isWin: Bool) -> Int {
        // Simple ELO calculation - could be enhanced
        let baseDelta = 15
        return isWin ? baseDelta : -baseDelta
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

#Preview {
    let sampleMatch = LocalMatchmakingService.LocalMatch(
        id: "sample",
        player1: LocalMatchmakingService.NearbyPlayer(
            id: "1",
            displayName: "Player 1",
            elo: 1200,
            matchType: "Casual",
            distance: 0.1,
            peerID: "device1"
        ),
        player2: LocalMatchmakingService.NearbyPlayer(
            id: "2", 
            displayName: "Player 2",
            elo: 1150,
            matchType: "Casual",
            distance: 0.1,
            peerID: "device2"
        ),
        matchType: "Casual",
        createdAt: Date()
    )
    
    LiveMatchView(match: sampleMatch)
        .environmentObject(AppState())
} 