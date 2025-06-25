import Foundation
import SwiftUI
import Combine

// MARK: - Advanced Achievement System

/// Represents different tiers of achievements
enum AchievementTier: String, Codable, CaseIterable {
    case bronze = "Bronze"
    case silver = "Silver" 
    case gold = "Gold"
    case platinum = "Platinum"
    case legendary = "Legendary"
    
    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.7, green: 0.7, blue: 0.7)
        case .gold: return Color(red: 1.0, green: 0.8, blue: 0.0)
        case .platinum: return Color(red: 0.9, green: 0.9, blue: 1.0)
        case .legendary: return Color(red: 1.0, green: 0.4, blue: 0.8)
        }
    }
    
    var xpMultiplier: Double {
        switch self {
        case .bronze: return 1.0
        case .silver: return 1.5
        case .gold: return 2.0
        case .platinum: return 3.0
        case .legendary: return 5.0
        }
    }
    
    var icon: String {
        switch self {
        case .bronze: return "medal.fill"
        case .silver: return "medal.fill"
        case .gold: return "medal.fill"
        case .platinum: return "star.circle.fill"
        case .legendary: return "crown.fill"
        }
    }
}

/// Defines different categories of achievements
enum AchievementCategory: String, Codable, CaseIterable {
    case gameplay = "Gameplay"
    case social = "Social"
    case progression = "Progression"
    case competitive = "Competitive"
    case exploration = "Exploration"
    case seasonal = "Seasonal"
    case secret = "Secret"
    
    var icon: String {
        switch self {
        case .gameplay: return "gamecontroller.fill"
        case .social: return "person.2.fill"
        case .progression: return "chart.line.uptrend.xyaxis"
        case .competitive: return "trophy.fill"
        case .exploration: return "map.fill"
        case .seasonal: return "calendar"
        case .secret: return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .gameplay: return .blue
        case .social: return .green
        case .progression: return .purple
        case .competitive: return .orange
        case .exploration: return .cyan
        case .seasonal: return .pink
        case .secret: return .gray
        }
    }
}

/// Complex achievement conditions
struct AchievementCondition: Codable {
    let type: ConditionType
    let value: Int
    let timeframe: TimeFrame?
    
    enum ConditionType: String, Codable {
        // Match-based conditions
        case matchesPlayed = "matches_played"
        case matchesWon = "matches_won"
        case winStreak = "win_streak"
        case perfectGames = "perfect_games"
        case comebackWins = "comeback_wins"
        
        // Score-based conditions
        case pointsScored = "points_scored"
        case averagePointsPerMatch = "avg_points_per_match"
        case shutoutWins = "shutout_wins"
        
        // Social conditions
        case friendsAdded = "friends_added"
        case matchesWithFriends = "matches_with_friends"
        case playersDefeated = "players_defeated"
        
        // Progression conditions
        case levelReached = "level_reached"
        case xpEarned = "xp_earned"
        case eloRating = "elo_rating"
        case eloGained = "elo_gained"
        
        // Time-based conditions
        case consecutiveDaysPlayed = "consecutive_days"
        case matchesInDay = "matches_in_day"
        case hoursPlayed = "hours_played"
        
        // Special conditions
        case tournamentsWon = "tournaments_won"
        case leaguesJoined = "leagues_joined"
        case courtsVisited = "courts_visited"
    }
    
    enum TimeFrame: String, Codable {
        case daily = "daily"
        case weekly = "weekly" 
        case monthly = "monthly"
        case allTime = "all_time"
    }
}

