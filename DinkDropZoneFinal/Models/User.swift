import Foundation
import SwiftData
import SwiftUI

enum UserError: LocalizedError {
    case invalidEmail
    case invalidELO
    case invalidXP
    case invalidMatchCount
    case invalidWinStreak
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Invalid email format"
        case .invalidELO:
            return "ELO rating must be non-negative"
        case .invalidXP:
            return "XP must be non-negative"
        case .invalidMatchCount:
            return "Invalid match count"
        case .invalidWinStreak:
            return "Win streak must be non-negative"
        }
    }
}

@Model
final class User: @unchecked Sendable {
    var id: UUID
    var email: String
    var password: String
    var displayName: String
    var bio: String
    var location: String
    var skillLevel: String
    var playStyle: String
    var favoriteShot: String
    var availability: [String: Bool]
    var profileImageURL: String?
    var elo: Int
    var xp: Int
    var totalMatches: Int
    var wins: Int
    var losses: Int
    var winStreak: Int
    var longestWinStreak: Int
    var totalPointsScored: Int
    var totalPointsConceded: Int
    // Note: achievements and monthlyStats removed for SwiftData compatibility
    // These can be stored separately or as JSON data if needed
    
    // Temporary computed properties for compatibility
    var achievements: [Achievement] { [] }
    var monthlyStats: [String: MonthlyStats] { [:] }
    var friends: [User] { [] }
    var teams: [Team] { [] }
    var leagues: [PickleLeague] { [] }
    var joinDate: Date
    var coins: Int
    var level: Int
    // Note: Temporarily removing relationships to isolate SwiftData issues
    // var friends: [User]
    // var teams: [Team]
    // var leagues: [PickleLeague]
    // Note: matches relationship removed to avoid circular reference issues
    // Use queries to fetch matches for a user instead
    // Note: notifications removed for SwiftData compatibility
    // These can be stored separately or as JSON data if needed
    
    // Temporary computed properties for compatibility
    var notifications: [UserNotification] { [] }
    var settings: UserSettings { UserSettings() }
    // Temporarily removing UserSettings relationship to isolate SwiftData issues
    // var settings: UserSettings
    var createdAt: Date
    var lastActive: Date
    

    
    init(
        id: UUID = UUID(),
        email: String,
        password: String,
        displayName: String = "",
        bio: String = "",
        location: String = "",
        skillLevel: String = SkillLevel.beginner.rawValue,
        playStyle: String = PlayStyle.balanced.rawValue,
        favoriteShot: String = "",
        availability: [String: Bool] = [:],
        profileImageURL: String? = nil,
        elo: Int = 1000,
        xp: Int = 0,
        totalMatches: Int = 0,
        wins: Int = 0,
        losses: Int = 0,
        winStreak: Int = 0,
        longestWinStreak: Int = 0,
        totalPointsScored: Int = 0,
        totalPointsConceded: Int = 0,

        joinDate: Date = Date(),
        coins: Int = 0,
        level: Int = 1,
        // friends: [User] = [],
        // teams: [Team] = [],
        // leagues: [PickleLeague] = [],

        // settings: UserSettings = UserSettings(),
        createdAt: Date = Date(),
        lastActive: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.password = password
        self.displayName = displayName
        self.bio = bio
        self.location = location
        self.skillLevel = skillLevel
        self.playStyle = playStyle
        self.favoriteShot = favoriteShot
        self.availability = availability
        self.profileImageURL = profileImageURL
        self.elo = elo
        self.xp = xp
        self.totalMatches = totalMatches
        self.wins = wins
        self.losses = losses
        self.winStreak = winStreak
        self.longestWinStreak = longestWinStreak
        self.totalPointsScored = totalPointsScored
        self.totalPointsConceded = totalPointsConceded

        self.joinDate = joinDate
        self.coins = coins
        self.level = level
        // self.friends = friends
        // self.teams = teams
        // self.leagues = leagues

        // self.settings = settings
        self.createdAt = createdAt
        self.lastActive = lastActive
    }
    

    
    var winRate: Double {
        guard totalMatches > 0 else { return 0 }
        return Double(wins) / Double(totalMatches)
    }
    
