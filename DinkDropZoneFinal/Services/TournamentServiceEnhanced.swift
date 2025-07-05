import Foundation
import FirebaseFirestore
import Combine

/// Enhanced Tournament Service with advanced caching, real-time updates, and better error handling.
@MainActor
class TournamentServiceEnhanced: ObservableObject {
    @Published var tournaments: [Tournament] = []
    @Published var myTournaments: [Tournament] = []
    @Published var isLoading: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastError: TournamentError?
    
    private let firebaseService: FirebaseService
    private let tournamentService: TournamentService
    
    // MARK: - Performance Configuration
    
    private struct Configuration {
        static let cacheDuration: TimeInterval = 300 // 5 minutes
        static let maxCacheSize = 100
        static let batchSize = 20
        static let maxRetries = 3
        static let retryDelay: TimeInterval = 1.0
        static let realtimeUpdateInterval: TimeInterval = 30.0
    }
    
    // MARK: - Cache Management
    
    private var tournamentCache: [String: CachedTournament] = [:]
    private var myTournamentsCache: [String: CachedTournament] = [:]
    private var lastFetchTimestamp: Date?
    private var lastMyTournamentsFetch: Date?
    
    private struct CachedTournament {
        let tournament: Tournament
        let timestamp: Date
        let version: Int
        
        var isValid: Bool {
            Date().timeIntervalSince(timestamp) < Configuration.cacheDuration
        }
    }
    
    // MARK: - Real-time Management
    
    private var listeners: [FirebaseService.ListenerHandle] = []
    private var realtimeTimer: Timer?
    private var maintenanceTimer: Timer?
    private var isSubscribedToRealtime = false
    
    enum ConnectionStatus {
        case connected, disconnected, connecting, error(String)
        
        var isConnected: Bool {
            if case .connected = self { return true }
            return false
        }
    }
    
    // MARK: - Initialization
    
    init(firebaseService: FirebaseService, tournamentService: TournamentService) {
        self.firebaseService = firebaseService
        self.tournamentService = tournamentService
        setupPerformanceMonitoring()
        loadFromLocalCache()
    }
    
    deinit {
        print("🧹 TournamentServiceEnhanced deallocating")
        realtimeTimer?.invalidate()
        realtimeTimer = nil
        maintenanceTimer?.invalidate()
        maintenanceTimer = nil
        
        // Clean up listeners synchronously to avoid retain cycles
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        isSubscribedToRealtime = false
    }
    
    // MARK: - Enhanced Public API
    
    /// Fetches all tournaments with intelligent caching and error handling
    func fetchAllTournaments(forceRefresh: Bool = false) async throws {
        // Check cache validity
        if !forceRefresh, 
           let lastFetch = lastFetchTimestamp,
           Date().timeIntervalSince(lastFetch) < Configuration.cacheDuration,
           !tournaments.isEmpty {
            print("📋 Using cached tournaments (\(tournaments.count) items)")
            return
        }
        
        await setLoadingState(true)
        
        do {
            let fetchedTournaments = try await performWithRetry {
                try await self.firebaseService.getAllTournaments(limit: 100)
            }
            
            await updateTournamentsCache(fetchedTournaments)
            await setConnectionStatus(.connected)
            
            print("✅ Fetched \(fetchedTournaments.count) tournaments from Firebase")
            
        } catch {
            await handleError(TournamentError.fetchFailed(error.localizedDescription))
            throw error
        }
        
        await setLoadingState(false)
    }
    
    /// Enhanced tournament creation with validation and optimistic updates
    func createTournament(_ tournament: Tournament) async throws -> String {
        do {
            // Validate tournament before creation
            try validateTournamentForCreation(tournament)
            
            await setLoadingState(true)
            
            // Create tournament in Firebase
            let tournamentId = try await performWithRetry {
                try await self.firebaseService.createTournament(tournament)
            }
            
            // Update local cache optimistically
            var tournamentWithId = tournament
            if let uuid = UUID(uuidString: tournamentId) {
                tournamentWithId = Tournament(
                    id: uuid,
                    name: tournament.name,
                    description: tournament.description,
                    type: tournament.type,
                    format: tournament.format,
                    skillLevel: tournament.skillLevel,
                    maxParticipants: tournament.maxParticipants,
                    startDate: tournament.startDate,
                    endDate: tournament.endDate,
                    status: tournament.status,
                    organizerID: tournament.organizerID,
                    organizerName: tournament.organizerName,
                    venueName: tournament.venueName,
                    venueAddress: tournament.venueAddress,
                    participants: tournament.participants,
                    matches: tournament.matches
                )
            }
            
            await addTournamentToCache(tournamentWithId)
            
            print("✅ Tournament created: \(tournament.name) (ID: \(tournamentId))")
            return tournamentId
            
        } catch {
            await handleError(TournamentError.creationFailed(error.localizedDescription))
            await setLoadingState(false)
            throw error
        }
    }
    
