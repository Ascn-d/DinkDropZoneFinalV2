import SwiftData
import Foundation
import CoreLocation

@MainActor
struct SeedDataService {
    static let shared = SeedDataService()
    private init() {}
    
    static func seedIfNeeded(modelContext: ModelContext) {
        // Live matches
        if try! modelContext.fetch(FetchDescriptor<LiveMatch>()).isEmpty {
            let samples: [LiveMatch] = [
                LiveMatch(player1: "Sarah C.", player2: "Mike J.", court: "Court 1"),
                LiveMatch(player1: "Emma W.", player2: "Alex T.", court: "Court 3")
            ]
            samples.forEach { modelContext.insert($0) }
        }
        // Tournaments
        if try! modelContext.fetch(FetchDescriptor<QueueTournament>()).isEmpty {
            let today = Date()
            let tourneys = [
                QueueTournament(name: "Friday Night Lights", participants: 16, maxParticipants: 32, startTime: today.addingTimeInterval(3600*5)),
                QueueTournament(name: "Weekend Warriors", participants: 8, maxParticipants: 16, startTime: today.addingTimeInterval(3600*12))
            ]
            tourneys.forEach { modelContext.insert($0) }
        }
    }
    
    func seedData(context: ModelContext) {
        // Check if data already exists
        let descriptor = FetchDescriptor<User>()
        if let existingUsers = try? context.fetch(descriptor), !existingUsers.isEmpty {
            print("Data already seeded")
            return
        }
        
        // Use the existing static seeding methods
        SeedDataService.seedIfNeeded(modelContext: context)
        
        try? context.save()
        print("Data seeded successfully")
    }
    
    // MARK: - Firebase Data Seeding
    
    /// Seeds Firebase with sample data for alpha testing
    func seedFirebaseData() async {
        print("🔥 Starting Firebase data seeding for alpha testing...")
        
        await seedSampleUsers()
        await seedSampleMatches()
        await seedSampleAchievements()
        await seedSampleNotifications()
        await seedSampleStatistics()
        
        print("🔥 Firebase data seeding completed!")
    }
    
    private func seedSampleUsers() async {
        let sampleUsers = [
            ("alice@example.com", "Alice Johnson", 1650, 25.7749, -80.1937), // Miami
            ("bob@example.com", "Bob Smith", 1420, 34.0522, -118.2437), // LA
            ("carol@example.com", "Carol Davis", 1580, 40.7128, -74.0060), // NYC
            ("david@example.com", "David Wilson", 1380, 41.8781, -87.6298), // Chicago
            ("emma@example.com", "Emma Brown", 1720, 37.7749, -122.4194), // SF
            ("frank@example.com", "Frank Miller", 1290, 29.7604, -95.3698), // Houston
            ("grace@example.com", "Grace Lee", 1510, 39.9526, -75.1652), // Philadelphia
            ("henry@example.com", "Henry Garcia", 1460, 33.4484, -112.0740), // Phoenix
        ]
        
        for (email, name, elo, lat, lon) in sampleUsers {
            do {
                // Create user account
                let user = try await FirebaseService.shared.signUp(
                    email: email,
                    password: "password123",
                    displayName: name
                )
                
                // Update with additional data
                user.elo = elo
                user.lat = lat
                user.lon = lon
                user.totalMatches = Int.random(in: 10...100)
                user.wins = Int.random(in: 5...user.totalMatches)
                user.losses = user.totalMatches - user.wins
                user.winStreak = Int.random(in: 0...10)
                user.totalPointsScored = Int.random(in: 200...2000)
                user.totalPointsConceded = Int.random(in: 150...1800)
                user.xp = Int.random(in: 500...5000)
                
                try await FirebaseService.shared.updateUser(user)
                
                print("✅ Created sample user: \(name)")
                
            } catch {
                print("❌ Failed to create user \(name): \(error)")
            }
        }
    }
    
    private func seedSampleMatches() async {
        print("📝 Creating sample match history...")
        
        let sampleMatches = [
            ("alice@example.com", "bob@example.com", "11-7", true, 15),
            ("carol@example.com", "david@example.com", "11-9", false, -12),
            ("emma@example.com", "frank@example.com", "11-4", true, 20),
            ("grace@example.com", "henry@example.com", "11-8", true, 18),
        ]
        
        for (player1Email, player2Email, score, player1Wins, eloChange) in sampleMatches {
            do {
                // Look up users by email from Firebase
                let allUsers = try await FirebaseService.shared.getGlobalLeaderboard(limit: 100)
                
                guard let player1 = allUsers.first(where: { $0.email == player1Email }),
                      let player2 = allUsers.first(where: { $0.email == player2Email }) else {
                    print("❌ Could not find users for match: \(player1Email) vs \(player2Email)")
                    continue
                }
                
                // Create match in Firebase
                let matchId = try await FirebaseService.shared.createMatch(
                    GameMatch(
                        opponentName: player1Wins ? player2.displayName : player1.displayName,
                        result: player1Wins ? "Win" : "Loss",
                        score: score,
                        eloChange: player1Wins ? "+\(eloChange)" : "\(eloChange)",
                        date: Date().addingTimeInterval(-Double.random(in: 86400...2592000)) // Random date in last 30 days
                    ),
                    players: [player1, player2]
                )
                
                // Update player statistics
                var updatedPlayer1 = player1
                var updatedPlayer2 = player2
                
                if player1Wins {
                    updatedPlayer1.wins += 1
                    updatedPlayer1.winStreak += 1
                    updatedPlayer1.elo += abs(eloChange)
                    updatedPlayer2.losses += 1
                    updatedPlayer2.winStreak = 0
                    updatedPlayer2.elo -= abs(eloChange)
                } else {
                    updatedPlayer2.wins += 1
                    updatedPlayer2.winStreak += 1
                    updatedPlayer2.elo += abs(eloChange)
                    updatedPlayer1.losses += 1
                    updatedPlayer1.winStreak = 0
                    updatedPlayer1.elo -= abs(eloChange)
                }
                
                updatedPlayer1.totalMatches += 1
                updatedPlayer2.totalMatches += 1
                
                // Update users in Firebase
                try await FirebaseService.shared.updateUser(updatedPlayer1)
                try await FirebaseService.shared.updateUser(updatedPlayer2)
                
                print("✅ Created match: \(player1Email) vs \(player2Email), score: \(score) (Match ID: \(matchId))")
                
            } catch {
                print("❌ Failed to create match \(player1Email) vs \(player2Email): \(error)")
            }
        }
    }
    
