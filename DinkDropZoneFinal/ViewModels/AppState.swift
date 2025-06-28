import SwiftData
import Foundation
import SwiftUI
import FirebaseAuth
import CoreLocation
import Combine

// MARK: - Matchmaking Types

// Use the renamed types from MatchmakingService
typealias QueueEntry = MMQueueEntry
typealias PotentialMatch = MMPotentialMatch
typealias MatchProposal = MMMatchProposal
typealias MatchResponse = MMMatchResponse

@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Core Properties
    
    @Published var currentUser: User? = nil
    @Published var currentMatch: Match? = nil
    @Published var darkModeEnabled: Bool = false
    @Published var currentNotification: UserNotification? = nil

    // Authentication
    var authService: AuthService? = nil
    
    // Services
    private var modelContext: ModelContext?
    private var matchmakingService: MatchmakingService?
    private var statisticsService: StatisticsService?
    private var leagueService: LeagueService?
    private var networkService: NetworkService?
    var locationService: UserLocationService?
    var nearbyPlayersService: NearbyPlayersService?
    var realtimeMatchmakingService: RealtimeMatchmakingService?
    var pushNotificationService: PushNotificationService?
    var alphaTestingService: AlphaTestingService?
    var localMatchmakingService: LocalMatchmakingService?
    var tournamentService: TournamentService?

    // Firestore listener handle
    private var userListenerHandle: FirebaseService.ListenerHandle?

    // Persist Firestore snapshot to SwiftData for offline launch
    private func persistUserToLocal(_ remote: User) {
        guard let context = modelContext else { return }

        let descriptor = FetchDescriptor<User>()
        if let existing = try? context.fetch(descriptor).first(where: { $0.id == remote.id }) {
            // Update fields
            existing.email = remote.email
            existing.displayName = remote.displayName
            existing.bio = remote.bio
            existing.location = remote.location
            existing.skillLevel = remote.skillLevel
            existing.playStyle = remote.playStyle
            existing.favoriteShot = remote.favoriteShot
            existing.availability = remote.availability
            existing.profileImageURL = remote.profileImageURL
            existing.elo = remote.elo
            existing.xp = remote.xp
            existing.totalMatches = remote.totalMatches
            existing.wins = remote.wins
            existing.losses = remote.losses
            existing.winStreak = remote.winStreak
            existing.longestWinStreak = remote.longestWinStreak
            existing.totalPointsScored = remote.totalPointsScored
            existing.totalPointsConceded = remote.totalPointsConceded
            existing.lat = remote.lat
            existing.lon = remote.lon
            existing.coins = remote.coins
            existing.level = remote.level
            existing.lastActive = remote.lastActive
        } else {
            context.insert(remote)
        }
        try? context.save()
    }
    
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
    
    /// Updates the current user instance and persists to local storage
    func updateUser(_ updatedUser: User) {
        currentUser = updatedUser
        persistUserToLocal(updatedUser)
    }
    
    /// Updates the user's profile image using local storage (free tier)
    func updateProfileImage(_ image: UIImage) async throws {
        guard let user = currentUser else { 
            print("AppState: No current user found for profile image update")
            throw FirebaseService.FirebaseError.invalidUser 
        }
        
        print("AppState: Starting local profile image update for user: \(user.id)")
        
        do {
            let updatedUser = try await FirebaseService.shared.updateProfileImageLocal(user, newImage: image)
            print("AppState: Local profile image update successful")
            
            await MainActor.run {
                self.currentUser = updatedUser
                self.persistUserToLocal(updatedUser)
                print("AppState: Current user updated with new profile image URL")
            }
        } catch {
            print("AppState: Local profile image update failed: \(error)")
            throw error
        }
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
    
    @Published var dailyChallenges: [AppDailyChallenge] = []
    var completedChallengesCount: Int {
        return dailyChallenges.filter { $0.isCompleted }.count
    }
    
    // MARK: - Queue & Matchmaking
    
    @Published var isInQueue: Bool = false
    @Published var queuePosition: Int = 0
    @Published var queueCount: Int = 0 // Number of players in queue
    @Published var estimatedWaitTime: TimeInterval = 0
    @Published var currentQueueType: MatchType?
    @Published var matchProposal: MatchProposal?
    @Published var activeMatchSetup: LocalMatchmakingService.LocalMatch?
    
    // MARK: - Statistics & Performance
    
    var userStats: DetailedUserStats?
    var recentPerformanceInsights: [PerformanceInsightModel] = []
    var eloProgression: [EloDataPoint] = []
    
    // MARK: - Recent Matches
    
    var recentMatches: [GameMatch]? = nil
    
    // MARK: - Social Features
    
    var onlineUsersCount: Int = 247
    var totalCommunityMembers: Int = 1432
    var nearbyPlayers: [User] = []
    var friendRequests: [AppFriendRequest] = []
    
    // MARK: - Nearby Players Sheet
    
    var nearbyPlayersSheet: NearbyPlayersSheet? {
        return NearbyPlayersSheet(players: nearbyPlayers)
    }
    
    // MARK: - Notifications & Updates
    
    var unreadNotifications: [AppNotification] = []
    var unreadNotificationCount: Int { unreadNotifications.count }
    var hasUnreadMessages: Bool = false
    var hasNewAchievements: Bool = false
    
    // MARK: - Service Access Methods
    
    func getLeagueService() -> LeagueService? {
        return leagueService
    }
    
    func getNetworkService() -> NetworkService? {
        return networkService
    }
    
    func getTournamentService() -> TournamentService? {
        return tournamentService
    }
    
    // MARK: - Achievement System
    
    @Published var achievementTracker: AdvancedAchievementTracker?
    @Published var achievementNotificationManager: AchievementNotificationManager?
    
    // MARK: - Initialization
    
    func initialize(with modelContext: ModelContext) {
        self.modelContext = modelContext
        self.networkService = NetworkService()
        self.matchmakingService = MatchmakingService(modelContext: modelContext)
        self.statisticsService = StatisticsService(modelContext: modelContext)
        self.leagueService = LeagueService(modelContext: modelContext, network: self.networkService)
        
        // Initialize location services
        self.locationService = UserLocationService()
        self.nearbyPlayersService = NearbyPlayersService(locationService: self.locationService!)
        
        // Initialize real-time services for alpha testing
        self.realtimeMatchmakingService = RealtimeMatchmakingService()
        self.pushNotificationService = PushNotificationService.shared
        self.alphaTestingService = AlphaTestingService.shared
        
        // Initialize local matchmaking for immediate testing
        self.localMatchmakingService = LocalMatchmakingService()
        
        // Initialize tournament service
        self.tournamentService = TournamentService(firebaseService: FirebaseService.shared)
        
        // Initialize achievement system
        self.achievementTracker = AdvancedAchievementTracker()
        self.achievementNotificationManager = AchievementNotificationManager()
        
        setupNotificationObservers()
        generateDailyChallenges()

        // Start observing the authenticated Firebase user, if available
        if let firebaseUser = Auth.auth().currentUser {
            // Try local cache first for instant launch
            if let uidUUID = UUID(uuidString: firebaseUser.uid) {
                let descriptor = FetchDescriptor<User>()
                if let cached = try? modelContext.fetch(descriptor).first(where: { $0.id == uidUUID }) {
                    currentUser = cached
                    
                    // Start alpha testing session
                    alphaTestingService?.startTestingSession(user: cached)
                    alphaTestingService?.setCrashlyticsUserId(firebaseUser.uid, displayName: cached.displayName)
                }
            }
            subscribeToUserUpdates(uid: firebaseUser.uid)
        }

        Task { 
            await loadInitialData()
            await setupPushNotifications()
        }
    }

    private func subscribeToUserUpdates(uid: String) {
        // Tear down previous listener first
        userListenerHandle?.remove()

        userListenerHandle = FirebaseService.shared.observeUser(id: uid) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.currentUser = user
                    self?.persistUserToLocal(user)
                case .failure(let error):
                    LoggingService.shared.logError(error, context: "User listener")
                }
            }
        }
    }
    
    // MARK: - User Actions
    
    /// Updates the current user with new data and syncs to Firebase
    func updateUserProfile(_ updatedUser: User) {
        currentUser = updatedUser
        Task {
            // Save to remote if available
            try? await FirebaseService.shared.updateUser(updatedUser)
            // Cache locally
            await MainActor.run {
                self.persistUserToLocal(updatedUser)
            }
            await refreshUserStats()
            
            // Check if profile is complete and award XP if needed
            await checkProfileCompletionAndAwardXP(updatedUser)
        }
    }
    
    /// Checks if the user profile is complete and awards XP if conditions are met
    func checkProfileCompletionAndAwardXP(_ user: User) async {
        // Only give profile completion XP once if profile is fully filled out
        let isProfileComplete = !user.displayName.isEmpty && 
                                !user.bio.isEmpty && 
                                !user.location.isEmpty && 
                                user.profileImageURL != nil
        
        if isProfileComplete && !(user.achievements.contains { $0.title == "Profile Complete" }) {
            LoggingService.shared.log("Profile complete, awarding XP")
            await awardXP(reward: .profileComplete, context: "Profile completion")
            
            // Add a notification for the user
            addNotification(AppNotification(
                type: .achievement,
                title: "Profile Complete!",
                message: "Your profile is now complete! You've earned XP for filling in all your details.",
                data: ["xp": XPManager.XPReward.profileComplete.rawValue]
            ))
            
            // Trigger XP notification
            NotificationCenter.default.post(
                name: .xpAwarded,
                object: nil,
                userInfo: [
                    "reward": XPManager.XPReward.profileComplete,
                    "amount": XPManager.XPReward.profileComplete.rawValue
                ]
            )
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
    
    func completeMatch(_ match: GameMatch, result: DinkDropZoneFinal.MatchResult) async {
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
        _ = user.elo
        user.elo += result.eloChange
        
        // Update monthly stats
        let userMatchResult = UserGameResult(
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
        
        // Update achievement progress
        achievementTracker?.updateProgress(
            matchesPlayed: user.totalMatches,
            matchesWon: user.wins,
            winStreak: user.winStreak,
            perfectGames: 0, // Would need to track perfect games
            pointsScored: user.totalPointsScored,
            level: userLevel,
            eloRating: user.elo
        )
        
        // Save to Firebase
        do {
            try await FirebaseService.shared.updateUser(user)
            
            // Save statistics if available
            if let stats = userStats {
                try await FirebaseService.shared.saveUserStatistics(stats, for: user.id.uuidString)
            }
        } catch {
            print("Failed to save match completion to Firebase: \(error)")
        }
        
        // Update the user locally
        updateUser(user)
        
        // Fetch recent matches
        await loadRecentMatches()
    }
    
    // MARK: - Data Loading
    
    private func loadInitialData() async {
        await loadRecentMatches()
        await loadUserStatistics()
        await loadNotifications()
        await loadFriends()
        await loadNearbyPlayers()
        await loadLeaderboard()
        await loadAchievements()
        await loadRealTournaments()
    }
    
    private func loadRealTournaments() async {
        guard let tournamentService = tournamentService else { return }
        
        do {
            // Load real tournaments from Firebase
            try await tournamentService.loadTournamentsFromFirebase()
            LoggingService.shared.log("Loaded real tournaments from Firebase")
        } catch {
            LoggingService.shared.log("Failed to load tournaments: \(error)")
        }
    }
    
    func loadRecentMatches() async {
        guard let userId = currentUser?.id.uuidString else { return }
        
        do {
            let matches = try await FirebaseService.shared.getRecentMatches(for: userId, limit: 10)
            await MainActor.run {
                self.recentMatches = matches
            }
        } catch {
            print("Failed to load recent matches: \(error)")
        }
    }
    
    func loadUserStatistics() async {
        guard let userId = currentUser?.id.uuidString else { return }
        
        do {
            let stats = try await FirebaseService.shared.loadUserStatistics(for: userId)
            await MainActor.run {
                self.userStats = stats
            }
        } catch {
            print("Failed to load user statistics: \(error)")
        }
    }
    
    func loadNotifications() async {
        guard let userId = currentUser?.id.uuidString else { return }
        
        do {
            let notifications = try await FirebaseService.shared.getUnreadNotifications(for: userId)
            await MainActor.run {
                self.unreadNotifications = notifications
            }
        } catch {
            print("Failed to load notifications: \(error)")
        }
    }
    
    func loadFriends() async {
        guard let userId = currentUser?.id.uuidString else { return }
        
        do {
            let _ = try await FirebaseService.shared.getFriends(for: userId)
            await MainActor.run {
                // Store friends in a way that can be accessed by the UI
                // For now, we'll keep the existing structure
            }
        } catch {
            print("Failed to load friends: \(error)")
        }
    }
    
    func loadNearbyPlayers() async {
        // If location permission is granted, start location services
        if let locationService = locationService, locationService.authorizationStatus == .authorizedWhenInUse || locationService.authorizationStatus == .authorizedAlways {
            locationService.request()
            
            // If we have a location, fetch nearby players
            if let location = locationService.currentLocation {
                do {
                    let nearby = try await FirebaseService.shared.fetchNearbyPlayers(center: location.coordinate, radiusKm: 10.0)
                    await MainActor.run {
                        self.nearbyPlayers = nearby
                    }
                } catch {
                    print("Failed to load nearby players: \(error)")
                }
            }
        }
    }
    
    func loadLeaderboard() async {
        do {
            let leaderboard = try await FirebaseService.shared.getGlobalLeaderboard(limit: 50)
            await MainActor.run {
                // Store leaderboard data - could add a leaderboard property to AppState
                print("Loaded \(leaderboard.count) players from leaderboard")
            }
        } catch {
            print("Failed to load leaderboard: \(error)")
        }
    }
    
    func loadAchievements() async {
        // Achievements are loaded by the AdvancedAchievementTracker
        await achievementTracker?.loadAchievementsFromFirebase()
    }
    
    func refreshUserStats() async {
        guard let user = currentUser else { return }
        
        // In a real app, we'd fetch this from a service
        // For now, just use the user's current stats
        userStats = DetailedUserStats(
            totalMatches: user.totalMatches,
            wins: user.wins,
            losses: user.losses,
            winRate: user.winRate,
            elo: user.elo,
            winStreak: user.winStreak,
            longestWinStreak: user.longestWinStreak,
            averagePointsScored: Double(user.totalPointsScored) / max(1, Double(user.totalMatches)),
            averagePointsConceded: Double(user.totalPointsConceded) / max(1, Double(user.totalMatches)),
            pointsDifferential: user.pointsDifferential
        )
    }
    
    func fetchRecentMatches() async {
        guard let _ = currentUser else { return }
        
        // In a real app, we'd fetch this from a service
        // For now, generate sample data based on the user's stats
        var matches: [GameMatch] = []
        
        // Generate some sample matches
        let calendar = Calendar.current
        let today = Date()
        
        // Create 5 sample matches over the past week
        for _ in 0..<5 {
            let daysAgo = Int.random(in: 0...7)
            let matchDate = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            
            let isWin = Bool.random()
            let playerScore = isWin ? Int.random(in: 11...15) : Int.random(in: 7...10)
            let opponentScore = isWin ? Int.random(in: 7...10) : 11
            
            let eloChange = isWin ? "+\(Int.random(in: 8...15))" : "-\(Int.random(in: 5...12))"
            
            let opponentNames = ["Alex", "Emma", "Michael", "Sarah", "James", "Olivia", "William", "Sophia"]
            let opponentName = "\(opponentNames.randomElement()!) \(String(UnicodeScalar(UInt8(65 + Int.random(in: 0...25)))))."
            
            let match = GameMatch(
                opponentName: opponentName,
                result: isWin ? "Win" : "Loss",
                score: "\(playerScore)-\(opponentScore)",
                eloChange: eloChange,
                date: matchDate
            )
            
            matches.append(match)
        }
        
        // Sort by date (newest first)
        matches.sort { $0.date > $1.date }
        
        recentMatches = matches
    }
    
    // MARK: - Notifications
    
    private func setupNotificationObservers() {
        // Listen for notifications that might require UI updates
    }
    
    func markNotificationAsRead(_ notification: AppNotification) {
        if let index = unreadNotifications.firstIndex(where: { $0.id == notification.id }) {
            unreadNotifications.remove(at: index)
        }
    }
    
    func markAllNotificationsAsRead() {
        unreadNotifications.removeAll()
    }
    
    // Function to push a notification to the user
    func pushNotification(_ notification: AppNotification) {
        addNotification(notification)
        // In a real app, we might also trigger a UI notification
    }
    
    // MARK: - Match Proposal
    
    enum MatchProposalResponse {
        case accepted
        case declined
    }
    
    func respondToMatchProposal(_ response: MatchProposalResponse) async {
        guard let proposal = matchProposal else { return }
        
        switch response {
        case .accepted:
            // In a real app, we'd send the response to the server
            // For now, just simulate a match creation
            LoggingService.shared.log("Accepted match proposal \(proposal.id)")
            
            // Create a match with the first opponent
            if let opponent = proposal.potentialMatch.players.first(where: { $0.user.id != currentUser?.id })?.user {
                let isWin = Bool.random()
                let playerScore = isWin ? 11 : Int.random(in: 7...10)
                let opponentScore = isWin ? Int.random(in: 5...9) : 11
                let eloChange = isWin ? Int.random(in: 8...15) : -Int.random(in: 5...12)
                
                // Create match result
                let result: MatchResult
                if isWin {
                    result = .win(pointsScored: playerScore, pointsConceded: opponentScore, eloChange: eloChange)
                } else {
                    result = .loss(pointsScored: playerScore, pointsConceded: opponentScore, eloChange: eloChange)
                }
                
                // Create match
                let match = GameMatch(
                    opponentName: opponent.displayName.isEmpty ? opponent.email : opponent.displayName,
                    result: isWin ? "Win" : "Loss",
                    score: "\(playerScore)-\(opponentScore)",
                    eloChange: isWin ? "+\(eloChange)" : "\(eloChange)",
                    date: Date()
                )
                
                // Complete match
                await completeMatch(match, result: result)
            }
            
        case .declined:
            // In a real app, we'd send the response to the server
            LoggingService.shared.log("Declined match proposal \(proposal.id)")
        }
        
        // Clear the proposal
        matchProposal = nil
    }
    
    // MARK: - Daily Challenges
    
    private func generateDailyChallenges() {
        // In a real app, we'd fetch these from a service
        // For now, generate some sample challenges
        dailyChallenges = [
            AppDailyChallenge(
                type: .playMatches,
                progress: Int.random(in: 0...3),
                isCompleted: Bool.random(),
                xpReward: 50
            ),
            AppDailyChallenge(
                type: .winMatches,
                progress: Int.random(in: 0...2),
                isCompleted: Bool.random(),
                xpReward: 75
            ),
            AppDailyChallenge(
                type: .scorePoints,
                progress: Int.random(in: 0...20),
                isCompleted: Bool.random(),
                xpReward: 60
            )
        ]
    }
    
    private func updateDailyChallenges(for reward: XPManager.XPReward) {
        // In a real app, we'd update challenges based on the reward type
        // For now, just randomly update progress
        for i in 0..<dailyChallenges.count {
            if !dailyChallenges[i].isCompleted && Bool.random() {
                dailyChallenges[i].progress += 1
                if dailyChallenges[i].progress >= dailyChallenges[i].type.targetValue {
                    dailyChallenges[i].isCompleted = true
                    
                    // Add notification
                    addNotification(AppNotification(
                        type: .challenge,
                        title: "Challenge Completed!",
                        message: "You completed the \(dailyChallenges[i].type.title) challenge",
                        data: ["xp": dailyChallenges[i].xpReward]
                    ))
                }
            }
        }
    }
    
    // MARK: - Queue Management
    
    func refreshQueue() {
        // Simulate queue data refresh
        queueCount = Int.random(in: 0...25)
        LoggingService.shared.log("Queue refreshed: \(queueCount) players in queue")
    }
    
    func joinQueue(type: MatchType = .competitive) {
        isInQueue = true
        currentQueueType = type
        queuePosition = Int.random(in: 1...10)
        estimatedWaitTime = TimeInterval(queuePosition * 30) // 30 seconds per position
        
        addNotification(AppNotification(
            type: .match,
            title: "Joined Queue",
            message: "Looking for a match... Position: \(queuePosition)",
            data: ["queueType": type.rawValue]
        ))
        
        LoggingService.shared.log("User joined \(type.rawValue) queue at position \(queuePosition)")
    }
    
    func leaveQueue() {
        isInQueue = false
        currentQueueType = nil
        queuePosition = 0
        estimatedWaitTime = 0
        
        addNotification(AppNotification(
            type: .system,
            title: "Left Queue",
            message: "You've left the matchmaking queue",
            data: [:]
        ))
        
        LoggingService.shared.log("User left queue")
    }
    
    // MARK: - Leaderboard Management
    
    func refreshLeaderboard() {
        LoggingService.shared.log("Leaderboard refreshed")
        // In a real app, this would fetch fresh leaderboard data
    }
    
    // MARK: - Tournament Management
    
    func refreshTournaments() {
        LoggingService.shared.log("Tournaments refreshed")
        // Load real tournaments from Firebase
        Task {
            await loadAvailableTournaments()
        }
    }
    
    func loadAvailableTournaments() async {
        guard let tournamentService = tournamentService else { return }
        
        do {
            let tournaments = try await tournamentService.firebaseService.getAllTournaments()
            await MainActor.run {
                // Store tournaments in AppState if needed
                LoggingService.shared.log("Loaded \(tournaments.count) real tournaments from Firebase")
            }
        } catch {
            LoggingService.shared.log("Failed to load tournaments: \(error)")
        }
    }
    
    // MARK: - Notification Management
    
    func markNotificationsAsRead() {
        unreadNotifications.removeAll()
        LoggingService.shared.log("Notifications marked as read")
    }
    
    func addNotification(_ notification: AppNotification) {
        unreadNotifications.append(notification)
        currentNotification = UserNotification(
            id: notification.id,
            title: notification.title,
            message: notification.message,
            type: .system, // Map from AppNotification.NotificationType to UserNotification type
            date: notification.timestamp
        )
        
        // Auto-dismiss after duration
        Task {
            try? await Task.sleep(nanoseconds: UInt64(notification.duration * 1_000_000_000))
            await MainActor.run {
                if currentNotification?.id == notification.id {
                    currentNotification = nil
                }
            }
        }
    }
    
    // MARK: - Alpha Testing Setup
    
    func setupAlphaTesting() async {
        guard let user = currentUser else { return }
        
        // Start alpha testing session
        alphaTestingService?.startTestingSession(user: user)
        
        if let uid = Auth.auth().currentUser?.uid {
            alphaTestingService?.setCrashlyticsUserId(uid, displayName: user.displayName)
        }
        
        // Setup push notifications
        await setupPushNotifications()
        
        // Enhanced monitoring for alpha is enabled by default
        
        LoggingService.shared.log("Alpha testing setup completed for user: \(user.displayName)")
    }
    
    private func setupPushNotifications() async {
        guard let pushService = pushNotificationService else { return }
        
        // Request permissions
        do {
            try await pushService.requestPermissions()
            LoggingService.shared.log("Push notifications enabled for alpha testing")
        } catch {
            LoggingService.shared.log("Failed to enable push notifications: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Real-time Matchmaking Integration
    
    func joinRealtimeQueue(matchType: MatchType) async throws {
        guard let user = currentUser,
              let realtimeService = realtimeMatchmakingService else {
            throw MatchmakingError.notAuthenticated
        }
        
        // Record matchmaking attempt for analytics
        alphaTestingService?.recordUserAction(
            action: "join_realtime_queue", 
            parameters: ["matchType": matchType.rawValue]
        )
        
        try await realtimeService.joinQueue(userId: user.id.uuidString, matchType: matchType)
        
        // Update local state
        isInQueue = true
        currentQueueType = matchType
        
        LoggingService.shared.log("User joined real-time matchmaking queue: \(matchType.rawValue)")
    }
    
    func leaveRealtimeQueue() async throws {
        guard let realtimeService = realtimeMatchmakingService else { return }
        
        try await realtimeService.leaveQueue()
        
        // Update local state
        isInQueue = false
        currentQueueType = nil
        queuePosition = 0
        estimatedWaitTime = 0
        
        LoggingService.shared.log("User left real-time matchmaking queue")
    }
    
    func respondToRealtimeMatchProposal(_ response: String) async throws {
        guard let realtimeService = realtimeMatchmakingService else {
            throw MatchmakingError.noActiveProposal
        }
        
        // Record response for analytics
        alphaTestingService?.recordUserAction(
            action: "match_proposal_response", 
            parameters: ["response": response]
        )
        
        try await realtimeService.respondToProposal(response)
        
        LoggingService.shared.log("User responded to match proposal: \(response)")
    }
    
    // MARK: - Local Matchmaking for Testing
    
    /// Start local matchmaking (for immediate testing without Firebase)
    func startLocalMatchmaking(matchType: MatchType) async throws {
        guard let user = currentUser,
              let localService = localMatchmakingService else {
            throw MatchmakingError.notAuthenticated
        }
        
        try await localService.startMatchmaking(user: user, matchType: matchType)
        
        // Update local state to match the local service
        isInQueue = localService.isInQueue
        queuePosition = localService.queuePosition
        estimatedWaitTime = localService.estimatedWaitTime
        currentQueueType = matchType
        
        LoggingService.shared.log("Started local matchmaking for \(matchType.rawValue)")
    }
    
    /// Stop local matchmaking
    func stopLocalMatchmaking() {
        localMatchmakingService?.stopMatchmaking()
        
        // Update local state
        isInQueue = false
        currentQueueType = nil
        queuePosition = 0
        estimatedWaitTime = 0
        
        LoggingService.shared.log("Stopped local matchmaking")
    }
    
    /// Propose match to a nearby player (local)
    func proposeLocalMatch(to player: LocalMatchmakingService.NearbyPlayer) async throws {
        guard let localService = localMatchmakingService else {
            throw MatchmakingError.notAuthenticated
        }
        
        try await localService.proposeMatch(to: player)
        LoggingService.shared.log("Proposed local match to \(player.displayName)")
    }
    
    /// Respond to local match proposal
    func respondToLocalProposal(accept: Bool) async throws {
        guard let localService = localMatchmakingService else {
            throw MatchmakingError.noActiveQueue
        }
        
        try await localService.respondToProposal(accept: accept)
        
        if accept {
            // Update state for accepted match
            isInQueue = false
            LoggingService.shared.log("Accepted local match proposal")
        } else {
            LoggingService.shared.log("Declined local match proposal")
        }
    }
}

// MARK: - Supporting Types

struct DetailedUserStats {
    let totalMatches: Int
    let wins: Int
    let losses: Int
    let winRate: Double
    let elo: Int
    let winStreak: Int
    let longestWinStreak: Int
    let averagePointsScored: Double
    let averagePointsConceded: Double
    let pointsDifferential: Int
}

struct PerformanceInsightModel {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct EloDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let elo: Int
}

struct AppFriendRequest: Identifiable {
    let id = UUID()
    let user: User
    let message: String
    let date: Date
}

struct AppNotification: Identifiable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date = Date()
    let data: [String: Any]
    let duration: TimeInterval = 4.0
    
    enum NotificationType {
        case match
        case friend
        case achievement
        case levelUp
        case system
        case challenge
        case error
        
        var color: Color {
            switch self {
            case .match: return .blue
            case .friend: return .green
            case .achievement: return .orange
            case .levelUp: return .purple
            case .system: return .gray
            case .challenge: return .indigo
            case .error: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .match: return "gamecontroller.fill"
            case .friend: return "person.fill"
            case .achievement: return "trophy.fill"
            case .levelUp: return "star.fill"
            case .system: return "bell.fill"
            case .challenge: return "checkmark.circle.fill"
            case .error: return "exclamationmark.triangle.fill"
            }
        }
    }
}

struct AppDailyChallenge: Identifiable {
    let id = UUID()
    let type: ChallengeType
    var progress: Int
    var isCompleted: Bool
    let xpReward: Int
    
    enum ChallengeType {
        case playMatches
        case winMatches
        case scorePoints
        case perfectGame
        case addFriend
        case joinTournament
        
        var title: String {
            switch self {
            case .playMatches: return "Play Matches"
            case .winMatches: return "Win Matches"
            case .scorePoints: return "Score Points"
            case .perfectGame: return "Perfect Game"
            case .addFriend: return "Add a Friend"
            case .joinTournament: return "Join Tournament"
            }
        }
        
        var description: String {
            switch self {
            case .playMatches: return "Play 3 matches today"
            case .winMatches: return "Win 2 matches today"
            case .scorePoints: return "Score 21 points today"
            case .perfectGame: return "Win a match 11-0"
            case .addFriend: return "Add 1 friend today"
            case .joinTournament: return "Join 1 tournament today"
            }
        }
        
        var icon: String {
            switch self {
            case .playMatches: return "gamecontroller.fill"
            case .winMatches: return "trophy.fill"
            case .scorePoints: return "number.circle.fill"
            case .perfectGame: return "crown.fill"
            case .addFriend: return "person.badge.plus.fill"
            case .joinTournament: return "flag.fill"
            }
        }
        
        var color: String {
            switch self {
            case .playMatches: return "blue"
            case .winMatches: return "gold"
            case .scorePoints: return "purple"
            case .perfectGame: return "gold"
            case .addFriend: return "blue"
            case .joinTournament: return "purple"
            }
        }
        
        var targetValue: Int {
            switch self {
            case .playMatches: return 3
            case .winMatches: return 2
            case .scorePoints: return 21
            case .perfectGame: return 1
            case .addFriend: return 1
            case .joinTournament: return 1
            }
        }
    }
}

struct GameMatch: Identifiable {
    let id = UUID()
    let opponentName: String
    let result: String
    let score: String
    let eloChange: String
    let date: Date
}

extension Notification.Name {
    static let userLeveledUp = Notification.Name("userLeveledUp")
    static let xpAwarded = Notification.Name("xpAwarded")
    static let missionCompleted = Notification.Name("missionCompleted")
    static let showXPNotification = Notification.Name("showXPNotification")
    static let showLevelUpNotification = Notification.Name("showLevelUpNotification")
    static let showMissionCompleteNotification = Notification.Name("showMissionCompleteNotification")
    static let trophyUnlocked = Notification.Name("trophyUnlocked")
    static let navigateToQueue = Notification.Name("navigateToQueue")
    static let navigateToTournaments = Notification.Name("navigateToTournaments")
} 