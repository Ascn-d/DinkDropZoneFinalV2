import Foundation
import SwiftData

@Model
public final class Match {
    public var id: UUID
    public var player1: User
    public var player2: User
    public var player1Score: Int?
    public var player2Score: Int?
    public var timestamp: Date

    public init(id: UUID = .init(), player1: User, player2: User, timestamp: Date = .init()) {
        self.id = id
        self.player1 = player1
        self.player2 = player2
        self.timestamp = timestamp
    }
} 