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
        // This would create sample match history for the users
        // For brevity, we'll create a few sample matches
        
        let sampleMatches = [
            ("alice@example.com", "bob@example.com", "11-7", true),
            ("carol@example.com", "david@example.com", "11-9", false),
            ("emma@example.com", "frank@example.com", "11-4", true),
            ("grace@example.com", "henry@example.com", "11-8", true),
        ]
        
        for (player1Email, player2Email, score, _) in sampleMatches {
            // In a real implementation, you'd look up users by email and create match records
            print("📝 Would create match: \(player1Email) vs \(player2Email), score: \(score)")
        }
    }
    
    private func seedSampleAchievements() async {
        // Seed some unlocked achievements for sample users
        let achievements = AchievementDefinitions.allAchievements
        
        // For each sample user, unlock some random achievements
        let sampleEmails = ["alice@example.com", "bob@example.com", "carol@example.com"]
        
        for email in sampleEmails {
            var userAchievements = achievements
            
            // Randomly unlock some achievements
            let unlockedCount = Int.random(in: 3...8)
            for i in 0..<min(unlockedCount, achievements.count) {
                userAchievements[i].isUnlocked = true
                userAchievements[i].unlockedAt = Date().addingTimeInterval(-Double.random(in: 0...2592000)) // Random time in last 30 days
            }
            
            // In a real implementation, you'd save these achievements to Firebase
            print("🏆 Would unlock \(unlockedCount) achievements for \(email)")
        }
    }
    
    private func seedSampleNotifications() async {
        let sampleNotifications = [
            ("alice@example.com", "friend_request", "New Friend Request", "Bob wants to be your friend!"),
            ("bob@example.com", "achievement", "Achievement Unlocked!", "You've reached 1400 ELO!"),
            ("carol@example.com", "match", "Match Invitation", "David invited you to a match"),
        ]
        
        for (email, _, title, _) in sampleNotifications {
            // In a real implementation, you'd look up the user ID and create notifications
            print("🔔 Would create notification for \(email): \(title)")
        }
    }
    
    private func seedSampleStatistics() async {
        // Create detailed statistics for sample users
        let sampleEmails = ["alice@example.com", "bob@example.com", "carol@example.com"]
        
        for email in sampleEmails {
            let stats = DetailedUserStats(
                totalMatches: Int.random(in: 10...100),
                wins: Int.random(in: 5...50),
                losses: Int.random(in: 5...50),
                winRate: Double.random(in: 0.3...0.7),
                elo: Int.random(in: 1200...1800),
                winStreak: Int.random(in: 0...10),
                longestWinStreak: Int.random(in: 0...15),
                averagePointsScored: Double.random(in: 8...12),
                averagePointsConceded: Double.random(in: 7...11),
                pointsDifferential: Int.random(in: -50...50)
            )
            
            // In a real implementation, you'd save these stats to Firebase
            print("📊 Would create statistics for \(email)")
        }
    }
    
    // MARK: - Original Local Seeding Methods
} 