import SwiftUI
import UniformTypeIdentifiers

// MARK: - Draggable Bracket Section

struct DraggableBracketSection: View {
    let title: String
    let rounds: [Int]
    let bracket: String
    let color: Color
    let tournament: Tournament
    let isEditMode: Bool
    let onMatchDrop: (TournamentMatch, TournamentMatch) -> Void
    let onMatchTap: (TournamentMatch) -> Void
    
    @State private var selectedRound: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Section header
            HStack {
                Image(systemName: bracket == "Winners" ? "trophy.fill" : "arrow.triangle.2.circlepath")
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                
                Spacer()
                
                if isEditMode {
                    Text("EDIT MODE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.orange.opacity(0.2))
                        )
                }
            }
            
            // Rounds scroll view
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 40) {
                    ForEach(Array(rounds.enumerated()), id: \.element) { index, round in
                        DraggableRoundColumn(
                            round: round,
                            bracket: bracket,
                            tournament: tournament,
                            isEditMode: isEditMode,
                            color: color,
                            onMatchDrop: onMatchDrop,
                            onMatchTap: onMatchTap
                        )
                        .scaleEffect(selectedRound == round ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedRound)
                    }
                }
                .padding(.horizontal, 20)
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
                                colors: [color.opacity(0.3), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: color.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Draggable Round Column

struct DraggableRoundColumn: View {
    let round: Int
    let bracket: String
    let tournament: Tournament
    let isEditMode: Bool
    let color: Color
    let onMatchDrop: (TournamentMatch, TournamentMatch) -> Void
    let onMatchTap: (TournamentMatch) -> Void
    
    private var roundMatches: [TournamentMatch] {
        tournament.matches
            .filter { $0.bracket == bracket && $0.round == round }
            .sorted { $0.matchNumber < $1.matchNumber }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Round header
            VStack(spacing: 8) {
                Text(roundTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                
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
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Matches in round
            VStack(spacing: 16) {
                ForEach(roundMatches) { match in
                    DraggableMatchCard(
                        match: match,
                        isEditMode: isEditMode,
                        onDrop: { droppedMatch in
                            onMatchDrop(droppedMatch, match)
                        },
                        onTap: {
                            onMatchTap(match)
                        }
                    )
                }
            }
        }
        .frame(minWidth: 200)
    }
    
    private var roundTitle: String {
        if bracket == "Winners" {
            return "Round \(round)"
        } else if bracket == "Losers" {
            return "LR \(round)"
        } else {
            return "R\(round)"
        }
    }
}

// MARK: - Draggable Grand Final Section

struct DraggableGrandFinalSection: View {
    let match: TournamentMatch
    let isEditMode: Bool
    let onMatchDrop: (TournamentMatch, TournamentMatch) -> Void
    let onMatchTap: (TournamentMatch) -> Void
    
    @State private var animateGlow = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Grand final header
            HStack {
                Image(systemName: "crown.fill")
                    .font(.title)
                    .foregroundColor(.yellow)
                    .scaleEffect(animateGlow ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateGlow)
                
                Text("Grand Final")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                
                Spacer()
                
                if isEditMode {
                    Text("CHAMPIONSHIP")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.purple.opacity(0.2))
                        )
                }
            }
            
            // Grand final match
            DraggableMatchCard(
                match: match,
                isGrandFinal: true,
                isEditMode: isEditMode,
                onDrop: { droppedMatch in
                    onMatchDrop(droppedMatch, match)
                },
                onTap: {
                    onMatchTap(match)
                }
            )
            .scaleEffect(1.1)
            
            // Championship rules
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
        .onAppear {
            animateGlow = true
        }
    }
}

// MARK: - Enhanced Draggable Match Card

struct DraggableMatchCard: View {
    let match: TournamentMatch
    var compact: Bool = false
    var isGrandFinal: Bool = false
    let isEditMode: Bool
    let onDrop: (TournamentMatch) -> Void
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var isDropTarget = false
    @State private var showingDetails = false
    
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
                
