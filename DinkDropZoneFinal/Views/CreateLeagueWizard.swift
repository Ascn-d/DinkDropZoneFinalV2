import SwiftUI
import SwiftData

struct CreateLeagueWizard: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var currentStep = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Tournament Details
    @State private var tournamentName = ""
    @State private var tournamentDescription = ""
    @State private var tournamentType: TournamentType = .doubleElimination
    @State private var format: TournamentFormat = .doubles
    @State private var skillLevel = "Intermediate"
    @State private var maxParticipants = 16
    @State private var startDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var venueName = ""
    @State private var venueAddress = ""
    @State private var isPrivate = false
    @State private var requiresApproval = false
    @State private var entryFee: Double = 0
    
    private let steps = ["Basic Info", "Format & Rules", "Venue & Schedule", "Settings", "Review"]
    private let skillLevelOptions = ["Beginner", "Intermediate", "Advanced", "Pro", "Open"]
    private let participantOptions = [8, 16, 32, 64, 128]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Indicator
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
            .navigationTitle("Create Tournament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Step Indicators
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(index <= currentStep ? .brown : .gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                            .scaleEffect(index == currentStep ? 1.3 : 1.0)
                            .animation(.spring(response: 0.3), value: currentStep)
                        
                        if index < steps.count - 1 {
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
            Text(steps[currentStep])
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.brown)
                .animation(.easeInOut(duration: 0.2), value: currentStep)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0: basicInfoStep
        case 1: formatStep
        case 2: venueStep
        case 3: settingsStep
        case 4: reviewStep
        default: basicInfoStep
        }
    }
    
    // MARK: - Step 1: Basic Info
    
    private var basicInfoStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "Tournament Basics",
                subtitle: "Let's start with the essential details",
                icon: "trophy.fill",
                color: .brown
            )
            
            VStack(spacing: 20) {
                                 TournamentTextField(
                     title: "Tournament Name",
                     text: $tournamentName,
                     icon: "trophy",
                     placeholder: "Enter tournament name"
                 )
                
                                 TournamentTextEditor(
                     title: "Description (Optional)",
                     text: $tournamentDescription,
                     icon: "text.alignleft",
                     placeholder: "Describe your tournament..."
                 )
                
                                 TournamentPickerField(
                     title: "Skill Level",
                     selection: $skillLevel,
                     options: skillLevelOptions,
                     icon: "star.circle"
                 )
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Step 2: Format & Rules
    
    private var formatStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "Tournament Format",
                subtitle: "Choose how the tournament will be structured",
                icon: "list.bullet.circle.fill",
                color: .green
            )
            
            VStack(spacing: 20) {
                // Tournament Type Selection
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "trophy.circle")
                            .foregroundColor(.green)
                        Text("Tournament Type")
                            .font(.headline)
                    }
                    
                    ForEach(TournamentType.allCases, id: \.self) { type in
                        TypeSelectionCard(
                            title: type.rawValue,
                            description: typeDescription(for: type),
                            isSelected: tournamentType == type
                        ) {
                            tournamentType = type
                        }
                    }
                }
                
                // Match Format Selection
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.2.circle")
                            .foregroundColor(.green)
                        Text("Match Format")
                            .font(.headline)
                    }
                    
                    ForEach(TournamentFormat.allCases, id: \.self) { fmt in
                        TypeSelectionCard(
                            title: fmt.rawValue,
                            description: formatDescription(for: fmt),
                            isSelected: format == fmt
                        ) {
                            format = fmt
                        }
                    }
                }
                
                                 // Max Participants
                 TournamentPickerField(
                     title: "Maximum Participants",
                     selection: .constant("\(maxParticipants) players"),
                     options: participantOptions.map { "\($0) players" },
                     icon: "person.3"
                 ) { selectedIndex in
                     maxParticipants = participantOptions[selectedIndex]
                 }
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Step 3: Venue & Schedule
    
    private var venueStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "Venue & Schedule",
                subtitle: "When and where will the tournament take place?",
                icon: "calendar.circle.fill",
                color: .blue
            )
            
            VStack(spacing: 20) {
                                 TournamentTextField(
                     title: "Venue Name",
                     text: $venueName,
                     icon: "location.circle",
                     placeholder: "e.g., Central Park Courts"
                 )
                 
                 TournamentTextField(
                     title: "Venue Address",
                     text: $venueAddress,
                     icon: "mappin.circle",
                     placeholder: "Enter full address"
                 )
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar.circle")
                            .foregroundColor(.blue)
                        Text("Start Date & Time")
                            .font(.headline)
                    }
                    
                    DatePicker(
                        "Tournament Start",
                        selection: $startDate,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Step 4: Settings
    
    private var settingsStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "Tournament Settings",
                subtitle: "Configure additional options",
                icon: "gearshape.circle.fill",
                color: .purple
            )
            
            VStack(spacing: 20) {
                ToggleCard(
                    title: "Private Tournament",
                    description: "Only invited players can join",
                    icon: "eye.slash",
                    isOn: $isPrivate
                )
                
                ToggleCard(
                    title: "Require Approval",
                    description: "Manually approve participant registrations",
                    icon: "checkmark.shield",
                    isOn: $requiresApproval
                )
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "dollarsign.circle")
                            .foregroundColor(.purple)
                        Text("Entry Fee (Optional)")
                            .font(.headline)
                    }
                    
                    HStack {
                        Text("$")
                            .font(.title2)
                            .fontWeight(.medium)
                        
                        TextField("0.00", value: $entryFee, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Step 5: Review
    
    private var reviewStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "Review & Create",
                subtitle: "Confirm your tournament details",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            VStack(spacing: 16) {
                ReviewCard(
                    title: "Tournament Details",
                    items: [
                        ("Name", tournamentName),
                        ("Type", tournamentType.rawValue),
                        ("Format", format.rawValue),
                        ("Skill Level", skillLevel),
                        ("Max Participants", "\(maxParticipants) players")
                    ]
                )
                
                ReviewCard(
                    title: "Venue & Schedule",
                    items: [
                        ("Venue", venueName.isEmpty ? "TBD" : venueName),
                        ("Address", venueAddress.isEmpty ? "TBD" : venueAddress),
                        ("Start Date", startDate.formatted(date: .abbreviated, time: .shortened))
                    ]
                )
                
                ReviewCard(
                    title: "Settings",
                    items: [
                        ("Privacy", isPrivate ? "Private" : "Public"),
                        ("Approval", requiresApproval ? "Required" : "Automatic"),
                                                 ("Entry Fee", entryFee > 0 ? String(format: "$%.2f", entryFee) : "Free")
                    ]
                )
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
            
            Button(currentStep == steps.count - 1 ? "Create Tournament" : "Next") {
                if currentStep == steps.count - 1 {
                    createTournament()
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
    
    // MARK: - Validation & Actions
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !tournamentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1: return true // Tournament type and format have defaults
        case 2: return true // Venue is optional
        case 3: return true // Settings are optional
        case 4: return !isLoading
        default: return false
        }
    }
    
    private func createTournament() {
        guard let tournamentService = appState.getTournamentService(),
              let currentUser = appState.currentUser else {
            errorMessage = "Tournament service not available"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let tournament = try await tournamentService.createTournament(
                    name: tournamentName,
                    description: tournamentDescription,
                    type: tournamentType.rawValue,
                    format: format.rawValue,
                    skillLevel: skillLevel,
                    maxParticipants: maxParticipants,
                    startDate: startDate,
                    organizerID: currentUser.id.uuidString,
                    organizerName: currentUser.displayName,
                    venueName: venueName,
                    venueAddress: venueAddress
                )
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                    
                    // Show success feedback
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }
                
                print("✅ Tournament created successfully: \(tournament.name)")
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func typeDescription(for type: TournamentType) -> String {
        switch type {
        case .singleElimination: return "One loss and you're out"
        case .doubleElimination: return "Two losses to be eliminated"
        case .roundRobin: return "Everyone plays everyone"
        case .swiss: return "Pairs players with similar records"
        }
    }
    
    private func formatDescription(for format: TournamentFormat) -> String {
        switch format {
        case .singles: return "Individual competition"
        case .doubles: return "Teams of two players"
        case .mixedDoubles: return "One male, one female per team"
        }
    }
}

// MARK: - Custom Components

struct TournamentTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.brown)
                Text(title)
                    .font(.headline)
            }
            
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
        }
    }
}

struct TournamentTextEditor: View {
    let title: String
    @Binding var text: String
    let icon: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.brown)
                Text(title)
                    .font(.headline)
            }
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: 100)
                    .padding(8)
                
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }
}

struct TournamentPickerField: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    let icon: String
    var onSelectionChange: ((Int) -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.brown)
                Text(title)
                    .font(.headline)
            }
            
            Menu {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button(option) {
                        selection = option
                        onSelectionChange?(index)
                    }
                }
            } label: {
                HStack {
                    Text(selection)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
        }
    }
}

struct TypeSelectionCard: View {
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .green : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .green.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? .green : .clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct ToggleCard: View {
    let title: String
    let description: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.purple)
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

struct ReviewCard: View {
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
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.green.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    CreateLeagueWizard()
        .environmentObject(AppState())
} 