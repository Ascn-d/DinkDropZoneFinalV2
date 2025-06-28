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