    var formattedWinRate: String {
        let percentage = winRate * 100
        return String(format: "%.1f%%", percentage)
    }
    
    var averagePointsPerMatch: Double {
        guard totalMatches > 0 else { return 0 }
        return Double(totalPointsScored) / Double(totalMatches)
    }
    
    var pointsDifferential: Int {
        return totalPointsScored - totalPointsConceded
    }
    
    func updateMonthlyStats(for date: Date, matchResult: UserMatchResult) {
        // Note: Monthly stats functionality removed for SwiftData compatibility
        // This can be implemented using separate models or JSON storage
    }
    
    func checkForNewAchievements() -> [Achievement] {
        // Note: Achievements functionality removed for SwiftData compatibility
        // This can be implemented using separate models or JSON storage
        return []
    }
    
    func addMatch(_ match: Match) {
        // Note: matches are now stored separately, not as a relationship
        totalMatches += 1
        
        if match.isWin(for: self) {
            wins += 1
            winStreak += 1
            longestWinStreak = max(longestWinStreak, winStreak)
        } else {
            losses += 1
            winStreak = 0
        }
        
        updateElo(match)
    }
    
    private func updateElo(_ match: Match) {
        let eloChange = Int(match.eloChange) ?? 0
        elo += eloChange
    }
    
    func addXP(_ amount: Int) {
        xp += amount
        level = XPManager.calculateLevel(from: xp)
    }
    
    func addCoins(_ amount: Int) {
        coins += amount
    }
    
    func addFriend(_ user: User) {
        // Note: Friends functionality removed for SwiftData compatibility
        // This can be implemented using separate models or JSON storage
    }
    
    func removeFriend(_ user: User) {
        // Note: Friends functionality removed for SwiftData compatibility
        // This can be implemented using separate models or JSON storage
    }
    
    func joinTeam(_ team: Team) {
        // Note: Teams functionality removed for SwiftData compatibility
        // This can be implemented using separate models or JSON storage
    }
    
    func leaveTeam(_ team: Team) {
        // Note: Teams functionality removed for SwiftData compatibility
        // This can be implemented using separate models or JSON storage
    }
    
    func joinLeague(_ league: PickleLeague) {
        // Note: Leagues functionality removed for SwiftData compatibility
        // This can be implemented using separate models or JSON storage
    }
    
    func leaveLeague(_ league: PickleLeague) {
        // Note: Leagues functionality removed for SwiftData compatibility
        // This can be implemented using separate models or JSON storage
    }
    
    func unlockAchievement(_ achievement: Achievement) {
        // Note: Achievements functionality removed for SwiftData compatibility
        // This can be implemented using separate models or JSON storage
        addXP(achievement.xpReward)
        addCoins(achievement.coinReward)
    }
    
    func addNotification(_ notification: UserNotification) {
        // Note: Notifications functionality removed for SwiftData compatibility
        // This can be implemented using separate models or JSON storage
    }
    
    func markNotificationAsRead(_ notification: UserNotification) {
        // Note: Notifications functionality removed for SwiftData compatibility
        // This can be implemented using separate models or JSON storage
    }
    
    func clearNotifications() {
        // Note: Notifications functionality removed for SwiftData compatibility
        // This can be implemented using separate models or JSON storage
    }
}

// MARK: - Supporting Types

struct UserMatchResult: Codable {
    let isWin: Bool
    let pointsScored: Int
    let pointsConceded: Int
    let eloChange: Int
    
    init(isWin: Bool, pointsScored: Int, pointsConceded: Int, eloChange: Int) {
        self.isWin = isWin
        self.pointsScored = pointsScored
        self.pointsConceded = pointsConceded
        self.eloChange = eloChange
    }
}

struct MonthlyStats: Codable {
    var matches: Int = 0
    var wins: Int = 0
    var pointsScored: Int = 0
    var pointsConceded: Int = 0
    var eloChange: Int = 0
    
    var winRate: Double {
        guard matches > 0 else { return 0 }
        return Double(wins) / Double(matches)
    }
    
    var losses: Int {
        matches - wins
    }
    
