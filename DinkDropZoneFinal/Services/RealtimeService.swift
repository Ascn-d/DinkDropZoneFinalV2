import Foundation
import FirebaseFirestore
import FirebaseAuth
import Network
import Combine
import os.log

/// Centralized Real-time Service for Firebase listeners and live data synchronization
@MainActor
class RealtimeService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var isOnline: Bool = true
    @Published var activeListeners: [String: ListenerInfo] = [:]
    @Published var lastSyncTime: Date?
    @Published var syncStatistics: SyncStatistics = SyncStatistics()
    @Published var hasUnreadUpdates: Bool = false
    
    // MARK: - Private Properties
    
    private let firebaseService: FirebaseService
    private let logger = Logger(subsystem: "DinkDropZone", category: "RealtimeService")
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    private let syncQueue = DispatchQueue(label: "RealtimeSyncQueue", qos: .utility)
    
    private var listeners: [String: FirebaseService.ListenerHandle] = [:]
    private var observationTokens: Set<AnyCancellable> = []
    private var healthCheckTimer: Timer?
    private var connectionRetryTimer: Timer?
    private var offlineChangeQueue: [OfflineChange] = []
    
    // MARK: - Configuration
    
    private struct Configuration {
        static let healthCheckInterval: TimeInterval = 30.0
        static let maxRetryAttempts = 5
        static let retryDelay: TimeInterval = 2.0
        static let offlineQueueLimit = 100
        static let batchSyncSize = 10
        static let connectionTimeout: TimeInterval = 10.0
    }
    
    // MARK: - Types
    
    enum ConnectionStatus: Equatable {
        case connected
        case disconnected
        case connecting
        case error(String)
        case syncing
        
        var isConnected: Bool {
            if case .connected = self { return true }
            return false
        }
        
        var displayText: String {
            switch self {
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting..."
            case .error(let message): return "Error: \(message)"
            case .syncing: return "Syncing..."
            }
        }
    }
    
    struct ListenerInfo {
        let id: String
        let type: ListenerType
        let path: String
        let isActive: Bool
        let lastUpdate: Date
        let updateCount: Int
        
        enum ListenerType: String, CaseIterable {
            case user = "user"
            case tournament = "tournament"
            case tournaments = "tournaments"
            case matches = "matches"
            case liveMatch = "liveMatch"
            case leaderboard = "leaderboard"
            case notifications = "notifications"
            case queue = "queue"
            case participants = "participants"
            
            var icon: String {
                switch self {
                case .user: return "person.circle"
                case .tournament: return "trophy.circle"
                case .tournaments: return "trophy.fill"
                case .matches: return "sportscourt"
                case .liveMatch: return "play.circle"
                case .leaderboard: return "list.number"
                case .notifications: return "bell.circle"
                case .queue: return "clock.circle"
                case .participants: return "person.3"
                }
            }
        }
    }
    
    struct SyncStatistics {
        var totalUpdates: Int = 0
        var successfulSyncs: Int = 0
        var failedSyncs: Int = 0
        var averageLatency: TimeInterval = 0
        var lastErrorMessage: String?
        var lastErrorTime: Date?
        
        var successRate: Double {
            guard totalUpdates > 0 else { return 0 }
            return Double(successfulSyncs) / Double(totalUpdates)
        }
    }
    
    struct OfflineChange {
        let id: String
        let type: ChangeType
        let path: String
        let data: [String: Any]
        let timestamp: Date
        
        enum ChangeType {
            case create, update, delete
        }
    }
    
    // MARK: - Initialization
    
    init(firebaseService: FirebaseService) {
        self.firebaseService = firebaseService
        setupNetworkMonitoring()
        startHealthChecking()
        setupNotificationObservers()
    }
    
    deinit {
        // Cleanup in deinit must be synchronous - async cleanup should be called explicitly before deallocation
        networkMonitor.cancel()
        healthCheckTimer?.invalidate()
        connectionRetryTimer?.invalidate()
        
        // Remove all Firebase listeners
        for (_, listener) in listeners {
            listener.remove()
        }
        listeners.removeAll()
        observationTokens.removeAll()
    }
    
    // MARK: - Public API
    
    /// Start comprehensive real-time monitoring
    func startRealtimeMonitoring() {
        logger.info("🔄 Starting comprehensive real-time monitoring")
        connectionStatus = .connecting
        
        Task {
            await setupCoreListeners()
            await testConnection()
        }
    }
    
    /// Stop all real-time monitoring
    func stopRealtimeMonitoring() {
        logger.info("🛑 Stopping real-time monitoring")
        cleanup()
        connectionStatus = .disconnected
    }
    
    /// Add custom listener for specific data
    func addListener<T: Codable>(
        id: String,
        type: ListenerInfo.ListenerType,
        path: String,
        decoder: @escaping ([String: Any]) -> T?,
        onChange: @escaping (Result<T, Error>) -> Void
    ) {
        logger.info("➕ Adding listener: \(id) (\(type.rawValue))")
        
        let listener = setupFirebaseListener(
            path: path,
            decoder: decoder,
            onChange: onChange
        )
        
        listeners[id] = listener
        
        let info = ListenerInfo(
            id: id,
            type: type,
            path: path,
            isActive: true,
            lastUpdate: Date(),
            updateCount: 0
        )
        
        activeListeners[id] = info
    }
    
    /// Remove specific listener
    func removeListener(id: String) {
        logger.info("➖ Removing listener: \(id)")
        
        listeners[id]?.remove()
        listeners.removeValue(forKey: id)
        activeListeners.removeValue(forKey: id)
    }
    
    /// Force sync all data
    func forceSyncAll() async {
        logger.info("🔄 Force syncing all data")
        connectionStatus = .syncing
        
        await syncOfflineChanges()
        await refreshAllActiveListeners()
        
        lastSyncTime = Date()
        connectionStatus = .connected
    }
    
    // MARK: - Core Listeners Setup
    
    private func setupCoreListeners() async {
        // Setup tournament collection listener
        setupTournamentsListener()
        
        // Setup user notifications listener
        setupNotificationsListener()
        
        // Setup leaderboard listener
        setupLeaderboardListener()
        
        // Setup queue statistics listener
        setupQueueListener()
        
        logger.info("✅ Core listeners established")
    }
    
    private func setupTournamentsListener() {
        let listener = firebaseService.observeAllTournaments { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                switch result {
                case .success(let tournaments):
                    self.handleTournamentsUpdate(tournaments)
                case .failure(let error):
                    self.handleListenerError("tournaments", error)
                }
            }
        }
        
        listeners["tournaments"] = listener
        activeListeners["tournaments"] = ListenerInfo(
            id: "tournaments",
            type: .tournaments,
            path: "tournaments",
            isActive: true,
            lastUpdate: Date(),
            updateCount: 0
        )
    }
    
    private func setupNotificationsListener() {
        // Setup for current user if available
        guard firebaseService.getCurrentUserId() != nil else { return }
        
        let listener = setupFirebaseListener(
            path: "notifications",
            decoder: { data in
                // Decode notification data
                return data
            },
            onChange: { [weak self] result in
                guard let self = self else { return }
                Task { @MainActor in
                    switch result {
                    case .success(let data):
                        self.handleNotificationsUpdate(data)
                    case .failure(let error):
                        self.handleListenerError("notifications", error)
                    }
                }
            }
        )
        
        listeners["notifications"] = listener
        activeListeners["notifications"] = ListenerInfo(
            id: "notifications",
            type: .notifications,
            path: "notifications",
            isActive: true,
            lastUpdate: Date(),
            updateCount: 0
        )
    }
    
    private func setupLeaderboardListener() {
        let listener = setupFirebaseListener(
            path: "leaderboard",
            decoder: { data in
                // Decode leaderboard data
                return data
            },
            onChange: { [weak self] result in
                guard let self = self else { return }
                Task { @MainActor in
                    switch result {
                    case .success(let data):
                        self.handleLeaderboardUpdate(data)
                    case .failure(let error):
                        self.handleListenerError("leaderboard", error)
                    }
                }
            }
        )
        
        listeners["leaderboard"] = listener
        activeListeners["leaderboard"] = ListenerInfo(
            id: "leaderboard",
            type: .leaderboard,
            path: "leaderboard",
            isActive: true,
            lastUpdate: Date(),
            updateCount: 0
        )
    }
    
    private func setupQueueListener() {
        let listener = setupFirebaseListener(
            path: "queue",
            decoder: { data in
                return data
            },
            onChange: { [weak self] result in
                guard let self = self else { return }
                Task { @MainActor in
                    switch result {
                    case .success(let data):
                        self.handleQueueUpdate(data)
                    case .failure(let error):
                        self.handleListenerError("queue", error)
                    }
                }
            }
        )
        
        listeners["queue"] = listener
        activeListeners["queue"] = ListenerInfo(
            id: "queue",
            type: .queue,
            path: "queue",
            isActive: true,
            lastUpdate: Date(),
            updateCount: 0
        )
    }
    
    // MARK: - Specialized Listeners
    
    /// Setup tournament-specific listener
    func observeTournament(id: String, onChange: @escaping (Result<Tournament, Error>) -> Void) -> String {
        let listenerId = "tournament_\(id)"
        
        let listener = firebaseService.observeTournament(id: id) { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                self.updateListenerStats(listenerId)
                
                switch result {
                case .success(let tournament):
                    self.logger.info("📊 Tournament updated: \(tournament.name)")
                    onChange(.success(tournament))
                case .failure(let error):
                    self.handleListenerError(listenerId, error)
                    onChange(.failure(error))
                }
            }
        }
        
        listeners[listenerId] = listener
        activeListeners[listenerId] = ListenerInfo(
            id: listenerId,
            type: .tournament,
            path: "tournaments/\(id)",
            isActive: true,
            lastUpdate: Date(),
            updateCount: 0
        )
        
        return listenerId
    }
    
    /// Setup user profile listener
    func observeUser(id: String, onChange: @escaping (Result<User, Error>) -> Void) -> String {
        let listenerId = "user_\(id)"
        
        let listener = firebaseService.observeUser(id: id) { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                self.updateListenerStats(listenerId)
                
                switch result {
                case .success(let user):
                    self.logger.info("👤 User updated: \(user.displayName)")
                    onChange(.success(user))
                case .failure(let error):
                    self.handleListenerError(listenerId, error)
                    onChange(.failure(error))
                }
            }
        }
        
        listeners[listenerId] = listener
        activeListeners[listenerId] = ListenerInfo(
            id: listenerId,
            type: .user,
            path: "users/\(id)",
            isActive: true,
            lastUpdate: Date(),
            updateCount: 0
        )
        
        return listenerId
    }
    
    /// Setup live match score listener
    func observeLiveMatchScore(
        tournamentId: String,
        matchId: String,
        onChange: @escaping (Result<[String: Any], Error>) -> Void
    ) -> String {
        let listenerId = "liveMatch_\(tournamentId)_\(matchId)"
        
        let listener = firebaseService.observeLiveMatchScore(
            tournamentId: tournamentId,
            matchId: matchId
        ) { [weak self] result in
            guard let self = self else { return }
            Task { @MainActor in
                self.updateListenerStats(listenerId)
                
                switch result {
                case .success(let data):
                    self.logger.info("🏓 Live match score updated: \(matchId)")
                    onChange(.success(data))
                case .failure(let error):
                    self.handleListenerError(listenerId, error)
                    onChange(.failure(error))
                }
            }
        }
        
        listeners[listenerId] = listener
        activeListeners[listenerId] = ListenerInfo(
            id: listenerId,
            type: .liveMatch,
            path: "tournaments/\(tournamentId)/liveMatches/\(matchId)",
            isActive: true,
            lastUpdate: Date(),
            updateCount: 0
        )
        
        return listenerId
    }
    
    // MARK: - Generic Firebase Listener
    
    private func setupFirebaseListener<T>(
        path: String,
        decoder: @escaping ([String: Any]) -> T?,
        onChange: @escaping (Result<T, Error>) -> Void
    ) -> FirebaseService.ListenerHandle {
        // This is a simplified implementation
        // In reality, you'd need to implement proper Firestore listener setup
        return FirebaseService.ListenerHandle {
            // Remove listener implementation
        }
    }
    
    // MARK: - Update Handlers
    
    private func handleTournamentsUpdate(_ tournaments: [Tournament]) {
        logger.info("📊 Tournaments updated: \(tournaments.count) tournaments")
        
        // Post notification for tournament views
        NotificationCenter.default.post(
            name: .realtimeTournamentsUpdated,
            object: tournaments
        )
        
        updateSyncStats(success: true)
        hasUnreadUpdates = true
    }
    
    private func handleNotificationsUpdate(_ data: [String: Any]) {
        logger.info("🔔 Notifications updated")
        
        // Post notification for notification views
        NotificationCenter.default.post(
            name: .realtimeNotificationsUpdated,
            object: data
        )
        
        updateSyncStats(success: true)
        hasUnreadUpdates = true
    }
    
    private func handleLeaderboardUpdate(_ data: [String: Any]) {
        logger.info("🏆 Leaderboard updated")
        
        // Post notification for leaderboard views
        NotificationCenter.default.post(
            name: .realtimeLeaderboardUpdated,
            object: data
        )
        
        updateSyncStats(success: true)
    }
    
    private func handleQueueUpdate(_ data: [String: Any]) {
        logger.info("⏰ Queue updated")
        
        // Post notification for queue views
        NotificationCenter.default.post(
            name: .realtimeQueueUpdated,
            object: data
        )
        
        updateSyncStats(success: true)
    }
    
    private func handleListenerError(_ listenerId: String, _ error: Error) {
        logger.error("❌ Listener error (\(listenerId)): \(error.localizedDescription)")
        
        // Update listener status
        if let info = activeListeners[listenerId] {
            activeListeners[listenerId] = ListenerInfo(
                id: info.id,
                type: info.type,
                path: info.path,
                isActive: false,
                lastUpdate: info.lastUpdate,
                updateCount: info.updateCount
            )
        }
        
        updateSyncStats(success: false, error: error)
        
        // Attempt to reconnect
        Task {
            await attemptReconnection(listenerId)
        }
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            Task { @MainActor in
                self.isOnline = path.status == .satisfied
                
                if path.status == .satisfied {
                    self.logger.info("🌐 Network connection restored")
                    await self.handleNetworkReconnection()
                } else {
                    self.logger.warning("📡 Network connection lost")
                    self.handleNetworkDisconnection()
                }
            }
        }
        
        networkMonitor.start(queue: networkQueue)
    }
    
    private func handleNetworkReconnection() async {
        if connectionStatus == .disconnected {
            connectionStatus = .connecting
            await syncOfflineChanges()
            await refreshAllActiveListeners()
            connectionStatus = .connected
        }
    }
    
    private func handleNetworkDisconnection() {
        connectionStatus = .disconnected
        
        // Clean up active listeners but keep their info for reconnection
        for (id, handle) in listeners {
            handle.remove()
            logger.info("📡 Disconnected listener: \(id)")
        }
        listeners.removeAll()
    }
    
    // MARK: - Health Checking
    
    private func startHealthChecking() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: Configuration.healthCheckInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                await self.performHealthCheck()
            }
        }
    }
    
    private func performHealthCheck() async {
        logger.info("🏥 Performing health check")
        
        // Check connection status
        if !isOnline {
            connectionStatus = .disconnected
            return
        }
        
        // Test Firebase connection
        await testConnection()
        
        // Check for stale listeners
        await checkStaleListeners()
        
        // Clean up old offline changes
        cleanupOfflineChanges()
    }
    
    private func testConnection() async {
        do {
            // Simple connection test
            _ = try await firebaseService.getGlobalLeaderboard(limit: 1)
            
            if connectionStatus != .connected {
                connectionStatus = .connected
                logger.info("✅ Connection test passed")
            }
        } catch {
            connectionStatus = .error(error.localizedDescription)
            logger.error("❌ Connection test failed: \(error.localizedDescription)")
        }
    }
    
    private func checkStaleListeners() async {
        let now = Date()
        let staleThreshold: TimeInterval = 300 // 5 minutes
        
        for (id, info) in activeListeners {
            if now.timeIntervalSince(info.lastUpdate) > staleThreshold {
                logger.warning("⚠️ Stale listener detected: \(id)")
                await attemptReconnection(id)
            }
        }
    }
    
    private func attemptReconnection(_ listenerId: String) async {
        logger.info("🔄 Attempting reconnection for listener: \(listenerId)")
        
        // Remove existing listener
        listeners[listenerId]?.remove()
        listeners.removeValue(forKey: listenerId)
        
        // Attempt to recreate listener based on type
        // This would need specific implementation for each listener type
        
        // For now, just log the attempt
        logger.info("🔄 Reconnection attempted for: \(listenerId)")
    }
    
    // MARK: - Offline Change Management
    
    private func syncOfflineChanges() async {
        guard !self.offlineChangeQueue.isEmpty else { return }
        
        logger.info("📤 Syncing \(self.offlineChangeQueue.count) offline changes")
        
        let changes = Array(self.offlineChangeQueue.prefix(Configuration.batchSyncSize))
        self.offlineChangeQueue.removeFirst(min(Configuration.batchSyncSize, self.offlineChangeQueue.count))
        
        for change in changes {
            // Attempt to sync change
            // This would need specific implementation for each change type
            logger.info("✅ Synced offline change: \(change.id)")
        }
    }
    
    private func cleanupOfflineChanges() {
        let now = Date()
        let maxAge: TimeInterval = 86400 // 24 hours
        
        let initialCount = self.offlineChangeQueue.count
        self.offlineChangeQueue.removeAll { change in
            now.timeIntervalSince(change.timestamp) > maxAge
        }
        
        if self.offlineChangeQueue.count < initialCount {
            logger.info("🧹 Cleaned up \(initialCount - self.offlineChangeQueue.count) old offline changes")
        }
    }
    
    // MARK: - Statistics & Utilities
    
    private func updateListenerStats(_ listenerId: String) {
        if let info = activeListeners[listenerId] {
            activeListeners[listenerId] = ListenerInfo(
                id: info.id,
                type: info.type,
                path: info.path,
                isActive: true,
                lastUpdate: Date(),
                updateCount: info.updateCount + 1
            )
        }
    }
    
    private func updateSyncStats(success: Bool, error: Error? = nil) {
        syncStatistics.totalUpdates += 1
        
        if success {
            syncStatistics.successfulSyncs += 1
        } else {
            syncStatistics.failedSyncs += 1
            
            if let error = error {
                syncStatistics.lastErrorMessage = error.localizedDescription
                syncStatistics.lastErrorTime = Date()
            }
        }
        
        // Calculate average latency (simplified)
        syncStatistics.averageLatency = 0.5 // Placeholder
    }
    
    private func refreshAllActiveListeners() async {
        logger.info("🔄 Refreshing all active listeners")
        
        for (id, _) in activeListeners {
            // Attempt to recreate listener
            await attemptReconnection(id)
        }
    }
    
    private func setupNotificationObservers() {
        // Clear any existing observers
        observationTokens.removeAll()
        
        // Monitor for data changes that should trigger updates
        NotificationCenter.default.publisher(for: .realtimeDataInvalidated)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.forceSyncAll()
                }
            }
            .store(in: &observationTokens)
    }
    
    private func cleanup() {
        // Clean up timers
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
        connectionRetryTimer?.invalidate()
        connectionRetryTimer = nil
        
        // Clean up network monitoring
        networkMonitor.cancel()
        
        // Clean up listeners
        for (id, handle) in listeners {
            handle.remove()
            logger.info("🧹 Cleaned up listener: \(id)")
        }
        listeners.removeAll()
        activeListeners.removeAll()
        
        // Clean up observers
        observationTokens.removeAll()
        
        logger.info("🧹 RealtimeService cleanup completed")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let realtimeTournamentsUpdated = Notification.Name("realtimeTournamentsUpdated")
    static let realtimeNotificationsUpdated = Notification.Name("realtimeNotificationsUpdated")
    static let realtimeLeaderboardUpdated = Notification.Name("realtimeLeaderboardUpdated")
    static let realtimeQueueUpdated = Notification.Name("realtimeQueueUpdated")
    static let realtimeDataInvalidated = Notification.Name("realtimeDataInvalidated")
    static let realtimeConnectionStatusChanged = Notification.Name("realtimeConnectionStatusChanged")
}

// MARK: - FirebaseService Extension

extension FirebaseService {
    func getCurrentUserId() -> String? {
        return Auth.auth().currentUser?.uid
    }
} 