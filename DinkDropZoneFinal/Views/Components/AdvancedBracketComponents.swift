import SwiftUI
import UniformTypeIdentifiers

// MARK: - Status Pill

struct StatusPill: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(color)
                    .overlay(
                        Capsule()
                            .stroke(.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Live Metrics Grid

struct LiveMetricsGrid: View {
    let tournament: Tournament
    @State private var animateMetrics = false
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            TournamentMetricCard(
                title: "Players",
                value: "\(tournament.registeredCount)",
                icon: "person.2.fill",
                color: .blue,
                animated: animateMetrics
            )
            
            TournamentMetricCard(
                title: "Matches",
                value: "\(tournament.matches.count)",
                icon: "gamecontroller.fill",
                color: .green,
                animated: animateMetrics
            )
            
            let completedMatches = tournament.matches.filter { $0.status == "Completed" }.count
            TournamentMetricCard(
                title: "Completed",
                value: "\(completedMatches)",
                icon: "checkmark.circle.fill",
                color: .purple,
                animated: animateMetrics
            )
            
            TournamentMetricCard(
                title: "Remaining",
                value: "\(tournament.matches.count - completedMatches)",
                icon: "clock.fill",
                color: .orange,
                animated: animateMetrics
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.5)) {
                animateMetrics = true
            }
        }
    }
}

// MARK: - Tournament Metric Card

struct TournamentMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let animated: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .scaleEffect(animated ? 1.0 : 0.5)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double.random(in: 0.1...0.3)), value: animated)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .opacity(animated ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.8).delay(0.3), value: animated)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .opacity(animated ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.8).delay(0.4), value: animated)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Bracket Section

struct BracketSection: View {
    let title: String
    let icon: String
    let color: Color
    let rounds: [Int]
    let tournament: Tournament
    let isEditMode: Bool
    let onMatchTap: (TournamentMatch) -> Void
    let onPlayerDrop: (String, TournamentMatch) -> Void
    let animateEntrance: Bool
    
    var body: some View {
        VStack(spacing: 32) {
            // Section header
            HStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .scaleEffect(animateEntrance ? 1.2 : 1.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3), value: animateEntrance)
                
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: color.opacity(0.5), radius: 4)
                
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
                                .overlay(
                                    Capsule()
                                        .stroke(.orange, lineWidth: 1)
                                )
                        )
                        .scaleEffect(animateEntrance ? 1.0 : 0.0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: animateEntrance)
                }
            }
            
            // Rounds display
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 60) {
                    ForEach(Array(rounds.enumerated()), id: \.element) { index, round in
                        RoundColumn(
                            round: round,
                            bracket: title.contains("Winners") ? "Winners" : (title.contains("Losers") ? "Losers" : "Main"),
                            tournament: tournament,
                            isEditMode: isEditMode,
                            color: color,
                            onMatchTap: onMatchTap,
                            onPlayerDrop: onPlayerDrop,
                            animationDelay: Double(index) * 0.2
                        )
                        .scaleEffect(animateEntrance ? 1.0 : 0.8)
                        .opacity(animateEntrance ? 1.0 : 0.0)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(Double(index) * 0.1 + 0.5), value: animateEntrance)
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.5), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .shadow(color: color.opacity(0.2), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Round Column

struct RoundColumn: View {
    let round: Int
    let bracket: String
    let tournament: Tournament
    let isEditMode: Bool
    let color: Color
    let onMatchTap: (TournamentMatch) -> Void
    let onPlayerDrop: (String, TournamentMatch) -> Void
    let animationDelay: Double
    
    private var roundMatches: [TournamentMatch] {
        tournament.matches
            .filter { $0.bracket == bracket && $0.round == round }
            .sorted { $0.matchNumber < $1.matchNumber }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Round header
            VStack(spacing: 8) {
                Text(roundTitle)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                let completedCount = roundMatches.filter { $0.status == "Completed" }.count
                BracketProgressIndicator(
                    completed: completedCount,
                    total: roundMatches.count,
                    color: color
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
            
            // Matches
            VStack(spacing: 20) {
                ForEach(Array(roundMatches.enumerated()), id: \.element.id) { index, match in
                    AdvancedMatchCard(
                        match: match,
                        isEditMode: isEditMode,
                        color: color,
                        onTap: { onMatchTap(match) },
                        onPlayerDrop: { player in onPlayerDrop(player, match) }
                    )
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay + Double(index) * 0.1), value: true)
                }
            }
        }
        .frame(minWidth: 240)
    }
    
    private var roundTitle: String {
        switch bracket {
        case "Winners":
            return "WR \(round)"
        case "Losers":
            return "LR \(round)"
        default:
            return "Round \(round)"
        }
    }
}