                // Edit mode indicators
                if isEditMode {
                    editModeIndicators
                }
            }
            .padding(compact ? 12 : 16)
            .frame(width: compact ? 160 : (isGrandFinal ? 240 : 200))
            .frame(minHeight: compact ? 100 : (isGrandFinal ? 180 : 140))
            .background(backgroundStyle)
            .overlay(borderStyle)
            .scaleEffect(isPressed ? 0.95 : (isDragging ? 1.05 : 1.0))
            .offset(dragOffset)
            .opacity(isDragging ? 0.8 : 1.0)
            .overlay(
                // Drop target indicator
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.blue, lineWidth: 3)
                    .opacity(isDropTarget ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: isDropTarget)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: dragOffset)
        .onLongPressGesture(minimumDuration: 0) {
            // Empty onChanged
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
        .draggable(match) {
            // Drag preview
            dragPreview
        }
        .dropDestination(for: TournamentMatch.self) { droppedMatches, location in
            guard let droppedMatch = droppedMatches.first else { return false }
            onDrop(droppedMatch)
            return true
        } isTargeted: { targeted in
            isDropTarget = targeted
        }
        .gesture(
            isEditMode ? 
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                    isDragging = true
                }
                .onEnded { _ in
                    withAnimation(.spring()) {
                        dragOffset = .zero
                        isDragging = false
                    }
                } : nil
        )
    }
    
    private var dragPreview: some View {
        VStack(spacing: 8) {
            Text(matchDisplayName)
                .font(.caption)
                .fontWeight(.bold)
            
            Text("\(match.player1Name) vs \(match.player2Name)")
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue, lineWidth: 2)
                )
        )
        .shadow(radius: 8)
    }
    
    private var matchDisplayName: String {
        if match.bracket == "Winners" {
            return "WR\(match.round)-\(match.matchNumber)"
        } else if match.bracket == "Losers" {
            return "LR\(match.round)-\(match.matchNumber)"
        } else if match.bracket == "Grand Final" {
            return "GRAND FINAL"
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
    
    private var editModeIndicators: some View {
        HStack(spacing: 8) {
            Image(systemName: "hand.draw")
                .font(.caption2)
                .foregroundColor(.blue)
            
            Text("Draggable")
                .font(.caption2)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.blue.opacity(0.1))
        )
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
            .stroke(strokeGradient, lineWidth: borderWidth)
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
        } else if isEditMode {
            return AnyShapeStyle(.blue.opacity(0.5))
        } else {
            return AnyShapeStyle(Color.gray.opacity(0.2))
        }
    }
    
    private var borderWidth: CGFloat {
        if isGrandFinal {
            return 2
        } else if isEditMode {
            return 2
        } else {
            return 1
        }
    }
}

// MARK: - Tree Bracket View

struct TreeBracketView: View {
    let tournament: Tournament
    let isEditMode: Bool
    let onMatchDrop: (TournamentMatch, TournamentMatch) -> Void
    let onMatchTap: (TournamentMatch) -> Void
    
    @State private var animateNodes = false
    @State private var selectedPath: [UUID] = []
    @State private var expandedNodes: Set<UUID> = []
    
