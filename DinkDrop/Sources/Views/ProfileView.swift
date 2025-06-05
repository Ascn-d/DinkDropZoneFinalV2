import SwiftUI
import Observation

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        Form {
            if let user = appState.currentUser {
                Section("Profile") {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(user.email)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("ELO")
                        Spacer()
                        Text("\(user.elo)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("XP")
                        Spacer()
                        Text("\(user.xp)")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Log Out") {
                        appState.currentUser = nil
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Profile")
    }
}

#Preview {
    ProfileView()
        .environment(AppState())
} 