import Foundation
import SwiftData

// MARK: - Simple Tournament Models (avoiding @Model macro issues)

// Basic tournament structure without SwiftData for now
struct Tournament: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var description: String
    var type: String
    var format: String
    var skillLevel: String
    var maxParticipants: Int
    var startDate: Date
    var endDate: Date
    var status: String
    var organizerID: String
    var organizerName: String
    var venueName: String
    var venueAddress: String
    var participants: [TournamentParticipant]
    var matches: [TournamentMatch]
    
    init(
        name: String,
        description: String = "",
        type: String = "Double Elimination",
        format: String = "Doubles",
        skillLevel: String = "Intermediate",
        maxParticipants: Int = 32,
        startDate: Date = Date(),
        organizerID: String,
        organizerName: String,
        venueName: String = "",
        venueAddress: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.type = type
        self.format = format
        self.skillLevel = skillLevel
        self.maxParticipants = maxParticipants
        self.startDate = startDate
        self.endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        
        // Set initial status based on start date
        let now = Date()
        if startDate > now.addingTimeInterval(86400) { // More than 24 hours away
            self.status = "Registration Open"
        } else if startDate > now.addingTimeInterval(3600) { // More than 1 hour away
            self.status = "Registration Closed"
        } else if startDate > now.addingTimeInterval(-3600) { // Started less than 1 hour ago
            self.status = "In Progress"
        } else {
            self.status = "Upcoming"
        }
        self.organizerID = organizerID
        self.organizerName = organizerName
        self.venueName = venueName
        self.venueAddress = venueAddress
        self.participants = []
        self.matches = []
    }
    
    // Full initializer for Firebase decoding
    init(
        id: UUID,
        name: String,
        description: String,
        type: String,
        format: String,
        skillLevel: String,
        maxParticipants: Int,
        startDate: Date,
        endDate: Date,
        status: String,
        organizerID: String,
        organizerName: String,
        venueName: String,
        venueAddress: String,
        participants: [TournamentParticipant],
        matches: [TournamentMatch]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.format = format
        self.skillLevel = skillLevel
        self.maxParticipants = maxParticipants
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.organizerID = organizerID
        self.organizerName = organizerName
        self.venueName = venueName
        self.venueAddress = venueAddress
        self.participants = participants
        self.matches = matches
    }
    
    var registeredCount: Int {
        participants.filter { $0.status == "Registered" }.count
    }
    
    var isRegistrationOpen: Bool {
        status == "Registration Open" && registeredCount < maxParticipants
    }
    
    var canStart: Bool {
        status == "Registration Closed" && registeredCount >= 4
    }
}

struct TournamentParticipant: Identifiable, Codable, Equatable {
    let id: UUID
    var userID: String
    var displayName: String
    var elo: Int
    var status: String
    var placement: Int?
    var isEliminated: Bool
    var wins: Int
    var losses: Int
    var partnerID: String?
    var partnerName: String?
    var teamName: String?
    
    init(
        userID: String,
        displayName: String,
        elo: Int = 1000,
        partnerID: String? = nil,
        partnerName: String? = nil,
        teamName: String? = nil
    ) {
        self.id = UUID()
        self.userID = userID
        self.displayName = displayName
        self.elo = elo
        self.status = "Registered"
        self.placement = nil
        self.isEliminated = false
        self.wins = 0
        self.losses = 0
        self.partnerID = partnerID
        self.partnerName = partnerName
        self.teamName = teamName
    }
    
    // Full initializer for Firebase decoding
    init(
        id: UUID,
        userID: String,
        displayName: String,
        elo: Int,
        status: String,
        placement: Int?,
        isEliminated: Bool,
        wins: Int,
        losses: Int,
        partnerID: String?,
        partnerName: String?,
        teamName: String?
    ) {
        self.id = id
        self.userID = userID
        self.displayName = displayName
        self.elo = elo
        self.status = status
        self.placement = placement
        self.isEliminated = isEliminated
        self.wins = wins
        self.losses = losses
        self.partnerID = partnerID
        self.partnerName = partnerName
        self.teamName = teamName
    }
    
    var effectiveName: String {
        if let teamName = teamName, !teamName.isEmpty {
            return teamName
        }
        if let partnerName = partnerName {
            return "\(displayName) / \(partnerName)"
        }
        return displayName
    }
}

struct TournamentMatch: Identifiable, Codable, Equatable {
    let id: UUID
    var round: Int
    var bracket: String
    var matchNumber: Int
    var player1ID: String
    var player2ID: String
    var player1Name: String
    var player2Name: String
    var winnerID: String?
    var loserID: String?
    var status: String
    var finalScore: String
    var isBye: Bool
    var isGrandFinalReset: Bool
    var scheduledTime: Date?
    var court: Int?
    var notes: String
    