    private var treeData: BracketTreeNode {
        generateTreeStructure()
    }
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            VStack(spacing: 40) {
                // Tree header
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "tree.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        
                        Text("Tournament Tree")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        if isEditMode {
                            Button("Reset Layout") {
                                withAnimation(.spring()) {
                                    resetTreeLayout()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Text("Navigate the tournament progression from participants to champion")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                // Tree visualization
                GeometryReader { geometry in
                    ZStack {
                        // Connection lines
                        TreeConnectionsView(
                            treeData: treeData,
                            geometry: geometry,
                            selectedPath: selectedPath,
                            animate: animateNodes
                        )
                        
                        // Tree nodes
                        TreeNodesView(
                            treeData: treeData,
                            geometry: geometry,
                            isEditMode: isEditMode,
                            selectedPath: selectedPath,
                            expandedNodes: expandedNodes,
                            onMatchTap: { match in
                                highlightPath(to: match)
                                onMatchTap(match)
                            },
                            onMatchDrop: onMatchDrop,
                            animate: animateNodes
                        )
                    }
                }
                .frame(
                    width: max(800, CGFloat(maxDepth * 200)),
                    height: max(600, CGFloat(maxNodes * 100))
                )
            }
            .padding(40)
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                animateNodes = true
            }
            
            // Auto-expand important nodes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                autoExpandNodes()
            }
        }
    }
    
    private func generateTreeStructure() -> BracketTreeNode {
        // Generate tree structure based on tournament matches
        let finalMatch = tournament.matches.first { $0.round == 999 } ??
                        tournament.matches.max { $0.round < $1.round }
        
        if let finalMatch = finalMatch {
            return buildTreeNode(for: finalMatch, depth: 0)
        } else {
            // Fallback for tournaments without matches
            return BracketTreeNode(
                match: nil,
                position: CGPoint(x: 400, y: 300),
                depth: 0,
                children: []
            )
        }
    }
    
    private func buildTreeNode(for match: TournamentMatch, depth: Int) -> BracketTreeNode {
        let position = calculateNodePosition(match: match, depth: depth)
        let parentMatches = findParentMatches(for: match)
        
        let children = parentMatches.map { parentMatch in
            buildTreeNode(for: parentMatch, depth: depth + 1)
        }
        
        return BracketTreeNode(
            match: match,
            position: position,
            depth: depth,
            children: children
        )
    }
    
    private func calculateNodePosition(match: TournamentMatch, depth: Int) -> CGPoint {
        let baseX = CGFloat(depth * 200)
        let baseY = CGFloat(match.matchNumber * 80 + depth * 40)
        
        return CGPoint(x: baseX, y: baseY)
    }
    
    private func findParentMatches(for match: TournamentMatch) -> [TournamentMatch] {
        // Find matches that feed into this match
        return tournament.matches.compactMap { parentMatch in
            let isParent = parentMatch.round == match.round - 1
            // Note: Using simplified logic since winnerAdvancesTo/loserAdvancesTo aren't in the model
            return isParent ? parentMatch : nil
        }
    }
    
    private func highlightPath(to match: TournamentMatch) {
        withAnimation(.easeInOut(duration: 0.5)) {
            selectedPath = generatePathToMatch(match)
        }
        
        // Clear highlight after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.3)) {
                selectedPath = []
            }
        }
    }
    
    private func generatePathToMatch(_ match: TournamentMatch) -> [UUID] {
        var path: [UUID] = [match.id]
        var currentMatch = match
        
        while let parentMatch = findParentMatches(for: currentMatch).first {
            path.append(parentMatch.id)
            currentMatch = parentMatch
        }
        
        return path.reversed()
    }
    
    private func resetTreeLayout() {
        expandedNodes.removeAll()
        selectedPath.removeAll()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            autoExpandNodes()
        }
    }
    
    private func autoExpandNodes() {
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            // Expand completed matches and current round
            let completedMatches = tournament.matches.filter { $0.status == "Completed" }
            let currentRoundMatches = tournament.matches.filter { $0.status == "In Progress" || $0.status == "Ready" }
            
            expandedNodes = Set(completedMatches.map { $0.id } + currentRoundMatches.map { $0.id })
        }
    }
    
    private var maxDepth: Int {
        calculateMaxDepth(treeData)
    }
    
    private var maxNodes: Int {
        tournament.matches.count / 2 + 1
    }
    
    private func calculateMaxDepth(_ node: BracketTreeNode) -> Int {
        if node.children.isEmpty {
            return node.depth
        }
        return max(node.depth, node.children.map { calculateMaxDepth($0) }.max() ?? 0)
    }
}

// MARK: - Timeline Bracket View

struct TimelineBracketView: View {
    let tournament: Tournament
    let isEditMode: Bool
    let onMatchDrop: (TournamentMatch, TournamentMatch) -> Void
    let onMatchTap: (TournamentMatch) -> Void
    
