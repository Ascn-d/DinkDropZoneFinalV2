import SwiftUI
import Observation

struct AchievementsView: View {
    @Environment(AppState.self) private var appState

    private var allAchievements: [Achievement] {
        AchievementManager.getAllPossibleAchievements()
    }

    private var unlockedIds: Set<String> {
        guard let user = appState.currentUser else { return [] }
        return Set(user.achievements.map { $0.title })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 16)], spacing: 16) {
                    ForEach(allAchievements, id: \.title) { achievement in
                        AchievementBadgeView(achievement: achievement, unlocked: unlockedIds.contains(achievement.title))
                    }
                }
                .padding()
            }
            .navigationTitle("Achievements")
        }
    }
}

private struct AchievementBadgeView: View {
    let achievement: Achievement
    let unlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.largeTitle)
                .foregroundColor(unlocked ? .yellow : .gray)
                .opacity(unlocked ? 1 : 0.3)
            Text(achievement.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(unlocked ? .primary : .secondary)
            if unlocked {
                Text("Earned")
                    .font(.caption2)
                    .foregroundColor(.green)
            } else {
                Text("Locked")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 120)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    let state = AppState()
    let user = User(email: "test", password: "", elo: 1000, xp: 0, totalMatches: 0, wins: 0, losses: 0, winStreak: 0)
    // Note: achievements are now computed properties, so we can't assign to them
    state.currentUser = user
    return AchievementsView().environment(state)
} 