    mutating func updateWith(result: UserMatchResult) {
        matches += 1
        if result.isWin {
            wins += 1
        }
        pointsScored += result.pointsScored
        pointsConceded += result.pointsConceded
        eloChange += result.eloChange
    }
}

public struct Achievement: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let description: String
    public let icon: String
    public let dateEarned: Date
    public let type: AchievementType
    public let xpReward: Int
    public let coinReward: Int
    
    public init(
        id: UUID = .init(),
        title: String,
        description: String,
        icon: String,
        dateEarned: Date,
        type: AchievementType,
        xpReward: Int = 0,
        coinReward: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.dateEarned = dateEarned
        self.type = type
        self.xpReward = xpReward
        self.coinReward = coinReward
    }
    
    public enum AchievementType: String, Codable, CaseIterable {
        case skill = "Skill"
        case milestone = "Milestone"
        case special = "Special"
        case streak = "Streak"
        case score = "Score"
        
        var color: Color {
            switch self {
            case .skill: return .blue
            case .milestone: return .green
            case .special: return .purple
            case .streak: return .orange
            case .score: return .red
            }
        }
    }
}

// MARK: - Achievement System

class AchievementManager {
    static func getAllPossibleAchievements() -> [Achievement] {
        return [
            // Milestone Achievements
            Achievement(title: "First Steps", description: "Play your first match", icon: "figure.walk", dateEarned: Date(), type: .milestone, xpReward: 0, coinReward: 0),
            Achievement(title: "Getting Started", description: "Win your first match", icon: "trophy.fill", dateEarned: Date(), type: .milestone, xpReward: 0, coinReward: 0),
            Achievement(title: "Dedicated Player", description: "Play 10 matches", icon: "10.circle.fill", dateEarned: Date(), type: .milestone, xpReward: 0, coinReward: 0),
            Achievement(title: "Veteran", description: "Play 50 matches", icon: "50.circle.fill", dateEarned: Date(), type: .milestone, xpReward: 0, coinReward: 0),
            Achievement(title: "Legend", description: "Play 100 matches", icon: "100.circle.fill", dateEarned: Date(), type: .milestone, xpReward: 0, coinReward: 0),
            
            // Skill Achievements
            Achievement(title: "Rising Star", description: "Reach 1200 ELO", icon: "star.fill", dateEarned: Date(), type: .skill, xpReward: 0, coinReward: 0),
            Achievement(title: "Advanced Player", description: "Reach 1600 ELO", icon: "star.circle.fill", dateEarned: Date(), type: .skill, xpReward: 0, coinReward: 0),
            Achievement(title: "Expert Level", description: "Reach 2000 ELO", icon: "crown.fill", dateEarned: Date(), type: .skill, xpReward: 0, coinReward: 0),
            Achievement(title: "Master", description: "Reach 2400 ELO", icon: "diamond.fill", dateEarned: Date(), type: .skill, xpReward: 0, coinReward: 0),
            
            // Streak Achievements
            Achievement(title: "Hot Streak", description: "Win 3 matches in a row", icon: "flame.fill", dateEarned: Date(), type: .streak, xpReward: 0, coinReward: 0),
            Achievement(title: "On Fire", description: "Win 5 matches in a row", icon: "flame.circle.fill", dateEarned: Date(), type: .streak, xpReward: 0, coinReward: 0),
            Achievement(title: "Unstoppable", description: "Win 10 matches in a row", icon: "bolt.fill", dateEarned: Date(), type: .streak, xpReward: 0, coinReward: 0),
            
            // Score Achievements
            Achievement(title: "Dominant Victory", description: "Win a match 11-0", icon: "shield.fill", dateEarned: Date(), type: .score, xpReward: 0, coinReward: 0),
            Achievement(title: "High Scorer", description: "Score 100 total points", icon: "target", dateEarned: Date(), type: .score, xpReward: 0, coinReward: 0),
            Achievement(title: "Point Machine", description: "Score 500 total points", icon: "burst.fill", dateEarned: Date(), type: .score, xpReward: 0, coinReward: 0),
            
            // Special Achievements
            Achievement(title: "Early Adopter", description: "Join during beta", icon: "sparkles", dateEarned: Date(), type: .special, xpReward: 0, coinReward: 0),
            Achievement(title: "Profile Complete", description: "Fill out your complete profile", icon: "person.fill.checkmark", dateEarned: Date(), type: .special, xpReward: 0, coinReward: 0),
            Achievement(title: "Social Player", description: "Play matches with 10 different opponents", icon: "person.3.fill", dateEarned: Date(), type: .special, xpReward: 0, coinReward: 0)
        ]
    }
    
