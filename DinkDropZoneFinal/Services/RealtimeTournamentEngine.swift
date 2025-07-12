import Foundation
import Combine
import SwiftUI

/// Comprehensive real-time tournament engine with live bracket updates, automatic progression, and conflict resolution
@MainActor
class RealtimeTournamentEngine: ObservableObject {
    
    // MARK: - Dependencies
    
    private let firebaseService: FirebaseService
    private let realtimeService: RealtimeService
    private let tournamentService: TournamentService
    private let doubleEliminationService = DoubleEliminationService()
    private let swissEngine = SwissEngine()
    
    // MARK: - Published State
    
    @Published var activeTournaments: [String: TournamentEngineState] = [:]
    @Published var connectionStatus: RealtimeService.ConnectionStatus = .disconnected
    @Published var pendingConflicts: [TournamentConflict] = []
    @Published var engineMetrics: EngineMetrics = EngineMetrics()
    
    // MARK: - Configuration
    
    private struct EngineConfig {
        static let maxConcurrentTournaments = 10
        static let conflictResolutionTimeout: TimeInterval = 30.0
        static let bracketUpdateInterval: TimeInterval = 5.0
        static let maxRetries = 3
        static let batchProcessingSize = 20
        static let stateSnapshotInterval: TimeInterval = 60.0
    }
    
    // MARK: - Private State
    
