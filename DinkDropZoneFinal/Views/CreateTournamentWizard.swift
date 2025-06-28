import SwiftUI
import MapKit

struct CreateTournamentWizard: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    @StateObject private var tournamentService = TournamentService(firebaseService: FirebaseService.shared)
    
    // Step management
    @State private var currentStep = 0
    private let totalSteps = 5
    
    // Tournament data
    @State private var name = ""
    @State private var description = ""
    @State private var selectedFormat: TournamentFormat = .doubles
    @State private var maxParticipants = 16
    @State private var entryFee = 0.0
    @State private var prizePool = 0.0
    @State private var isPublic = true
    @State private var requiresApproval = false
    @State private var allowPartners = true
    @State private var minRating = 0.0
    @State private var maxRating = 5.0
    
    // Venue & Schedule
    @State private var venueName = ""
    @State private var venueAddress = ""
    @State private var startDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    @State private var registrationDeadline = Date()
    @State private var estimatedDuration = 3 // hours
    
    // Advanced settings
    @State private var maxGamesPerMatch = 3
    @State private var gameToPoints = 11
    @State private var mustWinByTwo = true
    @State private var useTimeouts = true
    @State private var timeoutDuration = 60 // seconds
    
    // UI State
    @State private var isCreating = false
    @State private var showingSuccessAlert = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    private let stepTitles = [
        "Tournament Info",
        "Format & Rules", 
        "Venue & Schedule",
        "Advanced Settings",
        "Review & Create"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                progressHeader
                stepContent
                navigationButtons
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitle("Create Tournament", displayMode: .inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .alert("Tournament Created!", isPresented: $showingSuccessAlert) {
            Button("View Tournament") {
                // Navigate to tournament detail
                presentationMode.wrappedValue.dismiss()
            }
            Button("Create Another") {
                resetForm()
            }
            Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your tournament '\(name)' has been created successfully!")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Progress bar
            ProgressView(value: Double(currentStep), total: Double(totalSteps - 1))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            // Step indicator
            HStack {
                ForEach(0..<totalSteps, id: \.self) { step in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(step + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(step <= currentStep ? .white : .gray)
                            )
                        
                        Text(stepTitles[step])
                            .font(.caption2)
                            .foregroundColor(step <= currentStep ? .blue : .gray)
                            .multilineTextAlignment(.center)
                            .frame(width: 70)
                    }
                    
                    if step < totalSteps - 1 {
                        Rectangle()
                            .fill(step < currentStep ? Color.blue : Color.gray.opacity(0.3))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .shadow(radius: 2)
    }
    
    // MARK: - Step Content
    @ViewBuilder
    private var stepContent: some View {
        ScrollView {
            switch currentStep {
            case 0: basicInfoStep
            case 1: formatAndRulesStep
            case 2: venueAndScheduleStep
            case 3: advancedSettingsStep
            case 4: reviewStep
            default: basicInfoStep
            }
        }
        .padding()
    }
    
    // MARK: - Step 1: Basic Info
    private var basicInfoStep: some View {
        VStack(spacing: 20) {
            TournamentFormSection(title: "Tournament Details") {
                TournamentCreationTextField(
                    title: "Tournament Name",
                    text: $name,
                    placeholder: "Enter tournament name"
                )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description")
                        .font(.headline)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            
            TournamentFormSection(title: "Tournament Type") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Public Tournament")
                        Spacer()
                        Toggle("", isOn: $isPublic)
                    }
                    
                    if !isPublic {
                        HStack {
                            Text("Requires Approval")
                            Spacer()
                            Toggle("", isOn: $requiresApproval)
                        }
                    }
                    
                    HStack {
                        Text("Allow Partners")
                        Spacer()
                        Toggle("", isOn: $allowPartners)
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Format & Rules
    private var formatAndRulesStep: some View {
        VStack(spacing: 20) {
            TournamentFormSection(title: "Tournament Format") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(TournamentFormat.allCases, id: \.self) { format in
                        TournamentFormatCard(
                            format: format,
                            isSelected: selectedFormat == format
                        ) {
                            selectedFormat = format
                        }
                    }
                }
            }
            
            TournamentFormSection(title: "Participants") {
                VStack(spacing: 16) {
                    HStack {
                        Text("Max Participants")
                        Spacer()
                        Picker("Max Participants", selection: $maxParticipants) {
                            ForEach([8, 16, 32, 64, 128], id: \.self) { count in
                                Text("\(count)").tag(count)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Rating Range")
                            Spacer()
                            Text("\(String(format: "%.1f", minRating)) - \(String(format: "%.1f", maxRating))")
                                .foregroundColor(.secondary)
                        }
                        
                        RangeSlider(
                            minValue: $minRating,
                            maxValue: $maxRating,
                            bounds: 0...5,
                            step: 0.1
                        )
                    }
                }
            }
            
            TournamentFormSection(title: "Prize Information") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Entry Fee")
                        Spacer()
                        Text("$")
                        TextField("0.00", value: $entryFee, format: .currency(code: "USD"))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Additional Prize Pool")
                        Spacer()
                        Text("$")
                        TextField("0.00", value: $prizePool, format: .currency(code: "USD"))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Total Prize Pool")
                        Spacer()
                        Text("$\(String(format: "%.2f", totalPrizePool))")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    // MARK: - Step 3: Venue & Schedule
    private var venueAndScheduleStep: some View {
        VStack(spacing: 20) {
            TournamentFormSection(title: "Venue Information") {
                VStack(spacing: 12) {
                    TournamentCreationTextField(
                        title: "Venue Name",
                        text: $venueName,
                        placeholder: "Enter venue name"
                    )
                    
                    TournamentCreationTextField(
                        title: "Address",
                        text: $venueAddress,
                        placeholder: "Enter full address"
                    )
                }
            }
            
            TournamentFormSection(title: "Schedule") {
                VStack(spacing: 16) {
                    DatePicker("Tournament Date", selection: $startDate, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    DatePicker("Registration Deadline", selection: $registrationDeadline, displayedComponents: [.date, .hourAndMinute])
                        .datePickerStyle(CompactDatePickerStyle())
                    
                    HStack {
                        Text("Estimated Duration")
                        Spacer()
                        Picker("Duration", selection: $estimatedDuration) {
                            ForEach(1...12, id: \.self) { hours in
                                Text("\(hours) hour\(hours == 1 ? "" : "s")").tag(hours)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
        }
    }
    
    // MARK: - Step 4: Advanced Settings
    private var advancedSettingsStep: some View {
        VStack(spacing: 20) {
            TournamentFormSection(title: "Game Rules") {
                VStack(spacing: 16) {
                    HStack {
                        Text("Games per Match")
                        Spacer()
                        Picker("Games per Match", selection: $maxGamesPerMatch) {
                            ForEach([1, 3, 5], id: \.self) { games in
                                Text("\(games)").tag(games)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                    }
                    
                    HStack {
                        Text("Points per Game")
                        Spacer()
                        Picker("Points per Game", selection: $gameToPoints) {
                            ForEach([11, 15, 21], id: \.self) { points in
                                Text("\(points)").tag(points)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Must Win by 2")
                        Spacer()
                        Toggle("", isOn: $mustWinByTwo)
                    }
                }
            }
            
            TournamentFormSection(title: "Timeout Rules") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Allow Timeouts")
                        Spacer()
                        Toggle("", isOn: $useTimeouts)
                    }
                    
                    if useTimeouts {
                        HStack {
                            Text("Timeout Duration")
                            Spacer()
                            Picker("Timeout Duration", selection: $timeoutDuration) {
                                ForEach([30, 60, 90, 120], id: \.self) { seconds in
                                    Text("\(seconds)s").tag(seconds)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 5: Review
    private var reviewStep: some View {
        VStack(spacing: 20) {
            TournamentFormSection(title: "Tournament Summary") {
                VStack(spacing: 12) {
                    ReviewRow(title: "Name", value: name)
                    ReviewRow(title: "Format", value: selectedFormat.rawValue)
                    ReviewRow(title: "Max Participants", value: "\(maxParticipants)")
                    ReviewRow(title: "Entry Fee", value: "$\(String(format: "%.2f", entryFee))")
                    ReviewRow(title: "Total Prize Pool", value: "$\(String(format: "%.2f", totalPrizePool))")
                }
            }
            
            TournamentFormSection(title: "Schedule & Venue") {
                VStack(spacing: 12) {
                    ReviewRow(title: "Venue", value: venueName)
                    ReviewRow(title: "Date", value: DateFormatter.friendly.string(from: startDate))
                    ReviewRow(title: "Registration Deadline", value: DateFormatter.friendly.string(from: registrationDeadline))
                    ReviewRow(title: "Duration", value: "\(estimatedDuration) hours")
                }
            }
            
            TournamentFormSection(title: "Game Rules") {
                VStack(spacing: 12) {
                    ReviewRow(title: "Games per Match", value: "\(maxGamesPerMatch)")
                    ReviewRow(title: "Points per Game", value: "\(gameToPoints)")
                    ReviewRow(title: "Must Win by 2", value: mustWinByTwo ? "Yes" : "No")
                    ReviewRow(title: "Timeouts", value: useTimeouts ? "\(timeoutDuration)s" : "Disabled")
                }
            }
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button("Previous") {
                    withAnimation {
                        currentStep -= 1
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            Spacer()
            
            if currentStep < totalSteps - 1 {
                Button("Next") {
                    withAnimation {
                        currentStep += 1
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canProceedFromCurrentStep)
            } else {
                Button(isCreating ? "Creating..." : "Create Tournament") {
                    createTournament()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isCreating || !isFormValid)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Computed Properties
    private var totalPrizePool: Double {
        return (entryFee * Double(maxParticipants)) + prizePool
    }
    
    private var canProceedFromCurrentStep: Bool {
        switch currentStep {
        case 0: return !name.isEmpty
        case 1: return true
        case 2: return !venueName.isEmpty && !venueAddress.isEmpty
        case 3: return true
        default: return true
        }
    }
    
    private var isFormValid: Bool {
        return !name.isEmpty && !venueName.isEmpty && !venueAddress.isEmpty
    }
    
    // MARK: - Actions
    private func createTournament() {
        guard !isCreating else { return }
        
        isCreating = true
        
        Task {
            do {
                _ = try await tournamentService.createTournament(
                    name: name,
                    description: description,
                    type: "Double Elimination",
                    format: selectedFormat.rawValue,
                    skillLevel: "Intermediate",
                    maxParticipants: maxParticipants,
                    startDate: startDate,
                    organizerID: appState.currentUser?.id.uuidString ?? "",
                    organizerName: appState.currentUser?.displayName ?? "",
                    venueName: venueName,
                    venueAddress: venueAddress
                )
                
                await MainActor.run {
                    isCreating = false
                    showingSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
    
    private func resetForm() {
        currentStep = 0
        name = ""
        description = ""
        selectedFormat = .doubles
        maxParticipants = 16
        entryFee = 0.0
        prizePool = 0.0
        isPublic = true
        requiresApproval = false
        allowPartners = true
        minRating = 0.0
        maxRating = 5.0
        venueName = ""
        venueAddress = ""
        startDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        registrationDeadline = Date()
        estimatedDuration = 3
        maxGamesPerMatch = 3
        gameToPoints = 11
        mustWinByTwo = true
        useTimeouts = true
        timeoutDuration = 60
    }
}

// MARK: - Supporting Views

struct TournamentFormSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                content
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

struct TournamentCreationTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct TournamentFormatCard: View {
    let format: TournamentFormat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: format.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(format.rawValue)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ReviewRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let bounds: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("Min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $minValue, in: bounds.lowerBound...maxValue, step: step)
                }
                
                VStack {
                    Text("Max")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $maxValue, in: minValue...bounds.upperBound, step: step)
                }
            }
        }
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.blue)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Extensions

extension TournamentFormat {
    var iconName: String {
        switch self {
        case .singles: return "person.circle"
        case .doubles: return "person.2.circle"
        case .mixedDoubles: return "person.2.fill"
        }
    }
}

extension DateFormatter {
    static let friendly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
} 