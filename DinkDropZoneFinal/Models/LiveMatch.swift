import Foundation
import SwiftData

@Model
final class LiveMatch: Identifiable {
    @Attribute(.unique) var id: String
    var player1: String
    var player2: String
    var court: String
    var startTime: Date
    var isLive: Bool
    
    var timeElapsed: String {
        let minutes = Int(Date().timeIntervalSince(startTime) / 60)
        return "\(minutes) min"
    }
    
    init(id: String = UUID().uuidString,
         player1: String,
         player2: String,
         court: String,
         startTime: Date = Date(),
         isLive: Bool = true) {
        self.id = id
        self.player1 = player1
        self.player2 = player2
        self.court = court
        self.startTime = startTime
        self.isLive = isLive
    }
} 