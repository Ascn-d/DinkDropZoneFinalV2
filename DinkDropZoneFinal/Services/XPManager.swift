import Foundation

struct XPManager {
    
    // MARK: - XP Constants
    
    static let baseXPPerLevel = 100
    static let xpMultiplier = 1.2
    
    // MARK: - XP Rewards
    
    enum XPReward: Int {
        case matchComplete = 50
        case matchWin = 100
        case matchLoss = 25
        case firstMatchOfDay = 60
        case winStreak3 = 75
        case winStreak5 = 150
        case winStreak10 = 300
        case perfectGame = 200 // 11-0 win
        case challengeComplete = 30
        case dailyChallengeComplete = 110
        case achievementEarned = 160
        case profileComplete = 120
        case socialMatch = 35 // Playing with new opponent
        case tournamentParticipation = 250
        case tournamentWin = 500
    }
    
    // MARK: - Level Calculations
    
    static func calculateLevel(from xp: Int) -> Int {
        var level = 1
        var xpRequired = baseXPPerLevel
        var totalXP = 0
        
        while totalXP + xpRequired <= xp {
            totalXP += xpRequired
            level += 1
            xpRequired = Int(Double(baseXPPerLevel) * pow(xpMultiplier, Double(level - 1)))
        }
        
        return level
    }
    
    static func xpRequiredForLevel(_ level: Int) -> Int {
        var totalXP = 0
        
        for currentLevel in 1..<level {
            let xpForLevel = Int(Double(baseXPPerLevel) * pow(xpMultiplier, Double(currentLevel - 1)))
            totalXP += xpForLevel
        }
        
        return totalXP
    }
    
    static func xpRequiredForNextLevel(currentXP: Int) -> Int {
        let currentLevel = calculateLevel(from: currentXP)
        let nextLevelXP = xpRequiredForLevel(currentLevel + 1)
        return nextLevelXP - currentXP
    }
    
    static func xpProgressInCurrentLevel(currentXP: Int) -> (current: Int, required: Int, progress: Double) {
        let currentLevel = calculateLevel(from: currentXP)
        let currentLevelStartXP = xpRequiredForLevel(currentLevel)
        let nextLevelXP = xpRequiredForLevel(currentLevel + 1)
        
        let xpInCurrentLevel = currentXP - currentLevelStartXP
        let xpRequiredForLevel = nextLevelXP - currentLevelStartXP
        
        let progress = Double(xpInCurrentLevel) / Double(xpRequiredForLevel)
        
        return (current: xpInCurrentLevel, required: xpRequiredForLevel, progress: progress)
    }
    
    // MARK: - XP Award Functions
    
    static func awardXP(to user: inout User, reward: XPReward, context: String = "") -> Bool {
        let oldLevel = calculateLevel(from: user.xp)
        user.xp += reward.rawValue
        let newLevel = calculateLevel(from: user.xp)
        
        // Log XP gain
        LoggingService.shared.log("User \(user.displayName) gained \(reward.rawValue) XP for \(context.isEmpty ? reward.description : context)")
        
        // Check for level up
        if newLevel > oldLevel {
            handleLevelUp(user: &user, oldLevel: oldLevel, newLevel: newLevel)
            return true // Indicates level up occurred
        }
        
        return false
    }
    
    private static func handleLevelUp(user: inout User, oldLevel: Int, newLevel: Int) {
        LoggingService.shared.log("User \(user.displayName) leveled up from \(oldLevel) to \(newLevel)!")
        
        // Award bonus XP for level up
        user.xp += 50
        
        // Check for level-based achievements
        let _ = user.checkForNewAchievements()
        
        // Could trigger notifications, unlock features, etc.
        NotificationCenter.default.post(
            name: .userLeveledUp,
            object: nil,
            userInfo: [
                "user": user,
                "oldLevel": oldLevel,
                "newLevel": newLevel
            ]
        )
    }
    
    // MARK: - Daily Challenge XP
    
    static func calculateDailyChallengeXP(challengeType: DailyChallengeType) -> Int {
        switch challengeType {
        case .playMatch: return 50
        case .winMatch: return 75
        case .socialPlayer: return 100
        case .perfectGame: return 150
        case .winStreak: return 125
        }
    }
}

// MARK: - Daily Challenge System

enum DailyChallengeType: String, CaseIterable, Codable {
    case playMatch = "Play a Match"
    case winMatch = "Win a Game"
    case socialPlayer = "Social Player"
    case perfectGame = "Perfect Game"
    case winStreak = "Win Streak"
    
    var description: String {
        switch self {
        case .playMatch: return "Complete 1 match today"
        case .winMatch: return "Win 1 game today"
        case .socialPlayer: return "Play with 2 different opponents"
        case .perfectGame: return "Win a match 11-0"
        case .winStreak: return "Win 3 matches in a row"
        }
    }
    
    var icon: String {
        switch self {
        case .playMatch: return "gamecontroller.fill"
        case .winMatch: return "trophy.fill"
        case .socialPlayer: return "person.2.fill"
        case .perfectGame: return "crown.fill"
        case .winStreak: return "flame.fill"
        }
    }
    
    var targetValue: Int {
        switch self {
        case .playMatch: return 1
        case .winMatch: return 1
        case .socialPlayer: return 2
        case .perfectGame: return 1
        case .winStreak: return 3
        }
    }
}

struct DailyChallenge: Codable, Identifiable {
    let id: UUID
    let type: DailyChallengeType
    let date: Date
    var progress: Int
    var isCompleted: Bool
    let xpReward: Int
    
    init(type: DailyChallengeType, date: Date = Date()) {
        self.id = UUID()
        self.type = type
        self.date = date
        self.progress = 0
        self.isCompleted = false
        self.xpReward = XPManager.calculateDailyChallengeXP(challengeType: type)
    }
    
    var progressPercentage: Double {
        return min(1.0, Double(progress) / Double(type.targetValue))
    }
    
    mutating func updateProgress(increment: Int = 1) -> Bool {
        guard !isCompleted else { return false }
        
        progress += increment
        if progress >= type.targetValue {
            isCompleted = true
            return true
        }
        return false
    }
}

// MARK: - Extensions

extension XPManager.XPReward {
    var description: String {
        switch self {
        case .matchComplete: return "completing a match"
        case .matchWin: return "winning a match"
        case .matchLoss: return "match participation"
        case .firstMatchOfDay: return "first match of the day"
        case .winStreak3: return "3-match win streak"
        case .winStreak5: return "5-match win streak"
        case .winStreak10: return "10-match win streak"
        case .perfectGame: return "perfect game victory"
        case .challengeComplete: return "completing a challenge"
        case .dailyChallengeComplete: return "daily challenge completion"
        case .achievementEarned: return "earning an achievement"
        case .profileComplete: return "completing profile"
        case .socialMatch: return "playing with new opponent"
        case .tournamentParticipation: return "tournament participation"
        case .tournamentWin: return "tournament victory"
        }
    }
}

extension Notification.Name {
    static let userLeveledUp = Notification.Name("userLeveledUp")
    static let dailyChallengeCompleted = Notification.Name("dailyChallengeCompleted")
    static let achievementEarned = Notification.Name("achievementEarned")
} 