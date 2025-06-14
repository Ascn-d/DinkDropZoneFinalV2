import SwiftUI
import SwiftData

struct LeagueCard: View {
    let league: PickleLeague
    let onViewDetails: () -> Void
    @Environment(AppState.self) private var appState
    
    private var isJoined: Bool {
        league.players.contains { $0.id == appState.currentUser?.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // League Image
            ZStack(alignment: .topTrailing) {
                if let imageUrl = league.imageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 160)
                            .clipped()
                    } placeholder: {
                        Color.gray.opacity(0.2)
                            .frame(height: 160)
                    }
                } else {
                    Color.gray.opacity(0.2)
                        .frame(height: 160)
                }
                
                // Distance Badge
                Text(league.location)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Title and Rating
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(league.name)
                            .font(.headline)
                        Text(league.leagueDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(String(format: "%.1f", league.rating))
                            .font(.subheadline)
                    }
                }
                
                // Description
                Text(league.leagueDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // Stats
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2.fill")
                            .foregroundStyle(.secondary)
                        Text("\(league.players.count)/\(league.maxPlayers)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(league.format.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                
                // Schedule
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                    Text(league.schedule ?? "Schedule TBD")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Next Game
                HStack {
                    Text("$\(league.entryFee)")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                    
                    Spacer()
                    
                    Text("Next: \(league.nextGame ?? "TBD")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Tags
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(league.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                    }
                }
                
                // Action Buttons
                HStack(spacing: 8) {
                    Button(action: onViewDetails) {
                        Text("View Details")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { /* TODO: Implement join action */ }) {
                        Text(isJoined ? "Joined" : "Join League")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isJoined ? .gray : .green)
                }
            }
            .padding()
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 2)
    }
}

#Preview {
    LeagueCard(
        league: .preview,
        onViewDetails: {}
    )
    .padding()
    .modelContainer(for: [PickleLeague.self, User.self])
} 