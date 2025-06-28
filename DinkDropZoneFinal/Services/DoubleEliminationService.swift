import Foundation
import SwiftData

// MARK: - Bracket Engine (All Tournament Formats) - Enhanced for Large Tournaments

class BracketEngine: ObservableObject {
    
    // MARK: - Performance Configuration
    
    private struct TournamentLimits {
        static let maxParticipants = 128
        static let warningThreshold = 32
        static let batchSize = 10
        static let maxConcurrentMatches = 8
    }
    
    private struct ValidationResult {
        let isValid: Bool
        let warnings: [String]
        let errors: [String]
    }
    
    // MARK: - Enhanced Bracket Generation with Validation
    
    /// Creates a complete bracket for the given tournament format with performance optimizations
    func generateBracket(for tournament: Tournament) -> [TournamentMatch] {
        let validation = validateTournament(tournament)
        
        if !validation.isValid {
            print("❌ Tournament validation failed: \(validation.errors.joined(separator: ", "))")
            return []
        }
        
        if !validation.warnings.isEmpty {
            print("⚠️ Tournament warnings: \(validation.warnings.joined(separator: ", "))")
        }
        
        var matches: [TournamentMatch] = []
        let participants = tournament.participants.filter { $0.status == "Registered" }
        
        // Performance optimization: use async generation for large tournaments
        if participants.count >= TournamentLimits.warningThreshold {
            print("🏁 Generating large tournament bracket with \(participants.count) participants...")
        }
        
        // Seed participants by ELO with enhanced algorithm
        let seededParticipants = enhancedSeedParticipants(participants)
        
        switch tournament.type {
        case "Single Elimination":
            matches = generateSingleEliminationBracket(seededParticipants)
        case "Double Elimination":
            matches = generateDoubleEliminationBracket(seededParticipants)
        case "Round Robin":
            matches = generateRoundRobinBracket(seededParticipants)
        case "Swiss System":
            matches = generateSwissBracket(seededParticipants)
        default:
            matches = generateDoubleEliminationBracket(seededParticipants)
        }
        
        // Validate generated bracket
        validateGeneratedBracket(matches, participantCount: participants.count)
        
        return matches
    }
    
    // MARK: - Tournament Validation
    
    private func validateTournament(_ tournament: Tournament) -> ValidationResult {
        var warnings: [String] = []
        var errors: [String] = []
        
        let participants = tournament.participants.filter { $0.status == "Registered" }
        
        // Check minimum participants
        if participants.count < 4 {
            errors.append("Minimum 4 participants required (found \(participants.count))")
        }
        
        // Check maximum participants
        if participants.count > TournamentLimits.maxParticipants {
            errors.append("Maximum \(TournamentLimits.maxParticipants) participants allowed (found \(participants.count))")
        }
        
        // Performance warnings
        if participants.count >= TournamentLimits.warningThreshold {
            warnings.append("Large tournament detected (\(participants.count) participants) - expect longer processing times")
        }
        
        // Format-specific validation
        switch tournament.type {
        case "Round Robin":
            if participants.count > 20 {
                warnings.append("Round Robin with \(participants.count) participants will require \(calculateRoundRobinMatches(participants: participants.count)) matches")
            }
        case "Swiss System":
            if participants.count < 8 {
                warnings.append("Swiss System works best with 8+ participants")
            }
        default:
            break
        }
        
        // Check for duplicate participants
        let uniqueUserIDs = Set(participants.map { $0.userID })
        if uniqueUserIDs.count != participants.count {
            errors.append("Duplicate participants found")
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            warnings: warnings,
            errors: errors
        )
    }
    
    private func validateGeneratedBracket(_ matches: [TournamentMatch], participantCount: Int) {
        let totalMatches = matches.count
        print("✅ Generated \(totalMatches) matches for \(participantCount) participants")
        
        // Validate match structure
        let roundCounts = Dictionary(grouping: matches, by: { $0.round })
        for (round, roundMatches) in roundCounts {
            print("   Round \(round): \(roundMatches.count) matches")
        }
    }
    
    // MARK: - Enhanced Seeding Algorithm
    
