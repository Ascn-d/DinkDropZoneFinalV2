import SwiftUI

struct EnhancedTournamentCard: View {
    let tournament: Tournament
    let style: TournamentDS.CardStyle
    let animationDelay: Double
    var showUserProgress: Bool = false
    var isLive: Bool = false
    var isFeatured: Bool = false
    let onTap: () -> Void
    
    @State private var isAnimating = false
    @State private var isPressed = false
    @State private var showDetails = false
    
    var body: some View {
        Button(action: handleTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header section with tournament info
                headerSection
                
                // Tournament details
                detailsSection
                
                // Progress/Status section
                if showUserProgress {
                    userProgressSection
                } else {
                    statusSection
                }
                
                // Action section
                actionSection
            }
            .padding(DS.Layout.cardPadding)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
            .overlay(borderOverlay)
            .scaleEffect(isPressed ? DS.Layout.pressScale : 1.0)
            .opacity(isAnimating ? 1.0 : 0.0)
            .offset(y: isAnimating ? 0 : 20)
            .animation(
                TournamentDS.Animation.tournamentEntry.delay(animationDelay),
                value: isAnimating
            )
            .animation(DS.Animation.buttonPress, value: isPressed)
            .onAppear {
                isAnimating = true
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(
            minimumDuration: 0,
            pressing: { isPressing in
                isPressed = isPressing
            },
            perform: { }
        )
    }
    
    // MARK: - UI Components
    
    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            // Tournament icon with status indicator
            ZStack {
                Circle()
                    .fill(tournamentIconBackground)
                    .frame(width: 50, height: 50)
                
                Image(systemName: tournamentIcon)
                    .font(.title3)
                    .foregroundColor(.white)
                    .symbolEffect(.pulse.byLayer, options: .repeating)
                
                if isLive {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .offset(x: 18, y: -18)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(TournamentDS.Animation.pulse, value: isAnimating)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Tournament name with featured badge
                HStack {
                    Text(tournament.name)
                        .font(DS.Font.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if isFeatured {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                TournamentDS.Animation.sparkle.delay(0.5),
                                value: isAnimating
                            )
                    }
                }
                
                // Tournament format
                Text(tournament.format)
                    .font(DS.Font.subheadline)
                    .foregroundColor(.secondary)
                
                // Status badge
                statusBadge
            }
            
            Spacer()
            
            // Participant count
            participantCountView
        }
    }
    
