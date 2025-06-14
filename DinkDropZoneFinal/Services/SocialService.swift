import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class SocialService {
    
    private var modelContext: ModelContext
    
    // Social state
    var communityPosts: [CommunityPost] = []
    var conversations: [Conversation] = []
    var friendsList: [User] = []
    var friendRequests: [FriendRequest] = []
    var onlineUsers: [User] = []
    var blockedUsers: [User] = []
    
    // Activity tracking
    var userActivity: [UserActivity] = []
    var leaderboard: [LeaderboardEntry] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSocialData()
        generateSampleData()
    }
    
    // MARK: - Community Posts
    
    func createPost(
        author: User,
        content: String,
        type: PostType,
        attachments: [PostAttachment] = []
    ) -> CommunityPost {
        let post = CommunityPost(
            id: UUID(),
            author: author,
            content: content,
            type: type,
            attachments: attachments,
            createdAt: Date()
        )
        
        communityPosts.insert(post, at: 0)
        
        // Add to user activity
        let activity = UserActivity(
            user: author,
            type: .post,
            description: "Posted in community",
            timestamp: Date()
        )
        userActivity.insert(activity, at: 0)
        
        LoggingService.shared.log("Community post created by \(author.displayName)")
        
        NotificationCenter.default.post(
            name: .newCommunityPost,
            object: post
        )
        
        return post
    }
    
    func likePost(_ post: CommunityPost, by user: User) {
        if !post.likes.contains(where: { $0.id == user.id }) {
            post.likes.append(user)
            post.likesCount += 1
            
            // Notify post author if not self-like
            if post.author.id != user.id {
                sendNotification(
                    to: post.author,
                    type: "like",
                    title: "New Like",
                    message: "\(user.displayName) liked your post"
                )
            }
        }
    }
    
    func unlikePost(_ post: CommunityPost, by user: User) {
        post.likes.removeAll { $0.id == user.id }
        post.likesCount = max(0, post.likesCount - 1)
    }
    
    func commentOnPost(_ post: CommunityPost, comment: String, by user: User) {
        let postComment = PostComment(
            id: UUID(),
            author: user,
            content: comment,
            createdAt: Date()
        )
        
        post.comments.append(postComment)
        post.commentsCount += 1
        
        // Notify post author
        if post.author.id != user.id {
            sendNotification(
                to: post.author,
                type: "comment",
                title: "New Comment",
                message: "\(user.displayName) commented on your post"
            )
        }
    }
    
    // MARK: - Friend System
    
    func sendFriendRequest(from sender: User, to recipient: User) -> Bool {
        // Check if already friends or request exists
        if areFriends(sender, recipient) ||
           friendRequests.contains(where: { ($0.sender.id == sender.id && $0.recipient.id == recipient.id) ||
                                          ($0.sender.id == recipient.id && $0.recipient.id == sender.id) }) {
            return false
        }
        
        let request = FriendRequest(
            sender: sender,
            recipient: recipient,
            status: .pending,
            createdAt: Date()
        )
        
        friendRequests.append(request)
        
        sendNotification(
            to: recipient,
            type: "friendRequest",
            title: "Friend Request",
            message: "\(sender.displayName) wants to be your friend"
        )
        
        LoggingService.shared.log("Friend request sent from \(sender.displayName) to \(recipient.displayName)")
        
        return true
    }
    
    func acceptFriendRequest(_ request: FriendRequest) {
        request.status = .accepted
        
        // Add each other as friends
        if !friendsList.contains(where: { $0.id == request.sender.id }) {
            friendsList.append(request.sender)
        }
        
        // Remove from pending requests
        friendRequests.removeAll { $0.id == request.id }
        
        sendNotification(
            to: request.sender,
            type: "friendAccepted",
            title: "Friend Request Accepted",
            message: "\(request.recipient.displayName) accepted your friend request"
        )
        
        LoggingService.shared.log("Friend request accepted: \(request.sender.displayName) and \(request.recipient.displayName)")
    }
    
    func declineFriendRequest(_ request: FriendRequest) {
        request.status = .declined
        friendRequests.removeAll { $0.id == request.id }
        
        LoggingService.shared.log("Friend request declined")
    }
    
    func removeFriend(_ friend: User, by user: User) {
        friendsList.removeAll { $0.id == friend.id }
        
        LoggingService.shared.log("Friendship ended between \(user.displayName) and \(friend.displayName)")
    }
    
    func areFriends(_ user1: User, _ user2: User) -> Bool {
        return friendsList.contains(where: { $0.id == user1.id || $0.id == user2.id })
    }
    
    // MARK: - Messaging System
    
    func startConversation(participants: [User], initiator: User) -> Conversation {
        let conversation = Conversation(
            id: UUID(),
            participants: participants,
            createdAt: Date(),
            lastActivity: Date()
        )
        
        conversations.append(conversation)
        
        LoggingService.shared.log("Conversation started by \(initiator.displayName)")
        
        return conversation
    }
    
    func sendMessage(
        to conversation: Conversation,
        content: String,
        sender: User,
        type: MessageType = .text
    ) -> Message {
        let message = Message(
            id: UUID(),
            content: content,
            sender: sender,
            type: type,
            timestamp: Date()
        )
        
        conversation.messages.append(message)
        conversation.lastActivity = Date()
        conversation.lastMessage = message
        
        // Update unread counts for other participants
        for participant in conversation.participants {
            if participant.id != sender.id {
                conversation.unreadCounts[participant.id.uuidString] = (conversation.unreadCounts[participant.id.uuidString] ?? 0) + 1
            }
        }
        
        // Send push notification to other participants
        for participant in conversation.participants {
            if participant.id != sender.id {
                sendNotification(
                    to: participant,
                    type: "message",
                    title: "New Message",
                    message: "\(sender.displayName): \(content)"
                )
            }
        }
        
        return message
    }
    
    func markConversationAsRead(_ conversation: Conversation, by user: User) {
        conversation.unreadCounts[user.id.uuidString] = 0
    }
    
    // MARK: - User Activity & Presence
    
    func updateUserOnlineStatus(_ user: User, isOnline: Bool) {
        if isOnline {
            if !onlineUsers.contains(where: { $0.id == user.id }) {
                onlineUsers.append(user)
            }
        } else {
            onlineUsers.removeAll { $0.id == user.id }
        }
        
        // Broadcast presence update
        NotificationCenter.default.post(
            name: .userPresenceChanged,
            object: user,
            userInfo: ["isOnline": isOnline]
        )
    }
    
    func recordActivity(_ activity: UserActivity) {
        userActivity.insert(activity, at: 0)
        
        // Keep only recent activities (last 100)
        if userActivity.count > 100 {
            userActivity = Array(userActivity.prefix(100))
        }
    }
    
    func getRecentActivity(for user: User, limit: Int = 10) -> [UserActivity] {
        return Array(userActivity.filter { $0.user.id == user.id }.prefix(limit))
    }
    
    // MARK: - Leaderboards
    
    func updateLeaderboard() {
        // Fetch all users and sort by different criteria
        let descriptor = FetchDescriptor<User>()
        let allUsers = (try? modelContext.fetch(descriptor)) ?? []
        
        // ELO Leaderboard
        let eloSorted = allUsers.sorted { $0.elo > $1.elo }
        leaderboard = eloSorted.enumerated().map { index, user in
            LeaderboardEntry(
                rank: index + 1,
                user: user,
                value: user.elo,
                metric: .elo,
                change: calculateRankChange(for: user, metric: .elo)
            )
        }
    }
    
    func getLeaderboard(for metric: LeaderboardMetric, limit: Int = 50) -> [LeaderboardEntry] {
        let descriptor = FetchDescriptor<User>()
        let allUsers = (try? modelContext.fetch(descriptor)) ?? []
        
        let sorted: [User]
        switch metric {
        case .elo:
            sorted = allUsers.sorted { $0.elo > $1.elo }
        case .wins:
            sorted = allUsers.sorted { $0.wins > $1.wins }
        case .winRate:
            sorted = allUsers.sorted { $0.winRate > $1.winRate }
        case .winStreak:
            sorted = allUsers.sorted { $0.winStreak > $1.winStreak }
        case .totalMatches:
            sorted = allUsers.sorted { $0.totalMatches > $1.totalMatches }
        }
        
        return Array(sorted.prefix(limit)).enumerated().map { index, user in
            LeaderboardEntry(
                rank: index + 1,
                user: user,
                value: getMetricValue(for: user, metric: metric),
                metric: metric,
                change: calculateRankChange(for: user, metric: metric)
            )
        }
    }
    
    // MARK: - Court & Location Features
    
    func findNearbyPlayers(for user: User, radius: Double = 50.0) -> [User] {
        // In a real app, this would use location services
        // For now, return users in same location
        let descriptor = FetchDescriptor<User>()
        let allUsers = (try? modelContext.fetch(descriptor)) ?? []
        
        return allUsers.filter { $0.location == user.location && $0.id != user.id }
    }
    
    func findNearbyCourts(for location: String) -> [Court] {
        // Sample court data
        return [
            Court(name: "Golden Gate Park Courts", location: location, distance: 0.8, courts: 4, status: .available),
            Court(name: "Mission Bay Recreation", location: location, distance: 1.2, courts: 6, status: .busy),
            Court(name: "Presidio Sports Complex", location: location, distance: 2.1, courts: 8, status: .available)
        ]
    }
    
    // MARK: - Private Helper Methods
    
    private func sendNotification(to user: User, type: String, title: String, message: String) {
        // In a real app, this would send push notifications
        LoggingService.shared.log("Notification sent to \(user.displayName): \(title)")
    }
    
    private func calculateRankChange(for user: User, metric: LeaderboardMetric) -> Int {
        // This would compare with previous rankings
        // For now, return random changes
        return Int.random(in: -5...5)
    }
    
    private func getMetricValue(for user: User, metric: LeaderboardMetric) -> Int {
        switch metric {
        case .elo: return user.elo
        case .wins: return user.wins
        case .winRate: return Int(user.winRate * 100)
        case .winStreak: return user.winStreak
        case .totalMatches: return user.totalMatches
        }
    }
    
    private func loadSocialData() {
        // Load existing social data from storage
    }
    
    private func generateSampleData() {
        // Generate sample community posts
        generateSamplePosts()
        
        // Generate sample conversations
        generateSampleConversations()
        
        // Update leaderboard
        updateLeaderboard()
    }
    
    private func generateSamplePosts() {
        let sampleUsers = generateSampleUsers()
        let postTypes: [PostType] = [.general, .matchResult, .achievement, .question]
        
        let sampleContents = [
            "Just had an amazing match at Golden Gate Park! Who's up for a game tomorrow?",
            "Finally broke 1500 ELO! 🎾 The grind continues...",
            "Looking for a doubles partner for the weekend tournament. Any takers?",
            "That backhand slice is finally clicking! Practice pays off 💪",
            "Shoutout to @alex for the great match today. Always fun playing against strong competition!",
            "New to pickleball and loving it! Any tips for improving my serve?",
            "Tournament bracket is out! Good luck to everyone competing this weekend 🏆"
        ]
        
        for i in 0..<7 {
            if i < sampleUsers.count && i < sampleContents.count {
                let post = CommunityPost(
                    id: UUID(),
                    author: sampleUsers[i],
                    content: sampleContents[i],
                    type: postTypes.randomElement() ?? .general,
                    createdAt: Calendar.current.date(byAdding: .hour, value: -i, to: Date()) ?? Date()
                )
                
                // Add some likes and comments
                post.likesCount = Int.random(in: 2...15)
                post.commentsCount = Int.random(in: 0...8)
                
                communityPosts.append(post)
            }
        }
    }
    
    private func generateSampleConversations() {
        let sampleUsers = generateSampleUsers()
        
        if sampleUsers.count >= 2 {
            let conversation = Conversation(
                id: UUID(),
                participants: Array(sampleUsers.prefix(2)),
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                lastActivity: Date()
            )
            
            // Add sample messages
            let messages = [
                Message(id: UUID(), content: "Hey! Want to play tomorrow morning?", sender: sampleUsers[0], type: .text, timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()),
                Message(id: UUID(), content: "Sure! What time works for you?", sender: sampleUsers[1], type: .text, timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date()),
                Message(id: UUID(), content: "How about 9 AM at Golden Gate Park?", sender: sampleUsers[0], type: .text, timestamp: Date())
            ]
            
            conversation.messages = messages
            conversation.lastMessage = messages.last
            
            conversations.append(conversation)
        }
    }
    
    private func generateSampleUsers() -> [User] {
        let names = ["Alex Chen", "Sarah Kim", "Mike Johnson", "Emma Wilson", "David Park"]
        return names.map { name in
            let user = User(
                email: "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@example.com",
                password: "password",
                elo: Int.random(in: 1000...2000),
                xp: Int.random(in: 500...3000),
                totalMatches: Int.random(in: 10...80),
                wins: Int.random(in: 5...50),
                losses: Int.random(in: 3...30),
                winStreak: Int.random(in: 0...8)
            )
            user.displayName = name
            user.location = "San Francisco"
            return user
        }
    }
}