    @State private var animateTimeline = false
    @State private var selectedTimeframe: TimeFrame = .tournament
    @State private var autoScroll = true
    @State private var currentTime = Date()
    @State private var showingPredictions = true
    @State private var highlightedMatches: Set<UUID> = []
    
    enum TimeFrame: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case tournament = "Full Tournament"
        
        var icon: String {
            switch self {
            case .today: return "clock"
            case .week: return "calendar.badge.clock"
            case .tournament: return "calendar.circle"
            }
        }
    }
    
    private var timelineData: [TimelineEvent] {
        generateTimelineEvents()
    }
    
    private var filteredEvents: [TimelineEvent] {
        switch selectedTimeframe {
        case .today:
            return timelineData.filter { Calendar.current.isDate($0.date, inSameDayAs: currentTime) }
        case .week:
            let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: currentTime) ?? currentTime
            let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: currentTime) ?? currentTime
            return timelineData.filter { $0.date >= weekAgo && $0.date <= weekFromNow }
        case .tournament:
            return timelineData
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Timeline header with controls
            timelineHeader
            
            Divider()
            
            // Timeline visualization
            ScrollViewReader { proxy in
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredEvents.enumerated()), id: \.element.id) { index, event in
                            TimelineEventView(
                                event: event,
                                isLast: index == filteredEvents.count - 1,
                                isHighlighted: highlightedMatches.contains(event.matchID ?? UUID()),
                                showPredictions: showingPredictions,
                                animate: animateTimeline,
                                onEventTap: { handleEventTap(event) },
                                onMatchDrop: isEditMode ? { droppedMatch in
                                    if let targetMatch = event.match {
                                        onMatchDrop(droppedMatch, targetMatch)
                                    }
                                } : nil
                            )
                            .scaleEffect(animateTimeline ? 1.0 : 0.9)
                            .opacity(animateTimeline ? 1.0 : 0.0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.1),
                                value: animateTimeline
                            )
                        }
                    }
                    .padding(.vertical, 20)
                }
                .onAppear {
                    withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
                        animateTimeline = true
                    }
                    
                    if autoScroll {
                        scrollToCurrentTime(proxy: proxy)
                    }
                }
                .onChange(of: selectedTimeframe) { _, _ in
                    if autoScroll {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            scrollToCurrentTime(proxy: proxy)
                        }
                    }
                }
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
        )
        .onAppear {
            startTimeUpdates()
        }
    }
    
    private var timelineHeader: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tournament Timeline")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Track tournament progress over time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Current time indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text("NOW")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text(currentTime, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.red.opacity(0.1))
                        .stroke(.red.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Timeline controls
            HStack(spacing: 16) {
                // Timeframe selector
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                        HStack {
                            Image(systemName: timeframe.icon)
                            Text(timeframe.rawValue)
                        }
                        .tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                
                Spacer()
                
                // Toggle controls
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring()) {
                            showingPredictions.toggle()
                        }
                    } label: {
                        Image(systemName: showingPredictions ? "brain.head.profile.fill" : "brain.head.profile")
                            .foregroundColor(showingPredictions ? .blue : .secondary)
                    }
                    .buttonStyle(.bordered)
                    
                    Button {
                        withAnimation(.spring()) {
                            autoScroll.toggle()
                        }
                    } label: {
                        Image(systemName: autoScroll ? "location.fill" : "location")
                            .foregroundColor(autoScroll ? .green : .secondary)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(20)
    }
    
    private func generateTimelineEvents() -> [TimelineEvent] {
        var events: [TimelineEvent] = []
        
        // Add tournament start event
        events.append(TimelineEvent(
            id: UUID(),
            date: tournament.startDate,
            type: .tournamentStart,
            title: "Tournament Begins",
            description: "\(tournament.name) registration closes and play begins",
            match: nil,
            matchID: nil,
            status: tournament.startDate < currentTime ? .completed : .upcoming
        ))
        
        // Add match events
        let sortedMatches = tournament.matches.sorted(by: { match1, match2 in
            let time1 = match1.scheduledTime ?? Date()
            let time2 = match2.scheduledTime ?? Date()
            return time1 < time2
        })
        
        for match in sortedMatches {
            let matchDate = match.scheduledTime ?? estimateMatchTime(for: match)
            
            events.append(TimelineEvent(
                id: UUID(),
                date: matchDate,
                type: .match,
                title: getMatchTitle(match),
                description: getMatchDescription(match),
                match: match,
                matchID: match.id,
                status: getMatchStatus(match, at: matchDate)
            ))
            
            // Add match completion event if completed
            if match.status == "Completed" {
                let completedTime = match.scheduledTime ?? estimateMatchTime(for: match)
                let winnerName = match.winnerID != nil ? getWinnerName(match) : "TBD"
                events.append(TimelineEvent(
                    id: UUID(),
                    date: completedTime.addingTimeInterval(45 * 60), // Estimated match duration
                    type: .matchCompleted,
                    title: "\(getMatchTitle(match)) Completed",
                    description: "Winner: \(winnerName)",
                    match: match,
                    matchID: match.id,
                    status: .completed
                ))
            }
        }
        
        // Add tournament completion event (predicted or actual)
        let completionDate = tournament.status == "Completed" ? 
            tournament.endDate :
            estimateTournamentCompletion()
        
        let championName = tournament.status == "Completed" ? 
            (tournament.champion?.effectiveName ?? "TBD") : 
            "TBD"
        
        events.append(TimelineEvent(
            id: UUID(),
            date: completionDate,
            type: .tournamentEnd,
            title: "Tournament Ends",
            description: tournament.status == "Completed" ? 
                "Champion: \(championName)" : 
                "Estimated completion time",
            match: nil,
            matchID: nil,
            status: tournament.status == "Completed" ? .completed : .predicted
        ))
        
        return events.sorted(by: { $0.date < $1.date })
    }
    
    private func getMatchTitle(_ match: TournamentMatch) -> String {
        if match.round == 999 {
            return "Grand Final"
        } else if match.bracket == "Winners" {
            return "Winners R\(match.round) M\(match.matchNumber)"
        } else if match.bracket == "Losers" {
            return "Losers R\(match.round) M\(match.matchNumber)"
        } else {
            return "Round \(match.round) Match \(match.matchNumber)"
        }
    }
    
    private func getMatchDescription(_ match: TournamentMatch) -> String {
        let player1 = match.player1Name.isEmpty ? "TBD" : match.player1Name
        let player2 = match.player2Name.isEmpty ? "TBD" : match.player2Name
        return "\(player1) vs \(player2)"
    }
    
    private func getWinnerName(_ match: TournamentMatch) -> String {
        guard let winnerID = match.winnerID else { return "TBD" }
        if winnerID == match.player1ID {
            return match.player1Name.isEmpty ? "TBD" : match.player1Name
        } else if winnerID == match.player2ID {
            return match.player2Name.isEmpty ? "TBD" : match.player2Name
        }
        return "TBD"
    }
    
    private func getMatchStatus(_ match: TournamentMatch, at date: Date) -> TimelineEvent.Status {
        switch match.status {
        case "Completed": return .completed
        case "In Progress": return .inProgress
        case "Ready": return date <= currentTime ? .ready : .upcoming
        default: return date <= currentTime ? .ready : .upcoming
        }
    }
    
    private func estimateMatchTime(for match: TournamentMatch) -> Date {
        // Estimate match time based on round and position
        let minutesPerMatch = 45.0 // Average match duration
        let matchesBeforeThis = tournament.matches.filter { otherMatch in
            otherMatch.round < match.round || (otherMatch.round == match.round && otherMatch.matchNumber < match.matchNumber)
        }.count
        
        let estimatedMinutes = Double(matchesBeforeThis) * minutesPerMatch
        return tournament.startDate.addingTimeInterval(estimatedMinutes * 60)
    }
    
    private func estimateTournamentCompletion() -> Date {
        let totalMatches = tournament.matches.count
        let avgMatchDuration = 45.0 * 60.0 // 45 minutes
        let estimatedDuration = Double(totalMatches) * avgMatchDuration
        
        return tournament.startDate.addingTimeInterval(estimatedDuration)
    }
    
    private func handleEventTap(_ event: TimelineEvent) {
        if let match = event.match {
            // Highlight related matches
            withAnimation(.easeInOut(duration: 0.3)) {
                highlightedMatches = Set([match.id])
            }
            
            // Clear highlight after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    highlightedMatches.removeAll()
                }
            }
            
            onMatchTap(match)
        }
    }
    
    private func scrollToCurrentTime(proxy: ScrollViewProxy) {
        // Find the event closest to current time
        if let nearestEvent = timelineData.min(by: { event1, event2 in
            abs(event1.date.timeIntervalSince(currentTime)) < abs(event2.date.timeIntervalSince(currentTime))
        }) {
            withAnimation(.easeInOut(duration: 1.0)) {
                proxy.scrollTo(nearestEvent.id, anchor: .center)
            }
        }
    }
    
    private func startTimeUpdates() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            currentTime = Date()
        }
    }
}

