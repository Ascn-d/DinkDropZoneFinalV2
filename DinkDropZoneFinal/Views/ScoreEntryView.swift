import SwiftUI

struct ScoreEntryView: View {
    let match: TournamentMatch
    let tournament: Tournament
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var appState: AppState
    @StateObject private var tournamentService = TournamentService(firebaseService: FirebaseService.shared)
    
    // Score tracking
    @State private var player1Games: [Int] = []
    @State private var player2Games: [Int] = []
    @State private var currentGamePlayer1Score = 0
    @State private var currentGamePlayer2Score = 0
    @State private var currentGame = 1
    @State private var isMatchComplete = false
    @State private var matchWinner: String? = nil
    
    // Game settings
    @State private var pointsToWin = 11
    @State private var mustWinByTwo = true
    @State private var bestOfGames = 3
    
    // UI State
    @State private var isSubmitting = false
    @State private var showingConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingMatchComplete = false
    
    // Animation states
    @State private var animateScoreChange = false
    @State private var lastScoredPlayer: Int? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Match header
                        matchHeaderSection
                        
                        // Current game score
                        currentGameSection
                        
                        // Games completed
                        if !player1Games.isEmpty {
                            completedGamesSection
                        }
                        
                        // Score controls
                        scoreControlsSection
                        
                        // Match status
                        matchStatusSection
                        
