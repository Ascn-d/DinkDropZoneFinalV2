import SwiftUI

struct TournamentTabView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var selectedTab = 0
    @State private var showingCreateTournament = false
    @State private var searchText = ""
    @State private var showingFilters = false
    @State private var animateContent = false
    @State private var showingRecommendations = true
    
    // Navigation state
    @State private var selectedTournament: Tournament?
    @State private var showingTournamentDetail = false
    
    // Enhanced filtering and search
    @State private var filters = TournamentFilters()
    @State private var searchSuggestions: [String] = []
    @State private var showSearchSuggestions = false
    @FocusState private var isSearchFocused: Bool
    
    private let tabs = ["All", "My Tournaments", "Live", "Featured", "Completed"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced search header
                enhancedSearchHeader
                
                // Recommendations section (when no search)
                if searchText.isEmpty && showingRecommendations && selectedTab == 0 {
                    recommendationsSection
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
                
                // Enhanced tab selector
                enhancedTabSelector
                
                // Main content with enhanced animations
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(currentTournaments.enumerated()), id: \.element.id) { index, tournament in
                            TournamentEnhancedCard(
                                tournament: tournament,
                                onJoin: {
                                    // Handle join action
                                    print("Join tournament: \(tournament.name)")
                                    selectedTournament = tournament
                                    showingTournamentDetail = true
                                },
                                onView: {
                                    navigateToTournament(tournament)
                                }
                            )
                            .scaleEffect(animateContent ? 1.0 : 0.8)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1),
                                value: animateContent
                            )
                        }
                        
                        if currentTournaments.isEmpty && !searchText.isEmpty {
                            emptySearchResultsView
                        } else if currentTournaments.isEmpty {
                            emptyStateView
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Tournaments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.spring()) {
                            showingFilters.toggle()
                        }
                    } label: {
                        Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(.blue)
                            .scaleEffect(hasActiveFilters ? 1.1 : 1.0)
                            .animation(.spring(), value: hasActiveFilters)
                    }
                    
                    Button {
                        withAnimation(.spring()) {
                            showingCreateTournament = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                loadTournamentData()
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    animateContent = true
                }
            }
            .sheet(isPresented: $showingCreateTournament) {
                CreateTournamentWizard()
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingFilters) {
                TournamentFiltersView(filters: $filters)
            }
            .sheet(isPresented: $showingTournamentDetail) {
                if let tournament = selectedTournament {
                    TournamentDetailView(tournament: tournament)
                        .environmentObject(appState)
                }
            }
        }
    }
    
    // MARK: - Enhanced Search Header
    
    private var enhancedSearchHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Search field with suggestions
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .scaleEffect(isSearchFocused ? 1.1 : 1.0)
                            .animation(.spring(), value: isSearchFocused)
                        
                        TextField("Search tournaments, venues, organizers...", text: $searchText)
                            .textFieldStyle(.plain)
                            .focused($isSearchFocused)
                            .onChange(of: isSearchFocused) { _, focused in
                                withAnimation(.spring()) {
                                    showSearchSuggestions = focused && !searchText.isEmpty
                                }
                            }
                            .onChange(of: searchText) { _, newValue in
                                updateSearchSuggestions(for: newValue)
                                showSearchSuggestions = isSearchFocused && !newValue.isEmpty
                            }
                        
                        if !searchText.isEmpty {
                            Button {
                                withAnimation(.spring()) {
                                    searchText = ""
                                    showSearchSuggestions = false
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Search suggestions
                    if showSearchSuggestions && !searchSuggestions.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(searchSuggestions.prefix(5), id: \.self) { suggestion in
                                Button {
                                    searchText = suggestion
                                    showSearchSuggestions = false
                                } label: {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                        
                                        Text(suggestion)
                                            .foregroundColor(.primary)
                                            .font(.subheadline)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                                
                                if suggestion != searchSuggestions.prefix(5).last {
                                    Divider()
                                }
                            }
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSearchFocused ? .blue.opacity(0.5) : .clear,
                            lineWidth: 2
                        )
                        .animation(.spring(), value: isSearchFocused)
                )
            }
            
            // Quick filters
            if !hasActiveFilters {
                quickFiltersView
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommended for You")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Based on your skill level and preferences")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("See All") {
                    // Navigate to recommendations view
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(getRecommendedTournaments().prefix(5), id: \.id) { tournament in
                        TournamentRecommendationCard(tournament: tournament)
                            .onTapGesture {
                                navigateToTournament(tournament)
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Enhanced Tab Selector
    
    private var enhancedTabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    TabSelectorButton(
                        title: tabs[index],
                        isSelected: selectedTab == index,
                        count: getTabCount(for: index)
                    ) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            selectedTab = index
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Quick Filters
    
    private var quickFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                QuickFilterChip(
                    title: "This Week",
                    isSelected: filters.dateRange == .thisWeek
                ) {
                    toggleDateFilter(.thisWeek)
                }
                
                QuickFilterChip(
                    title: "Free Entry",
                    isSelected: filters.isFreeEntry
                ) {
                    filters.isFreeEntry.toggle()
                }
                
                QuickFilterChip(
                    title: "My Skill Level",
                    isSelected: filters.matchesMySkill
                ) {
                    filters.matchesMySkill.toggle()
                }
                
                QuickFilterChip(
                    title: "Nearby",
                    isSelected: filters.isNearby
                ) {
                    filters.isNearby.toggle()
                }
                
                QuickFilterChip(
                    title: "Doubles",
                    isSelected: filters.format == .doubles
                ) {
                    toggleFormatFilter(.doubles)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Empty States
    
    private var emptySearchResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No tournaments found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Button("Clear Filters") {
                withAnimation(.spring()) {
                    clearAllFilters()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "trophy.circle")
                .font(.system(size: 80))
                .foregroundColor(.brown)
            
            VStack(spacing: 12) {
                Text("No Tournaments Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Be the first to create a tournament in your area!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Create Tournament") {
                showingCreateTournament = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
    }
    
    // MARK: - Computed Properties
    
    private var currentTournaments: [Tournament] {
        let filteredTournaments = applyFilters(to: appState.tournaments)
        return applySearch(to: filteredTournaments)
    }
    
    private var hasActiveFilters: Bool {
        filters.hasActiveFilters
    }
    
    // MARK: - Helper Methods
    
    private func loadTournamentData() {
        if appState.tournaments.isEmpty {
            Task {
                await appState.loadTournamentData()
            }
        }
    }
    
    private func navigateToTournament(_ tournament: Tournament) {
        // Navigation logic
        print("Navigating to tournament: \(tournament.name)")
    }
    
    private func applyFilters(to tournaments: [Tournament]) -> [Tournament] {
        return tournaments.filter { tournament in
            // Apply all active filters
            if let dateRange = filters.dateRange {
                if !dateRange.contains(tournament.startDate) {
                    return false
                }
            }
            
            if filters.isFreeEntry && tournament.entryFee > 0 {
                return false
            }
            
            if let format = filters.format {
                if !tournament.format.lowercased().contains(format.rawValue.lowercased()) {
                    return false
                }
            }
            
            if filters.matchesMySkill {
                // Check if tournament matches user's skill level
                // This would be based on user's ELO or rating
                return true // Simplified for now
            }
            
            if filters.isNearby {
                // Check if tournament is nearby based on user location
                return true // Simplified for now
            }
            
            // Tab-based filtering
            switch selectedTab {
            case 1: // My Tournaments
                return appState.myTournaments.contains(tournament)
            case 2: // Live
                return tournament.status == "Live" || tournament.status == "In Progress"
            case 3: // Featured
                return tournament.isFeatured
            case 4: // Completed
                return tournament.status == "Completed"
            default: // All
                return true
            }
        }
    }
    
    private func applySearch(to tournaments: [Tournament]) -> [Tournament] {
        guard !searchText.isEmpty else { return tournaments }
        
        let searchTerm = searchText.lowercased()
        return tournaments.filter { tournament in
            tournament.name.lowercased().contains(searchTerm) ||
            tournament.description.lowercased().contains(searchTerm) ||
            tournament.venueName.lowercased().contains(searchTerm) ||
            tournament.organizerName.lowercased().contains(searchTerm) ||
            tournament.skillLevel.lowercased().contains(searchTerm) ||
            tournament.format.lowercased().contains(searchTerm)
        }
    }
    
    private func updateSearchSuggestions(for searchText: String) {
        guard !searchText.isEmpty else {
            searchSuggestions = []
            showSearchSuggestions = false
            return
        }
        
        let allTournaments = appState.tournaments
        var suggestions: Set<String> = []
        
        // Tournament names
        suggestions.formUnion(
            allTournaments
                .map { $0.name }
                .filter { $0.lowercased().contains(searchText.lowercased()) }
        )
        
        // Venue names
        suggestions.formUnion(
            allTournaments
                .map { $0.venueName }
                .filter { !$0.isEmpty && $0.lowercased().contains(searchText.lowercased()) }
        )
        
        // Organizer names
        suggestions.formUnion(
            allTournaments
                .map { $0.organizerName }
                .filter { !$0.isEmpty && $0.lowercased().contains(searchText.lowercased()) }
        )
        
        searchSuggestions = Array(suggestions).sorted()
        showSearchSuggestions = true
    }
    
    private func getRecommendedTournaments() -> [Tournament] {
        // AI-powered recommendations based on user preferences, ELO, location, etc.
        let userElo = appState.currentUser?.elo ?? 1000
        
        return appState.tournaments.filter { tournament in
            // Recommend tournaments that match user's skill level
            let isSkillMatch = tournament.skillLevel == getSkillLevelForElo(userElo)
            
            // Recommend nearby tournaments (if location available)
            let isNearby = true // Simplified for now
            
            // Recommend tournaments with similar players
            let hasSimilarPlayers = tournament.participants.contains { participant in
                abs(participant.elo - userElo) <= 200
            }
            
            return isSkillMatch || isNearby || hasSimilarPlayers
        }
        .sorted { tournament1, tournament2 in
            // Sort by relevance score
            calculateRelevanceScore(for: tournament1) > calculateRelevanceScore(for: tournament2)
        }
    }
    
    private func getSkillLevelForElo(_ elo: Int) -> String {
        switch elo {
        case ..<1200: return "Beginner"
        case 1200..<1600: return "Intermediate"
        case 1600..<2000: return "Advanced"
        default: return "Pro"
        }
    }
    
    private func calculateRelevanceScore(for tournament: Tournament) -> Double {
        guard let user = appState.currentUser else { return 0 }
        
        var score = 0.0
        
        // Skill level match
        if tournament.skillLevel == getSkillLevelForElo(user.elo) {
            score += 50
        }
        
        // Registration status
        if tournament.status == "Registration Open" {
            score += 30
        }
        
        // Recency
        let daysUntilStart = Calendar.current.dateComponents([.day], from: Date(), to: tournament.startDate).day ?? 0
        if daysUntilStart <= 7 {
            score += 20
        }
        
        // Similar participants
        let similarParticipants = tournament.participants.filter { participant in
            abs(participant.elo - user.elo) <= 200
        }.count
        score += Double(similarParticipants) * 5
        
        return score
    }
    
    private func getTabCount(for index: Int) -> Int? {
        switch index {
        case 1: return appState.myTournaments.count
        case 2: return appState.tournaments.filter { $0.status == "Live" || $0.status == "In Progress" }.count
        case 3: return appState.tournaments.filter { $0.isFeatured }.count
        case 4: return appState.tournaments.filter { $0.status == "Completed" }.count
        default: return nil
        }
    }
    
    private func toggleDateFilter(_ dateRange: TournamentDateRange) {
        if filters.dateRange == dateRange {
            filters.dateRange = nil
        } else {
            filters.dateRange = dateRange
        }
    }
    
    private func toggleFormatFilter(_ format: TournamentFormat) {
        if filters.format == format {
            filters.format = nil
        } else {
            filters.format = format
        }
    }
    
    private func clearAllFilters() {
        filters = TournamentFilters()
        searchText = ""
    }
}

// MARK: - Supporting Views

struct TabSelectorButton: View {
    let title: String
    let isSelected: Bool
    let count: Int?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue)
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .blue : .secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? .blue.opacity(0.1) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct QuickFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? .blue : .blue.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
    }
}

struct TournamentRecommendationCard: View {
    let tournament: Tournament
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                Text(tournament.format)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                TournamentStatusBadge(status: tournament.status)
            }
        }
        .padding(16)
        .frame(width: 160, height: 120)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct TournamentStatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch status {
        case "Registration Open": return .green
        case "Registration Closed": return .orange
        case "In Progress", "Live": return .red
        case "Completed": return .gray
        default: return .gray
        }
    }
}

// MARK: - Supporting Models

struct TournamentFilters {
    var dateRange: TournamentDateRange?
    var format: TournamentFormat?
    var isFreeEntry: Bool = false
    var matchesMySkill: Bool = false
    var isNearby: Bool = false
    
    var hasActiveFilters: Bool {
        dateRange != nil || format != nil || isFreeEntry || matchesMySkill || isNearby
    }
}

enum TournamentDateRange: CaseIterable {
    case today, thisWeek, thisMonth, nextMonth
    
    var title: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .nextMonth: return "Next Month"
        }
    }
    
    func contains(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .today:
            return calendar.isDate(date, inSameDayAs: now)
        case .thisWeek:
            return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        case .thisMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .nextMonth:
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: now) ?? now
            return calendar.isDate(date, equalTo: nextMonth, toGranularity: .month)
        }
    }
}

// Placeholder for the filters view
struct TournamentFiltersView: View {
    @Binding var filters: TournamentFilters
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Advanced Filters")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Filter options would go here
                Text("Coming soon...")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TournamentTabView()
        .environmentObject(AppState())
} 