// MARK: - Supporting Data Structures

struct BracketTreeNode {
    let match: TournamentMatch?
    let position: CGPoint
    let depth: Int
    let children: [BracketTreeNode]
}

struct TimelineEvent: Identifiable {
    let id: UUID
    let date: Date
    let type: EventType
    let title: String
    let description: String
    let match: TournamentMatch?
    let matchID: UUID?
    let status: Status
    
    enum EventType {
        case tournamentStart
        case match
        case matchCompleted
        case roundCompleted
        case tournamentEnd
        
        var icon: String {
            switch self {
            case .tournamentStart: return "flag.fill"
            case .match: return "sportscourt.fill"
            case .matchCompleted: return "checkmark.circle.fill"
            case .roundCompleted: return "crown.fill"
            case .tournamentEnd: return "trophy.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .tournamentStart: return .green
            case .match: return .blue
            case .matchCompleted: return .orange
            case .roundCompleted: return .purple
            case .tournamentEnd: return .gold
            }
        }
    }
    
    enum Status {
        case completed
        case inProgress
        case ready
        case upcoming
        case predicted
        
        var color: Color {
            switch self {
            case .completed: return .green
            case .inProgress: return .orange
            case .ready: return .blue
            case .upcoming: return .gray
            case .predicted: return .purple.opacity(0.6)
            }
        }
    }
}

