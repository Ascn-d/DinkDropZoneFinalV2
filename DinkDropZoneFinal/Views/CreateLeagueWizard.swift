import SwiftUI
import SwiftData
import Observation

struct CreateLeagueWizard: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState
    
    enum Step: Int { case name = 0, settings, details, review }
    @State private var step: Step = .name
    
    // Inputs
    @State private var name: String = ""
    @State private var format: LeagueFormat = .roundRobin
    @State private var maxParticipants: Int = 16
    @State private var description: String = ""
    @State private var startDate: Date = .now
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: .now) ?? .now
    @State private var minSkill: Double = 2.0
    @State private var maxSkill: Double = 5.0
    
    private var leagueService: LeagueService? { appState.getLeagueService() }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                ProgressView(value: Double(step.rawValue), total: Double(Step.review.rawValue))
                    .padding(.top)
                
                wizardContent
                Spacer()
                HStack {
                    if step != .name { Button("Back", action: prev) }
                    Spacer()
                    Button(step == .review ? "Create" : "Next", action: next)
                        .buttonStyle(.borderedProminent)
                        .disabled(!isValid)
                }
            }
            .padding()
            .navigationTitle("New League")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: { dismiss() }) } }
        }
    }
    
    @ViewBuilder private var wizardContent: some View {
        switch step {
        case .name:
            VStack(spacing: 24) {
                Text("League Name").font(.title2.bold())
                TextField("e.g. Sunday Smash Series", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
        case .settings:
            VStack(spacing: 16) {
                Picker("Format", selection: $format) {
                    ForEach(LeagueFormat.allCases, id: \.self) { format in
                        Text(format.rawValue)
                            .tag(format)
                    }
                }
                .pickerStyle(.segmented)
                
                Stepper(value: $maxParticipants, in: 4...64, step: 4) {
                    Text("Max Players: \(maxParticipants)")
                }
            }
            .frame(maxHeight: 250)
        case .details:
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Description").font(.headline)
                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3, reservesSpace: true)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Season Dates").font(.headline)
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skill Range").font(.headline)
                    HStack {
                        Slider(value: $minSkill, in: 1...5, step: 0.5)
                        Text(String(format: "%.1f", minSkill))
                    }
                    HStack {
                        Slider(value: $maxSkill, in: minSkill...5, step: 0.5)
                        Text(String(format: "%.1f", maxSkill))
                    }
                }
            }
            .frame(maxHeight: 350)
        case .review:
            VStack(spacing: 16) {
                reviewRow(label: "Name", value: name)
                reviewRow(label: "Format", value: format.rawValue.capitalized)
                reviewRow(label: "Max Players", value: "\(maxParticipants)")
                reviewRow(label: "Starts", value: DateFormatter.localizedString(from: startDate, dateStyle: .medium, timeStyle: .none))
                reviewRow(label: "Ends", value: DateFormatter.localizedString(from: endDate, dateStyle: .medium, timeStyle: .none))
                reviewRow(label: "Skill Range", value: String(format: "%.1f – %.1f", minSkill, maxSkill))
                Text("Looks good! Tap Create to finish.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func reviewRow(label: String, value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).foregroundColor(.secondary) }
    }
    
    private var isValid: Bool {
        if step == .name { return !name.trimmingCharacters(in: .whitespaces).isEmpty }
        return true
    }
    
    private func next() {
        switch step {
        case .name: step = .settings
        case .settings: step = .details
        case .details: step = .review
        case .review: createLeague()
        }
    }
    
    private func prev() {
        if let prevStep = Step(rawValue: step.rawValue - 1) { step = prevStep }
    }
    
    private func createLeague() {
        guard let owner = appState.currentUser,
              let leagueService = leagueService,
              let api = appState.getNetworkService() else { return }
        Task {
            do {
                let dto = try await api.createLeague(.init(
                    name: name,
                    description: description,
                    location: "Downtown Courts", // TODO: Add location picker
                    format: format.rawValue,
                    maxParticipants: maxParticipants,
                    price: 49.99, // TODO: Add price field
                    rating: 0.0,
                    imageUrl: nil,
                    schedule: "Mon/Wed 6-8pm", // TODO: Add schedule picker
                    nextGame: nil,
                    tags: ["Competitive", "Beginner Friendly"], // TODO: Add tag picker
                    skillLevel: "Beginner" // TODO: Add skill level picker
                ))
                await MainActor.run {
                    _ = leagueService.importLeague(from: dto)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    dismiss()
                }
            } catch {
                // Fallback to local create on failure
                _ = leagueService.createLeague(
                    name: name,
                    description: description,
                    location: "Downtown Courts",
                    owner: owner,
                    format: format,
                    maxParticipants: maxParticipants,
                    price: 49.99,
                    rating: 0.0,
                    imageUrl: nil,
                    schedule: "Mon/Wed 6-8pm",
                    nextGame: nil,
                    tags: ["Competitive", "Beginner Friendly"],
                    skillLevel: "Beginner"
                )
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                dismiss()
            }
        }
    }
}

#Preview {
    let state = AppState()
    state.currentUser = User(email: "demo", password: "", elo: 1000, xp: 0, totalMatches: 0, wins: 0, losses: 0, winStreak: 0)
    return CreateLeagueWizard().environment(state)
} 