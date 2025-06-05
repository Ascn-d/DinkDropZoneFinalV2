import XCTest
@testable import Services

final class EloCalculatorTests: XCTestCase {
    func testExpectedScoreSymmetry() {
        let ratingA = 1000
        let ratingB = 1000
        let expected = EloCalculator.expectedScore(rating: ratingA, opponent: ratingB)
        XCTAssertEqual(expected, 0.5, accuracy: 0.0001)
    }

    func testRatingChangeWin() {
        let newRating = EloCalculator.newRating(current: 1000, opponent: 1000, didWin: true, kFactor: 32)
        XCTAssertEqual(newRating, 1016)
    }

    func testRatingChangeLose() {
        let newRating = EloCalculator.newRating(current: 1000, opponent: 1000, didWin: false, kFactor: 32)
        XCTAssertEqual(newRating, 984)
    }
} 