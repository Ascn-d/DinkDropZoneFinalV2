import SwiftUI

struct EnhancedLiveMatchView: View {
    let configuration: MatchConfiguration
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var matchState: MatchState
    @State private var gameTimer: Timer?
    @State private var totalMatchTime: TimeInterval = 0
    @State private var currentGameTime: TimeInterval = 0
    @State private var showingEndMatch = false
    @State private var showingResults = false
    @State private var animateScoreUpdate = false
    @State private var showingGameComplete = false
    @State private var gameCompleteMessage = ""
    
    init(configuration: MatchConfiguration) {
        self.configuration = configuration
        self._matchState = State(initialValue: {
            var state = MatchState(configuration: configuration)
            state.initializeGames()
            return state
        }())
    }
    
    private var isPlayer1: Bool {
        guard let currentUser = appState.currentUser else { return true }
        return configuration.player1.id == currentUser.id.uuidString
    }
    
    private var currentPlayer: LocalMatchmakingService.NearbyPlayer {
        return isPlayer1 ? configuration.player1 : configuration.player2
    }
    
    private var opponentPlayer: LocalMatchmakingService.NearbyPlayer {
        return isPlayer1 ? configuration.player2 : configuration.player1
    }
    
    private var currentGame: GameState? {
        return matchState.currentGame
    }
    
    private var currentPlayerScore: Int {
        guard let game = currentGame else { return 0 }
        return isPlayer1 ? game.player1Score : game.player2Score
    }
    
    private var opponentScore: Int {
        guard let game = currentGame else { return 0 }
        return isPlayer1 ? game.player2Score : game.player1Score
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Dynamic background based on match progress
                backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Match Header with Games Progress
                    matchHeaderWithProgress
                    
                    // Current Game Display
                    currentGameDisplay
                    
                    // Score Controls
                    if !matchState.isCompleted {
                        scoreControlsSection
                    }
                    
                    // Match Timer
                    timerDisplay
                    
                    Spacer()
                    
                    // Action Buttons
                    if !matchState.isCompleted {
                        actionButtons
                    }
                }
                .padding()
                
                // Game Complete Overlay
                if showingGameComplete {
                    gameCompleteOverlay
                }
                
