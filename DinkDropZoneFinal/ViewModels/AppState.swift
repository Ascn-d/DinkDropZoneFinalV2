import Observation
import SwiftData
import Foundation

@Observable
@MainActor
final class AppState {
    
    // MARK: - Core Properties
    
    var currentUser: User? = nil
    var currentMatch: Match? = nil

    // Authentication
    var authService: AuthService? = nil
    
    // Services
    private var modelContext: ModelContext?
    private var matchmakingService: MatchmakingService?
    private var statisticsService: StatisticsService?
    private var leagueService: LeagueService?
    private var networkService: NetworkService?
    
    // MARK: - User Management
    
    var isAuthenticated: Bool {
        return currentUser != nil
    }
    
    var userLevel: Int {
        guard let user = currentUser else { return 1 }
        return XPManager.calculateLevel(from: user.xp)
    }
    
    var userXPProgress: (current: Int, required: Int, progress: Double) {
        guard let user = currentUser else { return (0, 100, 0) }
        return XPManager.xpProgressInCurrentLevel(currentXP: user.xp)
    }
    
    // MARK: - First-Run Profile Wizard
    var needsProfileSetup: Bool {
        guard let user = currentUser else { return false }
        return user.displayName.isEmpty || user.location.isEmpty
    }
    
    func markProfileComplete() {
        // Called by ProfileWizard when user finishes.
        // Here we could persist additional flags if desired.
    }
    
    // MARK: - Daily Challenges
    
    var dailyChallenges: [DailyChallenge] = []
    var completedChallengesCount: Int {
        return dailyChallenges.filter { $0.isCompleted }.count
    }
    
    // MARK: - Queue & Matchmaking
    
    var isInQueue: Bool = false
    var queuePosition: Int = 0
    var estimatedWaitTime: TimeInterval = 0
    var currentQueueType: MatchType?
    var matchProposal: MatchProposal?
    
    // MARK: - Statistics & Performance
    
    var userStats: DetailedUserStats?
    var recentPerformanceInsights: [PerformanceInsightModel] = []
    var eloProgression: [EloDataPoint] = []
    
    // MARK: - Social Features
    
    var onlineUsersCount: Int = 247
    var totalCommunityMembers: Int = 1432
    var nearbyPlayers: [User] = []
    var friendRequests: [AppFriendRequest] = []
    
    // MARK: - Notifications & Updates
    
    var unreadNotifications: [AppNotification] = []
    var hasUnreadMessages: Bool = false
    var hasNewAchievements: Bool = false
    
    // MARK: - Initialization
    
