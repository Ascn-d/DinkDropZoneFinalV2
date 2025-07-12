import SwiftUI

/// Enhanced design system specifically for tournament features with modern UI patterns
enum TournamentDS {
    
    // MARK: - Tournament-Specific Colors
    enum Color {
        // Tournament Status Colors
        static let active = LinearGradient(
            colors: [SwiftUI.Color.green.opacity(0.8), SwiftUI.Color.mint.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let upcoming = LinearGradient(
            colors: [SwiftUI.Color.blue.opacity(0.8), SwiftUI.Color.cyan.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let completed = LinearGradient(
            colors: [SwiftUI.Color.gray.opacity(0.6), SwiftUI.Color.secondary.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let registration = LinearGradient(
            colors: [SwiftUI.Color.orange.opacity(0.8), SwiftUI.Color.yellow.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Bracket UI Colors
        static let winner = LinearGradient(
            colors: [SwiftUI.Color.yellow.opacity(0.9), SwiftUI.Color.orange.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let finalist = LinearGradient(
            colors: [SwiftUI.Color.gray.opacity(0.8), SwiftUI.Color.secondary.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let semifinalist = LinearGradient(
            colors: [SwiftUI.Color.brown.opacity(0.7), SwiftUI.Color.orange.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Match Status Colors
        static let live = LinearGradient(
            colors: [SwiftUI.Color.red.opacity(0.8), SwiftUI.Color.pink.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let scheduled = LinearGradient(
            colors: [SwiftUI.Color.indigo.opacity(0.7), SwiftUI.Color.purple.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let finished = LinearGradient(
            colors: [SwiftUI.Color.green.opacity(0.7), SwiftUI.Color.teal.opacity(0.5)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Special Effect Colors
        static let championship = LinearGradient(
            colors: [
                SwiftUI.Color.purple.opacity(0.9),
                SwiftUI.Color.pink.opacity(0.7),
                SwiftUI.Color.blue.opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let premium = LinearGradient(
            colors: [
                SwiftUI.Color.indigo.opacity(0.9),
                SwiftUI.Color.cyan.opacity(0.7),
                SwiftUI.Color.mint.opacity(0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let elite = LinearGradient(
            colors: [
                SwiftUI.Color.black.opacity(0.8),
                SwiftUI.Color.gray.opacity(0.6),
                SwiftUI.Color.white.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Particle Effects
        static let sparkle = SwiftUI.Color.yellow.opacity(0.8)
        static let fire = SwiftUI.Color.orange.opacity(0.9)
        static let lightning = SwiftUI.Color.cyan.opacity(0.8)
    }
    
    // MARK: - Tournament Animations
    enum Animation {
        static let tournamentEntry = SwiftUI.Animation.spring(response: 0.8, dampingFraction: 0.6)
        static let bracketExpand = SwiftUI.Animation.easeInOut(duration: 0.6)
        static let matchUpdate = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let scoreIncrement = SwiftUI.Animation.easeOut(duration: 0.3)
        static let elimination = SwiftUI.Animation.easeIn(duration: 0.4)
        static let victory = SwiftUI.Animation.spring(response: 1.0, dampingFraction: 0.5)
        static let pulse = SwiftUI.Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        static let floating = SwiftUI.Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        static let sparkle = SwiftUI.Animation.easeOut(duration: 0.8).repeatForever()
    }
    
    // MARK: - Enhanced Effects
    enum Effect {
        static let victoryGlow: ShadowStyle = ShadowStyle(
            color: SwiftUI.Color.yellow.opacity(0.5),
            radius: 20,
            x: 0,
            y: 8
        )
        
        static let liveMatchGlow: ShadowStyle = ShadowStyle(
            color: SwiftUI.Color.red.opacity(0.4),
            radius: 15,
            x: 0,
            y: 6
        )
        
        static let championshipGlow: ShadowStyle = ShadowStyle(
            color: SwiftUI.Color.purple.opacity(0.6),
            radius: 25,
            x: 0,
            y: 10
        )
    }
    
    // MARK: - Tournament Card Styles
    enum CardStyle {
        case tournament
        case bracket
        case match
        case player
        case leaderboard
        case championship
        case live
        
        var backgroundColor: AnyView {
            switch self {
            case .tournament:
                return AnyView(DS.Color.surfaceGradient)
            case .bracket:
                return AnyView(SwiftUI.Color.clear)
            case .match:
                return AnyView(DS.Color.surface)
            case .player:
                return AnyView(DS.Color.surfaceAlt)
            case .leaderboard:
                return AnyView(Color.premium)
            case .championship:
                return AnyView(Color.championship)
            case .live:
                return AnyView(Color.live)
            }
        }
        
        var borderGradient: LinearGradient {
            switch self {
            case .tournament:
                return DS.Color.primaryGradient
            case .bracket:
                return Color.upcoming
            case .match:
                return Color.finished
            case .player:
                return DS.Color.accentGradient
            case .leaderboard:
                return Color.premium
            case .championship:
                return Color.championship
            case .live:
                return Color.live
            }
        }
        
        var shadow: ShadowStyle {
            switch self {
            case .tournament:
                return DS.Shadow.medium
            case .bracket:
                return DS.Shadow.large
            case .match:
                return DS.Shadow.small
            case .player:
                return DS.Shadow.subtle
            case .leaderboard:
                return DS.Shadow.dramatic
            case .championship:
                return Effect.championshipGlow
            case .live:
                return Effect.liveMatchGlow
            }
        }
    }
}

// MARK: - Tournament-Specific View Modifiers

struct TournamentCardModifier: ViewModifier {
    let style: TournamentDS.CardStyle
    let isSelected: Bool
    let isAnimated: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(DS.Layout.cardPadding)
            .background(style.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                    .stroke(style.borderGradient, lineWidth: isSelected ? 2 : 1)
                    .scaleEffect(isSelected ? 1.02 : 1.0)
                    .animation(TournamentDS.Animation.matchUpdate, value: isSelected)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
            .modifier(ShadowViewModifier(shadow: style.shadow))
            .scaleEffect(isAnimated ? 1.0 : 0.95)
            .opacity(isAnimated ? 1.0 : 0.0)
            .animation(TournamentDS.Animation.tournamentEntry, value: isAnimated)
    }
}

struct LiveIndicatorModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Circle()
                    .fill(SwiftUI.Color.red)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .opacity(isAnimating ? 0.7 : 1.0)
                    .animation(TournamentDS.Animation.pulse, value: isAnimating)
                    .onAppear {
                        isAnimating = true
                    },
                alignment: .topTrailing
            )
    }
}

struct VictoryEffectModifier: ViewModifier {
    let isWinner: Bool
    @State private var sparkleOffset: CGFloat = 0
    @State private var showEffect = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if isWinner && showEffect {
                        ForEach(0..<5, id: \.self) { index in
                            Image(systemName: "star.fill")
                                .foregroundColor(TournamentDS.Color.sparkle)
                                .font(.caption)
                                .offset(
                                    x: cos(Double(index) * 2 * .pi / 5) * 30 + sparkleOffset,
                                    y: sin(Double(index) * 2 * .pi / 5) * 30 + sparkleOffset
                                )
                                .opacity(0.8)
                                .animation(
                                    TournamentDS.Animation.sparkle.delay(Double(index) * 0.1),
                                    value: sparkleOffset
                                )
                        }
                    }
                }
            )
            .onChange(of: isWinner) { oldValue, newValue in
                if newValue {
                    withAnimation(TournamentDS.Animation.victory) {
                        showEffect = true
                        sparkleOffset = 20
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(TournamentDS.Animation.victory) {
                            showEffect = false
                            sparkleOffset = 0
                        }
                    }
                }
            }
    }
}

struct ScoreUpdateModifier: ViewModifier {
    let score: Int
    @State private var previousScore: Int = 0
    @State private var showIncrement = false
    @State private var incrementValue = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Group {
                    if showIncrement && incrementValue > 0 {
                        Text("+\(incrementValue)")
                            .font(DS.Font.caption)
                            .foregroundColor(.green)
                            .offset(y: showIncrement ? -30 : 0)
                            .opacity(showIncrement ? 0 : 1)
                            .animation(TournamentDS.Animation.scoreIncrement, value: showIncrement)
                    }
                },
                alignment: .topTrailing
            )
            .onChange(of: score) { oldScore, newScore in
                let increment = newScore - previousScore
                if increment > 0 {
                    incrementValue = increment
                    withAnimation(TournamentDS.Animation.scoreIncrement) {
                        showIncrement = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showIncrement = false
                        previousScore = newScore
                    }
                }
            }
    }
}

struct ParticleEffectModifier: ViewModifier {
    let effect: ParticleEffect
    let isActive: Bool
    @State private var particles: [TournamentParticle] = []
    @State private var animationTimer: Timer?
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    ForEach(particles, id: \.id) { particle in
                        Circle()
                            .fill(effect.color)
                            .frame(width: particle.size, height: particle.size)
                            .position(particle.position)
                            .opacity(particle.opacity)
                            .scaleEffect(particle.scale)
                    }
                }
                .allowsHitTesting(false)
            )
            .onAppear {
                if isActive {
                    startParticleAnimation()
                }
            }
            .onDisappear {
                stopParticleAnimation()
            }
            .onChange(of: isActive) { oldValue, active in
                if active {
                    startParticleAnimation()
                } else {
                    stopParticleAnimation()
                }
            }
    }
    
    private func startParticleAnimation() {
        stopParticleAnimation()
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            addParticle()
            updateParticles()
        }
    }
    
    private func stopParticleAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        particles.removeAll()
    }
    
    private func addParticle() {
        guard particles.count < 20 else { return }
        
        let particle = TournamentParticle(
            position: CGPoint(
                x: CGFloat.random(in: 0...300),
                y: CGFloat.random(in: 0...500)
            ),
            velocity: CGPoint(
                x: CGFloat.random(in: -2...2),
                y: CGFloat.random(in: -3...0)
            ),
            size: CGFloat.random(in: 2...6),
            opacity: 1.0,
            scale: 1.0,
            life: 1.0
        )
        
        particles.append(particle)
    }
    
    private func updateParticles() {
        for i in particles.indices.reversed() {
            particles[i].position.x += particles[i].velocity.x
            particles[i].position.y += particles[i].velocity.y
            particles[i].life -= 0.02
            particles[i].opacity = particles[i].life
            particles[i].scale = particles[i].life
            
            if particles[i].life <= 0 {
                particles.remove(at: i)
            }
        }
    }
}

// MARK: - Supporting Data Structures

struct TournamentParticle {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    let size: CGFloat
    var opacity: Double
    var scale: CGFloat
    var life: Double
}

enum ParticleEffect {
    case victory
    case fire
    case sparkle
    case confetti
    
    var color: SwiftUI.Color {
        switch self {
        case .victory: return TournamentDS.Color.sparkle
        case .fire: return TournamentDS.Color.fire
        case .sparkle: return TournamentDS.Color.lightning
        case .confetti: return SwiftUI.Color.random
        }
    }
}

extension SwiftUI.Color {
    static var random: SwiftUI.Color {
        SwiftUI.Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}

// MARK: - Enhanced View Extensions for Tournaments

extension View {
    /// Applies tournament card styling
    func tournamentCard(
        style: TournamentDS.CardStyle = .tournament,
        isSelected: Bool = false,
        isAnimated: Bool = true
    ) -> some View {
        modifier(TournamentCardModifier(style: style, isSelected: isSelected, isAnimated: isAnimated))
    }
    
    /// Adds live indicator for active matches
    func liveIndicator() -> some View {
        modifier(LiveIndicatorModifier())
    }
    
    /// Adds victory effect for winners
    func victoryEffect(isWinner: Bool) -> some View {
        modifier(VictoryEffectModifier(isWinner: isWinner))
    }
    
    /// Adds score update animation
    func scoreUpdate(score: Int) -> some View {
        modifier(ScoreUpdateModifier(score: score))
    }
    
    /// Adds particle effects
    func particleEffect(_ effect: ParticleEffect, isActive: Bool = true) -> some View {
        modifier(ParticleEffectModifier(effect: effect, isActive: isActive))
    }
    
    /// Enhanced tournament button
    func tournamentButton(
        gradient: LinearGradient = TournamentDS.Color.active,
        isDisabled: Bool = false
    ) -> some View {
        self
            .font(DS.Font.button)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                isDisabled ?
                AnyShapeStyle(LinearGradient(
                    colors: [DS.Color.divider, DS.Color.divider],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )) :
                AnyShapeStyle(gradient)
            )
            .clipShape(Capsule())
            .scaleEffect(isDisabled ? 0.95 : 1.0)
            .animation(TournamentDS.Animation.matchUpdate, value: isDisabled)
    }
    
    /// Enhanced bracket connection line
    func bracketLine(isActive: Bool = false) -> some View {
        Rectangle()
            .fill(
                isActive ? 
                AnyShapeStyle(TournamentDS.Color.live) :
                AnyShapeStyle(LinearGradient(
                    colors: [DS.Color.divider, DS.Color.divider],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            )
            .frame(height: 2)
            .animation(TournamentDS.Animation.bracketExpand, value: isActive)
    }
} 