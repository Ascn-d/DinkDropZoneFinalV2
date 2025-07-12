import SwiftUI
import Combine

struct TournamentLiveMonitorView: View {
    let tournament: Tournament
    @StateObject private var tournamentService = TournamentService(firebaseService: FirebaseService.shared)
    @EnvironmentObject var appState: AppState
    
    // State management
    @State private var matches: [TournamentMatch] = []
    @State private var participants: [TournamentParticipant] = []
    @State private var liveMatches: [TournamentMatch] = []
    @State private var isLoading = true
    @State private var selectedMatch: TournamentMatch?
    @State private var showingMatchControl = false
    @State private var refreshTimer: Timer?
    @State private var lastUpdateTime = Date()
    
    // Dashboard metrics
    @State private var tournamentStats = TournamentStats()
    @State private var recentActions: [TournamentAction] = []
    
    // UI State
    @State private var selectedTab = 0
    @State private var showingParticipantSheet = false
    @State private var showingSettingsSheet = false
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    private let dashboardTabs = ["Overview", "Live Matches", "Participants", "Results"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else {
                    dashboardContent
                }
            }
            .navigationTitle("Tournament Control")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: backButton,
                trailing: settingsButton
            )
            .task {
                await loadTournamentData()
                startRealTimeUpdates()
            }
            .onDisappear {
                stopRealTimeUpdates()
            }
            .sheet(isPresented: $showingMatchControl) {
                if let match = selectedMatch {
                    MatchControlSheet(
                        match: match,
                        tournament: tournament,
                        tournamentService: tournamentService,
                        onMatchUpdate: { updatedMatch in
                            await updateMatch(updatedMatch)
                        }
                    )
                }
            }
            .sheet(isPresented: $showingParticipantSheet) {
                ParticipantManagementSheet(
                    tournament: tournament,
                    participants: participants
                )
            }
            .sheet(isPresented: $showingSettingsSheet) {
                TournamentSettingsSheet(tournament: tournament)
            }
            .alert("Tournament Update", isPresented: $showingAlert) {
                Button("OK") {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Tournament Dashboard...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Preparing real-time monitoring")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Navigation
    private var backButton: some View {
        Button("Close") {
            // Navigate back to tournament detail
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            showingSettingsSheet = true
        }) {
            Image(systemName: "gear")
        }
    }
    
    // MARK: - Dashboard Content
    private var dashboardContent: some View {
        VStack(spacing: 0) {
            // Status header
            tournamentStatusHeader
            
            // Tab selection
            tabSelector
            
            // Tab content
            TabView(selection: $selectedTab) {
                overviewTab.tag(0)
                liveMatchesTab.tag(1)
                participantsTab.tag(2)
                resultsTab.tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
    
    // MARK: - Tournament Status Header
    private var tournamentStatusHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Live Tournament Control")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.5)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: true)
                    
                    Text("LIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
            
            // Quick stats
            HStack(spacing: 20) {
                quickStat("Active Matches", value: "\(liveMatches.count)", color: .green)
                quickStat("Completed", value: "\(tournamentStats.completedMatches)", color: .blue)
                quickStat("Remaining", value: "\(tournamentStats.remainingMatches)", color: .orange)
            }
            
            // Last update
            HStack {
                Spacer()
                Text("Last updated: \(DateFormatter.timeOnly.string(from: lastUpdateTime))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(.green.opacity(0.3))
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    private func quickStat(_ title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(0..<dashboardTabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(dashboardTabs[index])
                            .font(.subheadline)
                            .fontWeight(selectedTab == index ? .semibold : .medium)
                            .foregroundColor(selectedTab == index ? .blue : .secondary)
                        
                        Rectangle()
                            .fill(selectedTab == index ? .blue : .clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Overview Tab
    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Tournament overview cards
                tournamentOverviewCards
                
                // Recent actions
                recentActionsSection
                
                // Tournament progress
                tournamentProgressSection
            }
            .padding()
        }
    }
    
    private var tournamentOverviewCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            overviewCard(
                title: "Participants",
                value: "\(participants.count)",
                subtitle: "of \(tournament.maxParticipants) max",
                icon: "person.2.fill",
                color: .blue
            )
            
            overviewCard(
                title: "Total Matches",
                value: "\(matches.count)",
                subtitle: "\(tournamentStats.completedMatches) completed",
                icon: "gamecontroller.fill",
                color: .green
            )
            
            overviewCard(
                title: "Duration",
                value: tournamentStats.elapsedTime,
                subtitle: "elapsed time",
                icon: "clock.fill",
                color: .orange
            )
            
            overviewCard(
                title: "Current Round",
                value: "\(tournamentStats.currentRound)",
                subtitle: "of \(tournamentStats.totalRounds)",
                icon: "target",
                color: .purple
            )
        }
    }
    
    private func overviewCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Live Matches Tab
    private var liveMatchesTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if liveMatches.isEmpty {
                    noLiveMatchesView
                } else {
                    ForEach(liveMatches, id: \.id) { match in
                        TournamentLiveMatchCard(match: match) {
                            selectedMatch = match
                            showingMatchControl = true
                        }
                    }
                }
                
                // Ready to start matches
                readyMatchesSection
            }
            .padding()
        }
    }
    
    private var noLiveMatchesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Live Matches")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Start matches from the ready queue below")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var readyMatchesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ready to Start")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(readyMatches.count) matches")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if readyMatches.isEmpty {
                Text("All matches are either completed or in progress")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray.opacity(0.1))
                    )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(readyMatches, id: \.id) { match in
                        ReadyMatchCard(match: match) {
                            Task {
                                await startMatch(match)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var readyMatches: [TournamentMatch] {
        matches.filter { $0.status == "Ready" && $0.status != "In Progress" }
    }
    
    // MARK: - Participants Tab
    private var participantsTab: some View {
        VStack {
            // Participants header
            HStack {
                Text("Tournament Participants")
                    .font(.headline)
                
                Spacer()
                
                Button("Manage") {
                    showingParticipantSheet = true
                }
                .foregroundColor(.blue)
            }
            .padding()
            
            // Participants list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(participants.sorted(by: { $0.wins > $1.wins }), id: \.id) { participant in
                        ParticipantRow(participant: participant)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Results Tab
    private var resultsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Completed matches
                VStack(alignment: .leading, spacing: 12) {
                    Text("Completed Matches")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(completedMatches, id: \.id) { match in
                        CompletedMatchCard(match: match)
                    }
                }
            }
            .padding()
        }
    }
    
    private var completedMatches: [TournamentMatch] {
        matches.filter { $0.status == "Completed" }.sorted { (first: TournamentMatch, second: TournamentMatch) -> Bool in
            return first.round > second.round || (first.round == second.round && first.matchNumber > second.matchNumber)
        }
    }
    
    // MARK: - Helper Views
    private var recentActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Actions")
                .font(.headline)
            
            if recentActions.isEmpty {
                Text("No recent actions")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.gray.opacity(0.1))
                    )
            } else {
                VStack(spacing: 8) {
                    ForEach(recentActions.prefix(5), id: \.id) { action in
                        ActionRow(action: action)
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
    
    private var tournamentProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournament Progress")
                .font(.headline)
            
            // Progress bars for each bracket
            if tournament.format == "Double Elimination" {
                VStack(spacing: 12) {
                    bracketProgress("Winners Bracket", progress: tournamentStats.winnersProgress, color: .blue)
                    bracketProgress("Losers Bracket", progress: tournamentStats.losersProgress, color: .orange)
                }
            } else {
                bracketProgress("Tournament Progress", progress: tournamentStats.overallProgress, color: .green)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func bracketProgress(_ title: String, progress: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2)
        }
    }
    
    // MARK: - Data Loading and Updates
    private func loadTournamentData() async {
        isLoading = true
        
        do {
            async let matchesTask = tournamentService.getTournamentMatches(tournamentId: tournament.id.uuidString)
            async let participantsTask = tournamentService.getTournamentParticipants(tournamentId: tournament.id.uuidString)
            
            let (loadedMatches, loadedParticipants) = try await (matchesTask, participantsTask)
            
            await MainActor.run {
                self.matches = loadedMatches
                self.participants = loadedParticipants
                self.liveMatches = loadedMatches.filter { $0.status == "In Progress" }
                self.updateTournamentStats()
                self.lastUpdateTime = Date()
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.alertMessage = "Failed to load tournament data: \(error.localizedDescription)"
                self.showingAlert = true
            }
        }
    }
    
    // MARK: - Enhanced Real-time Setup
    
    private func startRealTimeUpdates() {
        // Use AppState's centralized match result listeners
        appState.setupMatchResultListeners(tournamentId: tournament.id.uuidString)
        
        // Setup traditional timer as backup
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await loadTournamentData()
            }
        }
        
        // Listen for match completion notifications
        NotificationCenter.default.addObserver(
            forName: .matchCompleted,
            object: nil,
            queue: .main
        ) { notification in
            if let match = notification.object as? TournamentMatch {
                handleMatchCompletion(match)
            }
        }
        
        // Listen for tournament updates
        NotificationCenter.default.addObserver(
            forName: .tournamentUpdated,
            object: nil,
            queue: .main
        ) { notification in
            if let tournament = notification.object as? Tournament {
                handleTournamentUpdate(tournament)
            }
        }
    }
    
    private func handleMatchCompletion(_ match: TournamentMatch) {
        // Update UI when match is completed
        if let index = matches.firstIndex(where: { $0.id == match.id }) {
            matches[index] = match
        }
        
        // Remove from live matches if completed
        liveMatches.removeAll { $0.id == match.id }
        
        updateTournamentStats()
        
        let action = TournamentAction(
            id: UUID().uuidString,
            type: "match_completed",
            description: "Match \(match.matchNumber) completed - Winner: \(match.winnerID ?? "Unknown")",
            timestamp: Date()
        )
        recentActions.insert(action, at: 0)
    }
    
    private func handleTournamentUpdate(_ tournament: Tournament) {
        // Update local tournament data when changes occur
        if tournament.id == self.tournament.id {
            self.matches = tournament.matches
            self.participants = tournament.participants
            self.liveMatches = tournament.matches.filter { $0.status == "In Progress" }
            updateTournamentStats()
            lastUpdateTime = Date()
        }
    }
    
    private func stopRealTimeUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        // Clean up centralized match result listeners
        appState.cleanupMatchResultListeners()
        
        // Remove notification observers
        NotificationCenter.default.removeObserver(self, name: .matchCompleted, object: nil)
        NotificationCenter.default.removeObserver(self, name: .tournamentUpdated, object: nil)
    }
    
    private func updateTournamentStats() {
        let completedMatches = matches.filter { $0.status == "Completed" }.count
        let totalMatches = matches.count
        let currentRound = matches.map { $0.round }.max() ?? 1
        let totalRounds = matches.isEmpty ? 1 : (matches.map { $0.round }.max() ?? 1)
        
        let winnersMatches = matches.filter { $0.bracket == "Winners" }
        let winnersCompleted = winnersMatches.filter { $0.status == "Completed" }.count
        let winnersProgress = winnersMatches.isEmpty ? 0.0 : Double(winnersCompleted) / Double(winnersMatches.count)
        
        let losersMatches = matches.filter { $0.bracket == "Losers" }
        let losersCompleted = losersMatches.filter { $0.status == "Completed" }.count
        let losersProgress = losersMatches.isEmpty ? 0.0 : Double(losersCompleted) / Double(losersMatches.count)
        
        let overallProgress = totalMatches == 0 ? 0.0 : Double(completedMatches) / Double(totalMatches)
        
        let elapsedTime = formatElapsedTime(from: tournament.startDate)
        
        tournamentStats = TournamentStats(
            completedMatches: completedMatches,
            remainingMatches: totalMatches - completedMatches,
            currentRound: currentRound,
            totalRounds: totalRounds,
            winnersProgress: winnersProgress,
            losersProgress: losersProgress,
            overallProgress: overallProgress,
            elapsedTime: elapsedTime
        )
    }
    
    private func formatElapsedTime(from startDate: Date) -> String {
        let elapsed = Date().timeIntervalSince(startDate)
        let hours = Int(elapsed) / 3600
        let minutes = Int(elapsed.truncatingRemainder(dividingBy: 3600)) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func startMatch(_ match: TournamentMatch) async {
        do {
            var updatedMatch = match
            updatedMatch.status = "In Progress"
            
            // Use AppState's centralized match update system
            try await appState.submitMatchResult(
                match: updatedMatch,
                winnerID: updatedMatch.winnerID ?? "",
                loserID: updatedMatch.loserID ?? "",
                score: updatedMatch.finalScore,
                tournament: tournament
            )
            
            await MainActor.run {
                if let index = matches.firstIndex(where: { $0.id == match.id }) {
                    matches[index] = updatedMatch
                }
                liveMatches.append(updatedMatch)
                
                let action = TournamentAction(
                    id: UUID().uuidString,
                    type: "match_started",
                    description: "Match \(match.matchNumber) started",
                    timestamp: Date()
                )
                recentActions.insert(action, at: 0)
            }
        } catch {
            await MainActor.run {
                alertMessage = "Failed to start match: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    
    private func updateMatch(_ match: TournamentMatch) async {
        do {
            // Use AppState's centralized match update system
            try await appState.submitMatchResult(
                match: match,
                winnerID: match.winnerID ?? "",
                loserID: match.loserID ?? "",
                score: match.finalScore,
                tournament: tournament
            )
            
            await MainActor.run {
                if let index = matches.firstIndex(where: { $0.id == match.id }) {
                    matches[index] = match
                }
                
                if let index = liveMatches.firstIndex(where: { $0.id == match.id }) {
                    if match.status == "Completed" {
                        liveMatches.remove(at: index)
                    } else {
                        liveMatches[index] = match
                    }
                }
                
                updateTournamentStats()
            }
        } catch {
            await MainActor.run {
                alertMessage = "Failed to update match: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

// MARK: - Supporting Data Models
struct TournamentStats {
    var completedMatches: Int = 0
    var remainingMatches: Int = 0
    var currentRound: Int = 1
    var totalRounds: Int = 1
    var winnersProgress: Double = 0.0
    var losersProgress: Double = 0.0
    var overallProgress: Double = 0.0
    var elapsedTime: String = "0m"
}

struct TournamentAction {
    let id: String
    let type: String
    let description: String
    let timestamp: Date
}

// MARK: - Supporting Views
struct TournamentLiveMatchCard: View {
    let match: TournamentMatch
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    Text("Match \(match.matchNumber)")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.5)
                            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: true)
                        
                        Text("LIVE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(match.player1Name.isEmpty ? "TBD" : match.player1Name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(match.player2Name.isEmpty ? "TBD" : match.player2Name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text(match.finalScore.isEmpty ? "0" : match.finalScore)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                if match.status == "In Progress" {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        Text("Match in progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.red.opacity(0.3), lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReadyMatchCard: View {
    let match: TournamentMatch
    let onStart: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Match \(match.matchNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(match.player1Name.isEmpty ? "TBD" : match.player1Name) vs \(match.player2Name.isEmpty ? "TBD" : match.player2Name)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Start Match") {
                onStart()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.green.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ParticipantRow: View {
    let participant: TournamentParticipant
    
    var body: some View {
        HStack {
            Text(participant.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(participant.wins)-\(participant.losses)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("W-L")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
        )
    }
}

struct CompletedMatchCard: View {
    let match: TournamentMatch
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Match \(match.matchNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("Completed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(match.player1Name.isEmpty ? "TBD" : match.player1Name)
                        .font(.caption)
                        .fontWeight(match.winnerID == match.player1ID ? .bold : .regular)
                        .foregroundColor(match.winnerID == match.player1ID ? .green : .primary)
                    
                    Text(match.player2Name.isEmpty ? "TBD" : match.player2Name)
                        .font(.caption)
                        .fontWeight(match.winnerID == match.player2ID ? .bold : .regular)
                        .foregroundColor(match.winnerID == match.player2ID ? .green : .primary)
                }
                
                Spacer()
                
                VStack {
                    Text(match.finalScore.isEmpty ? "No score" : match.finalScore)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                if match.winnerID == match.player1ID || match.winnerID == match.player2ID {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.1))
        )
    }
}

struct ActionRow: View {
    let action: TournamentAction
    
    var body: some View {
        HStack {
            Image(systemName: iconForActionType(action.type))
                .foregroundColor(colorForActionType(action.type))
                .frame(width: 20)
            
            Text(action.description)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(DateFormatter.timeOnly.string(from: action.timestamp))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func iconForActionType(_ type: String) -> String {
        switch type {
        case "match_started": return "play.circle"
        case "match_completed": return "checkmark.circle"
        case "participant_added": return "person.badge.plus"
        case "participant_removed": return "person.badge.minus"
        default: return "circle"
        }
    }
    
    private func colorForActionType(_ type: String) -> Color {
        switch type {
        case "match_started": return .green
        case "match_completed": return .blue
        case "participant_added": return .blue
        case "participant_removed": return .red
        default: return .gray
        }
    }
}

// MARK: - Supporting Sheets
struct MatchControlSheet: View {
    let match: TournamentMatch
    let tournament: Tournament
    let tournamentService: TournamentService
    let onMatchUpdate: (TournamentMatch) async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var isUpdating = false
    
    var body: some View {
        NavigationView {
            TournamentMatchView(match: match, tournament: tournament, tournamentService: tournamentService)
                .navigationTitle("Match Control")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarItems(
                    leading: Button("Close") {
                        dismiss()
                    }
                )
        }
    }
}

struct ParticipantManagementSheet: View {
    let tournament: Tournament
    let participants: [TournamentParticipant]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack {
                    ForEach(participants, id: \.id) { participant in
                        ParticipantRow(participant: participant)
                    }
                }
                .padding()
            }
            .navigationTitle("Manage Participants")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

struct TournamentSettingsSheet: View {
    let tournament: Tournament
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Tournament Info") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(tournament.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Format")
                        Spacer()
                        Text(tournament.format)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(tournament.status)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Actions") {
                    Button("Pause Tournament") {
                        // Pause tournament
                    }
                    .foregroundColor(.orange)
                    
                    Button("End Tournament") {
                        // End tournament
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Tournament Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

extension DateFormatter {
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
} 