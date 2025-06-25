import Foundation

// MARK: - Mission Model

struct Mission: Identifiable, Codable {
    var id: UUID = UUID()
    var type: MissionType
    var progress: Int = 0
    var isCompleted: Bool = false
    var completedAt: Date? = nil
    var createdAt: Date = Date()
    
    var progressPercentage: Double {
        return min(Double(progress) / Double(type.targetValue), 1.0)
    }
    
    var xpReward: Int {
        return type.xpReward
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, progress, isCompleted, completedAt, createdAt
    }
    
    init(type: MissionType, progress: Int = 0, isCompleted: Bool = false) {
        self.type = type
        self.progress = progress
        self.isCompleted = isCompleted
        
        // Auto-complete if progress meets target
        if progress >= type.targetValue {
            self.isCompleted = true
            self.completedAt = Date()
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(MissionType.self, forKey: .type)
        progress = try container.decode(Int.self, forKey: .progress)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(progress, forKey: .progress)
        try container.encode(isCompleted, forKey: .isCompleted)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    // Add method to update progress with an increment parameter
    mutating func updateProgress(increment: Int = 1) -> Bool {
        guard !isCompleted else { return false }
        
        progress += increment
        
        // Check if mission is now complete
        if progress >= type.targetValue {
            isCompleted = true
            completedAt = Date()
            return true
        }
        return false
    }
    
    // Add method to set progress to a specific value
    mutating func updateProgress(to newProgress: Int) -> Bool {
        guard !isCompleted else { return false }
        
        progress = newProgress
        
        // Check if mission is now complete
        if progress >= type.targetValue {
            isCompleted = true
            completedAt = Date()
            return true
        }
        return false
    }
    
    // Add method to update progress
    mutating func updateProgress(for reward: XPManager.XPReward) {
        guard !isCompleted else { return }
        
        // Determine how much to increment based on the reward type
        var increment = 0
        
        switch (type, reward) {
        case (.playMatches, .matchComplete), (.playMatches, .matchWin), (.playMatches, .matchLoss):
            increment = 1
        case (.winMatches, .matchWin):
            increment = 1
        case (.scorePoints, .matchComplete):
            increment = 5 // Assume 5 points per match
        case (.playTournament, .tournamentJoin):
            increment = 1
        case (.winStreak, .winStreak3), (.winStreak, .winStreak5), (.winStreak, .winStreak10):
            increment = 1
        case (.addFriends, .friendAdded):
            increment = 1
        case (.perfectGame, .perfectGame):
            increment = 1
        case (.reachElo, .skillImprovement):
            increment = 50 // Assume 50 ELO per skill improvement
        case (.playWithFriends, .socialMatch):
            increment = 1
        default:
            // No match, no increment
            break
        }
        
        if increment > 0 {
            progress += increment
            
            // Check if mission is now complete
            if progress >= type.targetValue {
                isCompleted = true
                completedAt = Date()
            }
        }
    }
}

// MARK: - Mission Types

// Define MissionType as a top-level enum to avoid conflicts
enum MissionType: String, Codable, CaseIterable {
    // Daily missions
    case playMatches = "playMatches"
    case winMatches = "winMatches"
    case scorePoints = "scorePoints"
    
    // Weekly missions
    case playTournament = "playTournament"
    case winStreak = "winStreak"
    case addFriends = "addFriends"
    
    // Achievement missions
    case perfectGame = "perfectGame"
    case reachElo = "reachElo"
    case playWithFriends = "playWithFriends"
    
    var title: String {
        switch self {
        case .playMatches: return "Play Matches"
        case .winMatches: return "Win Matches"
        case .scorePoints: return "Score Points"
        case .playTournament: return "Play Tournament"
        case .winStreak: return "Win Streak"
        case .addFriends: return "Add Friends"
        case .perfectGame: return "Perfect Game"
        case .reachElo: return "Reach ELO Rating"
        case .playWithFriends: return "Play With Friends"
        }
    }
    
    var isDaily: Bool {
        switch self {
        case .playMatches, .winMatches, .scorePoints:
            return true
        default:
            return false
        }
    }
    
    var isWeekly: Bool {
        switch self {
        case .playTournament, .winStreak, .addFriends:
            return true
        default:
            return false
        }
    }
    
    var isAchievement: Bool {
        switch self {
        case .perfectGame, .reachElo, .playWithFriends:
            return true
        default:
            return false
        }
    }
    
    var targetValue: Int {
        switch self {
        case .playMatches: return 3
        case .winMatches: return 2
        case .scorePoints: return 21
        case .playTournament: return 1
        case .winStreak: return 5
        case .addFriends: return 3
        case .perfectGame: return 1
        case .reachElo: return 1500
        case .playWithFriends: return 5
        }
    }
    
    var xpReward: Int {
        switch self {
        case .playMatches: return 50
        case .winMatches: return 75
        case .scorePoints: return 60
        case .playTournament: return 100
        case .winStreak: return 150
        case .addFriends: return 80
        case .perfectGame: return 200
        case .reachElo: return 250
        case .playWithFriends: return 120
        }
    }
    
    var icon: String {
        switch self {
        case .playMatches: return "gamecontroller.fill"
        case .winMatches: return "trophy.fill"
        case .scorePoints: return "number.circle.fill"
        case .playTournament: return "flag.fill"
        case .winStreak: return "flame.fill"
        case .addFriends: return "person.badge.plus.fill"
        case .perfectGame: return "crown.fill"
        case .reachElo: return "star.fill"
        case .playWithFriends: return "person.2.fill"
        }
    }
    
    var color: String {
        switch self {
        case .playMatches, .playTournament, .playWithFriends: return "blue"
        case .winMatches, .perfectGame, .reachElo: return "gold"
        case .scorePoints, .winStreak, .addFriends: return "purple"
        }
    }
    
    var description: String {
        switch self {
        case .playMatches: return "Play matches to earn XP"
        case .winMatches: return "Win matches against opponents"
        case .scorePoints: return "Score points in matches"
        case .playTournament: return "Participate in a tournament"
        case .winStreak: return "Win consecutive matches"
        case .addFriends: return "Add friends to your network"
        case .perfectGame: return "Win a match 11-0"
        case .reachElo: return "Reach specified ELO rating"
        case .playWithFriends: return "Play matches with friends"
        }
    }
} 