import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class TournamentService {
    
    private var modelContext: ModelContext
    
    // Tournament state
    var activeTournaments: [Tournament] = []
    var upcomingTournaments: [Tournament] = []
    var completedTournaments: [Tournament] = []
    var userTournaments: [Tournament] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadTournaments()
        generateSampleTournaments()
    }
    
    // MARK: - Tournament Management
    
    func createTournament(
        name: String,
        description: String,
        location: String,
        startDate: Date,
        endDate: Date,
        maxParticipants: Int,
        entryFee: Double,
        format: TournamentFormat,
        skillLevel: String
    ) -> Tournament {
        let tournament = Tournament(
            name: name,
            description: description,
            location: location,
            startDate: startDate,
            endDate: endDate,
            maxParticipants: maxParticipants,
            entryFee: entryFee,
            format: format,
            skillLevel: skillLevel
        )
        
        modelContext.insert(tournament)
        return tournament
    }
    
    func joinTournament(_ tournament: Tournament, player: User) throws {
        guard tournament.status == .open else {
            throw TournamentError.tournamentNotOpen
        }
        
        guard tournament.participants.count < tournament.maxParticipants else {
            throw TournamentError.tournamentFull
        }
        
        guard !tournament.participants.contains(where: { $0.id == player.id }) else {
            throw TournamentError.alreadyJoined
        }
        
        tournament.participants.append(player)
        
        if tournament.participants.count == tournament.maxParticipants {
            tournament.status = .inProgress
            generateBracket(for: tournament)
        }
    }
    
    func leaveTournament(_ tournament: Tournament, player: User) {
        tournament.participants.removeAll { $0.id == player.id }
    }
    
    // MARK: - Match Management
    
    func recordMatchResult(
        tournament: Tournament,
        match: TournamentMatch,
        winner: User,
        score: String
    ) throws {
        guard tournament.status == .inProgress else {
            throw TournamentError.tournamentNotInProgress
        }
        
        guard match.status == .scheduled else {
            throw TournamentError.matchAlreadyCompleted
        }
        
        match.winner = winner
        match.score = score
        match.status = .completed
        match.completedAt = Date()
        
        // Update tournament progress
        if let nextMatch = findNextMatch(for: match, in: tournament) {
            nextMatch.status = .scheduled
            if match.round == 1 {
                nextMatch.player1 = winner
            } else {
                nextMatch.player2 = winner
            }
        } else {
            // Tournament is complete
            tournament.status = .completed
            tournament.winner = winner
        }
    }
    
    // MARK: - Bracket Management
    
    private func generateBracket(for tournament: Tournament) {
        let participants = tournament.participants.shuffled()
        let rounds = calculateRounds(participantCount: participants.count)
        
        // Create first round matches
        for i in stride(from: 0, to: participants.count - 1, by: 2) {
            let match = TournamentMatch(
                tournament: tournament,
                round: 1,
                player1: participants[i],
                player2: i + 1 < participants.count ? participants[i + 1] : nil
            )
            tournament.matches.append(match)
        }
        
        // Create subsequent round matches
        for round in 2...rounds {
            let matchesInRound = tournament.matches.filter { $0.round == round - 1 }.count / 2
            for _ in 0..<matchesInRound {
                let match = TournamentMatch(
                    tournament: tournament,
                    round: round,
                    player1: nil,
                    player2: nil
                )
                tournament.matches.append(match)
            }
        }
    }
    
    private func calculateRounds(participantCount: Int) -> Int {
        var count = participantCount
        var rounds = 0
        while count > 1 {
            count = (count + 1) / 2
            rounds += 1
        }
        return rounds
    }
    
    private func findNextMatch(for match: TournamentMatch, in tournament: Tournament) -> TournamentMatch? {
        let nextRound = match.round + 1
        let matchIndex = tournament.matches.firstIndex { $0.id == match.id } ?? 0
        let nextMatchIndex = matchIndex / 2
        
        return tournament.matches.first { $0.round == nextRound && $0.id == tournament.matches[nextMatchIndex].id }
    }
    
    // MARK: - Prize System
    
    private func awardPrizes(for tournament: Tournament) {
        guard let winner = tournament.winner else { return }
        
        let prizes = calculatePrizes(for: tournament)
        winner.addXP(prizes.xp)
        winner.addCoins(prizes.coins)
        
        LoggingService.shared.log("Awarded prizes to \(winner.displayName): \(prizes.xp) XP, \(prizes.coins) coins")
    }
    
    private func calculatePrizes(for tournament: Tournament) -> (xp: Int, coins: Int) {
        let baseXP = 100
        let baseCoins = tournament.prizePool
        
        let multiplier = tournament.format == .singleElimination ? 2.0 : 1.0
        
        return (
            xp: Int(Double(baseXP) * multiplier),
            coins: Int(Double(baseCoins) * multiplier)
        )
    }
    
    // MARK: - Helper Methods
    
    private func calculateMatchTime(tournament: Tournament, round: Int, matchIndex: Int) -> Date {
        let baseTime = tournament.actualStartDate ?? tournament.startDate
        let roundInterval: TimeInterval = 3600 // 1 hour between rounds
        let matchInterval: TimeInterval = 900 // 15 minutes between matches
        
        return baseTime.addingTimeInterval(
            TimeInterval(round - 1) * roundInterval +
            TimeInterval(matchIndex) * matchInterval
        )
    }
    
    // MARK: - Data Loading
    
    private func loadTournaments() {
        let descriptor = FetchDescriptor<Tournament>()
        if let tournaments = try? modelContext.fetch(descriptor) {
            for tournament in tournaments {
                switch tournament.status {
                case .open, .registering:
                    upcomingTournaments.append(tournament)
                case .inProgress:
                    activeTournaments.append(tournament)
                case .completed:
                    completedTournaments.append(tournament)
                case .cancelled:
                    completedTournaments.append(tournament)
                }
            }
        }
    }
    
    private func generateSampleTournaments() {
        // Only generate sample data if no tournaments exist
        guard activeTournaments.isEmpty && upcomingTournaments.isEmpty else { return }
        
        _ = createTournament(
            name: "Summer Championship",
            description: "Join us for the biggest pickleball tournament of the summer!",
            location: "City Sports Complex",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            maxParticipants: 32,
            entryFee: 50.0,
            format: .singleElimination,
            skillLevel: "Intermediate"
        )
        
        _ = createTournament(
            name: "Weekly Tournament",
            description: "Stay active this winter with indoor pickleball!",
            location: "Sports Center",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            maxParticipants: 16,
            entryFee: 35.0,
            format: .doubleElimination,
            skillLevel: "Advanced"
        )
        
        LoggingService.shared.log("Generated sample tournaments")
    }
}

