import SwiftUI
import UniformTypeIdentifiers

struct InteractiveTournamentBracketView: View {
    @State private var tournament: Tournament

    @StateObject private var tournamentService = TournamentService(firebaseService: FirebaseService.shared)
    @EnvironmentObject private var appState: AppState
    
    // Drag and Drop State
    @State private var draggedMatch: TournamentMatch?
    @State private var draggedParticipant: TournamentParticipant?
    @State private var dropTargetMatch: TournamentMatch?
    @State private var isEditMode = false
    
    // Visual State
    @State private var selectedMatch: TournamentMatch?
    @State private var showingMatchDetails = false
    @State private var animateProgress = false
    @State private var selectedRound: Int?
    @State private var isLoading = true
    @State private var lastUpdateTime = Date()
    @State private var updateTimer: Timer?
    @State private var showingBracketSettings = false
    @State private var showingParticipantManager = false
    
    // Bracket Layout
    @State private var bracketScale: CGFloat = 1.0
    @State private var bracketOffset: CGSize = .zero
    @State private var showConnections = true
    @State private var animateConnections = true
    @State private var bracketLayoutMode: BracketLayoutMode = .traditional
    
    enum BracketLayoutMode: String, CaseIterable {
        case traditional = "Traditional"
        case compact = "Compact"
        case tree = "Tree View"
        case timeline = "Timeline"
        
        var icon: String {
            switch self {
            case .traditional: return "rectangle.grid.2x2"
            case .compact: return "rectangle.compress.vertical"
            case .tree: return "tree"
            case .timeline: return "timeline.selection"
            }
        }
    }
    
