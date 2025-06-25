import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Query(sort: \User.elo, order: .reverse) private var users: [User]
    @EnvironmentObject private var appState: AppState
    @State private var selectedCategory: LeaderboardCategory = .global
    @State private var selectedTimeframe: TimeFrame = .season
    @State private var showingLeagueInfo = false
    @State private var selectedLeague: League? = nil
    @State private var isRefreshing = false
    
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
                    RefreshableView(isRefreshing: $isRefreshing, onRefresh: refreshLeaderboardData)
                    
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
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingLeagueInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(DS.Color.accent)
                    }
                }
            }
            .sheet(isPresented: $showingLeagueInfo) {
                LeagueInfoView()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshLeaderboardData() async {
        // This would fetch fresh data from the server
        // For now, we'll just simulate a delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
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
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                        
                        HStack(spacing: 8) {
                            Text("#\(userRank)")
                                .font(DS.Font.title2)
                                .fontWeight(.bold)
                                .foregroundColor(DS.Color.primary)
                            
                            LeagueIcon(league: currentLeague, size: 24)
                        }
                    }
                    
                    Spacer()
                    
                    // League progression
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(currentLeague.name)
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                        
                        Text("\(currentUser.elo) ELO")
                            .font(DS.Font.title3)
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
                                .font(DS.Font.caption)
                                .foregroundColor(DS.Color.secondary)
                            Spacer()
                            Text("\(nextLeague.minELO - currentUser.elo) ELO to go")
                                .font(DS.Font.caption)
                                .foregroundColor(DS.Color.secondary)
                        }
                        
                        DSProgressBar(value: progress, color: nextLeague.color)
                    }
                }
            }
        }
        .padding()
        .background(DS.Color.surface)
    }
    
    // MARK: - League Tier Section
    
    private var leagueTierSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("League Tiers")
                    .font(DS.Font.headline)
                    .fontWeight(.bold)
                Spacer()
                Button("View All") {
                    showingLeagueInfo = true
                }
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.accent)
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
        .padding(.horizontal)
        .background(DS.Color.background)
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
                                .font(DS.Font.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedCategory == category ? DS.Color.accent : DS.Color.surface)
                                )
                                .foregroundColor(selectedCategory == category ? .white : DS.Color.primary)
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
                .font(DS.Font.headline)
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
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                .fill(LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
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
                    .font(DS.Font.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("12")
                        .font(DS.Font.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Days")
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("8")
                        .font(DS.Font.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Hours")
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("23")
                        .font(DS.Font.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Minutes")
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.secondary)
                }
                
                Spacer()
            }
            
            Text("Don't forget to claim your season rewards!")
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                .fill(Color.orange.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
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
                    .font(DS.Font.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(DS.Color.primary)
                
                Text("\(playerCount) players")
                    .font(DS.Font.caption2)
                    .foregroundColor(DS.Color.secondary)
                
                Text("\(league.minELO)+ ELO")
                    .font(DS.Font.caption2)
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
                    .font(DS.Font.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // User avatar
            Circle()
                .fill(DS.Color.accent.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(String(user.displayName.isEmpty ? user.email.prefix(1) : user.displayName.prefix(1)))
                        .font(DS.Font.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DS.Color.accent)
                )
            
            // User info
            VStack(spacing: 2) {
                Text(user.displayName.isEmpty ? user.email.components(separatedBy: "@").first ?? "Player" : user.displayName)
                    .font(DS.Font.caption)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                
                Text("\(user.elo) ELO")
                    .font(DS.Font.caption2)
                    .foregroundColor(DS.Color.secondary)
            }
            
            // Podium base
            Rectangle()
                .fill(color.opacity(0.8))
                .frame(width: 80, height: height)
                .overlay(
                    VStack {
                        Spacer()
                        Text("#\(rank)")
                            .font(DS.Font.title2)
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
                .font(DS.Font.headline)
                .fontWeight(.bold)
                .foregroundColor(isCurrentUser ? DS.Color.accent : DS.Color.secondary)
                .frame(width: 40, alignment: .leading)
            
            // User avatar
            Circle()
                .fill(isCurrentUser ? DS.Color.accent.opacity(0.3) : DS.Color.surface)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(user.displayName.isEmpty ? user.email.prefix(1) : user.displayName.prefix(1)))
                        .font(DS.Font.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(isCurrentUser ? DS.Color.accent : DS.Color.secondary)
                )
            
            // User info
            VStack(alignment: .leading, spacing: 2) {
                Text(user.displayName.isEmpty ? user.email.components(separatedBy: "@").first ?? "Player" : user.displayName)
                    .font(DS.Font.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isCurrentUser ? DS.Color.accent : DS.Color.primary)
                
                if showDivision {
                    let league = getLeagueForELO(user.elo)
                    HStack(spacing: 4) {
                        LeagueIcon(league: league, size: 16)
                        Text(league.name)
                            .font(DS.Font.caption2)
                            .foregroundColor(DS.Color.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(user.elo)")
                    .font(DS.Font.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isCurrentUser ? DS.Color.accent : DS.Color.primary)
                
                Text(user.formattedWinRate)
                    .font(DS.Font.caption2)
                    .foregroundColor(DS.Color.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                .fill(isCurrentUser ? DS.Color.accent.opacity(0.1) : DS.Color.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                        .stroke(isCurrentUser ? DS.Color.accent.opacity(0.3) : Color.clear, lineWidth: 1)
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Layout.sectionSpacing) {
                    // How Leagues Work
                    VStack(alignment: .leading, spacing: DS.Layout.itemSpacing) {
                        Text("How Leagues Work")
                            .font(DS.Font.title3)
                            .fontWeight(.bold)
                        
                        Text("Leagues are determined by your ELO rating. As you win matches, your ELO increases, allowing you to climb to higher leagues with better rewards.")
                            .font(DS.Font.body)
                            .foregroundColor(DS.Color.primary)
                    }
                    .padding()
                    .background(DS.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
                    
                    // League Tiers
                    VStack(alignment: .leading, spacing: DS.Layout.itemSpacing) {
                        Text("League Tiers")
                            .font(DS.Font.title3)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            ForEach(League.allLeagues) { league in
                                HStack(spacing: 16) {
                                    LeagueIcon(league: league, size: 40)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(league.name)
                                            .font(DS.Font.headline)
                                            .fontWeight(.semibold)
                                        
                                        Text("\(league.minELO)+ ELO required")
                                            .font(DS.Font.caption)
                                            .foregroundColor(DS.Color.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(Int.random(in: 5...100)) players")
                                        .font(DS.Font.caption)
                                        .foregroundColor(DS.Color.secondary)
                                }
                                .padding()
                                .background(DS.Color.surfaceAlt)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
                            }
                        }
                    }
                    .padding()
                    .background(DS.Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
                }
                .padding()
            }
            .navigationTitle("League Information")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(AppState())
} 