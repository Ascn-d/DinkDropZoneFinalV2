import SwiftUI
import Observation

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    var body: some View {
        VStack(spacing: 16) {
            if let user = appState.currentUser {
                Text("ELO: \(user.elo)")
                    .font(.headline)
                Text("XP: \(user.xp)")
                    .font(.subheadline)
            }
            Text("Last 3 matches placeholder")
                .foregroundColor(.secondary)
        }
        .navigationTitle("Dashboard")
    }
}

#Preview {
    DashboardView()
        .environment(AppState())
} 