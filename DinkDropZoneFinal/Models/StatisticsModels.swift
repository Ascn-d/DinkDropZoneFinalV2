import Foundation
import SwiftUI
import SwiftData
// Import the enums
// If using modules, you may need: import DinkDropZoneFinal

// MARK: - Data Structures

// DetailedUserStats is already defined in AppState.swift, so we'll use a different name
struct DetailedUserStatsExtended {
    let overview: OverviewStats
    let performance: PerformanceStats
    let trends: TrendStats
    let opponents: OpponentStats
    let shots: ShotStats
    let streaks: StreakStats
}

struct OverviewStats {
    let totalMatches: Int
    let wins: Int
    let losses: Int
    let winRate: Double
    let currentElo: Int
    let eloChange: Int
    let averagePointsPerMatch: Double
}

struct PerformanceStats {
    let recentWinRate: Double
    let averagePointsPerMatch: Double
    let averagePointsConceded: Double
    let bestPerformance: Double
    let worstPerformance: Double
}

struct TrendStats {
    let recentWinRate: Double
    let eloTrend: Double
    let performanceTrend: Double
}

struct OpponentStats {
    let toughestOpponent: String
    let easiestOpponent: String
    let mostPlayedOpponent: String
}

struct ShotStats {
    let favoriteShot: String
    let shotAccuracy: Double
    let shotDistribution: [String: Double]
}

struct StreakStats {
    let currentStreak: Int
    let longestStreak: Int
    let streakType: StreakType
}

struct MonthlyPerformance {
    let year: Int
    let month: Int
    let totalMatches: Int
    let totalWins: Int
    let totalPointsScored: Int
    let totalPointsConceded: Int
    let dailyStats: [DayStats]
    
    var winRate: Double {
        guard totalMatches > 0 else { return 0 }
        return Double(totalWins) / Double(totalMatches)
    }
}

struct DayStats {
    let day: Int
    var matches: Int
    var wins: Int
    var pointsScored: Int
    var pointsConceded: Int
    
    var winRate: Double {
        guard matches > 0 else { return 0 }
        return Double(wins) / Double(matches)
    }
}

// EloDataPoint is already defined in AppState.swift, so we'll use a different name
struct EloHistoryPoint {
    let date: Date
    let elo: Int
    let change: Int
}

struct MatchAnalysis {
    let matchId: String
    let result: DinkDropZoneFinal.MatchResult // Using fully qualified name
    let pointsScored: Int
    let pointsConceded: Int
    let eloChange: Int
    let dominance: Double
    let performance: Double
    let insights: [String]
}

struct StatisticsMatchPrediction {
    let userWinProbability: Double
    let expectedEloChange: Int
    let confidenceLevel: Double
    let factors: [PredictionFactor]
}

struct PredictionFactor {
    let name: String
    let impact: Double
    let description: String
}

// PerformanceInsightModel is already defined in AppState.swift, so we'll use a different name
struct PerformanceInsight {
    let type: PerformanceInsightType
    let title: String
    let description: String
    let icon: String
}
// All enums removed; now using those from GameEnums.swift 