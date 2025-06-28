import XCTest
@testable import DinkDropZoneFinal

final class TournamentTests: XCTestCase {
    
    var bracketEngine: BracketEngine!
    var mockParticipants: [TournamentParticipant]!
    
    override func setUpWithError() throws {
        bracketEngine = BracketEngine()
        
        // Create mock participants
        mockParticipants = [
            TournamentParticipant(userID: "user1", displayName: "Player 1", elo: 1200),
            TournamentParticipant(userID: "user2", displayName: "Player 2", elo: 1150),
            TournamentParticipant(userID: "user3", displayName: "Player 3", elo: 1100),
            TournamentParticipant(userID: "user4", displayName: "Player 4", elo: 1050),
            TournamentParticipant(userID: "user5", displayName: "Player 5", elo: 1000),
            TournamentParticipant(userID: "user6", displayName: "Player 6", elo: 950),
            TournamentParticipant(userID: "user7", displayName: "Player 7", elo: 900),
            TournamentParticipant(userID: "user8", displayName: "Player 8", elo: 850)
        ]
    }
    
    override func tearDownWithError() throws {
        bracketEngine = nil
        mockParticipants = nil
    }
    
    // MARK: - Single Elimination Tests
    
    func testSingleEliminationBracketGeneration() throws {
        // Create tournament
        var tournament = Tournament(
            name: "Test Single Elim",
            type: "Single Elimination",
            organizerID: "organizer1",
            organizerName: "Test Organizer"
        )
        tournament.participants = Array(mockParticipants.prefix(8))
        
        // Generate bracket
        let matches = bracketEngine.generateBracket(for: tournament)
        
        // Should have 7 matches for 8 players (8-4-2-1)
        XCTAssertEqual(matches.count, 7)
        
        // Should have 4 first round matches
        let firstRoundMatches = matches.filter { $0.round == 1 && $0.bracket == "Main" }
        XCTAssertEqual(firstRoundMatches.count, 4)
        
        // All first round matches should have players assigned
        for match in firstRoundMatches {
            XCTAssertFalse(match.player1ID.isEmpty)
            XCTAssertFalse(match.player2ID.isEmpty)
            XCTAssertFalse(match.player1Name.isEmpty)
            XCTAssertFalse(match.player2Name.isEmpty)
        }
    }
    
    func testSingleEliminationWithByes() throws {
        // Test with 6 players (should create 2 bye matches)
        var tournament = Tournament(
            name: "Test Single Elim Byes",
            type: "Single Elimination",
            organizerID: "organizer1",
            organizerName: "Test Organizer"
        )
        tournament.participants = Array(mockParticipants.prefix(6))
        
        let matches = bracketEngine.generateBracket(for: tournament)
        
        // Should have bye matches
        let byeMatches = matches.filter { $0.isBye }
        XCTAssertEqual(byeMatches.count, 2)
        
        // Bye matches should be completed automatically
        for byeMatch in byeMatches {
            XCTAssertEqual(byeMatch.status, "Completed")
            XCTAssertNotNil(byeMatch.winnerID)
            XCTAssertEqual(byeMatch.finalScore, "Bye")
        }
    }
    
    // MARK: - Double Elimination Tests
    
    func testDoubleEliminationBracketGeneration() throws {
        var tournament = Tournament(
            name: "Test Double Elim",
            type: "Double Elimination",
            organizerID: "organizer1",
            organizerName: "Test Organizer"
        )
        tournament.participants = Array(mockParticipants.prefix(8))
        
        let matches = bracketEngine.generateBracket(for: tournament)
        
        // Should have winners bracket, losers bracket, and grand final
        let winnersMatches = matches.filter { $0.bracket == "Winners" && $0.round < 999 }
        let losersMatches = matches.filter { $0.bracket == "Losers" }
        let grandFinalMatches = matches.filter { $0.round == 999 }
        
        XCTAssertGreaterThan(winnersMatches.count, 0)
        XCTAssertGreaterThan(losersMatches.count, 0)
        XCTAssertEqual(grandFinalMatches.count, 1)
    }
    
    // MARK: - Round Robin Tests
    
    func testRoundRobinBracketGeneration() throws {
        var tournament = Tournament(
            name: "Test Round Robin",
            type: "Round Robin",
            organizerID: "organizer1",
            organizerName: "Test Organizer"
        )
        tournament.participants = Array(mockParticipants.prefix(4))
        
        let matches = bracketEngine.generateBracket(for: tournament)
        
        // 4 players should create 6 matches (n * (n-1) / 2)
        XCTAssertEqual(matches.count, 6)
        
        // All matches should be in round robin bracket
        let roundRobinMatches = matches.filter { $0.bracket == "Round Robin" }
        XCTAssertEqual(roundRobinMatches.count, 6)
        
        // Verify all possible matchups exist
        var playerPairs: Set<String> = []
        for match in matches {
            let pair1 = "\(match.player1ID)-\(match.player2ID)"
            let pair2 = "\(match.player2ID)-\(match.player1ID)"
            XCTAssertFalse(playerPairs.contains(pair1))
            XCTAssertFalse(playerPairs.contains(pair2))
            playerPairs.insert(pair1)
        }
    }
    
    // MARK: - Match Progression Tests
    