// MARK: - Social Data Models

class CommunityPost: ObservableObject, Identifiable {
    let id: UUID
    let author: User
    let content: String
    let type: PostType
    let attachments: [PostAttachment]
    let createdAt: Date
    
    @Published var likes: [User] = []
    @Published var comments: [PostComment] = []
    @Published var likesCount: Int = 0
    @Published var commentsCount: Int = 0
    @Published var isEdited: Bool = false
    
    init(id: UUID, author: User, content: String, type: PostType, attachments: [PostAttachment] = [], createdAt: Date) {
        self.id = id
        self.author = author
        self.content = content
        self.type = type
        self.attachments = attachments
        self.createdAt = createdAt
    }
}

enum PostType: String, CaseIterable {
    case general = "General"
    case matchResult = "Match Result"
    case achievement = "Achievement"
    case question = "Question"
    case event = "Event"
    case announcement = "Announcement"
    
    var icon: String {
        switch self {
        case .general: return "bubble.left"
        case .matchResult: return "gamecontroller"
        case .achievement: return "trophy"
        case .question: return "questionmark.circle"
        case .event: return "calendar"
        case .announcement: return "megaphone"
        }
    }
    
    var color: String {
        switch self {
        case .general: return "blue"
        case .matchResult: return "green"
        case .achievement: return "purple"
        case .question: return "orange"
        case .event: return "red"
        case .announcement: return "yellow"
        }
    }
}

