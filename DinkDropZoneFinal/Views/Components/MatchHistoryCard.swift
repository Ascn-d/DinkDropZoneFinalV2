import SwiftUI
import SwiftData

struct MatchHistoryCard: View {
    let match: Match
    @Environment(AppState.self) private var appState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("vs \(opponentName)")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(match.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(match.score)
                        .font(.title3)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 4) {
                        Text(matchResult)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(resultColor.opacity(0.2))
                            }
                            .foregroundStyle(resultColor)
                        
                        Text(match.eloChange)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(eloChangeColor)
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
        }
    }
    
    private var opponentName: String {
        guard let currentUser = appState.currentUser else { return "Unknown" }
        return match.opponent(for: currentUser)
    }
    
    private var matchResult: String {
        guard let currentUser = appState.currentUser else { return "Draw" }
        return match.result(for: currentUser)
    }
    
    private var resultColor: Color {
        switch matchResult {
        case "Win":
            Color.green
        case "Loss":
            Color.red
        default:
            Color.orange
        }
    }
    
    private var eloChangeColor: Color {
        if match.eloChange.hasPrefix("+") {
            Color.green
        } else if match.eloChange.hasPrefix("-") {
            Color.red
        } else {
            Color.secondary
        }
    }
}

#Preview {
    PreviewHelper.matchHistoryCardPreview()
}

@MainActor
private struct PreviewHelper {
    static func matchHistoryCardPreview() -> some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: User.self, Match.self, configurations: config)
        
        // Create sample users
        let user1 = User(
            email: "player1@example.com",
            password: "password123",
            elo: 1000,
            xp: 0,
            totalMatches: 0,
            wins: 0,
            losses: 0,
            winStreak: 0
        )
        
        let user2 = User(
            email: "player2@example.com",
            password: "password123",
            elo: 1000,
            xp: 0,
            totalMatches: 0,
            wins: 0,
            losses: 0,
            winStreak: 0
        )
        
        container.mainContext.insert(user1)
        container.mainContext.insert(user2)
        
        // Create sample match
        let match = Match(
            player1: user1,
            player2: user2,
            player1Score: 11,
            player2Score: 9,
            winner: user1,
            eloChange: "+10"
        )
        
        return MatchHistoryCard(match: match)
            .padding()
            .modelContainer(container)
            .environment(AppState())
    }
} 