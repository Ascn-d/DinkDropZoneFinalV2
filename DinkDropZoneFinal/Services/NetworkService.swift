import Foundation
import Observation
import SwiftUI

@Observable
@MainActor
final class NetworkService {

    // Persisted so testers can switch between local & prod
    @ObservationIgnored
    @AppStorage("apiBaseURL") private var apiBaseURL: String = "http://localhost:3000"
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()
    
    // helper type for empty body/response
    private struct Empty: Codable {}
    
    // MARK: - Low-level wrapper (with body)
    private func request<T: Decodable, U: Encodable>(
        path: String,
        method: String = "GET",
        body: U? = nil,
        as type: T.Type = T.self
    ) async throws -> T {
        guard let url = URL(string: apiBaseURL + path) else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            req.addValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(body)
        }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // Convenience overload for requests with no body
    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        as type: T.Type = T.self
    ) async throws -> T {
        try await request(path: path, method: method, body: Optional<Empty>.none, as: type)
    }
    
    // MARK: - DTOs (mirror backend JSON)
    struct LeagueDTO: Codable {
        let id: String
        let name: String
        let leagueDescription: String?
        let location: String?
        let status: String
        let format: String
        let maxParticipants: Int
        let price: Double?
        let rating: Double?
        let imageUrl: String?
        let schedule: String?
        let nextGame: String?
        let tags: [String]?
        let skillLevel: String?
        let startDate: Date
        let endDate: Date
        let createdAt: Date
        let ownerId: String
        let members: [UserDTO]
        let matches: [MatchDTO]
        let standings: [StandingDTO]
        
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case leagueDescription = "description"
            case location
            case status
            case format
            case maxParticipants
            case price
            case rating
            case imageUrl
            case schedule
            case nextGame
            case tags
            case skillLevel
            case startDate
            case endDate
            case createdAt
            case ownerId
            case members
            case matches
            case standings
        }
    }
    struct UserDTO: Codable { let id: String; let displayName: String; let elo: Int }
    struct MatchDTO: Codable { let id: String; let round: Int; let player1Id: String; let player2Id: String; let player1Score: Int?; let player2Score: Int?; let status: String }
    struct StandingDTO: Codable { let userId: String; let wins: Int; let losses: Int; let points: Int }
    
    // MARK: - High-level helpers
    func fetchLeague(id: String) async throws -> LeagueDTO {
        try await request(path: "/leagues/\(id)", as: LeagueDTO.self)
    }
    
    struct CreateLeagueBody: Codable {
        let name: String
        let description: String?
        let location: String?
        let format: String
        let maxParticipants: Int
        let price: Double?
        let rating: Double?
        let imageUrl: String?
        let schedule: String?
        let nextGame: String?
        let tags: [String]?
        let skillLevel: String?
    }
    func createLeague(_ body: CreateLeagueBody) async throws -> LeagueDTO {
        try await request(path: "/leagues", method: "POST", body: body, as: LeagueDTO.self)
    }
    
    func joinLeague(id: String) async throws -> LeagueDTO {
        try await request(path: "/leagues/\(id)/join", method: "POST", body: Empty(), as: LeagueDTO.self)
    }
    
    func postMatchResult(matchId: String, p1Score: Int, p2Score: Int) async throws {
        struct Body: Codable { let player1Score: Int; let player2Score: Int }
        _ = try await request(path: "/matches/\(matchId)/score", method: "PATCH", body: Body(player1Score: p1Score, player2Score: p2Score), as: Empty.self)
    }
    
    func generateSchedule(leagueId: String) async throws -> LeagueDTO {
        try await request(path: "/matches/auto-generate", method: "POST", body: ["leagueId": leagueId] as [String:String], as: LeagueDTO.self)
    }
} 