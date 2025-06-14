import SwiftUI
import SwiftData
import Observation
import Combine
import FirebaseAuth

// MARK: - League Image View
private struct LeagueImageView: View {
    let imageUrl: String?
    
    var body: some View {
        if let imageUrl {
            AsyncImage(url: URL(string: imageUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
            } placeholder: {
                Color.gray.opacity(0.2)
                    .frame(height: 200)
            }
        }
    }
}

// MARK: - League Header View
private struct LeagueHeaderView: View {
    let league: PickleLeague
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Rating
            HStack {
                VStack(alignment: .leading) {
                    Text(league.name)
                        .font(.title2.bold())
                    Text(league.location)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", league.rating))
                }
            }
            
            // Status Badge
            Text(league.status.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(league.status == .inProgress ? Color.green.opacity(0.2) : Color.blue.opacity(0.2))
                .foregroundStyle(league.status == .inProgress ? .green : .blue)
                .clipShape(Capsule())
        }
    }
}

// MARK: - League Description View
private struct LeagueDescriptionView: View {
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
            Text(description)
                .font(.body)
        }
        .padding()
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - League Stats View
private struct LeagueStatsView: View {
    let league: PickleLeague
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(title: "Players", value: "\(league.players.count)/\(league.maxPlayers)")
            StatCard(title: "Format", value: league.format.rawValue)
            StatCard(title: "Skill Level", value: league.skillLevel ?? "All Levels")
        }
    }
}

// MARK: - League Schedule View
private struct LeagueScheduleView: View {
    let schedule: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schedule")
                .font(.headline)
            Text(schedule ?? "Schedule TBD")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - League Next Game View
private struct LeagueNextGameView: View {
    let nextGame: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Game")
                .font(.headline)
            Text(nextGame ?? "TBD")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - League Tags View
private struct LeagueTagsView: View {
    let tags: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Material.ultraThinMaterial)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - League Members View
private struct LeagueMembersView: View {
    let members: [User]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Players")
                .font(.headline)
            
            ForEach(members) { member in
                HStack {
                    Text(member.displayName)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("ELO: \(member.elo)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Material.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - League Matches View
private struct LeagueMatchesView: View {
    let matches: [LeagueMatch]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Matches")
                .font(.headline)
            
            ForEach(matches) { match in
                HStack {
                    VStack(alignment: .leading) {
                        Text("Round \(match.round)")
                            .font(.subheadline)
                        Text("\(match.match.player1.displayName) vs \(match.match.player2.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if match.status == .completed {
                        Text("\(match.match.player1Score) - \(match.match.player2Score)")
                            .font(.subheadline)
                    } else {
                        Text(match.status.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Material.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(Material.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}

// MARK: - Main League Detail View
struct LeagueDetailView: View {
    let league: PickleLeague
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    @State private var showingJoinAlert = false
    @State private var showingStartAlert = false
    
    private var isJoined: Bool {
        guard let currentUser = appState.currentUser else { return false }
        return league.players.contains { $0.id == currentUser.id }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    LeagueImageView(imageUrl: league.imageUrl)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        LeagueHeaderView(league: league)
                        LeagueDescriptionView(description: league.leagueDescription)
                        LeagueStatsView(league: league)
                        LeagueScheduleView(schedule: league.schedule)
                        LeagueNextGameView(nextGame: league.nextGame)
                        LeagueTagsView(tags: league.tags)
                        
                        if !league.matches.isEmpty {
                            LeagueMatchesView(matches: league.matches)
                        }
                        
                        LeagueMembersView(members: league.players)
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !isJoined {
                        Button("Join League") {
                            showingJoinAlert = true
                        }
                        .disabled(league.status != .open)
                    }
                }
            }
            .alert("Join League", isPresented: $showingJoinAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Join") {
                    joinLeague()
                }
            } message: {
                Text("Are you sure you want to join this league?")
            }
        }
    }
    
    private func joinLeague() {
        guard let currentUser = appState.currentUser else { return }
        // Add player to league (this would be handled by your data service)
        league.addPlayer(currentUser)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    LeagueDetailView(league: .preview)
        .modelContainer(for: [PickleLeague.self, User.self])
} 