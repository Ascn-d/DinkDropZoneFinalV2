import SwiftUI
import SwiftData

struct TournamentJoinView: View {
    let tournament: Tournament
    let tournamentService: TournamentService
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var currentStep = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Partner Selection
    @State private var partnerSelectionType: PartnerSelectionType = .none
    @State private var selectedPartnerID: String?
    @State private var selectedPartnerName: String?
    @State private var partnerEmail = ""
    @State private var teamName = ""
    @State private var needsPartner = false
    
    // Available users for partner selection
    @State private var availableUsers: [User] = []
    @State private var soloParticipants: [TournamentParticipant] = []
    
    private let steps = ["Join Type", "Partner Selection", "Team Details", "Confirm"]
    
    enum PartnerSelectionType: String, CaseIterable {
        case none = "Solo Entry"
        case invitePartner = "Invite Partner"
        case selectFromTournament = "Find Partner in Tournament"
        case waitForPartner = "Wait for Partner"
        
        var description: String {
            switch self {
            case .none:
                return "Join as individual (will be paired if needed)"
            case .invitePartner:
                return "Bring your own partner to the tournament"
            case .selectFromTournament:
                return "Choose from players already registered"
            case .waitForPartner:
                return "Join solo and wait to be paired"
            }
        }
        
        var icon: String {
            switch self {
            case .none: return "person.circle"
            case .invitePartner: return "person.badge.plus"
            case .selectFromTournament: return "person.2.circle"
            case .waitForPartner: return "clock.circle"
            }
        }
    }
    
    var isDoublesTournament: Bool {
        tournament.format.contains("Doubles")
    }
    