/// Advanced Trophy/Achievement model
struct Trophy: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let category: AchievementCategory
    let tier: AchievementTier
    let icon: String
    let conditions: [AchievementCondition]
    let xpReward: Int
    let prerequisiteAchievements: [UUID] // Achievement chains
    let isSecret: Bool
    let isLimited: Bool // Time-limited achievements
    let availableUntil: Date?
    
    // Progress tracking
    var progress: [String: Int] // Key-value pairs for tracking multiple conditions
    var isUnlocked: Bool
    var unlockedAt: Date?
    var currentProgress: Double // 0.0 to 1.0
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: AchievementCategory,
        tier: AchievementTier,
        icon: String,
        conditions: [AchievementCondition],
        xpReward: Int? = nil,
        prerequisiteAchievements: [UUID] = [],
        isSecret: Bool = false,
        isLimited: Bool = false,
        availableUntil: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.tier = tier
        self.icon = icon
        self.conditions = conditions
        self.xpReward = xpReward ?? Int(Double(tier.xpMultiplier) * 100)
        self.prerequisiteAchievements = prerequisiteAchievements
        self.isSecret = isSecret
        self.isLimited = isLimited
        self.availableUntil = availableUntil
        self.progress = [:]
        self.isUnlocked = false
        self.unlockedAt = nil
        self.currentProgress = 0.0
    }
    
    /// Updates progress for a specific condition
    mutating func updateProgress(for conditionType: AchievementCondition.ConditionType, value: Int) {
        let key = conditionType.rawValue
        progress[key] = value
        recalculateProgress()
    }
    
    /// Recalculates overall progress based on all conditions
    mutating func recalculateProgress() {
        var totalProgress: Double = 0
        
        for condition in conditions {
            let currentValue = progress[condition.type.rawValue] ?? 0
            let conditionProgress = min(1.0, Double(currentValue) / Double(condition.value))
            totalProgress += conditionProgress
        }
        
        currentProgress = totalProgress / Double(conditions.count)
        
        // Check if achievement should be unlocked
        if currentProgress >= 1.0 && !isUnlocked {
            unlock()
        }
    }
    
    /// Unlocks the achievement
    mutating func unlock() {
        isUnlocked = true
        unlockedAt = Date()
    }
    
    /// Checks if prerequisites are met
    func hasMetPrerequisites(unlockedAchievements: Set<UUID>) -> Bool {
        return prerequisiteAchievements.allSatisfy { unlockedAchievements.contains($0) }
    }
    
    /// Gets display text for progress
    func getProgressText() -> String {
        if isUnlocked {
            return "Completed"
        }
        
        if isSecret && currentProgress < 0.1 {
            return "???"
        }
        
        return "\(Int(currentProgress * 100))% Complete"
    }
}

// MARK: - Achievement Definitions

struct AchievementDefinitions {
    