// MARK: - Bracket Progress Indicator

struct BracketProgressIndicator: View {
    let completed: Int
    let total: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(completed)/\(total)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.2))
                        .frame(height: 4)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                        .animation(.easeOut(duration: 0.8), value: progress)
                }
            }
            .frame(height: 4)
        }
    }
    
    private var progress: Double {
        total > 0 ? Double(completed) / Double(total) : 0
    }
}

// MARK: - Advanced Match Card

struct AdvancedMatchCard: View {
    let match: TournamentMatch
    let isEditMode: Bool
    let color: Color
    let onTap: () -> Void
    let onPlayerDrop: (String) -> Void
    
    @State private var isPressed = false
    @State private var isDropTarget = false
    @State private var pulseEffect = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 16) {
                // Match header
                HStack {
                    Text(matchDisplayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    StatusDot(status: match.status)
                }
                
                // Players section
                VStack(spacing: 12) {
                    PlayerSlot(
                        name: match.player1Name.isEmpty ? "TBD" : match.player1Name,
                        isWinner: match.winnerID == match.player1ID,
                        isEditMode: isEditMode,
                        onPlayerDrop: onPlayerDrop
                    )
                    
                    VSIndicator(status: match.status)
                    
                    PlayerSlot(
                        name: match.player2Name.isEmpty ? "TBD" : match.player2Name,
                        isWinner: match.winnerID == match.player2ID,
                        isEditMode: isEditMode,
                        onPlayerDrop: onPlayerDrop
                    )
                }
                
                // Score or action section
                if match.hasResult {
                    ScoreDisplay(score: match.finalScore)
                } else if match.status == "Ready" {
                    ReadyToPlayIndicator()
                } else if match.isBye {
                    ByeIndicator()
                }
            }
            .padding(20)
            .frame(width: 220)
            .frame(minHeight: 160)
            .background(matchCardBackground)
            .scaleEffect(cardScale)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
            .overlay(dropTargetOverlay)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) {
            // Empty
        } onPressingChanged: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }
        .dropDestination(for: String.self) { players, location in
            guard let player = players.first else { return false }
            onPlayerDrop(player)
            return true
        } isTargeted: { targeted in
            isDropTarget = targeted
        }
        .onChange(of: match.status) { _, newStatus in
            if newStatus == "Ready" {
                withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
                    pulseEffect = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    pulseEffect = false
                }
            }
        }
    }
    
    private var matchDisplayName: String {
        switch match.bracket {
        case "Winners":
            return "WR\(match.round)-\(match.matchNumber)"
        case "Losers":
            return "LR\(match.round)-\(match.matchNumber)"
        case "Grand Final":
            return "GRAND FINAL"
        default:
            return "Match \(match.matchNumber)"
        }
    }
    
    private var borderColor: Color {
        if isEditMode {
            return .blue.opacity(0.6)
        } else if match.status == "Ready" {
            return .green.opacity(0.8)
        } else if match.status == "Completed" {
            return color.opacity(0.6)
        } else {
            return .white.opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        if isEditMode || match.status == "Ready" {
            return 2
        } else {
            return 1
        }
    }
    
    private var shadowColor: Color {
        if match.status == "Ready" {
            return .green.opacity(0.4)
        } else if match.status == "Completed" {
            return color.opacity(0.3)
        } else {
            return .black.opacity(0.2)
        }
    }
    
    private var shadowRadius: CGFloat {
        pulseEffect ? 16 : 8
    }
    
    private var shadowOffset: CGFloat {
        pulseEffect ? 8 : 4
    }
    
    private var matchCardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var cardScale: CGFloat {
        isPressed ? 0.95 : (pulseEffect ? 1.05 : 1.0)
    }
    
    private var dropTargetOverlay: some View {
        RoundedRectangle(cornerRadius: 20)
            .stroke(.green, lineWidth: 3)
            .opacity(isDropTarget ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.3), value: isDropTarget)
    }
}

// MARK: - Player Slot

