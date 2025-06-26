import SwiftUI

struct MatchSetupView: View {
    let match: LocalMatchmakingService.LocalMatch
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFormat: MatchConfiguration.MatchFormat = .bestOfThree
    @State private var selectedScoring: MatchConfiguration.ScoringSystem = .traditional
    @State private var player1Ready: Bool = false
    @State private var player2Ready: Bool = false
    @State private var showingBattleTransition: Bool = false
    @State private var animationPhase: AnimationPhase = .entrance
    @State private var countdown: Int = 0
    @State private var showingLiveMatch: Bool = false
    @State private var matchConfiguration: MatchConfiguration?
    
    enum AnimationPhase {
        case entrance
        case selection
        case readyUp
        case battleTransition
    }
    
    private var isPlayer1: Bool {
        guard let currentUser = appState.currentUser else { return true }
        return match.player1.id == currentUser.id.uuidString
    }
    
    private var currentPlayer: LocalMatchmakingService.NearbyPlayer {
        return isPlayer1 ? match.player1 : match.player2
    }
    
    private var opponentPlayer: LocalMatchmakingService.NearbyPlayer {
        return isPlayer1 ? match.player2 : match.player1
    }
    
    private var bothPlayersReady: Bool {
        return player1Ready && player2Ready
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic background based on animation phase
                backgroundGradient
                    .ignoresSafeArea()
                
                // Main content with scroll support
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Title Header
                        titleHeader
                            .padding(.top, geometry.safeAreaInsets.top + 10)
                        
                        Spacer()
                            .frame(height: animationPhase == .readyUp ? 20 : 40)
                        
                        // Players vs Display - Compact for ready phase
                        playersVersusDisplay
                        
                        Spacer()
                            .frame(height: animationPhase == .readyUp ? 30 : 40)
                        
                        // Match Configuration Section - Hidden during ready up
                        if animationPhase == .selection {
                            matchConfigurationSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal: .move(edge: .top).combined(with: .opacity)
                                ))
                            
