import SwiftUI

// MARK: - Advanced Match Details View

struct AdvancedMatchDetailsView: View {
    let match: TournamentMatch
    let tournament: Tournament
    let onScoreUpdate: (TournamentMatch, String, String) -> Void
    let onPlayerSwap: (TournamentMatch) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingScoreEntry = false
    @State private var animateEntry = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    colors: [.blue.opacity(0.8), .purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Match header
                        matchHeaderSection
                        
                        // Players section
                        playersSection
                        
                        // Match details
                        matchDetailsSection
                        
                        // Actions
                        actionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Match Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                }
            })
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animateEntry = true
            }
        }
        .sheet(isPresented: $showingScoreEntry) {
            ScoreEntryView(
                match: match,
                tournament: tournament
            )
        }
    }
    
    private var matchHeaderSection: some View {
        VStack(spacing: 16) {
            Text(matchDisplayName)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .scaleEffect(animateEntry ? 1.0 : 0.8)
                .opacity(animateEntry ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateEntry)
            
            StatusPill(text: match.status, color: statusColor)
                .scaleEffect(animateEntry ? 1.0 : 0.8)
                .opacity(animateEntry ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateEntry)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var playersSection: some View {
        VStack(spacing: 20) {
            Text("Players")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                PlayerDetailCard(
                    name: match.player1Name.isEmpty ? "TBD" : match.player1Name,
                    isWinner: match.winnerID == match.player1ID,
                    position: "Player 1"
                )
                
                Text("VS")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                PlayerDetailCard(
                    name: match.player2Name.isEmpty ? "TBD" : match.player2Name,
                    isWinner: match.winnerID == match.player2ID,
                    position: "Player 2"
                )
            }
        }
        .scaleEffect(animateEntry ? 1.0 : 0.8)
        .opacity(animateEntry ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateEntry)
    }
    
    private var matchDetailsSection: some View {
        VStack(spacing: 16) {
            Text("Match Information")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                DetailRow(title: "Round", value: "\(match.round)")
                DetailRow(title: "Match Number", value: "\(match.matchNumber)")
                DetailRow(title: "Bracket", value: match.bracket)
                
                if match.hasResult {
                    DetailRow(title: "Final Score", value: match.finalScore)
                }
                
                if let court = match.court {
                    DetailRow(title: "Court", value: "Court \(court)")
                }
                
                if let scheduledTime = match.scheduledTime {
                    DetailRow(title: "Scheduled", value: scheduledTime.formatted(date: .abbreviated, time: .shortened))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
        }
        .scaleEffect(animateEntry ? 1.0 : 0.8)
        .opacity(animateEntry ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: animateEntry)
    }
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            if canEnterScore {
                Button {
                    showingScoreEntry = true
                } label: {
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                        Text("Enter Score")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.green)
                    )
                }
            }
            
            if match.status != "Completed" {
                Button {
                    onPlayerSwap(match)
                } label: {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right")
                        Text("Swap Players")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.blue)
                    )
                }
            }
        }
        .scaleEffect(animateEntry ? 1.0 : 0.8)
        .opacity(animateEntry ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.0), value: animateEntry)
    }
    
    private var matchDisplayName: String {
        switch match.bracket {
        case "Winners":
            return "Winners Round \(match.round) - Match \(match.matchNumber)"
        case "Losers":
            return "Losers Round \(match.round) - Match \(match.matchNumber)"
        case "Grand Final":
            return "Grand Final"
        default:
            return "Round \(match.round) - Match \(match.matchNumber)"
        }
    }
    
    private var statusColor: Color {
        switch match.status {
        case "Upcoming": return .blue
        case "Ready": return .green
        case "In Progress": return .orange
        case "Completed": return .purple
        default: return .gray
        }
    }
    
    private var canEnterScore: Bool {
        return match.status == "Ready" || match.status == "In Progress"
    }
}

// MARK: - Player Detail Card

