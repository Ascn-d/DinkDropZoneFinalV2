import Foundation
import SwiftData

// MARK: - Tournament v2 Pro Circuit Models

// MARK: - Enhanced Tournament Format Support

enum TournamentFormatV2: String, CaseIterable, Codable {
    case singleElimination = "Single Elimination"
    case doubleElimination = "Double Elimination" 
    case roundRobin = "Round Robin"
    case swiss = "Swiss System"
    case poolPlay = "Pool Play"
    case poolToBracket = "Pool-to-Bracket"
    
    var supportsPhases: Bool {
        switch self {
        case .poolToBracket: return true
        case .swiss: return true
        default: return false
        }
    }
    
    var minParticipants: Int {
        switch self {
        case .swiss: return 8
        case .poolPlay, .poolToBracket: return 12
        default: return 4
        }
    }
    
    var optimalParticipants: Int {
        switch self {
        case .swiss: return 32
        case .poolPlay, .poolToBracket: return 24
        default: return 16
        }
    }
}

// MARK: - Feature Flag System

@MainActor
class FeatureFlagService: ObservableObject {
    @Published var flags: FeatureFlags = FeatureFlags()
    
    private let userDefaults = UserDefaults.standard
    private let flagPrefix = "feature_flag_"
    
    init() {
        loadFlags()
    }
    
    func isEnabled(_ flag: FeatureFlagKey) -> Bool {
        switch flag {
        case .swiss: return flags.swissEnabled
        case .poolPlay: return flags.poolPlayEnabled
        case .liveActivities: return flags.liveActivitiesEnabled
        case .pushNotifications: return flags.pushNotificationsEnabled
        case .courtScheduling: return flags.courtSchedulingEnabled
        case .analytics: return flags.analyticsEnabled
        case .watchCompanion: return flags.watchCompanionEnabled
        case .referralSystem: return flags.referralSystemEnabled
        }
    }
    
    func setFlag(_ flag: FeatureFlagKey, enabled: Bool) {
        switch flag {
        case .swiss: flags.swissEnabled = enabled
        case .poolPlay: flags.poolPlayEnabled = enabled
        case .liveActivities: flags.liveActivitiesEnabled = enabled
        case .pushNotifications: flags.pushNotificationsEnabled = enabled
        case .courtScheduling: flags.courtSchedulingEnabled = enabled
        case .analytics: flags.analyticsEnabled = enabled
        case .watchCompanion: flags.watchCompanionEnabled = enabled
        case .referralSystem: flags.referralSystemEnabled = enabled
        }
        
        userDefaults.set(enabled, forKey: flagPrefix + flag.rawValue)
    }
    
    private func loadFlags() {
        flags.swissEnabled = userDefaults.bool(forKey: flagPrefix + "swiss")
        flags.poolPlayEnabled = userDefaults.bool(forKey: flagPrefix + "poolPlay")
        flags.liveActivitiesEnabled = userDefaults.bool(forKey: flagPrefix + "liveActivities")
        flags.pushNotificationsEnabled = userDefaults.bool(forKey: flagPrefix + "pushNotifications")
        flags.courtSchedulingEnabled = userDefaults.bool(forKey: flagPrefix + "courtScheduling")
        flags.analyticsEnabled = userDefaults.bool(forKey: flagPrefix + "analytics")
        flags.watchCompanionEnabled = userDefaults.bool(forKey: flagPrefix + "watchCompanion")
        flags.referralSystemEnabled = userDefaults.bool(forKey: flagPrefix + "referralSystem")
    }
}

enum FeatureFlagKey: String, CaseIterable {
    case swiss = "swiss"
    case poolPlay = "poolPlay"
    case liveActivities = "liveActivities"
    case pushNotifications = "pushNotifications"
    case courtScheduling = "courtScheduling"
    case analytics = "analytics"
    case watchCompanion = "watchCompanion"
    case referralSystem = "referralSystem"
}

struct FeatureFlags: Codable, Equatable {
    var swissEnabled: Bool = false
    var poolPlayEnabled: Bool = false
    var liveActivitiesEnabled: Bool = true
    var pushNotificationsEnabled: Bool = true
    var courtSchedulingEnabled: Bool = false
    var analyticsEnabled: Bool = true
    var watchCompanionEnabled: Bool = false
    var referralSystemEnabled: Bool = true
}

// MARK: - Enhanced Tournament Match Models

struct CommentaryEvent: Identifiable, Codable {
    let id: String
    let timestamp: Date
    let type: CommentaryType
    let message: String
    let isSystemGenerated: Bool
    let userId: String?
    