struct PlayerSlot: View {
    let name: String
    let isWinner: Bool
    let isEditMode: Bool
    let onPlayerDrop: (String) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .font(.subheadline)
                .fontWeight(isWinner ? .bold : .medium)
                .foregroundColor(isWinner ? .yellow : .white)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if isWinner {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .scaleEffect(1.2)
            }
            
            if isEditMode && (name.isEmpty || name == "TBD") {
                Image(systemName: "plus.circle.dashed")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isWinner ? .yellow.opacity(0.2) : .white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isWinner ? .yellow.opacity(0.5) : .white.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Status Dot

struct StatusDot: View {
    let status: String
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(.white, lineWidth: 1)
            )
            .scaleEffect(status == "Ready" ? 1.3 : 1.0)
            .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: status == "Ready")
    }
    
    private var statusColor: Color {
        switch status {
        case "Upcoming": return .blue
        case "Ready": return .green
        case "In Progress": return .orange
        case "Completed": return .gray
        default: return .gray
        }
    }
}

// MARK: - VS Indicator

struct VSIndicator: View {
    let status: String
    
    var body: some View {
        ZStack {
            if status == "In Progress" {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(.orange)
                            .frame(width: 6, height: 6)
                            .scaleEffect(1.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: status
                            )
                    }
                }
            } else {
                Text("VS")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(.white.opacity(0.1))
                    )
            }
        }
    }
}

// MARK: - Score Display

struct ScoreDisplay: View {
    let score: String
    
    var body: some View {
        Text(score)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.green)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.green.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(.green.opacity(0.5), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Ready to Play Indicator

struct ReadyToPlayIndicator: View {
    @State private var pulse = false
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
                .scaleEffect(pulse ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)
            
            Text("Ready to Play")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.green.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(.green.opacity(0.5), lineWidth: 1)
                )
        )
        .onAppear {
            pulse = true
        }
    }
}

// MARK: - Bye Indicator

struct ByeIndicator: View {
    var body: some View {
        Text("Bye")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.orange)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(.orange.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(.orange.opacity(0.5), lineWidth: 1)
                    )
            )
    }
}

// MARK: - Grand Final Section

struct GrandFinalSection: View {
    let match: TournamentMatch
    let isEditMode: Bool
    let onMatchTap: (TournamentMatch) -> Void
    let onPlayerDrop: (String, TournamentMatch) -> Void
    let animateEntrance: Bool
    
    @State private var championshipGlow = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Championship header
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.yellow)
                    .scaleEffect(championshipGlow ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: championshipGlow)
                
                VStack(spacing: 4) {
                    Text("GRAND FINAL")
                        .font(.title)
                        .fontWeight(.black)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .yellow.opacity(0.5), radius: championshipGlow ? 12 : 6)
                    
                    Text("Championship Match")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.yellow)
                    .scaleEffect(championshipGlow ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(1), value: championshipGlow)
            }
            
            // Grand final match card
            AdvancedMatchCard(
                match: match,
                isEditMode: isEditMode,
                color: .yellow,
                onTap: { onMatchTap(match) },
                onPlayerDrop: { player in onPlayerDrop(player, match) }
            )
            .scaleEffect(1.1)
            .shadow(color: .yellow.opacity(0.4), radius: 16, x: 0, y: 8)
            
            // Championship rules
            VStack(spacing: 12) {
                Text("Championship Rules")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Best of 3 games • First to 11 points • Win by 2")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.yellow.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                )
        )
        .shadow(color: .yellow.opacity(0.3), radius: 20, x: 0, y: 10)
        .scaleEffect(animateEntrance ? 1.0 : 0.8)
        .opacity(animateEntrance ? 1.0 : 0.0)
        .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(1.0), value: animateEntrance)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).delay(1.5)) {
                championshipGlow = true
            }
        }
    }
}

// MARK: - Floating Button

struct FloatingButton: View {
    let icon: String
    let color: Color
    var size: CGFloat = 48
    var isPrimary: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(color)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.3), lineWidth: isPrimary ? 2 : 1)
                        )
                )
                .shadow(color: color.opacity(0.4), radius: isPressed ? 4 : 12, x: 0, y: isPressed ? 2 : 6)
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0) {
            // Empty
        } onPressingChanged: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }
    }
    
    private var iconSize: CGFloat {
        if isPrimary {
            return size * 0.4
        } else {
            return size * 0.35
        }
    }
}

