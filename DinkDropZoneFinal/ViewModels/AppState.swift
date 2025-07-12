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
    var realtimeService: RealtimeService?

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
    @Published var currentMatchProposal: RealtimeMatchmakingService.MatchProposal?
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
    
    var firebaseService: FirebaseService {
        return FirebaseService.shared
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
        
        // Initialize authentication service
        self.authService = AuthService(modelContext: modelContext)
        
        // Initialize location services
        self.locationService = UserLocationService()
        self.nearbyPlayersService = NearbyPlayersService(locationService: self.locationService!)
        
        // Initialize real-time services for alpha testing
        self.realtimeMatchmakingService = RealtimeMatchmakingService(appState: self)
        self.localMatchmakingService = LocalMatchmakingService(appState: self)
        
        // Initialize matchmaking services
        initializeMatchmakingServices()
        
        // Initialize push notification service
        self.pushNotificationService = PushNotificationService.shared
        self.alphaTestingService = AlphaTestingService.shared
        
        // Initialize tournament service
        self.tournamentService = TournamentService(firebaseService: FirebaseService.shared)
        
        // Initialize real-time service
        self.realtimeService = RealtimeService(firebaseService: FirebaseService.shared)
        
        // Initialize achievement system
        self.achievementTracker = AdvancedAchievementTracker()
        self.achievementNotificationManager = AchievementNotificationManager()
        
        setupNotificationObservers()
        setupRealtimeObservers()
        generateDailyChallenges()
        
        // Observe auth service user changes
        setupAuthServiceObserver()

        Task { 
            await loadInitialData()
            await setupPushNotifications()
            await startRealtimeMonitoring()
        }
    }

/// Sets up observer for AuthService user changes
private func setupAuthServiceObserver() {
    // Use NotificationCenter to observe auth changes since AuthService is @Observable
    NotificationCenter.default.addObserver(
        forName: NSNotification.Name("AuthServiceUserChanged"),
        object: nil,
        queue: .main
    ) { [weak self] notification in
        if let user = notification.object as? User {
            Task { @MainActor in
                self?.handleAuthServiceUserChange(user)
            }
        } else {
            Task { @MainActor in
                self?.handleAuthServiceUserSignOut()
            }
        }
    }
    
    // Check for existing user in AuthService
    if let existingUser = authService?.currentUser {
        handleAuthServiceUserChange(existingUser)
    }
}

/// Handles when AuthService reports a user sign in
private func handleAuthServiceUserChange(_ user: User) {
    print("📱 AppState: AuthService user changed - \(user.displayName)")
    
    // Update current user
    currentUser = user
    persistUserToLocal(user)
    
    // Start alpha testing session
    alphaTestingService?.startTestingSession(user: user)
    
    Task {
        await loadInitialData()
        await refreshUserStats()
    }
}

/// Handles when AuthService reports a user sign out
private func handleAuthServiceUserSignOut() {
    print("📱 AppState: AuthService user signed out")
    
    currentUser = nil
    // Clear other user-specific data
    userStats = nil
    recentMatches = nil
    nearbyPlayers = []
    friendRequests = []
    
    // Stop alpha testing session
    alphaTestingService?.endTestingSession()
}

