import Foundation
import SwiftData

actor MatchService {
    private var queue: [User] = []
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func enqueue(_ user: User) async -> Match? {
        guard !queue.contains(where: { $0.id == user.id }) else { return nil }
        queue.append(user)
        if queue.count >= 2 {
            let p1 = queue.removeFirst()
            let p2 = queue.removeFirst()
            let match = Match(player1: p1, player2: p2)
            context.insert(match)
            try? context.save()
            return match
        }
        return nil
    }
} 