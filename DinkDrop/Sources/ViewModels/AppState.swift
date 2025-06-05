import Observation
import SwiftData

@Observable
@MainActor
final class AppState {
    var currentUser: User? = nil
    var currentMatch: Match? = nil

    // In-memory queue for matchmaking
    @ObservationIgnored
    var queue: [User] = []
} 