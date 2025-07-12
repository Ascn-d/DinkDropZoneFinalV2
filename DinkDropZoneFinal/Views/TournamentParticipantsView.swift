import SwiftUI

/// Comprehensive view for displaying tournament participants with real-time updates
struct TournamentParticipantsView: View {
    let tournament: Tournament
    @StateObject private var tournamentService = TournamentService(firebaseService: FirebaseService.shared)
    @EnvironmentObject var appState: AppState
    
    @State private var participants: [TournamentParticipant] = []
    @State private var isLoading = true
    @State private var selectedParticipant: TournamentParticipant?
    @State private var showingPlayerProfile = false
    @State private var searchText = ""
    @State private var selectedFilter: ParticipantFilter = .all
    @State private var sortOption: ParticipantSort = .name
    @State private var refreshTimer: Timer?
    @State private var errorMessage: String?
    @State private var showingError = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationTitle("Participants")
                .navigationBarTitleDisplayMode(.large)
                .background(DS.Color.background)
                .toolbar {
                    leadingToolbarItem
                    trailingToolbarItem
                }
        }
        .sheet(isPresented: $showingPlayerProfile) {
            playerProfileSheet
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            loadParticipants()
            startRealtimeUpdates()
        }
        .onDisappear {
            stopRealtimeUpdates()
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        if isLoading {
            AnyView(loadingView)
        } else {
            AnyView(contentView)
        }
    }
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // Tournament header
            tournamentHeaderSection
            
            // Search and filters
            searchAndFilterSection
            
            // Participants list
            participantsListSection
        }
    }
    
    // MARK: - Toolbar Items
    private var leadingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Done") {
                dismiss()
            }
            .foregroundColor(DS.Color.accent)
        }
    }
    
    private var trailingToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            sortMenu
        }
    }
    
    private var sortMenu: some View {
        Menu {
            Section("Sort By") {
                ForEach(ParticipantSort.allCases, id: \.self) { sort in
                    Button {
                        withAnimation(DS.Animation.gentle) {
                            sortOption = sort
                        }
                    } label: {
                        HStack {
                            Text(sort.title)
                            if sortOption == sort {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundColor(DS.Color.accent)
        }
    }
    
    // MARK: - Sheet Content
    private var playerProfileSheet: some View {
        Group {
            if let participant = selectedParticipant {
                PlayerProfileSheet(participant: participant, tournament: tournament)
                    .environmentObject(appState)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(DS.Color.accent)
            
            VStack(spacing: 8) {
                Text("Loading Participants")
                    .font(DS.Font.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DS.Color.primary)
                
                Text("Please wait while we fetch the tournament participants...")
                    .font(DS.Font.body)
                    .foregroundColor(DS.Color.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.Color.background)
    }
    
    // MARK: - Tournament Header Section
    private var tournamentHeaderSection: some View {
        VStack(spacing: DS.Layout.itemSpacing) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.name)
                        .font(DS.Font.title2)
                        .fontWeight(.bold)
                        .foregroundColor(DS.Color.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 16) {
                        Label(tournament.format, systemImage: formatIcon)
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                        
                        Label(tournament.type, systemImage: "trophy")
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                    }
                }
                
                Spacer()
                
                // Participation stats
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(participants.count)")
                        .font(DS.Font.title)
                        .fontWeight(.bold)
                        .foregroundColor(DS.Color.accent)
                    
                    Text("of \(tournament.maxParticipants)")
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.secondary)
                    
                    Text("participants")
                        .font(DS.Font.caption2)
                        .foregroundColor(DS.Color.secondary)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Color.divider.opacity(0.3))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(progressGradient)
                        .frame(width: geometry.size.width * progressPercentage, height: 8)
                        .animation(DS.Animation.smooth, value: progressPercentage)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, DS.Layout.horizontalPadding)
        .padding(.vertical, DS.Layout.cardPadding)
        .background(DS.Color.surface)
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: DS.Layout.itemSpacing) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DS.Color.secondary)
                
                TextField("Search participants...", text: $searchText)
                    .font(DS.Font.body)
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DS.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                    .stroke(DS.Color.divider.opacity(0.3), lineWidth: 1)
            )
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(ParticipantFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.title,
                            count: getFilterCount(filter),
                            isSelected: selectedFilter == filter
                        ) {
                            withAnimation(DS.Animation.gentle) {
                                selectedFilter = filter
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Layout.horizontalPadding)
            }
        }
        .padding(.horizontal, DS.Layout.horizontalPadding)
        .padding(.vertical, DS.Layout.verticalPadding)
    }
    
    // MARK: - Participants List Section
    private var participantsListSection: some View {
        ScrollView {
            LazyVStack(spacing: DS.Layout.cardSpacing) {
                ForEach(filteredAndSortedParticipants, id: \.id) { participant in
                    ParticipantCard(
                        participant: participant,
                        tournament: tournament,
                        isCurrentUser: isCurrentUser(participant)
                    ) {
                        selectedParticipant = participant
                        showingPlayerProfile = true
                    }
                    .padding(.horizontal, DS.Layout.horizontalPadding)
                }
                
                if filteredAndSortedParticipants.isEmpty && !isLoading {
                    EmptyParticipantsView(filter: selectedFilter, searchText: searchText)
                        .padding(.top, 60)
                }
            }
            .padding(.vertical, DS.Layout.verticalPadding)
        }
    }
    
    // MARK: - Computed Properties
    private var formatIcon: String {
        switch tournament.format.lowercased() {
        case "singles":
            return "person.circle"
        case "doubles":
            return "person.2.circle"
        case "mixed doubles":
            return "person.2.fill"
        default:
            return "gamecontroller"
        }
    }
    
    private var progressPercentage: Double {
        guard tournament.maxParticipants > 0 else { return 0 }
        return Double(participants.count) / Double(tournament.maxParticipants)
    }
    
    private var progressGradient: LinearGradient {
        let percentage = progressPercentage
        if percentage >= 1.0 {
            return DS.Color.successGradient
        } else if percentage >= 0.8 {
            return DS.Color.warningGradient
        } else {
            return DS.Color.accentGradient
        }
    }
    
    private var filteredAndSortedParticipants: [TournamentParticipant] {
        let filtered = filteredParticipants
        
        switch sortOption {
        case .name:
            return filtered.sorted { $0.displayName < $1.displayName }
        case .elo:
            return filtered.sorted { $0.elo > $1.elo }
        case .status:
            return filtered.sorted { $0.status < $1.status }
        case .wins:
            return filtered.sorted { $0.wins > $1.wins }
        case .joinDate:
            return filtered // Would need join date in model
        }
    }
    
    private var filteredParticipants: [TournamentParticipant] {
        let baseFiltered: [TournamentParticipant]
        
        switch selectedFilter {
        case .all:
            baseFiltered = participants
        case .active:
            baseFiltered = participants.filter { !$0.isEliminated }
        case .eliminated:
            baseFiltered = participants.filter { $0.isEliminated }
        case .teams:
            baseFiltered = participants.filter { $0.partnerID != nil }
        case .solos:
            baseFiltered = participants.filter { $0.partnerID == nil }
        }
        
        if searchText.isEmpty {
            return baseFiltered
        } else {
            return baseFiltered.filter { participant in
                participant.displayName.localizedCaseInsensitiveContains(searchText) ||
                participant.teamName?.localizedCaseInsensitiveContains(searchText) == true ||
                participant.partnerName?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    private func getFilterCount(_ filter: ParticipantFilter) -> Int {
        switch filter {
        case .all:
            return participants.count
        case .active:
            return participants.filter { !$0.isEliminated }.count
        case .eliminated:
            return participants.filter { $0.isEliminated }.count
        case .teams:
            return participants.filter { $0.partnerID != nil }.count
        case .solos:
            return participants.filter { $0.partnerID == nil }.count
        }
    }
    
    private func isCurrentUser(_ participant: TournamentParticipant) -> Bool {
        return appState.currentUser?.id.uuidString == participant.userID
    }
    
    // MARK: - Data Loading
    private func loadParticipants() {
        participants = tournament.participants
        isLoading = false
    }
    
    private func refreshParticipants() async {
        do {
            let updatedTournament = try await tournamentService.getTournament(id: tournament.id.uuidString)
            
            await MainActor.run {
                withAnimation(DS.Animation.gentle) {
                    participants = updatedTournament.participants
                }
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to refresh participants: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    // MARK: - Real-time Updates
    private func startRealtimeUpdates() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { _ in
            Task {
                await refreshParticipants()
            }
        }
    }
    
    private func stopRealtimeUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - Supporting Enums
enum ParticipantFilter: String, CaseIterable {
    case all = "All"
    case active = "Active"
    case eliminated = "Eliminated" 
    case teams = "Teams"
    case solos = "Solo"
    
    var title: String { rawValue }
}

enum ParticipantSort: String, CaseIterable {
    case name = "Name"
    case elo = "ELO"
    case status = "Status"
    case wins = "Wins"
    case joinDate = "Join Date"
    
    var title: String { rawValue }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(DS.Font.caption)
                    .fontWeight(.medium)
                
                if count > 0 {
                    Text("\(count)")
                        .font(DS.Font.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Circle()
                                .fill(isSelected ? .white.opacity(0.3) : DS.Color.accent.opacity(0.2))
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? DS.Color.accent : DS.Color.surface)
            )
            .foregroundColor(isSelected ? .white : DS.Color.primary)
            .overlay(
                Capsule()
                    .stroke(isSelected ? DS.Color.accent : DS.Color.divider.opacity(0.3), lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(DS.Animation.gentle, value: isSelected)
    }
}

// MARK: - Participant Card Component
struct ParticipantCard: View {
    let participant: TournamentParticipant
    let tournament: Tournament
    let isCurrentUser: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DS.Layout.itemSpacing) {
                // Profile avatar placeholder
                ZStack {
                    Circle()
                        .fill(avatarGradient)
                        .frame(width: 50, height: 50)
                    
                    Text(participant.displayName.prefix(2).uppercased())
                        .font(DS.Font.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .overlay(
                    Circle()
                        .stroke(isCurrentUser ? DS.Color.accent : .clear, lineWidth: 3)
                        .frame(width: 54, height: 54)
                )
                
                // Participant info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(participant.displayName)
                            .font(DS.Font.body)
                            .fontWeight(.semibold)
                            .foregroundColor(DS.Color.primary)
                        
                        if isCurrentUser {
                            Text("(You)")
                                .font(DS.Font.caption)
                                .foregroundColor(DS.Color.accent)
                        }
                    }
                    
                    if let teamName = participant.teamName, !teamName.isEmpty {
                        Text(teamName)
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.accent)
                    } else if let partnerName = participant.partnerName {
                        Text("Partner: \(partnerName)")
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                    }
                    
                    // Stats row
                    HStack(spacing: 12) {
                        ParticipantStatBadge(label: "ELO", value: "\(participant.elo)", color: .blue)
                        
                        if tournament.status == "In Progress" || tournament.status == "Completed" {
                            ParticipantStatBadge(label: "W", value: "\(participant.wins)", color: .green)
                            ParticipantStatBadge(label: "L", value: "\(participant.losses)", color: .red)
                        }
                    }
                }
                
                Spacer()
                
                // Status and placement
                VStack(alignment: .trailing, spacing: 4) {
                    ParticipantStatusBadge(status: participant.status, isEliminated: participant.isEliminated)
                    
                    if let placement = participant.placement {
                        PlacementBadge(placement: placement)
                    }
                }
            }
            .padding(DS.Layout.cardPadding)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                .fill(cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? DS.Layout.pressScale : 1.0)
        .animation(DS.Animation.buttonPress, value: isPressed)
        .onLongPressGesture(minimumDuration: 0) {
            // Empty
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
    
    private var avatarGradient: LinearGradient {
        let colors: [Color] = [.blue, .purple, .green, .orange, .red, .pink]
        let index = abs(participant.displayName.hash) % colors.count
        let color = colors[index]
        return LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    
    private var cardBackground: Color {
        if isCurrentUser {
            return DS.Color.accent.opacity(0.05)
        } else if participant.isEliminated {
            return DS.Color.surface.opacity(0.5)
        } else {
            return DS.Color.surface
        }
    }
    
    private var cardBorder: Color {
        if isCurrentUser {
            return DS.Color.accent.opacity(0.2)
        } else {
            return DS.Color.divider.opacity(0.1)
        }
    }
}

// MARK: - Supporting Badge Components
struct ParticipantStatBadge: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(DS.Font.caption2)
                .foregroundColor(color)
            
            Text(value)
                .font(DS.Font.caption2)
                .fontWeight(.semibold)
                .foregroundColor(DS.Color.primary)
        }
    }
}

struct ParticipantStatusBadge: View {
    let status: String
    let isEliminated: Bool
    
    var body: some View {
        Text(displayStatus)
            .font(DS.Font.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(backgroundColor.opacity(0.2))
            )
            .foregroundColor(backgroundColor)
    }
    
    private var displayStatus: String {
        if isEliminated {
            return "Eliminated"
        }
        return status
    }
    
    private var backgroundColor: Color {
        if isEliminated {
            return .red
        }
        
        switch status {
        case "Registered":
            return .green
        case "Active":
            return .blue
        case "Waiting":
            return .orange
        default:
            return .gray
        }
    }
}

struct PlacementBadge: View {
    let placement: Int
    
    var body: some View {
        Text(placementText)
            .font(DS.Font.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(placementColor.opacity(0.2))
            )
            .foregroundColor(placementColor)
    }
    
    private var placementText: String {
        switch placement {
        case 1: return "🥇 1st"
        case 2: return "🥈 2nd"
        case 3: return "🥉 3rd"
        default: return "#\(placement)"
        }
    }
    
    private var placementColor: Color {
        switch placement {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }
}

// MARK: - Empty Participants View
struct EmptyParticipantsView: View {
    let filter: ParticipantFilter
    let searchText: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 48))
                .foregroundColor(DS.Color.secondary)
            
            VStack(spacing: 8) {
                Text(emptyTitle)
                    .font(DS.Font.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(DS.Color.primary)
                
                Text(emptySubtitle)
                    .font(DS.Font.body)
                    .foregroundColor(DS.Color.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
    
    private var emptyTitle: String {
        if !searchText.isEmpty {
            return "No Results Found"
        }
        
        switch filter {
        case .all:
            return "No Participants"
        case .active:
            return "No Active Participants"
        case .eliminated:
            return "No Eliminated Participants"
        case .teams:
            return "No Teams"
        case .solos:
            return "No Solo Players"
        }
    }
    
    private var emptySubtitle: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms"
        }
        
        switch filter {
        case .all:
            return "Participants will appear here once they join the tournament"
        case .active:
            return "All participants have been eliminated"
        case .eliminated:
            return "No participants have been eliminated yet"
        case .teams:
            return "No team partnerships have been formed"
        case .solos:
            return "All participants are part of teams"
        }
    }
}

// MARK: - Player Profile Sheet
struct PlayerProfileSheet: View {
    let participant: TournamentParticipant
    let tournament: Tournament
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DS.Layout.sectionSpacing) {
                    // Profile header
                    profileHeader
                    
                    // Tournament stats
                    tournamentStats
                    
                    // Match history (if available)
                    matchHistory
                }
                .padding(DS.Layout.horizontalPadding)
            }
            .navigationTitle("Player Profile")
            .navigationBarTitleDisplayMode(.large)
            .background(DS.Color.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DS.Color.accent)
                }
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: DS.Layout.itemSpacing) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Text(participant.displayName.prefix(2).uppercased())
                    .font(DS.Font.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Name and team info
            VStack(spacing: 4) {
                Text(participant.displayName)
                    .font(DS.Font.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DS.Color.primary)
                
                if let teamName = participant.teamName {
                    Text(teamName)
                        .font(DS.Font.subheadline)
                        .foregroundColor(DS.Color.accent)
                } else if let partnerName = participant.partnerName {
                    Text("Partner: \(partnerName)")
                        .font(DS.Font.subheadline)
                        .foregroundColor(DS.Color.secondary)
                }
            }
        }
        .padding(DS.Layout.cardPadding)
        .background(DS.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
    }
    
    private var tournamentStats: some View {
        VStack(alignment: .leading, spacing: DS.Layout.itemSpacing) {
            Text("Tournament Stats")
                .font(DS.Font.title3)
                .fontWeight(.bold)
                .foregroundColor(DS.Color.primary)
            
            HStack(spacing: DS.Layout.itemSpacing) {
                StatCard(title: "ELO", value: "\(participant.elo)", color: .blue)
                StatCard(title: "Wins", value: "\(participant.wins)", color: .green)
                StatCard(title: "Losses", value: "\(participant.losses)", color: .red)
                
                if let placement = participant.placement {
                    StatCard(title: "Place", value: "#\(placement)", color: .orange)
                }
            }
        }
    }
    
    private var matchHistory: some View {
        VStack(alignment: .leading, spacing: DS.Layout.itemSpacing) {
            Text("Recent Matches")
                .font(DS.Font.title3)
                .fontWeight(.bold)
                .foregroundColor(DS.Color.primary)
            
            // This would show recent matches for this participant
            Text("Match history would be displayed here")
                .font(DS.Font.body)
                .foregroundColor(DS.Color.secondary)
                .padding(DS.Layout.cardPadding)
                .background(DS.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
        }
    }
}

#Preview {
    let sampleTournament = Tournament(
        name: "Summer Championship 2024",
        description: "Annual summer tournament",
        format: "Doubles",
        skillLevel: "Intermediate",
        maxParticipants: 32,
        startDate: Date(),
        organizerID: "organizer123",
        organizerName: "Tournament Director"
    )
    
    return TournamentParticipantsView(tournament: sampleTournament)
        .environmentObject({
            let appState = AppState()
            return appState
        }())
}

 