struct PostAttachment {
    let id: UUID
    let type: AttachmentType
    let url: String
    let thumbnailUrl: String?
    
    init(type: AttachmentType, url: String, thumbnailUrl: String? = nil) {
        self.id = UUID()
        self.type = type
        self.url = url
        self.thumbnailUrl = thumbnailUrl
    }
}

enum AttachmentType {
    case image, video, link
}

struct PostComment: Identifiable {
    let id: UUID
    let author: User
    let content: String
    let createdAt: Date
}

class Conversation: ObservableObject, Identifiable {
    let id: UUID
    let participants: [User]
    let createdAt: Date
    
    @Published var messages: [Message] = []
    @Published var lastActivity: Date
    @Published var lastMessage: Message?
    @Published var unreadCounts: [String: Int] = [:]
    @Published var isTyping: [User] = []
    
    init(id: UUID, participants: [User], createdAt: Date, lastActivity: Date) {
        self.id = id
        self.participants = participants
        self.createdAt = createdAt
        self.lastActivity = lastActivity
    }
    
    func getOtherParticipants(excluding user: User) -> [User] {
        return participants.filter { $0.id != user.id }
    }
    
    func getUnreadCount(for user: User) -> Int {
        return unreadCounts[user.id.uuidString] ?? 0
    }
}