private func subscribeToUserUpdates(uid: String) {
    // This method is now handled by AuthService
    // We can remove or simplify this since AuthService manages Firebase user state
    print("📱 AppState: User updates now managed by AuthService")
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
    
    /// Setup real-time observers for centralized data sync
    private func setupRealtimeObservers() {
        // Real-time tournaments updates
        NotificationCenter.default.addObserver(
            forName: .realtimeTournamentsUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let tournaments = notification.object as? [Tournament] {
                Task { @MainActor [weak self] in
                    self?.handleRealtimeTournamentsUpdate(tournaments)
                }
            }
        }
        
        // Real-time notifications updates
        NotificationCenter.default.addObserver(
            forName: .realtimeNotificationsUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let data = notification.object as? [String: Any] {
                Task { @MainActor [weak self] in
                    self?.handleRealtimeNotificationsUpdate(data)
                }
            }
        }
        
        // Real-time leaderboard updates
        NotificationCenter.default.addObserver(
            forName: .realtimeLeaderboardUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let data = notification.object as? [String: Any] {
                Task { @MainActor [weak self] in
                    self?.handleRealtimeLeaderboardUpdate(data)
                }
            }
        }
        
        // Real-time queue updates
        NotificationCenter.default.addObserver(
            forName: .realtimeQueueUpdated,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let data = notification.object as? [String: Any] {
                Task { @MainActor [weak self] in
                    self?.handleRealtimeQueueUpdate(data)
                }
            }
        }
        
        // Connection status changes
        NotificationCenter.default.addObserver(
            forName: .realtimeConnectionStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let status = notification.object as? RealtimeService.ConnectionStatus {
                Task { @MainActor [weak self] in
                    self?.handleConnectionStatusChange(status)
                }
            }
        }
    }
    
    /// Start comprehensive real-time monitoring and data sync
    private func startRealtimeMonitoring() async {
        guard let realtimeService = realtimeService else { return }
        
        // Start real-time service
        realtimeService.startRealtimeMonitoring()
        
        // Load tournament data with real-time sync
        await loadTournamentData()
        
        // Setup user-specific listeners if authenticated
        if let currentUser = currentUser {
            setupUserSpecificListeners(for: currentUser)
        }
        
        LoggingService.shared.log("✅ Real-time monitoring started with tournament integration")
    }
    
    /// Setup user-specific real-time listeners
    private func setupUserSpecificListeners(for user: User) {
        guard let realtimeService = realtimeService else { return }
        
        // User profile listener
        _ = realtimeService.observeUser(id: user.id.uuidString) { [weak self] result in
            switch result {
            case .success(let updatedUser):
                self?.handleUserProfileUpdate(updatedUser)
            case .failure(let error):
                LoggingService.shared.log("User profile listener error: \(error)")
            }
        }
        
        LoggingService.shared.log("User-specific listeners setup completed")
    }
    
    // MARK: - Real-time Update Handlers
    
    private func handleRealtimeTournamentsUpdate(_ tournaments: [Tournament]) {
        // Update local tournament data
        LoggingService.shared.log("Received real-time tournaments update: \(tournaments.count) tournaments")
        
        // Notify tournament service
        tournamentService?.handleRealtimeUpdate(tournaments)
        
        // Post notification for tournament views
        NotificationCenter.default.post(
            name: .tournamentUpdated,
            object: tournaments
        )
    }
    
    private func handleRealtimeNotificationsUpdate(_ data: [String: Any]) {
        // Process notification updates
        LoggingService.shared.log("Received real-time notifications update")
        
        // Update unread notifications count
        if data["unreadCount"] != nil {
            // Update UI with new count
            Task {
                await loadNotifications()
            }
        }
    }
    
    private func handleRealtimeLeaderboardUpdate(_ data: [String: Any]) {
        // Process leaderboard updates
        LoggingService.shared.log("Received real-time leaderboard update")
        
        // Post notification for leaderboard views
        NotificationCenter.default.post(
            name: .leaderboardUpdated,
            object: data
        )
    }
    
    private func handleRealtimeQueueUpdate(_ data: [String: Any]) {
        // Process queue updates
        LoggingService.shared.log("Received real-time queue update")
        
        // Update queue statistics
        if let queueCount = data["queueCount"] as? Int {
            self.queueCount = queueCount
        }
        
        if let position = data["position"] as? Int {
            self.queuePosition = position
        }
        
        // Post notification for queue views
        NotificationCenter.default.post(
            name: .queueUpdated,
            object: data
        )
    }
    
    private func handleConnectionStatusChange(_ status: RealtimeService.ConnectionStatus) {
        // Handle connection status changes
        LoggingService.shared.log("Real-time connection status changed: \(status.displayText)")
        
        // Update UI based on connection status
        switch status {
        case .connected:
            // Connection restored - sync any pending data
            Task {
                await loadInitialData()
            }
        case .disconnected:
            // Connection lost - show offline indicator
            addNotification(AppNotification(
                type: .system,
                title: "Connection Lost",
                message: "You're currently offline. Changes will sync when connection is restored.",
                data: [:]
            ))
        case .error(let message):
            // Connection error - show error message
            addNotification(AppNotification(
                type: .system,
                title: "Connection Error",
                message: message,
                data: [:]
            ))
        default:
            break
        }
    }
    
    private func handleUserProfileUpdate(_ user: User) {
        // Update current user with real-time changes
        LoggingService.shared.log("Received user profile update: \(user.displayName)")
        
        currentUser = user
        
        // Update local storage
        persistUserToLocal(user)
        
        // Post notification for profile views
        NotificationCenter.default.post(
            name: .userProfileUpdated,
            object: user
        )
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
    
    // MARK: - Matchmaking Management
    
    func initializeMatchmakingServices() {
        // Only initialize if not already initialized with proper AppState reference
        if realtimeMatchmakingService == nil {
            realtimeMatchmakingService = RealtimeMatchmakingService(appState: self)
        }
        
        if localMatchmakingService == nil {
            localMatchmakingService = LocalMatchmakingService(appState: self)
        }
        
        // Bind service states to AppState
        if let realtimeService = realtimeMatchmakingService {
            realtimeService.$isInQueue.assign(to: &$isInQueue)
            realtimeService.$queuePosition.assign(to: &$queuePosition)
            realtimeService.$estimatedWaitTime.assign(to: &$estimatedWaitTime)
            realtimeService.$currentProposal.assign(to: &$currentMatchProposal)
        }
        
        // Setup notification observers for matchmaking
        setupMatchmakingNotifications()
    }
    
    func joinRealtimeQueue(matchType: MatchType) async throws {
        guard let currentUser = currentUser,
              let realtimeService = realtimeMatchmakingService else {
            throw NSError(domain: "AppState", code: 1, userInfo: [NSLocalizedDescriptionKey: "User or service not available"])
        }
        
        try await realtimeService.joinQueue(userId: currentUser.id.uuidString, matchType: matchType)
        print("✅ Successfully joined real-time matchmaking queue")
    }
    
    func leaveRealtimeQueue() async throws {
        guard let realtimeService = realtimeMatchmakingService else {
            throw NSError(domain: "AppState", code: 1, userInfo: [NSLocalizedDescriptionKey: "Service not available"])
        }
        
        try await realtimeService.leaveQueue()
        print("✅ Successfully left real-time matchmaking queue")
    }
    
    func startLocalMatchmaking(matchType: MatchType) async throws {
        guard let currentUser = currentUser,
              let localService = localMatchmakingService else {
            throw NSError(domain: "AppState", code: 1, userInfo: [NSLocalizedDescriptionKey: "User or service not available"])
        }
        
        try await localService.startMatchmaking(user: currentUser, matchType: matchType)
        print("✅ Successfully started local matchmaking")
    }
    
    func stopLocalMatchmaking() {
        guard let localService = localMatchmakingService else { return }
        
        Task {
            localService.stopMatchmaking()
            print("✅ Successfully stopped local matchmaking")
        }
    }
    
    func proposeLocalMatch(to player: LocalMatchmakingService.NearbyPlayer) async throws {
        guard let localService = localMatchmakingService else {
            throw NSError(domain: "AppState", code: 1, userInfo: [NSLocalizedDescriptionKey: "Local service not available"])
        }
        
        try await localService.proposeMatch(to: player)
        print("✅ Successfully proposed local match")
    }
    
    func respondToLocalProposal(accept: Bool) async throws {
        guard let localService = localMatchmakingService else {
            throw NSError(domain: "AppState", code: 1, userInfo: [NSLocalizedDescriptionKey: "Local service not available"])
        }
        
        try await localService.respondToProposal(accept: accept)
        print("✅ Successfully responded to local match proposal")
    }
    
    func respondToRealtimeProposal(response: String) async throws {
        guard let realtimeService = realtimeMatchmakingService else {
            throw NSError(domain: "AppState", code: 1, userInfo: [NSLocalizedDescriptionKey: "Real-time service not available"])
        }
        
        try await realtimeService.respondToProposal(response)
        print("✅ Successfully responded to real-time match proposal")
    }
    
    private func setupMatchmakingNotifications() {
        // Setup notifications for match proposals and updates
        NotificationCenter.default.addObserver(
            forName: .matchProposed,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let proposal = notification.object as? RealtimeMatchmakingService.MatchProposal {
                Task { @MainActor [weak self] in
                    self?.currentMatchProposal = proposal
                }
            }
        }
    }
    
    // MARK: - Match Results & Real-time Updates System
    
    @Published var activeMatchUpdates: [String: MatchUpdate] = [:]
    @Published var matchListeners: [String: FirebaseService.ListenerHandle] = [:]
    
    struct MatchUpdate {
        let matchId: String
        let tournamentId: String
        let score: String
        let winnerID: String?
        let status: String
        let timestamp: Date
    }
    
    /// Centralized match result submission that updates both local state and Firebase
    func submitMatchResult(
        match: TournamentMatch,
        winnerID: String,
        loserID: String,
        score: String,
        tournament: Tournament
    ) async throws {
        print("🏓 Submitting match result: \(match.displayName) - Winner: \(winnerID)")
        
        // Create updated match
        var updatedMatch = match
        updatedMatch.status = "Completed"
        updatedMatch.winnerID = winnerID
        updatedMatch.loserID = loserID
        updatedMatch.finalScore = score
        // Note: TournamentMatch doesn't have completedAt property, Firebase will handle timestamps
        
        do {
            // Update match in Firebase with transaction safety
            try await firebaseService.updateTournamentMatch(
                tournamentId: tournament.id.uuidString,
                match: updatedMatch
            )
            
            // Update local tournament service cache
            if let tournamentService = tournamentService {
                try await tournamentService.updateTournament(tournament)
            }
            
            // Trigger real-time notifications for connected views
            await triggerMatchUpdateNotifications(
                matchId: match.id.uuidString,
                tournamentId: tournament.id.uuidString,
                update: MatchUpdate(
                    matchId: match.id.uuidString,
                    tournamentId: tournament.id.uuidString,
                    score: score,
                    winnerID: winnerID,
                    status: "Completed",
                    timestamp: Date()
                )
            )
            
            print("✅ Match result submitted successfully")
            
        } catch {
            print("❌ Failed to submit match result: \(error)")
            throw error
        }
    }
    
    /// Real-time match score updates for live matches
    func updateLiveMatchScore(
        matchId: String,
        tournamentId: String,
        player1Score: Int,
        player2Score: Int
    ) async throws {
        print("📊 Updating live match score: \(matchId) - \(player1Score)-\(player2Score)")
        
        // Create real-time score update
        let scoreUpdate: [String: Any] = [
            "player1Score": player1Score,
            "player2Score": player2Score,
            "lastUpdated": Date().timeIntervalSince1970,
            "status": "In Progress"
        ]
        
        do {
            // Update score in Firebase real-time database for live sync
            try await firebaseService.updateLiveMatchScore(
                tournamentId: tournamentId,
                matchId: matchId,
                scoreData: scoreUpdate
            )
            
            // Trigger local UI updates
            await triggerLiveScoreUpdate(
                matchId: matchId,
                tournamentId: tournamentId,
                player1Score: player1Score,
                player2Score: player2Score
            )
            
        } catch {
            print("❌ Failed to update live match score: \(error)")
            throw error
        }
    }
    
    /// Setup real-time listeners for tournament matches
    func setupMatchResultListeners(tournamentId: String) {
        print("🔄 Setting up real-time match result listeners for tournament: \(tournamentId)")
        
        // Listen for tournament-wide match updates
        let listener = firebaseService.observeTournament(id: tournamentId) { [weak self] result in
            switch result {
            case .success(let tournament):
                Task {
                    await MainActor.run {
                        self?.handleTournamentMatchUpdates(tournament)
                    }
                }
            case .failure(let error):
                print("❌ Tournament match listener error: \(error)")
            }
        }
        
        matchListeners[tournamentId] = listener
    }
    
    /// Handle incoming tournament match updates
    private func handleTournamentMatchUpdates(_ tournament: Tournament) {
        print("🔄 Handling tournament match updates: \(tournament.name)")
        
        // Check for newly completed matches
        let completedMatches = tournament.matches.filter { $0.status == "Completed" }
        
        for match in completedMatches {
            // Trigger bracket update notifications
            NotificationCenter.default.post(
                name: .matchCompleted,
                object: match,
                userInfo: ["tournamentId": tournament.id.uuidString]
            )
            
            // Update ELO and stats for participants if current user is involved
            if let currentUser = currentUser, let firebaseUser = Auth.auth().currentUser,
               (match.player1ID == firebaseUser.uid || match.player2ID == firebaseUser.uid) {
                Task {
                    await updateUserStatsFromMatch(match: match)
                }
            }
        }
        
        // Post tournament update notification for UI refresh
        NotificationCenter.default.post(
            name: .tournamentUpdated,
            object: tournament
        )
    }
    
    /// Update user stats from completed match
    private func updateUserStatsFromMatch(match: TournamentMatch) async {
        guard let user = currentUser else { return }
        
        let isWinner = match.winnerID == user.id.uuidString
        let eloChange = calculateEloChange(isWinner: isWinner, opponentElo: 1200) // Default opponent ELO
        
        // Update user stats
        user.totalMatches += 1
        if isWinner {
            user.wins += 1
            user.winStreak += 1
            user.longestWinStreak = max(user.longestWinStreak, user.winStreak)
        } else {
            user.losses += 1
            user.winStreak = 0
        }
        
        user.elo += eloChange
        
        // Save updated user to Firebase
        do {
            try await firebaseService.updateUser(user)
            updateUser(user)
            print("✅ Updated user stats from tournament match")
        } catch {
            print("❌ Failed to update user stats: \(error)")
        }
    }
    
    /// Calculate ELO change for match result
    private func calculateEloChange(isWinner: Bool, opponentElo: Int) -> Int {
        // Simplified ELO calculation - could be enhanced with proper K-factor
        let baseDelta = 15
        return isWinner ? baseDelta : -baseDelta
    }
    
    /// Trigger match update notifications for connected views
    private func triggerMatchUpdateNotifications(
        matchId: String,
        tournamentId: String,
        update: MatchUpdate
    ) async {
        await MainActor.run {
            // Update active match updates
            activeMatchUpdates[matchId] = update
            
            // Post notification for bracket views
            NotificationCenter.default.post(
                name: .matchResultSubmitted,
                object: update,
                userInfo: [
                    "matchId": matchId,
                    "tournamentId": tournamentId
                ]
            )
            
            // Haptic feedback for successful submission
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            // Add user notification
            addNotification(AppNotification(
                type: .match,
                title: "Match Result Submitted",
                message: "Match result has been recorded and tournament updated",
                data: ["matchId": matchId, "tournamentId": tournamentId]
            ))
        }
    }
    
    /// Trigger live score update notifications
    private func triggerLiveScoreUpdate(
        matchId: String,
        tournamentId: String,
        player1Score: Int,
        player2Score: Int
    ) async {
        await MainActor.run {
            // Post notification for live match views
            NotificationCenter.default.post(
                name: .liveScoreUpdated,
                object: nil,
                userInfo: [
                    "matchId": matchId,
                    "tournamentId": tournamentId,
                    "player1Score": player1Score,
                    "player2Score": player2Score
                ]
            )
        }
    }
    
    /// Clean up match result listeners
    func cleanupMatchResultListeners() {
        for (_, listener) in matchListeners {
            listener.remove()
        }
        matchListeners.removeAll()
        activeMatchUpdates.removeAll()
    }
    
    // MARK: - Tournament State Management
    
    @Published var tournaments: [Tournament] = []
    @Published var myTournaments: [Tournament] = []
    @Published var liveTournaments: [Tournament] = []
    @Published var featuredTournaments: [Tournament] = []
    @Published var currentTournament: Tournament?
    @Published var activeTournamentMatch: TournamentMatch?
    @Published var tournamentDashboardData: TournamentDashboardData?
    @Published var tournamentLoadingState: TournamentLoadingState = .idle
    
    // Tournament filters and search
    @Published var tournamentSearchText: String = ""
    @Published var tournamentFilters: TournamentFilters = TournamentFilters()
    @Published var selectedTournamentTab: TournamentTab = .all
    
    // Tournament statistics
    @Published var tournamentStats: TournamentStatistics = TournamentStatistics()
    @Published var tournamentLeaderboard: [TournamentLeaderboardEntry] = []
    @Published var tournamentNotifications: [TournamentNotification] = []
    
    // Tournament listeners
    private var tournamentListeners: [String: FirebaseService.ListenerHandle] = [:]
    private var tournamentUpdateTimer: Timer?
    
    enum TournamentLoadingState: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }
    
    enum TournamentTab {
        case all
        case my
        case live
        case featured
        case completed
    }
    
    struct TournamentFilters {
        var skillLevel: String?
        var type: String?
        var status: String?
        var dateRange: DateRange?
        var location: String?
        var prizePool: PrizePoolRange?
        
        struct DateRange {
            let start: Date
            let end: Date
        }
        
        struct PrizePoolRange {
            let min: Int
            let max: Int
        }
    }
    
    struct TournamentDashboardData {
        let totalTournaments: Int
        let liveTournaments: Int
        let myActiveTournaments: Int
        let completedTournaments: Int
        let upcomingTournaments: Int
        let recentActivity: [TournamentActivity]
        let quickStats: QuickStats
        let announcements: [TournamentAnnouncement]
        
        struct QuickStats {
            let totalParticipants: Int
            let ongoingMatches: Int
            let completedMatches: Int
            let averageMatchDuration: TimeInterval
            let topPerformers: [String]
        }
        
        struct TournamentActivity {
            let id: String
            let type: ActivityType
            let description: String
            let tournamentName: String
            let timestamp: Date
            let userID: String?
            
            enum ActivityType {
                case joined
                case matchCompleted
                case roundAdvanced
                case tournamentWon
                case tournamentCreated
                case bracketUpdated
            }
        }
        
        struct TournamentAnnouncement {
            let id: String
            let title: String
            let message: String
            let priority: Priority
            let timestamp: Date
            let tournamentID: String?
            
            enum Priority {
                case low
                case medium
                case high
                case urgent
            }
        }
    }
    
    struct TournamentStatistics {
        var totalTournaments: Int = 0
        var participationRate: Double = 0.0
        var averagePerformance: Double = 0.0
        var bestFinishes: [TournamentFinish] = []
        var recentMatches: [TournamentMatch] = []
        var winRate: Double = 0.0
        var totalMatches: Int = 0
        var totalWins: Int = 0
        var averageEloGain: Double = 0.0
        var favoriteFormat: String = ""
        var streak: Int = 0
        
        struct TournamentFinish {
            let tournamentID: String
            let tournamentName: String
            let placement: Int
            let totalParticipants: Int
            let date: Date
            let prizesWon: [String]
        }
    }
    
    struct TournamentLeaderboardEntry {
        let userID: String
        let displayName: String
        let elo: Int
        let tournaments: Int
        let wins: Int
        let placement: Int
        let streak: Int
        let profileImageURL: String?
    }
    
    struct TournamentNotification {
        let id: String
        let type: NotificationType
        let title: String
        let message: String
        let tournamentID: String?
        let timestamp: Date
        let isRead: Bool
        
        enum NotificationType {
            case matchReady
            case tournamentStarted
            case roundCompleted
            case bracketUpdated
            case tournamentCompleted
            case registrationOpened
            case registrationClosed
            case prizeDistributed
        }
    }
    
    // MARK: - Centralized Tournament Data Management
    
    /// Load all tournament data with real-time synchronization
    func loadTournamentData() async {
        await MainActor.run {
            tournamentLoadingState = .loading
        }
        
        do {
            // Load tournaments from Firebase
            let allTournaments = try await firebaseService.getAllTournaments()
            
            await MainActor.run {
                // Update tournament collections
                self.tournaments = allTournaments
                self.updateTournamentCollections()
                
                // Load dashboard data
                Task {
                    await self.loadTournamentDashboardData()
                }
                
                // Load user-specific tournament data
                Task {
                    await self.loadUserTournamentData()
                }
                
                // Setup real-time listeners
                self.setupTournamentListeners()
                
                self.tournamentLoadingState = .loaded
                
                LoggingService.shared.log("✅ Tournament data loaded successfully: \(allTournaments.count) tournaments")
            }
            
        } catch {
            await MainActor.run {
                self.tournamentLoadingState = .error(error.localizedDescription)
                LoggingService.shared.log("❌ Failed to load tournament data: \(error)")
            }
        }
    }
    
    /// Update tournament collections based on current user and filters
    private func updateTournamentCollections() {
        // Filter tournaments based on user participation
        if let currentUser = currentUser, let firebaseUser = Auth.auth().currentUser {
            myTournaments = tournaments.filter { tournament in
                tournament.participants.contains { $0.userID == firebaseUser.uid }
            }
        } else {
            myTournaments = []
        }
        
        // Filter live tournaments
        liveTournaments = tournaments.filter { tournament in
            tournament.status == "In Progress" || tournament.status == "Live"
        }
        
        // Filter featured tournaments
        featuredTournaments = tournaments.filter { tournament in
            tournament.isFeatured == true && (tournament.status == "Registration Open" || tournament.status == "Upcoming")
        }.sorted { $0.prizePool > $1.prizePool }
        
        // Apply search and filters
        applyTournamentFilters()
    }
    
    /// Apply current filters and search to tournaments
    private func applyTournamentFilters() {
        // Implementation would filter tournaments based on current filters
        // This is a placeholder for the filtering logic
        LoggingService.shared.log("Applied tournament filters - Search: '\(tournamentSearchText)'")
    }
    
    /// Load tournament dashboard data
    private func loadTournamentDashboardData() async {
        // Calculate dashboard statistics
        let totalTournaments = tournaments.count
        let liveTournaments = self.liveTournaments.count
        let myActiveTournaments = myTournaments.filter { $0.status == "In Progress" || $0.status == "Registration Open" }.count
        let completedTournaments = tournaments.filter { $0.status == "Completed" }.count
        let upcomingTournaments = tournaments.filter { $0.status == "Upcoming" }.count
        
        // Load recent activity
        let recentActivity = await loadRecentTournamentActivity()
        
        // Calculate quick stats
        let quickStats = calculateQuickStats()
        
        // Load announcements
        let announcements = await loadTournamentAnnouncements()
        
        await MainActor.run {
            self.tournamentDashboardData = TournamentDashboardData(
                totalTournaments: totalTournaments,
                liveTournaments: liveTournaments,
                myActiveTournaments: myActiveTournaments,
                completedTournaments: completedTournaments,
                upcomingTournaments: upcomingTournaments,
                recentActivity: recentActivity,
                quickStats: quickStats,
                announcements: announcements
            )
            
            LoggingService.shared.log("✅ Tournament dashboard data loaded")
        }
    }
    
    /// Load user-specific tournament data
    private func loadUserTournamentData() async {
        guard let currentUser = currentUser, let firebaseUser = Auth.auth().currentUser else { return }
        
        do {
            // Load user tournament statistics
            let userTournaments = try await firebaseService.getUserTournaments(userId: firebaseUser.uid)
            
            // Calculate tournament statistics
            let stats = calculateTournamentStatistics(for: userTournaments)
            
            // Load tournament leaderboard
            let leaderboard = try await firebaseService.getTournamentLeaderboard(limit: 50)
            
            await MainActor.run {
                self.tournamentStats = stats
                self.tournamentLeaderboard = leaderboard.map { entry in
                    TournamentLeaderboardEntry(
                        userID: entry.userId,
                        displayName: entry.displayName,
                        elo: 1200, // Placeholder since original doesn't have elo
                        tournaments: entry.tournamentsPlayed,
                        wins: entry.totalWins,
                        placement: entry.rank,
                        streak: 0, // Placeholder since original doesn't have streak
                        profileImageURL: nil
                    )
                }
                
                LoggingService.shared.log("✅ User tournament data loaded")
            }
            
        } catch {
            LoggingService.shared.log("❌ Failed to load user tournament data: \(error)")
        }
    }
    
    /// Setup real-time listeners for tournament data
    private func setupTournamentListeners() {
        // Listen for tournament collection changes
        let tournamentListener = firebaseService.observeTournamentCollection { [weak self] result in
            switch result {
            case .success(let tournaments):
                Task {
                    await MainActor.run {
                        self?.handleTournamentCollectionUpdate(tournaments)
                    }
                }
            case .failure(let error):
                LoggingService.shared.log("❌ Tournament collection listener error: \(error)")
            }
        }
        
        tournamentListeners["tournament_collection"] = tournamentListener
        
        // Listen for tournament notifications
        if let currentUser = currentUser, let firebaseUser = Auth.auth().currentUser {
            let notificationListener = firebaseService.observeTournamentNotifications(userID: firebaseUser.uid) { [weak self] result in
                switch result {
                case .success(let notifications):
                    Task {
                        await MainActor.run {
                            self?.handleTournamentNotificationUpdate(notifications)
                        }
                    }
                case .failure(let error):
                    LoggingService.shared.log("❌ Tournament notification listener error: \(error)")
                }
            }
            
            tournamentListeners["tournament_notifications"] = notificationListener
        }
        
        LoggingService.shared.log("✅ Tournament real-time listeners setup")
    }
    
    /// Handle tournament collection updates
    private func handleTournamentCollectionUpdate(_ tournaments: [Tournament]) {
        self.tournaments = tournaments
        updateTournamentCollections()
        
        // Update dashboard data
        Task {
            await loadTournamentDashboardData()
        }
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: .tournamentDataUpdated,
            object: tournaments
        )
        
        LoggingService.shared.log("🔄 Tournament collection updated: \(tournaments.count) tournaments")
    }
    
    /// Handle tournament notification updates
    private func handleTournamentNotificationUpdate(_ notifications: [TournamentNotification]) {
        self.tournamentNotifications = notifications
        
        // Show new notifications
        let newNotifications = notifications.filter { !$0.isRead }
        for notification in newNotifications {
            addNotification(AppNotification(
                type: .tournament,
                title: notification.title,
                message: notification.message,
                data: ["tournamentID": notification.tournamentID ?? ""]
            ))
        }
        
        LoggingService.shared.log("🔔 Tournament notifications updated: \(newNotifications.count) new")
    }
    
    // MARK: - Tournament Actions
    
    /// Join a tournament
    func joinTournament(_ tournament: Tournament) async throws {
        guard let currentUser = currentUser,
              let tournamentService = tournamentService else {
            throw NSError(domain: "AppState", code: 1, userInfo: [NSLocalizedDescriptionKey: "User or service not available"])
        }
        
        do {
            try await tournamentService.joinTournament(tournament, user: currentUser)
            
            // Update local state
            await MainActor.run {
                if let index = tournaments.firstIndex(where: { $0.id == tournament.id }) {
                    // Update tournament in main collection
                    tournaments[index] = tournament
                    updateTournamentCollections()
                }
                
                // Add to notifications
                addNotification(AppNotification(
                    type: .tournament,
                    title: "Tournament Joined",
                    message: "Successfully joined \(tournament.name)",
                    data: ["tournamentID": tournament.id.uuidString]
                ))
            }
            
            LoggingService.shared.log("✅ Successfully joined tournament: \(tournament.name)")
            
        } catch {
            LoggingService.shared.log("❌ Failed to join tournament: \(error)")
            throw error
        }
    }
    
    /// Leave a tournament
    func leaveTournament(_ tournament: Tournament) async throws {
        guard let currentUser = currentUser,
              let tournamentService = tournamentService else {
            throw NSError(domain: "AppState", code: 1, userInfo: [NSLocalizedDescriptionKey: "User or service not available"])
        }
        
        do {
            try await tournamentService.leaveTournament(tournament, user: currentUser)
            
            // Update local state
            await MainActor.run {
                if let index = tournaments.firstIndex(where: { $0.id == tournament.id }) {
                    tournaments[index] = tournament
                    updateTournamentCollections()
                }
                
                addNotification(AppNotification(
                    type: .tournament,
                    title: "Tournament Left",
                    message: "Left \(tournament.name)",
                    data: ["tournamentID": tournament.id.uuidString]
                ))
            }
            
            LoggingService.shared.log("✅ Successfully left tournament: \(tournament.name)")
            
        } catch {
            LoggingService.shared.log("❌ Failed to leave tournament: \(error)")
            throw error
        }
    }
    
    /// Get tournament by ID
    func getTournament(id: String) -> Tournament? {
        return tournaments.first { $0.id.uuidString == id }
    }
    
    /// Get user's tournament status
    func getUserTournamentStatus(for tournament: Tournament) -> UserTournamentStatus {
        guard let currentUser = currentUser, let firebaseUser = Auth.auth().currentUser else { return .notRegistered }
        
        let isParticipant = tournament.participants.contains { $0.userID == firebaseUser.uid }
        
        switch tournament.status {
        case "Registration Open":
            return isParticipant ? .registered : .notRegistered
        case "Registration Closed":
            return isParticipant ? .waitingToStart : .notRegistered
        case "In Progress", "Live":
            return isParticipant ? .participating : .notRegistered
        case "Completed":
            return isParticipant ? .completed : .notRegistered
        default:
            return .notRegistered
        }
    }
    
    /// Cleanup tournament listeners
    func cleanupTournamentListeners() {
        for (_, listener) in tournamentListeners {
            listener.remove()
        }
        tournamentListeners.removeAll()
        
        tournamentUpdateTimer?.invalidate()
        tournamentUpdateTimer = nil
        
        LoggingService.shared.log("🧹 Tournament listeners cleaned up")
    }
    
    // MARK: - Helper Methods
    
    private func loadRecentTournamentActivity() async -> [TournamentDashboardData.TournamentActivity] {
        // Implementation would load recent tournament activity
        // This is a placeholder
        return []
    }
    
    private func calculateQuickStats() -> TournamentDashboardData.QuickStats {
        let totalParticipants = tournaments.reduce(0) { $0 + $1.participants.count }
        let ongoingMatches = tournaments.reduce(0) { $0 + $1.matches.filter { $0.status == "In Progress" }.count }
        let completedMatches = tournaments.reduce(0) { $0 + $1.matches.filter { $0.status == "Completed" }.count }
        
        return TournamentDashboardData.QuickStats(
            totalParticipants: totalParticipants,
            ongoingMatches: ongoingMatches,
            completedMatches: completedMatches,
            averageMatchDuration: 1800, // 30 minutes
            topPerformers: []
        )
    }
    
    private func loadTournamentAnnouncements() async -> [TournamentDashboardData.TournamentAnnouncement] {
        // Implementation would load tournament announcements
        // This is a placeholder
        return []
    }
    
    private func calculateTournamentStatistics(for tournaments: [Tournament]) -> TournamentStatistics {
        // Implementation would calculate detailed tournament statistics
        // This is a placeholder
        return TournamentStatistics()
    }
    
    // MARK: - Missing Methods
    
    /// Get player statistics by ID
    func getPlayerStats(id: String) -> PlayerStats? {
        // If it's the current user, return their stats
        if let currentUser = currentUser, currentUser.id.uuidString == id {
            let winPercentage = currentUser.totalMatches > 0 ? (Double(currentUser.wins) / Double(currentUser.totalMatches)) * 100.0 : 0.0
            
            return PlayerStats(
                playerId: id,
                rating: Double(currentUser.elo),
                wins: currentUser.wins,
                losses: currentUser.losses,
                totalMatches: currentUser.totalMatches,
                averageGameScore: Double(currentUser.totalPointsScored) / Double(max(currentUser.totalMatches, 1)),
                winStreak: currentUser.winStreak,
                lastMatchDate: currentUser.lastActive,
                tournamentWins: 0, // Would need to calculate from tournament data
                totalPoints: currentUser.totalPointsScored,
                winPercentage: winPercentage
            )
        }
        
        // TODO: For other players, would need to fetch from Firebase or cache
        return nil
    }
    
    /// Share content to social platforms
    func shareContent(_ content: SocialShareContent, platforms: [String]) async throws {
        // This would implement social sharing functionality
        // For now, just log the share attempt
        LoggingService.shared.log("📱 Sharing content: \(content.content) to platforms: \(platforms)")
        
        // In a real implementation, this would:
        // 1. Format content for each platform
        // 2. Use platform-specific APIs to share
        // 3. Handle authentication if needed
        // 4. Track sharing analytics
        
        // For now, just show a notification
        addNotification(AppNotification(
            type: .system,
            title: "Content Shared",
            message: "Your content has been shared to \(platforms.joined(separator: ", "))",
            data: ["platforms": platforms]
        ))
    }
    
    // MARK: - Tournament Status Enum
    
    enum UserTournamentStatus {
        case notRegistered
        case registered
        case waitingToStart
        case participating
        case completed
        case eliminated
        
        var displayText: String {
            switch self {
            case .notRegistered: return "Not Registered"
            case .registered: return "Registered"
            case .waitingToStart: return "Waiting to Start"
            case .participating: return "Participating"
            case .completed: return "Completed"
            case .eliminated: return "Eliminated"
            }
        }
        
        var color: Color {
            switch self {
            case .notRegistered: return .gray
            case .registered: return .blue
            case .waitingToStart: return .orange
            case .participating: return .green
            case .completed: return .purple
            case .eliminated: return .red
            }
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
        case tournament
        
        var color: Color {
            switch self {
            case .match: return .blue
            case .friend: return .green
            case .achievement: return .orange
            case .levelUp: return .purple
            case .system: return .gray
            case .challenge: return .indigo
            case .error: return .red
            case .tournament: return .teal
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
            case .tournament: return "flag.fill"
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
    static let navigateToMyTournaments = Notification.Name("navigateToMyTournaments")
    static let matchResultSubmitted = Notification.Name("matchResultSubmitted")
    static let liveScoreUpdated = Notification.Name("liveScoreUpdated")
    static let matchCompleted = Notification.Name("matchCompleted")
    static let userProfileUpdated = Notification.Name("userProfileUpdated")
    static let leaderboardUpdated = Notification.Name("leaderboardUpdated")
    static let tournamentDataUpdated = Notification.Name("tournamentDataUpdated")
} 