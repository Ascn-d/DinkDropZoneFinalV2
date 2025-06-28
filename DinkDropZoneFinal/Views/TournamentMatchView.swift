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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Enhanced Match Header
                enhancedMatchHeader
                
                // Match Timer (if in progress)
                if showMatchTimer {
                    matchTimerView
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
            .navigationTitle("Tournament Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        stopTimer()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Match History", systemImage: "clock.arrow.circlepath") {
                            showMatchHistory = true
                        }
                        
                        Button("Add Notes", systemImage: "note.text") {
                            // Add notes functionality
                        }
                        
                        if match.status == "Ready" && canStartMatch {
                            Button("Start Match", systemImage: "play.circle") {
                                startMatch()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showScoreEntry) {
                enhancedScoreEntryView
            }
            .sheet(isPresented: $showGameScoreEntry) {
                gameScoreEntryView
            }
            .onDisappear {
                stopTimer()
            }
        }
    }
    
    // MARK: - Match Header
    
    private var matchHeader: some View {
        VStack(spacing: 16) {
            // Tournament Name
            Text(tournament.name)
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Match Identifier
            VStack(spacing: 8) {
                Text(match.displayName)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(match.bracket == "Winners" ? "Winners Bracket" : "Losers Bracket")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Status Badge
            HStack {
                Label(match.status, systemImage: "circle.fill")
                    .foregroundColor(statusColor)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.1))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var statusColor: Color {
        switch match.status {
        case "Upcoming": return .gray
        case "Ready": return .blue
        case "In Progress": return .orange
        case "Completed": return .green
        case "Defaulted", "Cancelled": return .red
        default: return .gray
        }
    }
    
    // MARK: - Players Section
    
    private var playersSection: some View {
        VStack(spacing: 20) {
            // Player 1
            playerCard(
                name: match.player1Name,
                seed: nil, // Simplified model doesn't have seeds
                isCurrentUser: match.player1ID == appState.currentUser?.id.uuidString,
                isWinner: match.winnerID == match.player1ID
            )
            
            // VS Separator
            HStack {
                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(height: 1)
                
                Text("VS")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Player 2
            playerCard(
                name: match.player2Name,
                seed: nil, // Simplified model doesn't have seeds
                isCurrentUser: match.player2ID == appState.currentUser?.id.uuidString,
                isWinner: match.winnerID == match.player2ID
            )
        }
    }
    
    private func playerCard(name: String, seed: Int?, isCurrentUser: Bool, isWinner: Bool) -> some View {
        HStack(spacing: 16) {
            // Seed Badge (optional since simplified model doesn't have seeds)
            if let seed = seed {
                Text("\(seed)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(Circle().fill(.blue))
            }
            
            // Player Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name.isEmpty ? "TBD" : name)
                        .font(.title3)
                        .fontWeight(isWinner ? .bold : .medium)
                    
                    if isCurrentUser {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(.blue.opacity(0.1))
                            )
                    }
                }
                
                if isWinner {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                        Text("Winner")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? .blue.opacity(0.1) : 
                      isWinner ? .green.opacity(0.1) : .gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isCurrentUser ? .blue : 
                            isWinner ? .green : .gray.opacity(0.3),
                            lineWidth: isCurrentUser ? 2 : 1
                        )
                )
        )
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
                try await service.submitMatchResult(
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
    
    // MARK: - Enhanced Match Header
    
    private var enhancedMatchHeader: some View {
        VStack(spacing: 16) {
            // Tournament Name
            Text(tournament.name)
                .font(.headline)
                .foregroundColor(.secondary)
            
            // Match Identifier
            VStack(spacing: 8) {
                Text(match.displayName)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(match.bracket == "Winners" ? "Winners Bracket" : "Losers Bracket")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Status Badge
            HStack {
                Label(match.status, systemImage: "circle.fill")
                    .foregroundColor(statusColor)
                    .font(.subheadline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.1))
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Enhanced Players Section
    
    private var enhancedPlayersSection: some View {
        VStack(spacing: 20) {
            // Player 1
            playerCard(
                name: match.player1Name,
                seed: nil, // Simplified model doesn't have seeds
                isCurrentUser: match.player1ID == appState.currentUser?.id.uuidString,
                isWinner: match.winnerID == match.player1ID
            )
            
            // VS Separator
            HStack {
                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(height: 1)
                
                Text("VS")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Rectangle()
                    .fill(.secondary.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Player 2
            playerCard(
                name: match.player2Name,
                seed: nil, // Simplified model doesn't have seeds
                isCurrentUser: match.player2ID == appState.currentUser?.id.uuidString,
                isWinner: match.winnerID == match.player2ID
            )
        }
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