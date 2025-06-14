import Foundation
import SwiftData

@Model
final class Match {
    var id: String
    var player1: User
    var player2: User
    var player1Score: Int
    var player2Score: Int
    var winner: User?
    var eloChange: String
    var date: Date
    var duration: TimeInterval
    var location: String
    var notes: String?
    var status: MatchStatus
    var type: MatchType
    var createdAt: Date
    var updatedAt: Date
    

    
    init(
        id: String = UUID().uuidString,
        player1: User,
        player2: User,
        player1Score: Int = 0,
        player2Score: Int = 0,
        winner: User? = nil,
        eloChange: String = "0",
        date: Date = Date(),
        duration: TimeInterval = 0,
        location: String = "",
        notes: String? = nil,
        status: MatchStatus = .scheduled,
        type: MatchType = .casual,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.player1 = player1
        self.player2 = player2
        self.player1Score = player1Score
        self.player2Score = player2Score
        self.winner = winner
        self.eloChange = eloChange
        self.date = date
        self.duration = duration
        self.location = location
        self.notes = notes
        self.status = status
        self.type = type
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    

    
    // MARK: - Match Management
    
    func startMatch() {
        guard status == .scheduled else { return }
        status = .inProgress
        date = Date()
        updatedAt = Date()
    }
    
    func completeMatch(winner: User, player1Score: Int, player2Score: Int, duration: TimeInterval) {
        guard status == .inProgress else { return }
        
        self.winner = winner
        self.player1Score = player1Score
        self.player2Score = player2Score
        self.duration = duration
        self.status = .completed
        self.updatedAt = Date()
        
        // Update player stats
        player1.addMatch(self)
        player2.addMatch(self)
    }
    
    func cancelMatch() {
        guard status != .completed else { return }
        status = .cancelled
        updatedAt = Date()
    }
    
    // MARK: - Helper Methods
    
    func isWin(for player: User) -> Bool {
        guard let winner = winner else { return false }
        return winner.id == player.id
    }
    
    var isCompleted: Bool {
        status == .completed
    }
    
    var isInProgress: Bool {
        status == .inProgress
    }
    
    var isScheduled: Bool {
        status == .scheduled
    }
    
    var isCancelled: Bool {
        status == .cancelled
    }
    
    // MARK: - Computed Properties for UI
    
    func opponent(for currentUser: User) -> String {
        if player1.id == currentUser.id {
            return player2.displayName.isEmpty ? player2.email : player2.displayName
        } else {
            return player1.displayName.isEmpty ? player1.email : player1.displayName
        }
    }
    
    func result(for currentUser: User) -> String {
        guard let winner = winner else { return "Draw" }
        
        if winner.id == currentUser.id {
            return "Win"
        } else {
            return "Loss"
        }
    }
    
    var score: String {
        return "\(player1Score)-\(player2Score)"
    }
}

// MARK: - Supporting Types

enum MatchStatus: String, Codable {
    case scheduled = "Scheduled"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

// MARK: - Preview Helpers

extension Match {
    static var preview: Match {
        Match(
            player1: User.preview,
            player2: User.sampleUsers[0],
            player1Score: 11,
            player2Score: 9,
            winner: User.preview,
            eloChange: "+10",
            date: Date(),
            duration: 1800,
            location: "Community Courts",
            notes: "Great match!",
            status: .completed,
            type: .competitive
        )
    }
    
    static var sampleMatches: [Match] {
        [
            Match(
                player1: User.sampleUsers[0],
                player2: User.sampleUsers[1],
                player1Score: 11,
                player2Score: 8,
                winner: User.sampleUsers[0],
                eloChange: "+15",
                date: Date(),
                duration: 1500,
                location: "Sports Complex",
                status: .completed,
                type: .tournament
            ),
            Match(
                player1: User.sampleUsers[1],
                player2: User.sampleUsers[2],
                player1Score: 11,
                player2Score: 11,
                winner: User.sampleUsers[1],
                eloChange: "+5",
                date: Date(),
                duration: 2000,
                location: "City Park",
                status: .completed,
                type: .league
            ),
            Match(
                player1: User.preview,
                player2: User.sampleUsers[2],
                date: Date().addingTimeInterval(3600),
                location: "Community Center",
                status: .scheduled,
                type: .casual
            )
        ]
    }
} 
