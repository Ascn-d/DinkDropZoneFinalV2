import SwiftUI
import SwiftData

struct LeaguesHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var leagues: [PickleLeague]
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var selectedSkillLevel: String? = nil
    @State private var selectedDistance: String? = nil
    @State private var showingCreateLeague = false
    @State private var selectedLeague: PickleLeague?
    
    private var filteredLeagues: [PickleLeague] {
        leagues.filter { league in
            let matchesSearch = searchText.isEmpty ||
                league.name.localizedCaseInsensitiveContains(searchText) ||
                league.leagueDescription.localizedCaseInsensitiveContains(searchText)
            
            let matchesSkill = selectedSkillLevel == nil || 
                league.skillLevel == selectedSkillLevel
            
            let matchesDistance = selectedDistance == nil || 
                league.location.localizedCaseInsensitiveContains(selectedDistance ?? "")
            
            return matchesSearch && matchesSkill && matchesDistance
        }
    }
    
    private var totalPlayers: Int {
        leagues.reduce(0) { $0 + $1.players.count }
    }
    
    private var uniqueLocations: Int {
        Set(leagues.map { $0.location }).count
    }
    
    private var averageRating: Double {
        guard !leagues.isEmpty else { return 0.0 }
        let totalRating = leagues.map { $0.rating }.reduce(0, +)
        return totalRating / Double(leagues.count)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pickleball Leagues")
                            .font(.largeTitle.bold())
                        Text("Find and join local pickleball leagues near you")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Search and Filters
                    VStack(spacing: 12) {
                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search leagues...", text: $searchText)
                        }
                        .padding()
                        .background(Material.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                FilterChip(
                                    title: "All Levels",
                                    isSelected: selectedSkillLevel == nil,
                                    action: { selectedSkillLevel = nil }
                                )
                                
                                ForEach(["Beginner", "Intermediate", "Advanced"], id: \.self) { level in
                                    FilterChip(
                                        title: level,
                                        isSelected: selectedSkillLevel == level,
                                        action: { selectedSkillLevel = level }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Quick Stats
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatsCard(title: "Active Leagues", value: "\(leagues.count)")
                        StatsCard(title: "Total Players", value: "\(totalPlayers)")
                        StatsCard(title: "Locations", value: "\(uniqueLocations)")
                        StatsCard(title: "Avg Rating", value: String(format: "%.1f", averageRating))
                    }
                    .padding(.horizontal)
                    
                    // Leagues Grid
                    LazyVGrid(columns: [GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredLeagues) { league in
                            LeagueCard(league: league) {
                                selectedLeague = league
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingCreateLeague = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreateLeague) {
                CreateLeagueWizard()
            }
            .sheet(item: $selectedLeague) { league in
                LeagueDetailView(league: league)
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Material.regular : Material.ultraThinMaterial)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    LeaguesHomeView()
        .modelContainer(for: [PickleLeague.self, User.self])
} 