import Foundation
import FirebaseFirestore
import Combine

/// Enhanced Tournament Service with advanced caching, real-time updates, and better error handling.
class TournamentServiceEnhanced: ObservableObject {
    @Published var tournaments: [Tournament] = []
    @Published var myTournaments: [Tournament] = []
    @Published var isLoading: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    private let firebaseService: FirebaseService
    private let tournamentService: TournamentService
    private var tournamentCache: [String: Tournament] = [:]
    private var cacheTimestamp: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutes
    
    private var listeners: [FirebaseService.ListenerHandle] = []
    
    enum ConnectionStatus {
        case connected, disconnected, connecting
    }
    
    init(firebaseService: FirebaseService, tournamentService: TournamentService) {
        self.firebaseService = firebaseService
        self.tournamentService = tournamentService
        // Attempt to load from local cache on init
        loadFromLocalCache()
    }
    
    deinit {
        removeAllListeners()
    }
    
    // MARK: - Public API
    
    /// Fetches all tournaments, utilizing cache if available and still valid.
    func fetchAllTournaments(forceRefresh: Bool = false) async throws {
        if !forceRefresh, isCacheValid() {
            self.tournaments = Array(tournamentCache.values)
            return
        }
        
        await MainActor.run {
            self.isLoading = true
            self.connectionStatus = .connecting
        }
        
        do {
            let fetchedTournaments = try await firebaseService.getAllTournaments()
            updateCache(with: fetchedTournaments)
            
            await MainActor.run {
                self.tournaments = fetchedTournaments
                self.isLoading = false
                self.connectionStatus = .connected
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.connectionStatus = .disconnected
            }
            throw error
        }
    }
    
    /// Creates a new tournament and adds it to Firestore.
    func createTournament(_ tournament: Tournament) async throws {
        let tournamentId = try await firebaseService.createTournament(tournament)
        // Add to local cache immediately for UI responsiveness
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
        tournamentCache[tournamentWithId.id.uuidString] = tournamentWithId
        await MainActor.run {
            self.tournaments.append(tournamentWithId)
        }
    }
    
    /// Joins a tournament, handling partner logic if applicable.
    func joinTournament(_ tournament: Tournament, user: User, partner: User? = nil) async throws {
        var userParticipant = TournamentParticipant(
            userID: user.id.uuidString,
            displayName: user.displayName,
            elo: user.elo
        )
        
        if let partner = partner {
            let teamId = UUID().uuidString
            userParticipant.partnerID = partner.id.uuidString
            userParticipant.partnerName = partner.displayName
            userParticipant.teamName = "\(user.displayName) / \(partner.displayName)"
            
            var partnerParticipant = TournamentParticipant(
                userID: partner.id.uuidString,
                displayName: partner.displayName,
                elo: partner.elo,
                partnerID: user.id.uuidString,
                partnerName: user.displayName,
                teamName: "\(user.displayName) / \(partner.displayName)"
            )
            
            // Use TournamentService to register both participants
            try await tournamentService.registerForTournament(tournament, participant: partnerParticipant)
        }
        
        try await tournamentService.registerForTournament(tournament, participant: userParticipant)
        
        // Update local cache
        if var cachedTournament = tournamentCache[tournament.id.uuidString] {
            cachedTournament.participants.append(userParticipant)
            if let partner = partner {
                let partnerParticipant = TournamentParticipant(
                    userID: partner.id.uuidString,
                    displayName: partner.displayName,
                    elo: partner.elo,
                    partnerID: user.id.uuidString,
                    partnerName: user.displayName,
                    teamName: "\(user.displayName) / \(partner.displayName)"
                )
                cachedTournament.participants.append(partnerParticipant)
            }
            tournamentCache[tournament.id.uuidString] = cachedTournament
            await MainActor.run {
                if let index = self.tournaments.firstIndex(where: { $0.id == tournament.id }) {
                    self.tournaments[index] = cachedTournament
                }
            }
        }
    }
    
    /// Leaves a tournament, handling partner unlinking.
    func leaveTournament(_ tournament: Tournament, user: User) async throws {
        guard let participant = tournament.participants.first(where: { $0.userID == user.id.uuidString }) else {
            throw TournamentError.invalidStatus("User not found in tournament")
        }
        
        try await tournamentService.leaveTournament(tournament, user: user)
        
        // Update local cache
        if var cachedTournament = tournamentCache[tournament.id.uuidString] {
            cachedTournament.participants.removeAll { $0.userID == user.id.uuidString }
            // Also remove partner if exists
            if let partnerId = participant.partnerID {
                cachedTournament.participants.removeAll { $0.userID == partnerId }
            }
            tournamentCache[tournament.id.uuidString] = cachedTournament
            await MainActor.run {
                if let index = self.tournaments.firstIndex(where: { $0.id == tournament.id }) {
                    self.tournaments[index] = cachedTournament
                }
            }
        }
    }
    
    /// Starts a tournament, generating the bracket.
    func startTournament(_ tournament: Tournament) async throws {
        let updatedTournament = try await tournamentService.startTournament(tournament)
        
        // Update local cache
        tournamentCache[tournament.id.uuidString] = updatedTournament
        await MainActor.run {
            if let index = self.tournaments.firstIndex(where: { $0.id == tournament.id }) {
                self.tournaments[index] = updatedTournament
            }
        }
    }
    