    private var tournamentListeners: [String: Any] = [:]
    private var bracketUpdateTimers: [String: Timer] = [:]
    private var conflictResolutionTasks: [String: Task<Void, Never>] = [:]
    private var engineOperationQueue = OperationQueue()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        firebaseService: FirebaseService,
        realtimeService: RealtimeService,
        tournamentService: TournamentService
    ) {
        self.firebaseService = firebaseService
        self.realtimeService = realtimeService
        self.tournamentService = tournamentService
        
        setupEngineConfiguration()
        setupRealtimeMonitoring()
        setupConflictResolution()
    }
    
    // MARK: - Public API
    
    /// Start real-time management for a tournament
    func startTournamentManagement(tournamentId: String) async throws {
        LoggingService.shared.log("🚀 Starting real-time management for tournament: \(tournamentId)")
        
        // Validate tournament can be managed
        let tournament = try await firebaseService.getTournament(id: tournamentId)
        guard tournament.status == "In Progress" || tournament.status == "Registration Closed" else {
            throw TournamentEngineError.invalidTournamentState(tournament.status)
        }
        
        // Initialize tournament state
        let engineState = TournamentEngineState(
            tournamentId: tournamentId,
            tournament: tournament,
            bracketEngine: getBracketEngine(for: tournament),
            lastUpdateTime: Date(),
            version: 1
        )
        
        activeTournaments[tournamentId] = engineState
        
        // Setup real-time listeners
        try await setupTournamentListeners(tournamentId: tournamentId)
        
        // Start bracket update monitoring
        startBracketUpdateMonitoring(tournamentId: tournamentId)
        
        // Enable automatic progression
        enableAutomaticProgression(tournamentId: tournamentId)
        
        engineMetrics.activeTournaments += 1
        LoggingService.shared.log("✅ Tournament management started: \(tournamentId)")
    }
    
    /// Stop real-time management for a tournament
    func stopTournamentManagement(tournamentId: String) {
        LoggingService.shared.log("🛑 Stopping real-time management for tournament: \(tournamentId)")
        
        // Remove listeners
        removeTournamentListeners(tournamentId: tournamentId)
        
        // Stop timers
        bracketUpdateTimers[tournamentId]?.invalidate()
        bracketUpdateTimers.removeValue(forKey: tournamentId)
        
        // Cancel conflict resolution
        conflictResolutionTasks[tournamentId]?.cancel()
        conflictResolutionTasks.removeValue(forKey: tournamentId)
        
        // Remove from active tournaments
        activeTournaments.removeValue(forKey: tournamentId)
        
        engineMetrics.activeTournaments = max(0, engineMetrics.activeTournaments - 1)
    }
    
    /// Process match completion with automatic bracket progression
    func completeMatch(
        tournamentId: String,
        matchId: String,
        winnerID: String,
        loserID: String,
        score: String,
        submittedBy: String
    ) async throws {
        
        guard let engineState = activeTournaments[tournamentId] else {
            throw TournamentEngineError.tournamentNotManaged(tournamentId)
        }
        
        LoggingService.shared.log("🎾 Processing match completion: \(matchId) in tournament: \(tournamentId)")
        
        // Validate match completion
        guard let match = engineState.tournament.matches.first(where: { $0.id.uuidString == matchId }) else {
            throw TournamentEngineError.matchNotFound(matchId)
        }
        
        try validateMatchCompletion(match: match, winnerID: winnerID, loserID: loserID)
        
        // Process with conflict detection
        let operation = MatchCompletionOperation(
            tournamentId: tournamentId,
            matchId: matchId,
            winnerID: winnerID,
            loserID: loserID,
            score: score,
            submittedBy: submittedBy,
            timestamp: Date()
        )
        
        try await processMatchCompletionWithConflictResolution(operation)
    }
    
    /// Force bracket progression (manual override)
    func forceBracketProgression(tournamentId: String) async throws {
        guard let engineState = activeTournaments[tournamentId] else {
            throw TournamentEngineError.tournamentNotManaged(tournamentId)
        }
        
        LoggingService.shared.log("⚡ Forcing bracket progression for tournament: \(tournamentId)")
        
        let updatedTournament = try await progressBracket(
            tournament: engineState.tournament,
            bracketEngine: engineState.bracketEngine
        )
        
        await updateTournamentState(tournamentId: tournamentId, tournament: updatedTournament)
    }
    
    /// Resolve tournament conflict manually
    func resolveConflict(_ conflictId: String, resolution: ConflictResolution) async throws {
        guard let conflict = pendingConflicts.first(where: { $0.id == conflictId }) else {
            throw TournamentEngineError.conflictNotFound(conflictId)
        }
        
        LoggingService.shared.log("🔧 Resolving conflict: \(conflictId)")
        
        switch resolution {
        case .acceptLatest:
            try await applyConflictResolution(conflict, useLatest: true)
        case .acceptEarliest:
            try await applyConflictResolution(conflict, useLatest: false)
        case .manual(let data):
            try await applyManualResolution(conflict, data: data)
        }
        
        // Remove resolved conflict
        pendingConflicts.removeAll { $0.id == conflictId }
        engineMetrics.conflictsResolved += 1
    }
    
    /// Get tournament engine state
    func getTournamentState(tournamentId: String) -> TournamentEngineState? {
        return activeTournaments[tournamentId]
    }
    
    /// Get real-time tournament metrics
    func getTournamentMetrics(tournamentId: String) -> TournamentMetrics? {
        guard let engineState = activeTournaments[tournamentId] else { return nil }
        
        let tournament = engineState.tournament
        let completedMatches = tournament.matches.filter { $0.status == "Completed" }.count
        let totalMatches = tournament.matches.count
        let progress = totalMatches > 0 ? Double(completedMatches) / Double(totalMatches) : 0.0
        
        return TournamentMetrics(
            tournamentId: tournamentId,
            progress: progress,
            completedMatches: completedMatches,
            totalMatches: totalMatches,
            currentRound: tournament.currentRound,
            estimatedCompletionTime: calculateEstimatedCompletion(tournament),
            averageMatchDuration: calculateAverageMatchDuration(tournament),
            lastActivity: engineState.lastUpdateTime
        )
    }
    
    // MARK: - Real-time Listeners Setup
    
    private func setupTournamentListeners(tournamentId: String) async throws {
        // Tournament data listener
        let tournamentListener = realtimeService.observeTournament(id: tournamentId) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let tournament):
                    await self?.handleTournamentUpdate(tournament)
                case .failure(let error):
                    self?.handleListenerError(tournamentId: tournamentId, error: error)
                }
            }
        }
        
        // Match updates listener
        let matchListener = realtimeService.observeTournamentMatches(id: tournamentId) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let matches):
                    await self?.handleMatchUpdates(tournamentId: tournamentId, matches: matches)
                case .failure(let error):
                    self?.handleListenerError(tournamentId: tournamentId, error: error)
                }
            }
        }
        
        tournamentListeners["\(tournamentId)_tournament"] = tournamentListener
        tournamentListeners["\(tournamentId)_matches"] = matchListener
    }
    
    private func removeTournamentListeners(tournamentId: String) {
        if let tournamentListener = tournamentListeners["\(tournamentId)_tournament"] {
            realtimeService.removeListener(tournamentListener)
        }
        
        if let matchListener = tournamentListeners["\(tournamentId)_matches"] {
            realtimeService.removeListener(matchListener)
        }
        
        tournamentListeners.removeValue(forKey: "\(tournamentId)_tournament")
        tournamentListeners.removeValue(forKey: "\(tournamentId)_matches")
    }
    
    // MARK: - Bracket Management
    
    private func startBracketUpdateMonitoring(tournamentId: String) {
        let timer = Timer.scheduledTimer(withTimeInterval: EngineConfig.bracketUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkBracketProgression(tournamentId: tournamentId)
            }
        }
        
        bracketUpdateTimers[tournamentId] = timer
    }
    
    private func checkBracketProgression(tournamentId: String) async {
        guard let engineState = activeTournaments[tournamentId] else { return }
        
        let tournament = engineState.tournament
        
        // Check if any new matches can be started
        let readyMatches = getReadyMatches(tournament: tournament)
        if !readyMatches.isEmpty {
            LoggingService.shared.log("🔄 \(readyMatches.count) matches ready for progression in tournament: \(tournamentId)")
            
            do {
                let updatedTournament = try await progressBracket(
                    tournament: tournament,
                    bracketEngine: engineState.bracketEngine
                )
                await updateTournamentState(tournamentId: tournamentId, tournament: updatedTournament)
            } catch {
                LoggingService.shared.log("❌ Bracket progression failed: \(error)")
            }
        }
    }
    
    private func progressBracket(tournament: Tournament, bracketEngine: BracketEngineProtocol) async throws -> Tournament {
        var updatedTournament = tournament
        
        // Process completed matches and advance bracket
        let completedMatches = tournament.matches.filter { 
            $0.status == "Completed" && !$0.hasBeenProcessed
        }
        
        for match in completedMatches {
            guard let winnerID = match.winnerID, let loserID = match.loserID else { continue }
            
            // Apply bracket progression logic
            bracketEngine.completeMatch(
                match,
                winnerID: winnerID,
                loserID: loserID,
                score: match.finalScore,
                tournament: &updatedTournament
            )
            
            // Mark match as processed
            if let matchIndex = updatedTournament.matches.firstIndex(where: { $0.id == match.id }) {
                updatedTournament.matches[matchIndex].hasBeenProcessed = true
            }
        }
        
        // Update tournament in Firebase
        try await firebaseService.updateTournament(updatedTournament)
        
        engineMetrics.bracketsProgressed += 1
        return updatedTournament
    }
    
    // MARK: - Conflict Resolution
    
    private func processMatchCompletionWithConflictResolution(_ operation: MatchCompletionOperation) async throws {
        // Check for concurrent modifications
        guard let engineState = activeTournaments[operation.tournamentId] else {
            throw TournamentEngineError.tournamentNotManaged(operation.tournamentId)
        }
        
        // Detect conflicts
        if let conflict = detectConflict(operation: operation, engineState: engineState) {
            LoggingService.shared.log("⚠️ Conflict detected for match: \(operation.matchId)")
            pendingConflicts.append(conflict)
            engineMetrics.conflictsDetected += 1
            
            // Start automatic conflict resolution
            startConflictResolution(conflict)
            return
        }
        
        // No conflict - process normally
        try await applyMatchCompletion(operation)
    }
    
    private func detectConflict(operation: MatchCompletionOperation, engineState: TournamentEngineState) -> TournamentConflict? {
        guard let match = engineState.tournament.matches.first(where: { $0.id.uuidString == operation.matchId }) else {
            return nil
        }
        
        // Check if match was already completed by someone else
        if match.status == "Completed" {
            return TournamentConflict(
                id: UUID().uuidString,
                tournamentId: operation.tournamentId,
                matchId: operation.matchId,
                type: .duplicateCompletion,
                conflictingOperations: [operation],
                detectedAt: Date(),
                priority: .high
            )
        }
        
        // Check for version conflicts
        if engineState.version != engineState.expectedVersion {
            return TournamentConflict(
                id: UUID().uuidString,
                tournamentId: operation.tournamentId,
                matchId: operation.matchId,
                type: .versionMismatch,
                conflictingOperations: [operation],
                detectedAt: Date(),
                priority: .medium
            )
        }
        
        return nil
    }
    
    private func startConflictResolution(_ conflict: TournamentConflict) {
        let task = Task {
            await resolveConflictAutomatically(conflict)
        }
        
        conflictResolutionTasks[conflict.id] = task
    }
    
    private func resolveConflictAutomatically(_ conflict: TournamentConflict) async {
        // Wait for conflict resolution timeout
        try? await Task.sleep(nanoseconds: UInt64(EngineConfig.conflictResolutionTimeout * 1_000_000_000))
        
        // Check if conflict still exists
        guard pendingConflicts.contains(where: { $0.id == conflict.id }) else { return }
        
        LoggingService.shared.log("🤖 Auto-resolving conflict: \(conflict.id)")
        
        // Apply automatic resolution based on conflict type
        do {
            switch conflict.type {
            case .duplicateCompletion:
                try await resolveByTimestamp(conflict)
            case .versionMismatch:
                try await resolveByRefresh(conflict)
            case .concurrentModification:
                try await resolveByMerge(conflict)
            }
            
            // Remove resolved conflict
            pendingConflicts.removeAll { $0.id == conflict.id }
            engineMetrics.conflictsResolved += 1
            
        } catch {
            LoggingService.shared.log("❌ Auto-resolution failed: \(error)")
            // Mark conflict as requiring manual intervention
            if let index = pendingConflicts.firstIndex(where: { $0.id == conflict.id }) {
                pendingConflicts[index].requiresManualIntervention = true
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupEngineConfiguration() {
        engineOperationQueue.maxConcurrentOperationCount = EngineConfig.maxConcurrentTournaments
        engineOperationQueue.qualityOfService = .userInitiated
    }
    
    private func setupRealtimeMonitoring() {
        // Monitor connection status
        realtimeService.connectionStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.connectionStatus = status
            }
            .store(in: &cancellables)
    }
    
    private func setupConflictResolution() {
        // Setup periodic cleanup of resolved conflicts
        Timer.publish(every: 300, on: .main, in: .common) // 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupResolvedConflicts()
            }
            .store(in: &cancellables)
    }
    
    private func getBracketEngine(for tournament: Tournament) -> BracketEngineProtocol {
        switch tournament.type {
        case "Double Elimination":
            return doubleEliminationService as BracketEngineProtocol
        case "Swiss System", "Swiss":
            return swissEngine as BracketEngineProtocol
        default:
            return doubleEliminationService as BracketEngineProtocol // Default fallback
        }
    }
    
    private func enableAutomaticProgression(tournamentId: String) {
        // Enable automatic bracket advancement when matches complete
        LoggingService.shared.log("🔄 Enabling automatic progression for tournament: \(tournamentId)")
    }
    
    private func handleTournamentUpdate(_ tournament: Tournament) async {
        let tournamentId = tournament.id.uuidString
        
        guard var engineState = activeTournaments[tournamentId] else { return }
        
        // Update tournament state
        engineState.tournament = tournament
        engineState.lastUpdateTime = Date()
        engineState.version += 1
        
        activeTournaments[tournamentId] = engineState
        
        LoggingService.shared.log("📊 Tournament updated: \(tournamentId)")
    }
    
    private func handleMatchUpdates(tournamentId: String, matches: [TournamentMatch]) async {
        guard var engineState = activeTournaments[tournamentId] else { return }
        
        // Update matches in tournament
        engineState.tournament.matches = matches
        engineState.lastUpdateTime = Date()
        
        activeTournaments[tournamentId] = engineState
        
        // Check for bracket progression
        await checkBracketProgression(tournamentId: tournamentId)
    }
    
    private func handleListenerError(tournamentId: String, error: Error) {
        LoggingService.shared.log("❌ Listener error for tournament \(tournamentId): \(error)")
        engineMetrics.listenerErrors += 1
    }
    
    private func updateTournamentState(tournamentId: String, tournament: Tournament) async {
        guard var engineState = activeTournaments[tournamentId] else { return }
        
        engineState.tournament = tournament
        engineState.lastUpdateTime = Date()
        engineState.version += 1
        
        activeTournaments[tournamentId] = engineState
    }
    
    private func getReadyMatches(tournament: Tournament) -> [TournamentMatch] {
        return tournament.matches.filter { match in
            match.status == "Ready" && 
            !match.player1ID.isEmpty && 
            !match.player2ID.isEmpty &&
            match.player1ID != "TBD" &&
            match.player2ID != "TBD"
        }
    }
    
    private func validateMatchCompletion(match: TournamentMatch, winnerID: String, loserID: String) throws {
        guard match.status != "Completed" else {
            throw TournamentEngineError.matchAlreadyCompleted
        }
        
        guard [match.player1ID, match.player2ID].contains(winnerID) else {
            throw TournamentEngineError.invalidWinner
        }
        
        guard [match.player1ID, match.player2ID].contains(loserID) else {
            throw TournamentEngineError.invalidLoser
        }
        
        guard winnerID != loserID else {
            throw TournamentEngineError.invalidMatchResult
        }
    }
    
    private func applyMatchCompletion(_ operation: MatchCompletionOperation) async throws {
        // Update match in Firebase
        var updatedMatch = TournamentMatch(
            round: 0, // Will be set from existing match
            bracket: "Main",
            matchNumber: 0
        )
        
        // Get existing match details
        guard let engineState = activeTournaments[operation.tournamentId],
              let existingMatch = engineState.tournament.matches.first(where: { $0.id.uuidString == operation.matchId }) else {
            throw TournamentEngineError.matchNotFound(operation.matchId)
        }
        
        updatedMatch = existingMatch
        updatedMatch.winnerID = operation.winnerID
        updatedMatch.loserID = operation.loserID
        updatedMatch.finalScore = operation.score
        updatedMatch.status = "Completed"
        
        try await firebaseService.updateTournamentMatch(
            tournamentId: operation.tournamentId,
            match: updatedMatch
        )
        
        engineMetrics.matchesProcessed += 1
        LoggingService.shared.log("✅ Match completion applied: \(operation.matchId)")
    }
    
    // MARK: - Conflict Resolution Methods
    
    private func applyConflictResolution(_ conflict: TournamentConflict, useLatest: Bool) async throws {
        LoggingService.shared.log("🔧 Applying \(useLatest ? "latest" : "earliest") resolution for conflict: \(conflict.id)")
        
        let operation = useLatest ? conflict.conflictingOperations.last : conflict.conflictingOperations.first
        guard let selectedOperation = operation else {
            throw TournamentEngineError.invalidConflictResolution
        }
        
        try await applyMatchCompletion(selectedOperation)
    }
    
    private func applyManualResolution(_ conflict: TournamentConflict, data: [String: Any]) async throws {
        LoggingService.shared.log("🔧 Applying manual resolution for conflict: \(conflict.id)")
        
        guard let tournamentId = data["tournamentId"] as? String,
              let matchId = data["matchId"] as? String,
              let winnerID = data["winnerID"] as? String,
              let loserID = data["loserID"] as? String,
              let score = data["score"] as? String else {
            throw TournamentEngineError.invalidConflictResolution
        }
        
        let operation = MatchCompletionOperation(
            tournamentId: tournamentId,
            matchId: matchId,
            winnerID: winnerID,
            loserID: loserID,
            score: score,
            submittedBy: "manual_resolution",
            timestamp: Date()
        )
        
        try await applyMatchCompletion(operation)
    }
    
    private func resolveByTimestamp(_ conflict: TournamentConflict) async throws {
        // Use the earliest operation (first to arrive)
        try await applyConflictResolution(conflict, useLatest: false)
    }
    
    private func resolveByRefresh(_ conflict: TournamentConflict) async throws {
        // Refresh tournament data and reapply
        let tournament = try await firebaseService.getTournament(id: conflict.tournamentId)
        await updateTournamentState(tournamentId: conflict.tournamentId, tournament: tournament)
        
        // Check if conflict still exists after refresh
        if let latestMatch = tournament.matches.first(where: { $0.id.uuidString == conflict.matchId }),
           latestMatch.status != "Completed" {
            // Apply the operation
            if let operation = conflict.conflictingOperations.first {
                try await applyMatchCompletion(operation)
            }
        }
    }
    
    private func resolveByMerge(_ conflict: TournamentConflict) async throws {
        // Merge conflicting operations (complex logic depends on conflict type)
        try await applyConflictResolution(conflict, useLatest: true)
    }
    
    private func cleanupResolvedConflicts() {
        let cutoffTime = Date().addingTimeInterval(-3600) // 1 hour ago
        pendingConflicts.removeAll { conflict in
            conflict.detectedAt < cutoffTime && !conflict.requiresManualIntervention
        }
    }
    
    private func calculateEstimatedCompletion(_ tournament: Tournament) -> Date {
        let averageMatchDuration: TimeInterval = 2700 // 45 minutes
        let remainingMatches = tournament.matches.filter { $0.status != "Completed" }.count
        let estimatedRemainingTime = Double(remainingMatches) * averageMatchDuration
        
        return Date().addingTimeInterval(estimatedRemainingTime)
    }
    
    private func calculateAverageMatchDuration(_ tournament: Tournament) -> TimeInterval {
        let completedMatches = tournament.matches.filter { $0.status == "Completed" }
        guard !completedMatches.isEmpty else { return 2700 } // Default 45 minutes
        
        // This would require match start/end times to be accurate
        return 2700 // Placeholder
    }
}

