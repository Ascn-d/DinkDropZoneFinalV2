import Foundation

// MARK: - Daily Stats

struct DailyStats: Codable {
    var date: Date = Calendar.current.startOfDay(for: Date())
    var xpEarned: Int = 0
    var matchesPlayed: Int = 0
    var matchesWon: Int = 0
    var messagesSent: Int = 0
    var friendsAdded: Int = 0
    var courtsVisited: Int = 0
    var missionsCompleted: Int = 0
    var trophiesUnlocked: Int = 0
    var lastLogin: Date = Date()
    
    var winRate: Double {
        guard matchesPlayed > 0 else { return 0.0 }
        return Double(matchesWon) / Double(matchesPlayed)
    }
    
    mutating func reset() {
        date = Calendar.current.startOfDay(for: Date())
        xpEarned = 0
        matchesPlayed = 0
        matchesWon = 0
        messagesSent = 0
        friendsAdded = 0
        courtsVisited = 0
        missionsCompleted = 0
        trophiesUnlocked = 0
    }
    
    func shouldReset() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        return !Calendar.current.isDate(date, inSameDayAs: today)
    }
}

// MARK: - Weekly Stats

struct WeeklyStats: Codable {
    var weekStart: Date = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    var xpEarned: Int = 0
    var matchesPlayed: Int = 0
    var matchesWon: Int = 0
    var socialMatches: Int = 0
    var tournamentsJoined: Int = 0
    var tournamentsWon: Int = 0
    var perfectGames: Int = 0
    var courtsVisited: Set<String> = []
    var missionsCompleted: Int = 0
    var lastWeeklyLogin: Date = Date()
    
    var winRate: Double {
        guard matchesPlayed > 0 else { return 0.0 }
        return Double(matchesWon) / Double(matchesPlayed)
    }
    
    var uniqueCourtsVisited: Int {
        return courtsVisited.count
    }
    
    mutating func reset() {
        weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        xpEarned = 0
        matchesPlayed = 0
        matchesWon = 0
        socialMatches = 0
        tournamentsJoined = 0
        tournamentsWon = 0
        perfectGames = 0
        courtsVisited.removeAll()
        missionsCompleted = 0
    }
    
    func shouldReset() -> Bool {
        let currentWeekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return weekStart < currentWeekStart
    }
}

// MARK: - Lifetime Stats

struct LifetimeStats: Codable {
    var totalXP: Int = 0
    var matchesPlayed: Int = 0
    var matchesWon: Int = 0
    var matchesLost: Int = 0
    var perfectGames: Int = 0
    var socialMatches: Int = 0
    var currentWinStreak: Int = 0
    var longestWinStreak: Int = 0
    var tournamentsJoined: Int = 0
    var tournamentsWon: Int = 0
    var friendsAdded: Int = 0
    var messagesSent: Int = 0
    var courtsVisited: Int = 0
    var dailyLogins: Int = 0
    var consecutiveDays: Int = 0
    var lastLoginDate: Date?
    var accountCreated: Date = Date()
    
    // Advanced Stats
    var totalPlayTime: TimeInterval = 0
    var averageMatchDuration: TimeInterval = 0
    var favoriteTimeOfDay: Int = 12 // Hour of day (0-23)
    var weekendMatches: Int = 0
    var earlyBirdMatches: Int = 0 // Before 9 AM
    var nightOwlMatches: Int = 0 // After 9 PM
    var comebackWins: Int = 0 // Won after being down 0-8
    var streaksBroken: Int = 0 // Ended opponent's 5+ win streak
    
    var winRate: Double {
        guard matchesPlayed > 0 else { return 0.0 }
        return Double(matchesWon) / Double(matchesPlayed)
    }
    
    var lossRate: Double {
        guard matchesPlayed > 0 else { return 0.0 }
        return Double(matchesLost) / Double(matchesPlayed)
    }
    
    var perfectGameRate: Double {
        guard matchesWon > 0 else { return 0.0 }
        return Double(perfectGames) / Double(matchesWon)
    }
    
    var tournamentWinRate: Double {
        guard tournamentsJoined > 0 else { return 0.0 }
        return Double(tournamentsWon) / Double(tournamentsJoined)
    }
    
    var socialMatchRate: Double {
        guard matchesPlayed > 0 else { return 0.0 }
        return Double(socialMatches) / Double(matchesPlayed)
    }
    
    var accountAge: Int {
        let components = Calendar.current.dateComponents([.day], from: accountCreated, to: Date())
        return components.day ?? 0
    }
    
    mutating func updateLoginStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        
        if let lastLogin = lastLoginDate {
            let daysSinceLastLogin = Calendar.current.dateComponents([.day], from: lastLogin, to: today).day ?? 0
            
            if daysSinceLastLogin == 1 {
                // Consecutive day
                consecutiveDays += 1
            } else if daysSinceLastLogin > 1 {
                // Streak broken
                consecutiveDays = 1
            }
            // If daysSinceLastLogin == 0, already logged in today
        } else {
            // First login
            consecutiveDays = 1
        }
        
