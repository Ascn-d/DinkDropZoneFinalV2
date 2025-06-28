import SwiftUI
import SwiftData
import PhotosUI
import OSLog
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query private var allMatches: [Match]
    @State private var isEditingProfile = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showingMatchHistory = false
    @State private var showingAllAchievements = false
    @State private var isRefreshing = false
    @State private var isUploadingImage = false
    @State private var uploadError: String? = nil
    @State private var showingUploadError = false
    @State private var animateContent = false
    
    // Helper to get matches for current user
    private var userMatches: [Match] {
        guard let currentUser = appState.currentUser else { return [] }
        return allMatches.filter { match in
            match.player1.id == currentUser.id || match.player2.id == currentUser.id
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Profile Header - Properly positioned to avoid sidebar and navigation bar
                    profileHeaderWithSafeArea(safeAreaTop: safeAreaTop)
                    
                    // Main content with proper spacing and sidebar consideration
                    VStack(spacing: DS.Layout.sectionSpacing) {
                        // Level and XP Section
                        levelProgressSection
                        
                        // Quick Stats Section
                        VStack(spacing: 16) {
                            DSPremiumSectionHeader(
                                title: "Quick Stats",
                                subtitle: "Your performance at a glance",
                                icon: "chart.bar.fill"
                            )
                            
                            if let user = appState.currentUser {
                                quickStatsGrid(user: user)
                            }
                        }
                        
                        // Daily Challenges Section
                        VStack(spacing: 16) {
                            DSPremiumSectionHeader(
                                title: "Daily Challenges",
                                subtitle: "Complete to earn XP",
                                icon: "target"
                            )
                            
                            dailyChallengesContent
                        }
                        
                        // Achievements Section
                        VStack(spacing: 16) {
                            DSPremiumSectionHeader(
                                title: "Achievements",
                                subtitle: "Your trophies and milestones",
                                icon: "trophy.fill",
                                action: { showingAllAchievements = true }
                            )
                            
                            achievementsContent
                        }
                        
                        // Activity Section
                        VStack(spacing: 16) {
                            DSPremiumSectionHeader(
                                title: "My Activity",
                                subtitle: "View your tournaments and matches",
                                icon: "figure.pickleball"
                            )
                            
                            VStack(spacing: 12) {
                                NavigationLink(destination: MyTournamentsView()) {
                                    ProfileNavigationCard(
                                        title: "My Tournaments",
                                        subtitle: "View your joined and created tournaments",
                                        icon: "trophy.fill",
                                        color: .orange
                                    )
                                }
                                
                                Button(action: { showingMatchHistory = true }) {
                                    ProfileNavigationCard(
                                        title: "Match History",
                                        subtitle: "Review your past match results",
                                        icon: "clock.arrow.circlepath",
                                        color: .blue
                                    )
                                }
                                .disabled(userMatches.isEmpty)
                            }
                        }
                        
                        // Detailed Stats Section
                        VStack(spacing: 16) {
                            DSPremiumSectionHeader(
                                title: "Detailed Statistics",
                                subtitle: "In-depth performance analysis",
                                icon: "chart.line.uptrend.xyaxis"
                            )
                            
                            detailedStatsContent
                        }
                    }
                    .padding(.horizontal, DS.Layout.horizontalPadding)
                    .padding(.top, DS.Layout.sectionSpacing)
                    .padding(.bottom, max(safeAreaBottom, 20) + 60)
                    .opacity(animateContent ? 1 : 0)
                    .offset(y: animateContent ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(0.3), value: animateContent)
                }
            }
        }
        .background(DS.Color.backgroundGradient)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animateContent = true
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
        .alert("Upload Error", isPresented: $showingUploadError) {
            Button("OK") { uploadError = nil }
        } message: {
            Text(uploadError ?? "Unknown error occurred")
        }
    }
    
    // MARK: - Safe Area Aware Profile Header
    
    private func profileHeaderWithSafeArea(safeAreaTop: CGFloat) -> some View {
        ZStack {
            // Enhanced gradient background
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            DS.Color.accent.opacity(0.9),
                            DS.Color.premium.opacity(0.7),
                            DS.Color.accent.opacity(0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Subtle pattern overlay
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 300, height: 300)
                        .offset(x: -100, y: -50)
                        .blur(radius: 20)
                )
            
            VStack(spacing: 0) {
                // Dynamic Island/Notch safe area spacer
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: max(safeAreaTop + 10, 54)) // Extra 10pt buffer, minimum 54pt
                
                // Navigation bar space for sidebar navigation
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 50) // Navigation title space
                
                // Content area with proper padding
                VStack(spacing: 20) {
                    if let user = appState.currentUser {
                        // Profile photo and edit controls
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Profile")
                                    .font(DS.Font.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(user.displayName.isEmpty ? user.email.components(separatedBy: "@").first ?? "Player" : user.displayName)
                                    .font(DS.Font.body)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            // Profile image with controls
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 3)
                                    .frame(width: 70, height: 70)
                                
                                PhotosPicker(selection: $selectedItem, matching: .images) {
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
                                        .frame(width: 64, height: 64)
                                        .clipShape(Circle())
                                    } else {
                                        ZStack {
                                            Circle()
                                                .fill(Color.white.opacity(0.2))
                                                .frame(width: 64, height: 64)
                                            
                                            Image(systemName: "camera.fill")
                                                .font(.title3)
                                                .foregroundColor(.white)
                                        }
                                    }
                                }
                                .onChange(of: selectedItem) { _, newItem in
                                    Task {
                                        await MainActor.run {
                                            isUploadingImage = true
                                            uploadError = nil
                                        }
                                        
                                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                                           let uiImage = UIImage(data: data) {
                                            do {
                                                try await appState.updateProfileImage(uiImage)
                                                LoggingService.shared.log("Profile image updated successfully")
                                            } catch {
                                                let errorMessage = error.localizedDescription
                                                LoggingService.shared.logError(error, context: "Profile image update")
                                                
                                                await MainActor.run {
                                                    uploadError = errorMessage
                                                    showingUploadError = true
                                                }
                                            }
                                        } else {
                                            await MainActor.run {
                                                uploadError = "Failed to load selected image"
                                                showingUploadError = true
                                            }
                                        }
                                        
                                        await MainActor.run {
                                            isUploadingImage = false
                                            selectedItem = nil
                                        }
                                    }
                                }
                                .disabled(isUploadingImage)
                                
                                // Level badge
                                Text("\(XPManager.calculateLevel(from: user.xp))")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange)
                                    )
                                    .offset(x: 20, y: 20)
                            }
                            
                            // Action buttons
                            VStack(spacing: 8) {
                                Button {
                                    shareProfile()
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .medium))
                                        .frame(width: 28, height: 28)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Circle())
                                }

                                Button {
                                    isEditingProfile = true
                                } label: {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .medium))
                                        .frame(width: 28, height: 28)
                                        .background(Color.white.opacity(0.2))
                                        .clipShape(Circle())
                                }
                            }
                        }
                        .padding(.horizontal, DS.Layout.horizontalPadding)
                        
                        // Quick stats summary
                        HStack(spacing: 24) {
                            quickStatItem("ELO", "\(user.elo)", "star.fill")
                            quickStatItem("Level", "\(XPManager.calculateLevel(from: user.xp))", "bolt.fill")
                            quickStatItem("Wins", "\(user.wins)", "trophy.fill")
                        }
                        .padding(.horizontal, DS.Layout.horizontalPadding)
                    }
                }
                .padding(.bottom, 24) // Bottom padding for content
            }
        }
        .frame(height: calculateHeaderHeight(safeAreaTop: safeAreaTop))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 0,
                bottomLeadingRadius: 24,
                bottomTrailingRadius: 24,
                topTrailingRadius: 0
            )
        )
    }
    
    // Calculate dynamic header height based on device safe area
    private func calculateHeaderHeight(safeAreaTop: CGFloat) -> CGFloat {
        let dynamicIslandSpace = max(safeAreaTop + 10, 54) // Safe area + buffer
        let navigationSpace: CGFloat = 50 // Navigation title space
        let contentSpace: CGFloat = 160 // Content area
        
        return dynamicIslandSpace + navigationSpace + contentSpace
    }
    
    private func quickStatItem(_ title: String, _ value: String, _ icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Text(value)
                .font(DS.Font.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(DS.Font.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Level Progress Section
    
    private var levelProgressSection: some View {
        DSGlassMorphismCard {
            VStack(spacing: 16) {
                if let user = appState.currentUser {
                    let currentLevel = XPManager.calculateLevel(from: user.xp)
                    let nextLevelXP = XPManager.xpRequiredForLevel(currentLevel + 1)
                    let currentLevelXP = XPManager.xpRequiredForLevel(currentLevel)
                    let rawProgress = Double(user.xp - currentLevelXP) / Double(nextLevelXP - currentLevelXP)
                    let progress = min(max(rawProgress, 0), 1)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Level \(currentLevel)")
                                .font(DS.Font.headline)
                                .fontWeight(.bold)
                                .foregroundColor(DS.Color.primary)
                            
                            Text("\(user.xp - currentLevelXP) / \(nextLevelXP - currentLevelXP) XP")
                                .font(DS.Font.caption)
                                .foregroundColor(DS.Color.secondary)
                        }
                        
                        Spacer()
                        
                        Text("Total XP: \(user.xp)")
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                    }
                    
                    DSProgressBar(value: progress, color: .orange)
                        .frame(height: 8)
                }
            }
        }
    }
    
    // MARK: - Quick Stats Grid
    
    private func quickStatsGrid(user: User) -> some View {
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
    
    // MARK: - Daily Challenges Content
    
    private var dailyChallengesContent: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Text("2/3 Complete")
                    .font(DS.Font.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.orange.opacity(0.2)))
            }
            
            VStack(spacing: 8) {
                ProfileDailyChallengeCard(
                    title: "Play a Match",
                    progress: 1.0,
                    reward: "+50 XP",
                    isCompleted: true
                )
                
                ProfileDailyChallengeCard(
                    title: "Win a Game",
                    progress: 1.0,
                    reward: "+75 XP",
                    isCompleted: true
                )
                
                ProfileDailyChallengeCard(
                    title: "Social Player",
                    progress: 0.5,
                    reward: "+100 XP",
                    isCompleted: false
                )
            }
        }
    }
    
    // MARK: - Achievements Content
    
    private var achievementsContent: some View {
        VStack(spacing: 12) {
            // Achievement Progress Overview
            let stats = appState.achievementTracker?.getStatistics() ?? (unlocked: 0, total: 0, percentage: 0.0)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(stats.unlocked)")
                        .font(DS.Font.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Unlocked")
                        .font(DS.Font.caption2)
                        .foregroundColor(DS.Color.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(stats.total)")
                        .font(DS.Font.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Total")
                        .font(DS.Font.caption2)
                        .foregroundColor(DS.Color.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(Int(stats.percentage * 100))%")
                        .font(DS.Font.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Complete")
                        .font(DS.Font.caption2)
                        .foregroundColor(DS.Color.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.orange.opacity(0.1),
                        Color.blue.opacity(0.1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
            
            // Achievement Categories
            VStack(spacing: 12) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    if let tracker = appState.achievementTracker {
                        AdvancedAchievementCategoryRow(
                            category: category,
                            tracker: tracker
                        )
                    }
                }
            }
            
            // Recent Achievements
            let recentAchievements = appState.achievementTracker?.achievements
                .filter { $0.isUnlocked }
                .sorted { ($0.unlockedAt ?? Date.distantPast) > ($1.unlockedAt ?? Date.distantPast) }
                .prefix(6) ?? []
            
            if !recentAchievements.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recently Unlocked")
                        .font(DS.Font.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DS.Color.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(recentAchievements), id: \.id) { achievement in
                                CompactAchievementBadge(achievement: achievement)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
            } else {
                DSEmptyStateView(
                    icon: "trophy.fill",
                    title: "No achievements yet",
                    message: "Start playing to unlock your first achievement!"
                )
            }
        }
    }
    
    // MARK: - Recent Activity Content
    
    private var recentActivityContent: some View {
        VStack(spacing: 8) {
            if let user = appState.currentUser {
                if !userMatches.isEmpty {
                    VStack(spacing: 8) {
                        ForEach(Array(userMatches.prefix(3))) { match in
                            ProfileRecentMatchCard(
                                opponent: match.opponent(for: user),
                                result: match.result(for: user),
                                score: match.score,
                                date: RelativeDateTimeFormatter().localizedString(for: match.date, relativeTo: Date())
                            )
                        }
                    }
                } else {
                    DSEmptyStateView(
                        icon: "gamecontroller",
                        title: "No matches yet",
                        message: "Your recent matches will appear here"
                    )
                }
            }
        }
    }
    
    // MARK: - Detailed Stats Content
    
    private var detailedStatsContent: some View {
        VStack(spacing: 12) {
            if let user = appState.currentUser {
                // Performance Chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Performance Trends")
                        .font(DS.Font.subheadline)
                        .fontWeight(.semibold)
                    
                    PerformanceChartView(data: generatePerformanceData(for: user))
                        .frame(height: 200)
                }
                .padding()
                .background(DS.Color.surfaceAlt)
                .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
            
                // Monthly performance chart
                if !user.monthlyStats.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Monthly Performance")
                            .font(DS.Font.subheadline)
                            .fontWeight(.semibold)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(getMonthlyPerformanceData(), id: \.month) { data in
                                    MonthlyPerformanceCard(
                                        title: data.month,
                                        value: "\(data.matches) matches",
                                        trend: data.eloChange > 0 ? "+\(data.eloChange)" : "\(data.eloChange)",
                                        color: data.eloChange > 0 ? .green : .red
                                    )
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding()
                    .background(DS.Color.surfaceAlt)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
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
    
    // MARK: - Helper Functions
    
    private func refreshUserData() async {
        guard let userId = appState.currentUser?.id.uuidString else { return }
        
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            let refreshedUser = try await FirebaseService.shared.getUser(id: userId)
            await MainActor.run {
                appState.updateUser(refreshedUser)
            }
            LoggingService.shared.log("Profile data refreshed successfully")
        } catch {
            LoggingService.shared.logError(error, context: "Failed to refresh profile data")
        }
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

    private func shareProfile() {
        guard let user = appState.currentUser else { return }
        
        // Create a formatted profile summary string
        let profileSummary = """
        🎮 DinkDropZone Player Profile 🎮
        
        🏅 \(user.displayName)
        Level: \(XPManager.calculateLevel(from: user.xp))
        ELO Rating: \(user.elo)
        
        🏆 Stats:
        • Matches: \(user.totalMatches)
        • Win Rate: \(user.formattedWinRate)
        • Win Streak: \(user.winStreak)
        • Best Streak: \(user.longestWinStreak)
        
        🔥 Join me on DinkDropZone for pickleball matchmaking!
        """
        
        // Items to share
        let activityItems: [Any] = [profileSummary]
        
        // Get the top view controller to present from
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            // Create activity view controller
            let activityViewController = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: nil
            )
            
            // Present the view controller
            if UIDevice.current.userInterfaceIdiom == .pad {
                // For iPad, present as popover
                activityViewController.popoverPresentationController?.sourceView = UIView()
                rootViewController.present(activityViewController, animated: true)
            } else {
                // For iPhone
                rootViewController.present(activityViewController, animated: true)
            }
            
            LoggingService.shared.log("User \(user.displayName) shared their profile")
        }
    }
    
    private func generatePerformanceData(for user: User) -> [(date: Date, elo: Int, winRate: Double)] {
        // For demo/alpha, generate some sample data based on matches and time
        // In a real app, this would come from actual historical data
        var result: [(date: Date, elo: Int, winRate: Double)] = []
        
        // Start with 5 data points over the last month
        let calendar = Calendar.current
        let today = Date()
        let startElo = max(1000, user.elo - 200)
        let eloRange = user.elo - startElo
        let startWinRate = max(0.4, user.winRate - 0.2)
        let winRateRange = user.winRate - startWinRate
        
        for i in (0..<5).reversed() {
            let daysAgo = i * 7
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let progressRatio = Double(5-i) / 5.0
            let elo = startElo + Int(Double(eloRange) * progressRatio)
            let winRate = startWinRate + (winRateRange * progressRatio)
            
            result.append((date: date, elo: elo, winRate: winRate))
        }
        
        return result
    }
}

// MARK: - Supporting Views

// QuickStatBadge moved to DesignSystem.swift to avoid duplicate definitions

struct AchievementCategoryRow: View {
    let category: Achievement.AchievementType
    let achievements: [Achievement]
    let totalPossible: Int
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(category.color)
                    .frame(width: 10, height: 10)
                
                Text(category.rawValue)
                    .font(DS.Font.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(achievements.count)/\(totalPossible)")
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
            }
            
            // Progress bar
            DSProgressBar(value: Double(achievements.count), total: Double(totalPossible), color: category.color)
        }
        .padding(.horizontal, 4)
    }
}

struct RefreshableScrollContent: View {
    @Binding var isRefreshing: Bool
    let action: () async -> Void
    
    var body: some View {
        VStack {
            if isRefreshing {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
                    .padding(.top, 20)
            }
        }
        .frame(maxWidth: .infinity)
        .refreshable {
            await action()
        }
    }
}

struct MonthlyPerformanceData {
    let month: String
    let matches: Int
    let winRate: Double
    let eloChange: Int
}

// MARK: - Advanced Achievement Components

struct AdvancedAchievementCategoryRow: View {
    let category: AchievementCategory
    let tracker: AdvancedAchievementTracker
    
    var body: some View {
        let achievements = tracker.getAchievements(for: category)
        let unlocked = achievements.filter { $0.isUnlocked }.count
        let total = achievements.count
        
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(category.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Text("\(unlocked)/\(total)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primary.opacity(0.1))
                                .frame(height: 4)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(category.color)
                                .frame(
                                    width: geometry.size.width * CGFloat(total > 0 ? Double(unlocked) / Double(total) : 0),
                                    height: 4
                                )
                        }
                    }
                    .frame(height: 4)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.05))
        )
    }
}

struct CompactAchievementBadge: View {
    let achievement: Trophy
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.tier.color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Circle()
                            .stroke(achievement.tier.color, lineWidth: 2)
                    )
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(achievement.tier.color)
            }
            
            VStack(spacing: 2) {
                Text(achievement.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 2) {
                    Image(systemName: achievement.tier.icon)
                        .font(.system(size: 8))
                        .foregroundColor(achievement.tier.color)
                    
                    Text(achievement.tier.rawValue)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(achievement.tier.color)
                }
            }
        }
        .frame(width: 70)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(achievement.tier.color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Navigation Card
struct ProfileNavigationCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DS.Font.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DS.Color.primary)
                
                Text(subtitle)
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(DS.Color.secondary)
        }
        .padding()
        .background(DS.Color.surface)
        .cornerRadius(DS.Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                .stroke(DS.Color.divider.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    let sampleAppState = AppState()
    sampleAppState.currentUser = User.preview
    
    return ProfileView()
        .environmentObject(sampleAppState)
} 