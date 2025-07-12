import Foundation
import SwiftData
import Combine
import SwiftUI

// MARK: - Enhanced Tournament Service for Large Tournaments

@MainActor
class TournamentService: ObservableObject {
    let firebaseService: FirebaseService
    private let bracketEngine = BracketEngine()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Performance Configuration
    
    private struct ServiceConfiguration {
        static let maxConcurrentOperations = 5
        static let batchSize = 20
        static let cacheTimeout: TimeInterval = 300 // 5 minutes
        static let maxTournamentSize = 128
    }
    
    // MARK: - Cache Management
    
    private var tournamentCache: [String: (tournament: Tournament, timestamp: Date)] = [:]
    private var isPerformingBulkOperation = false
    
    // MARK: - Published Properties
    
    @Published var tournaments: [Tournament] = []
    @Published var isLoading = false
    @Published var error: TournamentError?
    @Published var operationProgress: Double = 0.0
    
    init(firebaseService: FirebaseService) {
        self.firebaseService = firebaseService
        setupPerformanceMonitoring()
    }
    
    // MARK: - Enhanced Tournament Management
    
    /// Creates a tournament with comprehensive validation and error handling
    func createTournament(
        name: String,
        description: String = "",
        type: String = "Double Elimination",
        format: String = "Doubles",
        skillLevel: String = "Intermediate",
        maxParticipants: Int = 32,
        startDate: Date = Date(),
        organizerID: String,
        organizerName: String,
        venueName: String = "",
        venueAddress: String = ""
    ) async throws -> Tournament {
        
        // Validate tournament parameters
        try validateTournamentCreation(
            name: name,
            maxParticipants: maxParticipants,
            startDate: startDate
        )
        
        let tournament = Tournament(
            name: name,
            description: description,
            type: type,
            format: format,
            skillLevel: skillLevel,
            maxParticipants: maxParticipants,
            startDate: startDate,
            organizerID: organizerID,
            organizerName: organizerName,
            venueName: venueName,
            venueAddress: venueAddress
        )
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let tournamentId = try await firebaseService.createTournament(tournament)
            
            // Cache the tournament
            cacheTournament(tournament)
            
            // Add to local tournaments if not already present
            if !tournaments.contains(where: { $0.id == tournament.id }) {
                tournaments.append(tournament)
            }
            
            print("✅ Tournament created successfully: \(name) (ID: \(tournamentId))")
            return tournament
            
        } catch {
            self.error = TournamentError.creationFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Enhanced tournament registration with validation and Firebase integration
    func registerForTournament(_ tournament: Tournament, participant: TournamentParticipant) async throws {
        try validateRegistration(tournament: tournament, participant: participant)
        
        // Use Firebase service to register participant with transaction safety
        try await firebaseService.registerForTournament(
            tournamentId: tournament.id.uuidString,
            participant: participant
        )
        
        // Refresh tournament data from Firebase to get updated state
        let updatedTournament = try await firebaseService.getTournament(id: tournament.id.uuidString)
        
        // Update local cache
        cacheTournament(updatedTournament)
        
        // Update local tournaments list
        if let index = tournaments.firstIndex(where: { $0.id == tournament.id }) {
            tournaments[index] = updatedTournament
        }
        
        print("✅ Registered \(participant.displayName) for tournament: \(tournament.name)")
    }
    
    /// Batch registration for multiple participants (useful for large tournaments)
    func batchRegisterParticipants(_ tournament: Tournament, participants: [TournamentParticipant]) async throws {
        guard !isPerformingBulkOperation else {
            throw TournamentError.operationInProgress
        }
        
        isPerformingBulkOperation = true
        defer { isPerformingBulkOperation = false }
        
        var updatedTournament = tournament
        var successfulRegistrations: [TournamentParticipant] = []
        var failedRegistrations: [(TournamentParticipant, Error)] = []
        
        let batches = participants.chunked(into: ServiceConfiguration.batchSize)
        
        for (batchIndex, batch) in batches.enumerated() {
            operationProgress = Double(batchIndex) / Double(batches.count)
            
            for participant in batch {
                do {
                    try validateRegistration(tournament: updatedTournament, participant: participant)
                    
                    if !updatedTournament.participants.contains(where: { $0.userID == participant.userID }) {
                        updatedTournament.participants.append(participant)
                        successfulRegistrations.append(participant)
                    }
                } catch {
                    failedRegistrations.append((participant, error))
                }
            }
            
            // Small delay to prevent overwhelming the system
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        }
        
        if !successfulRegistrations.isEmpty {
            updateTournamentStatus(&updatedTournament)
            try await updateTournament(updatedTournament)
        }
        
        operationProgress = 1.0
        
        print("✅ Batch registration completed: \(successfulRegistrations.count) successful, \(failedRegistrations.count) failed")
        
        if !failedRegistrations.isEmpty {
            let errorMessage = "Some registrations failed: \(failedRegistrations.count) participants"
            throw TournamentError.batchOperationPartialFailure(errorMessage)
        }
    }
    
    /// Enhanced tournament starting with comprehensive validation
    func startTournament(_ tournament: Tournament) async throws -> Tournament {
        try validateTournamentStart(tournament)
        
        var updatedTournament = tournament
        updatedTournament.status = "In Progress"
        
        // Generate bracket with performance monitoring
        let startTime = Date()
        let matches = bracketEngine.generateBracket(for: updatedTournament)
        let generationTime = Date().timeIntervalSince(startTime)
        
        print("🏁 Bracket generated in \(String(format: "%.2f", generationTime))s for \(updatedTournament.participants.count) participants")
        
        updatedTournament.matches = matches
        
        try await updateTournament(updatedTournament)
        return updatedTournament
    }
    
    /// Performance-optimized tournament retrieval with caching
    func getTournament(id: String) async throws -> Tournament {
        // Check cache first
        if let cachedData = tournamentCache[id],
           Date().timeIntervalSince(cachedData.timestamp) < ServiceConfiguration.cacheTimeout {
            return cachedData.tournament
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let tournament = try await firebaseService.getTournament(id: id)
            cacheTournament(tournament)
            return tournament
        } catch {
            self.error = TournamentError.fetchFailed(error.localizedDescription)
            throw error
        }
    }
    
    /// Enhanced match completion with validation and Firebase integration
    func completeMatch(
        tournamentId: String,
        match: TournamentMatch,
        winnerID: String,
        loserID: String,
        score: String
    ) async throws {
        
        try validateMatchCompletion(match: match, winnerID: winnerID, loserID: loserID, score: score)
        
        // Create updated match with result
        var updatedMatch = match
        updatedMatch.winnerID = winnerID
        updatedMatch.loserID = loserID
        updatedMatch.finalScore = score
        updatedMatch.status = "Completed"
        
        // Use Firebase service to update match with transaction safety
        try await firebaseService.updateTournamentMatch(
            tournamentId: tournamentId,
            match: updatedMatch
        )
        
        // Refresh tournament data from Firebase to get updated state
        let updatedTournament = try await firebaseService.getTournament(id: tournamentId)
        
        // Update local cache
        cacheTournament(updatedTournament)
        
        // Update local tournaments list
        if let index = tournaments.firstIndex(where: { $0.id.uuidString == tournamentId }) {
            tournaments[index] = updatedTournament
        }
        
        // Check for tournament completion
        if updatedTournament.status == "Completed" {
            await finalizeCompletedTournament(updatedTournament)
        }
        
        print("✅ Match completed: \(match.displayName) - Winner: \(winnerID)")
    }
    
    private func finalizeCompletedTournament(_ tournament: Tournament) async {
        print("🏆 Tournament completed: \(tournament.name)")
        
        // Update final placements
        let champion = tournament.participants.first { $0.placement == 1 }
        if let champion = champion {
            print("👑 Champion: \(champion.displayName)")
        }
        
        // Clear from cache since it's now completed
        tournamentCache.removeValue(forKey: tournament.id.uuidString)
    }
    
    // MARK: - Validation Methods
    
    private func validateTournamentCreation(name: String, maxParticipants: Int, startDate: Date) throws {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TournamentError.invalidName
        }
        
        guard maxParticipants >= 4 && maxParticipants <= ServiceConfiguration.maxTournamentSize else {
            throw TournamentError.invalidParticipantCount(maxParticipants)
        }
        
        guard startDate > Date() else {
            throw TournamentError.invalidStartDate
        }
    }
    
