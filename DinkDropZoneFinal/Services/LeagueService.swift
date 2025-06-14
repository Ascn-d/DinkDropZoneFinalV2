import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class LeagueService {
    private var modelContext: ModelContext
    private var network: NetworkService?
    
    init(modelContext: ModelContext, network: NetworkService? = nil) {
        self.modelContext = modelContext
        self.network = network
    }
    
    // MARK: - CRUD
    func createLeague(
        name: String,
        description: String = "",
        location: String = "",
        owner: User,
        format: LeagueFormat = .roundRobin,
        maxParticipants: Int = 16,
        price: Double = 0.0,
        rating: Double = 0.0,
        imageUrl: String? = nil,
        schedule: String? = nil,
        nextGame: String? = nil,
        tags: [String] = [],
        skillLevel: String = "Beginner"
    ) -> PickleLeague {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .month, value: 3, to: startDate) ?? Date()
        
        let league = PickleLeague(
            name: name,
            leagueDescription: description,
            location: location,
            imageUrl: imageUrl,
            rating: rating,
            format: format,
            status: .open,
            startDate: startDate,
            endDate: endDate,
            maxPlayers: maxParticipants,
            entryFee: Int(price),
            schedule: schedule,
            nextGame: nextGame,
            tags: tags
        )
        modelContext.insert(league)
        return league
    }
    
    // Import league sent from backend
    @discardableResult
    func importLeague(from dto: NetworkService.LeagueDTO, usersCache: [String: User] = [:]) -> PickleLeague {
        // Attempt to find existing league
        let existing: PickleLeague? = (try? modelContext.fetch(FetchDescriptor<PickleLeague>()))?.first { $0.id == dto.id }
        let league = existing ?? PickleLeague(
            name: dto.name,
            leagueDescription: dto.leagueDescription ?? "",
            location: dto.location ?? "",
            format: LeagueFormat(rawValue: dto.format) ?? .roundRobin,
            startDate: dto.startDate,
            endDate: dto.endDate
        )
        league.id = dto.id
        league.name = dto.name
        league.leagueDescription = dto.leagueDescription ?? ""
        league.location = dto.location ?? ""
        league.status = LeagueStatus(rawValue: dto.status) ?? .open
        league.format = LeagueFormat(rawValue: dto.format) ?? .roundRobin
        league.maxPlayers = dto.maxParticipants
        league.entryFee = Int(dto.price ?? 0.0)
        league.rating = dto.rating ?? 0.0
        league.imageUrl = dto.imageUrl
        league.schedule = dto.schedule
        league.nextGame = dto.nextGame
        league.tags = dto.tags ?? []
        league.createdAt = dto.createdAt
        league.players = dto.members.map { fetchOrCreateUser(id: $0.id, name: $0.displayName, elo: $0.elo, cache: usersCache) }
        // Matches mapping simplified (scores only)
        let matches: [LeagueMatch] = dto.matches.compactMap { m in
            let player1 = fetchOrCreateUser(id: m.player1Id, cache: usersCache)
            let player2 = fetchOrCreateUser(id: m.player2Id, cache: usersCache)
            let match = Match(player1: player1, player2: player2)
            let lm = LeagueMatch(league: league, match: match, round: m.round, matchNumber: 1)
            lm.id = m.id
            if let p1Score = m.player1Score, let p2Score = m.player2Score {
                match.player1Score = p1Score
                match.player2Score = p2Score
            }
            lm.status = LeagueMatch.MatchStatus(rawValue: m.status) ?? .scheduled
            return lm
        }
        league.matches = matches
        return league
    }
    
    private func fetchOrCreateUser(id: String, name: String = "Player", elo: Int = 1000, cache: [String: User]) -> User {
        if let cached = cache[id] { return cached }
        if let existing = (try? modelContext.fetch(FetchDescriptor<User>()))?.first(where: { $0.id.uuidString == id }) {
            return existing
        }
        let user = User(email: "temp@placeholder.com", password: "", elo: elo, xp: 0, totalMatches: 0, wins: 0, losses: 0, winStreak: 0)
        user.id = UUID(uuidString: id) ?? UUID()
        user.displayName = name
        modelContext.insert(user)
        return user
    }
    
    // Remote schedule generation
    func generateScheduleRemote(for league: PickleLeague) async throws {
        guard let network else { return }
        let dto = try await network.generateSchedule(leagueId: league.id) // league.id is already String
        _ = importLeague(from: dto)
    }
    
    func joinLeague(_ league: PickleLeague, user: User) {
        guard !league.players.contains(where: { $0.id == user.id }),
              league.players.count < league.maxPlayers else { return }
        league.players.append(user)
    }
    
    func leaveLeague(_ league: PickleLeague, user: User) {
        league.players.removeAll { $0.id == user.id }
    }
    
    // MARK: - Scheduling
    func generateSchedule(for league: PickleLeague) {
        guard league.format == .roundRobin else { return }
        let players = league.players
        guard players.count >= 2 else { return }
        var matchNumber = 1
        var matches: [LeagueMatch] = []
        for i in 0..<players.count {
            for j in (i+1)..<players.count {
                let match = Match(player1: players[i], player2: players[j])
                let leagueMatch = LeagueMatch(league: league, match: match, round: 1, matchNumber: matchNumber)
                matches.append(leagueMatch)
                matchNumber += 1
            }
        }
        league.matches = matches
    }
    
    // MARK: - Standings
    struct Standing: Identifiable {
        let id: String
        let user: User
        var wins: Int
        var losses: Int
        var points: Int { wins * 3 }
    }
    
    func calculateStandings(for league: PickleLeague) -> [Standing] {
        let matches = league.matches
        var table: [String: Standing] = [:]
        for player in league.players {
            table[player.id.uuidString] = Standing(id: player.id.uuidString, user: player, wins: 0, losses: 0)
        }
        for lm in matches where lm.status == .completed {
            let resultMatch = lm.match
            let p1 = resultMatch.player1
            let p2 = resultMatch.player2
            let p1Win = resultMatch.player1Score > resultMatch.player2Score
            if p1Win {
                if var s1 = table[p1.id.uuidString] { s1.wins += 1; table[p1.id.uuidString] = s1 }
                if var s2 = table[p2.id.uuidString] { s2.losses += 1; table[p2.id.uuidString] = s2 }
            } else {
                if var s1 = table[p2.id.uuidString] { s1.wins += 1; table[p2.id.uuidString] = s1 }
                if var s2 = table[p1.id.uuidString] { s2.losses += 1; table[p1.id.uuidString] = s2 }
            }
        }
        return table.values.sorted { $0.points > $1.points }
    }
    
    // MARK: - Reporting
    func reportMatchResult(leagueMatch: LeagueMatch, p1Score: Int, p2Score: Int) {
        guard leagueMatch.status != .completed else { return }
        let match = leagueMatch.match
        let p1 = match.player1
        let p2 = match.player2
        
        let winner = p1Score > p2Score ? p1 : (p2Score > p1Score ? p2 : nil)
        let eloChange = "0" // Placeholder until Elo calc integrated
        match.player1Score = p1Score
        match.player2Score = p2Score
        match.winner = winner
        match.eloChange = eloChange
        match.status = .completed
        modelContext.insert(match)
        leagueMatch.status = .completed
        leagueMatch.completedDate = Date()
    }
} 