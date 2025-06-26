import Foundation
import Combine
import os.log

// MARK: - Simplified Realtime Matchmaking Service (No Firebase Dependencies)
final class RealtimeMatchmakingService: ObservableObject {
    
    // MARK: - Observable Properties
    @Published var isInQueue: Bool = false
    @Published var queuePosition: Int = 0
    @Published var estimatedWaitTime: TimeInterval = 0
    @Published var currentProposal: MatchProposal?
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
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
    
    // MARK: - Mock Data
    private var mockUsers: [MockUser] = [
        MockUser(id: "user1", name: "Alex Johnson", elo: 1200),
        MockUser(id: "user2", name: "Sarah Chen", elo: 1180),
        MockUser(id: "user3", name: "Mike Wilson", elo: 1220),
        MockUser(id: "user4", name: "Emma Davis", elo: 1150)
    ]
    
    struct MockUser {
        let id: String
        let name: String
        let elo: Int
    }
    
    // MARK: - Initialization
    init() {
        logger.info("RealtimeMatchmakingService initialized (simplified version)")
    }
    
    // MARK: - Public Methods
    
    /// Join the realtime matchmaking queue
    @MainActor
    func joinQueue(userId: String, matchType: MatchType) async throws {
        guard !isInQueue else {
            throw MatchmakingError.alreadyInQueue
        }
        
        logger.info("Joining realtime queue for user: \(userId), match type: \(matchType.rawValue)")
        
        connectionStatus = .connecting
        
        // Simulate queue joining
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        isInQueue = true
        queuePosition = Int.random(in: 1...5)
        estimatedWaitTime = TimeInterval(Int.random(in: 30...120))
        connectionStatus = .connected
        
        // Start queue simulation
        startQueueSimulation()
        
        logger.info("Successfully joined realtime queue")
    }
    
    /// Leave the realtime matchmaking queue
    @MainActor
    func leaveQueue() async throws {
        guard isInQueue else {
            throw MatchmakingError.noActiveQueue
        }
        
        logger.info("Leaving realtime queue")
        
        isInQueue = false
        queuePosition = 0
        estimatedWaitTime = 0
        currentProposal = nil
        connectionStatus = .disconnected
        
        logger.info("Successfully left realtime queue")
    }
    
    /// Respond to a match proposal
    @MainActor
    func respondToProposal(_ response: String) async throws {
        guard let proposal = currentProposal else {
            throw MatchmakingError.noActiveProposal
        }
        
        logger.info("Responding to proposal \(proposal.id): \(response)")
        
        var updatedProposal = proposal
        updatedProposal.status = response == "accept" ? .accepted : .declined
        currentProposal = updatedProposal
        
        if response == "accept" {
            // Match accepted - exit queue
            isInQueue = false
            queuePosition = 0
            estimatedWaitTime = 0
            
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
            guard let self = self, self.isInQueue else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                // Update queue position
                self.queuePosition = max(1, self.queuePosition - 1)
                self.estimatedWaitTime = max(15, self.estimatedWaitTime - 10)
                
                // Randomly create match proposals
                if Int.random(in: 1...100) <= 20 { // 20% chance every 10 seconds
                    await self.createMockMatchProposal()
                }
            }
        }
    }
    
    private func createMockMatchProposal() async {
        guard isInQueue, currentProposal == nil else { return }
        
        let randomOpponent = mockUsers.randomElement()!
        
        let proposal = MatchProposal(
            id: UUID().uuidString,
            player1Id: "current_user",
            player2Id: randomOpponent.id,
            player1Name: "You",
            player2Name: randomOpponent.name,
            matchType: "singles",
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(30) // 30 seconds to respond
        )
        
        currentProposal = proposal
        
        logger.info("Created mock match proposal with \(randomOpponent.name)")
        
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
    }
}

// MARK: - MatchmakingError
enum MatchmakingError: LocalizedError {
    case alreadyInQueue
    case noActiveQueue
    case noActiveProposal
    case notAuthenticated
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .alreadyInQueue:
            return "Already in matchmaking queue"
        case .noActiveQueue:
            return "Not currently in queue"
        case .noActiveProposal:
            return "No active match proposal"
        case .notAuthenticated:
            return "User not authenticated"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
} 