import SwiftUI

struct MatchmakingView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var isSearching = false
    @State private var searchTime: Int = 0
    @State private var timer: Timer?
    @State private var selectedGameMode: GameMode = .casual
    @State private var showingMatchFound = false
    @State private var matchedPlayer: User?
    @State private var estimatedWaitTime: Int = 30
    
    enum GameMode: String, CaseIterable {
        case casual = "Casual"
        case ranked = "Ranked"
        case tournament = "Tournament"
        
        var icon: String {
            switch self {
            case .casual: return "figure.table.tennis"
            case .ranked: return "trophy.fill"
            case .tournament: return "person.3.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .casual: return DS.Color.accent
            case .ranked: return .orange
            case .tournament: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Game Mode Selection
                    gameModeSelection
                    
                    // Queue Status
                    queueStatus
                    
                    // Match Info
                    if showingMatchFound {
                        matchFoundView
                    }
                    
                    Spacer()
                    
                    // Action Button
                    actionButton
                }
                .padding()
            }
            .navigationTitle("Find Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        stopSearch()
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Update app state to reflect we're in queue
                if !isSearching {
                    appState.isInQueue = false
                }
            }
            .onDisappear {
                // Clean up timer when view disappears
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private var gameModeSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Mode")
                .font(DS.Font.headline)
                .fontWeight(.bold)
            
            HStack(spacing: 16) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    GameModeButton(
                        mode: mode,
                        isSelected: selectedGameMode == mode,
                        action: {
                            withAnimation {
                                selectedGameMode = mode
                            }
                        }
                    )
                }
            }
        }
        .dsCard()
    }
    
    private var queueStatus: some View {
        VStack(spacing: 20) {
            // Search Animation
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [selectedGameMode.color, selectedGameMode.color.opacity(0.5), selectedGameMode.color],
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(isSearching ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 2)
                            .repeatForever(autoreverses: false),
                        value: isSearching
                    )
                
                Image(systemName: "person.2.fill")
                    .font(.system(size: 40))
                    .foregroundColor(selectedGameMode.color)
            }
            
            // Status Text
            Text(isSearching ? "Searching for opponent..." : "Ready to play")
                .font(DS.Font.title3)
                .fontWeight(.medium)
            
            // Search Time
            if isSearching {
                Text(formatTime(searchTime))
                    .font(DS.Font.title2)
                    .monospacedDigit()
                    .foregroundColor(DS.Color.secondary)
            }
            
            // Estimated Wait
            if isSearching {
                Text("Estimated wait: \(formatTime(estimatedWaitTime))")
                    .font(DS.Font.subheadline)
                    .foregroundColor(DS.Color.secondary)
            }
            
            // Number of players in queue
            if isSearching {
                Text("\(Int.random(in: 15...30)) players in queue")
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
            }
        }
        .padding()
        .dsCard()
    }
    
    private var matchFoundView: some View {
        VStack(spacing: 20) {
            Text("Match Found!")
                .font(DS.Font.title2)
                .fontWeight(.bold)
                .foregroundColor(selectedGameMode.color)
            
            if let player = matchedPlayer {
                // Opponent Info
                VStack(spacing: 12) {
                    Circle()
                        .fill(selectedGameMode.color.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(selectedGameMode.color)
                        )
                    
                    Text(player.displayName.isEmpty ? player.email : player.displayName)
                        .font(DS.Font.title3)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 20) {
                        StatBadge(title: "ELO", value: "\(player.elo)")
                        StatBadge(title: "Win Rate", value: player.formattedWinRate)
                    }
                }
                
                // Match Type
                HStack {
                    Image(systemName: selectedGameMode.icon)
                    Text(selectedGameMode.rawValue)
                }
                .font(DS.Font.headline)
                .foregroundColor(selectedGameMode.color)
            }
        }
        .padding()
        .dsCard()
        .transition(.scale.combined(with: .opacity))
    }
    
    private var actionButton: some View {
        Button {
            if isSearching {
                stopSearch()
            } else if showingMatchFound {
                startMatch()
            } else {
                startSearch()
            }
        } label: {
            Text(isSearching ? "Cancel Search" : (showingMatchFound ? "Start Match" : "Find Match"))
                .font(DS.Font.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                        .fill(isSearching ? .red : selectedGameMode.color)
                )
        }
    }
    
    // MARK: - Actions
    
    @MainActor
    private func startSearch() {
        isSearching = true
        searchTime = 0
        showingMatchFound = false
        appState.isInQueue = true
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                self.searchTime += 1
                
                // Simulate finding a match after random time
                if self.searchTime >= Int.random(in: 5...15) && !self.showingMatchFound {
                    withAnimation {
                        self.showingMatchFound = true
                        // Find a random nearby player or create one
                        if !self.appState.nearbyPlayers.isEmpty {
                            self.matchedPlayer = self.appState.nearbyPlayers.randomElement()
                        } else {
                            // Create a sample opponent
                            self.matchedPlayer = User(
                                email: "opponent@example.com",
                                password: "",
                                displayName: "Random Player",
                                elo: Int.random(in: 900...1200),
                                xp: Int.random(in: 1000...2000),
                                totalMatches: Int.random(in: 10...30),
                                wins: Int.random(in: 5...20),
                                losses: Int.random(in: 5...10),
                                winStreak: Int.random(in: 0...3)
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func stopSearch() {
        isSearching = false
        showingMatchFound = false
        appState.isInQueue = false
        timer?.invalidate()
        timer = nil
    }
    
    private func startMatch() {
        // Simulate match completion
        if let opponent = matchedPlayer, let _ = appState.currentUser {
            let isWin = Bool.random()
            let playerScore = isWin ? 11 : Int.random(in: 7...10)
            let opponentScore = isWin ? Int.random(in: 5...9) : 11
            let eloChange = isWin ? Int.random(in: 8...15) : -Int.random(in: 5...12)
            
            // Create match result
            let result: DinkDropZoneFinal.MatchResult
            if isWin {
                result = .win(pointsScored: playerScore, pointsConceded: opponentScore, eloChange: eloChange)
            } else {
                result = .loss(pointsScored: playerScore, pointsConceded: opponentScore, eloChange: eloChange)
            }
            
            // Create match
            let match = GameMatch(
                opponentName: opponent.displayName.isEmpty ? opponent.email : opponent.displayName,
                result: isWin ? "Win" : "Loss",
                score: "\(playerScore)-\(opponentScore)",
                eloChange: isWin ? "+\(eloChange)" : "\(eloChange)",
                date: Date()
            )
            
            // Complete match
            Task {
                await appState.completeMatch(match, result: result)
            }
        }
        
        // Reset state and dismiss
        appState.isInQueue = false
        dismiss()
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", minutes, secs)
    }
}

// MARK: - Supporting Views

struct GameModeButton: View {
    let mode: MatchmakingView.GameMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? mode.color : DS.Color.surface)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: mode.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : mode.color)
                }
                
                Text(mode.rawValue)
                    .font(DS.Font.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? mode.color : DS.Color.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StatBadge: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.secondary)
            
            Text(value)
                .font(DS.Font.headline)
                .foregroundColor(DS.Color.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(DS.Color.surface)
        .cornerRadius(8)
    }
}

#Preview {
    MatchmakingView()
        .environmentObject(AppState())
} 
