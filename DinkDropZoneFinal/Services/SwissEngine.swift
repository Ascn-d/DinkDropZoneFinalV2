import Foundation
import SwiftData

// MARK: - Swiss System Tournament Engine

protocol BracketEngineProtocol {
    func generateBracket(for tournament: Tournament) -> [TournamentMatch]
    func completeMatch(_ match: TournamentMatch, winnerID: String, loserID: String, score: String, tournament: inout Tournament)
    func getBracketStatus(tournament: Tournament) -> BracketStatus
}

class SwissEngine: ObservableObject, BracketEngineProtocol {
    
    // MARK: - Configuration
    
    private struct SwissConfiguration {
        static let defaultRounds = 7
        static let minRounds = 4
        static let maxRounds = 12
        static let pairingTolerance = 50 // Elo difference tolerance
        static let colorBalanceWeight = 30 // Weight for color balance in pairing
        static let avoidRepeatWeight = 100 // Weight to avoid repeat pairings
    }
    
    // MARK: - Swiss System Generation
    
    func generateBracket(for tournament: Tournament) -> [TournamentMatch] {
        let participants = tournament.participants.filter { $0.status == "Registered" }
        
        guard participants.count >= 8 else {
            print("❌ Swiss System requires minimum 8 participants (found \(participants.count))")
            return []
        }
        
        let rounds = calculateOptimalRounds(for: participants.count)
        print("🏁 Generating Swiss System with \(rounds) rounds for \(participants.count) participants")
        
        // Generate first round with seeded pairings
        var allMatches: [TournamentMatch] = []
        let firstRoundMatches = generateSwissFirstRound(participants)
        allMatches.append(contentsOf: firstRoundMatches)
        
        // Generate placeholder matches for subsequent rounds
        for round in 2...rounds {
            let roundMatches = generateSwissRoundPlaceholders(round: round, participantCount: participants.count)
            allMatches.append(contentsOf: roundMatches)
        }
        
        return allMatches
    }
    
    // MARK: - First Round Generation
    
    private func generateSwissFirstRound(_ participants: [TournamentParticipant]) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let seededParticipants = seedParticipants(participants)
        let playerCount = seededParticipants.count
        
        // Swiss first round: divide players by rating, pair top half vs bottom half
        let topHalf = Array(seededParticipants[0..<playerCount/2])
        let bottomHalf = Array(seededParticipants[playerCount/2..<playerCount])
        
        for i in 0..<topHalf.count {
            var match = TournamentMatch(
                round: 1,
                bracket: "Swiss",
                matchNumber: i + 1
            )
            
            let topPlayer = topHalf[i]
            let bottomPlayer = bottomHalf[i]
            
            match.player1ID = topPlayer.userID
            match.player1Name = topPlayer.effectiveName
            match.player2ID = bottomPlayer.userID
            match.player2Name = bottomPlayer.effectiveName
            
            matches.append(match)
        }
        
        // Handle odd number of players (bye)
        if playerCount % 2 == 1 {
            let byePlayer = seededParticipants.last!
            var byeMatch = TournamentMatch(
                round: 1,
                bracket: "Swiss",
                matchNumber: matches.count + 1
            )
            
            byeMatch.player1ID = byePlayer.userID
            byeMatch.player1Name = byePlayer.effectiveName
            byeMatch.isBye = true
            byeMatch.status = "Completed"
            byeMatch.winnerID = byePlayer.userID
            byeMatch.finalScore = "Bye"
            
            matches.append(byeMatch)
        }
        
        return matches
    }
    
    // MARK: - BracketEngineProtocol Implementation
    
    func completeMatch(_ match: TournamentMatch, winnerID: String, loserID: String, score: String, tournament: inout Tournament) {
        // Update match result
        if let matchIndex = tournament.matches.firstIndex(where: { $0.id == match.id }) {
            tournament.matches[matchIndex].winnerID = winnerID
            tournament.matches[matchIndex].loserID = loserID
            tournament.matches[matchIndex].finalScore = score
            tournament.matches[matchIndex].status = "Completed"
        }
        
        // Update participant records
        updateParticipantRecord(userID: winnerID, won: true, tournament: &tournament)
        updateParticipantRecord(userID: loserID, won: false, tournament: &tournament)
        
        // Check tournament completion
        checkTournamentCompletion(tournament: &tournament)
    }
    
    func getBracketStatus(tournament: Tournament) -> BracketStatus {
        let allMatches = tournament.matches.filter { $0.bracket == "Swiss" }
        let completedMatches = allMatches.filter { $0.status == "Completed" }
        
        return BracketStatus(
            winnersCompleted: completedMatches.count,
            winnersTotal: allMatches.count,
            losersCompleted: 0,
            losersTotal: 0,
            totalCompleted: completedMatches.count,
            totalMatches: allMatches.count,
            isGrandFinalReady: false,
            isResetActive: false,
            isComplete: tournament.status == "Completed"
        )
    }
    
    // MARK: - Helper Methods
    
    private func generateSwissRoundPlaceholders(round: Int, participantCount: Int) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let matchCount = participantCount / 2
        
        for i in 0..<matchCount {
            let match = TournamentMatch(
                round: round,
                bracket: "Swiss",
                matchNumber: i + 1
            )
            matches.append(match)
        }
        
        // Add bye match if odd number of participants
        if participantCount % 2 == 1 {
            var byeMatch = TournamentMatch(
                round: round,
                bracket: "Swiss",
                matchNumber: matchCount + 1
            )
            byeMatch.isBye = true
            matches.append(byeMatch)
        }
        
        return matches
    }
    
    private func seedParticipants(_ participants: [TournamentParticipant]) -> [TournamentParticipant] {
        return participants.sorted { p1, p2 in
            if p1.elo != p2.elo {
                return p1.elo > p2.elo
            }
            
            // Tiebreak by win rate
            let p1WinRate = p1.wins + p1.losses > 0 ? Double(p1.wins) / Double(p1.wins + p1.losses) : 0.5
            let p2WinRate = p2.wins + p2.losses > 0 ? Double(p2.wins) / Double(p2.wins + p2.losses) : 0.5
            
            return p1WinRate > p2WinRate
        }
    }
    
    private func calculateOptimalRounds(for playerCount: Int) -> Int {
        // Calculate optimal rounds for Swiss system
        let idealRounds = Int(log2(Double(playerCount))) + 1
        return max(SwissConfiguration.minRounds, min(SwissConfiguration.maxRounds, idealRounds))
    }
    
    private func updateParticipantRecord(userID: String, won: Bool, tournament: inout Tournament) {
        if let participantIndex = tournament.participants.firstIndex(where: { $0.userID == userID }) {
            if won {
                tournament.participants[participantIndex].wins += 1
            } else {
                tournament.participants[participantIndex].losses += 1
            }
        }
    }
    
    private func checkTournamentCompletion(tournament: inout Tournament) {
        let totalRounds = calculateOptimalRounds(for: tournament.participants.count)
        let allMatches = tournament.matches.filter { $0.bracket == "Swiss" }
        let completedMatches = allMatches.filter { $0.status == "Completed" }
        let maxRound = allMatches.map { $0.round }.max() ?? 0
        
        if maxRound >= totalRounds && completedMatches.count == allMatches.count {
            tournament.status = "Completed"
            print("🏆 Swiss tournament completed!")
        }
    }
}
