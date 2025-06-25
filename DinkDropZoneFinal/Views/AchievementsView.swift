import SwiftUI
import SwiftData

struct AchievementsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var selectedCategory: AchievementCategory = .gameplay
    @State private var selectedTier: AchievementTier? = nil
    @State private var showingFilters = false
    @State private var searchText = ""
    @State private var animateOnAppear = false
    @State private var showSecretHint = false
    
    var filteredAchievements: [Trophy] {
        var achievements = appState.achievementTracker?.getAchievements(for: selectedCategory) ?? []
        
        if let tier = selectedTier {
            achievements = achievements.filter { $0.tier == tier }
        }
        
        if !searchText.isEmpty {
            achievements = achievements.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return achievements
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        selectedCategory.color.opacity(0.1),
                        selectedCategory.color.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with statistics
                    achievementHeader
                    
                    // Category selector
                    categorySelector
                    
                    // Filter and search bar
                    filterBar
                    
                    // Achievement list
                    achievementGrid
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(selectedCategory.color)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingFilters.toggle() }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(selectedCategory.color)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                AchievementFiltersView(selectedTier: $selectedTier)
                    .presentationDetents([.medium])
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8)) {
                animateOnAppear = true
            }
            updateAchievementProgress()
        }
    }
    
    // MARK: - Header
    
    private var achievementHeader: some View {
        let stats = appState.achievementTracker?.getStatistics() ?? (unlocked: 0, total: 0, percentage: 0.0)
        
        return VStack(spacing: 12) {
            // Overall progress ring
            ZStack {
                DSProgressRing(
                    progress: stats.percentage,
                    lineWidth: 8,
                    size: 120,
                    color: selectedCategory.color
                )
                
                VStack(spacing: 4) {
                    Text("\(stats.unlocked)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(selectedCategory.color)
                    
                    Text("of \(stats.total)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .scaleEffect(animateOnAppear ? 1 : 0.8)
            .opacity(animateOnAppear ? 1 : 0)
            .animation(.spring(duration: 0.8).delay(0.2), value: animateOnAppear)
            
            // Tier breakdown
            tierBreakdown
                .opacity(animateOnAppear ? 1 : 0)
                .offset(y: animateOnAppear ? 0 : 20)
                .animation(.spring(duration: 0.8).delay(0.4), value: animateOnAppear)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(selectedCategory.color.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var tierBreakdown: some View {
        HStack(spacing: 12) {
            ForEach(AchievementTier.allCases, id: \.self) { tier in
                let stats = appState.achievementTracker?.getStatistics(for: tier) ?? (unlocked: 0, total: 0)
                
                VStack(spacing: 4) {
                    Image(systemName: tier.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(tier.color)
                    
                    Text("\(stats.unlocked)/\(stats.total)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 40)
                
                if tier != AchievementTier.allCases.last {
                    Divider()
                        .frame(height: 30)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.05))
        )
    }
    
    // MARK: - Category Selector
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(duration: 0.6)) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - Filter Bar
    
    private var filterBar: some View {
        HStack {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search achievements...", text: $searchText)
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.08))
            )
            
            // Secret achievement hint
            if selectedCategory == .secret {
                Button(action: { showSecretHint.toggle() }) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(selectedCategory.color)
                        .font(.title2)
                }
                .alert("Secret Achievements", isPresented: $showSecretHint) {
                    Button("OK") { }
                } message: {
                    Text("Secret achievements are unlocked through special actions and hidden conditions. Keep playing to discover them!")
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Achievement Grid
    
    private var achievementGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(Array(filteredAchievements.enumerated()), id: \.element.id) { index, achievement in
                    AdvancedAchievementCard(achievement: achievement)
                        .opacity(animateOnAppear ? 1 : 0)
                        .offset(y: animateOnAppear ? 0 : 30)
                        .animation(
                            .spring(duration: 0.8)
                            .delay(0.6 + Double(index) * 0.1),
                            value: animateOnAppear
                        )
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
        .refreshable {
            updateAchievementProgress()
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateAchievementProgress() {
        guard let user = appState.currentUser else { return }
        
        appState.achievementTracker?.updateProgress(
            matchesPlayed: user.totalMatches,
            matchesWon: user.wins,
            winStreak: user.winStreak,
            perfectGames: 0, // This would need to be tracked
            friendsAdded: 0, // This would need to be tracked
            pointsScored: user.totalPointsScored,
            level: appState.userLevel,
            eloRating: user.elo
        )
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: AchievementCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .semibold))
                
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : category.color)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? category.color : category.color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(category.color.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Advanced Achievement Card

struct AdvancedAchievementCard: View {
    let achievement: Trophy
    @State private var showingDetails = false
    
    var body: some View {
        Button(action: { showingDetails = true }) {
            VStack(spacing: 12) {
                // Header with icon and tier
                HStack {
                    ZStack {
                        Circle()
                            .fill(achievement.tier.color.opacity(0.2))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: achievement.icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(achievement.isUnlocked ? achievement.tier.color : .secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Image(systemName: achievement.tier.icon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(achievement.tier.color)
                        
                        Text(achievement.tier.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Achievement info
                VStack(alignment: .leading, spacing: 6) {
                    Text(achievement.isSecret && !achievement.isUnlocked ? "???" : achievement.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(achievement.isSecret && achievement.currentProgress < 0.1 ? 
                         "A mysterious achievement awaits..." : achievement.description)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                // Progress or completion
                if achievement.isUnlocked {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 12))
                        
                        Text("Completed")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text("+\(achievement.xpReward) XP")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.orange)
                    }
                } else {
                    VStack(spacing: 6) {
                        HStack {
                            Text(achievement.getProgressText())
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("+\(achievement.xpReward) XP")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.orange)
                        }
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.primary.opacity(0.1))
                                    .frame(height: 4)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(achievement.category.color)
                                    .frame(
                                        width: geometry.size.width * CGFloat(achievement.currentProgress),
                                        height: 4
                                    )
                            }
                        }
                        .frame(height: 4)
                    }
                }
            }
            .padding(16)
            .frame(height: 180)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                achievement.isUnlocked ? 
                                achievement.tier.color.opacity(0.5) : 
                                Color.primary.opacity(0.1),
                                lineWidth: achievement.isUnlocked ? 2 : 1
                            )
                    )
            )
            .grayscale(achievement.isUnlocked ? 0 : 0.3)
            .scaleEffect(achievement.isUnlocked ? 1 : 0.95)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetails) {
            AchievementDetailView(achievement: achievement)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Achievement Detail View

struct AchievementDetailView: View {
    let achievement: Trophy
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero section
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(achievement.tier.color.opacity(0.2))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: achievement.icon)
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(achievement.tier.color)
                        }
                        
                        VStack(spacing: 8) {
                            Text(achievement.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                            
                            Text(achievement.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Tier and reward info
                        HStack(spacing: 20) {
                            VStack(spacing: 4) {
                                Text("Tier")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: achievement.tier.icon)
                                        .font(.system(size: 12))
                                        .foregroundColor(achievement.tier.color)
                                    
                                    Text(achievement.tier.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(achievement.tier.color)
                                }
                            }
                            
                            VStack(spacing: 4) {
                                Text("Reward")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("+\(achievement.xpReward) XP")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        )
                    }
                    
                    // Conditions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Requirements")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        ForEach(Array(achievement.conditions.enumerated()), id: \.offset) { index, condition in
                            ConditionRow(
                                condition: condition,
                                currentProgress: achievement.progress[condition.type.rawValue] ?? 0,
                                isCompleted: (achievement.progress[condition.type.rawValue] ?? 0) >= condition.value
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Status
                    if achievement.isUnlocked {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                
                                Text("Achievement Unlocked!")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            
                            if let unlockedAt = achievement.unlockedAt {
                                Text("Unlocked on \(unlockedAt, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.green.opacity(0.1))
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Condition Row

struct ConditionRow: View {
    let condition: AchievementCondition
    let currentProgress: Int
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .secondary)
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(conditionTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(currentProgress) / \(condition.value)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Progress indicator
            if !isCompleted {
                Text("\(Int((Double(currentProgress) / Double(condition.value)) * 100))%")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var conditionTitle: String {
        switch condition.type {
        case .matchesPlayed: return "Play matches"
        case .matchesWon: return "Win matches"
        case .winStreak: return "Win streak"
        case .perfectGames: return "Perfect games"
        case .friendsAdded: return "Add friends"
        case .pointsScored: return "Score points"
        case .levelReached: return "Reach level"
        case .eloRating: return "Reach ELO rating"
        default: return condition.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }
}

// MARK: - Achievement Filters View

struct AchievementFiltersView: View {
    @Binding var selectedTier: AchievementTier?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Filter by Tier")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        Button(action: { selectedTier = nil }) {
                            FilterTierButton(
                                tier: nil,
                                isSelected: selectedTier == nil
                            )
                        }
                        
                        ForEach(AchievementTier.allCases, id: \.self) { tier in
                            Button(action: { selectedTier = tier }) {
                                FilterTierButton(
                                    tier: tier,
                                    isSelected: selectedTier == tier
                                )
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FilterTierButton: View {
    let tier: AchievementTier?
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            if let tier = tier {
                Image(systemName: tier.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : tier.color)
                
                Text(tier.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : tier.color)
            } else {
                Text("All Tiers")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? (tier?.color ?? .blue) : (tier?.color.opacity(0.1) ?? Color.primary.opacity(0.1)))
        )
    }
}

// MARK: - Preview

#Preview {
    AchievementsView()
        .environmentObject(AppState())
} 