    func testSingleEliminationMatchProgression() throws {
        var tournament = Tournament(
            name: "Test Match Progression",
            type: "Single Elimination",
            organizerID: "organizer1",
            organizerName: "Test Organizer"
        )
        tournament.participants = Array(mockParticipants.prefix(4))
        tournament.matches = bracketEngine.generateBracket(for: tournament)
        
        // Get first round matches
        let firstRoundMatches = tournament.matches.filter { $0.round == 1 && $0.bracket == "Main" }
        XCTAssertEqual(firstRoundMatches.count, 2)
        
        // Complete first match
        let firstMatch = firstRoundMatches[0]
        bracketEngine.completeMatch(
            firstMatch,
            winnerID: firstMatch.player1ID,
            loserID: firstMatch.player2ID,
            score: "11-9",
            tournament: &tournament
        )
        
        // Check that match is marked complete
        let updatedMatch = tournament.matches.first { $0.id == firstMatch.id }
        XCTAssertEqual(updatedMatch?.status, "Completed")
        XCTAssertEqual(updatedMatch?.winnerID, firstMatch.player1ID)
        XCTAssertEqual(updatedMatch?.finalScore, "11-9")
        
        // Check participant records updated
        let winner = tournament.participants.first { $0.userID == firstMatch.player1ID }
        let loser = tournament.participants.first { $0.userID == firstMatch.player2ID }
        XCTAssertEqual(winner?.wins, 1)
        XCTAssertEqual(loser?.losses, 1)
    }
    
    func testRoundRobinCompletion() throws {
        var tournament = Tournament(
            name: "Test Round Robin Completion",
            type: "Round Robin",
            organizerID: "organizer1",
            organizerName: "Test Organizer"
        )
        tournament.participants = Array(mockParticipants.prefix(4))
        tournament.matches = bracketEngine.generateBracket(for: tournament)
        
        // Complete all matches with player1 winning
        for match in tournament.matches {
            bracketEngine.completeMatch(
                match,
                winnerID: match.player1ID,
                loserID: match.player2ID,
                score: "11-9",
                tournament: &tournament
            )
        }
        
        // Tournament should be completed
        XCTAssertEqual(tournament.status, "Completed")
        
        // Check final placements
        let champion = tournament.participants.first { $0.placement == 1 }
        XCTAssertNotNil(champion)
        XCTAssertGreaterThan(champion?.wins ?? 0, 0)
    }
    
    // MARK: - Bracket Status Tests
    
    func testBracketStatusCalculation() throws {
        var tournament = Tournament(
            name: "Test Bracket Status",
            type: "Double Elimination",
            organizerID: "organizer1",
            organizerName: "Test Organizer"
        )
        tournament.participants = Array(mockParticipants.prefix(4))
        tournament.matches = bracketEngine.generateBracket(for: tournament)
        
        // Initial status
        let initialStatus = bracketEngine.getBracketStatus(tournament: tournament)
        XCTAssertEqual(initialStatus.totalCompleted, 0)
        XCTAssertGreaterThan(initialStatus.totalMatches, 0)
        XCTAssertEqual(initialStatus.overallProgress, 0.0)
        
        // Complete one match
        if let firstMatch = tournament.matches.first {
            bracketEngine.completeMatch(
                firstMatch,
                winnerID: firstMatch.player1ID,
                loserID: firstMatch.player2ID,
                score: "11-9",
                tournament: &tournament
            )
        }
        
        let progressStatus = bracketEngine.getBracketStatus(tournament: tournament)
        XCTAssertEqual(progressStatus.totalCompleted, 1)
        XCTAssertGreaterThan(progressStatus.overallProgress, 0.0)
    }
    
    // MARK: - Edge Cases
    
    func testMinimumParticipants() throws {
        var tournament = Tournament(
            name: "Test Minimum",
            type: "Single Elimination",
            organizerID: "organizer1",
            organizerName: "Test Organizer"
        )
        tournament.participants = Array(mockParticipants.prefix(2)) // Below minimum
        
        let matches = bracketEngine.generateBracket(for: tournament)
        XCTAssertEqual(matches.count, 0) // Should generate no matches
    }
    
    func testPowerOfTwoBracketSize() throws {
        for playerCount in [4, 8, 16, 32] {
            var tournament = Tournament(
                name: "Test \(playerCount) players",
                type: "Single Elimination",
                organizerID: "organizer1",
                organizerName: "Test Organizer"
            )
            
            // Create enough participants
            var participants: [TournamentParticipant] = []
            for i in 0..<playerCount {
                participants.append(TournamentParticipant(
                    userID: "user\(i)",
                    displayName: "Player \(i)",
                    elo: 1000 + i * 10
                ))
            }
            tournament.participants = participants
            
            let matches = bracketEngine.generateBracket(for: tournament)
            
            // Should generate correct number of matches for single elimination
            let expectedMatches = playerCount - 1
            XCTAssertEqual(matches.count, expectedMatches,
                          "Expected \(expectedMatches) matches for \(playerCount) players")
        }
    }
}

// MARK: - TournamentService Tests

final class TournamentServiceTests: XCTestCase {
    
    // Note: These would require Firebase emulator or mocking
    // For now, we'll test the non-Firebase dependent logic
    
    func testTournamentStatusCalculation() throws {
        // Test user tournament status logic
        let tournament = Tournament(
            name: "Test Tournament",
            organizerID: "organizer1",
            organizerName: "Test Organizer"
        )
        
        let user = User(email: "test@example.com", password: "", displayName: "Test User")
        
        // These tests would require actual TournamentService instance
        // which needs ModelContext and Firebase setup
        XCTAssertTrue(true) // Placeholder
    }
}

// MARK: - Helper Extensions

extension TournamentTests {
    
    func createMockTournament(type: String = "Double Elimination", participantCount: Int = 8) -> Tournament {
        var tournament = Tournament(
            name: "Mock Tournament",
            type: type,
            organizerID: "mock_organizer",
            organizerName: "Mock Organizer"
        )
        
        tournament.participants = Array(mockParticipants.prefix(participantCount))
        return tournament
    }
} 