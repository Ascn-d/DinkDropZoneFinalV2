import SwiftUI

struct LiveActivityCard: View {
    let activity: LiveActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity type indicator
            ZStack {
                Circle()
                    .fill(activity.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: activity.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(activity.type.color)
            }
            
            // Activity content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if activity.isLive {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                                .scaleEffect(activity.pulseAnimation ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1).repeatForever(), value: activity.pulseAnimation)
                            
                            Text("LIVE")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                    } else {
                        Text(activity.timestamp, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let metadata = activity.metadata {
                    HStack(spacing: 8) {
                        ForEach(metadata.keys.sorted(), id: \.self) { key in
                            if let value = metadata[key] {
                                Text("\(key): \(value)")
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct LiveActivityMatchCard: View {
    let match: LiveMatchData
    
    var body: some View {
        VStack(spacing: 12) {
            // Match header
            HStack {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(match.isLive ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(), value: match.isLive)
                    
                    Text("LIVE MATCH")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Text(match.court)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Players and score
            HStack {
                // Player 1
                VStack(alignment: .leading, spacing: 4) {
                    Text(match.player1)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(match.player1ELO) ELO")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Score
                HStack(spacing: 8) {
                    Text("\(match.player1Score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(match.player1Score > match.player2Score ? .green : .primary)
                    
                    Text("-")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("\(match.player2Score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(match.player2Score > match.player1Score ? .green : .primary)
                }
                
                Spacer()
                
                // Player 2
                VStack(alignment: .trailing, spacing: 4) {
                    Text(match.player2)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("\(match.player2ELO) ELO")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Match info
            HStack {
                Text("⏱️ \(match.duration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Set \(match.currentSet)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.green.opacity(0.1),
                    Color.blue.opacity(0.1)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PlayerActivityCard: View {
    let activity: PlayerActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // Player avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(activity.playerName.prefix(1)))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.playerName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(activity.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(activity.action)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let achievement = activity.achievement {
                    HStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        
                        Text(achievement)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct TournamentUpdateCard: View {
    let tournament: TournamentUpdate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tournament.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(tournament.status.rawValue)
                        .font(.caption)
                        .foregroundColor(tournament.status.color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(tournament.status.color.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text(tournament.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(tournament.update)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(tournament.participants)/\(tournament.maxParticipants) players")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if tournament.canJoin {
                    Button("Join") {
                        // Handle join tournament
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Data Models

struct LiveActivity: Identifiable {
    let id = UUID()
    let type: ActivityType
    let title: String
    let description: String
    let timestamp: Date
    let isLive: Bool
    let metadata: [String: String]?
    let pulseAnimation: Bool
    
    enum ActivityType {
        case match, tournament, achievement, social
        
        var icon: String {
            switch self {
            case .match: return "gamecontroller.fill"
            case .tournament: return "trophy.fill"
            case .achievement: return "star.fill"
            case .social: return "person.2.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .match: return .green
            case .tournament: return .orange
            case .achievement: return .yellow
            case .social: return .blue
            }
        }
    }
    
    init(
        type: ActivityType,
        title: String,
        description: String,
        timestamp: Date = Date(),
        isLive: Bool = false,
        metadata: [String: String]? = nil,
        pulseAnimation: Bool = false
    ) {
        self.type = type
        self.title = title
        self.description = description
        self.timestamp = timestamp
        self.isLive = isLive
        self.metadata = metadata
        self.pulseAnimation = pulseAnimation
    }
}

struct LiveMatchData {
    let id = UUID()
    let player1: String
    let player2: String
    let player1ELO: Int
    let player2ELO: Int
    let player1Score: Int
    let player2Score: Int
    let court: String
    let duration: String
    let currentSet: Int
    let isLive: Bool
}

struct PlayerActivity {
    let id = UUID()
    let playerName: String
    let action: String
    let timestamp: Date
    let achievement: String?
}

struct TournamentUpdate {
    let id = UUID()
    let name: String
    let status: TournamentStatus
    let update: String
    let participants: Int
    let maxParticipants: Int
    let timestamp: Date
    let canJoin: Bool
    
    enum TournamentStatus: String {
        case registering = "Registering"
        case starting = "Starting Soon"
        case inProgress = "In Progress"
        case completed = "Completed"
        
        var color: Color {
            switch self {
            case .registering: return .blue
            case .starting: return .orange
            case .inProgress: return .green
            case .completed: return .gray
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            LiveActivityCard(
                activity: LiveActivity(
                    type: .match,
                    title: "Sarah vs Mike",
                    description: "Intense match at Golden Gate Park",
                    isLive: true,
                    metadata: ["Court": "1", "Set": "2"],
                    pulseAnimation: true
                )
            )
            
            LiveActivityMatchCard(
                match: LiveMatchData(
                    player1: "Sarah Chen",
                    player2: "Mike Johnson",
                    player1ELO: 1650,
                    player2ELO: 1580,
                    player1Score: 8,
                    player2Score: 6,
                    court: "Court 1",
                    duration: "12:34",
                    currentSet: 1,
                    isLive: true
                )
            )
            
            PlayerActivityCard(
                activity: PlayerActivity(
                    playerName: "Emma Wilson",
                    action: "Won a match against Alex Turner",
                    timestamp: Date().addingTimeInterval(-300),
                    achievement: "5-game win streak!"
                )
            )
            
            TournamentUpdateCard(
                tournament: TournamentUpdate(
                    name: "Friday Night Championship",
                    status: .registering,
                    update: "Registration closes in 2 hours",
                    participants: 12,
                    maxParticipants: 16,
                    timestamp: Date().addingTimeInterval(-600),
                    canJoin: true
                )
            )
        }
        .padding()
    }
} 