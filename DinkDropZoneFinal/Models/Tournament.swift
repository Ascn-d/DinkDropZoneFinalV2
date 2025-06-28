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