    enum CommentaryType: String, CaseIterable, Codable {
        case matchStart = "match_start"
        case scoreUpdate = "score_update"
        case statusChange = "status_change"
        case userComment = "user_comment"
        case highlight = "highlight"
        case matchEnd = "match_end"
    }
}

struct MatchHighlight: Identifiable, Codable {
    let id: String
    let timestamp: Date
    let type: HighlightType
    let title: String
    let description: String
    let matchId: String
    let playerId: String?
    
    enum HighlightType: String, CaseIterable, Codable {
        case scoreUpdate = "score_update"
        case winner = "winner"
        case comeback = "comeback"
        case longRally = "long_rally"
        case perfectGame = "perfect_game"
        case upset = "upset"
    }
}



struct RallyTracking: Codable {
    var totalRallies: Int = 0
    var averageRallyLength: Double = 0.0
    var longestRally: Int = 0
    var shortRallies: Int = 0 // 1-3 shots
    var mediumRallies: Int = 0 // 4-8 shots
    var longRallies: Int = 0 // 9+ shots
    var rallyLengths: [Int] = []
    
    mutating func addRally(length: Int) {
        totalRallies += 1
        rallyLengths.append(length)
        
        if length <= 3 {
            shortRallies += 1
        } else if length <= 8 {
            mediumRallies += 1
        } else {
            longRallies += 1
        }
        
        if length > longestRally {
            longestRally = length
        }
        
        averageRallyLength = Double(rallyLengths.reduce(0, +)) / Double(rallyLengths.count)
    }
}

struct PlayerStats: Codable {
    let playerId: String
    let rating: Double
    let wins: Int
    let losses: Int
    let totalMatches: Int
    let averageGameScore: Double
    let winStreak: Int
    let lastMatchDate: Date
    let tournamentWins: Int
    let totalPoints: Int
    let winPercentage: Double
    
    var gamesPlayed: Int {
        return wins + losses
    }
    
    var winRate: Double {
        guard gamesPlayed > 0 else { return 0.0 }
        return Double(wins) / Double(gamesPlayed)
    }
}

struct SpectatorReaction: Identifiable, Codable {
    let id: String
    let userId: String
    let matchId: String
    let reaction: String
    let timestamp: Date
    let position: CGPoint?
}

struct ReplayEvent: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let timestamp: Date
    let duration: TimeInterval
    let type: ReplayType
    let matchId: String
    let playerId: String?
    
    enum ReplayType: String, CaseIterable, Codable {
        case winner = "winner"
        case error = "error"
        case longRally = "long_rally"
        case trick_shot = "trick_shot"
        case comeback = "comeback"
        case match_point = "match_point"
    }
}

// MARK: - Live Streaming Models

struct LiveStream: Identifiable, Codable {
    let id: String
    let matchId: String
    let tournamentId: String
    let streamUrl: String
    let isActive: Bool
    let viewerCount: Int
    let startTime: Date
    let quality: StreamQuality
    let features: [StreamFeature]
    
    enum StreamQuality: String, CaseIterable, Codable {
        case low = "480p"
        case medium = "720p"
        case high = "1080p"
        case ultra = "4K"
    }
    
    enum StreamFeature: String, CaseIterable, Codable {
        case chat = "chat"
        case reactions = "reactions"
        case statistics = "statistics"
        case multiCamera = "multi_camera"
        case slowMotion = "slow_motion"
        case commentary = "commentary"
    }
}

struct StreamViewer: Identifiable, Codable {
    let id: String
    let userId: String
    let streamId: String
    let joinTime: Date
    let isActive: Bool
    let reactions: [SpectatorReaction]
}

// MARK: - Professional Broadcasting Models

struct BroadcastOverlay: Codable {
    let showScore: Bool
    let showTimer: Bool
    let showPlayerStats: Bool
    let showSpectatorCount: Bool
    let showCommentary: Bool
    let customBranding: BrandingOptions?
    let position: OverlayPosition
    let opacity: Double
    
    enum OverlayPosition: String, CaseIterable, Codable {
        case topLeft = "top_left"
        case topRight = "top_right"
        case bottomLeft = "bottom_left"
        case bottomRight = "bottom_right"
        case center = "center"
    }
}

struct BrandingOptions: Codable {
    let logoUrl: String?
    let primaryColor: String
    let secondaryColor: String
    let fontFamily: String
    let showWatermark: Bool
    let customGraphics: [String]
}