    /// Submits a match result and updates tournament progression
    func submitMatchResult(
        tournamentId: String,
        match: TournamentMatch,
        winnerID: String,
        loserID: String,
        score: String
    ) async throws {
        try await tournamentService.completeMatch(
            tournamentId: tournamentId,
            match: match,
            winnerID: winnerID,
            loserID: loserID,
            score: score
        )
        
        // Refresh tournament data to get updated bracket
        let updatedTournament = try await firebaseService.getTournament(id: tournamentId)
        tournamentCache[tournamentId] = updatedTournament
        
        await MainActor.run {
            if let index = self.tournaments.firstIndex(where: { $0.id.uuidString == tournamentId }) {
                self.tournaments[index] = updatedTournament
            }
        }
    }
    
    /// Gets user's tournaments with enhanced filtering
    func getUserTournaments(userId: String) async throws -> [Tournament] {
        let userTournaments = try await firebaseService.getUserTournaments(userId: userId)
        
        await MainActor.run {
            self.myTournaments = userTournaments.sorted { tournament1, tournament2 in
                // Sort by status priority first, then by date
                let statusPriority1 = getStatusPriority(tournament1.status)
                let statusPriority2 = getStatusPriority(tournament2.status)
                
                if statusPriority1 != statusPriority2 {
                    return statusPriority1 < statusPriority2
                }
                
                return tournament1.startDate > tournament2.startDate
            }
        }
        
        return userTournaments
    }
    
    /// Gets tournament matches with real-time updates
    func getTournamentMatches(tournamentId: String) async throws -> [TournamentMatch] {
        let tournament = try await firebaseService.getTournament(id: tournamentId)
        return tournament.matches
    }
    
    /// Gets tournament participants with real-time updates
    func getTournamentParticipants(tournamentId: String) async throws -> [TournamentParticipant] {
        let tournament = try await firebaseService.getTournament(id: tournamentId)
        return tournament.participants
    }
    
    /// Subscribes to real-time updates for a specific tournament.
    func subscribeToTournamentUpdates(tournamentId: String) {
        let listener = firebaseService.observeTournament(id: tournamentId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let tournament):
                self.tournamentCache[tournamentId] = tournament
                DispatchQueue.main.async {
                    if let index = self.tournaments.firstIndex(where: { $0.id.uuidString == tournamentId }) {
                        self.tournaments[index] = tournament
                    } else {
                        self.tournaments.append(tournament)
                    }
                }
            case .failure(let error):
                print("Error listening to tournament updates: \(error)")
            }
        }
        listeners.append(listener)
    }
    
    /// Subscribes to real-time updates for all tournaments
    func subscribeToAllTournamentUpdates() {
        // Subscribe to tournament collection changes
        Task {
            do {
                try await fetchAllTournaments(forceRefresh: true)
                
                // Set up periodic refresh for active tournaments
                Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
                    Task { [weak self] in
                        try? await self?.refreshActiveTournaments()
                    }
                }
            } catch {
                print("Failed to subscribe to tournament updates: \(error)")
            }
        }
    }
    
    /// Removes all active Firestore listeners.
    func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Private Helper Methods
    
    private func getStatusPriority(_ status: String) -> Int {
        switch status {
        case "In Progress": return 0
        case "Registration Open": return 1
        case "Registration Closed": return 2
        case "Upcoming": return 3
        case "Completed": return 4
        case "Cancelled": return 5
        default: return 6
        }
    }
    
    private func refreshActiveTournaments() async throws {
        let activeTournaments = tournaments.filter { tournament in
            tournament.status == "In Progress" || tournament.status == "Registration Open"
        }
        
        for tournament in activeTournaments {
            let updatedTournament = try await firebaseService.getTournament(id: tournament.id.uuidString)
            tournamentCache[tournament.id.uuidString] = updatedTournament
            
            await MainActor.run {
                if let index = self.tournaments.firstIndex(where: { $0.id == tournament.id }) {
                    self.tournaments[index] = updatedTournament
                }
            }
        }
    }
    
    // MARK: - Cache Management
    
    private func isCacheValid() -> Bool {
        guard let timestamp = cacheTimestamp else { return false }
        return Date().timeIntervalSince(timestamp) < cacheDuration
    }
    
    private func updateCache(with newTournaments: [Tournament]) {
        tournamentCache = Dictionary(uniqueKeysWithValues: newTournaments.map { ($0.id.uuidString, $0) })
        cacheTimestamp = Date()
        saveToLocalCache()
    }
    
    // MARK: - Local Persistence (UserDefaults)
    
    private func saveToLocalCache() {
        do {
            let data = try JSONEncoder().encode(tournamentCache)
            UserDefaults.standard.set(data, forKey: "tournamentCache")
        } catch {
            print("Failed to save tournament cache: \(error)")
        }
    }
    
    private func loadFromLocalCache() {
        guard let data = UserDefaults.standard.data(forKey: "tournamentCache") else { return }
        
        do {
            tournamentCache = try JSONDecoder().decode([String: Tournament].self, from: data)
            self.tournaments = Array(tournamentCache.values)
        } catch {
            print("Failed to load tournament cache: \(error)")
        }
    }
    
    // MARK: - Utility Functions
    
    /// Determines the user's status within a specific tournament.
    @MainActor
    func getUserTournamentStatus(user: User, tournament: Tournament) -> UserTournamentStatus {
        return tournamentService.getUserTournamentStatus(user: user, tournament: tournament)
    }
}