// MARK: - Tree Visualization Components

struct TreeConnectionsView: View {
    let treeData: BracketTreeNode
    let geometry: GeometryProxy
    let selectedPath: [UUID]
    let animate: Bool
    
    var body: some View {
        Canvas { context, size in
            drawTreeConnections(context: context, node: treeData, size: size)
        }
        .allowsHitTesting(false)
    }
    
    private func drawTreeConnections(context: GraphicsContext, node: BracketTreeNode, size: CGSize) {
        guard let match = node.match else { return }
        
        for child in node.children {
            guard let childMatch = child.match else { continue }
            
            let startPoint = node.position
            let endPoint = child.position
            
            // Draw connection line
            var path = Path()
            path.move(to: startPoint)
            
            // Create curved connection
            let midX = (startPoint.x + endPoint.x) / 2
            let controlPoint1 = CGPoint(x: midX, y: startPoint.y)
            let controlPoint2 = CGPoint(x: midX, y: endPoint.y)
            
            path.addCurve(to: endPoint, control1: controlPoint1, control2: controlPoint2)
            
            let isHighlighted = selectedPath.contains(match.id) && selectedPath.contains(childMatch.id)
            let strokeColor = isHighlighted ? Color.blue : Color.secondary.opacity(0.5)
            let lineWidth: CGFloat = isHighlighted ? 3.0 : 1.5
            
            context.stroke(path, with: .color(strokeColor), lineWidth: lineWidth)
            
            // Recursively draw child connections
            drawTreeConnections(context: context, node: child, size: size)
        }
    }
}