struct Message: Identifiable {
    let id: UUID
    let content: String
    let sender: User
    let type: MessageType
    let timestamp: Date
    var isRead: Bool = false
    var reactions: [MessageReaction] = []
}

enum MessageType {
    case text, image, matchInvite, locationShare
}

struct MessageReaction {
    let user: User
    let emoji: String
    let timestamp: Date
}

class FriendRequest: ObservableObject, Identifiable {
    let id: UUID
    let sender: User
    let recipient: User
    let createdAt: Date
    
    @Published var status: FriendRequestStatus
    
    init(sender: User, recipient: User, status: FriendRequestStatus, createdAt: Date) {
        self.id = UUID()
        self.sender = sender
        self.recipient = recipient
        self.status = status
        self.createdAt = createdAt
    }
}

enum FriendRequestStatus {
    case pending, accepted, declined
}

struct UserActivity: Identifiable {
    let id: UUID
    let user: User
    let type: ActivityType
    let description: String
    let timestamp: Date
    
    init(user: User, type: ActivityType, description: String, timestamp: Date) {
        self.id = UUID()
        self.user = user
        self.type = type
        self.description = description
        self.timestamp = timestamp
    }
}

enum ActivityType {
    case match, post, achievement, friendAdd, tournament
    
    var icon: String {
        switch self {
        case .match: return "gamecontroller"
        case .post: return "bubble.left"
        case .achievement: return "trophy"
        case .friendAdd: return "person.badge.plus"
        case .tournament: return "crown"
        }
    }
}

