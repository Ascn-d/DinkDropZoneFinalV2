import Foundation

public enum MatchResult: Codable {
    case win(pointsScored: Int, pointsConceded: Int, eloChange: Int)
    case loss(pointsScored: Int, pointsConceded: Int, eloChange: Int)
    
    public var isWin: Bool {
        switch self {
        case .win: return true
        case .loss: return false
        }
    }
    
    public var pointsScored: Int {
        switch self {
        case .win(let points, _, _), .loss(let points, _, _): return points
        }
    }
    
    public var pointsConceded: Int {
        switch self {
        case .win(_, let points, _), .loss(_, let points, _): return points
        }
    }
    
    public var eloChange: Int {
        switch self {
        case .win(_, _, let change), .loss(_, _, let change): return change
        }
    }
}

public enum PerformanceInsightType: Codable {
    case positive, negative, achievement, suggestion
    
    public var color: String {
        switch self {
        case .positive: return "green"
        case .negative: return "red"
        case .achievement: return "purple"
        case .suggestion: return "blue"
        }
    }
}

public enum StreakType: Codable {
    case win, loss
} 