struct TreeNodesView: View {
    let treeData: BracketTreeNode
    let geometry: GeometryProxy
    let isEditMode: Bool
    let selectedPath: [UUID]
    let expandedNodes: Set<UUID>
    let onMatchTap: (TournamentMatch) -> Void
    let onMatchDrop: (TournamentMatch, TournamentMatch) -> Void
    let animate: Bool
    
    var body: some View {
        ZStack {
            renderTreeNodes(node: treeData)
        }
    }
    
    private func renderTreeNodes(node: BracketTreeNode) -> AnyView {
        return AnyView(
            Group {
                if let match = node.match {
                    TreeNodeView(
                        match: match,
                        position: node.position,
                        isExpanded: expandedNodes.contains(match.id),
                        isHighlighted: selectedPath.contains(match.id),
                        isEditMode: isEditMode,
                        onTap: { onMatchTap(match) },
                        onDrop: { droppedMatch in onMatchDrop(droppedMatch, match) },
                        animate: animate
                    )
                }
                
                ForEach(node.children.indices, id: \.self) { index in
                    renderTreeNodes(node: node.children[index])
                }
            }
        )
    }
}

struct TreeNodeView: View {
    let match: TournamentMatch
    let position: CGPoint
    let isExpanded: Bool
    let isHighlighted: Bool
    let isEditMode: Bool
    let onTap: () -> Void
    let onDrop: (TournamentMatch) -> Void
    let animate: Bool
    
    @State private var isHovered = false
    @State private var pulseEffect = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Match title
                Text(getMatchTitle())
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Players
                VStack(spacing: 4) {
                    if !match.player1Name.isEmpty {
                        Text(match.player1Name)
                            .font(.caption2)
                            .foregroundColor(match.winnerID == match.player1ID ? .green : .primary)
                            .lineLimit(1)
                    }
                    
                    if !match.player2Name.isEmpty {
                        Text(match.player2Name)
                            .font(.caption2)
                            .foregroundColor(match.winnerID == match.player2ID ? .green : .primary)
                            .lineLimit(1)
                    }
                }
                
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseEffect ? 1.2 : 1.0)
            }
            .padding(12)
            .frame(width: 120, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .stroke(
                        isHighlighted ? Color.blue : (isHovered ? Color.secondary : Color.clear),
                        lineWidth: isHighlighted ? 2 : 1
                    )
            )
            .scaleEffect(isExpanded ? 1.1 : 1.0)
            .shadow(radius: isHighlighted ? 8 : 4)
        }
        .buttonStyle(.plain)
        .position(position)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onAppear {
            if match.status == "Ready" || match.status == "In Progress" {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulseEffect = true
                }
            }
        }
        .dropDestination(for: TournamentMatch.self) { droppedMatches, location in
            if let droppedMatch = droppedMatches.first {
                onDrop(droppedMatch)
                return true
            }
            return false
        }
    }
    
    private func getMatchTitle() -> String {
        if match.round == 999 {
            return "Final"
        } else if match.bracket == "Winners" {
            return "WR\(match.round)"
        } else if match.bracket == "Losers" {
            return "LR\(match.round)"
        } else {
            return "R\(match.round)"
        }
    }
    
    private var statusColor: Color {
        switch match.status {
        case "Completed": return .green
        case "In Progress": return .orange
        case "Ready": return .blue
        default: return .gray
        }
    }
}

// MARK: - Timeline Components

