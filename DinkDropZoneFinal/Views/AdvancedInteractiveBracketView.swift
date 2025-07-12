import SwiftUI
import UniformTypeIdentifiers

// MARK: - Bracket Manager

class BracketManager: ObservableObject {
    @Published var isDragActive = false
    @Published var draggedPlayer: String?
    @Published var dropTarget: UUID?
    
    func startDrag(player: String) {
        draggedPlayer = player
        isDragActive = true
    }
    
    func endDrag() {
        draggedPlayer = nil
        isDragActive = false
        dropTarget = nil
    }
    
    func setDropTarget(_ matchID: UUID?) {
        dropTarget = matchID
    }
}

struct AdvancedInteractiveBracketView: View {
    @State private var tournament: Tournament
    @StateObject private var bracketManager = BracketManager()
    @EnvironmentObject private var appState: AppState
    
    // Interactive State
    @State private var selectedMatch: TournamentMatch?
    @State private var draggedPlayer: String?
    @State private var isEditMode = false
    @State private var showingMatchDetails = false
    @State private var animateEntrance = false
    @State private var bracketScale: CGFloat = 1.0
    @State private var bracketOffset: CGSize = .zero
    @State private var showingParticipantSelector = false
    @State private var showingScoreEntry = false
    @State private var connectionAnimations: [UUID: Bool] = [:]
    @State private var tournamentListener: FirebaseService.ListenerHandle?
    
    // Visual Effects
    @State private var glowEffect = false
    @State private var pulseEffect = false
    @State private var showingConfetti = false
    @State private var lastWinner: String?
    
    init(tournament: Tournament) {
        self._tournament = State(initialValue: tournament)
    }
    