    private func validateRegistration(tournament: Tournament, participant: TournamentParticipant) throws {
        guard tournament.isRegistrationOpen else {
            throw TournamentError.registrationClosed
        }
        
        guard tournament.participants.count < tournament.maxParticipants else {
            throw TournamentError.tournamentFull
        }
        
        guard !tournament.participants.contains(where: { $0.userID == participant.userID }) else {
            throw TournamentError.alreadyRegistered
        }
    }
    
    private func validateTournamentStart(_ tournament: Tournament) throws {
        guard tournament.status == "Registration Closed" || tournament.status == "Registration Open" else {
            throw TournamentError.invalidStatus("Cannot start tournament with status: \(tournament.status)")
        }
        
        let registeredCount = tournament.participants.filter { $0.status == "Registered" }.count
        guard registeredCount >= 4 else {
            throw TournamentError.insufficientParticipants(registeredCount)
        }
        
        // Check for power of 2 for elimination tournaments
        if tournament.type.contains("Elimination") {
            let powerOfTwo = nextPowerOfTwo(registeredCount)
            if registeredCount < powerOfTwo / 2 {
                print("⚠️ Tournament will have \(powerOfTwo - registeredCount) bye matches")
            }
        }
    }
    
    private func validateMatchCompletion(match: TournamentMatch, winnerID: String, loserID: String, score: String) throws {
        guard match.status != "Completed" else {
            throw TournamentError.matchAlreadyCompleted
        }
        
        guard !winnerID.isEmpty && !loserID.isEmpty else {
            throw TournamentError.invalidMatchResult
        }
        
        guard winnerID != loserID else {
            throw TournamentError.invalidMatchResult
        }
        
        guard [match.player1ID, match.player2ID].contains(winnerID) &&
              [match.player1ID, match.player2ID].contains(loserID) else {
            throw TournamentError.invalidMatchResult
        }
    }
    