    func initialize(with modelContext: ModelContext) {
        self.modelContext = modelContext
        self.networkService = NetworkService()
        self.matchmakingService = MatchmakingService(modelContext: modelContext)
        self.statisticsService = StatisticsService(modelContext: modelContext)
        self.leagueService = LeagueService(modelContext: modelContext, network: self.networkService)
        
        setupNotificationObservers()
        generateDailyChallenges()
        
        // Simulate some initial data
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - User Actions
    
    func updateUser(_ user: User) {
        currentUser = user
        Task {
            await refreshUserStats()
        }
    }
    
    func awardXP(reward: XPManager.XPReward, context: String = "") async {
        guard let user = currentUser else { return }
        
        let oldLevel = XPManager.calculateLevel(from: user.xp)
        user.xp += reward.rawValue
        let newLevel = XPManager.calculateLevel(from: user.xp)
        let didLevelUp = newLevel > oldLevel
        
        LoggingService.shared.log("User \(user.displayName) gained \(reward.rawValue) XP for \(context.isEmpty ? reward.description : context)")
        
        currentUser = user
        
        if didLevelUp {
            addNotification(AppNotification(
                type: .levelUp,
                title: "Level Up!",
                message: "You reached level \(userLevel)!",
                data: ["level": userLevel]
            ))
        }
        
        // Update daily challenges
        updateDailyChallenges(for: reward)
        await refreshUserStats()
    }
    
    func completeMatch(_ match: Match, result: MatchResult) async {
        guard let user = currentUser else { return }
        
        // Update user stats
        user.totalMatches += 1
        if result.isWin {
            user.wins += 1
            user.winStreak += 1
            user.longestWinStreak = max(user.longestWinStreak, user.winStreak)
        } else {
            user.losses += 1
            user.winStreak = 0
        }
        
        // Update points
        user.totalPointsScored += result.pointsScored
        user.totalPointsConceded += result.pointsConceded
        
        // Update ELO
        let oldElo = user.elo
        user.elo += result.eloChange
        
        // Update monthly stats
        let userMatchResult = UserMatchResult(
            isWin: result.isWin,
            pointsScored: result.pointsScored,
            pointsConceded: result.pointsConceded,
            eloChange: result.eloChange
        )
        user.updateMonthlyStats(for: Date(), matchResult: userMatchResult)
        
        // Check for achievements
        let newAchievements = user.checkForNewAchievements()
        if !newAchievements.isEmpty {
            hasNewAchievements = true
            for achievement in newAchievements {
                addNotification(AppNotification(
                    type: .achievement,
                    title: "Achievement Unlocked!",
                    message: achievement.title,
                    data: ["achievement": achievement]
                ))
            }
        }
        
        currentUser = user
        currentMatch = match
        
        // Award XP based on match result
        if result.isWin {
            await awardXP(reward: .matchWin, context: "Match victory")
            if result.pointsScored == 11 && result.pointsConceded == 0 {
                await awardXP(reward: .perfectGame, context: "Perfect game!")
            }
        } else {
            await awardXP(reward: .matchLoss, context: "Match participation")
        }
        
        // Check for streak bonuses
        if user.winStreak == 3 {
            await awardXP(reward: .winStreak3, context: "3-match win streak")
        } else if user.winStreak == 5 {
            await awardXP(reward: .winStreak5, context: "5-match win streak")
        } else if user.winStreak == 10 {
            await awardXP(reward: .winStreak10, context: "10-match win streak")
        }
        
        await refreshUserStats()
        
        // Add match completion notification
        addNotification(AppNotification(
            type: .matchComplete,
            title: result.isWin ? "Victory!" : "Match Complete",
            message: "ELO: \(oldElo) → \(user.elo) (\(result.eloChange >= 0 ? "+" : "")\(result.eloChange))",
            data: ["match": match, "result": result]
        ))
    }
    
    // MARK: - Queue Management
    
    func joinQueue(matchType: MatchType) async {
        guard let user = currentUser,
              let service = matchmakingService else { return }
        
        isInQueue = true
        currentQueueType = matchType
        
        await service.joinQueue(user: user, matchType: matchType)
        
        // Update queue status
        queuePosition = service.queuePosition
        estimatedWaitTime = service.estimatedWaitTime
        matchProposal = service.matchProposal
    }
    
    func leaveQueue() async {
        guard let service = matchmakingService else { return }
        
        await service.leaveCurrentQueue()
        
        isInQueue = false
        currentQueueType = nil
        queuePosition = 0
        estimatedWaitTime = 0
        matchProposal = nil
    }
    
    // MARK: - Statistics & Analytics
    
    func refreshUserStats() async {
        guard let user = currentUser,
              let service = statisticsService else { return }
        
        userStats = await service.calculateDetailedStats(for: user)
        recentPerformanceInsights = await service.generatePerformanceInsights(for: user)
        eloProgression = await service.calculateEloProgression(for: user, days: 30)
    }
    
    func predictMatchOutcome(against opponent: User) async -> MatchPrediction? {
        guard let user = currentUser,
              let service = statisticsService else { return nil }
        
        return await service.predictMatchOutcome(user: user, opponent: opponent)
    }
    
    // MARK: - Daily Challenges
    
    private func generateDailyChallenges() {
        let today = Date()
        let challengeTypes = DailyChallengeType.allCases.shuffled().prefix(3)
        
        dailyChallenges = challengeTypes.map { type in
            DailyChallenge(type: type, date: today)
        }
    }
    
    private func updateDailyChallenges(for reward: XPManager.XPReward) {
        switch reward {
        case .matchComplete:
            updateChallengeProgress(.playMatch)
        case .matchWin:
            updateChallengeProgress(.winMatch)
        case .perfectGame:
            updateChallengeProgress(.perfectGame)
        case .socialMatch:
            updateChallengeProgress(.socialPlayer)
        default:
            break
        }
    }
    
    private func updateChallengeProgress(_ type: DailyChallengeType) {
        for index in dailyChallenges.indices {
            if dailyChallenges[index].type == type {
                let wasCompleted = dailyChallenges[index].updateProgress()
                if wasCompleted {
                    Task {
                        await awardXP(reward: .dailyChallengeComplete, context: "Daily challenge: \(type.rawValue)")
                    }
                    addNotification(AppNotification(
                        type: .challengeComplete,
                        title: "Challenge Complete!",
                        message: dailyChallenges[index].type.rawValue,
                        data: ["xp": dailyChallenges[index].xpReward]
                    ))
                }
                break
            }
        }
    }
    
    // MARK: - Social Features
    
    func updateOnlineStatus() {
        // Simulate dynamic online user count
        onlineUsersCount = Int.random(in: 200...300)
    }
    
    func loadNearbyPlayers() async {
        // In a real app, this would fetch from location services
        // For now, simulating with sample data
        nearbyPlayers = generateSamplePlayers(count: 8)
    }
    
    // MARK: - Notifications
    
    private func addNotification(_ notification: AppNotification) {
        unreadNotifications.insert(notification, at: 0)
        // Keep only last 20 notifications
        if unreadNotifications.count > 20 {
            unreadNotifications = Array(unreadNotifications.prefix(20))
        }
    }
    
    func markNotificationAsRead(_ notification: AppNotification) {
        unreadNotifications.removeAll { $0.id == notification.id }
    }
    
    func clearAllNotifications() {
        unreadNotifications.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .userLeveledUp,
            object: nil,
            queue: .main
        ) { _ in
            // Handle level up notification
        }
        
        NotificationCenter.default.addObserver(
            forName: .matchCreated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            // Handle match creation
            if let match = notification.object as? Match {
                Task { @MainActor in
                    self?.currentMatch = match
                }
            }
        }
    }
    
