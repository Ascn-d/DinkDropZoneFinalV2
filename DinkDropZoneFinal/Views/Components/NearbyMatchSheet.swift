import SwiftUI
import MultipeerConnectivity

struct NearbyMatchSheet: View {
    @Environment(NearbyMatchService.self) private var nearby
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if nearby.discoveredPeers.isEmpty {
                    HStack {
                        ProgressView()
                        Text("Searching for players…")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ForEach(nearby.discoveredPeers) { peer in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(peer.displayName)
                                    .font(.headline)
                                if let elo = peer.elo {
                                    Text("\(elo) ELO")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if nearby.pendingInviteFrom?.id == peer.id {
                                Button("Accept") {
                                    nearby.acceptInvite(from: peer)
                                    dismiss()
                                }
                                .buttonStyle(.borderedProminent)
                            } else {
                                Button("Invite") { nearby.sendInvite(to: peer) }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nearby Players")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}

#Preview {
    NearbyMatchSheet()
        .environment(NearbyMatchService(displayName: "Preview"))
} 