import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Query(sort: \User.elo, order: .reverse) private var users: [User]
    @Environment(AppState.self) private var appState
    @State private var selectedCategory: LeaderboardCategory = .global
    @State private var selectedTimeframe: TimeFrame = .season
    @State private var showingLeagueInfo = false
    @State private var selectedLeague: League? = nil
    
    enum LeaderboardCategory: String, CaseIterable {
        case global = "Global"
        case local = "Local"
        case friends = "Friends"
        case league = "League"
    }
    
    enum TimeFrame: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case season = "Season"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with current user rank and league info
                leaderboardHeader
                
                // League tier progression
                leagueTierSection
                
                // Category and timeframe selectors
                filtersSection
                
                // Leaderboard content
                ScrollView {
                    LazyVStack(spacing: 8) {
                        // Top 3 podium
                        if !filteredUsers.isEmpty {
                            topThreePodium
                        }
                        
                        // Rest of the rankings
                        ForEach(Array(filteredUsers.enumerated()), id: \.offset) { index, user in
                            if index >= 3 {
                                LeaderboardRow(
                                    user: user,
                                    rank: index + 1,
                                    isCurrentUser: user.id == appState.currentUser?.id,
                                    showDivision: selectedCategory == .global
                                )
                                .onTapGesture {
                                    // TODO: Show user profile
                                }
                            }
                        }
                        
                        // Season end countdown
                        if selectedTimeframe == .season {
                            seasonCountdownCard
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Leaderboards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingLeagueInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingLeagueInfo) {
                LeagueInfoView()
            }
        }
    }
    
    // MARK: - Header
    
    private var leaderboardHeader: some View {
        VStack(spacing: 16) {
            if let currentUser = appState.currentUser {
                let userRank = getUserRank(currentUser)
                let currentLeague = getLeagueForELO(currentUser.elo)
                
                HStack(spacing: 16) {
                    // Current user info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Rank")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Text("#\(userRank)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            LeagueIcon(league: currentLeague, size: 24)
                        }
                    }
                    
                    Spacer()
                    
                    // League progression
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(currentLeague.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(currentUser.elo) ELO")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(currentLeague.color)
                    }
                }
                
                // Progress to next league
                if let nextLeague = getNextLeague(currentLeague) {
                    let progress = getProgressToNextLeague(currentUser.elo, currentLeague: currentLeague, nextLeague: nextLeague)
                    
                    VStack(spacing: 8) {
                        HStack {
                            Text("Progress to \(nextLeague.name)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(nextLeague.minELO - currentUser.elo) ELO to go")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: nextLeague.color))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - League Tier Section
    
    private var leagueTierSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("League Tiers")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button("View All") {
                    showingLeagueInfo = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(League.allLeagues) { league in
                        LeagueTierCard(
                            league: league,
                            playerCount: getPlayerCountInLeague(league),
                            isCurrentUserLeague: isCurrentUserInLeague(league)
                        ) {
                            selectedLeague = league
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Filters Section
    
    private var filtersSection: some View {
        VStack(spacing: 8) {
            // Category picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
                            }
                        } label: {
                            Text(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == category ? Color.blue : Color(.tertiarySystemBackground))
                                )
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Timeframe picker
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Top Three Podium
    
    private var topThreePodium: some View {
        VStack(spacing: 16) {
            Text("🏆 Champions")
                .font(.headline)
                .fontWeight(.bold)
            
            HStack(alignment: .bottom, spacing: 8) {
                // 2nd place
                if filteredUsers.count > 1 {
                    PodiumPosition(
                        user: filteredUsers[1],
                        rank: 2,
                        height: 80,
                        color: .gray
                    )
                }
                
                // 1st place
                if !filteredUsers.isEmpty {
                    PodiumPosition(
                        user: filteredUsers[0],
                        rank: 1,
                        height: 100,
                        color: .yellow
                    )
                }
                
                // 3rd place
                if filteredUsers.count > 2 {
                    PodiumPosition(
                        user: filteredUsers[2],
                        rank: 3,
                        height: 60,
                        color: Color.orange.opacity(0.8)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Season Countdown Card
    
    private var seasonCountdownCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .foregroundColor(.orange)
                Text("Season Ends In")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("12")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Days")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("8")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("23")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text("Don't forget to claim your season rewards!")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties
    
    private var filteredUsers: [User] {
        switch selectedCategory {
        case .global:
            return Array(users.prefix(50)) // Limit to top 50 for performance
        case .local:
            // TODO: Filter by location
            return Array(users.prefix(25))
        case .friends:
            // TODO: Filter by friends
            return Array(users.prefix(10))
        case .league:
            // TODO: Filter by current user's league
            if let currentUser = appState.currentUser {
                let currentLeague = getLeagueForELO(currentUser.elo)
                return users.filter { user in
                    let userLeague = getLeagueForELO(user.elo)
                    return userLeague.id == currentLeague.id
                }
            }
            return []
        }
    }
    
    // MARK: - Helper Methods
    
    private func getUserRank(_ user: User) -> Int {
        return (users.firstIndex(where: { $0.id == user.id }) ?? 0) + 1
    }
    
    private func getLeagueForELO(_ elo: Int) -> League {
        return League.allLeagues.last { league in
            elo >= league.minELO
        } ?? League.allLeagues.first!
    }
    
    private func getNextLeague(_ currentLeague: League) -> League? {
        guard let currentIndex = League.allLeagues.firstIndex(where: { $0.id == currentLeague.id }),
              currentIndex < League.allLeagues.count - 1 else {
            return nil
        }
        return League.allLeagues[currentIndex + 1]
    }
    
    private func getProgressToNextLeague(_ currentELO: Int, currentLeague: League, nextLeague: League) -> Double {
        let currentMin = currentLeague.minELO
        let nextMin = nextLeague.minELO
        let progress = Double(currentELO - currentMin) / Double(nextMin - currentMin)
        return min(max(progress, 0), 1)
    }
    
    private func getPlayerCountInLeague(_ league: League) -> Int {
        return users.filter { user in
            let userLeague = getLeagueForELO(user.elo)
            return userLeague.id == league.id
        }.count
    }
    
    private func isCurrentUserInLeague(_ league: League) -> Bool {
        guard let currentUser = appState.currentUser else { return false }
        let currentLeague = getLeagueForELO(currentUser.elo)
        return currentLeague.id == league.id
    }
}

// MARK: - Supporting Views

struct LeagueIcon: View {
    let league: League
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [league.color, league.color.opacity(0.6)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            Image(systemName: league.icon)
                .font(.system(size: size * 0.5))
                .foregroundColor(.white)
        }
    }
}

struct LeagueTierCard: View {
    let league: League
    let playerCount: Int
    let isCurrentUserLeague: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [league.color, league.color.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(isCurrentUserLeague ? Color.white : Color.clear, lineWidth: 3)
                                .scaleEffect(1.1)
                        )
                    
                    Image(systemName: league.icon)
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    if isCurrentUserLeague {
                        Circle()
                            .fill(Color.yellow)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                            .offset(x: 20, y: -20)
                    }
                }
                
                Text(league.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("\(playerCount) players")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("\(league.minELO)+ ELO")
                    .font(.caption2)
                    .foregroundColor(league.color)
                    .fontWeight(.medium)
            }
            .frame(width: 90)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PodiumPosition: View {
    let user: User
    let rank: Int
    let height: CGFloat
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // Trophy or medal
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // User avatar
            Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(user.displayName.isEmpty ? user.email.prefix(1) : user.displayName.prefix(1)))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                )
            
            // User info
            VStack(spacing: 2) {
                Text(user.displayName.isEmpty ? user.email.components(separatedBy: "@").first ?? "Player" : user.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("\(user.elo) ELO")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Podium base
            Rectangle()
                .fill(color.opacity(0.8))
                .frame(width: 80, height: height)
                .overlay(
                    VStack {
                        Spacer()
                        Text("#\(rank)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.bottom, 8)
                    }
                )
        }
    }
}

struct LeaderboardRow: View {
    let user: User
    let rank: Int
    let isCurrentUser: Bool
    let showDivision: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text("#\(rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isCurrentUser ? .blue : .secondary)
                .frame(width: 40, alignment: .leading)
            
            // User avatar
            Circle()
                .fill(isCurrentUser ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user.displayName.isEmpty ? user.email.prefix(1) : user.displayName.prefix(1)))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(isCurrentUser ? .blue : .gray)
                )
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName.isEmpty ? user.email.components(separatedBy: "@").first ?? "Player" : user.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isCurrentUser ? .blue : .primary)
                
                if showDivision {
                    let league = getLeagueForELO(user.elo)
                    HStack(spacing: 4) {
                        LeagueIcon(league: league, size: 16)
                        Text(league.name)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(user.elo)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isCurrentUser ? .blue : .primary)
                
                Text(user.formattedWinRate)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentUser ? Color.blue.opacity(0.1) : Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isCurrentUser ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
    
    private func getLeagueForELO(_ elo: Int) -> League {
        return League.allLeagues.last { league in
            elo >= league.minELO
        } ?? League.allLeagues.first!
    }
}

// MARK: - Data Models

struct League: Identifiable {
    let id = UUID()
    let name: String
    let minELO: Int
    let icon: String
    let color: Color
    
    static let allLeagues: [League] = [
        League(name: "Bronze", minELO: 0, icon: "shield", color: Color.orange.opacity(0.8)),
        League(name: "Silver", minELO: 1000, icon: "shield.fill", color: Color.gray),
        League(name: "Gold", minELO: 1300, icon: "crown", color: Color.yellow),
        League(name: "Platinum", minELO: 1600, icon: "crown.fill", color: Color.cyan),
        League(name: "Diamond", minELO: 1900, icon: "diamond", color: Color.blue),
        League(name: "Master", minELO: 2200, icon: "diamond.fill", color: Color.purple),
        League(name: "Legend", minELO: 2500, icon: "star.circle.fill", color: Color.red)
    ]
}

// MARK: - Placeholder Views

struct LeagueInfoView: View {
    var body: some View {
        Text("League Information")
    }
}

#Preview {
    LeaderboardView()
        .environment(AppState())
} 