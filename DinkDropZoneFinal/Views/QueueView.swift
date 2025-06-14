import SwiftUI
import SwiftData

struct QueueView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    @Query private var users: [User]
    @State private var isInQueue = false
    @State private var queuePosition = 0
    @State private var estimatedWaitTime = 0
    @State private var selectedMatchType: MatchType = .singles
    @State private var selectedUser: User?
    @State private var showingMatchSetup = false
    @State private var showingTournamentDetails = false
    @State private var showingCourtBooking = false
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Queue Status Section (if in queue)
                    if isInQueue {
                        queueStatusSection
                    }
                    
                    // Quick Match Options
                    quickMatchSection
                    
                    // Live Activity & Nearby Players
                    liveActivitySection
                    
                    // Court Availability
                    courtAvailabilitySection
                    
                    // Current Tournaments
                    tournamentsSection
                    
                    // Practice Partners
                    practicePartnersSection
                    
                    // Weather & Conditions
                    weatherConditionsSection
                    
                    // Recent Activity & Quick Rematch
                    recentActivitySection
                }
                .padding()
            }
            .navigationTitle("Play Hub")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            refreshData()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                        
                        Button {
                            showingCourtBooking = true
                        } label: {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .onAppear {
                startRefreshTimer()
            }
            .onDisappear {
                stopRefreshTimer()
            }
            .sheet(isPresented: $showingMatchSetup) {
                if let user = selectedUser {
                    MatchSetupView(opponent: user) { result in
                        handleMatchResult(result)
                    }
                }
            }
            .sheet(isPresented: $showingTournamentDetails) {
                TournamentDetailsView()
            }
            .sheet(isPresented: $showingCourtBooking) {
                CourtBookingView()
            }
        }
    }
    
    // MARK: - Queue Status Section
    
    private var queueStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "timer")
                    .foregroundColor(.blue)
                Text("In Queue")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button("Leave Queue") {
                    leaveQueue()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("\(queuePosition)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Position")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(estimatedWaitTime)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text(selectedMatchType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(selectedMatchType.color)
                    Text("Match Type")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Queue Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text("Finding your match...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Cancel anytime")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                ProgressView()
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Quick Match Section
    
    private var quickMatchSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Match")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(MatchType.allCases, id: \.self) { matchType in
                    QuickMatchCard(
                        matchType: matchType,
                        playerCount: getPlayerCountForMatchType(matchType),
                        averageWaitTime: getAverageWaitTime(matchType),
                        isSelected: selectedMatchType == matchType
                    ) {
                        selectedMatchType = matchType
                        if !isInQueue {
                            joinQueue(matchType: matchType)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Live Activity Section
    
    private var liveActivitySection: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    Text("Live Activity")
                        .font(.headline)
                        .fontWeight(.bold)
                }
                Spacer()
                Text("\(getNearbyPlayersCount()) players nearby")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Nearby Players
                    ForEach(getNearbyPlayers()) { player in
                        NearbyPlayerCard(player: player) {
                            selectedUser = player
                            showingMatchSetup = true
                        }
                    }
                    
                    // Add more players card
                    Button {
                        // TODO: Show all nearby players
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 60, height: 60)
                                
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                            
                            Text("View All")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Live Matches Feed
            VStack(alignment: .leading, spacing: 8) {
                Text("🏓 Live Matches")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ForEach(getLiveMatches()) { match in
                    LiveMatchCard(match: match)
                }
            }
        }
    }
    
    // MARK: - Court Availability Section
    
    private var courtAvailabilitySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Court Availability")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button("Book Court") {
                    showingCourtBooking = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                ForEach(getNearbyCourts()) { court in
                    CourtAvailabilityCard(court: court) {
                        showingCourtBooking = true
                    }
                }
            }
        }
    }
    
    // MARK: - Tournaments Section
    
    private var tournamentsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Active Tournaments")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button("View All") {
                    showingTournamentDetails = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(getActiveTournaments()) { tournament in
                        TournamentCard(tournament: tournament) {
                            showingTournamentDetails = true
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Practice Partners Section
    
    private var practicePartnersSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Practice Partners")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("Find skill-matched partners")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(getPracticePartners()) { partner in
                    PracticePartnerCard(partner: partner) {
                        selectedUser = partner
                        selectedMatchType = .practice
                        showingMatchSetup = true
                    }
                }
            }
        }
    }
    
    // MARK: - Weather Conditions Section
    
    private var weatherConditionsSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weather & Conditions")
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.orange)
                        Text("72°F")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "wind")
                            .foregroundColor(.blue)
                        Text("5 mph")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                            .foregroundColor(.blue)
                        Text("0%")
                            .font(.subheadline)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Perfect conditions!")
                    .font(.caption)
                    .foregroundColor(.green)
                    .fontWeight(.medium)
                
                Text("Great day for pickleball")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
        )
    }
    
    // MARK: - Recent Activity Section
    
    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("Quick rematch")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(getRecentMatches()) { match in
                    QueueRecentMatchCard(match: match) {
                        // TODO: Setup rematch
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func joinQueue(matchType: MatchType) {
        withAnimation {
            isInQueue = true
            queuePosition = Int.random(in: 1...10)
            estimatedWaitTime = Int.random(in: 2...8)
            selectedMatchType = matchType
        }
    }
    
    private func leaveQueue() {
        withAnimation {
            isInQueue = false
            queuePosition = 0
            estimatedWaitTime = 0
        }
    }
    
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            refreshData()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func refreshData() {
        // Simulate data refresh
        if isInQueue && queuePosition > 1 {
            queuePosition = max(1, queuePosition - 1)
            estimatedWaitTime = max(1, estimatedWaitTime - 1)
        }
    }
    
    private func handleMatchResult(_ result: Result<Match, Error>) {
        switch result {
        case .success(_):
            // Handle successful match creation
            leaveQueue()
        case .failure(let error):
            // Handle error
            print("Match creation error: \(error)")
        }
    }
    
    // MARK: - Data Methods
    
    private func getPlayerCountForMatchType(_ matchType: MatchType) -> Int {
        switch matchType {
        case .singles: return Int.random(in: 15...25)
        case .doubles: return Int.random(in: 8...18)
        case .practice: return Int.random(in: 5...12)
        case .tournament: return Int.random(in: 20...35)
        case .casual: return Int.random(in: 10...20)
        case .competitive: return Int.random(in: 12...22)
        case .league: return Int.random(in: 8...16)
        }
    }
    
    private func getAverageWaitTime(_ matchType: MatchType) -> Int {
        switch matchType {
        case .singles: return Int.random(in: 2...5)
        case .doubles: return Int.random(in: 3...7)
        case .practice: return Int.random(in: 1...3)
        case .tournament: return Int.random(in: 5...10)
        case .casual: return Int.random(in: 2...4)
        case .competitive: return Int.random(in: 3...6)
        case .league: return Int.random(in: 4...8)
        }
    }
    
    private func getNearbyPlayersCount() -> Int {
        return Int.random(in: 8...15)
    }
    
    private func getNearbyPlayers() -> [User] {
        return Array(users.prefix(4))
    }
    
    private func getLiveMatches() -> [LiveMatch] {
        return [
            LiveMatch(id: "1", player1: "Sarah C.", player2: "Mike J.", court: "Court 1", timeElapsed: "12 min"),
            LiveMatch(id: "2", player1: "Emma W.", player2: "Alex T.", court: "Court 3", timeElapsed: "25 min")
        ]
    }
    
    private func getNearbyCourts() -> [CourtAvailability] {
        return [
            CourtAvailability(id: "1", name: "Golden Gate Park", distance: "0.8 mi", status: .available, courts: 3),
            CourtAvailability(id: "2", name: "Mission Dolores", distance: "1.2 mi", status: .busy, courts: 2)
        ]
    }
    
    private func getActiveTournaments() -> [QueueTournament] {
        return [
            QueueTournament(id: "1", name: "Friday Night Lights", participants: 16, maxParticipants: 32, startTime: "7:00 PM"),
            QueueTournament(id: "2", name: "Weekend Warriors", participants: 8, maxParticipants: 16, startTime: "9:00 AM")
        ]
    }
    
    private func getPracticePartners() -> [User] {
        return Array(users.prefix(2))
    }
    
    private func getRecentMatches() -> [QueueRecentMatch] {
        return [
            QueueRecentMatch(id: "1", opponent: "Sarah Chen", result: "Win", score: "11-8", date: "2 hours ago"),
            QueueRecentMatch(id: "2", opponent: "Mike Johnson", result: "Loss", score: "9-11", date: "Yesterday")
        ]
    }
}

// MARK: - Supporting Views

struct QuickMatchCard: View {
    let matchType: MatchType
    let playerCount: Int
    let averageWaitTime: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [matchType.color, matchType.color.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: matchType.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text(matchType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(playerCount) players")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("~\(averageWaitTime) min wait")
                        .font(.caption2)
                        .foregroundColor(matchType.color)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? matchType.color.opacity(0.1) : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? matchType.color.opacity(0.5) : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NearbyPlayerCard: View {
    let player: User
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Text(String(player.displayName.isEmpty ? player.email.prefix(1) : player.displayName.prefix(1)))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    // Online indicator
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 18, y: -18)
                }
                
                VStack(spacing: 2) {
                    Text(player.displayName.isEmpty ? "Player" : player.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("\(player.elo) ELO")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Models

struct LiveMatch: Identifiable {
    let id: String
    let player1: String
    let player2: String
    let court: String
    let timeElapsed: String
}

struct CourtAvailability: Identifiable {
    let id: String
    let name: String
    let distance: String
    let status: Status
    let courts: Int
    
    enum Status {
        case available, busy, full
        
        var color: Color {
            switch self {
            case .available: return .green
            case .busy: return .orange
            case .full: return .red
            }
        }
        
        var text: String {
            switch self {
            case .available: return "Available"
            case .busy: return "Busy"
            case .full: return "Full"
            }
        }
    }
}

struct QueueTournament: Identifiable {
    let id: String
    let name: String
    let participants: Int
    let maxParticipants: Int
    let startTime: String
}

struct QueueRecentMatch: Identifiable {
    let id: String
    let opponent: String
    let result: String
    let score: String
    let date: String
}

// MARK: - Additional Supporting Views (Placeholder implementations)

struct LiveMatchCard: View {
    let match: LiveMatch
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(match.player1) vs \(match.player2)")
                    .font(.caption)
                    .fontWeight(.medium)
                Text(match.court)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(match.timeElapsed)
                .font(.caption2)
                .foregroundColor(.green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(6)
    }
}

struct CourtAvailabilityCard: View {
    let court: CourtAvailability
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(court.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Text(court.distance)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(court.courts) courts")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Text(court.status.text)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(court.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(court.status.color.opacity(0.2))
                    )
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TournamentCard: View {
    let tournament: QueueTournament
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(tournament.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                Text("\(tournament.participants)/\(tournament.maxParticipants)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(tournament.startTime)
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
            }
            .padding()
            .frame(width: 100, height: 80)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PracticePartnerCard: View {
    let partner: User
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(partner.displayName.isEmpty ? partner.email.prefix(1) : partner.displayName.prefix(1)))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(partner.displayName.isEmpty ? "Practice Partner" : partner.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("\(partner.elo) ELO")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("Available now")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QueueRecentMatchCard: View {
    let match: QueueRecentMatch
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("vs \(match.opponent)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(match.date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(match.result)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(match.result == "Win" ? .green : .red)
                    
                    Text(match.score)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Placeholder Views

struct TournamentDetailsView: View {
    var body: some View {
        Text("Tournament Details")
    }
}

struct CourtBookingView: View {
    var body: some View {
        Text("Court Booking")
    }
}

// MARK: - Original Views (kept for compatibility)

struct MatchSetupView: View {
    let opponent: User
    let onComplete: (Result<Match, Error>) -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var player1Score = 0
    @State private var player2Score = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Score") {
                    Stepper("Your Score: \(player1Score)", value: $player1Score, in: 0...21)
                    Stepper("Opponent Score: \(player2Score)", value: $player2Score, in: 0...21)
                }
                
                Section {
                    Button("Create Match") {
                        createMatch()
                    }
                    .disabled(player1Score == 0 && player2Score == 0)
                }
            }
            .navigationTitle("New Match")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createMatch() {
        do {
            // Get current user from model context
            let descriptor = FetchDescriptor<User>()
            guard let currentUser = try modelContext.fetch(descriptor).first else {
                onComplete(.failure(AuthError.unknown))
                return
            }
            
            // Determine winner and ELO change
            let winner: User?
            let eloChange: String
            
            if player1Score > player2Score {
                winner = currentUser
                eloChange = "+10"
            } else if player2Score > player1Score {
                winner = opponent
                eloChange = "-8"
            } else {
                winner = nil
                eloChange = "0"
            }
            
            // Create match
            let match = Match(
                player1: currentUser,
                player2: opponent,
                player1Score: player1Score,
                player2Score: player2Score,
                winner: winner,
                eloChange: eloChange
            )
            
            modelContext.insert(match)
            try modelContext.save()
            
            onComplete(.success(match))
            dismiss()
        } catch {
            onComplete(.failure(error))
        }
    }
}

#Preview {
    PreviewHelper.queueViewPreview()
}

@MainActor
private struct PreviewHelper {
    static func queueViewPreview() -> some View {
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
        
        return QueueView()
            .modelContainer(container)
        .environment(AppState())
    }
} 