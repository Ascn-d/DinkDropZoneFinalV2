import Foundation
import Combine
import os.log

// MARK: - Realtime Matchmaking Service (Firebase-Connected)
final class RealtimeMatchmakingService: ObservableObject {
    
    // MARK: - Observable Properties
    @Published var currentProposal: MatchProposal?
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    // Queue state properties (synced with AppState)
    @Published var isInQueue: Bool = false
    @Published var queuePosition: Int = 0
    @Published var estimatedWaitTime: TimeInterval = 0
    
    // Reference to AppState for queue state management
    private weak var appState: AppState?
    
    // MARK: - Data Models
    struct MatchProposal: Identifiable, Codable {
        let id: String
        let player1Id: String
        let player2Id: String
        let player1Name: String
        let player2Name: String
        let matchType: String
        let createdAt: Date
        let expiresAt: Date
        var status: ProposalStatus = .pending
        
        enum ProposalStatus: String, Codable {
            case pending = "pending"
            case accepted = "accepted"
            case declined = "declined"
            case expired = "expired"
        }
    }
    
    enum ConnectionStatus {
        case connected
        case connecting
        case disconnected
        case error(String)
    }
    
    private let logger = Logger(subsystem: "DinkDropZone", category: "RealtimeMatchmaking")
    
    // Firebase service for real data
    private let firebaseService: FirebaseService = FirebaseService.shared
    
    // MARK: - Initialization
    init(appState: AppState? = nil) {
        self.appState = appState
        logger.info("RealtimeMatchmakingService initialized with Firebase connectivity")
    }
    
    // MARK: - Public Methods
    
    /// Join the realtime matchmaking queue
    @MainActor
    func joinQueue(userId: String, matchType: MatchType) async throws {
        guard let appState = appState else {
            throw MatchmakingError.noAppState
        }
        
        guard !appState.isInQueue else {
            throw MatchmakingError.alreadyInQueue
        }
        
        logger.info("Joining realtime queue for user: \(userId), match type: \(matchType.rawValue)")
        
        connectionStatus = .connecting
        
        // Simulate queue joining
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let position = Int.random(in: 1...5)
        let waitTime = TimeInterval(Int.random(in: 30...120))
        
        // Update both AppState and local properties
        appState.isInQueue = true
        appState.queuePosition = position
        appState.estimatedWaitTime = waitTime
        
        self.isInQueue = true
        self.queuePosition = position
        self.estimatedWaitTime = waitTime
        
        connectionStatus = .connected
        
        // Start queue simulation
        startQueueSimulation()
        
        logger.info("Successfully joined realtime queue")
    }
    
    /// Leave the realtime matchmaking queue
    @MainActor
    func leaveQueue() async throws {
        guard let appState = appState else {
            throw MatchmakingError.noAppState
        }
        
        guard appState.isInQueue else {
            throw MatchmakingError.noActiveQueue
        }
        
        logger.info("Leaving realtime queue")
        
        // Update both AppState and local properties
        appState.isInQueue = false
        appState.queuePosition = 0
        appState.estimatedWaitTime = 0
        
        self.isInQueue = false
        self.queuePosition = 0
        self.estimatedWaitTime = 0
        
        currentProposal = nil
        connectionStatus = .disconnected
        
        logger.info("Successfully left realtime queue")
    }
    
    /// Respond to a match proposal
    @MainActor
    func respondToProposal(_ response: String) async throws {
        guard let appState = appState else {
            throw MatchmakingError.noAppState
        }
        
        guard let proposal = currentProposal else {
            throw MatchmakingError.noActiveProposal
        }
        
        logger.info("Responding to proposal \(proposal.id): \(response)")
        
        var updatedProposal = proposal
        updatedProposal.status = response == "accept" ? .accepted : .declined
        currentProposal = updatedProposal
        
        if response == "accept" {
            // Match accepted - exit queue
            appState.isInQueue = false
            appState.queuePosition = 0
            appState.estimatedWaitTime = 0
            
            self.isInQueue = false
            self.queuePosition = 0
            self.estimatedWaitTime = 0
            
            logger.info("Match proposal accepted - exiting queue")
            
            // Simulate match start
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            currentProposal = nil
            
        } else {
            // Match declined - stay in queue
            currentProposal = nil
            logger.info("Match proposal declined - staying in queue")
        }
    }
    
    // MARK: - Private Methods
    
    private func startQueueSimulation() {
        // Simulate queue position updates
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] timer in
            guard let self = self, let appState = self.appState else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                // Check if still in queue
                guard appState.isInQueue else {
                    timer.invalidate()
                    return
                }
                
                // Update queue position in both AppState and local properties
                let newPosition = max(1, appState.queuePosition - 1)
                let newWaitTime = max(15, appState.estimatedWaitTime - 10)
                
                appState.queuePosition = newPosition
                appState.estimatedWaitTime = newWaitTime
                
                self.queuePosition = newPosition
                self.estimatedWaitTime = newWaitTime
                
                // Check for potential matches with real users
                if Int.random(in: 1...100) <= 20 { // 20% chance every 10 seconds
                    await self.findAndCreateMatchProposal()
                }
            }
        }
    }
    
    @MainActor
    private func findAndCreateMatchProposal() async {
        guard let appState = appState, appState.isInQueue, currentProposal == nil else { return }
        guard let currentUser = appState.currentUser else { return }
        
        do {
            // Find nearby users or users in queue from Firebase
            let allUsers = try await firebaseService.getGlobalLeaderboard(limit: 100)
            
            // Filter for potential opponents (excluding current user)
            let potentialOpponents = allUsers.filter { user in
                user.id != currentUser.id && 
                abs(user.elo - currentUser.elo) <= 200 // Similar skill level
            }
            
            guard let randomOpponent = potentialOpponents.randomElement() else {
                logger.info("No suitable opponents found for match proposal")
                return
            }
            
            let proposal = MatchProposal(
                id: UUID().uuidString,
                player1Id: currentUser.id.uuidString,
                player2Id: randomOpponent.id.uuidString,
                player1Name: currentUser.displayName.isEmpty ? currentUser.email : currentUser.displayName,
                player2Name: randomOpponent.displayName.isEmpty ? randomOpponent.email : randomOpponent.displayName,
                matchType: "singles",
                createdAt: Date(),
                expiresAt: Date().addingTimeInterval(30) // 30 seconds to respond
            )
            
            currentProposal = proposal
            
            logger.info("Created real match proposal with \(randomOpponent.displayName)")
            
            // Auto-expire proposal after 30 seconds
            Task {
                try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                if let current = currentProposal, current.id == proposal.id {
                    var expired = current
                    expired.status = .expired
                    currentProposal = nil
                    logger.info("Match proposal expired")
                }
            }
            
        } catch {
            logger.error("Failed to create real match proposal: \(error)")
        }
    }
}

// MARK: - MatchmakingError
enum MatchmakingError: LocalizedError {
    case alreadyInQueue
    case noActiveQueue
    case noActiveProposal
    case noAppState
    case notAuthenticated
    case networkError(Error)
    case serviceInitializationFailed
    
    var errorDescription: String? {
        switch self {
        case .alreadyInQueue:
            return "Already in matchmaking queue"
        case .noActiveQueue:
            return "Not currently in queue"
        case .noActiveProposal:
            return "No active match proposal"
        case .noAppState:
            return "AppState reference not available"
        case .notAuthenticated:
            return "User not authenticated"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serviceInitializationFailed:
            return "Failed to initialize matchmaking service"
        }
    }
} 