    init(
        round: Int,
        bracket: String,
        matchNumber: Int,
        player1ID: String = "",
        player1Name: String = "",
        player2ID: String = "",
        player2Name: String = ""
    ) {
        self.id = UUID()
        self.round = round
        self.bracket = bracket
        self.matchNumber = matchNumber
        self.player1ID = player1ID
        self.player2ID = player2ID
        self.player1Name = player1Name
        self.player2Name = player2Name
        self.winnerID = nil
        self.loserID = nil
        self.status = "Upcoming"
        self.finalScore = ""
        self.isBye = false
        self.isGrandFinalReset = false
        self.scheduledTime = nil
        self.court = nil
        self.notes = ""
    }
    
    // Full initializer for Firebase decoding
    init(
        id: UUID,
        round: Int,
        bracket: String,
        matchNumber: Int,
        player1ID: String,
        player2ID: String,
        player1Name: String,
        player2Name: String,
        winnerID: String?,
        loserID: String?,
        status: String,
        finalScore: String,
        isBye: Bool,
        isGrandFinalReset: Bool,
        scheduledTime: Date?,
        court: Int?,
        notes: String
    ) {
        self.id = id
        self.round = round
        self.bracket = bracket
        self.matchNumber = matchNumber
        self.player1ID = player1ID
        self.player2ID = player2ID
        self.player1Name = player1Name
        self.player2Name = player2Name
        self.winnerID = winnerID
        self.loserID = loserID
        self.status = status
        self.finalScore = finalScore
        self.isBye = isBye
        self.isGrandFinalReset = isGrandFinalReset
        self.scheduledTime = scheduledTime
        self.court = court
        self.notes = notes
    }
    
    var hasResult: Bool {
        !finalScore.isEmpty && winnerID != nil
    }
    
    var displayName: String {
        let bracketName = bracket == "Winners" ? "W" : "L"
        return "\(bracketName)\(round)-\(matchNumber)"
    }
    
    var shortDescription: String {
        if isBye {
            return "\(player1Name.isEmpty ? "TBD" : player1Name) (Bye)"
        }
        return "\(player1Name.isEmpty ? "TBD" : player1Name) vs \(player2Name.isEmpty ? "TBD" : player2Name)"
    }
}

// MARK: - Tournament Enums

enum TournamentType: String, CaseIterable, Codable {
    case singleElimination = "Single Elimination"
    case doubleElimination = "Double Elimination"
    case roundRobin = "Round Robin"
    case swiss = "Swiss System"
}

enum TournamentFormat: String, CaseIterable, Codable {
    case singles = "Singles"
    case doubles = "Doubles"
    case mixedDoubles = "Mixed Doubles"
}

enum TournamentStatus: String, CaseIterable, Codable {
    case upcoming = "Upcoming"
    case registrationOpen = "Registration Open"
    case registrationClosed = "Registration Closed"
    case inProgress = "In Progress"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

enum ParticipantStatus: String, CaseIterable, Codable {
    case registered = "Registered"
    case checkedIn = "Checked In"
    case active = "Active"
    case eliminated = "Eliminated"
    case withdrawn = "Withdrawn"
}

enum TournamentMatchStatus: String, CaseIterable, Codable {
    case upcoming = "Upcoming"
    case ready = "Ready"
    case inProgress = "In Progress"
    case completed = "Completed"
    case defaulted = "Defaulted"
    case cancelled = "Cancelled"
}

enum BracketType: String, CaseIterable, Codable {
    case winners = "Winners"
    case losers = "Losers"
}

enum AgeGroup: String, CaseIterable, Codable {
    case under30 = "Under 30"
    case thirties = "30-39"
    case forties = "40-49"
    case fifties = "50-59"
    case sixties = "60-69"
    case seventies = "70+"
    case open = "Open"
}

enum Gender: String, CaseIterable, Codable {
    case mens = "Men's"
    case womens = "Women's"
    case mixed = "Mixed"
    case open = "Open"
}

// MARK: - Tournament Analytics Models

/// Tournament statistics for analytics and reporting
struct TournamentStatistics: Codable {
    var totalTournaments: Int = 0
    var openTournaments: Int = 0
    var activeTournaments: Int = 0
    var completedTournaments: Int = 0
    var fullTournaments: Int = 0
    var totalParticipants: Int = 0
    
    var averageParticipantsPerTournament: Double {
        totalTournaments > 0 ? Double(totalParticipants) / Double(totalTournaments) : 0.0
    }
    
    var completionRate: Double {
        totalTournaments > 0 ? Double(completedTournaments) / Double(totalTournaments) : 0.0
    }
    