    /// Enhanced tournament registration with transaction safety
    func registerForTournament(tournamentId: String, user: User, partner: User? = nil) async throws {
        do {
            await setLoadingState(true)
            
            // Create participant from user data
            let participant = TournamentParticipant(
                from: user,
                partnerID: partner?.id.uuidString,
                partnerName: partner?.displayName
            )
            
            try await performWithRetry {
                try await self.firebaseService.registerForTournament(
                    tournamentId: tournamentId,
                    participant: participant
                )
            }
            
            // If there's a partner, register them too
            if let partner = partner {
                let partnerParticipant = TournamentParticipant(
                    from: partner,
                    partnerID: user.id.uuidString,
                    partnerName: user.displayName
                )
                
                try await performWithRetry {
                    try await self.firebaseService.registerForTournament(
                        tournamentId: tournamentId,
                        participant: partnerParticipant
                    )
                }
            }
            
            // Refresh tournament data
            await refreshTournament(tournamentId)
            
            print("✅ Registered for tournament: \(tournamentId)")
            
        } catch {
            await handleError(TournamentError.registrationFailed(error.localizedDescription))
            await setLoadingState(false)
            throw error
        }
    }
    
    /// Enhanced tournament leaving with cleanup
    func leaveTournament(tournamentId: String, user: User) async throws {
        do {
            await setLoadingState(true)
            
            try await performWithRetry {
                try await self.firebaseService.leaveTournament(
                    tournamentId: tournamentId,
                    userId: user.id.uuidString
                )
            }
            
            // Refresh tournament data
            await refreshTournament(tournamentId)
            
            print("✅ Left tournament: \(tournamentId)")
            
        } catch {
            await handleError(TournamentError.leaveFailed(error.localizedDescription))
            await setLoadingState(false)
            throw error
        }
    }
    
    /// Join tournament with user and optional partner (convenience method)
    func joinTournament(_ tournament: Tournament, user: User, partner: String? = nil) async throws {
        // Note: The participant creation is handled inside registerForTournament
        try await registerForTournament(tournamentId: tournament.id.uuidString, user: user)
    }
    
    /// Enhanced user tournaments fetching with caching
    func getUserTournaments(userId: String, forceRefresh: Bool = false) async throws -> [Tournament] {
        // Check cache validity
        if !forceRefresh,
           let lastFetch = lastMyTournamentsFetch,
           Date().timeIntervalSince(lastFetch) < Configuration.cacheDuration,
           !myTournaments.isEmpty {
            print("📋 Using cached user tournaments (\(myTournaments.count) items)")
            return myTournaments
        }
        
        do {
            await setLoadingState(true)
            
            let userTournaments = try await performWithRetry {
                try await self.firebaseService.getUserTournaments(userId: userId)
            }
            
            await updateMyTournamentsCache(userTournaments)
            
            print("✅ Fetched \(userTournaments.count) user tournaments")
            return userTournaments
            
        } catch {
            await handleError(TournamentError.fetchFailed(error.localizedDescription))
            await setLoadingState(false)
            throw error
        }
    }
    
    /// Enhanced tournament retrieval with smart caching
    func getTournament(id: String, forceRefresh: Bool = false) async throws -> Tournament {
        // Check cache first
        if !forceRefresh,
           let cached = tournamentCache[id],
           cached.isValid {
            print("📋 Using cached tournament: \(id)")
            return cached.tournament
        }
        
        do {
            let tournament = try await performWithRetry {
                try await self.firebaseService.getTournament(id: id)
            }
            
            await addTournamentToCache(tournament)
            return tournament
            
        } catch {
            await handleError(TournamentError.fetchFailed(error.localizedDescription))
            throw error
        }
    }
    
    /// Enhanced match result submission with validation
    func submitMatchResult(
        tournamentId: String,
        match: TournamentMatch,
        winnerID: String,
        loserID: String,
        score: String
    ) async throws {
        do {
            // Validate match result
            try validateMatchResult(match: match, winnerID: winnerID, loserID: loserID, score: score)
            
            await setLoadingState(true)
            
            // Create updated match
            var updatedMatch = match
            updatedMatch.winnerID = winnerID
            updatedMatch.loserID = loserID
            updatedMatch.finalScore = score
            updatedMatch.status = "Completed"
            
            try await performWithRetry {
                try await self.firebaseService.updateTournamentMatch(
                    tournamentId: tournamentId,
                    match: updatedMatch
                )
            }
            
            // Refresh tournament data
            await refreshTournament(tournamentId)
            
            print("✅ Match result submitted: \(match.displayName)")
            
        } catch {
            await handleError(TournamentError.matchUpdateFailed(error.localizedDescription))
            await setLoadingState(false)
            throw error
        }
    }
    
