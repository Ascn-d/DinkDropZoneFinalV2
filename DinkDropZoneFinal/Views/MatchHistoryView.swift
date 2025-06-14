import SwiftUI
import SwiftData

struct MatchHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var matches: [Match]
    @State private var searchText = ""
    @State private var selectedFilter: MatchFilter = .all
    
    enum MatchFilter: String, CaseIterable {
        case all = "All"
        case wins = "Wins"
        case losses = "Losses"
        
        var title: String { rawValue }
    }
    
    var filteredMatches: [Match] {
        let filtered = matches.filter { match in
            if searchText.isEmpty {
                return true
            }
            return match.player1.displayName.lowercased().contains(searchText.lowercased()) || match.player2.displayName.lowercased().contains(searchText.lowercased())
        }
        
        switch selectedFilter {
        case .all:
            return filtered
        case .wins:
            return filtered.filter { $0.winner != nil }
        case .losses:
            return filtered.filter { $0.winner == nil }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(MatchFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                List(filteredMatches) { match in
                    MatchHistoryCard(match: match)
                }
                .searchable(text: $searchText, prompt: "Search matches...")
            }
            .navigationTitle("Match History")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Match.self, configurations: config)
    
    // Create sample users
    let user1 = User(
        email: "player1@example.com",
        password: "password123",
        elo: 1000,
        xp: 0,
        totalMatches: 0,
        wins: 0,
        losses: 0,
        winStreak: 0
    )
    
    let user2 = User(
        email: "player2@example.com",
        password: "password123",
        elo: 1000,
        xp: 0,
        totalMatches: 0,
        wins: 0,
        losses: 0,
        winStreak: 0
    )
    
    container.mainContext.insert(user1)
    container.mainContext.insert(user2)
    
    // Create sample matches
    let match1 = Match(
        player1: user1,
        player2: user2,
        player1Score: 11,
        player2Score: 8,
        winner: user1,
        eloChange: "+10"
    )
    
    let match2 = Match(
        player1: user1,
        player2: user2,
        player1Score: 9,
        player2Score: 11,
        winner: user2,
        eloChange: "-8"
    )
    
    container.mainContext.insert(match1)
    container.mainContext.insert(match2)
    
    return MatchHistoryView()
        .modelContainer(container)
} 