    var fillRate: Double {
        totalTournaments > 0 ? Double(fullTournaments) / Double(totalTournaments) : 0.0
    }
}

/// Tournament leaderboard entry for global rankings
struct TournamentLeaderboardEntry: Codable, Identifiable {
    let id: UUID
    let userId: String
    let displayName: String
    var tournamentsPlayed: Int
    var championships: Int
    var totalWins: Int
    var totalLosses: Int
    var totalPlacement: Int
    var averageRank: Double
    var winRate: Double
    var points: Int
    
    var rank: Int = 0 // Set when generating leaderboard
    
    init(userId: String, displayName: String, tournamentsPlayed: Int = 0, championships: Int = 0, totalWins: Int = 0, totalLosses: Int = 0, totalPlacement: Int = 0, averageRank: Double = 0.0, winRate: Double = 0.0, points: Int = 0) {
        self.id = UUID()
        self.userId = userId
        self.displayName = displayName
        self.tournamentsPlayed = tournamentsPlayed
        self.championships = championships
        self.totalWins = totalWins
        self.totalLosses = totalLosses
        self.totalPlacement = totalPlacement
        self.averageRank = averageRank
        self.winRate = winRate
        self.points = points
    }
}

// MARK: - Enhanced Tournament Participant

extension TournamentParticipant {
    /// Creates a participant from a User object
    init(from user: User, partnerID: String? = nil, partnerName: String? = nil) {
        self.init(
            userID: user.id.uuidString,
            displayName: user.displayName,
            elo: user.elo,
            partnerID: partnerID,
            partnerName: partnerName
        )
    }
    
    /// Team name for doubles tournaments
    var teamDisplayName: String {
        return teamName?.isEmpty == false ? teamName! : effectiveName
    }
    
    /// Performance rating based on wins/losses and placement
    var performanceRating: Double {
        let winLossRatio = (wins + losses) > 0 ? Double(wins) / Double(wins + losses) : 0.0
        let placementBonus = placement != nil ? max(0, 10 - (placement ?? 10)) : 0
        return winLossRatio * 100 + Double(placementBonus) * 5
    }
}

// MARK: - Tournament Status Extensions

extension Tournament {
    /// Check if tournament is in progress
    var isInProgress: Bool {
        return status == "In Progress"
    }
    
    /// Check if tournament is completed
    var isCompleted: Bool {
        return status == "Completed"
    }
    
    /// Calculate registration progress (0.0 to 1.0)
    var registrationProgress: Double {
        return maxParticipants > 0 ? Double(participants.count) / Double(maxParticipants) : 0.0
    }
    
    /// Get available slots
    var availableSlots: Int {
        return max(0, maxParticipants - participants.count)
    }
    
    /// Check if tournament is full
    var isFull: Bool {
        return participants.count >= maxParticipants
    }
    
    /// Get tournament duration
    var duration: TimeInterval {
        return endDate.timeIntervalSince(startDate)
    }
    
    /// Get elapsed time since start (for in-progress tournaments)
    var elapsedTime: TimeInterval {
        guard isInProgress else { return 0 }
        return Date().timeIntervalSince(startDate)
    }
    
    /// Get estimated completion time
    var estimatedCompletionTime: Date {
        // Simple estimation based on number of matches and average match duration
        let averageMatchDuration: TimeInterval = 45 * 60 // 45 minutes
        let estimatedTotalTime = Double(matches.count) * averageMatchDuration
        return startDate.addingTimeInterval(estimatedTotalTime)
    }
    
    /// Get active matches
    var activeMatches: [TournamentMatch] {
        return matches.filter { $0.status == "In Progress" || $0.status == "Ready" }
    }
    
    /// Get completed matches
    var completedMatches: [TournamentMatch] {
        return matches.filter { $0.status == "Completed" }
    }
    
    /// Get current round number
    var currentRound: Int {
        return matches.map { $0.round }.max() ?? 1
    }
    
    /// Get tournament progress (0.0 to 1.0)
    var progress: Double {
        guard !matches.isEmpty else { return 0.0 }
        return Double(completedMatches.count) / Double(matches.count)
    }
    
    /// Get champion (first place participant)
    var champion: TournamentParticipant? {
        return participants.first { $0.placement == 1 }
    }
    
    /// Get runner-up (second place participant)
    var runnerUp: TournamentParticipant? {
        return participants.first { $0.placement == 2 }
    }
    
    /// Get third place participant
    var thirdPlace: TournamentParticipant? {
        return participants.first { $0.placement == 3 }
    }
    
    /// Get leaderboard (sorted participants by placement)
    var leaderboard: [TournamentParticipant] {
        return participants.sorted { p1, p2 in
            let placement1 = p1.placement ?? 999
            let placement2 = p2.placement ?? 999
            return placement1 < placement2
        }
    }
}

// MARK: - Tournament Match Extensions

extension TournamentMatch {
    /// Check if match involves a specific user
    func involvesUser(_ userId: String) -> Bool {
        return player1ID == userId || player2ID == userId
    }
    
