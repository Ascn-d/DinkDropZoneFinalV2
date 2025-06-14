import Foundation
import Observation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class MatchmakingService {
    
    // MARK: - Properties
    
    private var modelContext: ModelContext
    private var queueTimer: Timer?
    private var estimatedWaitTimes: [MatchType: TimeInterval] = [:]
    
    // Queue state
    var activeQueues: [MatchType: MatchQueue] = [:]
    var isInQueue: Bool = false
    var currentQueueType: MatchType?
    var queuePosition: Int = 0
    var estimatedWaitTime: TimeInterval = 0
    
    // Matchmaking state
    var matchProposal: MatchProposal?
    var isMatchmaking: Bool = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        initializeQueues()
        startQueueTimer()
    }
    
    deinit {}
    
    // MARK: - Queue Management
    
    func joinQueue(user: User, matchType: MatchType) async {
        // Prevent joining multiple queues
        if isInQueue {
            await leaveCurrentQueue()
        }
        
        // Add user to queue
        if activeQueues[matchType] == nil {
            activeQueues[matchType] = MatchQueue(type: matchType)
        }
        
        let queueEntry = QueueEntry(
            user: user,
            joinTime: Date(),
            preferredMatchType: matchType,
            eloRange: calculateEloRange(for: user.elo, matchType: matchType)
        )
        
        activeQueues[matchType]?.addUser(queueEntry)
        
        // Update user state
        isInQueue = true
        currentQueueType = matchType
        updateQueuePosition()
        
        LoggingService.shared.log("User \(user.displayName) joined \(matchType.rawValue) queue")
        
        // Start matchmaking process
        await attemptMatchmaking(for: matchType)
    }
    
    func leaveCurrentQueue() async {
        guard let queueType = currentQueueType,
              let queue = activeQueues[queueType] else { return }
        
        // Remove user from queue
        queue.removeCurrentUser()
        
        // Reset state
        isInQueue = false
        currentQueueType = nil
        queuePosition = 0
        estimatedWaitTime = 0
        matchProposal = nil
        isMatchmaking = false
        
        LoggingService.shared.log("User left \(queueType.rawValue) queue")
    }
    
    // MARK: - Matchmaking Logic
    
    private func attemptMatchmaking(for matchType: MatchType) async {
        guard let queue = activeQueues[matchType] else { return }
        
        isMatchmaking = true
        
        // Find potential matches
        let matches = findPotentialMatches(in: queue, for: matchType)
        
        if let bestMatch = matches.first {
            await proposeMatch(bestMatch)
        }
        
        isMatchmaking = false
    }
    
    private func findPotentialMatches(in queue: MatchQueue, for matchType: MatchType) -> [PotentialMatch] {
        var potentialMatches: [PotentialMatch] = []
        let entries = queue.entries
        
        switch matchType {
        case .singles:
            // Find 1v1 matches
            for i in 0..<entries.count {
                for j in (i+1)..<entries.count {
                    let match = PotentialMatch(
                        players: [entries[i], entries[j]],
                        matchType: matchType,
                        compatibility: calculateCompatibility(entries[i], entries[j])
                    )
                    potentialMatches.append(match)
                }
            }
            
        case .doubles:
            // Find 2v2 matches (4 players total)
            if entries.count >= 4 {
                // Simple implementation: take first 4 players
                // In reality, you'd want more sophisticated team balancing
                let match = PotentialMatch(
                    players: Array(entries.prefix(4)),
                    matchType: matchType,
                    compatibility: calculateTeamCompatibility(Array(entries.prefix(4)))
                )
                potentialMatches.append(match)
            }
            
        case .practice:
            // More lenient matching for practice
            for i in 0..<entries.count {
                for j in (i+1)..<entries.count {
                    let match = PotentialMatch(
                        players: [entries[i], entries[j]],
                        matchType: matchType,
                        compatibility: calculatePracticeCompatibility(entries[i], entries[j])
                    )
                    potentialMatches.append(match)
                }
            }
            
        case .tournament:
            // Tournament-specific logic would go here
            break
        default:
            break
        }
        
        // Sort by compatibility (highest first)
        return potentialMatches.sorted { $0.compatibility > $1.compatibility }
    }
    
    private func proposeMatch(_ potentialMatch: PotentialMatch) async {
        let proposal = MatchProposal(
            id: UUID(),
            potentialMatch: potentialMatch,
            proposedAt: Date(),
            expiresAt: Date().addingTimeInterval(30), // 30 second timeout
            responses: [:]
        )
        
        matchProposal = proposal
        
        LoggingService.shared.log("Match proposed for \(potentialMatch.players.count) players")
        
        // In a real app, you'd send push notifications to all players
        // For now, we'll simulate acceptance after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            Task {
                await self.simulateMatchAcceptance()
            }
        }
    }
    
    private func simulateMatchAcceptance() async {
        guard let proposal = matchProposal else { return }
        
        // Simulate all players accepting
        var responses = proposal.responses
        for player in proposal.potentialMatch.players {
            responses[player.user.id.uuidString] = .accepted
        }
        
        if responses.values.allSatisfy({ $0 == .accepted }) {
            await createMatchFromProposal(proposal)
        }
    }
    
    private func createMatchFromProposal(_ proposal: MatchProposal) async {
        let players = proposal.potentialMatch.players.map { $0.user }
        
        // Remove players from queue
        if let queueType = currentQueueType {
            for player in players {
                activeQueues[queueType]?.removeUser(player)
            }
        }
        
        // Create match
        let match = createMatch(players: players, type: proposal.potentialMatch.matchType)
        
        // Clear proposal
        matchProposal = nil
        
        // Reset queue state for current user
        isInQueue = false
        currentQueueType = nil
        queuePosition = 0
        
        LoggingService.shared.log("Match created with \(players.count) players")
        
        // Notify about match creation
        NotificationCenter.default.post(
            name: .matchCreated,
            object: match,
            userInfo: ["players": players]
        )
    }
    
    // MARK: - Compatibility Calculations
    
    private func calculateCompatibility(_ player1: QueueEntry, _ player2: QueueEntry) -> Double {
        let eloWeight = 0.6
        let waitTimeWeight = 0.3
        let regionWeight = 0.1
        
        // ELO compatibility (closer is better)
        let eloDiff = abs(player1.user.elo - player2.user.elo)
        let eloCompatibility = max(0, 1.0 - Double(eloDiff) / 500.0)
        
        // Wait time factor (longer wait = more lenient matching)
        let avgWaitTime = (player1.waitTime + player2.waitTime) / 2
        let waitTimeFactor = min(1.0, avgWaitTime / 300) // Max bonus after 5 minutes
        
        // Region compatibility (simplified)
        let regionCompatibility = player1.user.location == player2.user.location ? 1.0 : 0.8
        
        return (eloCompatibility * eloWeight) + 
               (waitTimeFactor * waitTimeWeight) + 
               (regionCompatibility * regionWeight)
    }
    
    private func calculateTeamCompatibility(_ players: [QueueEntry]) -> Double {
        guard players.count == 4 else { return 0 }
        
        // Calculate team balance
        let eloSum1 = players[0].user.elo + players[1].user.elo
        let eloSum2 = players[2].user.elo + players[3].user.elo
        let teamBalance = 1.0 - (Double(abs(eloSum1 - eloSum2)) / 1000.0)
        
        return max(0, teamBalance)
    }
    
    private func calculatePracticeCompatibility(_ player1: QueueEntry, _ player2: QueueEntry) -> Double {
        // More lenient for practice matches
        return calculateCompatibility(player1, player2) * 0.7 + 0.3
    }
    
    // MARK: - Helper Methods
    
    private func initializeQueues() {
        for matchType in MatchType.allCases {
            activeQueues[matchType] = MatchQueue(type: matchType)
            estimatedWaitTimes[matchType] = calculateBaseWaitTime(for: matchType)
        }
    }
    
    private func calculateBaseWaitTime(for matchType: MatchType) -> TimeInterval {
        switch matchType {
        case .singles: return 120 // 2 minutes
        case .doubles: return 180 // 3 minutes
        case .practice: return 60  // 1 minute
        case .tournament: return 300 // 5 minutes
        default: return 0
        }
    }
    
    private func calculateEloRange(for elo: Int, matchType: MatchType) -> ClosedRange<Int> {
        let tolerance = matchType == .practice ? 300 : 150
        return (elo - tolerance)...(elo + tolerance)
    }
    
    private func updateQueuePosition() {
        guard let queueType = currentQueueType,
              let queue = activeQueues[queueType] else { return }
        
        queuePosition = queue.entries.count
        estimatedWaitTime = estimatedWaitTimes[queueType] ?? 120
    }
    
    private func startQueueTimer() {
        queueTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            Task { @MainActor in
                await self.updateQueueStatus()
            }
        }
    }
    
    private func updateQueueStatus() async {
        // Update wait times and attempt new matches
        for (matchType, queue) in activeQueues {
            if !queue.entries.isEmpty {
                await attemptMatchmaking(for: matchType)
            }
        }
    }
    
    private func createMatch(players: [User], type: MatchType) -> Match {
        return Match(
            player1: players[0],
            player2: players.count > 1 ? players[1] : players[0],
            player1Score: 0,
            player2Score: 0,
            eloChange: "TBD"
        )
    }
    
    // MARK: - Public Response Handling
    func respondToMatchProposal(response: MatchResponse, for user: User) async {
        guard var proposal = matchProposal else { return }
        // Record response
        proposal.responses[user.id.uuidString] = response
        matchProposal = proposal
        
        LoggingService.shared.log("User \(user.displayName) responded \(response) to match proposal")
        
        // If all players responded, decide next steps
        if proposal.allPlayersResponded {
            if proposal.allAccepted {
                await createMatchFromProposal(proposal)
            } else {
                // One or more declined – reset proposal and put players back into queue
                matchProposal = nil
                isInQueue = false
                currentQueueType = nil
                queuePosition = 0
                LoggingService.shared.log("Match proposal declined by at least one player", level: .warning)
            }
        }
    }
}

