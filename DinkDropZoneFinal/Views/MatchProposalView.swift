import SwiftUI

struct MatchProposalView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let proposal: DinkDropZoneFinal.MMMatchProposal
    
    // Countdown
    @State private var timeRemaining: Int = 30
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Match Found!")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Match Type:")
                        .fontWeight(.medium)
                    Spacer()
                    Text(proposal.potentialMatch.matchType.rawValue)
                        .foregroundColor(proposal.potentialMatch.matchType.color)
                        .fontWeight(.semibold)
                }
                Divider()
                HStack {
                    Text("Players")
                        .fontWeight(.medium)
                    Spacer()
                }
                ForEach(proposal.potentialMatch.players, id: \.user.id) { entry in
                    PlayerRow(entry: entry, isCurrentUser: entry.user.id == appState.currentUser?.id)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
            
            VStack(spacing: 4) {
                Text("Accept within \(timeRemaining)s")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ProgressView(value: Double(timeRemaining), total: 30)
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
            }
            .onReceive(timer) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timer.upstream.connect().cancel()
                    decline()
                }
            }
            
            HStack(spacing: 20) {
                Button {
                    decline()
                } label: {
                    Text("Decline")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                
                Button {
                    accept()
                } label: {
                    Text("Accept")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        }
        .padding()
        .presentationDetents([.height(400)])
    }
    
    private func accept() {
        Task { @MainActor in
            await appState.respondToMatchProposal(.accepted)
        }
        dismiss()
    }
    
    private func decline() {
        Task { @MainActor in
            await appState.respondToMatchProposal(.declined)
        }
        dismiss()
    }
}

private struct PlayerRow: View {
    let entry: DinkDropZoneFinal.MMQueueEntry
    let isCurrentUser: Bool
    
    var body: some View {
        HStack {
            Text(entry.user.displayName.isEmpty ? entry.user.email : entry.user.displayName)
            Spacer()
            if isCurrentUser {
                Text("You")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
}

#Preview {
    let state = AppState()
    let u1 = User(email: "a@a.com", password: "", elo: 1000, xp: 0, totalMatches: 0, wins: 0, losses: 0, winStreak: 0)
    
    // Create entry with explicit constructor parameters
    let entry = DinkDropZoneFinal.MMQueueEntry(
        user: u1, 
        joinTime: Date(), 
        preferredMatchType: DinkDropZoneFinal.MatchType.singles, 
        eloRange: 900...1100
    )
    
    let proposal = DinkDropZoneFinal.MMMatchProposal(
        id: UUID(), 
        potentialMatch: DinkDropZoneFinal.MMPotentialMatch(
            players: [entry], 
            matchType: DinkDropZoneFinal.MatchType.singles, 
            compatibility: 1
        ), 
        proposedAt: Date(), 
        expiresAt: Date().addingTimeInterval(30), 
        responses: [:]
    )
    
    state.matchProposal = proposal
    state.currentUser = u1
    
    return MatchProposalView(proposal: proposal)
        .environmentObject(state)
} 