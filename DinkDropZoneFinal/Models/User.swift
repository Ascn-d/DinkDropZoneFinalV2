import Foundation
import SwiftData

@Model
public final class User {
    public var id: UUID
    public var email: String
    public var elo: Int
    public var xp: Int

    public init(id: UUID = .init(), email: String, elo: Int = 1000, xp: Int = 0) {
        self.id = id
        self.email = email
        self.elo = elo
        self.xp = xp
    }
} 