    // MARK: - Cache Management
    
    private func cacheTournament(_ tournament: Tournament) {
        tournamentCache[tournament.id.uuidString] = (tournament, Date())
        
        // Clean old cache entries
        let cutoffTime = Date().addingTimeInterval(-ServiceConfiguration.cacheTimeout)
        tournamentCache = tournamentCache.filter { $0.value.timestamp > cutoffTime }
    }
    
    private func clearCache() {
        tournamentCache.removeAll()
    }
    
    // MARK: - Tournament Status Management
    
    private func updateTournamentStatus(_ tournament: inout Tournament) {
        let registeredCount = tournament.participants.filter { $0.status == "Registered" }.count
        
        if registeredCount >= tournament.maxParticipants {
            tournament.status = "Registration Closed"
        } else if registeredCount >= 4 && tournament.status == "Upcoming" {
            tournament.status = "Registration Open"
        }
    }
    

    
    // MARK: - Performance Monitoring
    
    private func setupPerformanceMonitoring() {
        // Monitor memory usage and performance for large tournaments
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.performCacheMaintenance()
            }
            .store(in: &cancellables)
    }
    
    private func performCacheMaintenance() {
        let cutoffTime = Date().addingTimeInterval(-ServiceConfiguration.cacheTimeout)
        let oldCount = tournamentCache.count
        tournamentCache = tournamentCache.filter { $0.value.timestamp > cutoffTime }
        
        if tournamentCache.count < oldCount {
            print("🧹 Cache cleaned: removed \(oldCount - tournamentCache.count) expired entries")
        }
    }
    
    // MARK: - Legacy Support
    
    func getAllTournaments() -> [Tournament] {
        return tournaments
    }
    
    /// Loads all tournaments from Firebase and updates local cache
    func loadTournamentsFromFirebase() async throws {
        let fetchedTournaments = try await firebaseService.getAllTournaments()
        
        await MainActor.run {
            tournaments = fetchedTournaments
            
            // Cache all tournaments
            for tournament in fetchedTournaments {
                cacheTournament(tournament)
            }
        }
        
        print("✅ Loaded \(fetchedTournaments.count) tournaments from Firebase")
    }
    
    func updateTournament(_ tournament: Tournament) async throws {
        try await firebaseService.updateTournament(tournament)
        
        // Update local cache
        cacheTournament(tournament)
        
        // Update local tournaments array
        if let index = tournaments.firstIndex(where: { $0.id == tournament.id }) {
            tournaments[index] = tournament
        }
    }
    
    // MARK: - Additional Methods for AppState Compatibility
    
    /// Join tournament with a User object (convenience method)
    func joinTournament(_ tournament: Tournament, user: User) async throws {
        let participant = TournamentParticipant(
            userID: user.id.uuidString,
            displayName: user.displayName,
            elo: user.elo
        )
        try await registerForTournament(tournament, participant: participant)
    }
    
    /// Start tournament if it has enough participants (convenience method)
    func startTournamentIfReady(_ tournament: Tournament) async throws {
        let registeredCount = tournament.participants.filter { $0.status == "Registered" }.count
        if registeredCount >= 4 && tournament.status != "In Progress" {
            _ = try await startTournament(tournament)
        }
    }
    
    /// Submit match result (convenience method)
    func submitMatchResult(
        match: TournamentMatch,
        winnerID: String,
        loserID: String,
        score: String,
        tournament: Tournament
    ) async throws {
        try await completeMatch(
            tournamentId: tournament.id.uuidString,
            match: match,
            winnerID: winnerID,
            loserID: loserID,
            score: score
        )
    }
    
    /// Get ready matches for a tournament (convenience method)
    func getReadyMatches(in tournament: Tournament) -> [TournamentMatch] {
        return tournament.matches.filter { $0.status == "Ready" }
    }
    
    /// Get user tournament status (convenience method)
    func getUserTournamentStatus(user: User, tournament: Tournament) -> UserTournamentStatus {
        let userID = user.id.uuidString
        
        // Check if user is registered
        let isRegistered = tournament.participants.contains { $0.userID == userID }
        
        if !isRegistered {
            return .notRegistered
        }
        
        // Check if user has an active match
        let userMatches = tournament.matches.filter { match in
            (match.player1ID == userID || match.player2ID == userID) && match.status != "Completed"
        }
        
        if let activeMatch = userMatches.first(where: { $0.status == "Ready" }) {
            return .hasMatch(activeMatch)
        }
        
        // Check tournament status
        switch tournament.status {
        case "Completed":
            let participant = tournament.participants.first { $0.userID == userID }
            let placement = participant?.placement ?? 999
            if placement == 1 {
                return .finished(placement: placement)
            } else {
                return .eliminated(placement: placement)
            }
        case "In Progress":
            return .active
        default:
            return .registered(isPartnered: false)
        }
    }
    
    /// Leave tournament (Firebase integrated)
    func leaveTournament(_ tournament: Tournament, user: User) async throws {
        let userID = user.id.uuidString
        
        // Use Firebase service to remove participant with transaction safety
        try await firebaseService.leaveTournament(
            tournamentId: tournament.id.uuidString,
            userId: userID
        )
        
        // Refresh tournament data from Firebase to get updated state
        let updatedTournament = try await firebaseService.getTournament(id: tournament.id.uuidString)
        
        // Update local cache
        cacheTournament(updatedTournament)
        
        // Update local tournaments list
        if let index = tournaments.firstIndex(where: { $0.id == tournament.id }) {
            tournaments[index] = updatedTournament
        }
        
        print("✅ User \(user.displayName) left tournament: \(tournament.name)")
    }
    
    /// Start tournament immediately (organizer only)
    func startTournamentNow(_ tournament: Tournament, organizerID: String) async throws -> Tournament {
        // Verify organizer permission
        guard tournament.organizerID == organizerID else {
            throw TournamentError.invalidStatus("Only the tournament organizer can start the tournament")
        }
        
        // Validate minimum participants
        let registeredCount = tournament.participants.filter { $0.status == "Registered" }.count
        guard registeredCount >= 4 else {
            throw TournamentError.insufficientParticipants(registeredCount)
        }
        
        var updatedTournament = tournament
        updatedTournament.status = "In Progress"
        
        // Generate bracket
        let matches = bracketEngine.generateBracket(for: updatedTournament)
        updatedTournament.matches = matches
        
        try await updateTournament(updatedTournament)
        
        // Update local tournaments list
        if let index = tournaments.firstIndex(where: { $0.id == tournament.id }) {
            tournaments[index] = updatedTournament
        }
        
        print("🏁 Tournament started: \(tournament.name) with \(registeredCount) participants")
        return updatedTournament
    }
    
    /// Get tournament matches (convenience method for TournamentLiveMonitorView)
    func getTournamentMatches(tournamentId: String) async throws -> [TournamentMatch] {
        let tournament = try await getTournament(id: tournamentId)
        return tournament.matches
    }
    
    /// Get tournament participants (convenience method for TournamentLiveMonitorView)
    func getTournamentParticipants(tournamentId: String) async throws -> [TournamentParticipant] {
        let tournament = try await getTournament(id: tournamentId)
        return tournament.participants
    }
    
    // MARK: - Utility Methods
    
    private func nextPowerOfTwo(_ n: Int) -> Int {
        guard n > 0 else { return 1 }
        var power = 1
        while power < n {
            power *= 2
        }
        return power
    }
    
    // MARK: - Real-time Update Handling
    
    /// Handle real-time tournament updates from centralized RealtimeService
    func handleRealtimeUpdate(_ tournaments: [Tournament]) {
        // Update local tournament cache
        for tournament in tournaments {
            // Update or add tournament to local cache
            if let index = self.tournaments.firstIndex(where: { $0.id == tournament.id }) {
                self.tournaments[index] = tournament
            } else {
                self.tournaments.append(tournament)
            }
        }
        
        // Sort tournaments by start date
        self.tournaments.sort { $0.startDate < $1.startDate }
        
        LoggingService.shared.log("Updated \(tournaments.count) tournaments from real-time sync")
        
        // Post notification for tournament views
        NotificationCenter.default.post(
            name: .tournamentDataUpdated,
            object: tournaments
        )
    }
    
    // MARK: - Real-time Listener Management
    
    /// Subscribe to real-time updates for a specific tournament
    func subscribeToTournamentUpdates(tournamentId: String) {
        guard let realtimeService = getRealtimeService() else { return }
        
        let listenerId = realtimeService.observeTournament(id: tournamentId) { [weak self] result in
            switch result {
            case .success(let tournament):
                self?.handleSingleTournamentUpdate(tournament)
            case .failure(let error):
                LoggingService.shared.log("Tournament real-time listener error: \(error)")
            }
        }
        
        LoggingService.shared.log("Subscribed to real-time updates for tournament: \(tournamentId)")
    }
    
    /// Handle single tournament update
    private func handleSingleTournamentUpdate(_ tournament: Tournament) {
        // Update local tournament data
        if let index = tournaments.firstIndex(where: { $0.id == tournament.id }) {
            tournaments[index] = tournament
        }
        
        // Post notification for tournament views
        NotificationCenter.default.post(
            name: .tournamentUpdated,
            object: tournament
        )
    }
    
    /// Get reference to RealtimeService (would be injected in real implementation)
    private func getRealtimeService() -> RealtimeService? {
        // In a real implementation, this would be injected via dependency injection
        // For now, we'll need to access it through AppState or similar
        return nil
    }
}

