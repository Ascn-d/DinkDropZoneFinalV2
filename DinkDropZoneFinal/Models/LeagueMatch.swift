import Foundation
import SwiftData

@Model
final class LeagueMatch {
    var id: String
    var league: PickleLeague
    var match: Match
    var round: Int
    var matchNumber: Int
    var status: MatchStatus
    var scheduledDate: Date?
    var completedDate: Date?
    
    enum MatchStatus: String, Codable {
        case scheduled = "Scheduled"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"
    }
    

    
    init(
        id: String = UUID().uuidString,
        league: PickleLeague,
        match: Match,
        round: Int,
        matchNumber: Int,
        status: MatchStatus = .scheduled,
        scheduledDate: Date? = nil,
        completedDate: Date? = nil
    ) {
        self.id = id
        self.league = league
        self.match = match
        self.round = round
        self.matchNumber = matchNumber
        self.status = status
        self.scheduledDate = scheduledDate
        self.completedDate = completedDate
    }
    

} 