    private func loadInitialData() async {
        await loadNearbyPlayers()
        updateOnlineStatus()
        
        if currentUser != nil {
            await refreshUserStats()
        }
    }
    
    private func generateSamplePlayers(count: Int) -> [User] {
        var players: [User] = []
        let names = ["Sarah Chen", "Mike Johnson", "Emma Wilson", "Alex Turner", "Lisa Park", "David Kim", "Rachel Green", "Tom Brown"]
        
        for i in 0..<min(count, names.count) {
            let player = User(
                email: "\(names[i].lowercased().replacingOccurrences(of: " ", with: "."))@example.com",
                password: "password",
                elo: Int.random(in: 800...2000),
                xp: Int.random(in: 100...5000),
                totalMatches: Int.random(in: 5...100),
                wins: Int.random(in: 2...60),
                losses: Int.random(in: 1...40),
                winStreak: Int.random(in: 0...10)
            )
            player.displayName = names[i]
            player.location = ["San Francisco", "Los Angeles", "New York", "Seattle"].randomElement() ?? "San Francisco"
            players.append(player)
        }
        
        return players
    }
    
    // MARK: - Match Proposal Responses
    func respondToMatchProposal(_ response: MatchResponse) async {
        guard let user = currentUser,
              let service = matchmakingService else { return }
        await service.respondToMatchProposal(response: response, for: user)
        // Sync local proposal state with service
        matchProposal = service.matchProposal
    }
    
    func getLeagueService() -> LeagueService? { leagueService }
    
    func getNetworkService() -> NetworkService? { networkService }
}

// MARK: - Supporting Types

struct AppFriendRequest: Identifiable {
    let id: UUID
    let fromUser: User
    let toUser: User
    let createdAt: Date
    var status: AppFriendRequestStatus
    
    init(fromUser: User, toUser: User) {
        self.id = UUID()
        self.fromUser = fromUser
        self.toUser = toUser
        self.createdAt = Date()
        self.status = .pending
    }
}

enum AppFriendRequestStatus {
    case pending, accepted, declined
}

struct AppNotification: Identifiable {
    let id: UUID
    let type: NotificationType
    let title: String
    let message: String
    let createdAt: Date
    let data: [String: Any]
    
    init(type: NotificationType, title: String, message: String, data: [String: Any] = [:]) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.message = message
        self.createdAt = Date()
        self.data = data
    }
}

enum NotificationType {
    case levelUp, achievement, matchComplete, challengeComplete, friendRequest, tournament, general
    
    var icon: String {
        switch self {
        case .levelUp: return "arrow.up.circle.fill"
        case .achievement: return "trophy.fill"
        case .matchComplete: return "gamecontroller.fill"
        case .challengeComplete: return "checkmark.circle.fill"
        case .friendRequest: return "person.badge.plus"
        case .tournament: return "crown.fill"
        case .general: return "bell.fill"
        }
    }
    
    var color: String {
        switch self {
        case .levelUp: return "blue"
        case .achievement: return "purple"
        case .matchComplete: return "green"
        case .challengeComplete: return "orange"
        case .friendRequest: return "blue"
        case .tournament: return "gold"
        case .general: return "gray"
        }
    }
} 