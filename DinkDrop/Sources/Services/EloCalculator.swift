import Foundation

struct EloCalculator {
    static func expectedScore(rating: Int, opponent: Int) -> Double {
        return 1.0 / (1.0 + pow(10.0, Double(opponent - rating) / 400.0))
    }

    static func newRating(current: Int, opponent: Int, didWin: Bool, kFactor: Double = 32) -> Int {
        let expected = expectedScore(rating: current, opponent: opponent)
        let actual = didWin ? 1.0 : 0.0
        let newRating = Double(current) + kFactor * (actual - expected)
        return Int(round(newRating))
    }

    static func updatedRatings(player1: Int, player2: Int, p1Score: Int, p2Score: Int) -> (Int, Int) {
        let p1Win = p1Score > p2Score
        let new1 = newRating(current: player1, opponent: player2, didWin: p1Win)
        let new2 = newRating(current: player2, opponent: player1, didWin: !p1Win)
        return (new1, new2)
    }
} 