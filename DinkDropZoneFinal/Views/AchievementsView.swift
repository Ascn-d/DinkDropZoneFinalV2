import SwiftUI
import Observation

struct AchievementsView: View {
    @Environment(AppState.self) private var appState
    @State private var achievements: [Achievement] = []
    @State private var selectedCategory: AchievementCategory = .all
    
    enum AchievementCategory: String, CaseIterable {
        case all = "All"
        case skill = "Skill"
        case milestone = "Milestone"
        case special = "Special"
        case streak = "Streak"
        case score = "Score"
    }
    
    var filteredAchievements: [Achievement] {
        if selectedCategory == .all {
            return achievements
        } else {
            return achievements.filter { $0.type.rawValue == selectedCategory.rawValue }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                title: category.rawValue,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Achievements grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementBadgeView(achievement: achievement)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievements")
            .onAppear {
                loadAchievements()
            }
        }
    }
    
    private func loadAchievements() {
        achievements = AchievementManager.getAllPossibleAchievements()
    }
}

private struct AchievementBadgeView: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.largeTitle)
                .foregroundColor(.yellow)
            
            Text(achievement.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            Text("Earned")
                .font(.caption2)
                .foregroundColor(.green)
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

private struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.tertiarySystemBackground))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    let state = AppState()
    let user = User(email: "test", password: "", elo: 1000, xp: 0, totalMatches: 0, wins: 0, losses: 0, winStreak: 0)
    // Note: achievements are now computed properties, so we can't assign to them
    state.currentUser = user
    return AchievementsView().environment(state)
} 