    init(tournament: Tournament) {
        self._tournament = State(initialValue: tournament)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background with subtle pattern
                backgroundView
                
                if isLoading {
                    loadingView
                } else {
                    mainContent(geometry: geometry)
                }
                
                // Floating controls
                floatingControls
            }
        }
        .navigationTitle("Interactive Bracket")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                toolbarButtons
            }
        }
        .sheet(isPresented: $showingMatchDetails) {
            if let match = selectedMatch {
                EnhancedMatchDetailsView(match: match, tournament: tournament)
                    .environmentObject(appState)
            }
        }
        .sheet(isPresented: $showingBracketSettings) {
            BracketSettingsView(
                layoutMode: $bracketLayoutMode,
                showConnections: $showConnections,
                animateConnections: $animateConnections
            )
        }
        .sheet(isPresented: $showingParticipantManager) {
            ParticipantManagerView(tournament: $tournament)
                .environmentObject(appState)
        }
        .onAppear {
            setupView()
        }
        .onDisappear {
            cleanup()
        }
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        ZStack {
            // Base background
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground).opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern overlay
            if bracketLayoutMode != .timeline {
                BracketPatternView()
                    .opacity(0.1)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.2), .blue.opacity(0.05)],
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
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(animateProgress ? 360 : 0))
                    .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: animateProgress)
            }
            
            VStack(spacing: 8) {
                Text("Loading Interactive Bracket")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Preparing tournament visualization...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .transition(.opacity)
        .onAppear {
            animateProgress = true
        }
    }
    
    // MARK: - Main Content
    
    private func mainContent(geometry: GeometryProxy) -> some View {
        ScrollView([.horizontal, .vertical], showsIndicators: false) {
            ZStack {
                // Bracket connections
                if showConnections {
                    bracketConnectionsView
                        .opacity(animateConnections ? 1.0 : 0.3)
                }
                
                // Main bracket content
                VStack(spacing: 40) {
                    // Tournament header with enhanced info
                    enhancedTournamentHeader
                        .transition(.move(edge: .top).combined(with: .opacity))
                    
                    // Bracket layout based on selected mode
                    Group {
                        switch bracketLayoutMode {
                        case .traditional:
                            traditionalBracketLayout
                        case .compact:
                            compactBracketLayout
                        case .tree:
                            treeBracketLayout
                        case .timeline:
                            timelineBracketLayout
                        }
                    }
                    .scaleEffect(bracketScale)
                    .offset(bracketOffset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { scale in
                                    bracketScale = max(0.5, min(2.0, scale))
                                },
                            DragGesture()
                                .onChanged { value in
                                    bracketOffset = value.translation
                                }
                        )
                    )
                }
                .padding()
                .padding(.bottom, 100)
            }
        }
        .clipped()
    }
    
    // MARK: - Enhanced Tournament Header
    
    private var enhancedTournamentHeader: some View {
        VStack(spacing: 20) {
            // Title and status
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(tournament.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        Label(tournament.format, systemImage: "sportscourt")
                            .font(.title3)
                            .foregroundColor(.blue)
                        
                        Label(tournament.type, systemImage: "trophy")
                            .font(.title3)
                            .foregroundColor(.orange)
                        
                        Spacer()
                        
                        // Live indicator
                        if tournament.status == "In Progress" {
                            liveIndicator
                        }
                    }
                }
                
                Spacer()
                
                // Enhanced progress ring
                enhancedProgressRing
            }
            
            // Interactive tournament stats
            interactiveTournamentStats
            
            // Bracket progress visualization
            if tournament.status == "In Progress" {
                bracketProgressVisualization
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
                                colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private var liveIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
                .scaleEffect(animateProgress ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateProgress)
            
            Text("LIVE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.red)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.red.opacity(0.1))
                .overlay(
                    Capsule()
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private var enhancedProgressRing: some View {
        let completedMatches = tournament.matches.filter { $0.status == "Completed" }.count
        let totalMatches = tournament.matches.count
        let progress = totalMatches > 0 ? Double(completedMatches) / Double(totalMatches) : 0
        
        return ZStack {
            // Background rings
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)
            
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 4)
                .frame(width: 60, height: 60)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animateProgress ? progress : 0)
                .stroke(
                    AngularGradient(
                        colors: [.blue, .purple, .blue],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.5).delay(0.5), value: animateProgress)
            
            // Center content
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .contentTransition(.numericText())
                    .animation(.easeOut(duration: 1).delay(0.8), value: progress)
                
                Text("%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var interactiveTournamentStats: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            InteractiveStatCard(
                title: "Players",
                value: "\(tournament.registeredCount)",
                icon: "person.2.fill",
                color: .blue,
                trend: .stable
            ) {
                showingParticipantManager = true
            }
            
            let completedMatches = tournament.matches.filter { $0.status == "Completed" }.count
            InteractiveStatCard(
                title: "Matches",
                value: "\(tournament.matches.count)",
                icon: "gamecontroller.fill",
                color: .green,
                trend: .up
            ) {
                // Show matches overview
            }
            
            InteractiveStatCard(
                title: "Completed",
                value: "\(completedMatches)",
                icon: "checkmark.circle.fill",
                color: .purple,
                trend: .up
            ) {
                // Filter to completed matches
            }
            
            InteractiveStatCard(
                title: "Remaining",
                value: "\(tournament.matches.count - completedMatches)",
                icon: "clock.fill",
                color: .orange,
                trend: .down
            ) {
                // Show upcoming matches
            }
        }
    }
    
    private var bracketProgressVisualization: some View {
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
                    AnimatedProgressBar(
                        title: "Winners Bracket",
                        progress: winnersProgress,
                        completed: winnersCompleted,
                        total: winnersMatches.count,
                        color: .blue,
                        animated: animateProgress
                    )
                    
                    // Losers bracket progress
                    AnimatedProgressBar(
                        title: "Losers Bracket",
                        progress: losersProgress,
                        completed: losersCompleted,
                        total: losersMatches.count,
                        color: .orange,
                        animated: animateProgress
                    )
                }
            } else {
                AnimatedProgressBar(
                    title: "Overall Progress",
                    progress: progress,
                    completed: completedMatches,
                    total: totalMatches,
                    color: .green,
                    animated: animateProgress
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.quaternary, lineWidth: 1)
                )
        )
    }
    
    // MARK: - Bracket Layouts
    
    private var traditionalBracketLayout: some View {
        VStack(spacing: 32) {
            // Winners bracket
            if !winnersRounds.isEmpty {
                DraggableBracketSection(
                    title: "Winners Bracket",
                    rounds: winnersRounds,
                    bracket: "Winners",
                    color: .blue,
                    tournament: tournament,
                    isEditMode: isEditMode,
                    onMatchDrop: handleMatchDrop,
                    onMatchTap: { match in
                        selectedMatch = match
                        showingMatchDetails = true
                    }
                )
            }
            
            // Losers bracket
            if tournament.type == "Double Elimination" && !losersRounds.isEmpty {
                DraggableBracketSection(
                    title: "Losers Bracket",
                    rounds: losersRounds,
                    bracket: "Losers",
                    color: .orange,
                    tournament: tournament,
                    isEditMode: isEditMode,
                    onMatchDrop: handleMatchDrop,
                    onMatchTap: { match in
                        selectedMatch = match
                        showingMatchDetails = true
                    }
                )
            }
            
            // Grand final
            if let grandFinalMatch = tournament.matches.first(where: { $0.round == 999 }) {
                DraggableGrandFinalSection(
                    match: grandFinalMatch,
                    isEditMode: isEditMode,
                    onMatchDrop: handleMatchDrop,
                    onMatchTap: { match in
                        selectedMatch = match
                        showingMatchDetails = true
                    }
                )
            }
        }
    }
    
    private var compactBracketLayout: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3), spacing: 20) {
            ForEach(tournament.matches.sorted(by: { $0.round < $1.round })) { match in
                DraggableMatchCard(
                    match: match,
                    compact: true,
                    isEditMode: isEditMode,
                    onDrop: { droppedMatch in
                        handleMatchDrop(droppedMatch, to: match)
                    },
                    onTap: {
                        selectedMatch = match
                        showingMatchDetails = true
                    }
                )
            }
        }
    }
    
    private var treeBracketLayout: some View {
        TreeBracketView(
            tournament: tournament,
            isEditMode: isEditMode,
            onMatchDrop: handleMatchDrop,
            onMatchTap: { match in
                selectedMatch = match
                showingMatchDetails = true
            }
        )
    }
    
    private var timelineBracketLayout: some View {
        TimelineBracketView(
            tournament: tournament,
            isEditMode: isEditMode,
            onMatchDrop: handleMatchDrop,
            onMatchTap: { match in
                selectedMatch = match
                showingMatchDetails = true
            }
        )
    }
    
    // MARK: - Bracket Connections
    
    private var bracketConnectionsView: some View {
        Canvas { context, size in
            drawBracketConnections(context: context, size: size)
        }
        .allowsHitTesting(false)
    }
    
    private func drawBracketConnections(context: GraphicsContext, size: CGSize) {
        // Draw connection lines between matches
        let path = Path { path in
            // Implementation for drawing bracket connections
            // This would connect parent matches to child matches
            for match in tournament.matches {
                if let parentMatches = getParentMatches(for: match) {
                    for parentMatch in parentMatches {
                        let startPoint = getMatchPosition(parentMatch, in: size)
                        let endPoint = getMatchPosition(match, in: size)
                        
                        path.move(to: startPoint)
                        path.addQuadCurve(
                            to: endPoint,
                            control: CGPoint(
                                x: (startPoint.x + endPoint.x) / 2,
                                y: startPoint.y
                            )
                        )
                    }
                }
            }
        }
        
        context.stroke(
            path,
            with: .color(.blue.opacity(0.3)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
    }
    
    // MARK: - Floating Controls
    
    private var floatingControls: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 16) {
                    // Edit mode toggle
                    FloatingActionButton(
                        icon: isEditMode ? "lock.fill" : "pencil",
                        color: isEditMode ? .orange : .blue,
                        action: {
                            withAnimation(.spring()) {
                                isEditMode.toggle()
                            }
                        }
                    )
                    
                    // Zoom controls
                    VStack(spacing: 8) {
                        FloatingActionButton(
                            icon: "plus.magnifyingglass",
                            color: .green,
                            action: {
                                withAnimation(.spring()) {
                                    bracketScale = min(2.0, bracketScale + 0.2)
                                }
                            }
                        )
                        
                        FloatingActionButton(
                            icon: "minus.magnifyingglass",
                            color: .green,
                            action: {
                                withAnimation(.spring()) {
                                    bracketScale = max(0.5, bracketScale - 0.2)
                                }
                            }
                        )
                    }
                    
                    // Reset view
                    FloatingActionButton(
                        icon: "arrow.clockwise",
                        color: .purple,
                        action: {
                            withAnimation(.spring()) {
                                bracketScale = 1.0
                                bracketOffset = .zero
                            }
                        }
                    )
                }
            }
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Toolbar
    
    private var toolbarButtons: some View {
        HStack {
            Button {
                showingBracketSettings = true
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            
            Button {
                Task {
                    await refreshTournamentData()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            
            Menu {
                ForEach(BracketLayoutMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation(.spring()) {
                            bracketLayoutMode = mode
                        }
                    } label: {
                        Label(mode.rawValue, systemImage: mode.icon)
                    }
                }
            } label: {
                Image(systemName: bracketLayoutMode.icon)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                isLoading = false
                animateProgress = true
            }
        }
        startLiveUpdates()
    }
    
    private func cleanup() {
        stopLiveUpdates()
    }
    
    private func startLiveUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            Task {
                await refreshTournamentData()
            }
        }
    }
    
    private func stopLiveUpdates() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func refreshTournamentData() async {
        do {
            let updatedTournament = try await tournamentService.getTournament(id: tournament.id.uuidString)
            
            await MainActor.run {
                let hasChanges = tournament.matches.count != updatedTournament.matches.count ||
                    tournament.matches.contains { oldMatch in
                        guard let newMatch = updatedTournament.matches.first(where: { $0.id == oldMatch.id }) else { return true }
                        return oldMatch.status != newMatch.status || oldMatch.finalScore != newMatch.finalScore
                    }
                
                if hasChanges {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        tournament = updatedTournament
                        lastUpdateTime = Date()
                    }
                    
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        } catch {
            print("Failed to refresh tournament data: \(error)")
        }
    }
    
    private func handleMatchDrop(_ droppedMatch: TournamentMatch, to targetMatch: TournamentMatch) {
        guard isEditMode else { return }
        
        // Implement match reordering or participant swapping logic
        withAnimation(.spring()) {
            // Update tournament structure
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func getParentMatches(for match: TournamentMatch) -> [TournamentMatch]? {
        // Implementation to find parent matches in the bracket
        return nil
    }
    
    private func getMatchPosition(_ match: TournamentMatch, in size: CGSize) -> CGPoint {
        // Calculate position of match in the bracket layout
        return CGPoint(x: size.width / 2, y: size.height / 2)
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
}

// MARK: - Supporting Views

struct BracketPatternView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let spacing: CGFloat = 50
                let rows = Int(geometry.size.height / spacing) + 1
                let cols = Int(geometry.size.width / spacing) + 1
                
                for row in 0..<rows {
                    for col in 0..<cols {
                        let x = CGFloat(col) * spacing
                        let y = CGFloat(row) * spacing
                        
                        path.addEllipse(in: CGRect(x: x, y: y, width: 2, height: 2))
                    }
                }
            }
            .fill(.quaternary)
        }
    }
}