    private func seedSampleAchievements() async {
        print("🏆 Creating sample achievements...")
        
        // For each sample user, unlock some random achievements
        let sampleEmails = ["alice@example.com", "bob@example.com", "carol@example.com"]
        
        for email in sampleEmails {
            do {
                // Get user from Firebase
                let allUsers = try await FirebaseService.shared.getGlobalLeaderboard(limit: 100)
                guard let user = allUsers.first(where: { $0.email == email }) else {
                    print("❌ Could not find user for achievements: \(email)")
                    continue
                }
                
                // Create sample achievements (simplified for now)
                let sampleAchievements = [
                    Trophy(
                        title: "First Victory",
                        description: "Win your first match",
                        category: .competitive,
                        tier: .bronze,
                        icon: "trophy.fill",
                        conditions: [
                            AchievementCondition(type: .matchesWon, value: 1, timeframe: .allTime)
                        ]
                    ),
                    Trophy(
                        title: "Rising Star",
                        description: "Reach 1500 ELO",
                        category: .progression,
                        tier: .silver,
                        icon: "star.fill",
                        conditions: [
                            AchievementCondition(type: .eloRating, value: 1500, timeframe: .allTime)
                        ]
                    ),
                    Trophy(
                        title: "Social Player",
                        description: "Play 10 matches",
                        category: .social,
                        tier: .bronze,
                        icon: "person.2.fill",
                        conditions: [
                            AchievementCondition(type: .matchesPlayed, value: 10, timeframe: .allTime)
                        ]
                    )
                ]
                
                // Save achievements to Firebase
                try await FirebaseService.shared.saveAchievements(sampleAchievements, for: user.id.uuidString)
                
                let unlockedCount = sampleAchievements.filter { $0.isUnlocked }.count
                print("✅ Created \(unlockedCount) achievements for \(email)")
                
            } catch {
                print("❌ Failed to create achievements for \(email): \(error)")
            }
        }
    }
    
    private func seedSampleNotifications() async {
        print("🔔 Creating sample notifications...")
        
        let sampleNotifications = [
            ("alice@example.com", "friend_request", "New Friend Request", "Bob wants to be your friend!", ["senderId": "bob-id"]),
            ("bob@example.com", "achievement", "Achievement Unlocked!", "You've reached 1400 ELO!", ["achievementId": "rising-star"]),
            ("carol@example.com", "match", "Match Invitation", "David invited you to a match", ["matchId": "sample-match-id"]),
        ]
        
        for (email, type, title, message, data) in sampleNotifications {
            do {
                // Get user from Firebase
                let allUsers = try await FirebaseService.shared.getGlobalLeaderboard(limit: 100)
                guard let user = allUsers.first(where: { $0.email == email }) else {
                    print("❌ Could not find user for notification: \(email)")
                    continue
                }
                
                // Create notification in Firebase
                try await FirebaseService.shared.addNotification(
                    userId: user.id.uuidString,
                    type: type,
                    title: title,
                    message: message,
                    data: data
                )
                
                print("✅ Created notification for \(email): \(title)")
                
            } catch {
                print("❌ Failed to create notification for \(email): \(error)")
            }
        }
    }
    
    private func seedSampleStatistics() async {
        print("📊 Creating sample statistics...")
        
        // Create detailed statistics for sample users
        let sampleEmails = ["alice@example.com", "bob@example.com", "carol@example.com"]
        
        for email in sampleEmails {
            do {
                // Get user from Firebase
                let allUsers = try await FirebaseService.shared.getGlobalLeaderboard(limit: 100)
                guard let user = allUsers.first(where: { $0.email == email }) else {
                    print("❌ Could not find user for statistics: \(email)")
                    continue
                }
                
                // Create realistic statistics based on user's current data
                let detailedStats = DetailedUserStats(
                    totalMatches: max(user.totalMatches, Int.random(in: 10...50)),
                    wins: max(user.wins, Int.random(in: 5...25)),
                    losses: max(user.losses, Int.random(in: 3...20)),
                    winRate: user.totalMatches > 0 ? Double(user.wins) / Double(user.totalMatches) : Double.random(in: 0.4...0.7),
                    elo: user.elo,
                    winStreak: user.winStreak,
                    longestWinStreak: max(user.winStreak, Int.random(in: 0...15)),
                    averagePointsScored: Double.random(in: 8...12),
                    averagePointsConceded: Double.random(in: 7...11),
                    pointsDifferential: Int.random(in: -20...40)
                )
                
                // Save statistics to Firebase
                try await FirebaseService.shared.saveUserStatistics(detailedStats, for: user.id.uuidString)
                
                print("✅ Created statistics for \(email)")
                
            } catch {
                print("❌ Failed to create statistics for \(email): \(error)")
            }
        }
    }
    
    // MARK: - Original Local Seeding Methods
} 