struct TimelineEventView: View {
    let event: TimelineEvent
    let isLast: Bool
    let isHighlighted: Bool
    let showPredictions: Bool
    let animate: Bool
    let onEventTap: () -> Void
    let onMatchDrop: ((TournamentMatch) -> Void)?
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Timeline connector
            VStack(spacing: 0) {
                // Line from previous event
                if !isFirst {
                    Rectangle()
                        .fill(event.status.color.opacity(0.3))
                        .frame(width: 2, height: 20)
                }
                
                // Event icon
                ZStack {
                    Circle()
                        .fill(event.status.color)
                        .frame(width: 40, height: 40)
                        .scaleEffect(isHighlighted ? 1.2 : 1.0)
                        .shadow(radius: isHighlighted ? 8 : 4)
                    
                    Image(systemName: event.type.icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Line to next event
                if !isLast {
                    Rectangle()
                        .fill(event.status.color.opacity(0.3))
                        .frame(width: 2, height: 40)
                }
            }
            
            // Event content
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(event.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(event.date, style: .time)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(event.date, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        if event.status == .predicted && showPredictions {
                            Text("Predicted")
                                .font(.caption2)
                                .foregroundColor(.purple)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(.purple.opacity(0.1))
                                )
                        }
                    }
                }
                
                // Match details if applicable
                if let match = event.match {
                    MatchTimelineCard(
                        match: match,
                        isHighlighted: isHighlighted,
                        onDrop: onMatchDrop
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .stroke(
                        isHighlighted ? event.status.color : (isHovered ? Color.secondary.opacity(0.3) : Color.clear),
                        lineWidth: isHighlighted ? 2 : 1
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .onTapGesture {
                onEventTap()
            }
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    private var isFirst: Bool {
        // This would need to be passed in or calculated
        return false
    }
}

struct MatchTimelineCard: View {
    let match: TournamentMatch
    let isHighlighted: Bool
    let onDrop: ((TournamentMatch) -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            // Match info
            VStack(alignment: .leading, spacing: 4) {
                if !match.player1Name.isEmpty && !match.player2Name.isEmpty {
                    HStack(spacing: 8) {
                        Text(match.player1Name)
                            .font(.caption)
                            .foregroundColor(match.winnerID == match.player1ID ? .green : .primary)
                        
                        Text("vs")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(match.player2Name)
                            .font(.caption)
                            .foregroundColor(match.winnerID == match.player2ID ? .green : .primary)
                    }
                } else {
                    Text("Participants TBD")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !match.finalScore.isEmpty {
                    Text(match.finalScore)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status badge
            Text(match.status)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(statusColor)
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
                .stroke(isHighlighted ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .dropDestination(for: TournamentMatch.self) { droppedMatches, location in
            if let droppedMatch = droppedMatches.first, let onDrop = onDrop {
                onDrop(droppedMatch)
                return true
            }
            return false
        }
    }
    
    private var statusColor: Color {
        switch match.status {
        case "Completed": return .green
        case "In Progress": return .orange
        case "Ready": return .blue
        default: return .gray
        }
    }
}

// MARK: - Extensions

// MARK: - Bracket Settings View

struct BracketSettingsView: View {
    @Binding var layoutMode: InteractiveTournamentBracketView.BracketLayoutMode
    @Binding var showConnections: Bool
    @Binding var animateConnections: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Layout Options") {
                    Picker("Layout Mode", selection: $layoutMode) {
                        ForEach(InteractiveTournamentBracketView.BracketLayoutMode.allCases, id: \.self) { mode in
                            Label(mode.rawValue, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Visual Options") {
                    Toggle("Show Connections", isOn: $showConnections)
                    
                    if showConnections {
                        Toggle("Animate Connections", isOn: $animateConnections)
                    }
                }
                
                Section("Help") {
                    Label("Drag and drop matches in edit mode", systemImage: "hand.draw")
                        .foregroundColor(.secondary)
                    
                    Label("Pinch to zoom, drag to pan", systemImage: "hand.point.up.braille")
                        .foregroundColor(.secondary)
                    
                    Label("Tap matches for details", systemImage: "hand.tap")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Bracket Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Participant Manager View

struct ParticipantManagerView: View {
    @Binding var tournament: Tournament
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Participant Manager")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Manage tournament participants")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Coming Soon")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Participants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - TournamentMatch Transferable

extension TournamentMatch: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(for: TournamentMatch.self, contentType: .data)
    }
}