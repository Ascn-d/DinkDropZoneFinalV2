import SwiftUI

/// Premium tournament card with enhanced animations and visual effects
struct TournamentEnhancedCard: View {
    let tournament: Tournament
    let onJoin: () -> Void
    let onView: () -> Void
    
    @State private var isPressed = false
    @State private var isAnimating = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with status and live indicator
            tournamentHeader
            
            // Main content
            VStack(alignment: .leading, spacing: DS.Layout.itemSpacing) {
                tournamentTitle
                tournamentDetails
                participantInfo
                actionButtons
            }
            .padding(DS.Layout.cardPadding)
        }
        .dsPremiumCard(style: cardStyle)
        .scaleEffect(isPressed ? DS.Layout.pressScale : 1.0)
        .dsAnimated(isPressed, animation: DS.Animation.buttonPress)
        .onTapGesture {
            withAnimation(DS.Animation.gentle) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DS.Animation.gentle) {
                    isPressed = false
                }
                onView()
            }
        }
        .onAppear {
            withAnimation(DS.Animation.cardAppear.delay(Double.random(in: 0...0.3))) {
                isAnimating = true
            }
        }
    }
    
    // MARK: - Header Section
    private var tournamentHeader: some View {
        HStack {
            // Tournament format badge
            HStack(spacing: 6) {
                Image(systemName: formatIcon)
                    .font(.caption2)
                Text(tournament.format)
                    .font(DS.Font.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(DS.Color.accent.opacity(0.1))
            )
            .foregroundColor(DS.Color.accent)
            
            Spacer()
            
            // Live status indicator
            if tournament.status == "In Progress" {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.red)
                        .frame(width: 6, height: 6)
                        .scaleEffect(isAnimating ? 1.3 : 1.0)
                        .dsAnimated(isAnimating, animation: Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true))
                    
                    Text("LIVE")
                        .font(DS.Font.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(.red.opacity(0.1))
                )
            } else {
                // Status badge
                Text(tournament.status)
                    .font(DS.Font.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.1))
                    )
                    .foregroundColor(statusColor)
            }
        }
        .padding(.horizontal, DS.Layout.cardPadding)
        .padding(.top, DS.Layout.cardPadding)
    }
    
    // MARK: - Tournament Title
    private var tournamentTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(tournament.name)
                .font(DS.Font.title3)
                .fontWeight(.bold)
                .foregroundColor(DS.Color.primary)
                .lineLimit(2)
            
            if !tournament.description.isEmpty {
                Text(tournament.description)
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
                    .lineLimit(2)
            }
        }
    }
    
    // MARK: - Tournament Details
    private var tournamentDetails: some View {
        VStack(spacing: 8) {
            HStack {
                DetailItem(
                    icon: "location.fill",
                    text: tournament.venueName.isEmpty ? "TBD" : tournament.venueName,
                    color: .blue
                )
                
                Spacer()
                
                DetailItem(
                    icon: "calendar",
                    text: formatDate(tournament.startDate),
                    color: .green
                )
            }
            
            HStack {
                DetailItem(
                    icon: "trophy.fill",
                    text: tournament.type,
                    color: .orange
                )
                
                Spacer()
                
                DetailItem(
                    icon: "star.fill",
                    text: tournament.skillLevel,
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Participant Information
    private var participantInfo: some View {
        HStack {
            // Participant count with progress
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(DS.Color.accent)
                    
                    Text("\(tournament.registeredCount)/\(tournament.maxParticipants)")
                        .font(DS.Font.headline)
                        .fontWeight(.semibold)
                    
                    Text("players")
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.secondary)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(DS.Color.divider.opacity(0.3))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(progressGradient)
                            .frame(width: geometry.size.width * progressPercentage, height: 4)
                            .animation(DS.Animation.smooth, value: progressPercentage)
                    }
                }
                .frame(height: 4)
            }
            
            Spacer()
            
            // Registration status
            registrationStatusView
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 12) {
            // View Details Button
            Button(action: onView) {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text("Details")
                        .font(DS.Font.button)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .dsPremiumButton(style: .secondary)
            
            // Join/Status Button
            Button(action: canJoin ? onJoin : {}) {
                HStack(spacing: 6) {
                    Image(systemName: joinButtonIcon)
                        .font(.caption)
                    Text(joinButtonText)
                        .font(DS.Font.button)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .dsPremiumButton(
                style: joinButtonStyle,
                isDisabled: !canJoin
            )
        }
    }
    
    // MARK: - Helper Views
    private var registrationStatusView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if tournament.isRegistrationOpen {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                    Text("Open")
                        .font(DS.Font.caption2)
                        .foregroundColor(.green)
                }
            } else if tournament.registeredCount >= tournament.maxParticipants {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.red)
                        .frame(width: 6, height: 6)
                    Text("Full")
                        .font(DS.Font.caption2)
                        .foregroundColor(.red)
                }
            } else {
                HStack(spacing: 4) {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                    Text("Closed")
                        .font(DS.Font.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    private var cardStyle: DSCardStyle {
        switch tournament.status {
        case "In Progress":
            return .premium
        case "Registration Open":
            return .prominent
        default:
            return .standard
        }
    }
    
    private var statusColor: Color {
        switch tournament.status {
        case "Registration Open":
            return .green
        case "In Progress":
            return .red
        case "Completed":
            return .blue
        default:
            return .orange
        }
    }
    
    private var formatIcon: String {
        switch tournament.format.lowercased() {
        case "singles":
            return "person.circle"
        case "doubles":
            return "person.2.circle"
        case "mixed doubles":
            return "person.2.fill"
        default:
            return "gamecontroller"
        }
    }
    
    private var progressPercentage: Double {
        guard tournament.maxParticipants > 0 else { return 0 }
        return Double(tournament.registeredCount) / Double(tournament.maxParticipants)
    }
    
    private var progressGradient: LinearGradient {
        let percentage = progressPercentage
        if percentage >= 1.0 {
            return LinearGradient(colors: [.red, .red.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        } else if percentage >= 0.8 {
            return LinearGradient(colors: [.orange, .orange.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        } else {
            return LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
        }
    }
    
    private var canJoin: Bool {
        tournament.isRegistrationOpen && tournament.registeredCount < tournament.maxParticipants
    }
    
    private var joinButtonText: String {
        switch tournament.status {
        case "Registration Open":
            return canJoin ? "Join" : "Full"
        case "In Progress":
            return "Watch"
        case "Completed":
            return "Results"
        default:
            return "View"
        }
    }
    
    private var joinButtonIcon: String {
        switch tournament.status {
        case "Registration Open":
            return canJoin ? "plus.circle" : "xmark.circle"
        case "In Progress":
            return "eye"
        case "Completed":
            return "trophy"
        default:
            return "arrow.right"
        }
    }
    
    private var joinButtonStyle: DSButtonStyle {
        switch tournament.status {
        case "Registration Open":
            return canJoin ? .primary : .tertiary
        case "In Progress":
            return .secondary
        default:
            return .tertiary
        }
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Detail Item Component
struct DetailItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(text)
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Premium Button Modifier
struct TournamentPremiumButtonModifier: ViewModifier {
    let style: DSButtonStyle
    let isPressed: Bool
    let isDisabled: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isDisabled {
                        AnyView(Color.gray.opacity(0.2))
                    } else {
                        style.backgroundColor
                    }
                }
            )
            .foregroundColor(isDisabled ? .gray : style.foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                    .stroke(style.borderColor, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isDisabled ? 0.6 : 1.0)
            .animation(DS.Animation.buttonPress, value: isPressed)
    }
}

#Preview {
    let sampleTournament = Tournament(
        name: "Summer Championship 2024",
        description: "Annual summer tournament with exciting prizes and competitive play for all skill levels.",
        type: "Double Elimination",
        format: "Doubles",
        skillLevel: "Intermediate",
        maxParticipants: 32,
        startDate: Date().addingTimeInterval(86400), // Tomorrow
        organizerID: "organizer123",
        organizerName: "Tournament Director",
        venueName: "Griffith Park Courts",
        venueAddress: "4730 Crystal Springs Dr, Los Angeles, CA 90027"
    )
    
    return VStack(spacing: 20) {
        TournamentEnhancedCard(
            tournament: sampleTournament,
            onJoin: { print("Join tapped") },
            onView: { print("View tapped") }
        )
        
        TournamentEnhancedCard(
            tournament: {
                var t = sampleTournament
                t.status = "In Progress"
                return t
            }(),
            onJoin: { print("Watch tapped") },
            onView: { print("View tapped") }
        )
    }
    .padding()
    .background(DS.Color.background)
}

// MARK: - Enhanced Filter Chip
struct EnhancedFilterChip: View {
    let filter: TournamentFilter
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    enum TournamentFilter: String, CaseIterable {
        case all = "All"
        case open = "Open Registration"
        case starting = "Starting Soon"
        case inProgress = "In Progress"
        case nearby = "Nearby"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .open: return "door.left.hand.open"
            case .starting: return "clock.fill"
            case .inProgress: return "play.circle.fill"
            case .nearby: return "location.fill"
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .accentColor)
                
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.accentColor.opacity(0.2))
                        )
                        .foregroundColor(isSelected ? .white : .accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    .shadow(color: isSelected ? .accentColor.opacity(0.3) : .clear, radius: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - My Tournament Filter Chip
struct MyFilterChip: View {
    let filter: MyTournamentFilter
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    enum MyTournamentFilter: String, CaseIterable {
        case active = "Active"
        case upcoming = "Upcoming"
        case completed = "Completed"
        case all = "All"
        
        var icon: String {
            switch self {
            case .active: return "play.circle.fill"
            case .upcoming: return "clock.fill"
            case .completed: return "checkmark.circle.fill"
            case .all: return "list.bullet"
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .accentColor)
                
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.white.opacity(0.3) : Color.accentColor.opacity(0.2))
                        )
                        .foregroundColor(isSelected ? .white : .accentColor)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    .shadow(color: isSelected ? .accentColor.opacity(0.3) : .clear, radius: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced Stat Card
struct EnhancedStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: StatTrend?
    
    enum StatTrend {
        case up, down
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.circle.fill"
            case .down: return "arrow.down.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.caption)
                        .foregroundColor(trend.color)
                }
            }
            
            VStack(spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(minWidth: 80, minHeight: 70)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Enhanced Tournament Card moved to UI/EnhancedTournamentCard.swift

// MARK: - Enhanced Tournament Discovery Card
struct EnhancedTournamentDiscoveryCard: View {
    let tournament: Tournament
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tournament.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(tournament.venueName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    EnhancedStatusBadge(status: tournament.status)
                }
                
                // Tournament details
                HStack(spacing: 16) {
                    DetailPill(
                        icon: "calendar",
                        text: tournament.startDate.formatted(date: .abbreviated, time: .shortened),
                        color: .blue
                    )
                    
                    DetailPill(
                        icon: "person.2.fill",
                        text: "\(tournament.participants.count)/\(tournament.maxParticipants)",
                        color: .green
                    )
                    
                    DetailPill(
                        icon: "trophy.fill",
                        text: tournament.format,
                        color: .orange
                    )
                    
                    Spacer()
                }
                
                // Description (if available)
                if !tournament.description.isEmpty {
                    Text(tournament.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Registration progress
                if tournament.status == "Registration Open" {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Registration")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(tournament.participants.count) of \(tournament.maxParticipants)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: Double(tournament.participants.count), total: Double(tournament.maxParticipants))
                            .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                    }
                }
                
                // Action button
                if tournament.status == "Registration Open" {
                    HStack {
                        Spacer()
                        
                        Button("Join Tournament") {
                            // Handle join action
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.quaternary, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Enhanced My Tournament Card
struct EnhancedMyTournamentCard: View {
    let tournament: Tournament
    let userStatus: UserTournamentStatus
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with user status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tournament.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(tournament.venueName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    UserStatusBadge(status: userStatus)
                }
                
                // Progress or details based on status
                if tournament.status == "In Progress" {
                    progressSection
                } else {
                    detailsSection
                }
                
                // Action buttons
                HStack {
                    if tournament.status == "In Progress" {
                        ActionButton(
                            title: "View Bracket",
                            icon: "tournament",
                            color: .blue,
                            style: .secondary
                        ) {
                            // Handle bracket view
                        }
                    }
                    
                    Spacer()
                    
                    if userStatus.hasUpcomingMatch {
                        ActionButton(
                            title: "Next Match",
                            icon: "play.circle.fill",
                            color: .green,
                            style: .primary
                        ) {
                            // Handle next match
                        }
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(userStatus.color.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Tournament Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Round \(getCurrentRound())")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            }
            
            ProgressView(value: getTournamentProgress())
                .progressViewStyle(LinearProgressViewStyle(tint: userStatus.color))
        }
    }
    
    private var detailsSection: some View {
        HStack(spacing: 16) {
            DetailPill(
                icon: "calendar",
                text: tournament.startDate.formatted(date: .abbreviated, time: .shortened),
                color: .blue
            )
            
            DetailPill(
                icon: "trophy.fill",
                text: tournament.format,
                color: .orange
            )
            
            if let placement = getUserPlacement() {
                DetailPill(
                    icon: "number.circle.fill",
                    text: "#\(placement)",
                    color: placement <= 3 ? .yellow : .gray
                )
            }
            
            Spacer()
        }
    }
    
    private func getCurrentRound() -> Int {
        tournament.matches.map { $0.round }.max() ?? 1
    }
    
    private func getTournamentProgress() -> Double {
        let totalMatches = tournament.matches.count
        let completedMatches = tournament.matches.filter { $0.status == "Completed" }.count
        return totalMatches > 0 ? Double(completedMatches) / Double(totalMatches) : 0.0
    }
    
    private func getUserPlacement() -> Int? {
        // This would need access to current user - simplified for now
        return nil
    }
}

// LiveTournamentCard moved to TournamentTabView.swift to avoid duplication

// MARK: - Supporting Components

struct EnhancedStatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.2))
                    .overlay(
                        Capsule()
                            .stroke(statusColor, lineWidth: 1)
                    )
            )
            .foregroundColor(statusColor)
    }
    
    private var statusColor: Color {
        switch status {
        case "Registration Open": return .green
        case "Registration Closed": return .orange
        case "In Progress": return .blue
        case "Completed": return .gray
        default: return .secondary
        }
    }
}

struct UserStatusBadge: View {
    let status: UserTournamentStatus
    
    var body: some View {
        HStack(spacing: 4) {
            if status.hasUpcomingMatch {
                Circle()
                    .fill(status.color)
                    .frame(width: 6, height: 6)
                    .scaleEffect(1.2)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: true)
            }
            
            Text(status.description)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(status.color.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(status.color, lineWidth: 1)
                )
        )
        .foregroundColor(status.color)
    }
}

struct DetailPill: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(color)
            
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let style: ActionButtonStyle
    let action: () -> Void
    
    enum ActionButtonStyle {
        case primary, secondary
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(style == .primary ? color : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(color, lineWidth: 1)
                    )
            )
            .foregroundColor(style == .primary ? .white : color)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - UserTournamentStatus Extension

extension UserTournamentStatus {
    var hasUpcomingMatch: Bool {
        switch self {
        case .hasMatch: return true
        case .waitingForMatch: return true
        default: return false
        }
    }
} 