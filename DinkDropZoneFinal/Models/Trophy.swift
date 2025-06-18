import Foundation

// MARK: - Trophy Model

struct Trophy: Codable, Identifiable {
    let id = UUID()
    let type: TrophyType
    let unlockedAt: Date
    
    var title: String {
        return type.title
    }
    
    var description: String {
        return type.description
    }
    
    var icon: String {
        return type.icon
    }
    
    var rarity: TrophyRarity {
        return type.rarity
    }
    
    var isRecent: Bool {
        let daysSinceUnlock = Calendar.current.dateComponents([.day], from: unlockedAt, to: Date()).day ?? 0
        return daysSinceUnlock <= 7
    }
}

// MARK: - Trophy Types

enum TrophyType: String, CaseIterable, Codable {
    // Match-based Trophies
    case firstWin = "first_win"
    case winStreak5 = "win_streak_5"
    case winStreak10 = "win_streak_10"
    case perfectionist = "perfectionist"
    case centurion = "centurion"
    case champion = "champion"
    case grandSlam = "grand_slam"
    
    // Social Trophies
    case socialButterfly = "social_butterfly"
    case messenger = "messenger"
    case teamPlayer = "team_player"
    
    // Level-based Trophies
    case rookie = "rookie"
    case veteran = "veteran"
    case expert = "expert"
    case master = "master"
    case legend = "legend"
    
    // Mission-based Trophies
    case taskmaster = "taskmaster"
    case dedicated = "dedicated"
    case consistent = "consistent"
    
    // Special Trophies
    case xpCollector = "xp_collector"
    case explorer = "explorer"
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case weekendWarrior = "weekend_warrior"
    case streakBreaker = "streak_breaker"
    case comeback = "comeback"
    case unstoppable = "unstoppable"
    
    var title: String {
        switch self {
        case .firstWin: return "First Victory"
        case .winStreak5: return "Hot Streak"
        case .winStreak10: return "Unstoppable"
        case .perfectionist: return "Perfectionist"
        case .centurion: return "Centurion"
        case .champion: return "Champion"
        case .grandSlam: return "Grand Slam"
        case .socialButterfly: return "Social Butterfly"
        case .messenger: return "Messenger"
        case .teamPlayer: return "Team Player"
        case .rookie: return "Rookie"
        case .veteran: return "Veteran"
        case .expert: return "Expert"
        case .master: return "Master"
        case .legend: return "Legend"
        case .taskmaster: return "Taskmaster"
        case .dedicated: return "Dedicated"
        case .consistent: return "Consistent"
        case .xpCollector: return "XP Collector"
        case .explorer: return "Explorer"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .weekendWarrior: return "Weekend Warrior"
        case .streakBreaker: return "Streak Breaker"
        case .comeback: return "Comeback Kid"
        case .unstoppable: return "Unstoppable Force"
        }
    }
    
    var description: String {
        switch self {
        case .firstWin: return "Win your first match"
        case .winStreak5: return "Win 5 matches in a row"
        case .winStreak10: return "Win 10 matches in a row"
        case .perfectionist: return "Win a perfect game (11-0)"
        case .centurion: return "Play 100 matches"
        case .champion: return "Win your first tournament"
        case .grandSlam: return "Win 5 tournaments"
        case .socialButterfly: return "Add 10 friends"
        case .messenger: return "Send 100 messages"
        case .teamPlayer: return "Play 25 social matches"
        case .rookie: return "Reach level 5"
        case .veteran: return "Reach level 10"
        case .expert: return "Reach level 25"
        case .master: return "Reach level 50"
        case .legend: return "Reach level 100"
        case .taskmaster: return "Complete 50 missions"
        case .dedicated: return "Login for 30 consecutive days"
        case .consistent: return "Login for 100 days total"
        case .xpCollector: return "Earn 10,000 total XP"
        case .explorer: return "Visit 10 different courts"
        case .earlyBird: return "Play 10 matches before 9 AM"
        case .nightOwl: return "Play 10 matches after 9 PM"
        case .weekendWarrior: return "Play 50 weekend matches"
        case .streakBreaker: return "End someone's 5+ win streak"
        case .comeback: return "Win after being down 0-8"
        case .unstoppable: return "Win 20 matches in a row"
        }
    }
    
    var icon: String {
        switch self {
        case .firstWin: return "trophy.fill"
        case .winStreak5: return "flame.fill"
        case .winStreak10: return "flame.circle.fill"
        case .perfectionist: return "crown.fill"
        case .centurion: return "gamecontroller.fill"
        case .champion: return "trophy.circle.fill"
        case .grandSlam: return "rosette"
        case .socialButterfly: return "person.3.fill"
        case .messenger: return "message.circle.fill"
        case .teamPlayer: return "person.2.circle.fill"
        case .rookie: return "star"
        case .veteran: return "star.fill"
        case .expert: return "star.circle"
        case .master: return "star.circle.fill"
        case .legend: return "crown"
        case .taskmaster: return "checkmark.circle.fill"
        case .dedicated: return "calendar.circle.fill"
        case .consistent: return "chart.line.uptrend.xyaxis.circle.fill"
        case .xpCollector: return "dollarsign.circle.fill"
        case .explorer: return "location.circle.fill"
        case .earlyBird: return "sunrise.fill"
        case .nightOwl: return "moon.fill"
        case .weekendWarrior: return "calendar.badge.plus"
        case .streakBreaker: return "bolt.slash.fill"
        case .comeback: return "arrow.up.circle.fill"
        case .unstoppable: return "infinity.circle.fill"
        }
    }
    
    var rarity: TrophyRarity {
        switch self {
        case .firstWin, .rookie, .socialButterfly:
            return .common
        case .winStreak5, .perfectionist, .veteran, .messenger, .dedicated:
            return .uncommon
        case .winStreak10, .centurion, .champion, .expert, .teamPlayer, .taskmaster, .consistent, .xpCollector, .explorer:
            return .rare
        case .grandSlam, .master, .earlyBird, .nightOwl, .weekendWarrior, .streakBreaker, .comeback:
            return .epic
        case .legend, .unstoppable:
            return .legendary
        }
    }
    
    var xpReward: Int {
        return rarity.xpReward
    }
    
    static var matchTrophies: [TrophyType] {
        return [.firstWin, .winStreak5, .winStreak10, .perfectionist, .centurion, .champion, .grandSlam, .streakBreaker, .comeback, .unstoppable]
    }
    
    static var socialTrophies: [TrophyType] {
        return [.socialButterfly, .messenger, .teamPlayer]
    }
    
    static var levelTrophies: [TrophyType] {
        return [.rookie, .veteran, .expert, .master, .legend]
    }
    
    static var missionTrophies: [TrophyType] {
        return [.taskmaster, .dedicated, .consistent]
    }
    
    static var specialTrophies: [TrophyType] {
        return [.xpCollector, .explorer, .earlyBird, .nightOwl, .weekendWarrior]
    }
}

// MARK: - Trophy Rarity

enum TrophyRarity: String, CaseIterable, Codable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var title: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }
    
    var color: String {
        switch self {
        case .common: return "gray"
        case .uncommon: return "green"
        case .rare: return "blue"
        case .epic: return "purple"
        case .legendary: return "orange"
        }
    }
    
    var xpReward: Int {
        switch self {
        case .common: return 100
        case .uncommon: return 200
        case .rare: return 300
        case .epic: return 500
        case .legendary: return 1000
        }
    }
    
    var sparkleCount: Int {
        switch self {
        case .common: return 0
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 3
        case .legendary: return 5
        }
    }
} 