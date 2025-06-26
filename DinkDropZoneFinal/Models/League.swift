import Foundation
import SwiftUI

// MARK: - League Model

struct League: Identifiable {
    let id = UUID()
    let name: String
    let minELO: Int
    let icon: String
    let color: Color
    let description: String
    
    static let allLeagues: [League] = [
        League(
            name: "Bronze",
            minELO: 0,
            icon: "shield",
            color: Color.orange.opacity(0.8),
            description: "Starting division for new players learning the fundamentals"
        ),
        League(
            name: "Silver",
            minELO: 1000,
            icon: "shield.fill",
            color: Color.gray,
            description: "Intermediate players with solid basic skills"
        ),
        League(
            name: "Gold",
            minELO: 1300,
            icon: "crown",
            color: Color.yellow,
            description: "Advanced players with consistent performance"
        ),
        League(
            name: "Platinum",
            minELO: 1600,
            icon: "crown.fill",
            color: Color.cyan,
            description: "Expert players with exceptional technique"
        ),
        League(
            name: "Diamond",
            minELO: 1900,
            icon: "diamond",
            color: Color.blue,
            description: "Elite players competing at the highest level"
        ),
        League(
            name: "Master",
            minELO: 2200,
            icon: "diamond.fill",
            color: Color.purple,
            description: "Masters of the game with unmatched skill"
        ),
        League(
            name: "Legend",
            minELO: 2500,
            icon: "star.circle.fill",
            color: Color.red,
            description: "Legendary players who define the meta"
        )
    ]
} 