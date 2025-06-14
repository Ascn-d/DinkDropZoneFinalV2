import SwiftUI
import Observation

struct MatchmakingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var isSearching = false
    @State private var searchTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var selectedGameMode: GameMode = .casual
    @State private var showingMatchFound = false
    @State private var matchedPlayer: User?
    @State private var estimatedWaitTime: TimeInterval = 30
    
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
            case .casual: return .blue
            case .ranked: return .orange
            case .tournament: return .purple
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
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
        }
    }
    
    private var gameModeSelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Game Mode")
                .font(.title2)
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
    }
    
    private var queueStatus: some View {
        VStack(spacing: 20) {
            // Search Animation
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .purple, .blue],
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
                .font(.title3)
                .fontWeight(.medium)
            
            // Search Time
            if isSearching {
                Text(formatTime(searchTime))
                    .font(.title2)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
            
            // Estimated Wait
            if isSearching {
                Text("Estimated wait: \(formatTime(estimatedWaitTime))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
    
    private var matchFoundView: some View {
        VStack(spacing: 20) {
            if let player = matchedPlayer {
                // Opponent Info
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(selectedGameMode.color)
                    
                    Text(player.email)
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 20) {
                        StatBadge(title: "ELO", value: "\(player.elo)")
                        StatBadge(title: "Matches", value: "\(player.xp / 100)")
                    }
                }
                
                // Match Type
                Text(selectedGameMode.rawValue)
                    .font(.headline)
                    .foregroundColor(selectedGameMode.color)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSearching ? .red : selectedGameMode.color)
                )
        }
        .disabled(isSearching && !showingMatchFound)
    }
    
    // MARK: - Actions
    
    private func startSearch() {
        isSearching = true
        searchTime = 0
        showingMatchFound = false
        
        // Start timer
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            searchTime += 1
            
            // Simulate finding a match after random time
            if searchTime >= estimatedWaitTime && !showingMatchFound {
                withAnimation {
                    showingMatchFound = true
                    // Simulate finding a player
                    matchedPlayer = User(
                        email: "opponent@example.com",
                        password: "password123",
                        elo: 1050,
                        xp: 1500,
                        totalMatches: 15,
                        wins: 10,
                        losses: 5,
                        winStreak: 3
                    )
                }
            }
        }
    }
    
    private func stopSearch() {
        isSearching = false
        showingMatchFound = false
        timer?.invalidate()
        timer = nil
    }
    
    private func startMatch() {
        // TODO: Implement match start logic
        dismiss()
    }
    
    // MARK: - Helper Functions
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views

struct GameModeButton: View {
    let mode: MatchmakingView.GameMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.title2)
                Text(mode.rawValue)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? mode.color.opacity(0.2) : Color.clear)
            )
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? mode.color : .clear, lineWidth: 2)
            )
        }
        .foregroundColor(isSelected ? mode.color : .primary)
    }
}

struct StatBadge: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

#Preview {
    MatchmakingView()
        .environment(AppState())
} 