struct LeaderboardEntry: Identifiable {
    let id: UUID
    let rank: Int
    let user: User
    let value: Int
    let metric: LeaderboardMetric
    let change: Int
    
    init(rank: Int, user: User, value: Int, metric: LeaderboardMetric, change: Int) {
        self.id = UUID()
        self.rank = rank
        self.user = user
        self.value = value
        self.metric = metric
        self.change = change
    }
}

enum LeaderboardMetric: String, CaseIterable {
    case elo = "ELO"
    case wins = "Wins"
    case winRate = "Win Rate"
    case winStreak = "Win Streak"
    case totalMatches = "Total Matches"
    
    var icon: String {
        switch self {
        case .elo: return "chart.bar"
        case .wins: return "trophy"
        case .winRate: return "percent"
        case .winStreak: return "flame"
        case .totalMatches: return "gamecontroller"
        }
    }
}

struct Court: Identifiable {
    let id: UUID
    let name: String
    let location: String
    let distance: Double
    let courts: Int
    let status: CourtStatus
    
    init(name: String, location: String, distance: Double, courts: Int, status: CourtStatus) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.distance = distance
        self.courts = courts
        self.status = status
    }
}

enum CourtStatus {
    case available, busy, full, closed
    
    var color: String {
        switch self {
        case .available: return "green"
        case .busy: return "orange"
        case .full: return "red"
        case .closed: return "gray"
        }
    }
    
    var description: String {
        switch self {
        case .available: return "Available"
        case .busy: return "Busy"
        case .full: return "Full"
        case .closed: return "Closed"
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let newCommunityPost = Notification.Name("newCommunityPost")
    static let userPresenceChanged = Notification.Name("userPresenceChanged")
    static let newMessage = Notification.Name("newMessage")
    static let friendRequestReceived = Notification.Name("friendRequestReceived")
    static let friendRequestAccepted = Notification.Name("friendRequestAccepted")
} 