import Foundation

struct PerformanceData: Identifiable {
    let id = UUID()
    let date: Date
    let elo: Int
    let matches: Int
    let wins: Int
    
    var winRate: Double {
        guard matches > 0 else { return 0 }
        return Double(wins) / Double(matches)
    }
}

// Sample data generator
extension PerformanceData {
    static func generateSampleData(days: Int = 30) -> [PerformanceData] {
        let calendar = Calendar.current
        let today = Date()
        var data: [PerformanceData] = []
        var currentElo = 1000
        var totalMatches = 0
        var totalWins = 0
        
        for day in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -day, to: today)!
            let matches = Int.random(in: 0...3)
            let wins = Int.random(in: 0...matches)
            
            // Simulate ELO changes
            let eloChange = (wins - (matches - wins)) * 10
            currentElo += eloChange
            
            totalMatches += matches
            totalWins += wins
            
            data.append(PerformanceData(
                date: date,
                elo: currentElo,
                matches: totalMatches,
                wins: totalWins
            ))
        }
        
        return data
    }
} 