// MARK: - Tournament Models

@Model
final class Tournament {
    var id: String
    var name: String
    var tournamentDescription: String
    var location: String
    var startDate: Date
    var endDate: Date
    var maxParticipants: Int
    var entryFee: Double
    var format: TournamentFormat
    var skillLevel: String
    var status: TournamentStatus
    var participants: [User]
    var matches: [TournamentMatch]
    var winner: User?
    var actualStartDate: Date?
    var createdAt: Date
    var updatedAt: Date
    

    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        location: String,
        startDate: Date,
        endDate: Date,
        maxParticipants: Int,
        entryFee: Double,
        format: TournamentFormat,
        skillLevel: String,
        status: TournamentStatus = .open,
        participants: [User] = [],
        matches: [TournamentMatch] = [],
        winner: User? = nil,
        actualStartDate: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.tournamentDescription = description
        self.location = location
        self.startDate = startDate
        self.endDate = endDate
        self.maxParticipants = maxParticipants
        self.entryFee = entryFee
        self.format = format
        self.skillLevel = skillLevel
        self.status = status
        self.participants = participants
        self.matches = matches
        self.winner = winner
        self.actualStartDate = actualStartDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    

    
    var minParticipants: Int {
        switch format {
        case .weekly: return 4
        case .singleElimination: return 8
        case .doubleElimination: return 2
        case .roundRobin: return 4
        }
    }
    
    var isReadyToStart: Bool {
        participants.count >= minParticipants && status == .open
    }
    
    var prizePool: Int {
        switch format {
        case .weekly: return 400
        case .singleElimination: return 1000
        case .doubleElimination: return 1000
        case .roundRobin: return 0
        }
    }
    
    func addParticipant(_ user: User) {
        guard canJoin(user: user) else { return }
        participants.append(user)
    }
    
    func removeParticipant(_ user: User) {
        participants.removeAll { $0.id == user.id }
    }
    
    func canJoin(user: User) -> Bool {
        guard status == .open || status == .registering else { return false }
        guard !participants.contains(where: { $0.id == user.id }) else { return false }
        return participants.count < maxParticipants
    }
}

@Model
final class TournamentMatch {
    var id: String
    var tournament: Tournament
    var round: Int
    var player1: User?
    var player2: User?
    var winner: User?
    var score: String?
    var status: TournamentMatchStatus
    var scheduledDate: Date?
    var completedAt: Date?
    

    
    init(
        id: String = UUID().uuidString,
        tournament: Tournament,
        round: Int,
        player1: User? = nil,
        player2: User? = nil,
        winner: User? = nil,
        score: String? = nil,
        status: TournamentMatchStatus = .scheduled,
        scheduledDate: Date? = nil,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.tournament = tournament
        self.round = round
        self.player1 = player1
        self.player2 = player2
        self.winner = winner
        self.score = score
        self.status = status
        self.scheduledDate = scheduledDate
        self.completedAt = completedAt
    }
    

    
    var isReady: Bool {
        player1 != nil && player2 != nil && status == .scheduled
    }
}

enum TournamentFormat: String, Codable {
    case weekly
    case singleElimination
    case doubleElimination
    case roundRobin
}

enum TournamentStatus: String, Codable {
    case open
    case registering
    case inProgress
    case completed
    case cancelled
}

enum TournamentMatchStatus: String, Codable {
    case scheduled
    case inProgress
    case completed
    case cancelled
}

enum TournamentError: Error {
    case tournamentNotOpen
    case tournamentNotInProgress
    case tournamentFull
    case alreadyJoined
    case matchAlreadyCompleted
}

// MARK: - Notifications

extension Notification.Name {
    static let tournamentStarted = Notification.Name("tournamentStarted")
    static let tournamentCompleted = Notification.Name("tournamentCompleted")
}

// MARK: - Preview Helpers

extension Tournament {
    static var preview: Tournament {
        Tournament(
            name: "Summer Championship 2024",
            description: "Join us for the biggest pickleball tournament of the summer!",
            location: "City Sports Complex",
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            maxParticipants: 32,
            entryFee: 50.0,
            format: .singleElimination,
            skillLevel: "Intermediate"
        )
    }
    
    static var sampleTournaments: [Tournament] {
        [
            Tournament(
                name: "Winter Classic 2024",
                description: "Stay active this winter with indoor pickleball!",
                location: "Sports Center",
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
                maxParticipants: 16,
                entryFee: 35.0,
                format: .doubleElimination,
                skillLevel: "Advanced"
            ),
            Tournament(
                name: "Spring Open 2024",
                description: "Perfect for players of all levels!",
                location: "Community Courts",
                startDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
                endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
                maxParticipants: 64,
                entryFee: 75.0,
                format: .roundRobin,
                skillLevel: "All Levels"
            )
        ]
    }
} 