// MARK: - Particle System View

struct ParticleSystemView: View {
    let particleCount: Int
    let colors: [Color]
    let animated: Bool
    
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGPoint
        var color: Color
        var size: CGFloat
        var opacity: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .opacity(particle.opacity)
                        .position(particle.position)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                if animated {
                    startAnimation(in: geometry.size)
                }
            }
        }
    }
    
    private func generateParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                velocity: CGPoint(
                    x: CGFloat.random(in: -1...1),
                    y: CGFloat.random(in: -1...1)
                ),
                color: colors.randomElement() ?? .white,
                size: CGFloat.random(in: 2...6),
                opacity: Double.random(in: 0.1...0.5)
            )
        }
    }
    
    private func startAnimation(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                updateParticles(in: size)
            }
        }
    }
    
    private func updateParticles(in size: CGSize) {
        for i in particles.indices {
            particles[i].position.x += particles[i].velocity.x
            particles[i].position.y += particles[i].velocity.y
            
            // Wrap around edges
            if particles[i].position.x < 0 {
                particles[i].position.x = size.width
            } else if particles[i].position.x > size.width {
                particles[i].position.x = 0
            }
            
            if particles[i].position.y < 0 {
                particles[i].position.y = size.height
            } else if particles[i].position.y > size.height {
                particles[i].position.y = 0
            }
        }
    }
}

// MARK: - Mesh Gradient View

struct MeshGradientView: View {
    let colors: [Color]
    let animated: Bool
    
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .hueRotation(.degrees(animated ? animationOffset : 0))
        .onAppear {
            if animated {
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                    animationOffset = 360
                }
            }
        }
    }
}

// MARK: - Bracket Confetti View

struct BracketConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGPoint
        var color: Color
        var rotation: Double
        var rotationSpeed: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    Rectangle()
                        .fill(piece.color)
                        .frame(width: 8, height: 8)
                        .rotationEffect(.degrees(piece.rotation))
                        .position(piece.position)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
                animateConfetti(in: geometry.size)
            }
        }
    }
    
    private func generateConfetti(in size: CGSize) {
        let colors: [Color] = [.red, .blue, .green, .yellow, .purple, .orange, .pink]
        
        confettiPieces = (0..<100).map { _ in
            ConfettiPiece(
                position: CGPoint(x: CGFloat.random(in: 0...size.width), y: -20),
                velocity: CGPoint(
                    x: CGFloat.random(in: -2...2),
                    y: CGFloat.random(in: 2...5)
                ),
                color: colors.randomElement() ?? .blue,
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -10...10)
            )
        }
    }
    
    private func animateConfetti(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            withAnimation(.linear(duration: 0.05)) {
                updateConfetti(in: size)
            }
            
            // Stop after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                timer.invalidate()
            }
        }
    }
    
    private func updateConfetti(in size: CGSize) {
        for i in confettiPieces.indices {
            confettiPieces[i].position.x += confettiPieces[i].velocity.x
            confettiPieces[i].position.y += confettiPieces[i].velocity.y
            confettiPieces[i].rotation += confettiPieces[i].rotationSpeed
            
            // Remove pieces that fall off screen
            if confettiPieces[i].position.y > size.height + 20 {
                confettiPieces[i].position.y = -20
                confettiPieces[i].position.x = CGFloat.random(in: 0...size.width)
            }
        }
    }
}

// MARK: - Bracket Connections Canvas

struct BracketConnectionsCanvas: View {
    let tournament: Tournament
    let geometry: GeometryProxy
    let scale: CGFloat
    let offset: CGSize
    let animations: [UUID: Bool]
    
    var body: some View {
        Canvas { context, size in
            drawConnections(context: context, size: size)
        }
    }
    
    private func drawConnections(context: GraphicsContext, size: CGSize) {
        // Draw animated connections between matches
        let path = Path { path in
            // Implementation would draw actual bracket connections
            // This is a placeholder for the connection drawing logic
        }
        
        context.stroke(
            path,
            with: .color(.blue.opacity(0.4)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 5])
        )
    }
}

// MARK: - String Transferable

// Note: String already conforms to Transferable in iOS 16+
// extension String: Transferable {
//     public static var transferRepresentation: some TransferRepresentation {
//         CodableRepresentation(for: String.self, contentType: .plainText)
//     }
// }