                        // Action buttons
                        actionButtonsSection
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
        }
        .navigationTitle("Score Entry")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            }
        )
        .onAppear {
            setupGameSettings()
        }
        .alert("Match Complete!", isPresented: $showingMatchComplete) {
            Button("Submit Result") {
                submitMatchResult()
            }
            Button("Continue Editing") { }
        } message: {
            Text("\(getWinnerName()) wins the match!")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showingConfirmation) {
            ScoreConfirmationView(
                match: match,
                player1Games: player1Games,
                player2Games: player2Games,
                winner: matchWinner ?? "",
                onConfirm: submitMatchResult,
                onCancel: { showingConfirmation = false }
            )
        }
    }
    
    // MARK: - Match Header Section
    
    private var matchHeaderSection: some View {
        VStack(spacing: 16) {
            // Match info
            HStack {
                Text(match.displayName)
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(tournament.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Players
            HStack {
                // Player 1
                VStack(spacing: 8) {
                    Text(match.player1Name.isEmpty ? "Player 1" : match.player1Name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(matchWinner == match.player1ID ? .green : .primary)
                        .multilineTextAlignment(.center)
                    
                    if matchWinner == match.player1ID {
                        Image(systemName: "crown.fill")
                            .font(.title3)
                            .foregroundColor(.yellow)
                            .scaleEffect(animateScoreChange ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateScoreChange)
                    }
                }
                .frame(maxWidth: .infinity)
                
                Text("VS")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                // Player 2
                VStack(spacing: 8) {
                    Text(match.player2Name.isEmpty ? "Player 2" : match.player2Name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(matchWinner == match.player2ID ? .green : .primary)
                        .multilineTextAlignment(.center)
                    
                    if matchWinner == match.player2ID {
                        Image(systemName: "crown.fill")
                            .font(.title3)
                            .foregroundColor(.yellow)
                            .scaleEffect(animateScoreChange ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateScoreChange)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.quaternary, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Current Game Section
    
    private var currentGameSection: some View {
        VStack(spacing: 20) {
            // Game indicator
            HStack {
                Text("Game \(currentGame)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("First to \(pointsToWin)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Score display
            HStack(spacing: 40) {
                // Player 1 score
                VStack(spacing: 8) {
                    Text("\(currentGamePlayer1Score)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(lastScoredPlayer == 1 ? .blue : .primary)
                        .scaleEffect(lastScoredPlayer == 1 && animateScoreChange ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateScoreChange)
                    
                    Text("Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(.quaternary)
                    .frame(width: 2, height: 80)
                
                // Player 2 score
                VStack(spacing: 8) {
                    Text("\(currentGamePlayer2Score)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(lastScoredPlayer == 2 ? .blue : .primary)
                        .scaleEffect(lastScoredPlayer == 2 && animateScoreChange ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateScoreChange)
                    
                    Text("Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Game status
            if isGameComplete() {
                Text("Game \(currentGame) Complete!")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(.green.opacity(0.1))
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.quaternary, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Completed Games Section
    
    private var completedGamesSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Games Completed")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(getPlayer1GamesWon()) - \(getPlayer2GamesWon())")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(player1Games.enumerated()), id: \.offset) { index, player1Score in
                        let player2Score = player2Games[index]
                        GameScoreCard(
                            gameNumber: index + 1,
                            player1Score: player1Score,
                            player2Score: player2Score,
                            player1Name: match.player1Name,
                            player2Name: match.player2Name
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Score Controls Section
    
    private var scoreControlsSection: some View {
        VStack(spacing: 24) {
            Text("Add Points")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 40) {
                // Player 1 controls
                VStack(spacing: 16) {
                    Text(match.player1Name.isEmpty ? "Player 1" : match.player1Name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    VStack(spacing: 12) {
                        Button {
                            addPoint(to: 1)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                        }
                        .disabled(isGameComplete() || isMatchComplete)
                        .scaleEffect(lastScoredPlayer == 1 && animateScoreChange ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateScoreChange)
                        
                        Button {
                            removePoint(from: 1)
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 30))
                                .foregroundColor(.red)
                        }
                        .disabled(currentGamePlayer1Score == 0)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Player 2 controls
                VStack(spacing: 16) {
                    Text(match.player2Name.isEmpty ? "Player 2" : match.player2Name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    VStack(spacing: 12) {
                        Button {
                            addPoint(to: 2)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                        }
                        .disabled(isGameComplete() || isMatchComplete)
                        .scaleEffect(lastScoredPlayer == 2 && animateScoreChange ? 1.1 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateScoreChange)
                        
                        Button {
                            removePoint(from: 2)
                        } label: {
                            Image(systemName: "minus.circle")
                                .font(.system(size: 30))
                                .foregroundColor(.red)
                        }
                        .disabled(currentGamePlayer2Score == 0)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Match Status Section
    
    private var matchStatusSection: some View {
        VStack(spacing: 16) {
            if isGameComplete() && !isMatchComplete {
                Button {
                    finishCurrentGame()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        
                        Text("Finish Game \(currentGame)")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            
            if isMatchComplete {
                VStack(spacing: 12) {
                    Text("🏆 MATCH COMPLETE! 🏆")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("\(getWinnerName()) wins \(getPlayer1GamesWon())-\(getPlayer2GamesWon())!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.green.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.green, lineWidth: 2)
                        )
                )
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if isMatchComplete {
                Button {
                    showingConfirmation = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "paperplane.fill")
                            .font(.title3)
                        
                        Text(isSubmitting ? "Submitting..." : "Submit Match Result")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isSubmitting)
            }
            
            Button {
                resetMatch()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Match")
                }
                .foregroundColor(.red)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .stroke(.red, lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupGameSettings() {
        // Set up game settings based on tournament rules
        pointsToWin = 11 // Default pickleball
        mustWinByTwo = true
        bestOfGames = 3
    }
    
    private func addPoint(to player: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if player == 1 {
                currentGamePlayer1Score += 1
            } else {
                currentGamePlayer2Score += 1
            }
            
            lastScoredPlayer = player
            animateScoreChange.toggle()
        }
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Check if game is complete
        if isGameComplete() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }
    
    private func removePoint(from player: Int) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if player == 1 && currentGamePlayer1Score > 0 {
                currentGamePlayer1Score -= 1
            } else if player == 2 && currentGamePlayer2Score > 0 {
                currentGamePlayer2Score -= 1
            }
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func isGameComplete() -> Bool {
        let p1Score = currentGamePlayer1Score
        let p2Score = currentGamePlayer2Score
        
        if mustWinByTwo {
            return (p1Score >= pointsToWin && p1Score - p2Score >= 2) ||
                   (p2Score >= pointsToWin && p2Score - p1Score >= 2)
        } else {
            return p1Score >= pointsToWin || p2Score >= pointsToWin
        }
    }
    
    private func finishCurrentGame() {
        player1Games.append(currentGamePlayer1Score)
        player2Games.append(currentGamePlayer2Score)
        
        currentGamePlayer1Score = 0
        currentGamePlayer2Score = 0
        currentGame += 1
        
        // Check if match is complete
        let p1GamesWon = getPlayer1GamesWon()
        let p2GamesWon = getPlayer2GamesWon()
        let gamesToWin = (bestOfGames / 2) + 1
        
        if p1GamesWon >= gamesToWin {
            isMatchComplete = true
            matchWinner = match.player1ID
            showingMatchComplete = true
        } else if p2GamesWon >= gamesToWin {
            isMatchComplete = true
            matchWinner = match.player2ID
            showingMatchComplete = true
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            animateScoreChange.toggle()
        }
    }
    
    private func getPlayer1GamesWon() -> Int {
        return player1Games.enumerated().filter { index, p1Score in
            let p2Score = player2Games[index]
            return p1Score > p2Score
        }.count
    }
    
    private func getPlayer2GamesWon() -> Int {
        return player2Games.enumerated().filter { index, p2Score in
            let p1Score = player1Games[index]
            return p2Score > p1Score
        }.count
    }
    
    private func getWinnerName() -> String {
        if matchWinner == match.player1ID {
            return match.player1Name.isEmpty ? "Player 1" : match.player1Name
        } else {
            return match.player2Name.isEmpty ? "Player 2" : match.player2Name
        }
    }
    
    private func resetMatch() {
        player1Games.removeAll()
        player2Games.removeAll()
        currentGamePlayer1Score = 0
        currentGamePlayer2Score = 0
        currentGame = 1
        isMatchComplete = false
        matchWinner = nil
    }
    
    private func submitMatchResult() {
        guard isMatchComplete, let winner = matchWinner else { return }
        
        isSubmitting = true
        
        Task {
            do {
                let finalScore = "\(getPlayer1GamesWon())-\(getPlayer2GamesWon())"
                let loser = winner == match.player1ID ? match.player2ID : match.player1ID
                
                // Use AppState's centralized match result submission
                try await appState.submitMatchResult(
                    match: match,
                    winnerID: winner,
                    loserID: loser,
                    score: finalScore,
                    tournament: tournament
                )
                
                await MainActor.run {
                    isSubmitting = false
                    presentationMode.wrappedValue.dismiss()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to submit result: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct GameScoreCard: View {
    let gameNumber: Int
    let player1Score: Int
    let player2Score: Int
    let player1Name: String
    let player2Name: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Game \(gameNumber)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                VStack(spacing: 4) {
                    Text("\(player1Score)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(player1Score > player2Score ? .green : .secondary)
                    
                    Text(player1Name.isEmpty ? "P1" : String(player1Name.prefix(3)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text("-")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 4) {
                    Text("\(player2Score)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(player2Score > player1Score ? .green : .secondary)
                    
                    Text(player2Name.isEmpty ? "P2" : String(player2Name.prefix(3)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(player1Score > player2Score ? .green.opacity(0.3) : 
                               player2Score > player1Score ? .green.opacity(0.3) : .clear, lineWidth: 1)
                )
        )
    }
}

struct ScoreConfirmationView: View {
    let match: TournamentMatch
    let player1Games: [Int]
    let player2Games: [Int]
    let winner: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Confirm Match Result")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: 16) {
                    Text("Final Score")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        VStack {
                            Text(match.player1Name)
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            Text("\(getPlayer1GamesWon())")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(winner == match.player1ID ? .green : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Text("-")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        VStack {
                            Text(match.player2Name)
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            Text("\(getPlayer2GamesWon())")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(winner == match.player2ID ? .green : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button("Confirm & Submit") {
                        onConfirm()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .navigationTitle("Confirm Result")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func getPlayer1GamesWon() -> Int {
        return player1Games.enumerated().filter { index, p1Score in
            let p2Score = player2Games[index]
            return p1Score > p2Score
        }.count
    }
    
    private func getPlayer2GamesWon() -> Int {
        return player2Games.enumerated().filter { index, p2Score in
            let p1Score = player1Games[index]
            return p2Score > p1Score
        }.count
    }
}

#Preview {
    let match = TournamentMatch(
        round: 1,
        bracket: "Winners",
        matchNumber: 1,
        player1ID: "player1",
        player1Name: "Alice Johnson",
        player2ID: "player2",
        player2Name: "Bob Smith"
    )
    
    let tournament = Tournament(
        name: "Summer Championship",
        organizerID: "organizer1",
        organizerName: "Tournament Director"
    )
    
    ScoreEntryView(match: match, tournament: tournament)
        .environmentObject(AppState())
} 