                            Spacer()
                                .frame(height: 30)
                        }
                        
                        // Ready Up Section - Prominent display
                        if animationPhase == .readyUp {
                            waitingForPlayersSection
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .scale),
                                    removal: .move(edge: .bottom).combined(with: .opacity)
                                ))
                            
                            Spacer()
                                .frame(height: 30)
                        }
                        
                        // Action Buttons
                        actionButtonsSection
                        
                        // Bottom padding
                        Spacer()
                            .frame(height: geometry.safeAreaInsets.bottom + 20)
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .opacity(showingBattleTransition ? 0 : 1)
                
                // Battle Transition Overlay
                if showingBattleTransition {
                    battleTransitionOverlay
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startEntranceAnimation()
        }
        .fullScreenCover(isPresented: $showingLiveMatch) {
            if let config = matchConfiguration {
                EnhancedLiveMatchView(configuration: config)
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: 1.0), value: animationPhase)
    }
    
    private var backgroundColors: [Color] {
        switch animationPhase {
        case .entrance:
            return [.black, .gray.opacity(0.8)]
        case .selection:
            return [DS.Color.accent.opacity(0.3), DS.Color.background, DS.Color.accent.opacity(0.2)]
        case .readyUp:
            return [.green.opacity(0.3), DS.Color.background, .blue.opacity(0.3)]
        case .battleTransition:
            return [.red.opacity(0.6), .orange.opacity(0.6), .yellow.opacity(0.6)]
        }
    }
    
    // MARK: - Title Header
    
    private var titleHeader: some View {
        VStack(spacing: 8) {
            Text(animationPhase == .readyUp ? "WAITING FOR PLAYERS" : "MATCH SETUP")
                .font(.system(size: animationPhase == .readyUp ? 28 : 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
                .scaleEffect(animationPhase == .entrance ? 0.5 : 1.0)
                .opacity(animationPhase == .entrance ? 0 : 1)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.5), value: animationPhase)
            
            if animationPhase != .entrance {
                Text(animationPhase == .readyUp ? "Ready up to start the match" : "Configure your battle")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Players Display
    
    private var playersVersusDisplay: some View {
        HStack(spacing: animationPhase == .readyUp ? 30 : 40) {
            // Player 1 (Current User Side)
            playerCard(
                player: currentPlayer,
                isCurrentUser: true,
                isReady: isPlayer1 ? player1Ready : player2Ready,
                side: .left
            )
            
            // VS Symbol
            vsSymbol
            
            // Player 2 (Opponent Side)
            playerCard(
                player: opponentPlayer,
                isCurrentUser: false,
                isReady: isPlayer1 ? player2Ready : player1Ready,
                side: .right
            )
        }
        .scaleEffect(animationPhase == .entrance ? 0.3 : (animationPhase == .readyUp ? 0.85 : 1.0))
        .opacity(animationPhase == .entrance ? 0 : 1)
        .animation(.spring(response: 1.0, dampingFraction: 0.7).delay(1.0), value: animationPhase)
    }
    
    private func playerCard(player: LocalMatchmakingService.NearbyPlayer, isCurrentUser: Bool, isReady: Bool, side: Side) -> some View {
        let cardSize: CGFloat = animationPhase == .readyUp ? 90 : 120
        let avatarSize: CGFloat = animationPhase == .readyUp ? 100 : 120
        
        return VStack(spacing: animationPhase == .readyUp ? 12 : 16) {
            // Player Avatar with Ready Glow
            ZStack {
                // Glow effect when ready
                if isReady {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.green.opacity(0.6), .green.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 15,
                                endRadius: 60
                            )
                        )
                        .frame(width: avatarSize + 40, height: avatarSize + 40)
                        .scaleEffect(isReady ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isReady)
                }
                
                // Main avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isCurrentUser ? 
                                [DS.Color.accent, DS.Color.accent.opacity(0.7)] : 
                                [.gray, .gray.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: cardSize, height: cardSize)
                    .overlay(
                        Text(String(player.displayName.prefix(1)).uppercased())
                            .font(.system(size: cardSize * 0.35, weight: .black))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                isReady ? .green : (isCurrentUser ? DS.Color.accent : .gray),
                                lineWidth: 3
                            )
                            .frame(width: cardSize + 8, height: cardSize + 8)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Ready checkmark
                if isReady {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 25))
                        .foregroundColor(.green)
                        .background(Circle().fill(.white))
                        .offset(x: cardSize * 0.35, y: -cardSize * 0.35)
                        .scaleEffect(isReady ? 1.0 : 0.0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isReady)
                }
            }
            
            // Player Info - Compact for ready phase
            VStack(spacing: animationPhase == .readyUp ? 4 : 8) {
                Text(player.displayName)
                    .font(animationPhase == .readyUp ? .headline : .title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                
                if animationPhase != .readyUp {
                    HStack(spacing: 8) {
                        // ELO Badge
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            Text("\(player.elo)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .fixedSize()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(.black.opacity(0.8))
                                .overlay(
                                    Capsule()
                                        .stroke(.yellow.opacity(0.3), lineWidth: 1)
                                )
                        )
                        
                        // Skill Level Badge
                        Text(skillLevelDisplayText(player.eloRange))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(skillLevelColor(player.eloRange))
                                    .shadow(color: skillLevelColor(player.eloRange).opacity(0.3), radius: 2)
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize()
                    }
                }
            }
            
            // Side indicator
            if isCurrentUser {
                Text("YOU")
                    .font(.caption)
                    .fontWeight(.black)
                    .foregroundColor(DS.Color.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(.white))
            }
        }
        .scaleEffect(side == .left ? (animationPhase == .entrance ? 0.5 : 1.0) : (animationPhase == .entrance ? 0.5 : 1.0))
        .offset(x: side == .left ? (animationPhase == .entrance ? -200 : 0) : (animationPhase == .entrance ? 200 : 0))
    }
    
    private var vsSymbol: some View {
        VStack(spacing: 6) {
            Text("VS")
                .font(.system(size: animationPhase == .readyUp ? 32 : 48, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: .red.opacity(0.8), radius: 6, x: 0, y: 0)
                .scaleEffect(animationPhase == .entrance ? 0 : 1.0)
                .rotationEffect(.degrees(animationPhase == .entrance ? 180 : 0))
                .animation(.spring(response: 1.2, dampingFraction: 0.5).delay(1.5), value: animationPhase)
            
            if animationPhase != .entrance {
                Text(match.matchType.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                    .transition(.opacity)
            }
        }
    }
    
    // MARK: - Configuration Section
    
    private var matchConfigurationSection: some View {
        VStack(spacing: 24) {
            // Format Selection
            formatSelectionGrid
            
            // Scoring System Selection  
            scoringSystemSelection
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 15)
        )
        .padding(.horizontal)
    }
    
    private var formatSelectionGrid: some View {
        VStack(spacing: 16) {
            Text("Match Format")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(minimum: 100), spacing: 10), count: 3), 
                spacing: 12
            ) {
                ForEach(MatchConfiguration.MatchFormat.allCases, id: \.self) { format in
                    formatCard(format)
                }
            }
        }
    }
    
    private func formatCard(_ format: MatchConfiguration.MatchFormat) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                selectedFormat = format
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: format.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(selectedFormat == format ? .white : format.color)
                
                Text(format.rawValue)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(selectedFormat == format ? .white : .primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Text(formatDescription(format))
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(selectedFormat == format ? .white.opacity(0.9) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 10)
            .frame(minHeight: 110)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedFormat == format ? format.color : Color(.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedFormat == format ? format.color : .clear, lineWidth: 2)
                    )
            )
            .scaleEffect(selectedFormat == format ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
    
    private var scoringSystemSelection: some View {
        VStack(spacing: 12) {
            Text("Scoring System")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            HStack(spacing: 10) {
                ForEach(MatchConfiguration.ScoringSystem.allCases, id: \.self) { system in
                    scoringSystemCard(system)
                }
            }
        }
    }
    
    private func scoringSystemCard(_ system: MatchConfiguration.ScoringSystem) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                selectedScoring = system
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: system.icon)
                    .font(.title2)
                    .foregroundColor(selectedScoring == system ? .white : system.color)
                
                Text(system.rawValue)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(selectedScoring == system ? .white : .primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(scoringDescription(system))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(selectedScoring == system ? .white.opacity(0.9) : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 130)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedScoring == system ? system.color : Color(.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedScoring == system ? system.color.opacity(0.3) : .clear, lineWidth: 1)
                    )
            )
            .scaleEffect(selectedScoring == system ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Waiting for Players Section
    
    private var waitingForPlayersSection: some View {
        VStack(spacing: 25) {
            // Match Configuration Summary
            VStack(spacing: 12) {
                Text("MATCH CONFIGURATION")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    // Format
                    VStack(spacing: 4) {
                        Image(systemName: selectedFormat.icon)
                            .font(.title2)
                            .foregroundColor(selectedFormat.color)
                        Text(selectedFormat.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                    
                    // Scoring
                    VStack(spacing: 4) {
                        Image(systemName: selectedScoring.icon)
                            .font(.title2)
                            .foregroundColor(selectedScoring.color)
                        Text(selectedScoring.rawValue)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
            
            // Ready Status
            VStack(spacing: 20) {
                Text("READY STATUS")
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .shadow(color: .green.opacity(0.8), radius: 4)
                
                HStack(spacing: 30) {
                    // Player 1 Ready Status
                    readyStatusCard(
                        playerName: isPlayer1 ? "YOU" : opponentPlayer.displayName,
                        isReady: player1Ready,
                        isCurrentUser: isPlayer1
                    )
                    
                    Text("&")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Player 2 Ready Status
                    readyStatusCard(
                        playerName: isPlayer1 ? opponentPlayer.displayName : "YOU",
                        isReady: player2Ready,
                        isCurrentUser: !isPlayer1
                    )
                }
                
                // Progress indicator
                if !bothPlayersReady {
                    VStack(spacing: 8) {
                        HStack {
                            ForEach(0..<3, id: \.self) { index in
                                Circle()
                                    .fill(.white.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(animationPhase == .readyUp ? 1.2 : 1.0)
                                    .opacity(animationPhase == .readyUp ? 1.0 : 0.5)
                                    .animation(
                                        .easeInOut(duration: 0.6)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                        value: animationPhase
                                    )
                            }
                        }
                        
                        Text("Waiting for all players to ready up...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(bothPlayersReady ? .green : .white.opacity(0.3), lineWidth: 2)
                )
                .shadow(color: bothPlayersReady ? .green.opacity(0.3) : .black.opacity(0.2), radius: 15)
        )
        .padding(.horizontal)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            if animationPhase == .selection {
                Button("CONFIRM SETUP") {
                    withAnimation(.spring()) {
                        animationPhase = .readyUp
                    }
                }
                .buttonStyle(BattleButtonStyle(color: .blue))
            }
            
            if animationPhase == .readyUp {
                let currentUserReady = isPlayer1 ? player1Ready : player2Ready
                
                Button(currentUserReady ? "READY!" : "READY UP") {
                    toggleReady()
                }
                .buttonStyle(BattleButtonStyle(color: currentUserReady ? .green : .orange))
                
                if bothPlayersReady {
                    Button("START BATTLE!") {
                        startBattle()
                    }
                    .buttonStyle(BattleButtonStyle(color: .red))
                    .transition(.scale.combined(with: .opacity))
                }
            }
            
            // Exit Button
            Button("Exit") {
                dismiss()
            }
            .foregroundColor(.white.opacity(0.7))
            .padding(.top)
        }
    }
    
    // MARK: - Battle Transition
    
    private var battleTransitionOverlay: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("BATTLE!")
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .red, radius: 10)
                    .scaleEffect(showingBattleTransition ? 1.5 : 0.5)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showingBattleTransition)
                
                if countdown > 0 {
                    Text("\(countdown)")
                        .font(.system(size: 120, weight: .black, design: .rounded))
                        .foregroundColor(.red)
                        .scaleEffect(countdown > 0 ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: countdown)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func startEntranceAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                animationPhase = .selection
            }
        }
    }
    
    private func toggleReady() {
        if isPlayer1 {
            player1Ready.toggle()
        } else {
            player2Ready.toggle()
        }
        
        // TODO: Send ready state to opponent via MultipeerConnectivity
        sendReadyState()
    }
    
    private func sendReadyState() {
        // TODO: Implement MP ready state sync
        print("🔄 Sending ready state update")
    }
    
    private func startBattle() {
        withAnimation {
            showingBattleTransition = true
            animationPhase = .battleTransition
        }
        
        countdown = 3
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdown -= 1
            
            if countdown <= 0 {
                timer.invalidate()
                startLiveMatch()
            }
        }
    }
    
    private func startLiveMatch() {
        let configuration = MatchConfiguration(
            matchFormat: selectedFormat,
            scoringSystem: selectedScoring,
            player1: match.player1,
            player2: match.player2,
            matchType: match.matchType,
            createdAt: Date()
        )
        
        matchConfiguration = configuration
        showingLiveMatch = true
    }
    
    private func skillLevelColor(_ level: String) -> Color {
        switch level.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        case "expert": return .purple
        case "pro": return .indigo
        default: return .blue
        }
    }
    
    private func skillLevelDisplayText(_ level: String) -> String {
        switch level.lowercased() {
        case "beginner": return "BEGINNER"
        case "intermediate": return "INTER"
        case "advanced": return "ADV"
        case "expert": return "EXPERT"
        case "pro": return "PRO"
        default: return level.uppercased()
        }
    }
    
    private func formatDescription(_ format: MatchConfiguration.MatchFormat) -> String {
        switch format {
        case .bestOfOne: return "Single game\nto 11 points"
        case .bestOfThree: return "First to win\n2 games"
        case .bestOfFive: return "First to win\n3 games"
        case .firstToEleven: return "Race to\n11 points"
        case .firstToFifteen: return "Race to\n15 points"
        case .firstToTwentyOne: return "Race to\n21 points"
        }
    }
    
    private func scoringDescription(_ system: MatchConfiguration.ScoringSystem) -> String {
        switch system {
        case .traditional: return "Win by 2 points\nServe alternates\nevery 2 points"
        case .rally: return "Point on every rally\nServe alternates\nevery point"
        case .tennis: return "Tennis scoring\n15, 30, 40, Game\nDeuce rules apply"
        }
    }
    
    private func readyStatusCard(playerName: String, isReady: Bool, isCurrentUser: Bool) -> some View {
        VStack(spacing: 12) {
            // Status Icon with Animation
            ZStack {
                Circle()
                    .fill(isReady ? .green.opacity(0.2) : .orange.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .scaleEffect(isReady ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isReady)
                
                Image(systemName: isReady ? "checkmark.circle.fill" : "clock.circle")
                    .font(.system(size: 30))
                    .foregroundColor(isReady ? .green : .orange)
                    .scaleEffect(isReady ? 1.2 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isReady)
            }
            
            VStack(spacing: 4) {
                Text(playerName)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(isReady ? "READY!" : "WAITING...")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(isReady ? .green : .orange)
                    .opacity(isReady ? 1.0 : 0.7)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isReady ? .green : .orange.opacity(0.5), lineWidth: 2)
                )
        )
        .shadow(color: isReady ? .green.opacity(0.3) : .orange.opacity(0.2), radius: 8)
    }
    
    enum Side {
        case left, right
    }
}

// MARK: - Custom Button Style

struct BattleButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.gradient)
                    .shadow(color: color.opacity(0.5), radius: configuration.isPressed ? 2 : 8, x: 0, y: configuration.isPressed ? 1 : 4)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    let sampleMatch = LocalMatchmakingService.LocalMatch(
        id: "sample",
        player1: LocalMatchmakingService.NearbyPlayer(
            id: "1",
            displayName: "Player 1",
            elo: 1200,
            matchType: "Casual",
            distance: 0.1,
            peerID: "device1"
        ),
        player2: LocalMatchmakingService.NearbyPlayer(
            id: "2",
            displayName: "Player 2", 
            elo: 1150,
            matchType: "Casual",
            distance: 0.1,
            peerID: "device2"
        ),
        matchType: "Casual",
        createdAt: Date()
    )
    
    MatchSetupView(match: sampleMatch)
        .environmentObject(AppState())
} 