import Foundation
import SwiftUI

enum MatchType: String, Codable, CaseIterable {
    case casual = "Casual"
    case competitive = "Competitive"
    case tournament = "Tournament"
    case league = "League"
    case singles = "Singles"
    case doubles = "Doubles"
    case practice = "Practice"
    
    var color: Color {
        switch self {
        case .casual: return .blue
        case .competitive: return .orange
        case .tournament: return .purple
        case .league: return .green
        case .singles: return .red
        case .doubles: return .indigo
        case .practice: return .orange
        }
    }
    
    var description: String {
        switch self {
        case .casual: return "Friendly match with no ranking impact"
        case .competitive: return "Ranked match affecting ELO"
        case .tournament: return "Tournament match"
        case .league: return "League match"
        case .singles: return "1v1 match"
        case .doubles: return "2v2 match"
        case .practice: return "Practice match"
        }
    }
    
    var playersRequired: Int {
        switch self {
        case .singles, .practice: return 2
        case .doubles: return 4
        case .tournament: return 8 // Minimum for a tournament
        case .casual, .competitive, .league: return 2
        }
    }
    
    var icon: String {
        switch self {
        case .singles: return "person.fill"
        case .doubles: return "person.2.fill"
        case .practice: return "figure.walk"
        case .tournament: return "trophy.fill"
        case .casual: return "hand.thumbsup.fill"
        case .competitive: return "star.fill"
        case .league: return "trophy.circle.fill"
        }
    }
} 