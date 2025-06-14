import SwiftUI
import SwiftData
import Observation
import PhotosUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Query private var allMatches: [Match]
    @State private var isEditingProfile = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingMatchHistory = false
    @State private var showingAllAchievements = false
    
    // Helper to get matches for current user
    private var userMatches: [Match] {
        guard let currentUser = appState.currentUser else { return [] }
        return allMatches.filter { match in
            match.player1.id == currentUser.id || match.player2.id == currentUser.id
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section with Avatar and Basic Info
                    profileHeaderSection
                    
                    // Level and XP Section
                    levelProgressSection
                    
                    // Quick Stats Cards
                    quickStatsSection
                    
                    // Daily Challenges Section
                    dailyChallengesSection
                    
                    // Training Partner Section
                    trainingPartnerSection
                    
                    // Streaks & Milestones Section
                    streaksSection
                    
                    // Shot Mastery Section
                    shotMasterySection
                    
                    // Bio Section
                    bioSection
                    
                    // Achievements & Badges Section
                    achievementsBadgesSection
                    
                    // Recent Activity Section
                    recentActivitySection
                    
                    // Detailed Stats Section
                    detailedStatsSection
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isEditingProfile = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button("Log Out") {
                        appState.currentUser = nil
                    }
                    .foregroundColor(.red)
                }
            }
            .sheet(isPresented: $isEditingProfile) {
                if let user = appState.currentUser {
                    ProfileEditView(user: user)
                }
            }
            .sheet(isPresented: $showingMatchHistory) {
                MatchHistoryView()
            }
            .sheet(isPresented: $showingAllAchievements) {
                AchievementsView()
            }
        }
    }
    
    // MARK: - Profile Header Section
    
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            if let user = appState.currentUser {
                // Background gradient
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(height: 220)
                    
                    VStack(spacing: 16) {
                        // Profile Image with Level Border
                        ZStack {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 4
                                )
                                .frame(width: 120, height: 120)
                            
                            if let imageURL = user.profileImageURL {
                                AsyncImage(url: URL(string: imageURL)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .foregroundColor(.white)
                                }
                                .frame(width: 110, height: 110)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .frame(width: 110, height: 110)
                                    .foregroundColor(.white)
                            }
                            
                            // Level Badge
                            VStack {
                                Spacer()
                    HStack {
                        Spacer()
                                    Text("\(calculateLevel(from: user.xp))")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(Color.orange)
                                                .shadow(radius: 2)
                                        )
                                        .offset(x: -10, y: -10)
                                }
                            }
                        }
                        
                        // Name and Skill Level
                        VStack(spacing: 4) {
                            Text(user.displayName.isEmpty ? user.email.components(separatedBy: "@").first ?? "Player" : user.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                if !user.skillLevel.isEmpty {
                                    Text(user.skillLevel.uppercased())
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(skillLevelColor(user.skillLevel))
                                                .shadow(radius: 1)
                                        )
                                }
                                
                                if !user.location.isEmpty {
                                    HStack(spacing: 4) {
                                        Image(systemName: "location.fill")
                                        Text(user.location)
                                    }
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
    }
    
    // MARK: - Level Progress Section
    
    private var levelProgressSection: some View {
        VStack(spacing: 12) {
            if let user = appState.currentUser {
                let currentLevel = calculateLevel(from: user.xp)
                let nextLevelXP = calculateXPForLevel(currentLevel + 1)
                let currentLevelXP = calculateXPForLevel(currentLevel)
                let rawProgress = Double(user.xp - currentLevelXP) / Double(nextLevelXP - currentLevelXP)
                let progress = min(max(rawProgress, 0), 1)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Level \(currentLevel)")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("\(user.xp - currentLevelXP) / \(nextLevelXP - currentLevelXP) XP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Total XP: \(user.xp)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Quick Stats Section
    
    private var quickStatsSection: some View {
        VStack(spacing: 16) {
            if let user = appState.currentUser {
                HStack {
                    Text("Quick Stats")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    QuickStatBadge(
                        title: "ELO",
                        value: "\(user.elo)",
                        icon: "star.fill",
                        color: eloColor(for: user.elo),
                        gradient: true
                    )
                    
                    QuickStatBadge(
                        title: "Win Rate",
                        value: user.formattedWinRate,
                        icon: "chart.line.uptrend.xyaxis",
                        color: winRateColor(for: user.winRate),
                        gradient: true
                    )
                    
                    QuickStatBadge(
                        title: "Matches",
                        value: "\(user.totalMatches)",
                        icon: "gamecontroller.fill",
                        color: .blue,
                        gradient: false
                    )
                    
                    QuickStatBadge(
                        title: "Win Streak",
                        value: "\(user.winStreak)",
                        icon: "flame.fill",
                        color: user.winStreak > 0 ? .orange : .gray,
                        gradient: user.winStreak > 0
                    )
                    
                    QuickStatBadge(
                        title: "Best Streak",
                        value: "\(user.longestWinStreak)",
                        icon: "bolt.fill",
                        color: .yellow,
                        gradient: true
                    )
                    
                    QuickStatBadge(
                        title: "Points +/-",
                        value: "\(user.pointsDifferential > 0 ? "+" : "")\(user.pointsDifferential)",
                        icon: user.pointsDifferential > 0 ? "plus.circle.fill" : "minus.circle.fill",
                        color: user.pointsDifferential > 0 ? .green : .red,
                        gradient: true
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Daily Challenges Section
    
    private var dailyChallengesSection: some View {
        VStack(spacing: 16) {
            if let _ = appState.currentUser {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .foregroundColor(.orange)
                        Text("Daily Challenges")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Text("2/3 Complete")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                }
                
                VStack(spacing: 8) {
                    DailyChallengeCard(
                        title: "Play a Match",
                        description: "Complete 1 match today",
                        progress: 1.0,
                        reward: "+50 XP",
                        isCompleted: true,
                        icon: "gamecontroller.fill"
                    )
                    
                    DailyChallengeCard(
                        title: "Win a Game",
                        description: "Win 1 game today",
                        progress: 1.0,
                        reward: "+75 XP",
                        isCompleted: true,
                        icon: "trophy.fill"
                    )
                    
                    DailyChallengeCard(
                        title: "Social Player",
                        description: "Play with 2 different opponents",
                        progress: 0.5,
                        reward: "+100 XP",
                        isCompleted: false,
                        icon: "person.2.fill"
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Training Partner Section
    
    private var trainingPartnerSection: some View {
        VStack(spacing: 16) {
            if let _ = appState.currentUser {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.blue)
                        Text("Training Partner")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Button("Change") {
                        // TODO: Implement partner selection
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                TrainingPartnerCard(
                    name: "Sarah Chen",
                    skillLevel: "Advanced",
                    matchesPlayed: 12,
                    winRate: 0.75,
                    lastPlayed: "2 days ago",
                    partnershipDays: 45,
                    profileImage: nil
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Streaks Section
    
    private var streaksSection: some View {
        VStack(spacing: 16) {
            if let _ = appState.currentUser {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("Streaks & Milestones")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    Spacer()
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StreakCard(
                        title: "Daily Play",
                        value: "7",
                        subtitle: "days",
                        icon: "calendar.circle.fill",
                        color: .green,
                        isActive: true
                    )
                    
                    StreakCard(
                        title: "Weekly Win",
                        value: "3",
                        subtitle: "weeks",
                        icon: "trophy.circle.fill",
                        color: .blue,
                        isActive: true
                    )
                    
                    StreakCard(
                        title: "Social Streak",
                        value: "12",
                        subtitle: "new players",
                        icon: "person.2.circle.fill",
                        color: .purple,
                        isActive: false
                    )
                    
                    StreakCard(
                        title: "Court Explorer",
                        value: "5",
                        subtitle: "courts",
                        icon: "map.circle.fill",
                        color: .orange,
                        isActive: false
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Shot Mastery Section
    
    private var shotMasterySection: some View {
        VStack(spacing: 16) {
            if let _ = appState.currentUser {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "target")
                            .foregroundColor(.purple)
                        Text("Shot Mastery")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    Text("8/12 Shots")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.purple.opacity(0.2)))
                }
                
                VStack(spacing: 12) {
                    // Mastered shots
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ShotMasteryBadge(
                            name: "Dink",
                            icon: "hand.point.down.fill",
                            mastery: 1.0,
                            isUnlocked: true,
                            color: .green
                        )
                        
                        ShotMasteryBadge(
                            name: "Drive",
                            icon: "arrow.right.circle.fill",
                            mastery: 1.0,
                            isUnlocked: true,
                            color: .blue
                        )
                        
                        ShotMasteryBadge(
                            name: "Lob",
                            icon: "arrow.up.circle.fill",
                            mastery: 1.0,
                            isUnlocked: true,
                            color: .orange
                        )
                        
                        ShotMasteryBadge(
                            name: "Drop",
                            icon: "arrow.down.circle.fill",
                            mastery: 0.8,
                            isUnlocked: true,
                            color: .purple
                        )
                        
                        ShotMasteryBadge(
                            name: "Volley",
                            icon: "bolt.circle.fill",
                            mastery: 0.6,
                            isUnlocked: true,
                            color: .yellow
                        )
                        
                        ShotMasteryBadge(
                            name: "Serve",
                            icon: "figure.tennis",
                            mastery: 0.9,
                            isUnlocked: true,
                            color: .red
                        )
                        
                        ShotMasteryBadge(
                            name: "Smash",
                            icon: "bolt.fill",
                            mastery: 0.4,
                            isUnlocked: true,
                            color: .pink
                        )
                        
                        ShotMasteryBadge(
                            name: "Slice",
                            icon: "rotate.3d",
                            mastery: 0.7,
                            isUnlocked: true,
                            color: .cyan
                        )
                        
                        // Locked shots
                        ShotMasteryBadge(
                            name: "Erne",
                            icon: "figure.badminton",
                            mastery: 0.0,
                            isUnlocked: false,
                            color: .gray
                        )
                        
                        ShotMasteryBadge(
                            name: "ATP",
                            icon: "arrow.triangle.2.circlepath",
                            mastery: 0.0,
                            isUnlocked: false,
                            color: .gray
                        )
                        
                        ShotMasteryBadge(
                            name: "Tweener",
                            icon: "figure.gymnastics",
                            mastery: 0.0,
                            isUnlocked: false,
                            color: .gray
                        )
                        
                        ShotMasteryBadge(
                            name: "Spin Serve",
                            icon: "tornado",
                            mastery: 0.0,
                            isUnlocked: false,
                            color: .gray
                        )
                    }
                    
                    // Overall progress
                    VStack(spacing: 8) {
                        HStack {
                            Text("Overall Shot Mastery")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                            Text("67%")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.purple)
                        }
                        
                        ProgressView(value: 0.67)
                            .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemBackground))
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Bio Section
    
    private var bioSection: some View {
        VStack(spacing: 12) {
            if let user = appState.currentUser {
                if !user.bio.isEmpty || !user.playStyle.isEmpty || !user.favoriteShot.isEmpty {
                    HStack {
                        Text("About")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                    }
                    
                    VStack(spacing: 12) {
                        if !user.bio.isEmpty {
                            Text(user.bio)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if !user.playStyle.isEmpty || !user.favoriteShot.isEmpty {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                if !user.playStyle.isEmpty {
                                    InfoChip(
                                        title: "Play Style",
                                        value: user.playStyle,
                                        icon: "figure.table.tennis",
                                        color: .purple
                                    )
                                }
                                
                                if !user.favoriteShot.isEmpty {
                                    InfoChip(
                                        title: "Favorite Shot",
                                        value: user.favoriteShot,
                                        icon: "hand.raised.fill",
                                        color: .green
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Achievements & Badges Section
    
    private var achievementsBadgesSection: some View {
        VStack(spacing: 16) {
            if let user = appState.currentUser {
                HStack {
                    Text("Achievements")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button("View All") {
                        showingAllAchievements = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                // Achievement Progress
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(user.achievements.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        Text("Earned")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(AchievementManager.getAllPossibleAchievements().count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Total")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        let percentage = Int(Double(user.achievements.count) / Double(AchievementManager.getAllPossibleAchievements().count) * 100)
                        Text("\(percentage)%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Complete")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                
                // Recent Achievements
                if !user.achievements.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(user.achievements.prefix(6))) { achievement in
                                AchievementBadge(achievement: achievement)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.orange.opacity(0.6))
                        
                        Text("No achievements yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Start playing to unlock your first badge!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Recent Activity Section
    
    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            if let user = appState.currentUser {
                    HStack {
                    Text("Recent Activity")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                        Spacer()
                    
                    if !userMatches.isEmpty {
                        Button("View All") {
                            showingMatchHistory = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                
                if !userMatches.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(Array(userMatches.prefix(3))) { match in
                            ProfileRecentMatchCard(match: match, currentUser: user)
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "gamecontroller")
                            .font(.system(size: 40))
                            .foregroundColor(.blue.opacity(0.6))
                        
                        Text("No matches yet")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Your recent matches will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Detailed Stats Section
    
    private var detailedStatsSection: some View {
        VStack(spacing: 16) {
            if let user = appState.currentUser {
                HStack {
                    Text("Detailed Statistics")
                        .font(.headline)
                        .fontWeight(.bold)
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    // Monthly performance chart
                    if !user.monthlyStats.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Monthly Performance")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(getMonthlyPerformanceData(), id: \.month) { data in
                                        MonthlyPerformanceCard(data: data)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                    }
                    
                    // Detailed metrics grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        DetailedStatCard(
                            title: "Avg Points/Match",
                            value: String(format: "%.1f", user.averagePointsPerMatch),
                            icon: "target",
                            color: .purple
                        )
                        
                        DetailedStatCard(
                            title: "Total Points",
                            value: "\(user.totalPointsScored)",
                            icon: "plus.circle.fill",
                            color: .green
                        )
                        
                        DetailedStatCard(
                            title: "Points Conceded",
                            value: "\(user.totalPointsConceded)",
                            icon: "minus.circle.fill",
                            color: .red
                        )
                        
                        DetailedStatCard(
                            title: "Member Since",
                            value: formatJoinDate(user.joinDate),
                            icon: "calendar.badge.clock",
                            color: .orange
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Functions
    
    private func calculateLevel(from xp: Int) -> Int {
        return max(1, Int(sqrt(Double(xp) / 100)))
    }
    
    private func calculateXPForLevel(_ level: Int) -> Int {
        return level * level * 100
    }
    
    private func skillLevelColor(_ skillLevel: String) -> Color {
        switch skillLevel.lowercased() {
        case "beginner": return .green
        case "intermediate": return .orange
        case "advanced": return .red
        case "expert": return .purple
        default: return .blue
        }
    }
    
    private func eloColor(for elo: Int) -> Color {
        switch elo {
        case 0...1200: return .gray
        case 1201...1600: return .blue
        case 1601...2000: return .purple
        case 2001...2400: return .orange
        default: return .red
        }
    }
    
    private func winRateColor(for winRate: Double) -> Color {
        switch winRate {
        case 0.0..<0.4: return .red
        case 0.4..<0.6: return .orange
        case 0.6..<0.8: return .blue
        default: return .green
        }
    }
    
    private func getMonthlyPerformanceData() -> [MonthlyPerformanceData] {
        guard let user = appState.currentUser else { return [] }
        
        return user.monthlyStats.compactMap { (key, stats) in
            MonthlyPerformanceData(
                month: formatMonthKey(key),
                matches: stats.matches,
                winRate: stats.winRate,
                eloChange: stats.eloChange
            )
        }.sorted { $0.month > $1.month }
    }
    
    private func formatMonthKey(_ key: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        if let date = formatter.date(from: key) {
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
        return key
    }
    
    private func formatJoinDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct QuickStatBadge: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let gradient: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if gradient {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [color, color.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                } else {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)
                }
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(gradient ? .white : color)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

struct InfoChip: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [achievement.type.color, achievement.type.color.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: achievement.type.color.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }
            
            Text(achievement.title)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 70)
        }
    }
}

struct ProfileRecentMatchCard: View {
    let match: Match
    let currentUser: User
    
    var body: some View {
        HStack(spacing: 12) {
            // Result indicator
            Circle()
                .fill(match.result(for: currentUser) == "Win" ? Color.green : Color.red)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(match.opponent(for: currentUser))
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(match.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(match.score)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(match.eloChange)
                    .font(.caption2)
                    .foregroundColor(match.eloChange.hasPrefix("+") ? .green : .red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

struct MonthlyPerformanceCard: View {
    let data: MonthlyPerformanceData
    
    var body: some View {
        VStack(spacing: 6) {
            Text(data.month)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Text("\(data.matches)")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("matches")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.vertical, 2)
            
            Text(String(format: "%.0f%%", data.winRate * 100))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(data.winRate > 0.5 ? .green : .red)
            
            Text("\(data.eloChange > 0 ? "+" : "")\(data.eloChange) ELO")
                .font(.caption2)
                .foregroundColor(data.eloChange > 0 ? .green : .red)
        }
        .padding(8)
        .frame(width: 80)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

struct DetailedStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct DailyChallengeCard: View {
    let title: String
    let description: String
    let progress: Double
    let reward: String
    let isCompleted: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.orange.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.orange)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(reward)
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if !isCompleted {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        .scaleEffect(x: 1, y: 0.8, anchor: .center)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCompleted ? Color.green.opacity(0.1) : Color(.tertiarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCompleted ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

struct TrainingPartnerCard: View {
    let name: String
    let skillLevel: String
    let matchesPlayed: Int
    let winRate: Double
    let lastPlayed: String
    let partnershipDays: Int
    let profileImage: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Partner avatar with heart indicator
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.pink, Color.purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                
                if let profileImage = profileImage {
                    AsyncImage(url: URL(string: profileImage)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                
                // Heart indicator
                Circle()
                    .fill(Color.red)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundColor(.white)
                    )
                    .offset(x: 18, y: -18)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(partnershipDays) days")
                        .font(.caption2)
                        .foregroundColor(.pink)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.pink.opacity(0.2)))
                }
                
                Text(skillLevel)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(matchesPlayed)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("matches")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.0f%%", winRate * 100))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(winRate > 0.5 ? .green : .orange)
                        Text("win rate")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("Last: \(lastPlayed)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct StreakCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: isActive ? [color, color.opacity(0.6)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(isActive ? color.opacity(0.5) : Color.clear, lineWidth: 2)
                            .scaleEffect(1.2)
                    )
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isActive ? .white : .gray)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(isActive ? color : .gray)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? color.opacity(0.1) : Color(.tertiarySystemBackground))
        )
    }
}

struct ShotMasteryBadge: View {
    let name: String
    let icon: String
    let mastery: Double
    let isUnlocked: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? 
                        LinearGradient(
                            gradient: Gradient(colors: [color, color.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(isUnlocked ? color.opacity(0.4) : Color.clear, lineWidth: 2)
                            .scaleEffect(1.1)
                    )
                
                if isUnlocked {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Mastery indicator
                if isUnlocked && mastery == 1.0 {
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.white)
                        )
                        .offset(x: 15, y: -15)
                }
            }
            
            Text(name)
                .font(.caption2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(isUnlocked ? .primary : .gray)
            
            if isUnlocked && mastery < 1.0 {
                ProgressView(value: mastery)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .scaleEffect(x: 1, y: 0.5, anchor: .center)
                    .frame(width: 40)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isUnlocked ? color.opacity(0.1) : Color(.systemGray6))
        )
    }
}

// MARK: - Data Models

struct MonthlyPerformanceData {
    let month: String
    let matches: Int
    let winRate: Double
    let eloChange: Int
}

// MARK: - Preview

#Preview {
    @MainActor
    struct PreviewHelper {
        static func createSampleUserWithData() -> User {
            let user = User(email: "john.doe@example.com", password: "password", elo: 1650, xp: 2400, totalMatches: 32, wins: 21, losses: 11, winStreak: 4)
            
            // Fill in profile details
            user.displayName = "John Doe"
            user.bio = "Passionate pickleball player who loves strategic gameplay and meeting new opponents! Always looking to improve my game and have fun on the court."
            user.location = "San Francisco, CA"
            user.skillLevel = SkillLevel.advanced.rawValue
            user.playStyle = PlayStyle.balanced.rawValue
            user.favoriteShot = "Dink Shot"
            
            // Set availability
            user.availability = [
                "Monday": true,
                "Tuesday": false,
                "Wednesday": true,
                "Thursday": true,
                "Friday": false,
                "Saturday": true,
                "Sunday": true
            ]
            
            // Add comprehensive stats
            user.totalPointsScored = 387
            user.totalPointsConceded = 295
            user.longestWinStreak = 8
            
            // Note: achievements is now a computed property that returns empty data
            // Sample achievements functionality removed for SwiftData compatibility
            
            // Note: monthlyStats is now a computed property that returns empty data
            // Sample monthly stats functionality removed for SwiftData compatibility
            
            return user
        }
    }
    
    let sampleAppState = AppState()
    sampleAppState.currentUser = PreviewHelper.createSampleUserWithData()
    
    return ProfileView()
        .environment(sampleAppState)
} 