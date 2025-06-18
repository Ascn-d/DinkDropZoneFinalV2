import SwiftUI
import SwiftData

struct MissionsView: View {
    @Environment(AppState.self) private var appState
    @Environment(XPManager.self) private var xpManager
    @State private var selectedTab = 0
    @State private var showTrophyUnlock = false
    @State private var unlockedTrophy: Trophy?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom Tab Picker
                HStack(spacing: 0) {
                    TabButton(
                        title: "Missions",
                        icon: "target",
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabButton(
                        title: "Trophies",
                        icon: "trophy.fill",
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Content
                TabView(selection: $selectedTab) {
                    // Missions Tab
                    MissionsTabView()
                        .tag(0)
                    
                    // Trophies Tab
                    TrophiesTabView()
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
        .onReceive(NotificationCenter.default.publisher(for: .trophyUnlocked)) { notification in
            if let trophy = notification.object as? Trophy {
                unlockedTrophy = trophy
                showTrophyUnlock = true
            }
        }
        .fullScreenCover(isPresented: $showTrophyUnlock) {
            if let trophy = unlockedTrophy {
                TrophyUnlockView(trophy: trophy, isPresented: $showTrophyUnlock)
            }
        }
    }
}

// MARK: - Tab Button

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Missions Tab View

struct MissionsTabView: View {
    @Environment(XPManager.self) private var xpManager
    
    var activeMissions: [Mission] {
        xpManager.getMissionsForDisplay()
    }
    
    var dailyMissions: [Mission] {
        activeMissions.filter { $0.type.isDaily }
    }
    
    var weeklyMissions: [Mission] {
        activeMissions.filter { $0.type.isWeekly }
    }
    
    var achievementMissions: [Mission] {
        activeMissions.filter { $0.type.isAchievement }
    }
    
    var completedToday: Int {
        xpManager.completedMissions.filter { mission in
            guard let completedAt = mission.completedAt else { return false }
            return Calendar.current.isDateInToday(completedAt)
        }.count
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Progress Summary
                MissionProgressSummary(
                    completedCount: completedToday,
                    totalCount: activeMissions.count,
                    todayXP: xpManager.dailyStats.xpEarned
                )
                .padding(.horizontal)
                
                // XP and Level Info
                XPProgressCard()
                    .padding(.horizontal)
                
                // Daily Missions
                if !dailyMissions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            title: "Daily Missions",
                            subtitle: "Reset at midnight",
                            icon: "sun.max.fill",
                            color: .blue
                        )
                        
                        LazyVStack(spacing: 12) {
                            ForEach(dailyMissions) { mission in
                                MissionCard(mission: mission)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Weekly Missions
                if !weeklyMissions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            title: "Weekly Missions",
                            subtitle: "Reset on Monday",
                            icon: "calendar.badge.clock",
                            color: .purple
                        )
                        
                        LazyVStack(spacing: 12) {
                            ForEach(weeklyMissions) { mission in
                                MissionCard(mission: mission)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Achievement Missions
                if !achievementMissions.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            title: "Achievement Missions",
                            subtitle: "Long-term goals",
                            icon: "star.circle.fill",
                            color: .orange
                        )
                        
                        LazyVStack(spacing: 12) {
                            ForEach(achievementMissions) { mission in
                                MissionCard(mission: mission)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Empty State
                if activeMissions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("All Missions Complete!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Great job! New missions will be available soon.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Check Back Later") {
                            // Refresh missions
                            xpManager.generateDailyMissions()
                        }
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 40)
                }
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Trophies Tab View

struct TrophiesTabView: View {
    @Environment(XPManager.self) private var xpManager
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Trophy Collection
                TrophyCollectionView(unlockedTrophies: xpManager.unlockedTrophies)
                    .padding(.horizontal)
                
                // Recent Trophies
                if !xpManager.getRecentTrophies().isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(
                            title: "Recent Unlocks",
                            subtitle: "Last 7 days",
                            icon: "sparkles",
                            color: .orange
                        )
                        
                        LazyVStack(spacing: 8) {
                            ForEach(xpManager.getRecentTrophies()) { trophy in
                                CompactTrophyCard(trophy: trophy)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Trophy Categories
                TrophyCategoriesView()
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - XP Progress Card

struct XPProgressCard: View {
    @Environment(XPManager.self) private var xpManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(xpManager.currentLevel)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(xpManager.currentXP) / \(xpManager.calculateXPForLevel(xpManager.currentLevel + 1)) XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(xpManager.xpToNextLevel) XP")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    
                    Text("to next level")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 16)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.8), .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * xpManager.getProgressToNextLevel(),
                            height: 16
                        )
                        .animation(.easeInOut(duration: 1.0), value: xpManager.getProgressToNextLevel())
                }
            }
            .frame(height: 16)
            
            // Stats
            HStack {
                StatItem(title: "Total XP", value: "\(xpManager.totalXPEarned)")
                
                Spacer()
                
                StatItem(title: "Today", value: "\(xpManager.dailyStats.xpEarned) XP")
                
                Spacer()
                
                StatItem(title: "Progress", value: "\(Int(xpManager.getProgressToNextLevel() * 100))%")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Stat Item

struct StatItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Trophy Categories View

struct TrophyCategoriesView: View {
    @Environment(XPManager.self) private var xpManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trophy Categories")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                CategoryCard(
                    title: "Match Trophies",
                    icon: "gamecontroller.fill",
                    color: .blue,
                    count: xpManager.unlockedTrophies.filter { TrophyType.matchTrophies.contains($0.type) }.count,
                    total: TrophyType.matchTrophies.count
                )
                
                CategoryCard(
                    title: "Social Trophies",
                    icon: "person.3.fill",
                    color: .green,
                    count: xpManager.unlockedTrophies.filter { TrophyType.socialTrophies.contains($0.type) }.count,
                    total: TrophyType.socialTrophies.count
                )
                
                CategoryCard(
                    title: "Level Trophies",
                    icon: "star.fill",
                    color: .orange,
                    count: xpManager.unlockedTrophies.filter { TrophyType.levelTrophies.contains($0.type) }.count,
                    total: TrophyType.levelTrophies.count
                )
                
                CategoryCard(
                    title: "Special Trophies",
                    icon: "sparkles",
                    color: .purple,
                    count: xpManager.unlockedTrophies.filter { TrophyType.specialTrophies.contains($0.type) }.count,
                    total: TrophyType.specialTrophies.count
                )
            }
        }
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    let count: Int
    let total: Int
    
    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Title
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Progress
            VStack(spacing: 6) {
                Text("\(count)/\(total)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(
                                width: geometry.size.width * progress,
                                height: 6
                            )
                            .animation(.easeInOut(duration: 1.0), value: progress)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Preview

#Preview {
    MissionsView()
        .environment(AppState())
        .environment(XPManager(modelContext: ModelContext(try! ModelContainer(for: User.self))))
}