                // Match Results Overlay
                if showingResults {
                    matchResultsOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startMatchTimer()
        }
        .onDisappear {
            gameTimer?.invalidate()
        }
        .alert("End Match?", isPresented: $showingEndMatch) {
            Button("Cancel", role: .cancel) { }
            Button("End Match", role: .destructive) {
                endMatch()
            }
        } message: {
            Text("Are you sure you want to end this match? Current progress will be saved.")
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                matchState.isCompleted ? .green.opacity(0.3) : DS.Color.accent.opacity(0.1),
                DS.Color.background,
                matchState.isCompleted ? .blue.opacity(0.3) : DS.Color.accent.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: 1.0), value: matchState.isCompleted)
    }
    
    // MARK: - Match Header with Progress
    
    private var matchHeaderWithProgress: some View {
        VStack(spacing: 16) {
            // Exit and Match Type
            HStack {
                Button("Exit") {
                    showingEndMatch = true
                }
                .foregroundColor(.red)
                .font(.headline)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text(configuration.matchFormat.rawValue)
                        .font(DS.Font.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DS.Color.primary)
                    
                    Text(configuration.scoringSystem.rawValue)
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(matchState.isCompleted ? .green : .orange)
                    .frame(width: 12, height: 12)
            }
            
            // Players with Games Won
            HStack(spacing: 20) {
                playerGameProgress(currentPlayer, gamesWon: isPlayer1 ? matchState.player1GamesWon : matchState.player2GamesWon, isCurrentUser: true)
                
                Text("VS")
                    .font(DS.Font.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DS.Color.secondary)
                
                playerGameProgress(opponentPlayer, gamesWon: isPlayer1 ? matchState.player2GamesWon : matchState.player1GamesWon, isCurrentUser: false)
            }
            
            // Games Progress Indicator
            if configuration.matchFormat.maxGames > 1 {
                gamesProgressIndicator
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10)
        )
    }
    
    private func playerGameProgress(_ player: LocalMatchmakingService.NearbyPlayer, gamesWon: Int, isCurrentUser: Bool) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(LinearGradient(
                    colors: isCurrentUser ? [DS.Color.accent, DS.Color.accent.opacity(0.7)] : [.gray, .gray.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(player.displayName.prefix(1)).uppercased())
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(spacing: 2) {
                Text(player.displayName)
                    .font(DS.Font.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                // Games won display
                Text("Games: \(gamesWon)")
                    .font(DS.Font.caption)
                    .foregroundColor(.secondary)
                
                Text("\(player.elo) ELO")
                    .font(DS.Font.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var gamesProgressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<configuration.matchFormat.maxGames, id: \.self) { gameIndex in
                Circle()
                    .fill(gameWinnerColor(gameIndex))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text("\(gameIndex + 1)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(gameIndex == matchState.currentGameIndex ? DS.Color.accent : .clear, lineWidth: 2)
                            .frame(width: 24, height: 24)
                    )
            }
        }
    }
    
    private func gameWinnerColor(_ gameIndex: Int) -> Color {
        guard gameIndex < matchState.games.count else { return .gray.opacity(0.3) }
        let game = matchState.games[gameIndex]
        
        if !game.isCompleted {
            return gameIndex == matchState.currentGameIndex ? .orange : .gray.opacity(0.3)
        }
        
        guard let winner = game.winner else { return .gray }
        
        if winner == configuration.player1.id {
            return isPlayer1 ? DS.Color.accent : .red
        } else {
            return isPlayer1 ? .red : DS.Color.accent
        }
    }
    
    // MARK: - Current Game Display
    
    private var currentGameDisplay: some View {
        VStack(spacing: 20) {
            // Game Number and Status
            if let game = currentGame {
                Text("Game \(game.gameNumber)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DS.Color.primary)
            }
            
            // Current Score Display
            HStack(spacing: 40) {
                // Current Player Score
                VStack(spacing: 8) {
                    Text("\(currentPlayerScore)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(DS.Color.accent)
                        .scaleEffect(animateScoreUpdate ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateScoreUpdate)
                    
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
            
            // Win Condition Progress
            winConditionProgress
        }
        .padding(.vertical, 32)
    }
    
    private var winConditionProgress: some View {
        VStack(spacing: 8) {
            Text("Playing to \(getGameWinCondition())")
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.secondary)
            
            // Progress bars for both players
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    ProgressView(value: Double(currentPlayerScore), total: Double(getGameWinCondition()))
                        .progressViewStyle(LinearProgressViewStyle(tint: DS.Color.accent))
                        .frame(width: 100)
                    Text("You")
                        .font(.caption2)
                        .foregroundColor(DS.Color.secondary)
                }
                
                VStack(spacing: 4) {
                    ProgressView(value: Double(opponentScore), total: Double(getGameWinCondition()))
                        .progressViewStyle(LinearProgressViewStyle(tint: .gray))
                        .frame(width: 100)
                    Text("Opponent")
                        .font(.caption2)
                        .foregroundColor(DS.Color.secondary)
                }
            }
        }
    }
    
    // MARK: - Score Controls
    
    private var scoreControlsSection: some View {
        VStack(spacing: 20) {
            Text("Update Your Score")
                .font(DS.Font.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 24) {
                // Subtract Point Button
                Button(action: {
                    updateCurrentPlayerScore(currentPlayerScore - 1)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(currentPlayerScore > 0 ? .red : .gray.opacity(0.5))
                }
                .disabled(currentPlayerScore <= 0)
                
                // Current Score Display
                Text("\(currentPlayerScore)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(DS.Color.primary)
                    .frame(minWidth: 80)
                
                // Add Point Button
                Button(action: {
                    updateCurrentPlayerScore(currentPlayerScore + 1)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(DS.Color.accent)
                }
            }
            
            // Quick add buttons
            HStack(spacing: 12) {
                quickScoreButton("+1") { updateCurrentPlayerScore(currentPlayerScore + 1) }
                quickScoreButton("+2") { updateCurrentPlayerScore(currentPlayerScore + 2) }
                quickScoreButton("+3") { updateCurrentPlayerScore(currentPlayerScore + 3) }
                
                Divider()
                    .frame(height: 30)
                
                quickScoreButton("Undo") { 
                    if currentPlayerScore > 0 {
                        updateCurrentPlayerScore(currentPlayerScore - 1)
                    }
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
    
    private func quickScoreButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(title == "Undo" ? .gray : DS.Color.accent)
                )
        }
    }
    
    // MARK: - Timer Display
    
    private var timerDisplay: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("Game Time")
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
                
                Text(formatTime(currentGameTime))
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundColor(DS.Color.primary)
            }
            
            Divider()
                .frame(height: 40)
            
            VStack(spacing: 4) {
                Text("Total Time")
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
                
                Text(formatTime(totalMatchTime))
                    .font(.system(size: 20, weight: .semibold, design: .monospaced))
                    .foregroundColor(DS.Color.primary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            if gameCanBeCompleted() {
                Button("Complete Game") {
                    completeCurrentGame()
                }
                .font(DS.Font.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.gradient)
                )
            }
            
            Button("End Match Early") {
                showingEndMatch = true
            }
            .font(DS.Font.subheadline)
            .foregroundColor(.red)
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Overlays
    
    private var gameCompleteOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Game Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(gameCompleteMessage)
                    .font(.headline)
                    .foregroundColor(.green)
                
                Button("Next Game") {
                    proceedToNextGame()
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding()
                .background(DS.Color.accent)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }
    
    private var matchResultsOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Match Complete!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Final match results
                VStack(spacing: 16) {
                    Text("Final Result")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 40) {
                        VStack {
                            Text("\(isPlayer1 ? matchState.player1GamesWon : matchState.player2GamesWon)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(didWinMatch() ? .green : .white)
                            Text("You")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Text("-")
                            .font(.title)
                            .foregroundColor(.white)
                        
                        VStack {
                            Text("\(isPlayer1 ? matchState.player2GamesWon : matchState.player1GamesWon)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(!didWinMatch() ? .green : .white)
                            Text("Opponent")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    
                    let resultText = didWinMatch() ? "Victory!" : "Defeat"
                    Text(resultText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(didWinMatch() ? .green : .red)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground).opacity(0.9))
                )
                
                Button("Return to Dashboard") {
                    completeMatch()
                }
                .font(.headline)
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
    
    // MARK: - Helper Methods
    
    private func startMatchTimer() {
        gameTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            totalMatchTime += 1
            currentGameTime += 1
        }
    }
    
    private func updateCurrentPlayerScore(_ newScore: Int) {
        guard var game = currentGame, newScore >= 0 else { return }
        
        if isPlayer1 {
            game.player1Score = newScore
        } else {
            game.player2Score = newScore
        }
        
        matchState.currentGame = game
        
        // Animate score update
        withAnimation(.spring()) {
            animateScoreUpdate = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateScoreUpdate = false
        }
        
        // Send score update to opponent
        sendScoreUpdate()
    }
    
    private func sendScoreUpdate() {
        // Send real-time score update via MultipeerConnectivity
        do {
            try appState.localMatchmakingService?.sendScoreUpdate(
                matchId: matchState.id,
                player1Score: currentGame?.player1Score ?? 0,
                player2Score: currentGame?.player2Score ?? 0
            )
        } catch {
            print("❌ Failed to send score update: \(error)")
        }
    }
    
    private func gameCanBeCompleted() -> Bool {
        guard let game = currentGame else { return false }
        let winCondition = getGameWinCondition()
        return game.player1Score >= winCondition || game.player2Score >= winCondition
    }
    
    private func getGameWinCondition() -> Int {
        switch configuration.matchFormat {
        case .firstToEleven: return 11
        case .firstToFifteen: return 15
        case .firstToTwentyOne: return 21
        default: return 11 // Default for best-of formats
        }
    }
    
    private func completeCurrentGame() {
        guard var game = currentGame else { return }
        
        // Determine winner
        let winner = game.player1Score > game.player2Score ? configuration.player1.id : configuration.player2.id
        game.complete(winner: winner)
        matchState.currentGame = game
        
        currentGameTime = 0 // Reset game timer
        
        // Show game complete message
        let isCurrentUserWinner = (isPlayer1 && winner == configuration.player1.id) || (!isPlayer1 && winner == configuration.player2.id)
        gameCompleteMessage = isCurrentUserWinner ? "You won this game!" : "Opponent won this game!"
        
        // Check if match is complete
        if isMatchComplete() {
            matchState.completeMatch()
            showingResults = true
        } else {
            showingGameComplete = true
        }
    }
    
    private func isMatchComplete() -> Bool {
        let player1Games = matchState.player1GamesWon
        let player2Games = matchState.player2GamesWon
        let winCondition = configuration.matchFormat.winCondition
        
        return player1Games >= winCondition || player2Games >= winCondition
    }
    
    private func proceedToNextGame() {
        matchState.advanceToNextGame()
        showingGameComplete = false
    }
    
    private func didWinMatch() -> Bool {
        guard let winner = matchState.winner else { return false }
        return (isPlayer1 && winner == configuration.player1.id) || (!isPlayer1 && winner == configuration.player2.id)
    }
    
    private func endMatch() {
        if !matchState.isCompleted {
            matchState.completeMatch()
        }
        showingResults = true
    }
    
    private func completeMatch() {
        // Calculate overall match result for ELO/stats
        let didWin = didWinMatch()
        let totalPlayerPoints = matchState.games.reduce(0) { total, game in
            total + (isPlayer1 ? game.player1Score : game.player2Score)
        }
        let totalOpponentPoints = matchState.games.reduce(0) { total, game in
            total + (isPlayer1 ? game.player2Score : game.player1Score)
        }
        
        let matchResult: DinkDropZoneFinal.MatchResult
        if didWin {
            matchResult = .win(pointsScored: totalPlayerPoints, pointsConceded: totalOpponentPoints, eloChange: 15)
        } else {
            matchResult = .loss(pointsScored: totalPlayerPoints, pointsConceded: totalOpponentPoints, eloChange: -15)
        }
        
        // Create GameMatch object for stats
        let gameMatch = GameMatch(
            opponentName: opponentPlayer.displayName,
            result: didWin ? "Win" : "Loss",
            score: "\(isPlayer1 ? matchState.player1GamesWon : matchState.player2GamesWon)-\(isPlayer1 ? matchState.player2GamesWon : matchState.player1GamesWon)",
            eloChange: didWin ? "+15" : "-15",
            date: Date()
        )
        
        // Update user stats
        Task {
            await appState.completeMatch(gameMatch, result: matchResult)
        }
        
        // Clear active match and return
        appState.activeMatchSetup = nil
        dismiss()
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

#Preview {
    let sampleConfig = MatchConfiguration(
        matchFormat: .bestOfThree,
        scoringSystem: .traditional,
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
    
    EnhancedLiveMatchView(configuration: sampleConfig)
        .environmentObject(AppState())
} 