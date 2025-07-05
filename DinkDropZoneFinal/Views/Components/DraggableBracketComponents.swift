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
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Tree Bracket Layout")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            // Tree visualization would go here
            // For now, fall back to traditional layout
            Text("Coming Soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.quaternary)
                )
        }
    }
}

// MARK: - Timeline Bracket View

struct TimelineBracketView: View {
    let tournament: Tournament
    let isEditMode: Bool
    let onMatchDrop: (TournamentMatch, TournamentMatch) -> Void
    let onMatchTap: (TournamentMatch) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Timeline Bracket Layout")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            // Timeline visualization would go here
            Text("Coming Soon")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(40)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.quaternary)
                )
        }
    }
}

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