// MARK: - Supporting Types

struct TournamentEngineState {
    let tournamentId: String
    var tournament: Tournament
    let bracketEngine: BracketEngineProtocol
    var lastUpdateTime: Date
    var version: Int
    var expectedVersion: Int = 1
}

struct MatchCompletionOperation {
    let tournamentId: String
    let matchId: String
    let winnerID: String
    let loserID: String
    let score: String
    let submittedBy: String
    let timestamp: Date
}

struct TournamentConflict {
    let id: String
    let tournamentId: String
    let matchId: String
    let type: ConflictType
    let conflictingOperations: [MatchCompletionOperation]
    let detectedAt: Date
    let priority: ConflictPriority
    var requiresManualIntervention: Bool = false
}

enum ConflictType {
    case duplicateCompletion
    case versionMismatch
    case concurrentModification
}

enum ConflictPriority {
    case low, medium, high, critical
}

enum ConflictResolution {
    case acceptLatest
    case acceptEarliest
    case manual([String: Any])
}

struct EngineMetrics {
    var activeTournaments: Int = 0
    var matchesProcessed: Int = 0
    var bracketsProgressed: Int = 0
    var conflictsDetected: Int = 0
    var conflictsResolved: Int = 0
    var listenerErrors: Int = 0
}

struct TournamentMetrics {
    let tournamentId: String
    let progress: Double
    let completedMatches: Int
    let totalMatches: Int
    let currentRound: Int
    let estimatedCompletionTime: Date
    let averageMatchDuration: TimeInterval
    let lastActivity: Date
}