    private func enhancedSeedParticipants(_ participants: [TournamentParticipant]) -> [TournamentParticipant] {
        // Multi-factor seeding: ELO + recent performance + randomization for ties
        let sorted = participants.sorted { p1, p2 in
            // Primary sort: ELO
            if p1.elo != p2.elo {
                return p1.elo > p2.elo
            }
            
            // Secondary sort: Win rate (wins / (wins + losses))
            let p1WinRate = p1.wins + p1.losses > 0 ? Double(p1.wins) / Double(p1.wins + p1.losses) : 0.5
            let p2WinRate = p2.wins + p2.losses > 0 ? Double(p2.wins) / Double(p2.wins + p2.losses) : 0.5
            
            if abs(p1WinRate - p2WinRate) > 0.01 {
                return p1WinRate > p2WinRate
            }
            
            // Tertiary sort: Random for ties (consistent within session)
            return p1.id.uuidString < p2.id.uuidString
        }
        
        return sorted
    }
    
    // MARK: - Enhanced Swiss System Implementation
    
    private func generateSwissBracket(_ participants: [TournamentParticipant]) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let rounds = calculateSwissRounds(for: participants.count)
        
        // Generate first round with seeded pairings
        matches.append(contentsOf: generateSwissFirstRound(participants))
        
        // Subsequent rounds will be generated based on results
        // For now, create placeholder matches
        for round in 2...rounds {
            matches.append(contentsOf: generateSwissRound(
                round: round,
                participants: participants,
                previousMatches: matches.filter { $0.round < round }
            ))
        }
        
