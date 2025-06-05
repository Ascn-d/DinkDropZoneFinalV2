import SwiftUI
import Observation

struct QueueView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var context
    @State private var isFindingMatch = false
    private var matchService: MatchService { MatchService(context: context) }

    var body: some View {
        VStack(spacing: 24) {
            if let match = appState.currentMatch {
                Text("Matched! \(match.player1.email) vs \(match.player2.email)")
            }

            Button(isFindingMatch ? "Finding…" : "Find Match") {
                Task {
                    await findMatch()
                }
            }
            .disabled(isFindingMatch)
        }
        .navigationTitle("Queue")
        .padding()
    }

    private func findMatch() async {
        guard let user = appState.currentUser else { return }
        isFindingMatch = true
        if let match = await matchService.enqueue(user) {
            await MainActor.run {
                appState.currentMatch = match
            }
        }
        isFindingMatch = false
    }
}

#Preview {
    QueueView()
        .environment(AppState())
} 