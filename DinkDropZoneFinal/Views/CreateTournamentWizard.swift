import SwiftUI
import MapKit
import FirebaseAuth

struct CreateTournamentWizard: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppState
    
    // Step management
    @State private var currentStep = 0
    private let totalSteps = 6 // Increased for new AI optimization step
    
    // Use AppState's tournament service
    private var tournamentService: TournamentService? {
        return appState.getTournamentService()
    }
    
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
    
    // AI & Enhanced Features
    @State private var useAIOptimization = true
    @State private var aiRecommendations: [AIRecommendation] = []
    @State private var isLoadingAI = false
    @State private var selectedTemplate: TournamentTemplate?
    @State private var enableLiveStreaming = false
    @State private var enableProfessionalFeatures = false
    @State private var socialMediaIntegration = false
    @State private var smartPricing = false
    @State private var autoBracketSeeding = true
    
    // UI State
    @State private var isCreating = false
    @State private var showingSuccessAlert = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var showingTemplates = false
    @State private var formValidationErrors: [String] = []
    
    private let stepTitles = [
        "Tournament Info",
        "Format & Rules", 
        "Venue & Schedule",
        "Advanced Settings",
        "AI Optimization",
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
            case 4: aiOptimizationStep
            case 5: reviewStep
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
    
    // MARK: - Step 5: AI Optimization
    private var aiOptimizationStep: some View {
        VStack(spacing: 20) {
            TournamentFormSection(title: "AI-Powered Optimization") {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Enable AI Optimization")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Get smart recommendations for your tournament")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $useAIOptimization)
                    }
                    
                    if useAIOptimization {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Auto Bracket Seeding")
                                Spacer()
                                Toggle("", isOn: $autoBracketSeeding)
                            }
                            
                            HStack {
                                Text("Smart Pricing")
                                Spacer()
                                Toggle("", isOn: $smartPricing)
                            }
                            
                            if smartPricing {
                                Text("AI will analyze local market data and suggest optimal entry fees")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 16)
                            }
                        }
                    }
                }
            }
            
            TournamentFormSection(title: "Professional Features") {
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Live Streaming")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Broadcast your tournament live")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $enableLiveStreaming)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Professional Package")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Advanced analytics, custom branding, premium support")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $enableProfessionalFeatures)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Social Media Integration")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Auto-post updates and results")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $socialMediaIntegration)
                    }
                }
            }
            
            if useAIOptimization && isLoadingAI {
                ProgressView("Analyzing tournament data...")
                    .padding()
            }
            
            if !aiRecommendations.isEmpty {
                TournamentFormSection(title: "AI Recommendations") {
                    VStack(spacing: 12) {
                        ForEach(aiRecommendations, id: \.id) { recommendation in
                            AIRecommendationCard(recommendation: recommendation) {
                                applyRecommendation(recommendation)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if useAIOptimization {
                loadAIRecommendations()
            }
        }
        .onChange(of: useAIOptimization) { _, newValue in
            if newValue {
                loadAIRecommendations()
            }
        }
    }
    
    // MARK: - Step 6: Review
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
                _ = try await tournamentService?.createTournament(
                    name: name,
                    description: description,
                    type: "Double Elimination",
                    format: selectedFormat.rawValue,
                    skillLevel: "Intermediate",
                    maxParticipants: maxParticipants,
                    startDate: startDate,
                    organizerID: Auth.auth().currentUser?.uid ?? "",
                    organizerName: appState.currentUser?.displayName ?? "",
                    venueName: venueName,
                    venueAddress: venueAddress
                )
                
                await MainActor.run {
                    isCreating = false
                    showingSuccessAlert = true
                    
                    // Refresh tournaments in AppState
                    appState.refreshTournaments()
                    
                    // Send notification to refresh tournament views
                    NotificationCenter.default.post(
                        name: Notification.Name("tournamentCreated"),
                        object: nil
                    )
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
        
        // Reset AI features
        useAIOptimization = true
        aiRecommendations = []
        isLoadingAI = false
        selectedTemplate = nil
        enableLiveStreaming = false
        enableProfessionalFeatures = false
        socialMediaIntegration = false
        smartPricing = false
        autoBracketSeeding = true
    }
    
    // MARK: - AI Optimization Methods
    private func loadAIRecommendations() {
        isLoadingAI = true
        
        Task {
            do {
                // Simulate AI analysis
                try await Task.sleep(for: .seconds(2))
                
                let recommendations = await generateAIRecommendations()
                
                await MainActor.run {
                    self.aiRecommendations = recommendations
                    self.isLoadingAI = false
                }
            } catch {
                await MainActor.run {
                    self.isLoadingAI = false
                }
            }
        }
    }
    
    private func generateAIRecommendations() async -> [AIRecommendation] {
        var recommendations: [AIRecommendation] = []
        
        // Analyze tournament data and generate recommendations
        if smartPricing {
            let suggestedFee = calculateOptimalEntryFee()
            if suggestedFee != entryFee {
                recommendations.append(AIRecommendation(
                    id: "pricing",
                    title: "Optimize Entry Fee",
                    description: "Based on local market analysis, we recommend an entry fee of $\(String(format: "%.2f", suggestedFee)) to maximize participation",
                    impact: "High",
                    action: "price_optimization",
                    value: suggestedFee
                ))
            }
        }
        
        if autoBracketSeeding {
            recommendations.append(AIRecommendation(
                id: "seeding",
                title: "Smart Bracket Seeding",
                description: "Enable automatic bracket seeding based on player ELO ratings for more competitive matches",
                impact: "Medium",
                action: "enable_seeding",
                value: nil
            ))
        }
        
        // Time optimization
        let optimalTime = calculateOptimalStartTime()
        if optimalTime != startDate {
            recommendations.append(AIRecommendation(
                id: "timing",
                title: "Optimal Start Time",
                description: "Based on player activity patterns, starting at \(DateFormatter.shortTime.string(from: optimalTime)) may increase participation",
                impact: "Medium",
                action: "time_optimization",
                value: optimalTime
            ))
        }
        
        // Format recommendation
        if selectedFormat != .doubles {
            recommendations.append(AIRecommendation(
                id: "format",
                title: "Format Suggestion",
                description: "Doubles tournaments typically have 40% higher participation rates in your area",
                impact: "High",
                action: "format_suggestion",
                value: TournamentFormat.doubles
            ))
        }
        
        return recommendations
    }
    
    private func calculateOptimalEntryFee() -> Double {
        // Simulate AI calculation based on:
        // - Local market data
        // - Historical participation rates
        // - Player demographics
        // - Tournament type and format
        
        let basePrice = 25.0
        let marketMultiplier = 1.2 // Based on local market
        let formatMultiplier = selectedFormat == .doubles ? 1.3 : 1.0
        let participantMultiplier = Double(maxParticipants) / 32.0
        
        return basePrice * marketMultiplier * formatMultiplier * participantMultiplier
    }
    
    private func calculateOptimalStartTime() -> Date {
        // Simulate AI calculation for optimal start time
        // Based on player activity patterns, weather data, etc.
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: startDate)
        
        // Most tournaments perform best starting at 10 AM on weekends
        components.hour = 10
        components.minute = 0
        
        return calendar.date(from: components) ?? startDate
    }
    
    private func applyRecommendation(_ recommendation: AIRecommendation) {
        switch recommendation.action {
        case "price_optimization":
            if let newPrice = recommendation.value as? Double {
                entryFee = newPrice
            }
        case "time_optimization":
            if let newTime = recommendation.value as? Date {
                startDate = newTime
            }
        case "format_suggestion":
            if let newFormat = recommendation.value as? TournamentFormat {
                selectedFormat = newFormat
            }
        case "enable_seeding":
            autoBracketSeeding = true
        default:
            break
        }
        
        // Remove applied recommendation
        aiRecommendations.removeAll { $0.id == recommendation.id }
    }
}

// MARK: - Supporting Structures

struct AIRecommendation: Identifiable {
    let id: String
    let title: String
    let description: String
    let impact: String
    let action: String
    let value: Any?
}

struct TournamentTemplate: Identifiable {
    let id: String
    let name: String
    let description: String
    let format: TournamentFormat
    let maxParticipants: Int
    let entryFee: Double
    let estimatedDuration: Int
}

// MARK: - Supporting Views

struct AIRecommendationCard: View {
    let recommendation: AIRecommendation
    let onApply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Text(recommendation.impact)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(impactColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(impactColor.opacity(0.1))
                        .cornerRadius(6)
                    
                    Button("Apply") {
                        onApply()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var impactColor: Color {
        switch recommendation.impact {
        case "High": return .red
        case "Medium": return .orange
        case "Low": return .green
        default: return .gray
        }
    }
}

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

struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let bounds: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(minValue, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(maxValue, specifier: "%.1f")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Slider(value: $minValue, in: bounds.lowerBound...maxValue, step: step)
                        .tint(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Max")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Slider(value: $maxValue, in: minValue...bounds.upperBound, step: step)
                        .tint(.blue)
                }
            }
        }
    }
}

struct TournamentFormatCard: View {
    let format: TournamentFormat
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(format.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
    
    private var iconName: String {
        switch format {
        case .singles: return "person.circle"
        case .doubles: return "person.2.circle"
        case .mixedDoubles: return "person.2.circle.fill"
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
    
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

extension TournamentFormat {
    var displayName: String {
        switch self {
        case .singles: return "Singles"
        case .doubles: return "Doubles"
        case .mixedDoubles: return "Mixed Doubles"
        }
    }
} 