// MARK: - Supporting Types

enum UserTournamentStatus: Equatable {
    case notRegistered
    case registered(isPartnered: Bool)
    case waitingForMatch
    case hasMatch(TournamentMatch)
    case eliminated(placement: Int)
    case finished(placement: Int)
    case active
    case champion
    case runnerUp
    case thirdPlace
    
    var description: String {
        switch self {
        case .notRegistered: return "Not Registered"
        case .registered(let isPartnered): return isPartnered ? "Registered" : "Need Partner"
        case .waitingForMatch: return "Waiting"
        case .hasMatch: return "Match Ready"
        case .eliminated: return "Eliminated"
        case .finished: return "Finished"
        case .active: return "Active"
        case .champion: return "Champion"
        case .runnerUp: return "Runner-up"
        case .thirdPlace: return "3rd Place"
        }
    }

    var color: Color {
        switch self {
        case .notRegistered: return .gray
        case .registered(let isPartnered): return isPartnered ? .green : .orange
        case .waitingForMatch: return .blue
        case .hasMatch: return .purple
        case .eliminated: return .red
        case .finished: return .gray
        case .active: return .green
        case .champion: return .yellow
        case .runnerUp: return .gray
        case .thirdPlace: return .orange
        }
    }
}

// Note: TournamentError is defined in Tournament.swift to avoid duplication

// MARK: - Array Extension for Chunking

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Int Extension for Ordinals

extension Int {
    var ordinal: String {
        let suffix: String
        switch self % 100 {
        case 11...13:
            suffix = "th"
        default:
            switch self % 10 {
            case 1: suffix = "st"
            case 2: suffix = "nd"
            case 3: suffix = "rd"
            default: suffix = "th"
            }
        }
        return "\(self)\(suffix)"
    }
} 