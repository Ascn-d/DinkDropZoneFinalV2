import SwiftUI
import SwiftData

struct TournamentBracketView: View {
    @State private var tournament: Tournament
    @EnvironmentObject private var appState: AppState
    @State private var selectedMatch: TournamentMatch? = nil
    @State private var showMatchDetails = false
    @State private var animateProgress = false
    @State private var selectedRound: Int? = nil
    @State private var isLoading = true
    @State private var lastUpdateTime = Date()
    
    // Real-time Firebase listener handle
    @State private var tournamentListener: FirebaseService.ListenerHandle?
    @State private var showingInteractiveBracket = false
    @State private var showingAdvancedBracket = false
    
    init(tournament: Tournament) {
        self._tournament = State(initialValue: tournament)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground).opacity(0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    loadingView
                } else {
                    mainContent
                }
            }
        }
        .navigationTitle("Tournament Bracket")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    showingInteractiveBracket = true
                } label: {
                    Image(systemName: "hand.draw")
                        .foregroundColor(.brown)
                }
                
                Button {
                    showingAdvancedBracket = true
                } label: {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                }
                
                liveUpdateIndicator
            }
        }
        .sheet(isPresented: $showMatchDetails) {
            if let match = selectedMatch {
                EnhancedMatchDetailsView(match: match, tournament: tournament)
            }
        }
        .fullScreenCover(isPresented: $showingInteractiveBracket) {
            InteractiveTournamentBracketView(tournament: tournament)
        }
        .fullScreenCover(isPresented: $showingAdvancedBracket) {
            AdvancedInteractiveBracketView(tournament: tournament)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                    isLoading = false
                    animateProgress = true
                }
            }
            startLiveUpdates()
        }
        .onDisappear {
            stopLiveUpdates()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            // Animated bracket icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.brown.opacity(0.2), .brown.opacity(0.05)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateProgress ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateProgress)
                
                Image(systemName: "tournament")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.brown)
                    .rotationEffect(.degrees(animateProgress ? 5 : -5))
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateProgress)
            }
            
            VStack(spacing: 8) {
                Text("Loading Tournament Bracket")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Generating bracket visualization...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ProgressView()
                .scaleEffect(1.2)
                .tint(.brown)
        }
        .transition(.opacity)
        .onAppear {
            animateProgress = true
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 32) {
                // Enhanced tournament header
                enhancedTournamentHeader
                    .transition(.move(edge: .top).combined(with: .opacity))
                
                Divider()
                    .overlay(.brown.opacity(0.3))
                
                // Tournament format specific content
                if tournament.type == "Round Robin" {
                    roundRobinView
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                } else {
                    eliminationBracketView
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }
            .padding()
            .padding(.bottom, 100)
        }
        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: isLoading)
    }
    
    // MARK: - Enhanced Tournament Header
    
    private var enhancedTournamentHeader: some View {
        VStack(spacing: 24) {
            // Title section
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(tournament.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 12) {
                            Label(tournament.format, systemImage: "sportscourt")
                                .font(.title3)
                                .foregroundColor(.brown)
                            
                            Spacer()
                            
                            statusBadge
                        }
                    }
                    
                    Spacer()
                    
                    // Enhanced progress ring
                    enhancedProgressRing
                }
            }
            
            // Tournament stats grid
            tournamentStatsGrid
            
            // Progress overview
            if tournament.status == "In Progress" {
                bracketProgressView
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.brown.opacity(0.3), .brown.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var statusBadge: some View {
        Text(tournament.status)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.2))
            )
            .foregroundColor(statusColor)
            .overlay(
                Capsule()
                    .stroke(statusColor.opacity(0.4), lineWidth: 1)
            )
            .scaleEffect(animateProgress ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateProgress)
    }
    
    private var enhancedProgressRing: some View {
        let completedMatches = tournament.matches.filter { $0.status == "Completed" }.count
        let totalMatches = tournament.matches.count
        let progress = totalMatches > 0 ? Double(completedMatches) / Double(totalMatches) : 0
        
        return ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                .frame(width: 100, height: 100)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animateProgress ? progress : 0)
                .stroke(
                    AngularGradient(
                        colors: [.brown, .brown.opacity(0.7), .brown],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.5).delay(0.5), value: animateProgress)
            
            // Center content
            VStack(spacing: 4) {
                Text("\(Int(progress * 100))")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.brown)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 1).delay(0.8), value: progress)
                
                Text("%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .shadow(color: .brown.opacity(0.3), radius: 8, x: 0, y: 4)
    }
    
    private var tournamentStatsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            statCard(
                title: "Players",
                value: "\(tournament.registeredCount)",
                icon: "person.2.fill",
                color: .blue
            )
            
            statCard(
                title: "Matches",
                value: "\(tournament.matches.count)",
                icon: "gamecontroller.fill",
                color: .green
            )
            
            let completedMatches = tournament.matches.filter { $0.status == "Completed" }.count
            statCard(
                title: "Completed",
                value: "\(completedMatches)",
                icon: "checkmark.circle.fill",
                color: .purple
            )
            
            statCard(
                title: "Remaining",
                value: "\(tournament.matches.count - completedMatches)",
                icon: "clock.fill",
                color: .orange
            )
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .contentTransition(.numericText())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .scaleEffect(animateProgress ? 1.0 : 0.8)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double.random(in: 0.1...0.3)), value: animateProgress)
    }
    
    private var bracketProgressView: some View {
        let completedMatches = tournament.matches.filter { $0.status == "Completed" }.count
        let totalMatches = tournament.matches.count
        let progress = totalMatches > 0 ? Double(completedMatches) / Double(totalMatches) : 0
        
        return VStack(spacing: 16) {
            Text("Tournament Progress")
                .font(.headline)
                .foregroundColor(.primary)
            
            if tournament.type == "Double Elimination" {
                let winnersMatches = tournament.matches.filter { $0.bracket == "Winners" }
                let winnersCompleted = winnersMatches.filter { $0.status == "Completed" }.count
                let winnersProgress = winnersMatches.count > 0 ? Double(winnersCompleted) / Double(winnersMatches.count) : 0
                
                let losersMatches = tournament.matches.filter { $0.bracket == "Losers" }
                let losersCompleted = losersMatches.filter { $0.status == "Completed" }.count
                let losersProgress = losersMatches.count > 0 ? Double(losersCompleted) / Double(losersMatches.count) : 0
                
                VStack(spacing: 12) {
                    // Winners bracket progress
                    progressBar(
                        title: "Winners Bracket",
                        progress: winnersProgress,
                        completed: winnersCompleted,
                        total: winnersMatches.count,
                        color: .blue
                    )
                    
                    // Losers bracket progress
                    progressBar(
                        title: "Losers Bracket",
                        progress: losersProgress,
                        completed: losersCompleted,
                        total: losersMatches.count,
                        color: .orange
                    )
                }
            } else {
                // Single elimination or round robin progress
                progressBar(
                    title: "Overall Progress",
                    progress: progress,
                    completed: completedMatches,
                    total: totalMatches,
                    color: .green
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
        )
    }
    
    private func progressBar(title: String, progress: Double, completed: Int, total: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(completed)/\(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(height: 8)
                        .clipShape(Capsule())
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (animateProgress ? progress : 0), height: 8)
                        .clipShape(Capsule())
                        .animation(.easeOut(duration: 1).delay(0.3), value: animateProgress)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Round Robin View
    
    private var roundRobinView: some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "person.3.sequence.fill")
                    .font(.title2)
                    .foregroundColor(.brown)
                
                Text("Round Robin Matches")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            let matches = tournament.matches.filter { $0.bracket == "Round Robin" }
            let groupedMatches = Dictionary(grouping: matches) { match in
                match.status
            }
            
            VStack(spacing: 20) {
                // Completed matches
                if let completedMatches = groupedMatches["Completed"], !completedMatches.isEmpty {
                    matchSection(title: "Completed", matches: completedMatches, color: .green)
                }
                
                // Ready matches
                if let readyMatches = groupedMatches["Ready"], !readyMatches.isEmpty {
                    matchSection(title: "Ready to Play", matches: readyMatches, color: .blue)
                }
                
                // Upcoming matches
                if let upcomingMatches = groupedMatches["Upcoming"], !upcomingMatches.isEmpty {
                    matchSection(title: "Upcoming", matches: upcomingMatches, color: .orange)
                }
            }
            
            // Standings
            roundRobinStandings
        }
    }
    
    private func matchSection(title: String, matches: [TournamentMatch], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                
                Spacer()
                
                Text("\(matches.count) matches")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(matches.enumerated()), id: \.element.id) { index, match in
                    EnhancedMatchCard(match: match, compact: true) {
                        selectedMatch = match
                        showMatchDetails = true
                    }
                    .scaleEffect(animateProgress ? 1.0 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05), value: animateProgress)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var roundRobinStandings: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.number")
                    .foregroundColor(.brown)
                
                Text("Current Standings")
                    .font(.headline)
                
                Spacer()
            }
            
            let sortedParticipants = tournament.participants.sorted { p1, p2 in
                if p1.wins != p2.wins {
                    return p1.wins > p2.wins
                }
                return p1.losses < p2.losses
            }
            
            VStack(spacing: 8) {
                ForEach(Array(sortedParticipants.enumerated()), id: \.element.id) { index, participant in
                    standingRow(position: index + 1, participant: participant)
                        .scaleEffect(animateProgress ? 1.0 : 0.8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: animateProgress)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func standingRow(position: Int, participant: TournamentParticipant) -> some View {
        HStack {
            // Position
            ZStack {
                Circle()
                    .fill(positionColor(position))
                    .frame(width: 32, height: 32)
                
                Text("\(position)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Player name
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.effectiveName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("ELO: \(participant.elo)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Record
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(participant.wins)-\(participant.losses)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("W-L")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(position <= 3 ? positionColor(position).opacity(0.1) : Color(uiColor: .systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(position <= 3 ? positionColor(position).opacity(0.3) : .clear, lineWidth: 1)
        )
    }
    
    private func positionColor(_ position: Int) -> Color {
        switch position {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .brown
        default: return .blue
        }
    }
    
    // MARK: - Elimination Bracket View
    
    private var eliminationBracketView: some View {
        VStack(spacing: 32) {
            // Winners bracket
            if !winnersRounds.isEmpty {
                bracketSection(
                    title: "Winners Bracket",
                    rounds: winnersRounds,
                    bracket: "Winners",
                    color: .blue
                )
            }
            
            // Losers bracket (only for double elimination)
            if tournament.type == "Double Elimination" && !losersRounds.isEmpty {
                bracketSection(
                    title: "Losers Bracket",
                    rounds: losersRounds,
                    bracket: "Losers",
                    color: .orange
                )
            }
            
            // Grand final
            if let grandFinalMatch = tournament.matches.first(where: { $0.round == 999 }) {
                grandFinalSection(match: grandFinalMatch)
            }
        }
    }
    
    private func bracketSection(title: String, rounds: [Int], bracket: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Image(systemName: bracket == "Winners" ? "trophy.fill" : "arrow.triangle.2.circlepath")
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 40) {
                    ForEach(Array(rounds.enumerated()), id: \.element) { index, round in
                        roundColumn(round: round, bracket: bracket, roundIndex: index)
                            .scaleEffect(animateProgress ? 1.0 : 0.8)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(Double(index) * 0.2), value: animateProgress)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func roundColumn(round: Int, bracket: String, roundIndex: Int) -> some View {
        VStack(spacing: 20) {
            // Round header
            Button {
                withAnimation(.spring()) {
                    selectedRound = selectedRound == round ? nil : round
                }
            } label: {
                VStack(spacing: 8) {
                    Text(roundTitle(round: round, bracket: bracket))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(bracket == "Winners" ? .blue : .orange)
                    
                    let roundMatches = matchesForRound(round, bracket: bracket)
                    let completedCount = roundMatches.filter { $0.status == "Completed" }.count
                    
                    Text("\(completedCount)/\(roundMatches.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color(uiColor: .systemBackground))
                        .overlay(
                            Capsule()
                                .stroke(selectedRound == round ? .brown : .clear, lineWidth: 2)
                        )
                )
            }
            
            // Matches in round
            VStack(spacing: 16) {
                ForEach(Array(matchesForRound(round, bracket: bracket).enumerated()), id: \.element.id) { index, match in
                    EnhancedMatchCard(match: match) {
                        selectedMatch = match
                        showMatchDetails = true
                    }
                    .scaleEffect(selectedRound == round ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedRound)
                }
            }
        }
        .frame(minWidth: 200)
    }
    
    private func grandFinalSection(match: TournamentMatch) -> some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
                
                Text("Grand Final")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Spacer()
            }
            
            EnhancedMatchCard(match: match, isGrandFinal: true) {
                selectedMatch = match
                showMatchDetails = true
            }
            .scaleEffect(animateProgress ? 1.05 : 0.9)
            .animation(.spring(response: 1, dampingFraction: 0.6).delay(1), value: animateProgress)
            
            // Grand final rules
            VStack(spacing: 8) {
                Text("Championship Rules")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Best of 3 matches • Winner takes the championship")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.purple.opacity(0.1))
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.purple, .yellow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: .purple.opacity(0.3), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Helper Methods
    
    private func statusColor(for status: String) -> Color {
        switch status {
        case "Upcoming": return .blue
        case "Registration Open": return .green
        case "Registration Closed": return .orange
        case "In Progress": return .purple
        case "Completed": return .gray
        case "Cancelled": return .red
        default: return .gray
        }
    }
    
    private var statusColor: Color {
        statusColor(for: tournament.status)
    }
    
    private var winnersRounds: [Int] {
        let winnersMatches = tournament.matches.filter { $0.bracket == "Winners" && $0.round < 999 }
        let rounds = Set(winnersMatches.map { $0.round })
        return rounds.sorted()
    }
    
    private var losersRounds: [Int] {
        let losersMatches = tournament.matches.filter { $0.bracket == "Losers" }
        let rounds = Set(losersMatches.map { $0.round })
        return rounds.sorted()
    }
    
    private func matchesForRound(_ round: Int, bracket: String) -> [TournamentMatch] {
        tournament.matches
            .filter { $0.bracket == bracket && $0.round == round }
            .sorted { $0.matchNumber < $1.matchNumber }
    }
    
    private func roundTitle(round: Int, bracket: String) -> String {
        if bracket == "Winners" {
            return "Round \(round)"
        } else {
            return "LR \(round)"
        }
    }
    
    // MARK: - Live Updates
    
    private var liveUpdateIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
                .scaleEffect(animateProgress ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateProgress)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("LIVE")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                
                Text(lastUpdateTime, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.green.opacity(0.1))
        )
    }
    
    private func startLiveUpdates() {
        tournamentListener = appState.firebaseService.observeTournament(id: tournament.id.uuidString) { result in
            switch result {
            case .success(let updatedTournament):
                Task {
                    await MainActor.run {
                        tournament = updatedTournament
                        lastUpdateTime = Date()
                        
                        // Haptic feedback for updates
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                }
            case .failure(let error):
                print("❌ Tournament listener error: \(error)")
            }
        }
    }
    
    private func stopLiveUpdates() {
        tournamentListener?.remove()
        tournamentListener = nil
    }
}

// MARK: - Enhanced Match Card

struct EnhancedMatchCard: View {
    let match: TournamentMatch
    var compact: Bool = false
    var isGrandFinal: Bool = false
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: compact ? 8 : 12) {
                // Match header
                HStack {
                    Text(matchDisplayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    statusIndicator
                }
                
                // Players section
                VStack(spacing: compact ? 6 : 8) {
                    playerRow(
                        name: match.player1Name.isEmpty ? "TBD" : match.player1Name,
                        isWinner: match.winnerID == match.player1ID,
                        compact: compact
                    )
                    
                    vsIndicator
                    
                    playerRow(
                        name: match.player2Name.isEmpty ? "TBD" : match.player2Name,
                        isWinner: match.winnerID == match.player2ID,
                        compact: compact
                    )
                }
                
                // Score or status
                bottomSection
            }
            .padding(compact ? 12 : 16)
            .frame(width: compact ? 160 : 200)
            .frame(minHeight: compact ? 100 : 140)
            .background(backgroundStyle)
            .overlay(borderStyle)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) {
            // Empty onChanged
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
    
    private var matchDisplayName: String {
        if match.bracket == "Winners" {
            return "WR\(match.round)-\(match.matchNumber)"
        } else if match.bracket == "Losers" {
            return "LR\(match.round)-\(match.matchNumber)"
        } else if match.bracket == "Round Robin" {
            return "Match \(match.matchNumber)"
        } else {
            return "Match \(match.matchNumber)"
        }
    }
    
    private var statusIndicator: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(.white, lineWidth: 1)
            )
            .scaleEffect(match.status == "Ready" ? 1.2 : 1.0)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: match.status == "Ready")
    }
    
    private var statusColor: Color {
        switch match.status {
        case "Upcoming": return .blue
        case "Ready": return .green
        case "In Progress": return .orange
        case "Completed": return .gray
        default: return .gray
        }
    }
    
    private var vsIndicator: some View {
        ZStack {
            if match.status == "In Progress" {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.orange)
                            .frame(width: 4, height: 4)
                            .scaleEffect(1.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: match.status
                            )
                    }
                }
            } else {
                Text("VS")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func playerRow(name: String, isWinner: Bool, compact: Bool) -> some View {
        HStack(spacing: 8) {
            Text(name)
                .font(compact ? .caption : .subheadline)
                .fontWeight(isWinner ? .bold : .medium)
                .foregroundColor(isWinner ? .primary : .secondary)
                .lineLimit(compact ? 1 : 2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isWinner {
                Image(systemName: "crown.fill")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                    .scaleEffect(1.2)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var bottomSection: some View {
        Group {
            if match.hasResult {
                Text(match.finalScore)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.green.opacity(0.1))
                    )
            } else if match.isBye {
                Text("Bye")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.orange.opacity(0.1))
                    )
            } else if match.status == "Ready" {
                Text("Ready to Play")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.green.opacity(0.1))
                    )
            }
        }
    }
    
    private var backgroundStyle: AnyShapeStyle {
        if isGrandFinal {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.purple.opacity(0.1), .yellow.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(.ultraThinMaterial)
        }
    }
    
    private var borderStyle: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(strokeGradient, lineWidth: isGrandFinal ? 2 : 1)
    }
    
    private var strokeGradient: AnyShapeStyle {
        if isGrandFinal {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.purple, .yellow],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        } else {
            return AnyShapeStyle(Color.gray.opacity(0.2))
        }
    }
}

