import SwiftUI
import SwiftData
import FirebaseAuth

// MARK: - Notification Names

extension Notification.Name {
    static let tournamentUpdated = Notification.Name("tournamentUpdated")
    static let bracketUpdated = Notification.Name("bracketUpdated")
}

struct TournamentDetailView: View {
    let tournament: Tournament
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showBracket = false
    @State private var showMatchView = false
    @State private var currentMatch: TournamentMatch?
    @State private var showTournamentJoin = false
    @State private var animateContent = false
    @State private var showCelebration = false
    @State private var parallaxOffset: CGFloat = 0
    @State private var showingOrganizerDashboard = false
    
    // Use centralized tournament status from AppState
    private var userStatus: AppState.UserTournamentStatus {
        return appState.getUserTournamentStatus(for: tournament)
    }
    
    // Check if current user is the tournament organizer
    private var isUserTournamentOrganizer: Bool {
        guard let currentUser = appState.currentUser else { return false }
        // Use Firebase user ID for organizer comparison
        guard let firebaseUser = Auth.auth().currentUser else { return false }
        return tournament.organizerID == firebaseUser.uid
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background with parallax effect
                DS.Color.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Enhanced Tournament Header with parallax
                        enhancedTournamentHeader
                            .offset(y: parallaxOffset * 0.5)
                        
                        // Main Content
                        VStack(spacing: 24) {
                            // Enhanced Status and Actions
                            enhancedStatusSection
                            
                            // Enhanced Tournament Information
                            enhancedTournamentInfo
                            
                            // Current Match (if user is participating and has active match)
                            if userStatus == .participating, let activeMatch = getUserActiveMatch() {
                                enhancedCurrentMatchSection(activeMatch)
                            }
                            
                            // Enhanced Tournament Progress
                            if userStatus == .participating || userStatus == .completed {
                                enhancedTournamentProgress
                            }
                            
                            // Enhanced Bracket Preview
                            enhancedBracketPreview
                            
                            // Enhanced Participants Preview
                            enhancedParticipantsPreview
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(DS.Color.surface)
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: -5)
                        )
                        .offset(y: -20)
                    }
                }
                .scrollDisabled(false)
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    parallaxOffset = value
                }
                
                // Floating action button
                if userStatus == .participating, let activeMatch = getUserActiveMatch() {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button {
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                currentMatch = activeMatch
                                showMatchView = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "play.fill")
                                        .font(.title3)
                                    Text("Play Match")
                                        .font(DS.Font.button)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(TournamentDS.Color.live)
                                .clipShape(Capsule())
                                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .scaleEffect(animateContent ? 1.0 : 0.8)
                            .animation(TournamentDS.Animation.victory.delay(1.0), value: animateContent)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                withAnimation(TournamentDS.Animation.tournamentEntry) {
                    animateContent = true
                }
            }
            .sheet(isPresented: $showBracket) {
                InteractiveTournamentBracketView(tournament: tournament)
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showMatchView) {
                if let match = currentMatch {
                    ScoreEntryView(
                        match: match,
                        tournament: tournament
                    )
                    .environmentObject(appState)
                }
            }
            .sheet(isPresented: $showTournamentJoin) {
                TournamentJoinView(tournament: tournament, tournamentService: appState.getTournamentService()!)
                    .environmentObject(appState)
                    .onDisappear {
                        LoggingService.shared.log("Tournament join view dismissed")
                    }
            }
            .sheet(isPresented: $showingOrganizerDashboard) {
                TournamentOrganizerDashboard(tournament: tournament)
                    .environmentObject(appState)
            }
            .onReceive(NotificationCenter.default.publisher(for: .tournamentUpdated)) { notification in
                if let updatedTournament = notification.object as? Tournament,
                   updatedTournament.id == tournament.id {
                    LoggingService.shared.log("Tournament updated via notification")
                    
                    // Trigger update animation
                    withAnimation(TournamentDS.Animation.matchUpdate) {
                        // Visual feedback for updates
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .bracketUpdated)) { notification in
                if let updatedTournament = notification.object as? Tournament,
                   updatedTournament.id == tournament.id {
                    LoggingService.shared.log("Tournament bracket updated")
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            .particleEffect(.victory, isActive: showCelebration)
        }
    }
    
    // MARK: - Enhanced Tournament Header
    
    private var enhancedTournamentHeader: some View {
        ZStack {
            // Background with enhanced gradient
            RoundedRectangle(cornerRadius: 0)
                .fill(
                    LinearGradient(
                        colors: [
                            .blue.opacity(0.8),
                            .blue.opacity(0.6),
                            .blue.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 320)
                .overlay(
                    // Subtle pattern overlay
                    Image(systemName: "triangle.fill")
                        .font(.system(size: 200))
                        .foregroundColor(.white.opacity(0.1))
                        .offset(x: 100, y: -50)
                        .rotationEffect(.degrees(15))
                )
            
            VStack(spacing: 20) {
                // Back button
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    enhancedStatusIndicator
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                // Tournament icon with enhanced effects
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateContent ? 1.0 : 0.8)
                        .animation(TournamentDS.Animation.tournamentEntry.delay(0.3), value: animateContent)
                    
                    Image(systemName: tournamentIcon)
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .symbolEffect(.bounce, value: animateContent)
                        .offset(y: animateContent ? 0 : 10)
                        .animation(TournamentDS.Animation.tournamentEntry.delay(0.5), value: animateContent)
                }
                
                // Tournament name and description
                VStack(spacing: 8) {
                    Text(tournament.name)
                        .font(DS.Font.displayLarge)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .offset(y: animateContent ? 0 : 20)
                        .opacity(animateContent ? 1.0 : 0.0)
                        .animation(TournamentDS.Animation.tournamentEntry.delay(0.7), value: animateContent)
                    
                    if !tournament.description.isEmpty {
                        Text(tournament.description)
                            .font(DS.Font.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .offset(y: animateContent ? 0 : 20)
                            .opacity(animateContent ? 1.0 : 0.0)
                            .animation(TournamentDS.Animation.tournamentEntry.delay(0.9), value: animateContent)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Enhanced Status Section
    
    private var enhancedStatusSection: some View {
        VStack(spacing: 16) {
            // Status badges with enhanced styling
            HStack(spacing: 12) {
                EnhancedStatusBadge(
                    status: tournament.status
                )
                
                Spacer()
                
                EnhancedStatusBadge(
                    status: userStatus.displayText
                )
            }
            
            // Enhanced action buttons
            enhancedActionButtons
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .scaleEffect(animateContent ? 1.0 : 0.95)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(TournamentDS.Animation.tournamentEntry.delay(1.1), value: animateContent)
    }
    
    // MARK: - Enhanced Tournament Info
    
    private var enhancedTournamentInfo: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Tournament Details")
                .font(DS.Font.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // Enhanced info cards with animation
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                EnhancedInfoCard(
                    title: "Format",
                    value: tournament.format,
                    icon: "gamecontroller.fill",
                    gradient: TournamentDS.Color.active,
                    delay: 0.0
                )
                
                EnhancedInfoCard(
                    title: "Participants",
                    value: "\(tournament.registeredCount)/\(tournament.maxParticipants)",
                    icon: "person.2.fill",
                    gradient: TournamentDS.Color.upcoming,
                    delay: 0.1
                )
                
                EnhancedInfoCard(
                    title: "Prize Pool",
                    value: "$\(tournament.prizePool)",
                    icon: "dollarsign.circle.fill",
                    gradient: TournamentDS.Color.winner,
                    delay: 0.2
                )
                
                EnhancedInfoCard(
                    title: "Entry Fee",
                    value: "$\(tournament.entryFee)",
                    icon: "creditcard.fill",
                    gradient: TournamentDS.Color.registration,
                    delay: 0.3
                )
            }
            
            // Enhanced venue and schedule
            enhancedVenueSchedule
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(DS.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Enhanced Current Match Section
    
    private func enhancedCurrentMatchSection(_ match: TournamentMatch) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Current Match")
                    .font(DS.Font.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Live indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animateContent ? 1.2 : 1.0)
                        .animation(TournamentDS.Animation.pulse, value: animateContent)
                    
                    Text("LIVE")
                        .font(DS.Font.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
            }
            
            EnhancedMatchCard(match: match) {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                currentMatch = match
                showMatchView = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(DS.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                .stroke(TournamentDS.Color.live, lineWidth: 2)
        )
        .shadow(color: .red.opacity(0.2), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Enhanced Tournament Progress
    
    private var enhancedTournamentProgress: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tournament Progress")
                    .font(DS.Font.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(getTournamentProgress() * 100))%")
                    .font(DS.Font.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            // Enhanced progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DS.Color.divider.opacity(0.3))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(TournamentDS.Color.active)
                        .frame(width: geometry.size.width * getTournamentProgress(), height: 8)
                        .cornerRadius(4)
                        .animation(TournamentDS.Animation.tournamentEntry.delay(1.5), value: animateContent)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(getCompletedMatches()) of \(tournament.matches.count) matches completed")
                    .font(DS.Font.body)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(progressStatusText)
                    .font(DS.Font.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(DS.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Enhanced Bracket Preview
    
    private var enhancedBracketPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tournament Bracket")
                    .font(DS.Font.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View Full Bracket") {
                    showBracket = true
                }
                .tournamentButton(gradient: TournamentDS.Color.upcoming)
            }
            
            // Enhanced bracket preview
            bracketPreviewContent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(DS.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Enhanced Participants Preview
    
    private var enhancedParticipantsPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Participants (\(tournament.registeredCount))")
                    .font(DS.Font.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to participants view
                }
                .tournamentButton(gradient: TournamentDS.Color.upcoming)
            }
            
            // Enhanced participants grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Array(tournament.participants.prefix(9).enumerated()), id: \.offset) { index, participant in
                    EnhancedParticipantCard(
                        participant: participant.displayName,
                        delay: Double(index) * 0.1
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(DS.Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Helper Components
    
    private var enhancedStatusIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .scaleEffect(animateContent ? 1.2 : 1.0)
                .animation(TournamentDS.Animation.pulse, value: animateContent)
            
            Text(tournament.status.uppercased())
                .font(DS.Font.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
    
    private var enhancedActionButtons: some View {
        VStack(spacing: 12) {
            // Tournament Organizer Dashboard Button
            if isUserTournamentOrganizer {
                Button("Tournament Dashboard") {
                    showingOrganizerDashboard = true
                }
                .tournamentButton(gradient: TournamentDS.Color.live, isDisabled: isLoading)
                .disabled(isLoading)
            }
            
            // Regular participant action buttons
            HStack(spacing: 12) {
                switch userStatus {
                case .notRegistered:
                    if tournament.status == "Registration Open" {
                        Button("Join Tournament") {
                            joinTournament()
                        }
                        .tournamentButton(gradient: TournamentDS.Color.registration, isDisabled: isLoading)
                        .disabled(isLoading)
                    }
                    
                case .registered, .waitingToStart:
                    Button("Leave Tournament") {
                        leaveTournament()
                    }
                    .tournamentButton(gradient: TournamentDS.Color.completed, isDisabled: isLoading)
                    .disabled(isLoading)
                    
                case .participating:
                    Button("View Bracket") {
                        showBracket = true
                    }
                    .tournamentButton(gradient: TournamentDS.Color.upcoming)
                    
                case .completed, .eliminated:
                    Button("View Results") {
                        showBracket = true
                    }
                    .tournamentButton(gradient: TournamentDS.Color.completed)
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                }
            }
        }
    }
    
    private var enhancedVenueSchedule: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "location.circle.fill")
                    .font(.title3)
                    .foregroundStyle(TournamentDS.Color.upcoming)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Venue")
                        .font(DS.Font.caption)
                        .foregroundColor(.secondary)
                    
                    Text(tournament.venueName.isEmpty ? "Venue TBD" : tournament.venueName)
                        .font(DS.Font.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                Image(systemName: "calendar.circle.fill")
                    .font(.title3)
                    .foregroundStyle(TournamentDS.Color.active)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Start Date")
                        .font(DS.Font.caption)
                        .foregroundColor(.secondary)
                    
                    Text(tournament.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(DS.Font.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
            
            if tournament.endDate != tournament.startDate {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock.fill")
                        .font(.title3)
                        .foregroundStyle(TournamentDS.Color.registration)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("End Date")
                            .font(DS.Font.caption)
                            .foregroundColor(.secondary)
                        
                        Text(tournament.endDate.formatted(date: .abbreviated, time: .shortened))
                            .font(DS.Font.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DS.Color.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.smallCornerRadius))
    }
    
    private var bracketPreviewContent: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Round of \(tournament.matches.count)")
                    .font(DS.Font.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Next: \(nextMatchTime)")
                    .font(DS.Font.caption)
                    .foregroundColor(.secondary)
            }
            
            // Simplified bracket visualization
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(index < 2 ? AnyShapeStyle(TournamentDS.Color.finished) : AnyShapeStyle(DS.Color.divider.opacity(0.3)))
                        .frame(height: 8)
                        .animation(TournamentDS.Animation.tournamentEntry.delay(Double(index) * 0.1), value: animateContent)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DS.Color.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.smallCornerRadius))
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch tournament.status {
        case "Registration Open": return .green
        case "Registration Closed": return .orange
        case "In Progress", "Live": return .red
        case "Completed": return .gray
        default: return .gray
        }
    }
    
    private var statusGradient: LinearGradient {
        switch tournament.status {
        case "Registration Open": return TournamentDS.Color.registration
        case "Registration Closed": return TournamentDS.Color.upcoming
        case "In Progress", "Live": return TournamentDS.Color.live
        case "Completed": return TournamentDS.Color.completed
        default: return TournamentDS.Color.upcoming
        }
    }
    
    private var statusIcon: String {
        switch tournament.status {
        case "Registration Open": return "person.badge.plus"
        case "Registration Closed": return "person.badge.minus"
        case "In Progress", "Live": return "play.circle.fill"
        case "Completed": return "checkmark.circle.fill"
        default: return "circle"
        }
    }
    
    private var userStatusGradient: LinearGradient {
        switch userStatus {
        case .notRegistered: return TournamentDS.Color.upcoming
        case .registered, .waitingToStart: return TournamentDS.Color.registration
        case .participating: return TournamentDS.Color.live
        case .completed: return TournamentDS.Color.winner
        case .eliminated: return TournamentDS.Color.completed
        }
    }
    
    private var userStatusIcon: String {
        switch userStatus {
        case .notRegistered: return "person.circle"
        case .registered, .waitingToStart: return "person.circle.fill"
        case .participating: return "gamecontroller.fill"
        case .completed: return "trophy.fill"
        case .eliminated: return "xmark.circle.fill"
        }
    }
    
    private var tournamentIcon: String {
        switch tournament.format {
        case "Singles": return "person.circle.fill"
        case "Doubles": return "person.2.circle.fill"
        case "Mixed": return "person.3.circle.fill"
        default: return "trophy.fill"
        }
    }
    
    private var progressStatusText: String {
        let progress = getTournamentProgress()
        if progress == 0 {
            return "Not started"
        } else if progress < 0.5 {
            return "Early rounds"
        } else if progress < 1.0 {
            return "Final rounds"
        } else {
            return "Completed"
        }
    }
    
    private var nextMatchTime: String {
        // Mock next match time
        return "15:30"
    }
    
    // MARK: - Helper Methods
    
    private func getUserActiveMatch() -> TournamentMatch? {
        guard let currentUser = appState.currentUser else { return nil }
        guard let firebaseUser = Auth.auth().currentUser else { return nil }
        
        return tournament.matches.first { match in
            match.status == "Ready" &&
            (match.player1ID == firebaseUser.uid || match.player2ID == firebaseUser.uid)
        }
    }
    
    private func joinTournament() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await appState.joinTournament(tournament)
                await MainActor.run {
                    isLoading = false
                    withAnimation(TournamentDS.Animation.victory) {
                        showCelebration = true
                    }
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
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await appState.leaveTournament(tournament)
                await MainActor.run {
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
    
    private func getTournamentProgress() -> Double {
        let total = tournament.matches.count
        let completed = getCompletedMatches()
        return total > 0 ? Double(completed) / Double(total) : 0.0
    }
    
    private func getCompletedMatches() -> Int {
        return tournament.matches.filter { $0.status == "Completed" }.count
    }
}

// MARK: - Supporting Views (moved to avoid duplicates)

struct EnhancedInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let gradient: LinearGradient
    let delay: Double
    
    @State private var isAnimated = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(gradient)
                
                Spacer()
            }
            
            Text(title)
                .font(DS.Font.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(DS.Font.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DS.Color.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.smallCornerRadius))
        .scaleEffect(isAnimated ? 1.0 : 0.9)
        .opacity(isAnimated ? 1.0 : 0.0)
        .animation(TournamentDS.Animation.tournamentEntry.delay(delay), value: isAnimated)
        .onAppear {
            isAnimated = true
        }
    }
}

// EnhancedMatchCard moved to avoid duplicate declarations

struct EnhancedParticipantCard: View {
    let participant: String
    let delay: Double
    
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(TournamentDS.Color.upcoming)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(participant.prefix(1).uppercased()))
                        .font(DS.Font.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            Text(participant.isEmpty ? "Player" : participant)
                .font(DS.Font.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .background(DS.Color.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.smallCornerRadius))
        .scaleEffect(isAnimated ? 1.0 : 0.8)
        .opacity(isAnimated ? 1.0 : 0.0)
        .animation(TournamentDS.Animation.tournamentEntry.delay(delay), value: isAnimated)
        .onAppear {
            isAnimated = true
        }
    }
}

// MARK: - Scroll Offset Tracking

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, configurations: config)
    
    let tournament = {
        var t = Tournament(
            name: "Summer Championship",
            description: "Annual summer tournament featuring the best players",
            organizerID: "organizer1",
            organizerName: "Tournament Director"
        )
        t.status = "Registration Open"
        return t
    }()
    
    let appState = AppState()
    
    TournamentDetailView(tournament: tournament)
        .modelContainer(container)
        .environmentObject(appState)
} 