    var totalSteps: Int {
        isDoublesTournament ? 4 : 2 // Skip partner steps for singles
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Header
                progressHeader
                
                // Step Content
                ScrollView {
                    VStack(spacing: 32) {
                        stepContent
                    }
                    .padding()
                }
                
                // Navigation Buttons
                navigationButtons
            }
            .navigationTitle("Join Tournament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAvailableData()
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Tournament Info
            VStack(spacing: 8) {
                Text(tournament.name)
                    .font(.headline)
                    .fontWeight(.bold)
                
                HStack {
                    Label(tournament.format, systemImage: "sportscourt")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(tournament.participants.count)/\(tournament.maxParticipants)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            
            // Step Indicators
            HStack {
                ForEach(0..<totalSteps, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(index <= currentStep ? .brown : .gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .scaleEffect(index == currentStep ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3), value: currentStep)
                        
                        if index < totalSteps - 1 {
                            Rectangle()
                                .fill(index < currentStep ? .brown : .gray.opacity(0.3))
                                .frame(height: 2)
                                .animation(.easeInOut(duration: 0.3), value: currentStep)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            // Current Step Title
            if currentStep < steps.count {
                Text(steps[currentStep])
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.brown)
                    .animation(.easeInOut(duration: 0.2), value: currentStep)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: 
            joinTypeStep
        case 1: 
            if isDoublesTournament {
                partnerSelectionStep
            } else {
                teamDetailsStep
            }
        case 2: 
            if isDoublesTournament {
                teamDetailsStep
            } else {
                confirmStep
            }
        case 3: 
            confirmStep
        default: 
            joinTypeStep
        }
    }
    
    // MARK: - Step 1: Join Type
    
    private var joinTypeStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "How would you like to join?",
                subtitle: isDoublesTournament ? "Choose your participation style for this doubles tournament" : "Confirm your registration",
                icon: "person.circle.fill",
                color: .blue
            )
            
            if isDoublesTournament {
                VStack(spacing: 16) {
                    ForEach(PartnerSelectionType.allCases, id: \.self) { type in
                        PartnerTypeCard(
                            type: type,
                            isSelected: partnerSelectionType == type
                        ) {
                            partnerSelectionType = type
                        }
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Singles Tournament")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("You'll compete individually in this singles tournament.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.blue.opacity(0.1))
                )
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Step 2: Partner Selection
    
    private var partnerSelectionStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "Select Your Partner",
                subtitle: getPartnerStepSubtitle(),
                icon: "person.2.circle.fill",
                color: .green
            )
            
            switch partnerSelectionType {
            case .none, .waitForPartner:
                soloJoinView
            case .invitePartner:
                invitePartnerView
            case .selectFromTournament:
                selectFromTournamentView
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    private var soloJoinView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.circle.dashed")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Solo Entry")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("You'll be paired with another solo player or wait for a partner to join.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Toggle("Looking for a partner", isOn: $needsPartner)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.orange.opacity(0.1))
                )
        }
        .padding()
    }
    
    private var invitePartnerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.circle")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Invite Your Partner")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                TextField("Partner's Email", text: $partnerEmail)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                Text("We'll send them an invitation to join your team")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var selectFromTournamentView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 50))
                .foregroundColor(.green)
            
            Text("Choose a Partner")
                .font(.title3)
                .fontWeight(.bold)
            
            if soloParticipants.isEmpty {
                VStack(spacing: 12) {
                    Text("No solo players available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Be the first to join solo and wait for others!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.1))
                )
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(soloParticipants, id: \.id) { participant in
                        PartnerSelectionCard(
                            participant: participant,
                            isSelected: selectedPartnerID == participant.userID
                        ) {
                            selectedPartnerID = participant.userID
                            selectedPartnerName = participant.displayName
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - Step 3: Team Details
    
    private var teamDetailsStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "Team Details",
                subtitle: "Customize your team information",
                icon: "flag.circle.fill",
                color: .purple
            )
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "flag")
                            .foregroundColor(.purple)
                        Text("Team Name (Optional)")
                            .font(.headline)
                    }
                    
                    TextField("Enter team name", text: $teamName)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                }
                
                // Team Preview
                TeamPreviewCard(
                    playerName: appState.currentUser?.displayName ?? "You",
                    partnerName: getPartnerDisplayName(),
                    teamName: teamName
                )
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Step 4: Confirm
    
    private var confirmStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "Confirm Registration",
                subtitle: "Review your tournament entry",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            VStack(spacing: 16) {
                ConfirmationCard(
                    title: "Tournament Details",
                    items: [
                        ("Tournament", tournament.name),
                        ("Format", tournament.format),
                        ("Start Date", tournament.startDate.formatted(date: .abbreviated, time: .shortened)),
                        ("Venue", tournament.venueName.isEmpty ? "TBD" : tournament.venueName)
                    ]
                )
                
                if isDoublesTournament {
                    ConfirmationCard(
                        title: "Your Team",
                        items: [
                            ("Player 1", appState.currentUser?.displayName ?? "You"),
                            ("Player 2", getPartnerDisplayName()),
                            ("Team Name", teamName.isEmpty ? "No team name" : teamName),
                            ("Entry Type", partnerSelectionType.rawValue)
                        ]
                    )
                }
            }
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.red.opacity(0.1))
                    )
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep -= 1
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            
            Spacer()
            
            Button(currentStep == totalSteps - 1 ? "Join Tournament" : "Next") {
                if currentStep == totalSteps - 1 {
                    joinTournament()
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep += 1
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isLoading || !canProceed)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Helper Views
    
    private func stepHeader(title: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(color)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadAvailableData() {
        // Load solo participants looking for partners
        soloParticipants = tournament.participants.filter { participant in
            participant.partnerID == nil && participant.userID != appState.currentUser?.id.uuidString
        }
    }
    
    private func joinTournament() {
        guard let currentUser = appState.currentUser else {
            errorMessage = "User not available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Handle partner logic for doubles tournaments
                var partner: User? = nil
                if isDoublesTournament && partnerSelectionType == .selectFromTournament,
                   let partnerID = selectedPartnerID,
                   let partnerParticipant = soloParticipants.first(where: { $0.userID == partnerID }) {
                    
                    // Create a User object for the partner (simplified)
                    partner = User(
                        email: "partner@placeholder.com", // We don't have email from participant
                        password: "placeholder", // Placeholder password
                        displayName: partnerParticipant.displayName,
                        elo: partnerParticipant.elo
                    )
                }
                
                // Use tournament service to join tournament
                _ = partner?.displayName
                try await tournamentService.joinTournament(tournament, user: currentUser)
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                    
                    // Show success feedback
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    
                    // Send notification to refresh tournament views
                    NotificationCenter.default.post(
                        name: Notification.Name("tournamentUpdated"),
                        object: nil
                    )
                    
                    // Refresh tournaments in AppState
                    appState.refreshTournaments()
                }
                
                print("✅ Successfully joined tournament: \(tournament.name)")
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true
        case 1:
            if !isDoublesTournament { return true }
            switch partnerSelectionType {
            case .invitePartner: return !partnerEmail.isEmpty
            case .selectFromTournament: return selectedPartnerID != nil
            default: return true
            }
        case 2: return true
        case 3: return !isLoading
        default: return false
        }
    }
    
    private func getPartnerStepSubtitle() -> String {
        switch partnerSelectionType {
        case .none:
            return "Join as a solo player"
        case .invitePartner:
            return "Invite someone via email"
        case .selectFromTournament:
            return "Choose from registered players"
        case .waitForPartner:
            return "Wait to be paired"
        }
    }
    
    private func getPartnerDisplayName() -> String {
        switch partnerSelectionType {
        case .invitePartner:
            return partnerEmail.isEmpty ? "Partner (invited)" : partnerEmail
        case .selectFromTournament:
            return selectedPartnerName ?? "No partner selected"
        default:
            return "Solo entry"
        }
    }
}

// MARK: - Supporting Views

struct PartnerTypeCard: View {
    let type: TournamentJoinView.PartnerSelectionType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: type.icon)
                            .foregroundColor(.blue)
                        
                        Text(type.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .green.opacity(0.1) : .gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? .green : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct PartnerSelectionCard: View {
    let participant: TournamentParticipant
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(participant.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("ELO: \(participant.elo)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? .green.opacity(0.1) : .gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? .green : .clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct TeamPreviewCard: View {
    let playerName: String
    let partnerName: String
    let teamName: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(.purple)
                
                Text("Team Preview")
                    .font(.headline)
                    .fontWeight(.medium)
            }
            
            VStack(spacing: 8) {
                HStack {
                    Text("Team Name:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(teamName.isEmpty ? "No team name" : teamName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Players:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(playerName) & \(partnerName)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct ConfirmationCard: View {
    let title: String
    let items: [(String, String)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.green)
            
            VStack(spacing: 8) {
                ForEach(items, id: \.0) { item in
                    HStack {
                        Text(item.0)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(item.1)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    let tournament = Tournament(
        name: "Test Tournament",
        description: "Test doubles tournament",
        type: "Double Elimination",
        format: "Doubles",
        skillLevel: "Intermediate",
        organizerID: "test",
        organizerName: "Test Organizer"
    )
    
    let appState = AppState()
    let tournamentService = TournamentService(firebaseService: FirebaseService.shared)
    
    TournamentJoinView(tournament: tournament, tournamentService: tournamentService)
        .environmentObject(appState)
} 