    /// Enhanced real-time subscription management
    func subscribeToAllTournamentUpdates() {
        guard !isSubscribedToRealtime else { return }
        
        print("🔄 Setting up real-time tournament updates")
        isSubscribedToRealtime = true
        
        // Initial fetch
        Task {
            try? await fetchAllTournaments(forceRefresh: true)
        }
        
        // Set up periodic refresh for active tournaments
        realtimeTimer = Timer.scheduledTimer(withTimeInterval: Configuration.realtimeUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshActiveTournaments()
            }
        }
        
        Task { @MainActor in
            await setConnectionStatus(.connected)
        }
    }
    
    /// Enhanced listener management
    func removeAllListeners() {
        print("🔄 Removing all tournament listeners")
        listeners.forEach { $0.remove() }
        listeners.removeAll()
        realtimeTimer?.invalidate()
        realtimeTimer = nil
        isSubscribedToRealtime = false
        
        Task { @MainActor in
            connectionStatus = .disconnected
        }
    }
    
    // MARK: - Enhanced Helper Methods
    
    private func performWithRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...Configuration.maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                print("⚠️ Attempt \(attempt) failed: \(error.localizedDescription)")
                
                if attempt < Configuration.maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(Configuration.retryDelay * Double(attempt) * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? TournamentError.operationFailed("Max retries exceeded")
    }
    
    private func validateTournamentForCreation(_ tournament: Tournament) throws {
        guard !tournament.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TournamentError.invalidName
        }
        
        guard tournament.maxParticipants >= 4 && tournament.maxParticipants <= 128 else {
            throw TournamentError.invalidParticipantCount(tournament.maxParticipants)
        }
        
        guard tournament.startDate > Date() else {
            throw TournamentError.invalidStartDate
        }
    }
    
    private func validateMatchResult(match: TournamentMatch, winnerID: String, loserID: String, score: String) throws {
        guard match.status != "Completed" else {
            throw TournamentError.matchAlreadyCompleted
        }
        
        guard !winnerID.isEmpty && !loserID.isEmpty && winnerID != loserID else {
            throw TournamentError.invalidMatchResult
        }
        
        guard [match.player1ID, match.player2ID].contains(winnerID) &&
              [match.player1ID, match.player2ID].contains(loserID) else {
            throw TournamentError.invalidMatchResult
        }
        
        guard !score.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TournamentError.invalidMatchResult
        }
    }
    
    // MARK: - Cache Management
    
    private func addTournamentToCache(_ tournament: Tournament) async {
        let cached = CachedTournament(
            tournament: tournament,
            timestamp: Date(),
            version: 1
        )
        
        tournamentCache[tournament.id.uuidString] = cached
        
        // Update tournaments array
        if let index = tournaments.firstIndex(where: { $0.id == tournament.id }) {
            tournaments[index] = tournament
        } else {
            tournaments.append(tournament)
        }
        
        // Maintain cache size
        await maintainCacheSize()
        await saveToLocalCache()
    }
    
    private func updateTournamentsCache(_ newTournaments: [Tournament]) async {
        let timestamp = Date()
        
        for tournament in newTournaments {
            let cached = CachedTournament(
                tournament: tournament,
                timestamp: timestamp,
                version: 1
            )
            tournamentCache[tournament.id.uuidString] = cached
        }
        
        tournaments = newTournaments
        lastFetchTimestamp = timestamp
        
        await maintainCacheSize()
        await saveToLocalCache()
    }
    
    private func updateMyTournamentsCache(_ newTournaments: [Tournament]) async {
        let timestamp = Date()
        
        for tournament in newTournaments {
            let cached = CachedTournament(
                tournament: tournament,
                timestamp: timestamp,
                version: 1
            )
            myTournamentsCache[tournament.id.uuidString] = cached
        }
        
        myTournaments = newTournaments.sorted { tournament1, tournament2 in
            let priority1 = getStatusPriority(tournament1.status)
            let priority2 = getStatusPriority(tournament2.status)
            
            if priority1 != priority2 {
                return priority1 < priority2
            }
            
            return tournament1.startDate > tournament2.startDate
        }
        
        lastMyTournamentsFetch = timestamp
        await saveToLocalCache()
    }
    
    private func maintainCacheSize() async {
        if tournamentCache.count > Configuration.maxCacheSize {
            let sortedEntries = tournamentCache.sorted { $0.value.timestamp < $1.value.timestamp }
            let entriesToRemove = sortedEntries.prefix(tournamentCache.count - Configuration.maxCacheSize)
            
            for (key, _) in entriesToRemove {
                tournamentCache.removeValue(forKey: key)
            }
            
            print("🧹 Cache cleanup: removed \(entriesToRemove.count) old entries")
        }
    }
    
    private func refreshTournament(_ tournamentId: String) async {
        do {
            let updatedTournament = try await firebaseService.getTournament(id: tournamentId)
            await addTournamentToCache(updatedTournament)
        } catch {
            print("⚠️ Failed to refresh tournament \(tournamentId): \(error)")
        }
    }
    
    private func refreshActiveTournaments() async {
        let activeTournaments = tournaments.filter { tournament in
            tournament.status == "In Progress" || tournament.status == "Registration Open"
        }
        
        guard !activeTournaments.isEmpty else { return }
        
        print("🔄 Refreshing \(activeTournaments.count) active tournaments")
        
        for tournament in activeTournaments {
            await refreshTournament(tournament.id.uuidString)
        }
    }
    
    // MARK: - State Management
    
    private func setLoadingState(_ loading: Bool) async {
        isLoading = loading
    }
    
    private func setConnectionStatus(_ status: ConnectionStatus) async {
        connectionStatus = status
    }
    
    private func handleError(_ error: TournamentError) async {
        lastError = error
        print("❌ Tournament error: \(error.localizedDescription)")
        
        switch error {
        case .networkError:
            await setConnectionStatus(.error("Network error"))
        case .fetchFailed:
            await setConnectionStatus(.error("Fetch failed"))
        default:
            await setConnectionStatus(.error(error.localizedDescription))
        }
    }
    
    // MARK: - Local Persistence
    
    private func saveToLocalCache() async {
        let cacheData = CacheData(
            tournaments: tournaments,
            myTournaments: myTournaments,
            lastFetchTimestamp: lastFetchTimestamp,
            lastMyTournamentsFetch: lastMyTournamentsFetch
        )
        
        do {
            let data = try JSONEncoder().encode(cacheData)
            UserDefaults.standard.set(data, forKey: "tournamentServiceCache")
        } catch {
            print("⚠️ Failed to save cache: \(error)")
        }
    }
    
    private func loadFromLocalCache() {
        guard let data = UserDefaults.standard.data(forKey: "tournamentServiceCache") else { return }
        
        do {
            let cacheData = try JSONDecoder().decode(CacheData.self, from: data)
            tournaments = cacheData.tournaments
            myTournaments = cacheData.myTournaments
            lastFetchTimestamp = cacheData.lastFetchTimestamp
            lastMyTournamentsFetch = cacheData.lastMyTournamentsFetch
            
            print("📋 Loaded \(tournaments.count) tournaments from local cache")
        } catch {
            print("⚠️ Failed to load cache: \(error)")
        }
    }
    
    // MARK: - Performance Monitoring
    
    private func setupPerformanceMonitoring() {
        maintenanceTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.performMaintenanceTasks()
            }
        }
    }
    
    private func performMaintenanceTasks() async {
        // Clean expired cache entries
        let cutoffTime = Date().addingTimeInterval(-Configuration.cacheDuration)
        let originalCount = tournamentCache.count
        
        tournamentCache = tournamentCache.filter { $0.value.timestamp > cutoffTime }
        myTournamentsCache = myTournamentsCache.filter { $0.value.timestamp > cutoffTime }
        
        if tournamentCache.count < originalCount {
            print("🧹 Maintenance: cleaned \(originalCount - tournamentCache.count) expired cache entries")
        }
    }
    
    // MARK: - Utility Methods
    
    private func getStatusPriority(_ status: String) -> Int {
        switch status {
        case "In Progress": return 0
        case "Registration Open": return 1
        case "Registration Closed", "Upcoming": return 2
        case "Completed": return 3
        case "Cancelled": return 4
        default: return 5
        }
    }
    
    /// Determines the user's status within a specific tournament.
    func getUserTournamentStatus(user: User, tournament: Tournament) -> UserTournamentStatus {
        return tournamentService.getUserTournamentStatus(user: user, tournament: tournament)
    }
}

// MARK: - Supporting Types

private struct CacheData: Codable {
    let tournaments: [Tournament]
    let myTournaments: [Tournament]
    let lastFetchTimestamp: Date?
    let lastMyTournamentsFetch: Date?
}

// Note: TournamentError is defined in Tournament.swift to avoid duplication


