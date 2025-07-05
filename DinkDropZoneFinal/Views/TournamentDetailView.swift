import SwiftUI
import SwiftData

// MARK: - Notification Names

extension Notification.Name {
    static let tournamentUpdated = Notification.Name("tournamentUpdated")
    static let bracketUpdated = Notification.Name("bracketUpdated")
}

struct TournamentDetailView: View {
    let tournament: Tournament
    let tournamentService: TournamentService?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var userStatus: UserTournamentStatus = .notRegistered
    @State private var showBracket = false
    @State private var showMatchView = false
    @State private var currentMatch: TournamentMatch?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var refreshTimer: Timer?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Tournament Header
                    tournamentHeader
                    
                    // User Status Section
                    userStatusSection
                    
                    // Action Buttons
                    actionButtons
                    
                    // Tournament Info
                    tournamentInfo
                    
                    // Participants Section
                    participantsSection
                    
                    // Ready Matches Section
                    if tournament.status == "In Progress" {
                        readyMatchesSection
                    }
                }
                .padding()
            }
            .navigationTitle(tournament.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Bracket") {
                        showBracket = true
                    }
                    .disabled(tournament.matches.isEmpty)
                }
            }
            .sheet(isPresented: $showBracket) {
                TournamentBracketView(tournament: tournament)
            }
            .sheet(isPresented: $showMatchView) {
                if let match = currentMatch {
                    TournamentMatchView(match: match, tournament: tournament, tournamentService: tournamentService)
                }
            }
            .onAppear {
                updateUserStatus()
                startRefreshTimer()
            }
            .onDisappear {
                stopRefreshTimer()
            }
            .onReceive(NotificationCenter.default.publisher(for: .tournamentUpdated)) { notification in
                if let updatedTournament = notification.object as? Tournament,
                   updatedTournament.id == tournament.id {
                    updateUserStatus()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .bracketUpdated)) { notification in
                if let updatedTournament = notification.object as? Tournament,
                   updatedTournament.id == tournament.id {
                    updateUserStatus()
                }
            }
        }
    }
    
    // MARK: - Tournament Header
    
    private var tournamentHeader: some View {
        VStack(spacing: 16) {
            Text(tournament.name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            HStack {
                statusBadge
                Spacer()
                Text(tournament.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !tournament.description.isEmpty {
                Text(tournament.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var statusBadge: some View {
        Text(tournament.status)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.2))
            )
            .foregroundColor(statusColor)
    }
    
    private var statusColor: Color {
        switch tournament.status {
        case "Upcoming": return .blue
        case "Registration Open": return .green
        case "Registration Closed": return .orange
        case "In Progress": return .purple
        case "Completed": return .gray
        case "Cancelled": return .red
        default: return .gray
        }
    }
    
    // MARK: - User Status Section
    
    private var userStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(userStatusColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(userStatus.description)
                        .font(.headline)
                        .foregroundColor(userStatusColor)
                }
                
                Spacer()
            }
            
            // Show match ready notification
            if case .hasMatch(let match) = userStatus {
                VStack(spacing: 8) {
                    Text("Your match is ready!")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("vs \(getOpponentName(match: match))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Play Match") {
                        currentMatch = match
                        showMatchView = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var statusIcon: String {
        switch userStatus {
        case .notRegistered:
            return "person.badge.plus"
        case .registered:
            return "checkmark.circle"
        case .waitingForMatch:
            return "clock"
        case .hasMatch:
            return "gamecontroller"
        case .eliminated:
            return "xmark.circle"
        case .finished:
            return "trophy"
        case .active:
            return "play.circle"
        case .champion:
            return "crown.fill"
        case .runnerUp:
            return "medal.fill"
        case .thirdPlace:
            return "medal"
        }
    }
    
    private var userStatusColor: Color {
        switch userStatus {
        case .notRegistered:
            return .blue
        case .registered:
            return .green
        case .waitingForMatch:
            return .orange
        case .hasMatch:
            return .purple
        case .eliminated:
            return .red
        case .finished:
            return .gray
        case .active:
            return .green
        case .champion:
            return .yellow
        case .runnerUp:
            return .gray
        case .thirdPlace:
            return .orange
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Organizer controls (if user is the organizer)
            if isOrganizer {
                organizerControls
            }
            
            // Regular participant controls
            switch userStatus {
            case .notRegistered:
                if tournament.isRegistrationOpen {
                    Button("Join Tournament") {
                        joinTournament()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(isLoading)
                } else {
                    Text("Registration Closed")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
            case .registered:
                if tournament.status == "Registration Open" {
                    Button("Leave Tournament") {
                        leaveTournament()
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .disabled(isLoading)
                }
                
            case .waitingForMatch:
                VStack(spacing: 8) {
                    Text("Waiting for next opponent...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    ProgressView()
                        .scaleEffect(1.2)
                }
                .padding()
                
            case .hasMatch(let match):
                Button("View Match Details") {
                    currentMatch = match
                    showMatchView = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                
            case .eliminated(let placement):
                VStack(spacing: 8) {
                    Text("Tournament Complete")
                        .font(.headline)
                    
                    Text("Final Placement: \(placement.ordinal)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
            case .finished(let placement):
                VStack(spacing: 8) {
                    if placement == 1 {
                        Text("🏆 Champion! 🏆")
                            .font(.title2)
                            .fontWeight(.bold)
                    } else {
                        Text("Tournament Complete")
                            .font(.headline)
                    }
                    
                    Text("Final Placement: \(placement.ordinal)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
            case .active:
                VStack(spacing: 8) {
                    Text("Tournament in Progress")
                        .font(.headline)
                        .foregroundColor(.green)
                    
                    Text("Waiting for your next match...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                
            case .champion:
                VStack(spacing: 8) {
                    Text("🏆 CHAMPION! 🏆")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    
                    Text("Congratulations on winning the tournament!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
            case .runnerUp:
                VStack(spacing: 8) {
                    Text("🥈 Runner-up")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                    
                    Text("Great performance! You finished in 2nd place.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
            case .thirdPlace:
                VStack(spacing: 8) {
                    Text("🥉 Third Place")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("Excellent job! You finished in 3rd place.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Organizer Controls
    
    private var organizerControls: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                Text("Tournament Organizer")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.yellow.opacity(0.1))
            )
            
            if tournament.status == "Registration Open" || tournament.status == "Registration Closed" {
                Button("Start Tournament") {
                    startTournament()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isLoading || tournament.participants.count < 4)
                
                if tournament.participants.count < 4 {
                    Text("Need at least 4 participants to start")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var isOrganizer: Bool {
        guard let currentUser = appState.currentUser else { return false }
        return tournament.organizerID == currentUser.id.uuidString
    }
    
    // MARK: - Tournament Info
    
    private var tournamentInfo: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournament Details")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                infoItem(title: "Format", value: tournament.format)
                infoItem(title: "Skill Level", value: tournament.skillLevel)
                infoItem(title: "Max Players", value: "\(tournament.maxParticipants)")
                infoItem(title: "Registered", value: "\(tournament.registeredCount)")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func infoItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Participants Section
    
    private var participantsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Participants")
                    .font(.headline)
                
                Spacer()
                
                Text("\(tournament.registeredCount)/\(tournament.maxParticipants)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(tournament.participants.prefix(8), id: \.id) { participant in
                    participantCard(participant)
                }
                
                if tournament.registeredCount > 8 {
                    Text("+ \(tournament.registeredCount - 8) more")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func participantCard(_ participant: TournamentParticipant) -> some View {
        VStack(spacing: 4) {
            Text(participant.effectiveName)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            Text("ELO: \(participant.elo)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        )
    }
    
    // MARK: - Ready Matches Section
    
    private var readyMatchesSection: some View {
        let readyMatches = tournamentService?.getReadyMatches(in: tournament) ?? []
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Current Matches")
                .font(.headline)
            
            if readyMatches.isEmpty {
                Text("No matches ready")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(readyMatches, id: \.id) { match in
                        readyMatchCard(match)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func readyMatchCard(_ match: TournamentMatch) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(match.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(match.shortDescription)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper Methods
    
    private func updateUserStatus() {
        guard let user = appState.currentUser,
              let service = tournamentService else {
            userStatus = .notRegistered
            return
        }
        
        userStatus = service.getUserTournamentStatus(user: user, tournament: tournament)
    }
    
    private func getOpponentName(match: TournamentMatch) -> String {
        guard let user = appState.currentUser else { return "Unknown" }
        
        let userID = user.id.uuidString
        if match.player1ID == userID {
            return match.player2Name.isEmpty ? "TBD" : match.player2Name
        } else {
            return match.player1Name.isEmpty ? "TBD" : match.player1Name
        }
    }
    
    private func joinTournament() {
        guard let user = appState.currentUser,
              let service = tournamentService else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await service.joinTournament(tournament, user: user)
                await MainActor.run {
                    updateUserStatus()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func leaveTournament() {
        guard let user = appState.currentUser,
              let service = tournamentService else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await service.leaveTournament(tournament, user: user)
                await MainActor.run {
                    updateUserStatus()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            updateUserStatus()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func startTournament() {
        guard let user = appState.currentUser,
              let service = tournamentService else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await service.startTournamentNow(tournament, organizerID: user.id.uuidString)
                await MainActor.run {
                    updateUserStatus()
                    isLoading = false
                    
                    // Show success feedback
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, configurations: config)
    
    // Create tournament with initial status
    let tournament = {
        var t = Tournament(
            name: "Summer Championship",
            description: "Annual summer tournament",
            organizerID: "organizer1",
            organizerName: "Tournament Director"
        )
        t.status = "Registration Open"
        return t
    }()
    
    let appState = AppState()
    let tournamentService = TournamentService(firebaseService: FirebaseService.shared)
    
    return TournamentDetailView(tournament: tournament, tournamentService: tournamentService)
        .modelContainer(container)
        .environmentObject(appState)
} 