struct PlayerDetailCard: View {
    let name: String
    let isWinner: Bool
    let position: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(position)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(name)
                    .font(.title2)
                    .fontWeight(isWinner ? .bold : .medium)
                    .foregroundColor(isWinner ? .yellow : .white)
            }
            
            Spacer()
            
            if isWinner {
                VStack {
                    Image(systemName: "crown.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                    
                    Text("WINNER")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isWinner ? .yellow.opacity(0.2) : .white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isWinner ? .yellow.opacity(0.5) : .white.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Participant Selector View

struct ParticipantSelectorView: View {
    let tournament: Tournament
    let onPlayerSelected: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredParticipants: [TournamentParticipant] {
        if searchText.isEmpty {
            return tournament.participants
        } else {
            return tournament.participants.filter { participant in
                participant.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Search bar
                SearchBar(text: $searchText)
                    .padding()
                
                // Participants list
                List(filteredParticipants) { participant in
                    TournamentParticipantRow(participant: participant) {
                        onPlayerSelected(participant.displayName)
                        dismiss()
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            })
        }
    }
}

// MARK: - Search Bar

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search players...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

// MARK: - Tournament Participant Row

struct TournamentParticipantRow: View {
    let participant: TournamentParticipant
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(participant.displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("ELO: \(participant.elo)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Round Robin Standings View

struct RoundRobinStandingsView: View {
    let tournament: Tournament
    let isEditMode: Bool
    let onMatchTap: (TournamentMatch) -> Void
    
    private var sortedParticipants: [TournamentParticipant] {
        tournament.participants.sorted { p1, p2 in
            if p1.wins != p2.wins {
                return p1.wins > p2.wins
            }
            return p1.losses < p2.losses
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Standings table
            VStack(spacing: 16) {
                // Header
                HStack {
                    Text("Pos")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 40)
                    
                    Text("Player")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("W")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 30)
                    
                    Text("L")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 30)
                    
                    Text("Win %")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 60)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.1))
                )
                
                // Participants
                ForEach(Array(sortedParticipants.enumerated()), id: \.element.id) { index, participant in
                    StandingRow(
                        position: index + 1,
                        participant: participant
                    )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            
            // Matches grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(tournament.matches.filter { $0.bracket == "Round Robin" }) { match in
                    Button {
                        onMatchTap(match)
                    } label: {
                        RoundRobinMatchCard(match: match)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Standing Row

struct StandingRow: View {
    let position: Int
    let participant: TournamentParticipant
    
    private var winPercentage: Double {
        let totalGames = participant.wins + participant.losses
        return totalGames > 0 ? Double(participant.wins) / Double(totalGames) * 100 : 0
    }
    
    private var positionColor: Color {
        switch position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .white.opacity(0.8)
        }
    }
    
    var body: some View {
        HStack {
            // Position
            ZStack {
                Circle()
                    .fill(positionColor)
                    .frame(width: 32, height: 32)
                
                Text("\(position)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(position <= 3 ? .black : .white)
            }
            .frame(width: 40)
            
            // Player name
            Text(participant.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Wins
            Text("\(participant.wins)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.green)
                .frame(width: 30)
            
            // Losses
            Text("\(participant.losses)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.red)
                .frame(width: 30)
            
            // Win percentage
            Text("\(Int(winPercentage))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(position <= 3 ? positionColor.opacity(0.1) : .white.opacity(0.05))
        )
    }
}

// MARK: - Round Robin Match Card

struct RoundRobinMatchCard: View {
    let match: TournamentMatch
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Match \(match.matchNumber)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                StatusDot(status: match.status)
            }
            
            VStack(spacing: 8) {
                Text(match.player1Name.isEmpty ? "TBD" : match.player1Name)
                    .font(.subheadline)
                    .fontWeight(match.winnerID == match.player1ID ? .bold : .medium)
                    .foregroundColor(match.winnerID == match.player1ID ? .yellow : .white)
                    .lineLimit(1)
                
                Text("vs")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                
                Text(match.player2Name.isEmpty ? "TBD" : match.player2Name)
                    .font(.subheadline)
                    .fontWeight(match.winnerID == match.player2ID ? .bold : .medium)
                    .foregroundColor(match.winnerID == match.player2ID ? .yellow : .white)
                    .lineLimit(1)
            }
            
            if match.hasResult {
                Text(match.finalScore)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.green.opacity(0.2))
                    )
            }
        }
        .padding(16)
        .frame(height: 120)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
} 