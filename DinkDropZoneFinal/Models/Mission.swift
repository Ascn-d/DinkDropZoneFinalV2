import Foundation

// MARK: - Mission Model

struct Mission: Codable, Identifiable {
    let id = UUID()
    let type: MissionType
    let createdAt: Date
    var completedAt: Date?
    var progress: Int = 0
    
    var isCompleted: Bool {
        return progress >= targetValue
    }
    
    var targetValue: Int {
        return type.targetValue
    }
    
    var progressPercentage: Double {
        return min(Double(progress) / Double(targetValue), 1.0)
    }
    
    mutating func updateProgress(for reward: XPManager.XPReward) {
        guard !isCompleted else { return }
        
        switch type {
        // Daily Missions
        case .playMatches:
            if reward == .matchWin || reward == .matchLoss {
                progress += 1
            }
        case .winMatches:
            if reward == .matchWin {
                progress += 1
            }
        case .sendMessages:
            if reward == .messagesSent {
                progress += 1
            }
        case .addFriends:
            if reward == .friendAdded {
                progress += 1
            }
        case .earnXP:
            progress += reward.rawValue
            
        // Weekly Missions
        case .winStreak:
            // This needs special handling in XPManager
            break
        case .playTournament:
            if reward == .tournamentJoin {
                progress += 1
            }
        case .socialMatches:
            if reward == .socialMatch {
                progress += 1
            }
        case .visitCourts:
            if reward == .courtCheckin {
                progress += 1
            }
        case .weeklyXP:
            progress += reward.rawValue
            
        // Achievement Missions
        case .perfectGames:
            if reward == .perfectGame {
                progress += 1
            }
        case .levelUp:
            // This needs special handling in XPManager
            break
        case .unlockTrophies:
            if reward == .achievementUnlock {
                progress += 1
            }
        case .completeMissions:
            if reward == .missionComplete {
                progress += 1
            }
        }
    }
}

// MARK: - Mission Types

enum MissionType: String, CaseIterable, Codable {
    // Daily Missions (reset daily)
    case playMatches = "play_matches"
    case winMatches = "win_matches"
    case sendMessages = "send_messages"
    case addFriends = "add_friends"
    case earnXP = "earn_xp"
    
    // Weekly Missions (reset weekly)
    case winStreak = "win_streak"
    case playTournament = "play_tournament"
    case socialMatches = "social_matches"
    case visitCourts = "visit_courts"
    case weeklyXP = "weekly_xp"
    
    // Achievement Missions (permanent)
    case perfectGames = "perfect_games"
    case levelUp = "level_up"
    case unlockTrophies = "unlock_trophies"
    case completeMissions = "complete_missions"
    
    var title: String {
        switch self {
        case .playMatches: return "Play Matches"
        case .winMatches: return "Win Matches"
        case .sendMessages: return "Send Messages"
        case .addFriends: return "Add Friends"
        case .earnXP: return "Earn XP"
        case .winStreak: return "Win Streak"
        case .playTournament: return "Play Tournament"
        case .socialMatches: return "Social Matches"
        case .visitCourts: return "Visit Courts"
        case .weeklyXP: return "Weekly XP"
        case .perfectGames: return "Perfect Games"
        case .levelUp: return "Level Up"
        case .unlockTrophies: return "Unlock Trophies"
        case .completeMissions: return "Complete Missions"
        }
    }
    
    var description: String {
        switch self {
        case .playMatches: return "Play \(targetValue) matches today"
        case .winMatches: return "Win \(targetValue) matches today"
        case .sendMessages: return "Send \(targetValue) messages today"
        case .addFriends: return "Add \(targetValue) friends today"
        case .earnXP: return "Earn \(targetValue) XP today"
        case .winStreak: return "Achieve a \(targetValue)-game win streak"
        case .playTournament: return "Join a tournament this week"
        case .socialMatches: return "Play \(targetValue) social matches this week"
        case .visitCourts: return "Visit \(targetValue) different courts this week"
        case .weeklyXP: return "Earn \(targetValue) XP this week"
        case .perfectGames: return "Win \(targetValue) perfect games (11-0)"
        case .levelUp: return "Reach level \(targetValue)"
        case .unlockTrophies: return "Unlock \(targetValue) trophies"
        case .completeMissions: return "Complete \(targetValue) missions"
        }
    }
    
    var targetValue: Int {
        switch self {
        case .playMatches: return 3
        case .winMatches: return 2
        case .sendMessages: return 5
        case .addFriends: return 1
        case .earnXP: return 200
        case .winStreak: return 3
        case .playTournament: return 1
        case .socialMatches: return 5
        case .visitCourts: return 3
        case .weeklyXP: return 1000
        case .perfectGames: return 1
        case .levelUp: return 10
        case .unlockTrophies: return 5
        case .completeMissions: return 10
        }
    }
    
    var xpReward: Int {
        switch self {
        case .playMatches, .winMatches, .sendMessages, .addFriends: return 100
        case .earnXP: return 150
        case .winStreak, .playTournament, .socialMatches, .visitCourts: return 200
        case .weeklyXP: return 300
        case .perfectGames, .levelUp, .unlockTrophies, .completeMissions: return 500
        }
    }
    
    var icon: String {
        switch self {
        case .playMatches: return "gamecontroller"
        case .winMatches: return "trophy.fill"
        case .sendMessages: return "message.fill"
        case .addFriends: return "person.badge.plus"
        case .earnXP: return "star.fill"
        case .winStreak: return "flame.fill"
        case .playTournament: return "person.3.fill"
        case .socialMatches: return "person.2.fill"
        case .visitCourts: return "location.fill"
        case .weeklyXP: return "chart.line.uptrend.xyaxis"
        case .perfectGames: return "crown.fill"
        case .levelUp: return "arrow.up.circle.fill"
        case .unlockTrophies: return "rosette"
        case .completeMissions: return "checkmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .playMatches, .winMatches, .sendMessages, .addFriends, .earnXP:
            return "blue"
        case .winStreak, .playTournament, .socialMatches, .visitCourts, .weeklyXP:
            return "purple"
        case .perfectGames, .levelUp, .unlockTrophies, .completeMissions:
            return "gold"
        }
    }
    
    var isDaily: Bool {
        switch self {
        case .playMatches, .winMatches, .sendMessages, .addFriends, .earnXP:
            return true
        default:
            return false
        }
    }
    
    var isWeekly: Bool {
        switch self {
        case .winStreak, .playTournament, .socialMatches, .visitCourts, .weeklyXP:
            return true
        default:
            return false
        }
    }
    
    var isAchievement: Bool {
        switch self {
        case .perfectGames, .levelUp, .unlockTrophies, .completeMissions:
            return true
        default:
            return false
        }
    }
    
    static var dailyMissions: [MissionType] {
        return allCases.filter { $0.isDaily }
    }
    
    static var weeklyMissions: [MissionType] {
        return allCases.filter { $0.isWeekly }
    }
    
    static var achievementMissions: [MissionType] {
        return allCases.filter { $0.isAchievement }
    }
} 