import SwiftData
import Foundation

@MainActor
struct SeedDataService {
    static func seedIfNeeded(modelContext: ModelContext) {
        // Live matches
        if try! modelContext.fetch(FetchDescriptor<LiveMatch>()).isEmpty {
            let samples: [LiveMatch] = [
                LiveMatch(player1: "Sarah C.", player2: "Mike J.", court: "Court 1"),
                LiveMatch(player1: "Emma W.", player2: "Alex T.", court: "Court 3")
            ]
            samples.forEach { modelContext.insert($0) }
        }
        // Tournaments
        if try! modelContext.fetch(FetchDescriptor<QueueTournament>()).isEmpty {
            let today = Date()
            let tourneys = [
                QueueTournament(name: "Friday Night Lights", participants: 16, maxParticipants: 32, startTime: today.addingTimeInterval(3600*5)),
                QueueTournament(name: "Weekend Warriors", participants: 8, maxParticipants: 16, startTime: today.addingTimeInterval(3600*12))
            ]
            tourneys.forEach { modelContext.insert($0) }
        }
    }
} 