import SwiftUI
import SwiftData

struct LeaderboardView: View {
    @Query(sort: \User.elo, order: .reverse) private var users: [User]
    @EnvironmentObject private var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedCategory: LeaderboardCategory = .global
    @State private var selectedTimeframe: TimeFrame = .season
    @State private var showingLeagueInfo = false
    @State private var selectedLeague: League? = nil
    @State private var isRefreshing = false
    @State private var animateContent = false
    
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
        GeometryReader { geometry in
            let safeAreaTop = geometry.safeAreaInsets.top
            let safeAreaBottom = geometry.safeAreaInsets.bottom
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Champions Header - Properly positioned to avoid sidebar and navigation bar
                    championsHeaderWithSafeArea(safeAreaTop: safeAreaTop)
                    
                    // Main content with proper spacing and sidebar consideration
                    VStack(spacing: DS.Layout.sectionSpacing) {
                        // League tier progression with enhanced design
                        leagueTierSection
                        
                        // Enhanced category and timeframe selectors
                        filtersSection
                        
                        // Leaderboard content with premium styling
                        LazyVStack(spacing: DS.Layout.cardSpacing) {
                            // Enhanced top 3 podium
                            if !filteredUsers.isEmpty {
                                topThreePodium
                            }
                            
                            // Rest of the rankings with premium cards
                            ForEach(Array(filteredUsers.enumerated()), id: \.offset) { index, user in
                                if index >= 3 {
                                    PremiumLeaderboardRow(
                                        user: user,
                                        rank: index + 1,
                                        isCurrentUser: user.id == appState.currentUser?.id,
                                        showDivision: selectedCategory == .global
                                    )
                                    .onTapGesture {
                                        // Show user profile with haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                    }
                                }
                            }
                            
                            // Enhanced season end countdown
                            if selectedTimeframe == .season {
                                seasonCountdownCard
                            }
                        }
                        
                        // Refresh indicator
                        if isRefreshing {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .padding()
                                    .background(DS.Color.surface)
                                    .clipShape(Circle())
                                    .shadow(radius: 8)
                                Spacer()
                            }
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
            .refreshable {
                await refreshLeaderboardData()
            }
        }
        .background(DS.Color.backgroundGradient)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animateContent = true
            }
        }
        .sheet(isPresented: $showingLeagueInfo) {
            LeagueInfoView()
        }
    }
    
    // MARK: - Safe Area Aware Champions Header
    
    private func championsHeaderWithSafeArea(safeAreaTop: CGFloat) -> some View {
        ZStack {
            // Enhanced gradient background
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.9),
                            Color.yellow.opacity(0.7),
                            Color.orange.opacity(0.5)
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
                        .offset(x: 100, y: -50)
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
                    if let currentUser = appState.currentUser {
                        let userRank = getUserRank(currentUser)
                        let currentLeague = getLeagueForELO(currentUser.elo)
                        
                        // Champions header and user rank
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Champions")
                                    .font(DS.Font.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("Global leaderboard")
                                    .font(DS.Font.body)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            // Info button
                            Button {
                                showingLeagueInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                                    .frame(width: 32, height: 32)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, DS.Layout.horizontalPadding)
                        
                        // Current user stats
                        HStack(spacing: 24) {
                            quickStatItem("Your Rank", "#\(userRank)", "trophy.fill")
                            quickStatItem("League", currentLeague.name, "shield.fill")
                            quickStatItem("ELO", "\(currentUser.elo)", "star.fill")
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
    
    // MARK: - Helper Methods
    
    private func refreshLeaderboardData() async {
        await MainActor.run {
            isRefreshing = true
        }
        
        // Simulate data refresh with haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run {
            isRefreshing = false
        }
    }
    
    // MARK: - Enhanced League Tier Section
    
    private var leagueTierSection: some View {
        VStack(spacing: 16) {
            DSPremiumSectionHeader(
                title: "League Tiers",
                subtitle: "Competitive divisions",
                icon: "trophy.fill"
            )
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(League.allLeagues) { league in
                        PremiumLeagueTierCard(
                            league: league,
                            playerCount: getPlayerCountInLeague(league),
                            isCurrentUserLeague: isCurrentUserInLeague(league)
                        ) {
                            selectedLeague = league
                            // Add haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Enhanced Filters Section
    
    private var filtersSection: some View {
        VStack(spacing: 16) {
            // Premium category picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LeaderboardCategory.allCases, id: \.self) { category in
                        Button {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedCategory = category
                            }
                            
                            // Add haptic feedback
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
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
            
            // Enhanced timeframe picker
            Picker("Timeframe", selection: $selectedTimeframe) {
                ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                    Text(timeframe.rawValue).tag(timeframe)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .accentColor(DS.Color.accent)
        }
    }
    
    // MARK: - Enhanced Top Three Podium
    
    private var topThreePodium: some View {
        DSGlassMorphismCard {
            VStack(spacing: 20) {
                Text("🏆 Hall of Champions")
                    .font(DS.Font.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DS.Color.primary)
                
                HStack(alignment: .bottom, spacing: 12) {
                    // 2nd place
                    if filteredUsers.count > 1 {
                        PremiumPodiumPosition(
                            user: filteredUsers[1],
                            rank: 2,
                            height: 100,
                            gradient: DS.Color.silverGradient
                        )
                    }
                    
                    // 1st place
                    if !filteredUsers.isEmpty {
                        PremiumPodiumPosition(
                            user: filteredUsers[0],
                            rank: 1,
                            height: 130,
                            gradient: DS.Color.goldGradient
                        )
                    }
                    
                    // 3rd place
                    if filteredUsers.count > 2 {
                        PremiumPodiumPosition(
                            user: filteredUsers[2],
                            rank: 3,
                            height: 80,
                            gradient: DS.Color.bronzeGradient
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Enhanced Season Countdown Card
    
    private var seasonCountdownCard: some View {
        DSGlassMorphismCard {
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(DS.Color.warningGradient)
                        .font(.title2)
                    
                    Text("Season Ends In")
                        .font(DS.Font.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DS.Color.primary)
                    
                    Spacer()
                }
                
                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        DSAnimatedCounter(value: 12, duration: 0.8)
                            .font(DS.Font.title)
                            .fontWeight(.bold)
                            .foregroundColor(DS.Color.warning)
                        Text("Days")
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        DSAnimatedCounter(value: 8, duration: 1.0)
                            .font(DS.Font.title)
                            .fontWeight(.bold)
                            .foregroundColor(DS.Color.warning)
                        Text("Hours")
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                    }
                    
                    VStack(spacing: 4) {
                        DSAnimatedCounter(value: 23, duration: 1.2)
                            .font(DS.Font.title)
                            .fontWeight(.bold)
                            .foregroundColor(DS.Color.warning)
                        Text("Minutes")
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                    }
                    
                    Spacer()
                }
                
                Text("🎁 Don't forget to claim your season rewards!")
                    .font(DS.Font.bodyEmphasized)
                    .foregroundColor(DS.Color.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
        }
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

struct PremiumLeaderboardRow: View {
    let user: User
    let rank: Int
    let isCurrentUser: Bool
    let showDivision: Bool
    
    var body: some View {
        DSGlassMorphismCard {
            HStack(spacing: 16) {
                // Rank with premium styling
                ZStack {
                    Circle()
                        .fill(isCurrentUser ? DS.Color.accentGradient : DS.Color.surfaceGradient)
                        .frame(width: 40, height: 40)
                        .shadow(color: isCurrentUser ? DS.Color.accent.opacity(0.3) : .clear, radius: 8)
                    
                    Text("\(rank)")
                        .font(DS.Font.headline)
                        .fontWeight(.bold)
                        .foregroundColor(isCurrentUser ? .white : DS.Color.primary)
                }
                
                // User avatar with league indicator
                ZStack {
                    Circle()
                        .fill(DS.Color.surfaceGradient)
                        .frame(width: 50, height: 50)
                    
                    if let imageURL = user.profileImageURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .foregroundColor(DS.Color.secondary)
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(DS.Color.secondary)
                            .font(.title2)
                    }
                    
                    // League badge
                    if showDivision {
                        let league = getLeagueForELO(user.elo)
                        Circle()
                            .fill(league.color)
                            .frame(width: 18, height: 18)
                            .overlay(
                                Image(systemName: league.icon)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                            .offset(x: 18, y: 18)
                    }
                }
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName.isEmpty ? "Player \(rank)" : user.displayName)
                        .font(DS.Font.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DS.Color.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if showDivision {
                        let league = getLeagueForELO(user.elo)
                        Text(league.name)
                            .font(DS.Font.caption)
                            .foregroundColor(league.color)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack(spacing: 8) {
                        Text("\(user.totalMatches) matches")
                            .font(DS.Font.caption)
                            .foregroundColor(DS.Color.secondary)
                        
                        if user.winStreak > 0 {
                            Text("•")
                                .foregroundColor(DS.Color.secondary)
                                .font(DS.Font.caption)
                            
                            Text("\(user.winStreak) streak")
                                .font(DS.Font.caption)
                                .fontWeight(.medium)
                                .foregroundColor(DS.Color.success)
                        }
                    }
                }
                
                Spacer()
                
                // ELO and stats
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(user.elo)")
                        .font(DS.Font.title3)
                        .fontWeight(.bold)
                        .foregroundColor(isCurrentUser ? DS.Color.accent : DS.Color.primary)
                    
                    Text("ELO")
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.secondary)
                    
                    if user.totalMatches > 0 {
                        Text("\(Int(user.winRate * 100))% WR")
                            .font(DS.Font.caption)
                            .fontWeight(.medium)
                            .foregroundColor(user.winRate > 0.6 ? DS.Color.success : DS.Color.warning)
                    }
                }
            }
        }
    }
    
    private func getLeagueForELO(_ elo: Int) -> League {
        return League.allLeagues.last { league in
            elo >= league.minELO
        } ?? League.allLeagues.first!
    }
}

struct PremiumLeagueIcon: View {
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
                .shadow(color: league.color.opacity(0.3), radius: size * 0.2)
            
            Image(systemName: league.icon)
                .font(.system(size: size * 0.5))
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
    }
}

struct PremiumLeagueTierCard: View {
    let league: League
    let playerCount: Int
    let isCurrentUserLeague: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // League icon with enhanced styling
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [league.color, league.color.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .shadow(color: league.color.opacity(0.4), radius: 12)
                    
                    Image(systemName: league.icon)
                        .font(.title)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    // Current user indicator
                    if isCurrentUserLeague {
                        Circle()
                            .fill(DS.Color.warningGradient)
                            .frame(width: 20, height: 20)
                            .overlay(
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                            .offset(x: 25, y: -25)
                            .shadow(color: DS.Color.warning.opacity(0.5), radius: 4)
                    }
                }
                
                VStack(spacing: 6) {
                    Text(league.name)
                        .font(DS.Font.headline)
                        .fontWeight(.bold)
                        .foregroundColor(DS.Color.primary)
                    
                    Text("\(playerCount) players")
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.secondary)
                    
                    Text("\(league.minELO)+ ELO")
                        .font(DS.Font.caption)
                        .fontWeight(.medium)
                        .foregroundColor(league.color)
                }
            }
            .frame(width: 120)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                    .fill(isCurrentUserLeague ? league.color.opacity(0.1) : DS.Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                            .stroke(isCurrentUserLeague ? league.color.opacity(0.3) : DS.Color.divider.opacity(0.1), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PremiumPodiumPosition: View {
    let user: User
    let rank: Int
    let height: CGFloat
    let gradient: LinearGradient
    
    var body: some View {
        VStack(spacing: 12) {
            // Trophy with rank
            ZStack {
                Circle()
                    .fill(gradient)
                    .frame(width: rank == 1 ? 80 : 60, height: rank == 1 ? 80 : 60)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                
                VStack(spacing: 2) {
                    Image(systemName: rank == 1 ? "crown.fill" : "medal.fill")
                        .font(.system(size: rank == 1 ? 24 : 18))
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    
                    Text("\(rank)")
                        .font(DS.Font.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            // User avatar
            ZStack {
                Circle()
                    .fill(DS.Color.surfaceGradient)
                    .frame(width: 50, height: 50)
                
                if let imageURL = user.profileImageURL {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .foregroundColor(DS.Color.secondary)
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .foregroundColor(DS.Color.secondary)
                        .font(.title2)
                }
            }
            
            // User info
            VStack(spacing: 4) {
                Text(user.displayName.isEmpty ? "Champion" : user.displayName)
                    .font(DS.Font.bodyEmphasized)
                    .fontWeight(.bold)
                    .foregroundColor(DS.Color.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text("\(user.elo) ELO")
                    .font(DS.Font.caption)
                    .fontWeight(.medium)
                    .foregroundColor(DS.Color.secondary)
                
                if user.winStreak > 0 {
                    Text("\(user.winStreak) streak")
                        .font(DS.Font.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DS.Color.success)
                }
            }
            
            // Podium base
            Rectangle()
                .fill(gradient)
                .frame(width: 80, height: height)
                .cornerRadius(8, corners: [.topLeft, .topRight])
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
        }
        .scaleEffect(rank == 1 ? 1.1 : 1.0)
    }
}

// MARK: - Helper Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - League Info View

struct LeagueInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Color.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DS.Layout.sectionSpacing) {
                        DSGlassMorphismCard {
                            VStack(spacing: 16) {
                                Text("League System")
                                    .font(DS.Font.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(DS.Color.primary)
                                
                                Text("Climb through competitive divisions based on your ELO rating and skill level.")
                                    .font(DS.Font.bodyEmphasized)
                                    .foregroundColor(DS.Color.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        ForEach(League.allLeagues.reversed()) { league in
                            DSGlassMorphismCard {
                                HStack(spacing: 16) {
                                    PremiumLeagueIcon(league: league, size: 60)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(league.name)
                                            .font(DS.Font.headline)
                                            .fontWeight(.bold)
                                            .foregroundColor(DS.Color.primary)
                                        
                                        Text("\(league.minELO)+ ELO Required")
                                            .font(DS.Font.bodyEmphasized)
                                            .foregroundColor(league.color)
                                            .fontWeight(.medium)
                                        
                                        Text(league.description)
                                            .font(DS.Font.caption)
                                            .foregroundColor(DS.Color.secondary)
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("League System")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DS.Color.accent)
                }
            }
        }
    }
}

// MARK: - Original Supporting Views (updated with DS styling)

struct LeagueIcon: View {
    let league: League
    let size: CGFloat
    
    var body: some View {
        PremiumLeagueIcon(league: league, size: size)
    }
}

struct LeagueTierCard: View {
    let league: League
    let playerCount: Int
    let isCurrentUserLeague: Bool
    let action: () -> Void
    
    var body: some View {
        PremiumLeagueTierCard(
            league: league,
            playerCount: playerCount,
            isCurrentUserLeague: isCurrentUserLeague,
            action: action
        )
    }
}

struct PodiumPosition: View {
    let user: User
    let rank: Int
    let height: CGFloat
    let color: Color
    
    var body: some View {
        let gradient = LinearGradient(
            colors: [color, color.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        PremiumPodiumPosition(
            user: user,
            rank: rank,
            height: height,
            gradient: gradient
        )
    }
}

struct LeaderboardRow: View {
    let user: User
    let rank: Int
    let isCurrentUser: Bool
    let showDivision: Bool
    
    var body: some View {
        PremiumLeaderboardRow(
            user: user,
            rank: rank,
            isCurrentUser: isCurrentUser,
            showDivision: showDivision
        )
    }
}

#Preview {
    LeaderboardView()
        .environmentObject(AppState())
} 