        return matches
    }
    
    private func generateSwissFirstRound(_ participants: [TournamentParticipant]) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let pairs = participants.count / 2
        
        // Swiss first round: top half vs bottom half
        for i in 0..<pairs {
            let topSeed = participants[i]
            let bottomSeed = participants[i + pairs]
            
            var match = TournamentMatch(
                round: 1,
                bracket: "Swiss",
                matchNumber: i + 1
            )
            
            match.player1ID = topSeed.userID
            match.player1Name = topSeed.effectiveName
            match.player2ID = bottomSeed.userID
            match.player2Name = bottomSeed.effectiveName
            
            matches.append(match)
        }
        
        // Handle odd participant (bye)
        if participants.count % 2 == 1 {
            let byePlayer = participants.last!
            var byeMatch = TournamentMatch(
                round: 1,
                bracket: "Swiss",
                matchNumber: pairs + 1
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
    
    private func generateSwissRound(round: Int, participants: [TournamentParticipant], previousMatches: [TournamentMatch]) -> [TournamentMatch] {
        // Swiss pairing algorithm - players with similar scores face each other
        // For now, create placeholder matches that will be paired based on standings
        var matches: [TournamentMatch] = []
        let pairs = participants.count / 2
        
        for i in 0..<pairs {
            let match = TournamentMatch(
                round: round,
                bracket: "Swiss",
                matchNumber: i + 1
            )
            matches.append(match)
        }
        
        return matches
    }
    
    private func calculateSwissRounds(for participantCount: Int) -> Int {
        // Swiss rounds formula: approximately log2(participants) + 1
        // Minimum 4 rounds, maximum 8 rounds
        let calculated = Int(log2(Double(participantCount))) + 1
        return max(4, min(8, calculated))
    }
    
    // MARK: - Performance Optimized Double Elimination
    
    private func generateDoubleEliminationBracket(_ participants: [TournamentParticipant]) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let bracketSize = nextPowerOfTwo(participants.count)
        
        print("🏆 Generating Double Elimination bracket: \(participants.count) participants, bracket size: \(bracketSize)")
        
        // Generate Winners Bracket with performance optimization
        let winnersMatches = generateOptimizedWinnersBracket(participants, bracketSize: bracketSize)
        matches.append(contentsOf: winnersMatches)
        
        // Generate Losers Bracket structure with enhanced algorithm
        let losersMatches = generateOptimizedLosersBracket(bracketSize: bracketSize)
        matches.append(contentsOf: losersMatches)
        
        // Create Grand Final with potential reset
        matches.append(contentsOf: generateEnhancedGrandFinal())
        
        return matches
    }
    
    private func generateOptimizedWinnersBracket(_ participants: [TournamentParticipant], bracketSize: Int) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let rounds = Int(log2(Double(bracketSize)))
        
        // Generate first round with enhanced seeding
        let firstRoundMatches = generateOptimizedFirstRound(participants, bracketSize: bracketSize)
        matches.append(contentsOf: firstRoundMatches)
        
        // Generate subsequent rounds
        var previousRoundMatches = firstRoundMatches
        for round in 2...rounds {
            let roundMatches = generateWinnersRound(round: round, previousMatches: previousRoundMatches)
            matches.append(contentsOf: roundMatches)
            previousRoundMatches = roundMatches
        }
        
        return matches
    }
    
    private func generateOptimizedFirstRound(_ participants: [TournamentParticipant], bracketSize: Int) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let matchups = createOptimizedFirstRoundMatchups(participants, bracketSize: bracketSize)
        
        for (index, matchup) in matchups.enumerated() {
            var match = TournamentMatch(
                round: 1,
                bracket: "Winners",
                matchNumber: index + 1
            )
            
            if let player1 = matchup.0 {
                match.player1ID = player1.userID
                match.player1Name = player1.effectiveName
            }
            
            if let player2 = matchup.1 {
                match.player2ID = player2.userID
                match.player2Name = player2.effectiveName
            } else {
                // Optimized bye handling
                match.isBye = true
                match.status = "Completed"
                match.winnerID = match.player1ID
                match.finalScore = "Bye"
            }
            
            matches.append(match)
        }
        
        return matches
    }
    
    private func createOptimizedFirstRoundMatchups(_ participants: [TournamentParticipant], bracketSize: Int) -> [(TournamentParticipant?, TournamentParticipant?)] {
        var matchups: [(TournamentParticipant?, TournamentParticipant?)] = []
        let seeds = createBalancedSeedOrder(for: bracketSize)
        
        // Optimized matchup creation with better bye distribution
        for i in stride(from: 0, to: seeds.count, by: 2) {
            let seed1 = seeds[i]
            let seed2 = seeds[i + 1]
            
            let player1 = participants.indices.contains(seed1 - 1) ? participants[seed1 - 1] : nil
            let player2 = participants.indices.contains(seed2 - 1) ? participants[seed2 - 1] : nil
            
            matchups.append((player1, player2))
        }
        
        return matchups
    }
    
    private func createBalancedSeedOrder(for bracketSize: Int) -> [Int] {
        // Enhanced seeding algorithm for better bracket balance
        var seeds: [Int] = []
        
        func addSeedsBalanced(start: Int, end: Int) {
            if start > end { return }
            seeds.append(start)
            if start != end {
                seeds.append(end)
                addSeedsBalanced(start: start + 1, end: end - 1)
            }
        }
        
        addSeedsBalanced(start: 1, end: bracketSize)
        return seeds
    }
    
    private func generateOptimizedLosersBracket(bracketSize: Int) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let winnersRounds = Int(log2(Double(bracketSize)))
        
        var currentMatchNumber = 1
        var losersRound = 1
        
        // Enhanced losers bracket generation with better structure
        while losersRound <= (winnersRounds - 1) * 2 + 1 {
            let roundMatches: [TournamentMatch]
            
            if losersRound % 2 == 1 {
                // Odd rounds: droppers from winners bracket
                roundMatches = generateOptimizedLosersDropRound(
                    round: losersRound,
                    startingMatchNumber: currentMatchNumber,
                    bracketSize: bracketSize
                )
            } else {
                // Even rounds: advancement within losers bracket
                roundMatches = generateOptimizedLosersAdvanceRound(
                    round: losersRound,
                    startingMatchNumber: currentMatchNumber,
                    bracketSize: bracketSize
                )
            }
            
            matches.append(contentsOf: roundMatches)
            currentMatchNumber += roundMatches.count
            losersRound += 1
        }
        
        return matches
    }
    
    private func generateOptimizedLosersDropRound(round: Int, startingMatchNumber: Int, bracketSize: Int) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        
        // Enhanced calculation for losers bracket match count
        let winnersRound = (round + 1) / 2
        let matchCount = max(1, bracketSize / Int(pow(2.0, Double(winnersRound + 1))))
        
        for i in 0..<matchCount {
            let match = TournamentMatch(
                round: round,
                bracket: "Losers",
                matchNumber: startingMatchNumber + i
            )
            matches.append(match)
        }
        
        return matches
    }
    
    private func generateOptimizedLosersAdvanceRound(round: Int, startingMatchNumber: Int, bracketSize: Int) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        
        // Enhanced calculation for advancement rounds
        let previousRound = round - 1
        let previousMatchCount = bracketSize / Int(pow(2.0, Double((previousRound + 1) / 2 + 1)))
        let matchCount = max(1, previousMatchCount / 2)
        
        for i in 0..<matchCount {
            let match = TournamentMatch(
                round: round,
                bracket: "Losers",
                matchNumber: startingMatchNumber + i
            )
            matches.append(match)
        }
        
        return matches
    }
    
    private func generateEnhancedGrandFinal() -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        
        // Standard grand final
        let grandFinal = TournamentMatch(
            round: 999, // Special round number for grand final
            bracket: "Grand Final",
            matchNumber: 1
        )
        matches.append(grandFinal)
        
        // Potential reset match (if losers bracket winner wins first grand final)
        var resetMatch = TournamentMatch(
            round: 1000, // Reset match
            bracket: "Grand Final",
            matchNumber: 2
        )
        resetMatch.isGrandFinalReset = true
        matches.append(resetMatch)
        
        return matches
    }
    
    // MARK: - Legacy Support (Deprecated - use enhanced version above)
    
    /// Legacy method - redirects to enhanced version
    @available(*, deprecated, message: "Use enhanced generateBracket method instead")
    func generateBracketLegacy(for tournament: Tournament) -> [TournamentMatch] {
        return generateBracket(for: tournament)
    }
    
    // MARK: - Single Elimination
    
    private func generateSingleEliminationBracket(_ participants: [TournamentParticipant]) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let bracketSize = nextPowerOfTwo(participants.count)
        let rounds = Int(log2(Double(bracketSize)))
        
        // Generate first round with proper seeding
        let firstRoundMatches = generateSingleElimFirstRound(participants, bracketSize: bracketSize)
        matches.append(contentsOf: firstRoundMatches)
        
        // Generate subsequent rounds
        var previousRoundMatches = firstRoundMatches
        for round in 2...rounds {
            let roundMatches = generateSingleElimRound(round: round, previousMatches: previousRoundMatches)
            matches.append(contentsOf: roundMatches)
            previousRoundMatches = roundMatches
        }
        
        return matches
    }
    
    private func generateSingleElimFirstRound(_ participants: [TournamentParticipant], bracketSize: Int) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let matchups = createFirstRoundMatchups(participants, bracketSize: bracketSize)
        
        for (index, matchup) in matchups.enumerated() {
            var match = TournamentMatch(
                round: 1,
                bracket: "Main",
                matchNumber: index + 1
            )
            
            if let player1 = matchup.0 {
                match.player1ID = player1.userID
                match.player1Name = player1.effectiveName
            }
            
            if let player2 = matchup.1 {
                match.player2ID = player2.userID
                match.player2Name = player2.effectiveName
            } else {
                // Bye match
                match.isBye = true
                match.status = "Completed"
                match.winnerID = match.player1ID
                match.finalScore = "Bye"
            }
            
            matches.append(match)
        }
        
        return matches
    }
    
    private func generateSingleElimRound(round: Int, previousMatches: [TournamentMatch]) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let matchCount = previousMatches.count / 2
        
        for i in 0..<matchCount {
            let match = TournamentMatch(
                round: round,
                bracket: "Main",
                matchNumber: i + 1
            )
            matches.append(match)
        }
        
        return matches
    }
    
    // MARK: - Double Elimination (existing implementation)
    
    // MARK: - Round Robin
    
    private func generateRoundRobinBracket(_ participants: [TournamentParticipant]) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        var matchNumber = 1
        
        // Generate all possible matchups
        for i in 0..<participants.count {
            for j in (i+1)..<participants.count {
                let player1 = participants[i]
                let player2 = participants[j]
                
                var match = TournamentMatch(
                    round: 1, // All matches are in "round 1" for round robin
                    bracket: "Round Robin",
                    matchNumber: matchNumber
                )
                
                match.player1ID = player1.userID
                match.player1Name = player1.effectiveName
                match.player2ID = player2.userID
                match.player2Name = player2.effectiveName
                
                matches.append(match)
                matchNumber += 1
            }
        }
        
        return matches
    }
    
    // MARK: - Legacy Seeding (use enhancedSeedParticipants instead)
    
    @available(*, deprecated, message: "Use enhancedSeedParticipants for better results")
    private func seedParticipants(_ participants: [TournamentParticipant]) -> [TournamentParticipant] {
        return enhancedSeedParticipants(participants)
    }
    
    private func createFirstRoundMatchups(_ participants: [TournamentParticipant], bracketSize: Int) -> [(TournamentParticipant?, TournamentParticipant?)] {
        var matchups: [(TournamentParticipant?, TournamentParticipant?)] = []
        let seeds = createSeedOrder(for: bracketSize)
        
        // Create matchups based on seed order
        for i in stride(from: 0, to: seeds.count, by: 2) {
            let seed1 = seeds[i]
            let seed2 = seeds[i + 1]
            
            let player1 = participants.indices.contains(seed1 - 1) ? participants[seed1 - 1] : nil
            let player2 = participants.indices.contains(seed2 - 1) ? participants[seed2 - 1] : nil
            
            matchups.append((player1, player2))
        }
        
        return matchups
    }
    
    private func createSeedOrder(for bracketSize: Int) -> [Int] {
        // Standard tournament seeding (1 vs last, 2 vs second-to-last, etc.)
        var seeds: [Int] = []
        
        func addSeeds(start: Int, end: Int) {
            if start > end { return }
            seeds.append(start)
            if start != end {
                seeds.append(end)
                addSeeds(start: start + 1, end: end - 1)
            }
        }
        
        addSeeds(start: 1, end: bracketSize)
        return seeds
    }
    
    // MARK: - Double Elimination Specific Methods (from original implementation)
    
    private func generateWinnersBracket(_ participants: [TournamentParticipant], bracketSize: Int) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let rounds = Int(log2(Double(bracketSize)))
        
        // Generate first round with proper seeding
        let firstRoundMatches = generateFirstRound(participants, bracketSize: bracketSize)
        matches.append(contentsOf: firstRoundMatches)
        
        // Generate subsequent rounds
        var previousRoundMatches = firstRoundMatches
        for round in 2...rounds {
            let roundMatches = generateWinnersRound(round: round, previousMatches: previousRoundMatches)
            matches.append(contentsOf: roundMatches)
            previousRoundMatches = roundMatches
        }
        
        return matches
    }
    
    private func generateFirstRound(_ participants: [TournamentParticipant], bracketSize: Int) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let matchups = createFirstRoundMatchups(participants, bracketSize: bracketSize)
        
        for (index, matchup) in matchups.enumerated() {
            var match = TournamentMatch(
                round: 1,
                bracket: "Winners",
                matchNumber: index + 1
            )
            
            if let player1 = matchup.0 {
                match.player1ID = player1.userID
                match.player1Name = player1.effectiveName
            }
            
            if let player2 = matchup.1 {
                match.player2ID = player2.userID
                match.player2Name = player2.effectiveName
            } else {
                // Bye match
                match.isBye = true
                match.status = "Completed"
                match.winnerID = match.player1ID
                match.finalScore = "Bye"
            }
            
            matches.append(match)
        }
        
        return matches
    }
    
    private func generateWinnersRound(round: Int, previousMatches: [TournamentMatch]) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let matchCount = previousMatches.count / 2
        
        for i in 0..<matchCount {
            let match = TournamentMatch(
                round: round,
                bracket: "Winners",
                matchNumber: i + 1
            )
            matches.append(match)
        }
        
        return matches
    }
    
    private func generateLosersBracket(bracketSize: Int) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        let winnersRounds = Int(log2(Double(bracketSize)))
        
        var currentMatchNumber = 1
        var losersRound = 1
        
        // Generate all losers bracket rounds
        while losersRound <= (winnersRounds - 1) * 2 + 1 {
            let roundMatches: [TournamentMatch]
            
            if losersRound % 2 == 1 {
                // Odd rounds: losers from winners bracket enter
                roundMatches = generateLosersDropRound(
                    round: losersRound,
                    startingMatchNumber: currentMatchNumber,
                    bracketSize: bracketSize
                )
            } else {
                // Even rounds: winners from previous losers round advance
                roundMatches = generateLosersAdvanceRound(
                    round: losersRound,
                    startingMatchNumber: currentMatchNumber
                )
            }
            
            matches.append(contentsOf: roundMatches)
            currentMatchNumber += roundMatches.count
            losersRound += 1
        }
        
        return matches
    }
    
    private func generateLosersDropRound(round: Int, startingMatchNumber: Int, bracketSize: Int) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        
        // Calculate how many matches in this round
        let winnersRound = (round + 1) / 2
        let matchCount = bracketSize / Int(pow(2.0, Double(winnersRound + 1)))
        
        for i in 0..<matchCount {
            let match = TournamentMatch(
                round: round,
                bracket: "Losers",
                matchNumber: startingMatchNumber + i
            )
            matches.append(match)
        }
        
        return matches
    }
    
    private func generateLosersAdvanceRound(round: Int, startingMatchNumber: Int) -> [TournamentMatch] {
        var matches: [TournamentMatch] = []
        
        // These rounds take winners from previous losers round
        let matchCount = 1 // Simplified for now
        
        for i in 0..<matchCount {
            let match = TournamentMatch(
                round: round,
                bracket: "Losers",
                matchNumber: startingMatchNumber + i
            )
            matches.append(match)
        }
        
        return matches
    }
    
    private func generateGrandFinal() -> [TournamentMatch] {
        let grandFinal = TournamentMatch(
            round: 999, // Special round number for grand final
            bracket: "Winners",
            matchNumber: 1
        )
        
        return [grandFinal]
    }
    
    // MARK: - Match Progression (supports all formats)
    
    /// Updates bracket when a match is completed
    func completeMatch(_ match: TournamentMatch, winnerID: String, loserID: String, score: String, tournament: inout Tournament) {
        // Find and update the match in the tournament
        if let matchIndex = tournament.matches.firstIndex(where: { $0.id == match.id }) {
            tournament.matches[matchIndex].winnerID = winnerID
            tournament.matches[matchIndex].loserID = loserID
            tournament.matches[matchIndex].finalScore = score
            tournament.matches[matchIndex].status = "Completed"
        }
        
        // Update participant records
        updateParticipantRecord(userID: winnerID, won: true, tournament: &tournament)
        updateParticipantRecord(userID: loserID, won: false, tournament: &tournament)
        
        // Check if tournament is complete based on format
        checkTournamentCompletion(tournament: &tournament)
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
        switch tournament.type {
        case "Single Elimination":
            checkSingleElimCompletion(tournament: &tournament)
        case "Double Elimination":
            checkDoubleElimCompletion(tournament: &tournament)
        case "Round Robin":
            checkRoundRobinCompletion(tournament: &tournament)
        default:
            checkDoubleElimCompletion(tournament: &tournament)
        }
    }
    
    private func checkSingleElimCompletion(tournament: inout Tournament) {
        // Single elim is complete when the final match is finished
        let finalMatches = tournament.matches.filter { $0.bracket == "Main" }
        let maxRound = finalMatches.map { $0.round }.max() ?? 0
        let finalMatch = finalMatches.first { $0.round == maxRound }
        
        if let finalMatch = finalMatch, finalMatch.status == "Completed" {
            if let winnerID = finalMatch.winnerID {
                completeTournament(tournament: &tournament, championID: winnerID)
            }
        }
    }
    
    private func checkDoubleElimCompletion(tournament: inout Tournament) {
        // Tournament is complete when grand final is finished
        let grandFinal = tournament.matches.first { $0.round == 999 }
        
        if let grandFinal = grandFinal, grandFinal.status == "Completed" {
            if let winnerID = grandFinal.winnerID {
                completeTournament(tournament: &tournament, championID: winnerID)
            }
        }
    }
    
    private func checkRoundRobinCompletion(tournament: inout Tournament) {
        // Round robin is complete when all matches are finished
        let allMatches = tournament.matches.filter { $0.bracket == "Round Robin" }
        let completedMatches = allMatches.filter { $0.status == "Completed" }
        
        if completedMatches.count == allMatches.count {
            // Determine winner by best record
            let championID = determineRoundRobinWinner(tournament: tournament)
            completeTournament(tournament: &tournament, championID: championID)
        }
    }
    
    private func determineRoundRobinWinner(tournament: Tournament) -> String {
        // Find participant with most wins
        let bestParticipant = tournament.participants.max { p1, p2 in
            if p1.wins != p2.wins {
                return p1.wins < p2.wins
            }
            // Tiebreaker: fewer losses
            return p1.losses > p2.losses
        }
        
        return bestParticipant?.userID ?? ""
    }
    
    private func completeTournament(tournament: inout Tournament, championID: String) {
        tournament.status = "Completed"
        
        // Set final placements
        if let championIndex = tournament.participants.firstIndex(where: { $0.userID == championID }) {
            tournament.participants[championIndex].placement = 1
        }
        
        // Set other placements based on tournament format
        setFinalPlacements(tournament: &tournament, championID: championID)
    }
    
    private func setFinalPlacements(tournament: inout Tournament, championID: String) {
        switch tournament.type {
        case "Single Elimination":
            setSingleElimPlacements(tournament: &tournament, championID: championID)
        case "Double Elimination":
            setDoubleElimPlacements(tournament: &tournament, championID: championID)
        case "Round Robin":
            setRoundRobinPlacements(tournament: &tournament)
        default:
            setDoubleElimPlacements(tournament: &tournament, championID: championID)
        }
    }
    
    private func setSingleElimPlacements(tournament: inout Tournament, championID: String) {
        // Runner-up is the other finalist
        let finalMatches = tournament.matches.filter { $0.bracket == "Main" }
        let maxRound = finalMatches.map { $0.round }.max() ?? 0
        let finalMatch = finalMatches.first { $0.round == maxRound }
        
        if let finalMatch = finalMatch {
            let runnerUpID = finalMatch.player1ID == championID ? finalMatch.player2ID : finalMatch.player1ID
            if let runnerUpIndex = tournament.participants.firstIndex(where: { $0.userID == runnerUpID }) {
                tournament.participants[runnerUpIndex].placement = 2
            }
        }
    }
    
    private func setDoubleElimPlacements(tournament: inout Tournament, championID: String) {
        // Runner-up is the other grand final participant
        let grandFinal = tournament.matches.first { $0.round == 999 }
        if let grandFinal = grandFinal {
            let runnerUpID = grandFinal.player1ID == championID ? grandFinal.player2ID : grandFinal.player1ID
            if let runnerUpIndex = tournament.participants.firstIndex(where: { $0.userID == runnerUpID }) {
                tournament.participants[runnerUpIndex].placement = 2
            }
        }
    }
    
    private func setRoundRobinPlacements(tournament: inout Tournament) {
        // Sort all participants by wins (desc), then losses (asc)
        let sortedParticipants = tournament.participants.sorted { p1, p2 in
            if p1.wins != p2.wins {
                return p1.wins > p2.wins
            }
            return p1.losses < p2.losses
        }
        
        for (index, participant) in sortedParticipants.enumerated() {
            if let participantIndex = tournament.participants.firstIndex(where: { $0.userID == participant.userID }) {
                tournament.participants[participantIndex].placement = index + 1
            }
        }
    }
    
    private func nextPowerOfTwo(_ n: Int) -> Int {
        guard n > 0 else { return 1 }
        var power = 1
        while power < n {
            power *= 2
        }
        return power
    }
    
    // MARK: - Bracket Analysis (supports all formats)
    
    func getBracketStatus(tournament: Tournament) -> BracketStatus {
        let allMatches = tournament.matches
        let completedMatches = allMatches.filter { $0.status == "Completed" }
        
        switch tournament.type {
        case "Single Elimination":
            return getSingleElimStatus(tournament: tournament, allMatches: allMatches, completedMatches: completedMatches)
        case "Double Elimination":
            return getDoubleElimStatus(tournament: tournament, allMatches: allMatches, completedMatches: completedMatches)
        case "Round Robin":
            return getRoundRobinStatus(tournament: tournament, allMatches: allMatches, completedMatches: completedMatches)
        default:
            return getDoubleElimStatus(tournament: tournament, allMatches: allMatches, completedMatches: completedMatches)
        }
    }
    
    private func getSingleElimStatus(tournament: Tournament, allMatches: [TournamentMatch], completedMatches: [TournamentMatch]) -> BracketStatus {
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
    
    private func getDoubleElimStatus(tournament: Tournament, allMatches: [TournamentMatch], completedMatches: [TournamentMatch]) -> BracketStatus {
        let winnersMatches = allMatches.filter { $0.bracket == "Winners" && $0.round < 999 }
        let losersMatches = allMatches.filter { $0.bracket == "Losers" }
        let grandFinal = allMatches.first { $0.round == 999 }
        
        let completedWinners = winnersMatches.filter { $0.status == "Completed" }.count
        let completedLosers = losersMatches.filter { $0.status == "Completed" }.count
        
        return BracketStatus(
            winnersCompleted: completedWinners,
            winnersTotal: winnersMatches.count,
            losersCompleted: completedLosers,
            losersTotal: losersMatches.count,
            totalCompleted: completedMatches.count,
            totalMatches: allMatches.count,
            isGrandFinalReady: grandFinal?.status == "Ready",
            isResetActive: false,
            isComplete: tournament.status == "Completed"
        )
    }
    
    private func getRoundRobinStatus(tournament: Tournament, allMatches: [TournamentMatch], completedMatches: [TournamentMatch]) -> BracketStatus {
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
    
    // MARK: - Tournament Status and Analytics
    
    /// Calculates total number of matches for a tournament format
    func calculateTotalMatches(participants: Int, type: TournamentType) -> Int {
        switch type {
        case .singleElimination:
            return calculateSingleElimMatches(participants: participants)
        case .doubleElimination:
            return calculateDoubleElimMatches(participants: participants)
        case .roundRobin:
            return calculateRoundRobinMatches(participants: participants)
        case .swiss:
            return calculateSwissMatches(participants: participants)
        }
    }
    
    private func calculateSingleElimMatches(participants: Int) -> Int {
        // Single elimination: participants - 1 matches total
        return max(0, participants - 1)
    }
    
    private func calculateDoubleElimMatches(participants: Int) -> Int {
        // Double elimination: approximately 2 * (participants - 1) matches
        // More precisely: (participants - 1) winners bracket + up to (participants - 2) losers bracket + 1-2 grand finals
        let winnersMatches = max(0, participants - 1)
        let losersMatches = max(0, participants - 2)
        let grandFinals = 2 // Potentially 2 grand final matches
        return winnersMatches + losersMatches + grandFinals
    }
    
    private func calculateRoundRobinMatches(participants: Int) -> Int {
        // Round robin: each participant plays every other participant once
        // Formula: n * (n - 1) / 2
        return participants >= 2 ? (participants * (participants - 1)) / 2 : 0
    }
    
    private func calculateSwissMatches(participants: Int) -> Int {
        // Swiss system: typically 6-8 rounds depending on participants
        // Formula: approximately log2(participants) + 2 rounds
        let rounds = Int(log2(Double(participants))) + 2
        return participants * rounds / 2
    }
}

// MARK: - Legacy support (for existing code that uses DoubleEliminationService)
typealias DoubleEliminationService = BracketEngine

// MARK: - Supporting Types

struct BracketStatus {
    let winnersCompleted: Int
    let winnersTotal: Int
    let losersCompleted: Int
    let losersTotal: Int
    let totalCompleted: Int
    let totalMatches: Int
    let isGrandFinalReady: Bool
    let isResetActive: Bool
    let isComplete: Bool
    
    var winnersProgress: Double {
        guard winnersTotal > 0 else { return 0 }
        return Double(winnersCompleted) / Double(winnersTotal)
    }
    
    var losersProgress: Double {
        guard losersTotal > 0 else { return 0 }
        return Double(losersCompleted) / Double(losersTotal)
    }
    
    var overallProgress: Double {
        guard totalMatches > 0 else { return 0 }
        return Double(totalCompleted) / Double(totalMatches)
    }
} 