    static let allAchievements: [Trophy] = [
        // MARK: - Gameplay Achievements
        
        // First Steps
        Trophy(
            title: "First Serve",
            description: "Play your first match",
            category: .gameplay,
            tier: .bronze,
            icon: "tennis.racket",
            conditions: [
                AchievementCondition(type: .matchesPlayed, value: 1, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Getting Warmed Up",
            description: "Play 10 matches",
            category: .gameplay,
            tier: .bronze,
            icon: "flame",
            conditions: [
                AchievementCondition(type: .matchesPlayed, value: 10, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Court Regular",
            description: "Play 50 matches",
            category: .gameplay,
            tier: .silver,
            icon: "figure.tennis",
            conditions: [
                AchievementCondition(type: .matchesPlayed, value: 50, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Pickleball Veteran",
            description: "Play 200 matches",
            category: .gameplay,
            tier: .gold,
            icon: "sportscourt",
            conditions: [
                AchievementCondition(type: .matchesPlayed, value: 200, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Legend of the Court",
            description: "Play 1000 matches",
            category: .gameplay,
            tier: .legendary,
            icon: "crown",
            conditions: [
                AchievementCondition(type: .matchesPlayed, value: 1000, timeframe: .allTime)
            ]
        ),
        
        // MARK: - Win Achievements
        
        Trophy(
            title: "First Victory",
            description: "Win your first match",
            category: .competitive,
            tier: .bronze,
            icon: "hand.raised.fill",
            conditions: [
                AchievementCondition(type: .matchesWon, value: 1, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Hat Trick",
            description: "Win 3 matches in a row",
            category: .competitive,
            tier: .silver,
            icon: "3.circle.fill",
            conditions: [
                AchievementCondition(type: .winStreak, value: 3, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Unstoppable",
            description: "Win 5 matches in a row",
            category: .competitive,
            tier: .gold,
            icon: "5.circle.fill",
            conditions: [
                AchievementCondition(type: .winStreak, value: 5, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Legendary Streak",
            description: "Win 10 matches in a row",
            category: .competitive,
            tier: .legendary,
            icon: "infinity.circle.fill",
            conditions: [
                AchievementCondition(type: .winStreak, value: 10, timeframe: .allTime)
            ]
        ),
        
        // MARK: - Perfect Game Achievements
        
        Trophy(
            title: "Flawless Victory",
            description: "Win a match 11-0",
            category: .competitive,
            tier: .gold,
            icon: "shield.checkered",
            conditions: [
                AchievementCondition(type: .perfectGames, value: 1, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Perfectionist",
            description: "Win 5 perfect games",
            category: .competitive,
            tier: .platinum,
            icon: "diamond.fill",
            conditions: [
                AchievementCondition(type: .perfectGames, value: 5, timeframe: .allTime)
            ]
        ),
        
        // MARK: - Social Achievements
        
        Trophy(
            title: "Social Butterfly",
            description: "Add 5 friends",
            category: .social,
            tier: .bronze,
            icon: "person.2.badge.plus",
            conditions: [
                AchievementCondition(type: .friendsAdded, value: 5, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Community Builder",
            description: "Add 25 friends",
            category: .social,
            tier: .silver,
            icon: "person.3.fill",
            conditions: [
                AchievementCondition(type: .friendsAdded, value: 25, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Network Master",
            description: "Add 100 friends",
            category: .social,
            tier: .gold,
            icon: "person.crop.circle.badge.plus",
            conditions: [
                AchievementCondition(type: .friendsAdded, value: 100, timeframe: .allTime)
            ]
        ),
        
        // MARK: - Progression Achievements
        
        Trophy(
            title: "Rising Star",
            description: "Reach level 10",
            category: .progression,
            tier: .bronze,
            icon: "star.fill",
            conditions: [
                AchievementCondition(type: .levelReached, value: 10, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Elite Player",
            description: "Reach level 25",
            category: .progression,
            tier: .silver,
            icon: "star.circle.fill",
            conditions: [
                AchievementCondition(type: .levelReached, value: 25, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Master Player",
            description: "Reach level 50",
            category: .progression,
            tier: .gold,
            icon: "star.square.fill",
            conditions: [
                AchievementCondition(type: .levelReached, value: 50, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Grandmaster",
            description: "Reach level 100",
            category: .progression,
            tier: .legendary,
            icon: "star.leadinghalf.filled",
            conditions: [
                AchievementCondition(type: .levelReached, value: 100, timeframe: .allTime)
            ]
        ),
        
        // MARK: - ELO Rating Achievements
        
        Trophy(
            title: "Climbing the Ranks",
            description: "Reach 1200 ELO",
            category: .competitive,
            tier: .bronze,
            icon: "chart.line.uptrend.xyaxis",
            conditions: [
                AchievementCondition(type: .eloRating, value: 1200, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Strong Competitor",
            description: "Reach 1500 ELO",
            category: .competitive,
            tier: .silver,
            icon: "arrowtriangle.up.fill",
            conditions: [
                AchievementCondition(type: .eloRating, value: 1500, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Elite Competitor",
            description: "Reach 1800 ELO",
            category: .competitive,
            tier: .gold,
            icon: "crown.fill",
            conditions: [
                AchievementCondition(type: .eloRating, value: 1800, timeframe: .allTime)
            ]
        ),
        
        Trophy(
            title: "Champion",
            description: "Reach 2000 ELO",
            category: .competitive,
            tier: .platinum,
            icon: "trophy.fill",
            conditions: [
                AchievementCondition(type: .eloRating, value: 2000, timeframe: .allTime)
            ]
        ),
        
        // MARK: - Complex Multi-Condition Achievements
        
        Trophy(
            title: "Weekend Warrior",
            description: "Win 10 matches and score 100 points in a single weekend",
            category: .gameplay,
            tier: .gold,
            icon: "calendar.badge.clock",
            conditions: [
                AchievementCondition(type: .matchesWon, value: 10, timeframe: .weekly),
                AchievementCondition(type: .pointsScored, value: 100, timeframe: .weekly)
            ]
        ),
        
        Trophy(
            title: "Daily Dominator",
            description: "Play 5 matches and maintain a perfect win rate in a single day",
            category: .competitive,
            tier: .platinum,
            icon: "sun.max.fill",
            conditions: [
                AchievementCondition(type: .matchesPlayed, value: 5, timeframe: .daily),
                AchievementCondition(type: .matchesWon, value: 5, timeframe: .daily)
            ]
        ),
        
        // MARK: - Secret Achievements
        
        Trophy(
            title: "The Chosen One",
            description: "A mysterious achievement for the truly dedicated",
            category: .secret,
            tier: .legendary,
            icon: "sparkles",
            conditions: [
                AchievementCondition(type: .matchesPlayed, value: 42, timeframe: .allTime),
                AchievementCondition(type: .perfectGames, value: 7, timeframe: .allTime),
                AchievementCondition(type: .friendsAdded, value: 13, timeframe: .allTime)
            ],
            isSecret: true
        ),
        
        Trophy(
            title: "Time Traveler",
            description: "Play at midnight exactly on New Year's Eve",
            category: .secret,
            tier: .platinum,
            icon: "clock.fill",
            conditions: [
                AchievementCondition(type: .matchesPlayed, value: 1, timeframe: .daily)
            ],
            isSecret: true
        ),
        
        // MARK: - Seasonal/Limited Achievements
        
        Trophy(
            title: "Holiday Champion",
            description: "Win 25 matches during the holiday season",
            category: .seasonal,
            tier: .gold,
            icon: "gift.fill",
            conditions: [
                AchievementCondition(type: .matchesWon, value: 25, timeframe: .monthly)
            ],
            isLimited: true,
            availableUntil: Calendar.current.date(from: DateComponents(year: 2024, month: 12, day: 31))
        ),
        
        // MARK: - Achievement Chains (with prerequisites)
        
        Trophy(
            title: "Court Master",
            description: "The ultimate gameplay achievement - requires completing multiple milestones",
            category: .gameplay,
            tier: .legendary,
            icon: "star.circle",
            conditions: [
                AchievementCondition(type: .matchesPlayed, value: 500, timeframe: .allTime),
                AchievementCondition(type: .levelReached, value: 75, timeframe: .allTime)
            ],
            prerequisiteAchievements: [] // Will be populated with IDs of prerequisite achievements
        )
    ]
    
    /// Gets achievements by category
    static func achievements(for category: AchievementCategory) -> [Trophy] {
        return allAchievements.filter { $0.category == category }
    }
    
    /// Gets achievements by tier
    static func achievements(for tier: AchievementTier) -> [Trophy] {
        return allAchievements.filter { $0.tier == tier }
    }
    
    /// Gets secret achievements
    static var secretAchievements: [Trophy] {
        return allAchievements.filter { $0.isSecret }
    }
    
    /// Gets limited-time achievements
    static var limitedAchievements: [Trophy] {
        return allAchievements.filter { $0.isLimited && ($0.availableUntil ?? Date.distantFuture) > Date() }
    }
}

// MARK: - Achievement Progress Tracker

@MainActor
class AdvancedAchievementTracker: ObservableObject {
    @Published var achievements: [Trophy] = []
    @Published var unlockedAchievements: Set<UUID> = []
    @Published var recentlyUnlocked: [Trophy] = []
    
    init() {
        loadAchievements()
    }
    
    private func loadAchievements() {
        achievements = AchievementDefinitions.allAchievements
        
        // Load progress from UserDefaults (in a real app, this would be from a database)
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let savedAchievements = try? JSONDecoder().decode([Trophy].self, from: data) {
            achievements = savedAchievements
            unlockedAchievements = Set(achievements.filter { $0.isUnlocked }.map { $0.id })
        }
    }
    
    func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: "achievements")
        }
    }
    
    /// Updates progress for specific achievement conditions
    func updateProgress(
        matchesPlayed: Int? = nil,
        matchesWon: Int? = nil,
        winStreak: Int? = nil,
        perfectGames: Int? = nil,
        friendsAdded: Int? = nil,
        pointsScored: Int? = nil,
        level: Int? = nil,
        eloRating: Int? = nil
    ) {
        let updates: [(AchievementCondition.ConditionType, Int)] = [
            (.matchesPlayed, matchesPlayed),
            (.matchesWon, matchesWon),
            (.winStreak, winStreak),
            (.perfectGames, perfectGames),
            (.friendsAdded, friendsAdded),
            (.pointsScored, pointsScored),
            (.levelReached, level),
            (.eloRating, eloRating)
        ].compactMap { type, value in
            guard let value = value else { return nil }
            return (type, value)
        }
        
        for i in 0..<achievements.count {
            let oldUnlocked = achievements[i].isUnlocked
            
            // Check prerequisites
            if !achievements[i].hasMetPrerequisites(unlockedAchievements: unlockedAchievements) {
                continue
            }
            
            // Update progress for matching conditions
            for (type, value) in updates {
                if achievements[i].conditions.contains(where: { $0.type == type }) {
                    achievements[i].updateProgress(for: type, value: value)
                }
            }
            
            // Check if newly unlocked
            if !oldUnlocked && achievements[i].isUnlocked {
                unlockedAchievements.insert(achievements[i].id)
                recentlyUnlocked.append(achievements[i])
                
                // Post notification for UI updates
                NotificationCenter.default.post(
                    name: .trophyUnlocked,
                    object: achievements[i],
                    userInfo: ["xpReward": achievements[i].xpReward]
                )
            }
        }
        
        saveAchievements()
    }
    
    /// Gets achievements by category with progress
    func getAchievements(for category: AchievementCategory) -> [Trophy] {
        return achievements.filter { $0.category == category }.sorted { first, second in
            if first.isUnlocked != second.isUnlocked {
                return first.isUnlocked && !second.isUnlocked
            }
            return first.tier.rawValue < second.tier.rawValue
        }
    }
    
    /// Gets overall achievement statistics
    func getStatistics() -> (unlocked: Int, total: Int, percentage: Double) {
        let unlocked = achievements.filter { $0.isUnlocked }.count
        let total = achievements.count
        let percentage = total > 0 ? Double(unlocked) / Double(total) : 0.0
        return (unlocked, total, percentage)
    }
    
    /// Gets achievement statistics by tier
    func getStatistics(for tier: AchievementTier) -> (unlocked: Int, total: Int) {
        let tierAchievements = achievements.filter { $0.tier == tier }
        let unlocked = tierAchievements.filter { $0.isUnlocked }.count
        return (unlocked, tierAchievements.count)
    }
    
    /// Clears recently unlocked achievements (call after showing notifications)
    func clearRecentlyUnlocked() {
        recentlyUnlocked.removeAll()
    }
} 