    var body: some View {
        ZStack {
            // Dynamic background with tournament theme
            dynamicBackground
            
            // Main bracket content
            GeometryReader { geometry in
                ZStack {
                    // Animated connection lines
                    BracketConnectionsCanvas(
                        tournament: tournament,
                        geometry: geometry,
                        scale: bracketScale,
                        offset: bracketOffset,
                        animations: connectionAnimations
                    )
                    .allowsHitTesting(false)
                    
                    // Interactive bracket layout
                    ScrollView([.horizontal, .vertical]) {
                        bracketContent(geometry: geometry)
                            .scaleEffect(bracketScale)
                            .offset(bracketOffset)
                            .gesture(bracketGestures)
                    }
                    .clipped()
                }
            }
            
            // Floating UI elements
            floatingInterface
            
            // Confetti overlay for celebrations
            if showingConfetti {
                BracketConfettiView()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .navigationTitle("Interactive Bracket")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    // Handle done action
                }
                .foregroundColor(.white)
                .fontWeight(.semibold)
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                toolbarControls
            }
        }
        .sheet(isPresented: $showingMatchDetails) {
            if let match = selectedMatch {
                AdvancedMatchDetailsView(
                    match: match,
                    tournament: tournament,
                    onScoreUpdate: handleScoreUpdate,
                    onPlayerSwap: handlePlayerSwap
                )
            }
        }
        .sheet(isPresented: $showingParticipantSelector) {
            ParticipantSelectorView(
                tournament: tournament,
                onPlayerSelected: handlePlayerSelection
            )
        }
        .onAppear {
            setupBracket()
        }
        .onDisappear {
            cleanupListeners()
        }
        .onChange(of: tournament.matches) { _, _ in
            updateConnectionAnimations()
        }
    }
    
    // MARK: - Dynamic Background
    
    private var dynamicBackground: some View {
        ZStack {
            // Base gradient that changes based on tournament status
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated particles
            ParticleSystemView(
                particleCount: 50,
                colors: [.white.opacity(0.1), .blue.opacity(0.1)],
                animated: animateEntrance
            )
            .ignoresSafeArea()
            
            // Dynamic mesh gradient overlay
            MeshGradientView(
                colors: meshColors,
                animated: glowEffect
            )
            .opacity(0.3)
            .ignoresSafeArea()
        }
    }
    
    private var backgroundColors: [Color] {
        switch tournament.status {
        case "In Progress":
            return [.blue.opacity(0.8), .purple.opacity(0.6), .indigo.opacity(0.8)]
        case "Completed":
            return [.green.opacity(0.8), .mint.opacity(0.6), .cyan.opacity(0.8)]
        default:
            return [.gray.opacity(0.8), .gray.opacity(0.6), .gray.opacity(0.4)]
        }
    }
    
    private var meshColors: [Color] {
        [.blue, .purple, .indigo, .cyan, .mint, .green]
    }
    
    // MARK: - Bracket Content
    
    private func bracketContent(geometry: GeometryProxy) -> some View {
        VStack(spacing: 60) {
            // Tournament header with live stats
            enhancedTournamentHeader
                .scaleEffect(animateEntrance ? 1.0 : 0.8)
                .opacity(animateEntrance ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateEntrance)
            
            // Interactive bracket visualization
            if tournament.type == "Double Elimination" {
                doubleEliminationBracket(geometry: geometry)
            } else if tournament.type == "Round Robin" {
                roundRobinBracket
            } else {
                singleEliminationBracket(geometry: geometry)
            }
        }
        .padding(40)
        .padding(.bottom, 120)
    }
    
    // MARK: - Enhanced Tournament Header
    
    private var enhancedTournamentHeader: some View {
        VStack(spacing: 24) {
            // Title with glow effect
            VStack(spacing: 12) {
                Text(tournament.name)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.5), radius: glowEffect ? 20 : 10)
                    .scaleEffect(glowEffect ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowEffect)
                
                HStack(spacing: 20) {
                    StatusPill(text: tournament.type, color: .blue)
                    StatusPill(text: tournament.format, color: .green)
                    StatusPill(text: tournament.status, color: statusColor)
                }
            }
            
            // Live tournament metrics
            LiveMetricsGrid(tournament: tournament)
        }
        .padding(32)
        .background(
            ZStack {
                // Glass morphism background
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                // Animated border
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        AngularGradient(
                            colors: [.blue, .purple, .blue],
                            center: .center
                        ),
                        lineWidth: 2
                    )
                    .rotationEffect(.degrees(glowEffect ? 360 : 0))
                    .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: glowEffect)
            }
        )
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - Double Elimination Bracket
    
    private func doubleEliminationBracket(geometry: GeometryProxy) -> some View {
        VStack(spacing: 80) {
            // Winners Bracket
            BracketSection(
                title: "Winners Bracket",
                icon: "crown.fill",
                color: .blue,
                rounds: winnersRounds,
                tournament: tournament,
                isEditMode: isEditMode,
                onMatchTap: handleMatchTap,
                onPlayerDrop: handlePlayerDrop,
                animateEntrance: animateEntrance
            )
            
            // Losers Bracket
            if !losersRounds.isEmpty {
                BracketSection(
                    title: "Losers Bracket",
                    icon: "arrow.triangle.2.circlepath",
                    color: .orange,
                    rounds: losersRounds,
                    tournament: tournament,
                    isEditMode: isEditMode,
                    onMatchTap: handleMatchTap,
                    onPlayerDrop: handlePlayerDrop,
                    animateEntrance: animateEntrance
                )
            }
            
            // Grand Final
            if let grandFinal = tournament.matches.first(where: { $0.round == 999 }) {
                GrandFinalSection(
                    match: grandFinal,
                    isEditMode: isEditMode,
                    onMatchTap: handleMatchTap,
                    onPlayerDrop: handlePlayerDrop,
                    animateEntrance: animateEntrance
                )
            }
        }
    }
    
    // MARK: - Single Elimination Bracket
    
    private func singleEliminationBracket(geometry: GeometryProxy) -> some View {
        BracketSection(
            title: "Tournament Bracket",
            icon: "trophy.fill",
            color: .gold,
            rounds: allRounds,
            tournament: tournament,
            isEditMode: isEditMode,
            onMatchTap: handleMatchTap,
            onPlayerDrop: handlePlayerDrop,
            animateEntrance: animateEntrance
        )
    }
    
    // MARK: - Round Robin Bracket
    
    private var roundRobinBracket: some View {
        VStack(spacing: 40) {
            Text("Round Robin Standings")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Interactive standings table
            RoundRobinStandingsView(
                tournament: tournament,
                isEditMode: isEditMode,
                onMatchTap: handleMatchTap
            )
        }
    }
    
    // MARK: - Floating Interface
    
    private var floatingInterface: some View {
        VStack {
            Spacer()
            
            HStack {
                // Left side controls
                VStack(spacing: 16) {
                    if isEditMode {
                        FloatingButton(
                            icon: "person.badge.plus",
                            color: .green,
                            size: 56
                        ) {
                            showingParticipantSelector = true
                        }
                        
                        FloatingButton(
                            icon: "shuffle",
                            color: .purple,
                            size: 56
                        ) {
                            shuffleBracket()
                        }
                    }
                }
                
                Spacer()
                
                // Right side controls
                VStack(spacing: 16) {
                    // Edit mode toggle
                    FloatingButton(
                        icon: isEditMode ? "lock.fill" : "pencil",
                        color: isEditMode ? .orange : .blue,
                        size: 64,
                        isPrimary: true
                    ) {
                        toggleEditMode()
                    }
                    
                    // Zoom controls
                    VStack(spacing: 8) {
                        FloatingButton(icon: "plus.magnifyingglass", color: .green) {
                            zoomIn()
                        }
                        
                        FloatingButton(icon: "minus.magnifyingglass", color: .green) {
                            zoomOut()
                        }
                    }
                    
                    // Reset view
                    FloatingButton(icon: "arrow.clockwise", color: .purple) {
                        resetView()
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Toolbar Controls
    
    private var toolbarControls: some View {
        HStack(spacing: 16) {
            Button {
                generateNewBracket()
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.white)
            }
            
            Button {
                exportBracket()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.white)
            }
            
            Button {
                shareToSocial()
            } label: {
                Image(systemName: "share")
                    .foregroundColor(.white)
            }
        }
    }
    
    // MARK: - Gestures
    
    private var bracketGestures: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { scale in
                    bracketScale = max(0.5, min(3.0, scale))
                },
            DragGesture()
                .onChanged { value in
                    bracketOffset = value.translation
                }
        )
    }
    
    // MARK: - Action Handlers
    
    private func setupBracket() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animateEntrance = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                glowEffect = true
            }
        }
        
        // Setup real-time Firebase listeners
        setupRealtimeListeners()
    }
    
    private func setupRealtimeListeners() {
        tournamentListener = appState.firebaseService.observeTournament(id: tournament.id.uuidString) { result in
            switch result {
            case .success(let updatedTournament):
                Task {
                    await MainActor.run {
                        let hasChanges = updatedTournament.matches.count != tournament.matches.count ||
                            updatedTournament.matches.contains { oldMatch in
                                guard let newMatch = tournament.matches.first(where: { $0.id == oldMatch.id }) else { return true }
                                return oldMatch.status != newMatch.status || oldMatch.finalScore != newMatch.finalScore
                            }
                        
                        if hasChanges {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                tournament = updatedTournament
                            }
                            
                            // Check for new match completions and trigger celebrations
                            checkForNewCompletions(updatedTournament)
                            
                            // Update connection animations
                            updateConnectionAnimations()
                            
                            // Haptic feedback for updates
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
                }
            case .failure(let error):
                print("❌ Tournament listener error: \(error)")
            }
        }
    }
    
    private func cleanupListeners() {
        tournamentListener?.remove()
        tournamentListener = nil
    }
    
    private func checkForNewCompletions(_ updatedTournament: Tournament) {
        // Check for newly completed matches and trigger celebrations
        let newlyCompletedMatches = updatedTournament.matches.filter { match in
            match.status == "Completed" && 
            !(tournament.matches.first(where: { $0.id == match.id })?.status == "Completed")
        }
        
        if !newlyCompletedMatches.isEmpty {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                showingConfetti = true
            }
            
            // Hide confetti after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut(duration: 1)) {
                    showingConfetti = false
                }
            }
        }
    }
    
    private func handleMatchTap(_ match: TournamentMatch) {
        selectedMatch = match
        showingMatchDetails = true
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func handlePlayerDrop(player: String, to match: TournamentMatch) {
        guard isEditMode else { return }
        
        withAnimation(.spring()) {
            // Update match with new player
            if let index = tournament.matches.firstIndex(where: { $0.id == match.id }) {
                var updatedMatch = tournament.matches[index]
                
                // Determine which slot to fill
                if updatedMatch.player1Name.isEmpty || updatedMatch.player1Name == "TBD" {
                    updatedMatch.player1Name = player
                    updatedMatch.player1ID = player
                } else if updatedMatch.player2Name.isEmpty || updatedMatch.player2Name == "TBD" {
                    updatedMatch.player2Name = player
                    updatedMatch.player2ID = player
                }
                
                // Update status if both players are assigned
                if !updatedMatch.player1Name.isEmpty && !updatedMatch.player2Name.isEmpty &&
                   updatedMatch.player1Name != "TBD" && updatedMatch.player2Name != "TBD" {
                    updatedMatch.status = "Ready"
                }
                
                tournament.matches[index] = updatedMatch
            }
        }
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        // Update connections
        updateConnectionAnimations()
    }
    
    private func handleScoreUpdate(match: TournamentMatch, score: String, winnerID: String) {
        withAnimation(.spring()) {
            if let index = tournament.matches.firstIndex(where: { $0.id == match.id }) {
                var updatedMatch = tournament.matches[index]
                updatedMatch.finalScore = score
                updatedMatch.winnerID = winnerID
                updatedMatch.status = "Completed"
                
                tournament.matches[index] = updatedMatch
                
                // Advance winner to next round
                advanceWinner(from: updatedMatch)
                
                // Check for tournament completion
                if isTournamentComplete() {
                    celebrateCompletion()
                }
            }
        }
        
        lastWinner = winnerID
        updateConnectionAnimations()
    }
    
    private func handlePlayerSwap(match: TournamentMatch) {
        guard isEditMode else { return }
        
        withAnimation(.spring()) {
            if let index = tournament.matches.firstIndex(where: { $0.id == match.id }) {
                var updatedMatch = tournament.matches[index]
                let tempName = updatedMatch.player1Name
                let tempID = updatedMatch.player1ID
                
                updatedMatch.player1Name = updatedMatch.player2Name
                updatedMatch.player1ID = updatedMatch.player2ID
                updatedMatch.player2Name = tempName
                updatedMatch.player2ID = tempID
                
                tournament.matches[index] = updatedMatch
            }
        }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func handlePlayerSelection(_ playerName: String) {
        draggedPlayer = playerName
        showingParticipantSelector = false
    }
    
    private func toggleEditMode() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isEditMode.toggle()
        }
        
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        // Visual feedback
        withAnimation(.easeInOut(duration: 0.3)) {
            pulseEffect.toggle()
        }
    }
    
    private func zoomIn() {
        withAnimation(.spring()) {
            bracketScale = min(3.0, bracketScale + 0.3)
        }
    }
    
    private func zoomOut() {
        withAnimation(.spring()) {
            bracketScale = max(0.5, bracketScale - 0.3)
        }
    }
    
    private func resetView() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
            bracketScale = 1.0
            bracketOffset = .zero
        }
    }
    
    private func shuffleBracket() {
        guard isEditMode else { return }
        
        withAnimation(.spring()) {
            // Shuffle participants in first round matches
            var firstRoundMatches = tournament.matches.filter { $0.round == 1 }
            let players = firstRoundMatches.flatMap { [$0.player1Name, $0.player2Name] }
                .filter { !$0.isEmpty && $0 != "TBD" }
                .shuffled()
            
            var playerIndex = 0
            for i in firstRoundMatches.indices {
                if playerIndex < players.count {
                    firstRoundMatches[i].player1Name = players[playerIndex]
                    playerIndex += 1
                }
                if playerIndex < players.count {
                    firstRoundMatches[i].player2Name = players[playerIndex]
                    playerIndex += 1
                }
            }
            
            // Update tournament
            for match in firstRoundMatches {
                if let index = tournament.matches.firstIndex(where: { $0.id == match.id }) {
                    tournament.matches[index] = match
                }
            }
        }
        
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    private func generateNewBracket() {
        // Generate a new bracket structure
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func exportBracket() {
        // Export bracket as image or PDF
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func shareToSocial() {
        // Share bracket to social media
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func advanceWinner(from match: TournamentMatch) {
        // Find next match for winner
        let nextRound = match.round + 1
        
        if let nextMatch = tournament.matches.first(where: { nextMatch in
            nextMatch.bracket == match.bracket &&
            nextMatch.round == nextRound &&
            (nextMatch.player1Name.isEmpty || nextMatch.player1Name == "TBD" ||
             nextMatch.player2Name.isEmpty || nextMatch.player2Name == "TBD")
        }) {
            
            if let index = tournament.matches.firstIndex(where: { $0.id == nextMatch.id }) {
                var updatedMatch = tournament.matches[index]
                let winnerName = match.winnerID == match.player1ID ? match.player1Name : match.player2Name
                
                if updatedMatch.player1Name.isEmpty || updatedMatch.player1Name == "TBD" {
                    updatedMatch.player1Name = winnerName
                    updatedMatch.player1ID = match.winnerID ?? ""
                } else {
                    updatedMatch.player2Name = winnerName
                    updatedMatch.player2ID = match.winnerID ?? ""
                }
                
                // Update status if both players are now assigned
                if !updatedMatch.player1Name.isEmpty && !updatedMatch.player2Name.isEmpty &&
                   updatedMatch.player1Name != "TBD" && updatedMatch.player2Name != "TBD" {
                    updatedMatch.status = "Ready"
                }
                
                tournament.matches[index] = updatedMatch
            }
        }
    }
    
    private func isTournamentComplete() -> Bool {
        // Check if tournament is complete
        if tournament.type == "Double Elimination" {
            return tournament.matches.first(where: { $0.round == 999 })?.status == "Completed"
        } else {
            let finalRound = tournament.matches.map { $0.round }.max() ?? 0
            return tournament.matches.filter { $0.round == finalRound }.allSatisfy { $0.status == "Completed" }
        }
    }
    
    private func celebrateCompletion() {
        withAnimation(.spring()) {
            showingConfetti = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut) {
                showingConfetti = false
            }
        }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    
    private func updateConnectionAnimations() {
        // Animate connections between matches
        for match in tournament.matches {
            connectionAnimations[match.id] = match.status == "Completed"
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch tournament.status {
        case "Registration Open": return .green
        case "In Progress": return .blue
        case "Completed": return .purple
        default: return .gray
        }
    }
    
    private var winnersRounds: [Int] {
        let matches = tournament.matches.filter { $0.bracket == "Winners" && $0.round < 999 }
        return Array(Set(matches.map { $0.round })).sorted()
    }
    
    private var losersRounds: [Int] {
        let matches = tournament.matches.filter { $0.bracket == "Losers" }
        return Array(Set(matches.map { $0.round })).sorted()
    }
    
    private var allRounds: [Int] {
        let matches = tournament.matches.filter { $0.round < 999 }
        return Array(Set(matches.map { $0.round })).sorted()
    }
}

// MARK: - Supporting Views and Extensions

extension Color {
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

#Preview {
    let sampleTournament = Tournament(
        name: "Championship Finals",
        description: "Advanced interactive tournament bracket",
        type: "Double Elimination",
        format: "Singles",
        skillLevel: "Professional",
        maxParticipants: 16,
        startDate: Date(),
        organizerID: "organizer1",
        organizerName: "Tournament Director"
    )
    
    AdvancedInteractiveBracketView(tournament: sampleTournament)
        .environmentObject(AppState())
}