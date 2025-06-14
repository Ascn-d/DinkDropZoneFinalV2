import Foundation
import SwiftData

@Model
final class Team {
    var id: String
    var name: String
    var players: [User]
    
    init(id: String = UUID().uuidString, name: String, players: [User] = []) {
        self.id = id
        self.name = name
        self.players = players
    }
} 