// MARK: - Social Sharing Models

struct SocialShareContent: Codable {
    let matchId: String
    let tournamentId: String
    let shareType: ShareType
    let content: String
    let mediaUrl: String?
    let hashtags: [String]
    let mentions: [String]
    let timestamp: Date
    
    enum ShareType: String, CaseIterable, Codable {
        case score = "score"
        case highlight = "highlight"
        case victory = "victory"
        case tournament = "tournament"
        case comeback = "comeback"
        case achievement = "achievement"
    }
}

struct SocialPlatform: Codable {
    let name: String
    let isEnabled: Bool
    let apiKey: String?
    let features: [SocialFeature]
    
    enum SocialFeature: String, CaseIterable, Codable {
        case autoPost = "auto_post"
        case liveUpdates = "live_updates"
        case videoSharing = "video_sharing"
        case photoSharing = "photo_sharing"
        case storySharing = "story_sharing"
    }
}

// MARK: - Analytics Models

struct MatchAnalytics: Codable {
    let matchId: String
    let tournamentId: String
    let startTime: Date
    let endTime: Date?
    let totalViewers: Int
    let peakViewers: Int
    let averageViewTime: TimeInterval
    let totalReactions: Int
    let shareCount: Int
    let commentCount: Int
    let highlights: [MatchHighlight]
    let viewerRetention: [RetentionData]
    
    struct RetentionData: Codable {
        let timestamp: Date
        let activeViewers: Int
        let newViewers: Int
        let departedViewers: Int
    }
}

struct TournamentAnalytics: Codable {
    let tournamentId: String
    let totalMatches: Int
    let completedMatches: Int
    let totalViewers: Int
    let totalViewTime: TimeInterval
    let peakConcurrentViewers: Int
    let averageMatchDuration: TimeInterval
    let topHighlights: [MatchHighlight]
    let viewerDemographics: ViewerDemographics
    let engagementMetrics: EngagementMetrics
    
    struct ViewerDemographics: Codable {
        let ageGroups: [String: Int]
        let locations: [String: Int]
        let deviceTypes: [String: Int]
        let newUsers: Int
        let returningUsers: Int
    }
    
    struct EngagementMetrics: Codable {
        let totalReactions: Int
        let totalComments: Int
        let totalShares: Int
        let averageSessionDuration: TimeInterval
        let bounceRate: Double
        let returnRate: Double
    }
}

// MARK: - Spectator Models

struct SpectatorUser: Identifiable, Codable {
    let id = UUID()
    let userId: String
    let displayName: String
    let profileImageURL: String?
    let joinedAt: Date
    let isActive: Bool
    
    var initials: String {
        let components = displayName.components(separatedBy: " ")
        return components.compactMap { $0.first }.map { String($0) }.joined()
    }
}

struct SpectatorNotification: Identifiable, Codable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    let matchId: String?
    let tournamentId: String?
    let userId: String
    let isRead: Bool
    
    enum NotificationType: String, CaseIterable, Codable {
        case matchStart = "match_start"
        case matchEnd = "match_end"
        case scoreUpdate = "score_update"
        case highlight = "highlight"
        case tournamentUpdate = "tournament_update"
        case reaction = "reaction"
        case comment = "comment"
    }
}

// MARK: - Real-time Update Models

struct MatchUpdate: Codable {
    let matchId: String
    let updateType: UpdateType
    let timestamp: Date
    let data: [String: Any]
    
    enum UpdateType: String, CaseIterable, Codable {
        case scoreChange = "score_change"
        case statusChange = "status_change"
        case playerJoin = "player_join"
        case playerLeave = "player_leave"
        case gameStart = "game_start"
        case gameEnd = "game_end"
        case timeout = "timeout"
        case penaltyCall = "penalty_call"
    }
    
    // Custom coding keys to handle [String: Any] data
    enum CodingKeys: String, CodingKey {
        case matchId, updateType, timestamp
    }
    
    init(matchId: String, updateType: UpdateType, timestamp: Date, data: [String: Any] = [:]) {
        self.matchId = matchId
        self.updateType = updateType
        self.timestamp = timestamp
        self.data = data
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        matchId = try container.decode(String.self, forKey: .matchId)
        updateType = try container.decode(UpdateType.self, forKey: .updateType)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        data = [:] // Firebase data would be handled separately
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(matchId, forKey: .matchId)
        try container.encode(updateType, forKey: .updateType)
        try container.encode(timestamp, forKey: .timestamp)
        // Firebase data would be handled separately
    }
}