struct InteractiveStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection
    let action: () -> Void
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .gray
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    
                    Spacer()
                    
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                    
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AnimatedProgressBar: View {
    let title: String
    let progress: Double
    let completed: Int
    let total: Int
    let color: Color
    let animated: Bool
    
    var body: some View {
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
                    .contentTransition(.numericText())
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
                        .frame(width: geometry.size.width * (animated ? progress : 0), height: 8)
                        .clipShape(Capsule())
                        .animation(.easeOut(duration: 1).delay(0.3), value: animated)
                        .overlay(
                            // Shimmer effect
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [.clear, .white.opacity(0.3), .clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .clipShape(Capsule())
                                .offset(x: animated ? geometry.size.width : -geometry.size.width)
                                .animation(
                                    .linear(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(1),
                                    value: animated
                                )
                        )
                }
            }
            .frame(height: 8)
        }
    }
}

struct FloatingActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color)
                        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let sampleTournament = Tournament(
        name: "Interactive Championship",
        description: "A sample tournament with drag-and-drop functionality",
        type: "Double Elimination",
        format: "Singles",
        skillLevel: "Intermediate",
        maxParticipants: 16,
        startDate: Date(),
        organizerID: "organizer1",
        organizerName: "Tournament Director"
    )
    
    InteractiveTournamentBracketView(tournament: sampleTournament)
        .environmentObject(AppState())
} 