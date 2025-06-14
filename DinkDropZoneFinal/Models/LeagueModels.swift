import Foundation
import SwiftData

@Model
final class PickleLeague {
    var id: String
    var name: String
    var leagueDescription: String
    var location: String
    var imageUrl: String?
    var rating: Double
    var format: LeagueFormat
    var status: LeagueStatus
    var startDate: Date
    var endDate: Date
    var maxPlayers: Int
    var currentPlayers: Int
    var players: [User]
    var matches: [LeagueMatch]
    var standings: [Standing]
    var rules: [String]
    var prizePool: Int
    var entryFee: Int
    var schedule: String?
    var nextGame: String?
    var tags: [String]
    var skillLevel: String?
    var createdAt: Date
    var updatedAt: Date
    

    
    init(
        id: String = UUID().uuidString,
        name: String,
        leagueDescription: String,
        location: String,
        imageUrl: String? = nil,
        rating: Double = 0.0,
        format: LeagueFormat = .roundRobin,
        status: LeagueStatus = .open,
        startDate: Date,
        endDate: Date,
        maxPlayers: Int = 16,
        currentPlayers: Int = 0,
        players: [User] = [],
        matches: [LeagueMatch] = [],
        standings: [Standing] = [],
        rules: [String] = [],
        prizePool: Int = 0,
        entryFee: Int = 0,
        schedule: String? = nil,
        nextGame: String? = nil,
        tags: [String] = [],
        skillLevel: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.leagueDescription = leagueDescription
        self.location = location
        self.imageUrl = imageUrl
        self.rating = rating
        self.format = format
        self.status = status
        self.startDate = startDate
        self.endDate = endDate
        self.maxPlayers = maxPlayers
        self.currentPlayers = currentPlayers
        self.players = players
        self.matches = matches
        self.standings = standings
        self.rules = rules
        self.prizePool = prizePool
        self.entryFee = entryFee
        self.schedule = schedule
        self.nextGame = nextGame
        self.tags = tags
        self.skillLevel = skillLevel
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    

    
    // MARK: - League Management
    
    func addPlayer(_ player: User) {
        guard currentPlayers < maxPlayers else { return }
        guard !players.contains(where: { $0.id == player.id }) else { return }
        
        players.append(player)
        currentPlayers += 1
        updatedAt = Date()
    }
    
    func removePlayer(_ player: User) {
        players.removeAll { $0.id == player.id }
        currentPlayers -= 1
        updatedAt = Date()
    }
    
    func addMatch(_ match: LeagueMatch) {
        matches.append(match)
        updatedAt = Date()
    }
    
    func updateStandings() {
        standings = calculateStandings()
        updatedAt = Date()
    }
    
    private func calculateStandings() -> [Standing] {
        var playerStats: [String: (wins: Int, losses: Int, pointsFor: Int, pointsAgainst: Int)] = [:]
        
        // Calculate stats for each player
        for leagueMatch in matches where leagueMatch.status == .completed {
            let match = leagueMatch.match
            let player1 = match.player1
            let player2 = match.player2
            let p1Score = match.player1Score
            let p2Score = match.player2Score
            
            if p1Score > p2Score {
                // Player 1 wins
                playerStats[player1.id.uuidString, default: (0, 0, 0, 0)].wins += 1
                playerStats[player1.id.uuidString, default: (0, 0, 0, 0)].pointsFor += p1Score
                playerStats[player1.id.uuidString, default: (0, 0, 0, 0)].pointsAgainst += p2Score
                
                playerStats[player2.id.uuidString, default: (0, 0, 0, 0)].losses += 1
                playerStats[player2.id.uuidString, default: (0, 0, 0, 0)].pointsFor += p2Score
                playerStats[player2.id.uuidString, default: (0, 0, 0, 0)].pointsAgainst += p1Score
            } else if p2Score > p1Score {
                // Player 2 wins
                playerStats[player2.id.uuidString, default: (0, 0, 0, 0)].wins += 1
                playerStats[player2.id.uuidString, default: (0, 0, 0, 0)].pointsFor += p2Score
                playerStats[player2.id.uuidString, default: (0, 0, 0, 0)].pointsAgainst += p1Score
                
                playerStats[player1.id.uuidString, default: (0, 0, 0, 0)].losses += 1
                playerStats[player1.id.uuidString, default: (0, 0, 0, 0)].pointsFor += p1Score
                playerStats[player1.id.uuidString, default: (0, 0, 0, 0)].pointsAgainst += p2Score
            }
            // Draw case - no wins/losses recorded
        }
        
        // Convert to standings
        return playerStats.map { playerId, stats in
            Standing(
                playerId: playerId,
                wins: stats.wins,
                losses: stats.losses,
                pointsFor: stats.pointsFor,
                pointsAgainst: stats.pointsAgainst
            )
        }.sorted { $0.winPercentage > $1.winPercentage }
    }
}

// MARK: - Supporting Types

enum LeagueFormat: String, Codable, CaseIterable {
    case roundRobin = "Round Robin"
    case singleElimination = "Single Elimination"
    case doubleElimination = "Double Elimination"
    case swiss = "Swiss"
}

enum LeagueStatus: String, Codable {
    case open = "Open"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

struct Standing: Codable {
    var playerId: String
    var wins: Int
    var losses: Int
    var pointsFor: Int
    var pointsAgainst: Int
    
    var winPercentage: Double {
        let total = wins + losses
        guard total > 0 else { return 0 }
        return Double(wins) / Double(total)
    }
    
    var pointDifferential: Int {
        pointsFor - pointsAgainst
    }
}

// MARK: - Preview Helpers

extension PickleLeague {
    static var preview: PickleLeague {
        PickleLeague(
            name: "Summer League 2024",
            leagueDescription: "Join us for a summer of pickleball fun!",
            location: "Community Center Courts",
            imageUrl: nil,
            rating: 4.5,
            format: .roundRobin,
            status: .open,
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .month, value: 3, to: Date())!,
            maxPlayers: 16,
            currentPlayers: 8,
            rules: [
                "Best of 3 games to 11",
                "Win by 2 points",
                "Round robin format",
                "Top 4 advance to playoffs"
            ],
            prizePool: 1000,
            entryFee: 50
        )
    }
    
    static var sampleLeagues: [PickleLeague] {
        [
            PickleLeague(
                name: "Winter League 2024",
                leagueDescription: "Stay active this winter with indoor pickleball!",
                location: "Sports Complex",
                imageUrl: nil,
                rating: 4.2,
                format: .singleElimination,
                status: .inProgress,
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .month, value: 2, to: Date())!,
                maxPlayers: 32,
                currentPlayers: 24,
                rules: [
                    "Single elimination tournament",
                    "Best of 3 games to 11",
                    "Win by 2 points"
                ],
                prizePool: 2000,
                entryFee: 75
            ),
            PickleLeague(
                name: "Spring Doubles League",
                leagueDescription: "Perfect for doubles teams!",
                location: "City Park Courts",
                imageUrl: nil,
                rating: 4.0,
                format: .roundRobin,
                status: .open,
                startDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
                endDate: Calendar.current.date(byAdding: .month, value: 4, to: Date())!,
                maxPlayers: 16,
                currentPlayers: 6,
                rules: [
                    "Doubles teams only",
                    "Round robin format",
                    "Best of 3 games to 11",
                    "Win by 2 points"
                ],
                prizePool: 1500,
                entryFee: 100
            )
        ]
    }
} 