    /// Get opponent ID for a specific user
    func getOpponentId(for userId: String) -> String? {
        if player1ID == userId {
            return player2ID
        } else if player2ID == userId {
            return player1ID
        }
        return nil
    }
    
    /// Get opponent name for a specific user
    func getOpponentName(for userId: String) -> String {
        if player1ID == userId {
            return player2Name.isEmpty ? "TBD" : player2Name
        } else if player2ID == userId {
            return player1Name.isEmpty ? "TBD" : player1Name
        }
        return "Unknown"
    }
    
    /// Check if user won this match
    func didUserWin(_ userId: String) -> Bool? {
        guard status == "Completed", let winnerId = winnerID else { return nil }
        return winnerId == userId
    }
    
    /// Get match duration (if completed)
    var matchDuration: TimeInterval? {
        // This would require storing match start/end times in the model
        // For now, return nil
        return nil
    }
    
    /// Get formatted match description
    var matchDescription: String {
        let p1Name = player1Name.isEmpty ? "TBD" : player1Name
        let p2Name = player2Name.isEmpty ? "TBD" : player2Name
        
        if status == "Completed", !finalScore.isEmpty {
            return "\(p1Name) vs \(p2Name) - \(finalScore)"
        } else {
            return "\(p1Name) vs \(p2Name)"
        }
    }
}

// MARK: - Tournament Validation Helpers

extension Tournament {
    /// Validate tournament data for creation
    func validate() throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TournamentError.invalidName
        }
        
        guard maxParticipants >= 4 && maxParticipants <= 128 else {
            throw TournamentError.invalidParticipantCount(maxParticipants)
        }
        
        guard startDate > Date() else {
            throw TournamentError.invalidStartDate
        }
        
        guard endDate > startDate else {
            throw TournamentError.invalidStartDate
        }
        
        guard !organizerID.isEmpty else {
            throw TournamentError.invalidStatus("Organizer ID cannot be empty")
        }
    }
    
    /// Check if user can register for this tournament
    func canUserRegister(_ userId: String) -> (canRegister: Bool, reason: String?) {
        guard isRegistrationOpen else {
            return (false, "Registration is closed")
        }
        
        guard !isFull else {
            return (false, "Tournament is full")
        }
        
        guard !participants.contains(where: { $0.userID == userId }) else {
            return (false, "Already registered")
        }
        
        return (true, nil)
    }
    
    /// Check if tournament can be started
    func canBeStarted() -> (canStart: Bool, reason: String?) {
        guard status == "Registration Open" || status == "Registration Closed" else {
            return (false, "Tournament status must be Registration Open or Closed")
        }
        
        guard participants.count >= 4 else {
            return (false, "Need at least 4 participants")
        }
        
        return (true, nil)
    }
}

// MARK: - Error Types

enum TournamentError: LocalizedError, Equatable {
    case invalidName
    case invalidParticipantCount(Int)
    case invalidStartDate
    case registrationClosed
    case tournamentFull
    case alreadyRegistered
    case notRegistered
    case invalidStatus(String)
    case insufficientParticipants(Int)
    case matchAlreadyCompleted
    case invalidMatchResult
    case operationInProgress
    case batchOperationPartialFailure(String)
    case creationFailed(String)
    case fetchFailed(String)
    case registrationFailed(String)
    case leaveFailed(String)
    case matchUpdateFailed(String)
    case networkError(String)
    case operationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Tournament name cannot be empty"
        case .invalidParticipantCount(let count):
            return "Invalid participant count: \(count). Must be between 4 and 128."
        case .invalidStartDate:
            return "Tournament start date must be in the future"
        case .registrationClosed:
            return "Registration for this tournament is closed"
        case .tournamentFull:
            return "Tournament is full"
        case .alreadyRegistered:
            return "Already registered for this tournament"
        case .notRegistered:
            return "Not registered for this tournament"
        case .invalidStatus(let status):
            return "Invalid tournament status: \(status)"
        case .insufficientParticipants(let count):
            return "Insufficient participants to start tournament: \(count)"
        case .matchAlreadyCompleted:
            return "Match has already been completed"
        case .invalidMatchResult:
            return "Invalid match result"
        case .operationInProgress:
            return "Another operation is already in progress"
        case .batchOperationPartialFailure(let message):
            return "Batch operation partially failed: \(message)"
        case .creationFailed(let message):
            return "Failed to create tournament: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch tournament data: \(message)"
        case .registrationFailed(let message):
            return "Failed to register for tournament: \(message)"
        case .leaveFailed(let message):
            return "Failed to leave tournament: \(message)"
        case .matchUpdateFailed(let message):
            return "Failed to update match: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        }
    }
} 