        lastLoginDate = today
        dailyLogins += 1
    }
    
    mutating func recordMatch(won: Bool, duration: TimeInterval, isPerfectGame: Bool = false, isSocialMatch: Bool = false, isComeback: Bool = false, brokeStreak: Bool = false) {
        matchesPlayed += 1
        totalPlayTime += duration
        averageMatchDuration = totalPlayTime / Double(matchesPlayed)
        
        if won {
            matchesWon += 1
            currentWinStreak += 1
            longestWinStreak = max(longestWinStreak, currentWinStreak)
            
            if isPerfectGame {
                perfectGames += 1
            }
            
            if isComeback {
                comebackWins += 1
            }
        } else {
            matchesLost += 1
            currentWinStreak = 0
        }
        
        if isSocialMatch {
            socialMatches += 1
        }
        
        if brokeStreak {
            streaksBroken += 1
        }
        
        // Track time of day
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 9 {
            earlyBirdMatches += 1
        } else if hour >= 21 {
            nightOwlMatches += 1
        }
        
        // Track weekend matches
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 1 || weekday == 7 { // Sunday or Saturday
            weekendMatches += 1
        }
        
        // Update favorite time of day (simplified)
        favoriteTimeOfDay = hour
    }
}

// MARK: - Achievement Progress

struct AchievementProgress: Codable {
    var matchesPlayed: Int = 0
    var matchesWon: Int = 0
    var perfectGames: Int = 0
    var winStreak: Int = 0
    var longestWinStreak: Int = 0
    var tournamentsWon: Int = 0
    var friendsAdded: Int = 0
    var messagesSent: Int = 0
    var socialMatches: Int = 0
    var courtsVisited: Int = 0
    var dailyLogins: Int = 0
    var consecutiveLogins: Int = 0
    var totalXP: Int = 0
    var missionsCompleted: Int = 0
    var level: Int = 1
    
    func getProgress(for trophy: TrophyType) -> (current: Int, target: Int, percentage: Double) {
        let (current, target) = getProgressValues(for: trophy)
        let percentage = min(Double(current) / Double(target), 1.0)
        return (current, target, percentage)
    }
    
    private func getProgressValues(for trophy: TrophyType) -> (current: Int, target: Int) {
        switch trophy {
        case .firstWin:
            return (matchesWon, 1)
        case .winStreak5:
            return (longestWinStreak, 5)
        case .winStreak10:
            return (longestWinStreak, 10)
        case .perfectionist:
            return (perfectGames, 1)
        case .centurion:
            return (matchesPlayed, 100)
        case .champion:
            return (tournamentsWon, 1)
        case .grandSlam:
            return (tournamentsWon, 5)
        case .socialButterfly:
            return (friendsAdded, 10)
        case .messenger:
            return (messagesSent, 100)
        case .teamPlayer:
            return (socialMatches, 25)
        case .rookie:
            return (level, 5)
        case .veteran:
            return (level, 10)
        case .expert:
            return (level, 25)
        case .master:
            return (level, 50)
        case .legend:
            return (level, 100)
        case .taskmaster:
            return (missionsCompleted, 50)
        case .dedicated:
            return (consecutiveLogins, 30)
        case .consistent:
            return (dailyLogins, 100)
        case .xpCollector:
            return (totalXP, 10000)
        case .explorer:
            return (courtsVisited, 10)
        case .earlyBird:
            return (0, 10) // Needs special tracking
        case .nightOwl:
            return (0, 10) // Needs special tracking
        case .weekendWarrior:
            return (0, 50) // Needs special tracking
        case .streakBreaker:
            return (0, 1) // Needs special tracking
        case .comeback:
            return (0, 1) // Needs special tracking
        case .unstoppable:
            return (longestWinStreak, 20)
        }
    }
}

// MARK: - Stats Summary

struct StatsSummary: Codable {
    let daily: DailyStats
    let weekly: WeeklyStats
    let lifetime: LifetimeStats
    let achievements: AchievementProgress
    
    var todayXP: Int { daily.xpEarned }
    var weekXP: Int { weekly.xpEarned }
    var totalXP: Int { lifetime.totalXP }
    
    var todayMatches: Int { daily.matchesPlayed }
    var weekMatches: Int { weekly.matchesPlayed }
    var totalMatches: Int { lifetime.matchesPlayed }
    
    var todayWinRate: Double { daily.winRate }
    var weekWinRate: Double { weekly.winRate }
    var overallWinRate: Double { lifetime.winRate }
    
    var currentStreak: Int { lifetime.currentWinStreak }
    var longestStreak: Int { lifetime.longestWinStreak }
    
    var accountAge: Int { lifetime.accountAge }
    var loginStreak: Int { lifetime.consecutiveDays }
} 