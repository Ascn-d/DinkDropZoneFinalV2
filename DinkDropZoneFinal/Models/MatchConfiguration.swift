import Foundation
import SwiftUI

// MARK: - Match Configuration Models

struct MatchConfiguration: Codable, Identifiable {
    var id: String { "\(player1.id)-\(player2.id)-\(matchType)-\(createdAt.timeIntervalSince1970)" }
    let matchFormat: MatchFormat
    let scoringSystem: ScoringSystem
    let player1: LocalMatchmakingService.NearbyPlayer
    let player2: LocalMatchmakingService.NearbyPlayer
    let matchType: String
    let createdAt: Date
    
    enum MatchFormat: String, CaseIterable, Codable {
        case bestOfOne = "Best of 1"
        case bestOfThree = "Best of 3" 
        case bestOfFive = "Best of 5"
        case firstToEleven = "First to 11"
        case firstToFifteen = "First to 15"
        case firstToTwentyOne = "First to 21"
        
        var maxGames: Int {
            switch self {
            case .bestOfOne: return 1
            case .bestOfThree: return 3
            case .bestOfFive: return 5
            case .firstToEleven, .firstToFifteen, .firstToTwentyOne: return 1
            }
        }
        
        var winCondition: Int {
            switch self {
            case .bestOfOne: return 1
            case .bestOfThree: return 2
            case .bestOfFive: return 3
            case .firstToEleven: return 11
            case .firstToFifteen: return 15
            case .firstToTwentyOne: return 21
            }
        }
        
        var icon: String {
            switch self {
            case .bestOfOne: return "1.circle.fill"
            case .bestOfThree: return "3.circle.fill"
            case .bestOfFive: return "5.circle.fill"
            case .firstToEleven: return "11.circle.fill"
            case .firstToFifteen: return "15.circle.fill"
            case .firstToTwentyOne: return "21.circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .bestOfOne: return "Single game to 11 points"
            case .bestOfThree: return "First to win 2 games"
            case .bestOfFive: return "First to win 3 games"
            case .firstToEleven: return "Race to 11 points"
            case .firstToFifteen: return "Race to 15 points"
            case .firstToTwentyOne: return "Race to 21 points"
            }
        }
        
        var color: Color {
            switch self {
            case .bestOfOne: return .blue
            case .bestOfThree: return .green
            case .bestOfFive: return .orange
            case .firstToEleven: return .purple
            case .firstToFifteen: return .red
            case .firstToTwentyOne: return .pink
            }
        }
    }
    
    enum ScoringSystem: String, CaseIterable, Codable {
        case traditional = "Traditional"
        case rally = "Rally Point"
        case tennis = "Tennis Style"
        
        var description: String {
            switch self {
            case .traditional: return "Win by 2, serve alternates every 2 points"
            case .rally: return "Point on every rally, serve alternates every point"
            case .tennis: return "Tennis-style scoring (15, 30, 40, Game)"
            }
        }
        
        var icon: String {
            switch self {
            case .traditional: return "sportscourt.fill"
            case .rally: return "bolt.fill"
            case .tennis: return "tennis.racket"
            }
        }
        
        var color: Color {
            switch self {
            case .traditional: return .blue
            case .rally: return .orange
            case .tennis: return .green
            }
        }
    }
}

// MARK: - Game State Models

struct GameState: Codable, Identifiable {
    var id: String { "game-\(gameNumber)-\(startTime.timeIntervalSince1970)" }
    var gameNumber: Int
    var player1Score: Int = 0
    var player2Score: Int = 0
    var isCompleted: Bool = false
    var winner: String? = nil
    var startTime: Date = Date()
    var endTime: Date?
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    mutating func complete(winner: String) {
        self.isCompleted = true
        self.winner = winner
        self.endTime = Date()
    }
}

struct MatchState: Codable, Identifiable {
    var id: String { "match-\(configuration.id)-\(startTime.timeIntervalSince1970)" }
    let configuration: MatchConfiguration
    var games: [GameState] = []
    var currentGameIndex: Int = 0
    var isCompleted: Bool = false
    var winner: String? = nil
    var startTime: Date = Date()
    var endTime: Date?
    
    var currentGame: GameState? {
        get {
            guard currentGameIndex < games.count else { return nil }
            return games[currentGameIndex]
        }
        set {
            if let newValue = newValue, currentGameIndex < games.count {
                games[currentGameIndex] = newValue
            }
        }
    }
    
    var player1GamesWon: Int {
        games.filter { $0.winner == configuration.player1.id }.count
    }
    
    var player2GamesWon: Int {
        games.filter { $0.winner == configuration.player2.id }.count
    }
    
    var totalDuration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    mutating func advanceToNextGame() {
        if currentGameIndex < games.count - 1 {
            currentGameIndex += 1
        }
    }
    
    mutating func completeMatch() {
        isCompleted = true
        endTime = Date()
        
        // Determine overall winner based on format
        switch configuration.matchFormat {
        case .bestOfOne, .bestOfThree, .bestOfFive:
            winner = player1GamesWon > player2GamesWon ? configuration.player1.id : configuration.player2.id
        case .firstToEleven, .firstToFifteen, .firstToTwentyOne:
            // For "first to X" formats, winner is determined by the single game
            winner = games.first?.winner
        }
    }
    
    mutating func initializeGames() {
        games = []
        for i in 0..<configuration.matchFormat.maxGames {
            games.append(GameState(gameNumber: i + 1))
        }
    }
} 