import Foundation
import SwiftData

@Model
final class QueueTournament: Identifiable {
    @Attribute(.unique) var id: String
    var name: String
    var participants: Int
    var maxParticipants: Int
    var startTime: Date
    
    init(id: String = UUID().uuidString,
         name: String,
         participants: Int,
         maxParticipants: Int,
         startTime: Date) {
        self.id = id
        self.name = name
        self.participants = participants
        self.maxParticipants = maxParticipants
        self.startTime = startTime
    }
    
    var startTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }
} 