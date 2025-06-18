import Foundation
import SwiftData
import Observation
import SwiftUI

@MainActor
@Observable
final class XPManager {
    
    // MARK: - Properties
    
    private var modelContext: ModelContext
    
    // XP and Level tracking
    var currentXP: Int = 0
    var currentLevel: Int = 1
    var xpToNextLevel: Int = 100
    var totalXPEarned: Int = 0
    
    // Missions and Achievements
    var activeMissions: [Mission] = []
    var completedMissions: [Mission] = []
    var unlockedTrophies: [Trophy] = []
    var pendingRewards: [XPReward] = []
    
    // Tracking
    var dailyStats: DailyStats = DailyStats()
    var weeklyStats: WeeklyStats = WeeklyStats()
    var lifetimeStats: LifetimeStats = LifetimeStats()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadUserProgress()
        generateDailyMissions()
        checkForNewTrophies()
        
        // Listen for notifications to trigger UI updates
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .xpAwarded,
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let reward = userInfo["reward"] as? XPReward,
                  let amount = userInfo["amount"] as? Int else { return }
            
            // Post to notification manager if available
            NotificationCenter.default.post(
                name: .showXPNotification,
                object: nil,
                userInfo: ["reward": reward, "amount": amount]
            )
        }
        
        NotificationCenter.default.addObserver(
            forName: .userLeveledUp,
            object: nil,
            queue: .main
        ) { notification in
            guard let userInfo = notification.userInfo,
                  let newLevel = userInfo["newLevel"] as? Int,
                  let levelsGained = userInfo["levelsGained"] as? Int else { return }
            
            let xpGained = levelsGained * newLevel * 50 // Level up bonus calculation
            
            // Post to notification manager
            NotificationCenter.default.post(
                name: .showLevelUpNotification,
                object: nil,
                userInfo: ["newLevel": newLevel, "xpGained": xpGained]
            )
        }
        
        NotificationCenter.default.addObserver(
            forName: .missionCompleted,
            object: nil,
            queue: .main
        ) { notification in
            guard let mission = notification.object as? Mission,
                  let userInfo = notification.userInfo,
                  let xpReward = userInfo["xpReward"] as? Int else { return }
            
            // Post to notification manager
            NotificationCenter.default.post(
                name: .showMissionCompleteNotification,
                object: mission,
                userInfo: ["xpReward": xpReward]
            )
        }
    }
    
    // MARK: - XP System
    
    enum XPReward: Int, CaseIterable {
        case profileComplete = 50
        case firstMatch = 100
        case matchWin = 75
        case matchLoss = 25
        case matchComplete = 45
        case perfectGame = 200
        case winStreak3 = 150
        case winStreak5 = 300
        case winStreak10 = 500
        case tournamentJoin = 120
        case tournamentWin = 600
        case socialMatch = 55
        case dailyLogin = 35
        case weeklyLogin = 125
        case friendAdded = 30
        case messagesSent = 10
        case courtCheckin = 40
        case skillImprovement = 80
        case leagueJoin = 85
        case achievementUnlock = 110
        case missionComplete = 60
        case dailyChallengeComplete = 90
        
        var description: String {
            switch self {
            case .profileComplete: return "Complete your profile"
            case .firstMatch: return "Play your first match"
            case .matchWin: return "Win a match"
            case .matchLoss: return "Complete a match"
            case .matchComplete: return "Match completed"
            case .perfectGame: return "Win 11-0"
            case .winStreak3: return "3-game win streak"
            case .winStreak5: return "5-game win streak"
            case .winStreak10: return "10-game win streak"
            case .tournamentJoin: return "Join a tournament"
            case .tournamentWin: return "Win a tournament"
            case .socialMatch: return "Play with a friend"
            case .dailyLogin: return "Daily login bonus"
            case .weeklyLogin: return "Weekly login bonus"
            case .friendAdded: return "Add a friend"
            case .messagesSent: return "Send messages"
            case .courtCheckin: return "Check in at a court"
            case .skillImprovement: return "Improve skill level"
            case .leagueJoin: return "Join a league"
            case .achievementUnlock: return "Unlock achievement"
            case .missionComplete: return "Complete mission"
            case .dailyChallengeComplete: return "Complete daily challenge"
            }
        }
        
        var icon: String {
            switch self {
            case .profileComplete: return "person.fill"
            case .firstMatch: return "gamecontroller"
            case .matchWin: return "trophy.fill"
            case .matchLoss: return "gamecontroller.fill"
            case .matchComplete: return "gamecontroller.fill"
            case .perfectGame: return "crown.fill"
            case .winStreak3, .winStreak5, .winStreak10: return "flame.fill"
            case .tournamentJoin: return "person.3.fill"
            case .tournamentWin: return "trophy.circle.fill"
            case .socialMatch: return "person.2.fill"
            case .dailyLogin, .weeklyLogin: return "calendar"
            case .friendAdded: return "person.badge.plus"
            case .messagesSent: return "message.fill"
            case .courtCheckin: return "location.fill"
            case .skillImprovement: return "chart.line.uptrend.xyaxis"
            case .leagueJoin: return "sportscourt.fill"
            case .achievementUnlock: return "star.fill"
            case .missionComplete: return "checkmark.circle.fill"
            case .dailyChallengeComplete: return "checkmark.circle.fill"
            }
        }
    }
    
    func awardXP(_ reward: XPReward, multiplier: Double = 1.0) {
        let xpAmount = Int(Double(reward.rawValue) * multiplier)
        currentXP += xpAmount
        totalXPEarned += xpAmount
        
        // Check for level up
        checkLevelUp()
        
        // Update stats
        updateStats(for: reward, amount: xpAmount)
        
        // Check mission progress
        updateMissionProgress(for: reward)
        
        // Check for new trophies
        checkForNewTrophies()
        
        // Add to pending rewards for UI display
        pendingRewards.append(reward)
        
        // Save progress
        saveUserProgress()
        
        LoggingService.shared.log("Awarded \(xpAmount) XP for \(reward.description)")
        
        // Post notification
        NotificationCenter.default.post(
            name: .xpAwarded,
            object: nil,
            userInfo: ["reward": reward, "amount": xpAmount]
        )
    }
    
    private func checkLevelUp() {
        let newLevel = XPManager.calculateLevel(from: currentXP)
        if newLevel > currentLevel {
            let levelsGained = newLevel - currentLevel
            currentLevel = newLevel
            xpToNextLevel = calculateXPForLevel(currentLevel + 1) - currentXP
            
            // Award level up bonus
            for _ in 0..<levelsGained {
                awardLevelUpRewards()
            }
            
            LoggingService.shared.log("Level up! Now level \(currentLevel)")
            
            NotificationCenter.default.post(
                name: .userLeveledUp,
                object: nil,
                userInfo: ["newLevel": currentLevel, "levelsGained": levelsGained]
            )
        } else {
            xpToNextLevel = calculateXPForLevel(currentLevel + 1) - currentXP
        }
    }
    
    private func awardLevelUpRewards() {
        // Award XP bonus for leveling up
        let bonus = currentLevel * 50
        currentXP += bonus
        totalXPEarned += bonus
        
        // Unlock level-based trophies
        checkLevelBasedTrophies()
    }
    
    static func calculateLevel(from xp: Int) -> Int {
        // Progressive XP curve: Level n requires n^2 * 100 XP
        return max(1, Int(sqrt(Double(xp) / 100)))
    }
    
    func calculateXPForLevel(_ level: Int) -> Int {
        return level * level * 100
    }
    
    func getProgressToNextLevel() -> Double {
        let currentLevelXP = calculateXPForLevel(currentLevel)
        let nextLevelXP = calculateXPForLevel(currentLevel + 1)
        let progressXP = max(0, currentXP - currentLevelXP)
        let requiredXP = max(1, nextLevelXP - currentLevelXP)
        
        let ratio = Double(progressXP) / Double(requiredXP)
        return min(max(ratio, 0), 1)
    }
    
    // MARK: - Mission System
    
    func generateDailyMissions() {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Clear old missions
        activeMissions.removeAll { mission in
            mission.type.isDaily && !Calendar.current.isDate(mission.createdAt, inSameDayAs: today)
        }
        
        // Generate new daily missions if needed
        let dailyMissions = activeMissions.filter { $0.type.isDaily }
        if dailyMissions.count < 3 {
            let newMissions = MissionType.dailyMissions.shuffled().prefix(3 - dailyMissions.count)
            for missionType in newMissions {
                let mission = Mission(type: missionType, createdAt: today)
                activeMissions.append(mission)
            }
        }
        
        // Generate weekly missions
        generateWeeklyMissions()
        
        // Generate achievement missions
        generateAchievementMissions()
    }
    
    private func generateWeeklyMissions() {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        
        let weeklyMissions = activeMissions.filter { $0.type.isWeekly }
        if weeklyMissions.isEmpty {
            let newMissions = MissionType.weeklyMissions.shuffled().prefix(2)
            for missionType in newMissions {
                let mission = Mission(type: missionType, createdAt: weekStart)
                activeMissions.append(mission)
            }
        }
    }
    
    private func generateAchievementMissions() {
        let achievementMissions = activeMissions.filter { $0.type.isAchievement }
        if achievementMissions.count < 2 {
            let newMissions = MissionType.achievementMissions.shuffled().prefix(2 - achievementMissions.count)
            for missionType in newMissions {
                let mission = Mission(type: missionType, createdAt: Date())
                activeMissions.append(mission)
            }
        }
    }
    
    func updateMissionProgress(for reward: XPReward) {
        for i in 0..<activeMissions.count where !activeMissions[i].isCompleted {
            let oldProgress = activeMissions[i].progress
            activeMissions[i].updateProgress(for: reward)
            
            if activeMissions[i].isCompleted && oldProgress < activeMissions[i].targetValue {
                completeMission(activeMissions[i])
            }
        }
    }
    
    private func completeMission(_ mission: Mission) {
        // Find the mission in activeMissions and update it
        if let index = activeMissions.firstIndex(where: { $0.id == mission.id }) {
            activeMissions[index].completedAt = Date()
            completedMissions.append(activeMissions[index])
        }
        
        // Award mission completion XP
        awardXP(.missionComplete)
        
        // Award mission-specific XP bonus
        let bonusXP = mission.type.xpReward
        currentXP += bonusXP
        totalXPEarned += bonusXP
        
        LoggingService.shared.log("Mission completed: \(mission.type.title)")
        
        NotificationCenter.default.post(
            name: .missionCompleted,
            object: mission,
            userInfo: ["xpReward": bonusXP]
        )
        
        // Check for trophy unlocks
        checkMissionBasedTrophies()
    }
    
    // MARK: - Trophy System
    
    private func checkForNewTrophies() {
        checkMatchBasedTrophies()
        checkSocialTrophies()
        checkLevelBasedTrophies()
        checkMissionBasedTrophies()
        checkSpecialTrophies()
    }
    
    private func checkMatchBasedTrophies() {
        let matchTrophies: [(TrophyType, () -> Bool)] = [
            (.firstWin, { self.lifetimeStats.matchesWon >= 1 }),
            (.winStreak5, { self.lifetimeStats.longestWinStreak >= 5 }),
            (.winStreak10, { self.lifetimeStats.longestWinStreak >= 10 }),
            (.perfectionist, { self.lifetimeStats.perfectGames >= 1 }),
            (.centurion, { self.lifetimeStats.matchesPlayed >= 100 }),
            (.champion, { self.lifetimeStats.tournamentsWon >= 1 }),
            (.grandSlam, { self.lifetimeStats.tournamentsWon >= 5 }),
        ]
        
        for (trophyType, condition) in matchTrophies {
            if condition() && !hasTrophy(trophyType) {
                unlockTrophy(trophyType)
            }
        }
    }
    
    private func checkSocialTrophies() {
        let socialTrophies: [(TrophyType, () -> Bool)] = [
            (.socialButterfly, { self.lifetimeStats.friendsAdded >= 10 }),
            (.messenger, { self.lifetimeStats.messagesSent >= 100 }),
            (.teamPlayer, { self.lifetimeStats.socialMatches >= 25 }),
        ]
        
        for (trophyType, condition) in socialTrophies {
            if condition() && !hasTrophy(trophyType) {
                unlockTrophy(trophyType)
            }
        }
    }
    
    private func checkLevelBasedTrophies() {
        let levelTrophies: [(TrophyType, Int)] = [
            (.rookie, 5),
            (.veteran, 10),
            (.expert, 25),
            (.master, 50),
            (.legend, 100)
        ]
        
        for (trophyType, requiredLevel) in levelTrophies {
            if currentLevel >= requiredLevel && !hasTrophy(trophyType) {
                unlockTrophy(trophyType)
            }
        }
    }
    
    private func checkMissionBasedTrophies() {
        let missionTrophies: [(TrophyType, () -> Bool)] = [
            (.taskmaster, { self.completedMissions.count >= 50 }),
            (.dedicated, { self.lifetimeStats.dailyLogins >= 30 }),
            (.consistent, { self.lifetimeStats.dailyLogins >= 100 }),
        ]
        
        for (trophyType, condition) in missionTrophies {
            if condition() && !hasTrophy(trophyType) {
                unlockTrophy(trophyType)
            }
        }
    }
    
    private func checkSpecialTrophies() {
        // Special condition trophies
        if totalXPEarned >= 10000 && !hasTrophy(.xpCollector) {
            unlockTrophy(.xpCollector)
        }
        
        if lifetimeStats.courtsVisited >= 10 && !hasTrophy(.explorer) {
            unlockTrophy(.explorer)
        }
    }
    
    private func hasTrophy(_ type: TrophyType) -> Bool {
        return unlockedTrophies.contains { $0.type == type }
    }
    
    private func unlockTrophy(_ type: TrophyType) {
        let trophy = Trophy(type: type, unlockedAt: Date())
        unlockedTrophies.append(trophy)
        
        // Award trophy XP
        awardXP(.achievementUnlock)
        
        LoggingService.shared.log("Trophy unlocked: \(type.title)")
        
        NotificationCenter.default.post(
            name: .trophyUnlocked,
            object: trophy,
            userInfo: ["type": type]
        )
    }
    
    // MARK: - Stats Tracking
    
    private func updateStats(for reward: XPReward, amount: Int) {
        dailyStats.xpEarned += amount
        weeklyStats.xpEarned += amount
        lifetimeStats.totalXP += amount
        
        switch reward {
        case .matchWin:
            dailyStats.matchesWon += 1
            weeklyStats.matchesWon += 1
            lifetimeStats.matchesWon += 1
            lifetimeStats.matchesPlayed += 1
            
        case .matchLoss:
            lifetimeStats.matchesPlayed += 1
            
        case .perfectGame:
            lifetimeStats.perfectGames += 1
            
        case .tournamentWin:
            lifetimeStats.tournamentsWon += 1
            
        case .friendAdded:
            lifetimeStats.friendsAdded += 1
            
        case .messagesSent:
            dailyStats.messagesSent += 1
            lifetimeStats.messagesSent += 1
            
        case .socialMatch:
            lifetimeStats.socialMatches += 1
            
        case .dailyLogin:
            lifetimeStats.dailyLogins += 1
            
        case .courtCheckin:
            lifetimeStats.courtsVisited += 1
            
        default:
            break
        }
    }
    
    // MARK: - Public Interface
    
    func trackMatchResult(won: Bool, isPerfectGame: Bool = false, isSocialMatch: Bool = false) {
        if won {
            awardXP(.matchWin)
            if isPerfectGame {
                awardXP(.perfectGame)
            }
        } else {
            awardXP(.matchLoss)
        }
        
        if isSocialMatch {
            awardXP(.socialMatch)
        }
        
        // Update win streak
        if won {
            lifetimeStats.currentWinStreak += 1
            lifetimeStats.longestWinStreak = max(lifetimeStats.longestWinStreak, lifetimeStats.currentWinStreak)
            
            // Check win streak rewards
            switch lifetimeStats.currentWinStreak {
            case 3: awardXP(.winStreak3)
            case 5: awardXP(.winStreak5)
            case 10: awardXP(.winStreak10)
            default: break
            }
        } else {
            lifetimeStats.currentWinStreak = 0
        }
    }
    
    func trackDailyLogin() {
        let today = Calendar.current.startOfDay(for: Date())
        if !Calendar.current.isDate(dailyStats.lastLogin, inSameDayAs: today) {
            awardXP(.dailyLogin)
            dailyStats.lastLogin = today
            
            // Check for weekly login bonus
            let daysSinceWeeklyLogin = Calendar.current.dateComponents([.day], from: weeklyStats.lastWeeklyLogin, to: today).day ?? 0
            if daysSinceWeeklyLogin >= 7 {
                awardXP(.weeklyLogin)
                weeklyStats.lastWeeklyLogin = today
            }
        }
    }
    
    func trackTournamentJoin() {
        awardXP(.tournamentJoin)
    }
    
    func trackTournamentWin() {
        awardXP(.tournamentWin)
    }
    
    func trackFriendAdded() {
        awardXP(.friendAdded)
    }
    
    func trackMessageSent() {
        awardXP(.messagesSent)
    }
    
    func trackCourtCheckin() {
        awardXP(.courtCheckin)
    }
    
    func trackProfileComplete() {
        awardXP(.profileComplete)
    }
    
    func trackSkillImprovement() {
        awardXP(.skillImprovement)
    }
    
    func trackLeagueJoin() {
        awardXP(.leagueJoin)
    }
    
    func trackDailyChallengeComplete() {
        awardXP(.dailyChallengeComplete)
    }
    
    // MARK: - Data Persistence
    
    private func saveUserProgress() {
        UserDefaults.standard.set(currentXP, forKey: "currentXP")
        UserDefaults.standard.set(currentLevel, forKey: "currentLevel")
        UserDefaults.standard.set(totalXPEarned, forKey: "totalXPEarned")
        
        // Save missions and trophies
        if let missionsData = try? JSONEncoder().encode(activeMissions) {
            UserDefaults.standard.set(missionsData, forKey: "activeMissions")
        }
        
        if let trophiesData = try? JSONEncoder().encode(unlockedTrophies) {
            UserDefaults.standard.set(trophiesData, forKey: "unlockedTrophies")
        }
        
        // Save stats
        if let dailyStatsData = try? JSONEncoder().encode(dailyStats) {
            UserDefaults.standard.set(dailyStatsData, forKey: "dailyStats")
        }
        
        if let weeklyStatsData = try? JSONEncoder().encode(weeklyStats) {
            UserDefaults.standard.set(weeklyStatsData, forKey: "weeklyStats")
        }
        
        if let lifetimeStatsData = try? JSONEncoder().encode(lifetimeStats) {
            UserDefaults.standard.set(lifetimeStatsData, forKey: "lifetimeStats")
        }
    }
    
    private func loadUserProgress() {
        currentXP = UserDefaults.standard.integer(forKey: "currentXP")
        currentLevel = max(1, UserDefaults.standard.integer(forKey: "currentLevel"))
        totalXPEarned = UserDefaults.standard.integer(forKey: "totalXPEarned")
        
        // Load missions
        if let missionsData = UserDefaults.standard.data(forKey: "activeMissions"),
           let missions = try? JSONDecoder().decode([Mission].self, from: missionsData) {
            activeMissions = missions
        }
        
        // Load trophies
        if let trophiesData = UserDefaults.standard.data(forKey: "unlockedTrophies"),
           let trophies = try? JSONDecoder().decode([Trophy].self, from: trophiesData) {
            unlockedTrophies = trophies
        }
        
        // Load stats
        if let dailyStatsData = UserDefaults.standard.data(forKey: "dailyStats"),
           let stats = try? JSONDecoder().decode(DailyStats.self, from: dailyStatsData) {
            dailyStats = stats
        }
        
        if let weeklyStatsData = UserDefaults.standard.data(forKey: "weeklyStats"),
           let stats = try? JSONDecoder().decode(WeeklyStats.self, from: weeklyStatsData) {
            weeklyStats = stats
        }
        
        if let lifetimeStatsData = UserDefaults.standard.data(forKey: "lifetimeStats"),
           let stats = try? JSONDecoder().decode(LifetimeStats.self, from: lifetimeStatsData) {
            lifetimeStats = stats
        }
        
        // Recalculate level if needed
        if currentXP > 0 {
            checkLevelUp()
        }
    }
    
    // MARK: - Utility Methods
    
    func clearPendingRewards() {
        pendingRewards.removeAll()
    }
    
    func getMissionsForDisplay() -> [Mission] {
        return activeMissions.filter { !$0.isCompleted }
    }
    
    func getRecentTrophies(limit: Int = 5) -> [Trophy] {
        return Array(unlockedTrophies.sorted { $0.unlockedAt > $1.unlockedAt }.prefix(limit))
    }
    
    func getTrophyProgress() -> (unlocked: Int, total: Int) {
        return (unlockedTrophies.count, TrophyType.allCases.count)
    }
    
    // MARK: - Static Helper Methods
    
    static func xpProgressInCurrentLevel(currentXP: Int) -> (current: Int, required: Int, progress: Double) {
        let level = calculateLevel(from: currentXP)
        let xpForCurrentLevel = xpRequiredForLevel(level)
        let xpForNextLevel = xpRequiredForLevel(level + 1)
        let xpInCurrentLevel = currentXP - xpForCurrentLevel
        let xpNeededForNextLevel = xpForNextLevel - xpForCurrentLevel
        let progress = Double(xpInCurrentLevel) / Double(xpNeededForNextLevel)
        
        return (current: xpInCurrentLevel, required: xpNeededForNextLevel, progress: progress)
    }
    
    static func xpRequiredForLevel(_ level: Int) -> Int {
        if level <= 1 { return 0 }
        return (level - 1) * (level - 1) * 100
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let xpAwarded = Notification.Name("xpAwarded")
    static let userLeveledUp = Notification.Name("userLeveledUp")
    static let missionCompleted = Notification.Name("missionCompleted")
    static let trophyUnlocked = Notification.Name("trophyUnlocked")
    
    // Notification manager notifications
    static let showXPNotification = Notification.Name("showXPNotification")
    static let showLevelUpNotification = Notification.Name("showLevelUpNotification")
    static let showMissionCompleteNotification = Notification.Name("showMissionCompleteNotification")
}

// MARK: - Daily Challenge System

enum DailyChallengeType: String, CaseIterable, Codable {
    case playMatch = "Play a Match"
    case winMatch = "Win a Game"
    case socialPlayer = "Social Player"
    case perfectGame = "Perfect Game"
    case winStreak = "Win Streak"
    
    var title: String {
        return self.rawValue
    }
    
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
    
    var color: Color {
        switch self {
        case .playMatch: return .blue
        case .winMatch: return .green
        case .socialPlayer: return .purple
        case .perfectGame: return .orange
        case .winStreak: return .red
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
        self.xpReward = Self.calculateDailyChallengeXP(challengeType: type)
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

extension DailyChallenge {
    static func calculateDailyChallengeXP(challengeType: DailyChallengeType) -> Int {
        switch challengeType {
        case .playMatch: return 50
        case .winMatch: return 75
        case .socialPlayer: return 100
        case .perfectGame: return 200
        case .winStreak: return 150
        }
    }
} 