// MARK: - Supporting Types

class MatchQueue: ObservableObject {
    let type: MatchType
    @Published var entries: [QueueEntry] = []
    
    init(type: MatchType) {
        self.type = type
    }
    
    func addUser(_ entry: QueueEntry) {
        entries.append(entry)
        entries.sort { $0.joinTime < $1.joinTime }
    }
    
    func removeUser(_ user: User) {
        entries.removeAll { $0.user.id == user.id }
    }
    
    func removeCurrentUser() {
        // Remove the first entry (current user)
        if !entries.isEmpty {
            entries.removeFirst()
        }
    }
}

struct QueueEntry {
    let user: User
    let joinTime: Date
    let preferredMatchType: MatchType
    let eloRange: ClosedRange<Int>
    
    var waitTime: TimeInterval {
        Date().timeIntervalSince(joinTime)
    }
}

struct PotentialMatch {
    let players: [QueueEntry]
    let matchType: MatchType
    let compatibility: Double
}

struct MatchProposal {
    let id: UUID
    let potentialMatch: PotentialMatch
    let proposedAt: Date
    let expiresAt: Date
    var responses: [String: MatchResponse]
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var allPlayersResponded: Bool {
        responses.count == potentialMatch.players.count
    }
    
    var allAccepted: Bool {
        allPlayersResponded && responses.values.allSatisfy { $0 == .accepted }
    }
}

enum MatchResponse {
    case accepted
    case declined
    case noResponse
}

// MARK: - Extensions

extension Notification.Name {
    static let matchCreated = Notification.Name("matchCreated")
    static let matchProposed = Notification.Name("matchProposed")
    static let queueUpdated = Notification.Name("queueUpdated")
} 