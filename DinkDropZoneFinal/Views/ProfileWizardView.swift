import SwiftUI
import Observation

struct ProfileWizardView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var step: Int = 0
    @State private var displayName: String = ""
    @State private var location: String = ""
    @State private var skillLevel: SkillLevel = .beginner

    private var user: User? { appState.currentUser }

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                ProgressView(value: Double(step), total: 2)
                    .padding(.top)

                stepView
                Spacer()
                HStack {
                    if step > 0 {
                        Button("Back") { step -= 1 }
                    }
                    Spacer()
                    Button(step < 2 ? "Next" : "Finish") {
                        handleNext()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!isStepValid)
                }
            }
            .padding()
            .navigationTitle("Profile Setup")
            .navigationBarBackButtonHidden()
        }
        .onAppear {
            if let u = user {
                displayName = u.displayName
                location = u.location
                if let level = SkillLevel(rawValue: u.skillLevel) { skillLevel = level }
            }
        }
    }

    @ViewBuilder
    private var stepView: some View {
        switch step {
        case 0: nameStep
        case 1: locationStep
        default: skillStep
        }
    }

    // MARK: Steps
    private var nameStep: some View {
        VStack(spacing: 20) {
            Text("Choose a display name")
                .font(.title2.bold())
            TextField("Display Name", text: $displayName)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var locationStep: some View {
        VStack(spacing: 20) {
            Text("Where do you play?")
                .font(.title2.bold())
            TextField("City or Club", text: $location)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var skillStep: some View {
        VStack(spacing: 20) {
            Text("Select your skill level")
                .font(.title2.bold())
            Picker("Skill", selection: $skillLevel) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    Text(level.rawValue).tag(level)
                }
            }
            .pickerStyle(.wheel)
        }
    }

    private var isStepValid: Bool {
        switch step {
        case 0: return !displayName.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return !location.trimmingCharacters(in: .whitespaces).isEmpty
        default: return true
        }
    }

    private func handleNext() {
        if step < 2 {
            step += 1
            return
        }
        // Save data to user
        guard let user = user else { return }
        user.displayName = displayName
        user.location = location
        user.skillLevel = skillLevel.rawValue
        appState.markProfileComplete()
        dismiss()
    }
}

#Preview {
    let state = AppState()
    state.currentUser = User(email: "test@demo.com", password: "", elo: 1000, xp: 0, totalMatches: 0, wins: 0, losses: 0, winStreak: 0)
    return ProfileWizardView().environment(state)
} 