    @ViewBuilder
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Venue information
            if !tournament.venueName.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "location.circle.fill")
                        .foregroundColor(.secondary)
                    
                    Text(tournament.venueName)
                        .font(DS.Font.body)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Date and time
            HStack(spacing: 8) {
                Image(systemName: "calendar.circle.fill")
                    .foregroundColor(.secondary)
                
                Text(tournament.startDate, style: .date)
                    .font(DS.Font.body)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(tournament.startDate, style: .time)
                    .font(DS.Font.caption)
                    .foregroundColor(.secondary)
            }
            
            // Tournament description (if available)
            if !tournament.description.isEmpty {
                Text(tournament.description)
                    .font(DS.Font.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
        }
    }
    
    @ViewBuilder
    private var userProgressSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Progress")
                .font(DS.Font.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(DS.Color.divider.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(TournamentDS.Color.active)
                        .frame(width: geometry.size.width * userProgress, height: 4)
                        .cornerRadius(2)
                        .animation(TournamentDS.Animation.tournamentEntry, value: userProgress)
                }
            }
            .frame(height: 4)
            
            HStack {
                Text("Round \(currentRound)")
                    .font(DS.Font.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(userProgress * 100))% Complete")
                    .font(DS.Font.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var statusSection: some View {
        HStack {
            // Tournament statistics
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Participants")
                        .font(DS.Font.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("\(tournament.participants.count) / \(tournament.maxParticipants)")
                        .font(DS.Font.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Skill Level")
                        .font(DS.Font.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(tournament.skillLevel)
                        .font(DS.Font.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var actionSection: some View {
        HStack {
            // Action button based on tournament state
            actionButton
            
            Spacer()
            
            // Additional info button
            Button {
                showDetails.toggle()
            } label: {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            // Base background
            style.backgroundColor
            
            // Overlay effects for special tournaments
            if isFeatured {
                TournamentDS.Color.championship
                    .opacity(0.1)
                    .blendMode(.overlay)
            }
            
            if isLive {
                TournamentDS.Color.live
                    .opacity(0.15)
                    .blendMode(.overlay)
            }
        }
    }
    
    @ViewBuilder
    private var borderOverlay: some View {
        RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
            .stroke(style.borderGradient, lineWidth: 1)
            .opacity(isPressed ? 0.8 : 1.0)
    }
    
    @ViewBuilder
    private var statusBadge: some View {
        Text(tournament.status)
            .font(DS.Font.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    @ViewBuilder
    private var participantCountView: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text("\(tournament.participants.count)")
                .font(DS.Font.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("/ \(tournament.maxParticipants)")
                .font(DS.Font.caption)
                .foregroundColor(.secondary)
            
            // Participant progress indicator
            Circle()
                .trim(from: 0, to: participantProgress)
                .stroke(
                    TournamentDS.Color.active,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 20, height: 20)
                .rotationEffect(.degrees(-90))
                .animation(TournamentDS.Animation.tournamentEntry, value: participantProgress)
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        Button {
            handleActionButton()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: actionButtonIcon)
                    .font(.caption)
                
                Text(actionButtonText)
                    .font(DS.Font.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(actionButtonBackground)
            .clipShape(Capsule())
        }
        .disabled(isActionDisabled)
        .opacity(isActionDisabled ? 0.6 : 1.0)
    }
    
    // MARK: - Computed Properties
    
    private var tournamentIcon: String {
        switch tournament.format {
        case "Singles": return "person.circle.fill"
        case "Doubles": return "person.2.circle.fill"
        case "Mixed": return "person.3.circle.fill"
        default: return "trophy.circle.fill"
        }
    }
    
    private var tournamentIconBackground: LinearGradient {
        switch tournament.status {
        case "Registration Open": return TournamentDS.Color.registration
        case "In Progress": return TournamentDS.Color.live
        case "Completed": return TournamentDS.Color.completed
        default: return TournamentDS.Color.upcoming
        }
    }
    
    private var statusColor: Color {
        switch tournament.status {
        case "Registration Open": return .green
        case "Registration Closed": return .orange
        case "In Progress": return .red
        case "Completed": return .gray
        default: return .secondary
        }
    }
    
    private var participantProgress: CGFloat {
        CGFloat(tournament.participants.count) / CGFloat(tournament.maxParticipants)
    }
    
    private var userProgress: CGFloat {
        // Mock user progress calculation
        switch tournament.status {
        case "Registration Open": return 0.0
        case "In Progress": return 0.6
        case "Completed": return 1.0
        default: return 0.0
        }
    }
    
    private var currentRound: Int {
        // Mock current round calculation
        switch tournament.status {
        case "In Progress": return 2
        case "Completed": return 3
        default: return 1
        }
    }
    
    private var actionButtonText: String {
        switch tournament.status {
        case "Registration Open": return "Join"
        case "Registration Closed": return "View"
        case "In Progress": return "Watch"
        case "Completed": return "Results"
        default: return "View"
        }
    }
    
    private var actionButtonIcon: String {
        switch tournament.status {
        case "Registration Open": return "plus.circle.fill"
        case "Registration Closed": return "eye.circle.fill"
        case "In Progress": return "play.circle.fill"
        case "Completed": return "list.bullet.circle.fill"
        default: return "eye.circle.fill"
        }
    }
    
    private var actionButtonBackground: LinearGradient {
        switch tournament.status {
        case "Registration Open": return TournamentDS.Color.registration
        case "Registration Closed": return TournamentDS.Color.upcoming
        case "In Progress": return TournamentDS.Color.live
        case "Completed": return TournamentDS.Color.completed
        default: return TournamentDS.Color.upcoming
        }
    }
    
    private var isActionDisabled: Bool {
        tournament.status == "Registration Closed" && tournament.participants.count >= tournament.maxParticipants
    }
    
    // MARK: - Actions
    
    private func handleTap() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        onTap()
    }
    
    private func handleActionButton() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        switch tournament.status {
        case "Registration Open":
            // Handle join tournament
            break
        case "In Progress":
            // Handle watch tournament
            break
        case "Completed":
            // Handle view results
            break
        default:
            // Handle view tournament
            break
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        EnhancedTournamentCard(
            tournament: Tournament(
                name: "Summer Championship",
                description: "Annual summer tournament featuring the best players from around the region",
                type: "Double Elimination",
                format: "Singles",
                skillLevel: "Intermediate",
                maxParticipants: 32,
                startDate: Date().addingTimeInterval(86400),
                organizerID: "organizer1",
                organizerName: "Tournament Director",
                venueName: "Central Sports Complex",
                venueAddress: "123 Sports St"
            ),
            style: .tournament,
            animationDelay: 0.0
        ) {
            print("Tournament tapped")
        }
        
        EnhancedTournamentCard(
            tournament: Tournament(
                name: "Elite Masters",
                description: "Premium tournament for advanced players",
                type: "Single Elimination",
                format: "Doubles",
                skillLevel: "Advanced",
                maxParticipants: 16,
                startDate: Date(),
                organizerID: "organizer2",
                organizerName: "Elite Organizer",
                venueName: "Elite Sports Center",
                venueAddress: "456 Elite Ave"
            ),
            style: .live,
            animationDelay: 0.1,
            isLive: true
        ) {
            print("Live tournament tapped")
        }
        
        EnhancedTournamentCard(
            tournament: Tournament(
                name: "Grand Championship",
                description: "The ultimate tournament experience",
                type: "Double Elimination",
                format: "Mixed",
                skillLevel: "Professional",
                maxParticipants: 64,
                startDate: Date().addingTimeInterval(172800),
                organizerID: "organizer3",
                organizerName: "Grand Master",
                venueName: "Grand Arena",
                venueAddress: "789 Championship Blvd"
            ),
            style: .championship,
            animationDelay: 0.2,
            isFeatured: true
        ) {
            print("Championship tournament tapped")
        }
    }
    .padding()
} 