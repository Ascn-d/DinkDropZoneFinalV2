import SwiftUI
import SwiftData

struct MissionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @Environment(XPManager.self) private var xpManager
    @State private var selectedTab = 0
    @State private var showTrophyUnlock = false
    @State private var unlockedTrophy: Trophy?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress Summary
                missionProgressSummary
                
                // Tab selector
                Picker("Mission Type", selection: $selectedTab) {
                    Text("Daily").tag(0)
                    Text("Weekly").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Mission list
                ScrollView {
                    if selectedTab == 0 {
                        dailyMissions
                    } else {
                        weeklyMissions
                    }
                }
            }
            .navigationTitle("Missions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
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
    
    private var missionProgressSummary: some View {
        let missions = xpManager.getMissionsForDisplay()
        let completedCount = missions.filter { $0.isCompleted }.count
        let totalCount = missions.count
        let todayXP = missions.filter { $0.isCompleted }.reduce(0) { $0 + $1.xpReward }
        
        return MissionProgressSummary(
            completedCount: completedCount,
            totalCount: totalCount,
            todayXP: todayXP
        )
        .padding()
        .dsCard()
        .padding(.horizontal)
    }
    
    private var dailyMissions: some View {
        let dailyMissions = xpManager.getMissionsForDisplay().filter { $0.type.isDaily }
        
        return VStack(spacing: 16) {
            if dailyMissions.isEmpty {
                emptyMissionsView(message: "All daily missions completed! Check back tomorrow for new missions.")
            } else {
                ForEach(dailyMissions) { mission in
                    MissionCard(mission: mission)
                        .padding(.horizontal)
                }
            }
            
            Spacer(minLength: 50)
        }
        .padding(.vertical)
    }
    
    private var weeklyMissions: some View {
        let weeklyMissions = xpManager.getMissionsForDisplay().filter { $0.type.isWeekly }
        
        return VStack(spacing: 16) {
            if weeklyMissions.isEmpty {
                emptyMissionsView(message: "All weekly missions completed! Check back next week for new missions.")
            } else {
                ForEach(weeklyMissions) { mission in
                    MissionCard(mission: mission)
                        .padding(.horizontal)
                }
            }
            
            Spacer(minLength: 50)
        }
        .padding(.vertical)
    }
    
    private func emptyMissionsView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("All Completed!")
                .font(DS.Font.title2)
                .fontWeight(.bold)
                .foregroundColor(DS.Color.primary)
            
            Text(message)
                .font(DS.Font.body)
                .foregroundColor(DS.Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
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
                    count: xpManager.unlockedTrophies.filter { $0.category == .gameplay }.count,
                    total: 5 // Approximate count for gameplay achievements
                )
                
                CategoryCard(
                    title: "Social Trophies",
                    icon: "person.3.fill",
                    color: .green,
                    count: xpManager.unlockedTrophies.filter { $0.category == .social }.count,
                    total: 4 // Approximate count for social achievements
                )
                
                CategoryCard(
                    title: "Level Trophies",
                    icon: "star.fill",
                    color: .orange,
                    count: xpManager.unlockedTrophies.filter { $0.category == .progression }.count,
                    total: 6 // Approximate count for progression achievements
                )
                
                CategoryCard(
                    title: "Special Trophies",
                    icon: "sparkles",
                    color: .purple,
                    count: xpManager.unlockedTrophies.filter { $0.category == .secret }.count,
                    total: 3 // Approximate count for secret achievements
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
        .environmentObject(AppState())
        .environment(XPManager(modelContext: ModelContext(try! ModelContainer(for: User.self))))
}