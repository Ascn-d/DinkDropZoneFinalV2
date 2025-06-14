import Foundation

@Observable
final class FirebaseService {
    static let shared = FirebaseService()
    private init() {}

    enum FirebaseError: Error { case unsupported }

    // MARK: - Authentication (stubs)
    func signIn(email: String, password: String) async throws -> User {
        throw FirebaseError.unsupported
    }

    func signOut() throws {
        // No-op for stub
    }

    // MARK: - User Management (stubs)
    func createUser(_ user: User) async throws {
        // No-op for stub
    }

    func updateUser(_ user: User) async throws {
        // No-op for stub
    }

    func getUser(id: String) async throws -> User {
        throw FirebaseError.unsupported
    }

    // MARK: - League Management (stubs)
    func createLeague(_ league: PickleLeague) async throws {}
    func updateLeague(_ league: PickleLeague) async throws {}
    func getLeague(id: String) async throws -> PickleLeague { throw FirebaseError.unsupported }
    func getLeagues() async throws -> [PickleLeague] { [] }
    func joinLeague(_ league: PickleLeague, user: User) async throws {}
    func leaveLeague(_ league: PickleLeague, user: User) async throws {}
    func startLeague(_ league: PickleLeague) async throws {}

    // MARK: - Match Management (stubs)
    func createMatch(_ match: LeagueMatch) async throws {}
    func updateMatch(_ match: LeagueMatch) async throws {}
    func getMatches(for league: PickleLeague) async throws -> [LeagueMatch] { [] }
} 