enum TournamentEngineError: Error, LocalizedError {
    case tournamentNotManaged(String)
    case matchNotFound(String)
    case conflictNotFound(String)
    case invalidTournamentState(String)
    case matchAlreadyCompleted
    case invalidWinner
    case invalidLoser
    case invalidMatchResult
    case invalidConflictResolution
    
    var errorDescription: String? {
        switch self {
        case .tournamentNotManaged(let id):
            return "Tournament \(id) is not being managed by the engine"
        case .matchNotFound(let id):
            return "Match \(id) not found"
        case .conflictNotFound(let id):
            return "Conflict \(id) not found"
        case .invalidTournamentState(let state):
            return "Invalid tournament state: \(state)"
        case .matchAlreadyCompleted:
            return "Match has already been completed"
        case .invalidWinner:
            return "Invalid winner ID"
        case .invalidLoser:
            return "Invalid loser ID"
        case .invalidMatchResult:
            return "Invalid match result"
        case .invalidConflictResolution:
            return "Invalid conflict resolution data"
        }
    }
}

// MARK: - Extensions

extension TournamentMatch {
    var hasBeenProcessed: Bool {
        get {
            // This would need to be added to the TournamentMatch model
            return false // Placeholder
        }
        set {
            // This would need to be added to the TournamentMatch model
        }
    }
}

// MARK: - Protocol Conformance

// Note: DoubleEliminationService and SwissEngine already conform to BracketEngineProtocol in their respective files
// No additional conformance needed here

// MARK: - RealtimeService Extensions

extension RealtimeService {
    func observeTournamentMatches(id: String, completion: @escaping (Result<[TournamentMatch], Error>) -> Void) -> Any {
        // This would be implemented in RealtimeService
        return observeTournament(id: id) { result in
            switch result {
            case .success(let tournament):
                completion(.success(tournament.matches))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    var connectionStatusPublisher: AnyPublisher<RealtimeService.ConnectionStatus, Never> {
        // This would be implemented in RealtimeService
        return Just(.connected).eraseToAnyPublisher()
    }
    
    func removeListener(_ listener: Any) {
        // This would be implemented in RealtimeService
    }
} 