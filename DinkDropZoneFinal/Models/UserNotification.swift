import Foundation

public enum UserNotificationType: String, Codable {
    case match = "Match"
    case achievement = "Achievement"
    case friend = "Friend"
    case league = "League"
    case system = "System"
}

public struct UserNotification: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let message: String
    public let type: UserNotificationType
    public let date: Date
    public var isRead: Bool
    
    public init(id: UUID = UUID(), title: String, message: String, type: UserNotificationType, date: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.title = title
        self.message = message
        self.type = type
        self.date = date
        self.isRead = isRead
    }
}