    static func checkAchievement(_ achievement: Achievement, for user: User) -> Bool {
        switch achievement.title {
        case "First Steps": return user.totalMatches >= 1
        case "Getting Started": return user.wins >= 1
        case "Dedicated Player": return user.totalMatches >= 10
        case "Veteran": return user.totalMatches >= 50
        case "Legend": return user.totalMatches >= 100
        case "Rising Star": return user.elo >= 1200
        case "Advanced Player": return user.elo >= 1600
        case "Expert Level": return user.elo >= 2000
        case "Master": return user.elo >= 2400
        case "Hot Streak": return user.winStreak >= 3
        case "On Fire": return user.winStreak >= 5
        case "Unstoppable": return user.winStreak >= 10
        case "High Scorer": return user.totalPointsScored >= 100
        case "Point Machine": return user.totalPointsScored >= 500
        case "Profile Complete": return !user.displayName.isEmpty && !user.bio.isEmpty && !user.location.isEmpty
        default: return false
        }
    }
}

public enum SkillLevel: String, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    case expert = "Expert"
    case pro = "Professional"
    
    public var description: String {
        switch self {
        case .beginner: return "New to pickleball"
        case .intermediate: return "Regular player with good fundamentals"
        case .advanced: return "Experienced player with strong skills"
        case .expert: return "Highly skilled player"
        case .pro: return "Professional level player"
        }
    }
    
    public var eloRange: ClosedRange<Int> {
        switch self {
        case .beginner: return 0...1200
        case .intermediate: return 1201...1600
        case .advanced: return 1601...2000
        case .expert: return 2001...2400
        case .pro: return 2401...3000
        }
    }
}

public enum PlayStyle: String, CaseIterable {
    case aggressive = "Aggressive"
    case defensive = "Defensive"
    case balanced = "Balanced"
    case technical = "Technical"
    case power = "Power"
    
    public var description: String {
        switch self {
        case .aggressive: return "Focuses on offensive play and quick points"
        case .defensive: return "Prioritizes consistency and counter-attacking"
        case .balanced: return "Adapts strategy based on the situation"
        case .technical: return "Emphasizes precision and shot placement"
        case .power: return "Relies on strong serves and powerful shots"
        }
    }
}

// MARK: - Preview Helpers

extension User {
    static var preview: User {
        User(
            email: "player@example.com",
            password: "password123",
            displayName: "Player One",
            elo: 1200,
            xp: 5000,
            totalMatches: 50,
            wins: 30,
            losses: 20,
            winStreak: 3,
            longestWinStreak: 5,
            coins: 1000,
            level: 5
        )
    }
    
    static var sampleUsers: [User] {
        [
            User(
                email: "alex@example.com",
                password: "password123",
                displayName: "Alex",
                elo: 1500,
                xp: 8000,
                totalMatches: 100,
                wins: 65,
                losses: 35,
                winStreak: 5,
                longestWinStreak: 8,
                coins: 2000,
                level: 8
            ),
            User(
                email: "sam@example.com",
                password: "password123",
                displayName: "Sam",
                elo: 1300,
                xp: 6000,
                totalMatches: 75,
                wins: 45,
                losses: 30,
                winStreak: 2,
                longestWinStreak: 6,
                coins: 1500,
                level: 6
            ),
            User(
                email: "casey@example.com",
                password: "password123",
                displayName: "Casey",
                elo: 1100,
                xp: 4000,
                totalMatches: 40,
                wins: 20,
                losses: 20,
                winStreak: 0,
                longestWinStreak: 4,
                coins: 800,
                level: 4
            )
        ]
    }
} 