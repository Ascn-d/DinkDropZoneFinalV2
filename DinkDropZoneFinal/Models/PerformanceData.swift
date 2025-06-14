import Foundation

struct PerformanceData: Identifiable, Codable {
    var id: String
    var date: Date
    var elo: Int
    var matches: Int
    var wins: Int
    
    var winRate: Double {
        guard matches > 0 else { return 0 }
        return Double(wins) / Double(matches)
    }
    
    init(id: String = UUID().uuidString, date: Date, elo: Int, matches: Int, wins: Int) {
        self.id = id
        self.date = date
        self.elo = elo
        self.matches = matches
        self.wins = wins
    }
}

// MARK: - Sample Data Generator
extension PerformanceData {
    static func generateSampleData(days: Int = 30) -> [PerformanceData] {
        var data: [PerformanceData] = []
        let calendar = Calendar.current
        let today = Date()
        
        var currentElo = 1000
        var totalMatches = 0
        var totalWins = 0
        
        for day in (0..<days).reversed() {
            let date = calendar.date(byAdding: .day, value: -day, to: today)!
            
            // Generate random matches for the day (0-3 matches)
            let matchesToday = Int.random(in: 0...3)
            let winsToday = Int.random(in: 0...matchesToday)
            
            // Update totals
            totalMatches += matchesToday
            totalWins += winsToday
            
            // Calculate ELO change (random between -20 and +20)
            let eloChange = Int.random(in: -20...20)
            currentElo += eloChange
            
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