// MARK: - Enhanced Match Details View

struct EnhancedMatchDetailsView: View {
    let match: TournamentMatch
    let tournament: Tournament
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var showingScoreEntry = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Match header with enhanced styling
                    matchHeaderSection
                    
                    // Players comparison
                    playersComparisonSection
                    
                    // Match details
                    matchDetailsSection
                    
                    // Tournament context
                    tournamentContextSection
                    
                    // Score entry button (if user can enter scores)
                    if canEnterScore {
                        scoreEntryButton
                    }
                }
                .padding()
            }
            .navigationTitle("Match Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingScoreEntry) {
                ScoreEntryView(match: match, tournament: tournament)
                    .environmentObject(appState)
            }
        }
    }
    
    private var matchHeaderSection: some View {
        VStack(spacing: 16) {
            Text(match.displayName)
                .font(.title)
                .fontWeight(.bold)
            
            Text("\(tournament.name) • \(match.bracket) Bracket")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            statusBadge
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var statusBadge: some View {
        Text(match.status)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.2))
            )
            .foregroundColor(statusColor)
    }
    
    private var statusColor: Color {
        switch match.status {
        case "Upcoming": return .blue
        case "Ready": return .green
        case "In Progress": return .orange
        case "Completed": return .gray
        default: return .gray
        }
    }
    
    private var playersComparisonSection: some View {
        HStack(spacing: 24) {
            // Player 1
            playerDetailCard(
                name: match.player1Name.isEmpty ? "TBD" : match.player1Name,
                isWinner: match.winnerID == match.player1ID
            )
            
            Image(systemName: "bolt.horizontal.fill")
                .font(.title2)
                .foregroundColor(.orange)
            
            // Player 2
            playerDetailCard(
                name: match.player2Name.isEmpty ? "TBD" : match.player2Name,
                isWinner: match.winnerID == match.player2ID
            )
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func playerDetailCard(name: String, isWinner: Bool) -> some View {
        VStack(spacing: 12) {
            if isWinner {
                Image(systemName: "crown.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
            }
            
            Text(name)
                .font(.headline)
                .fontWeight(isWinner ? .bold : .medium)
                .multilineTextAlignment(.center)
            
            if isWinner {
                Text("Winner")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.green.opacity(0.1))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isWinner ? .green.opacity(0.1) : Color(uiColor: .systemBackground))
        )
    }
    
    private var matchDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Match Information")
                .font(.headline)
            
            if match.hasResult {
                VStack(spacing: 8) {
                    Text("Final Score")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(match.finalScore)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.green.opacity(0.1))
                )
            }
            
            VStack(spacing: 12) {
                detailRow(title: "Round", value: "\(match.round)")
                detailRow(title: "Match Number", value: "\(match.matchNumber)")
                detailRow(title: "Bracket", value: match.bracket)
                detailRow(title: "Status", value: match.status)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var tournamentContextSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournament Context")
                .font(.headline)
            
            VStack(spacing: 12) {
                detailRow(title: "Tournament", value: tournament.name)
                detailRow(title: "Format", value: tournament.format)
                detailRow(title: "Type", value: tournament.type)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
    
    private var canEnterScore: Bool {
        guard let currentUser = appState.currentUser else { return false }
        let userId = currentUser.id.uuidString
        
        // User can enter score if:
        // 1. They are one of the players in the match
        // 2. The match is ready to play or in progress
        // 3. The match doesn't already have a result
        
        let isPlayer = match.player1ID == userId || match.player2ID == userId
        let isMatchReady = match.status == "Ready" || match.status == "In Progress"
        let hasNoResult = !match.hasResult
        
        return isPlayer && isMatchReady && hasNoResult
    }
    
    private var scoreEntryButton: some View {
        VStack(spacing: 16) {
            Text("Ready to Play?")
                .font(.headline)
                .foregroundColor(.primary)
            
            Button {
                showingScoreEntry = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "sportscourt.fill")
                        .font(.title3)
                    
                    Text("Enter Match Score")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            
            Text("Enter the score after completing your match")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    let sampleTournament = Tournament(
        name: "Sample Tournament",
        description: "A sample tournament",
        type: "Double Elimination",
        format: "Singles",
        skillLevel: "Intermediate",
        maxParticipants: 16,
        startDate: Date(),
        organizerID: "organizer1",
        organizerName: "Organizer"
    )
    
    TournamentBracketView(tournament: sampleTournament)
} 