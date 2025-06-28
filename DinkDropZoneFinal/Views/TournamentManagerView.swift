import SwiftUI
import SwiftData
import Combine

struct TournamentManagerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @StateObject private var enhancedTournamentService = TournamentServiceEnhanced(
        firebaseService: FirebaseService.shared,
        tournamentService: TournamentService(firebaseService: FirebaseService.shared)
    )
    @State private var tournaments: [Tournament] = []
    @State private var showCreateTournament = false
    @State private var selectedTournament: Tournament?
    @State private var isLoading = true
    @State private var selectedFilter: TournamentFilter = .all
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var showAnalytics = false
    @State private var refreshTimer: Timer?
    @State private var lastRefreshTime = Date()
    @State private var showingJoinTournament = false
    @State private var tournamentToJoin: Tournament?
    
    // Analytics state
    @State private var totalTournaments = 0
    @State private var activeTournaments = 0
    @State private var myTournamentCount = 0
    @State private var completionRate: Double = 0.0
    
    enum TournamentFilter: String, CaseIterable {
        case all = "All"
        case upcoming = "Upcoming"
        case active = "Active"
        case completed = "Completed"
        case myTournaments = "My Tournaments"
        case featured = "Featured"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .upcoming: return "clock"
            case .active: return "play.circle"
            case .completed: return "checkmark.circle"
            case .myTournaments: return "person.circle"
            case .featured: return "star"
            }
        }
        
        var description: String {
            switch self {
            case .all: return "All tournaments"
            case .upcoming: return "Tournaments starting soon"
            case .active: return "Currently in progress"
            case .completed: return "Finished tournaments"
            case .myTournaments: return "Tournaments you've joined"
            case .featured: return "Highlighted tournaments"
            }
        }
    }
    
    var filteredTournaments: [Tournament] {
        // First, ensure unique tournaments by ID to prevent duplicates
        let uniqueTournaments = Dictionary(grouping: tournaments, by: { $0.id })
            .compactMapValues { $0.first }
            .values
            .map { $0 }
        
        var filtered = uniqueTournaments
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { tournament in
                tournament.name.localizedCaseInsensitiveContains(searchText) ||
                tournament.description.localizedCaseInsensitiveContains(searchText) ||
                tournament.skillLevel.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .upcoming:
            filtered = filtered.filter { $0.status == "Upcoming" || $0.status == "Registration Open" }
        case .active:
            filtered = filtered.filter { $0.status == "In Progress" }
        case .completed:
            filtered = filtered.filter { $0.status == "Completed" }
        case .myTournaments:
            if let currentUser = appState.currentUser {
                filtered = filtered.filter { tournament in
                    tournament.participants.contains { $0.userID == currentUser.id.uuidString }
                }
            }
        case .featured:
            // Implement featured tournaments logic
            break
        }
        
        return filtered.sorted { $0.startDate < $1.startDate }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.8),
                        Color(.secondarySystemBackground).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search and Filter Header
                    headerView
                    
                    if isLoading {
                        loadingView
                    } else if filteredTournaments.isEmpty {
                        emptyStateView
                    } else {
                        tournamentsList
                    }
                }
            }
            .navigationTitle("Tournaments")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.spring()) {
                                showFilters.toggle()
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title2)
                                .foregroundColor(.primary)
                        }
                        
                        Button {
                            withAnimation(.spring()) {
                                showAnalytics.toggle()
                            }
                        } label: {
                            Image(systemName: "chart.bar.doc.horizontal")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateTournament = true
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.brown)
                    }
                }
            }
            .sheet(isPresented: $showCreateTournament) {
                CreateTournamentWizard()
                    .onDisappear {
                        Task {
                            await loadTournamentsWithAnimation()
                        }
                    }
            }
            .sheet(item: $selectedTournament) { tournament in
                TournamentDetailView(tournament: tournament, tournamentService: TournamentService(firebaseService: FirebaseService.shared))
                    .environmentObject(appState)
            }
            .sheet(isPresented: $showingJoinTournament) {
                if let tournament = tournamentToJoin {
                    TournamentJoinView(tournament: tournament, enhancedService: enhancedTournamentService)
                        .environmentObject(appState)
                        .onDisappear {
                            Task {
                                await loadTournamentsWithAnimation()
                            }
                        }
                }
            }
            .sheet(isPresented: $showAnalytics) {
                TournamentAnalyticsView(
                    totalTournaments: totalTournaments,
                    activeTournaments: activeTournaments,
                    myTournaments: myTournamentCount,
                    completionRate: completionRate,
                    tournaments: tournaments
                )
            }
            .onAppear {
                Task {
                    await loadTournamentsWithAnimation()
                }
            }
            .onDisappear {
                stopRealTimeUpdates()
            }
            .refreshable {
                await loadTournamentsWithAnimation()
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search tournaments...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
            
            // Filter Pills
            if showFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(TournamentFilter.allCases, id: \.self) { filter in
                            TournamentManagerFilterPill(
                                filter: filter,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedFilter = filter
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .horizontal)
        )
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            ForEach(0..<3, id: \.self) { _ in
                TournamentCardSkeleton()
            }
        }
        .padding()
        .transition(.opacity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            // Animated Trophy
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.brown.opacity(0.2), .brown.opacity(0.05)],
                            center: .center,
                            startRadius: 20,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(isLoading ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isLoading)
                
                Image(systemName: "trophy.circle")
                    .font(.system(size: 80, weight: .light))
                    .foregroundColor(.brown)
                    .rotationEffect(.degrees(isLoading ? 5 : -5))
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isLoading)
            }
            
            VStack(spacing: 16) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(emptyStateMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)
            
            Button {
                showCreateTournament = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    
                    Text("Create Tournament")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.brown, .brown.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .brown.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .scaleEffect(isLoading ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isLoading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        ))
    }
    
    private var emptyStateTitle: String {
        switch selectedFilter {
        case .all:
            return searchText.isEmpty ? "No Tournaments Yet" : "No Results Found"
        case .upcoming:
            return "No Upcoming Tournaments"
        case .active:
            return "No Active Tournaments"
        case .completed:
            return "No Completed Tournaments"
        case .myTournaments:
            return "You Haven't Joined Any Tournaments"
        case .featured:
            return "No Featured Tournaments"
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedFilter {
        case .all:
            return searchText.isEmpty ? 
                "Create your first tournament to get the competition started!" :
                "Try adjusting your search terms or clear the filter"
        case .upcoming:
            return "Check back later or create a new tournament to compete in"
        case .active:
            return "No tournaments are currently in progress"
        case .completed:
            return "No tournaments have been completed yet"
        case .myTournaments:
            return "Join a tournament to start competing and climbing the rankings!"
        case .featured:
            return "No featured tournaments available"
        }
    }
    
    // MARK: - Tournaments List
    
    private var tournamentsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(filteredTournaments.enumerated()), id: \.element.id) { index, tournament in
                    EnhancedTournamentCard(
                        tournament: tournament,
                        index: index,
                        canJoin: canJoinTournament(tournament)
                    ) {
                        selectedTournament = tournament
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } onJoin: {
                        tournamentToJoin = tournament
                        showingJoinTournament = true
                    } onDelete: {
                        deleteTournament(tournament)
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100) // Extra bottom padding
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: filteredTournaments.count)
    }
    
    // MARK: - Helper Methods
    
    @MainActor
    private func loadTournamentsWithAnimation() async {
        isLoading = true
        lastRefreshTime = Date()
        
        do {
            // Use enhanced tournament service for better caching and real-time updates
            try await enhancedTournamentService.fetchAllTournaments(forceRefresh: true)
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                tournaments = enhancedTournamentService.tournaments
                updateAnalytics()
                isLoading = false
            }
            
            // Start real-time updates for active tournaments
            enhancedTournamentService.subscribeToAllTournamentUpdates()
            
        } catch {
            print("❌ Failed to load tournaments: \(error)")
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                tournaments = enhancedTournamentService.tournaments // Use cached data
                updateAnalytics()
                isLoading = false
            }
        }
        
        // Start real-time updates
        startRealTimeUpdates()
    }
    
    private func updateAnalytics() {
        totalTournaments = tournaments.count
        activeTournaments = tournaments.filter { $0.status == "In Progress" }.count
        
        if let currentUser = appState.currentUser {
            myTournamentCount = tournaments.filter { tournament in
                tournament.participants.contains { $0.userID == currentUser.id.uuidString }
            }.count
        }
        
        let completedTournaments = tournaments.filter { $0.status == "Completed" }.count
        completionRate = totalTournaments > 0 ? Double(completedTournaments) / Double(totalTournaments) : 0.0
    }
    
    private func startRealTimeUpdates() {
        stopRealTimeUpdates()
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await refreshTournamentsQuietly()
            }
        }
    }
    
    private func stopRealTimeUpdates() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    @MainActor
    private func refreshTournamentsQuietly() async {
        guard Date().timeIntervalSince(lastRefreshTime) > 25 else { return }
        
        do {
            if let tournamentService = appState.tournamentService {
                let oldCount = tournaments.count
                try await tournamentService.loadTournamentsFromFirebase()
                let newTournaments = tournamentService.getAllTournaments()
                
                // Only update if there are actual changes
                if newTournaments.count != oldCount || hasChanges(newTournaments) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        tournaments = newTournaments
                        updateAnalytics()
                    }
                }
            }
        } catch {
            print("⚠️ Quiet refresh failed: \(error)")
        }
        
        lastRefreshTime = Date()
    }
    
    private func hasChanges(_ newTournaments: [Tournament]) -> Bool {
        for tournament in newTournaments {
            if let existing = tournaments.first(where: { $0.id == tournament.id }) {
                if existing.status != tournament.status ||
                   existing.participants.count != tournament.participants.count ||
                   existing.matches.count != tournament.matches.count {
                    return true
                }
            }
        }
        return false
    }
    
    private func deleteTournament(_ tournament: Tournament) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            tournaments.removeAll { $0.id == tournament.id }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
        
        // Show success feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    private func canJoinTournament(_ tournament: Tournament) -> Bool {
        guard let currentUser = appState.currentUser else { return false }
        let userID = currentUser.id.uuidString
        
        // Check if user is not already registered and tournament is open
        let isAlreadyRegistered = tournament.participants.contains { $0.userID == userID }
        let isRegistrationOpen = tournament.status == "Registration Open" || tournament.status == "Upcoming"
        let hasSpace = tournament.participants.count < tournament.maxParticipants
        
        return !isAlreadyRegistered && isRegistrationOpen && hasSpace
    }
}

// MARK: - Filter Pill Component

struct TournamentManagerFilterPill: View {
    let filter: TournamentManagerView.TournamentFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? .brown : Color(uiColor: .systemBackground))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                Capsule()
                    .stroke(isSelected ? .brown : .clear, lineWidth: 1)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Enhanced Tournament Card

struct EnhancedTournamentCard: View {
    let tournament: Tournament
    let index: Int
    let canJoin: Bool
    let onTap: () -> Void
    let onJoin: () -> Void
    let onDelete: () -> Void
    @StateObject private var bracketEngine = BracketEngine()
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Header with gradient background
                headerSection
                
                // Content section
                contentSection
                
                // Footer with stats
                footerSection
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [.brown.opacity(0.3), .brown.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) {
            // Empty onChanged for animation
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
        .swipeActions(edge: .trailing) {
            if tournament.status == "Upcoming" || tournament.status == "Registration Open" {
                Button("Delete", role: .destructive) {
                    onDelete()
                }
                .tint(.red)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: tournament)
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(tournament.format)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    statusBadge
                    
                    if tournament.status == "In Progress" {
                        progressRing
                    } else {
                        Image(systemName: "trophy.circle")
                            .font(.title2)
                            .foregroundColor(.brown.opacity(0.7))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .background(
            LinearGradient(
                colors: [statusColor.opacity(0.1), statusColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private var contentSection: some View {
        VStack(spacing: 16) {
            if !tournament.description.isEmpty {
                Text(tournament.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Date and venue info
            VStack(spacing: 8) {
                HStack {
                    Label(
                        tournament.startDate.formatted(date: .abbreviated, time: .shortened),
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Label(tournament.skillLevel, systemImage: "target")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !tournament.venueName.isEmpty {
                    HStack {
                        Label(tournament.venueName, systemImage: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var footerSection: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal, 20)
            
            HStack {
                statCard(
                    title: "Players",
                    value: "\(tournament.registeredCount)",
                    subtitle: "of \(tournament.maxParticipants)",
                    icon: "person.2.fill",
                    color: .blue
                )
                
                Spacer()
                
                if tournament.status == "In Progress" {
                    let status = bracketEngine.getBracketStatus(tournament: tournament)
                    statCard(
                        title: "Progress",
                        value: "\(Int(status.overallProgress * 100))%",
                        subtitle: "\(status.totalCompleted)/\(status.totalMatches)",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .purple
                    )
                } else {
                    statCard(
                        title: "Entry",
                        value: "Free",
                        subtitle: "open entry",
                        icon: "dollarsign.circle",
                        color: .green
                    )
                }
                
                Spacer()
                
                statCard(
                    title: "Format",
                    value: tournament.type,
                    subtitle: tournament.format,
                    icon: "trophy",
                    color: .brown
                )
            }
            .padding(.horizontal, 20)
            
            // Action buttons
            if canJoin && (tournament.status == "Registration Open" || tournament.status == "Upcoming") {
                HStack {
                    Spacer()
                    Button(action: onJoin) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Join Tournament")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(20)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Spacer()
                }
                .padding(.horizontal, 20)
            }
            
            Spacer(minLength: 20)
        }
    }
    
    private var statusBadge: some View {
        Text(tournament.status)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.2))
            )
            .foregroundColor(statusColor)
            .overlay(
                Capsule()
                    .stroke(statusColor.opacity(0.4), lineWidth: 1)
            )
    }
    
    private var progressRing: some View {
        let status = bracketEngine.getBracketStatus(tournament: tournament)
        
        return ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                .frame(width: 32, height: 32)
            
            Circle()
                .trim(from: 0, to: status.overallProgress)
                .stroke(statusColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: status.overallProgress)
            
            Text("\(Int(status.overallProgress * 100))")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        switch tournament.status {
        case "Upcoming": return .blue
        case "Registration Open": return .green
        case "Registration Closed": return .orange
        case "In Progress": return .purple
        case "Completed": return .gray
        case "Cancelled": return .red
        default: return .gray
        }
    }
    
    private func statCard(title: String, value: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            
            Text(value)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tournament Card Skeleton

struct TournamentCardSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Rectangle()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(height: 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Rectangle()
                        .fill(Color(uiColor: .systemGray5))
                        .frame(height: 16)
                        .frame(width: 120)
                }
                
                Spacer()
                
                Circle()
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 40, height: 40)
            }
            
            Rectangle()
                .fill(Color(uiColor: .systemGray5))
                .frame(height: 40)
                
            HStack {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color(uiColor: .systemGray5))
                            .frame(width: 20, height: 20)
                        
                        Rectangle()
                            .fill(Color(uiColor: .systemGray5))
                            .frame(height: 12)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .opacity(isAnimating ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Extensions
// Note: Int.ordinal extension is defined in TournamentService.swift

// MARK: - Enhanced Create Tournament View

struct CreateTournamentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    let tournamentService: TournamentService?
    @StateObject private var bracketEngine = BracketEngine()
    
    @State private var currentStep = 0
    @State private var name = ""
    @State private var description = ""
    @State private var tournamentType: TournamentType = .doubleElimination
    @State private var format: TournamentFormat = .doubles
    @State private var skillLevel: String = "Intermediate"
    @State private var maxParticipants = 16
    @State private var startDate = Date().addingTimeInterval(86400) // Tomorrow
    @State private var venueName = ""
    @State private var venueAddress = ""
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let totalSteps = 4
    private let participantOptions = [8, 16, 32, 64]
    private let skillLevelOptions = ["Beginner", "Intermediate", "Advanced", "Expert", "Open"]
    
    var progress: Double {
        Double(currentStep + 1) / Double(totalSteps)
    }
    
    var canProceed: Bool {
        switch currentStep {
        case 0: return !name.isEmpty
        case 1: return true // Format selection always valid
        case 2: return true // Schedule always valid  
        case 3: return !venueName.isEmpty
        default: return false
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground).opacity(0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress header
                    progressHeader
                    
                    // Content area
                    ScrollView {
                        VStack(spacing: 32) {
                            stepContent
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                    }
                    
                    // Navigation footer
                    navigationFooter
                }
            }
            .navigationTitle("New Tournament")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: 16) {
            // Progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("Step \(currentStep + 1) of \(totalSteps)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.brown)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color(uiColor: .quaternaryLabel).opacity(0.3))
                            .frame(height: 6)
                            .clipShape(Capsule())
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.brown, .brown.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progress, height: 6)
                            .clipShape(Capsule())
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 6)
            }
            
            // Step indicators
            HStack(spacing: 0) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(step <= currentStep ? .brown : Color(uiColor: .quaternaryLabel).opacity(0.3))
                            .frame(width: 12, height: 12)
                            .scaleEffect(step == currentStep ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                        
                        if step < totalSteps - 1 {
                            Rectangle()
                                .fill(Color(uiColor: .quaternaryLabel).opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            tournamentDetailsStep
        case 1:
            formatSelectionStep
        case 2:
            scheduleStep
        case 3:
            venueStep
        default:
            EmptyView()
        }
    }
    
    // Step 1: Tournament Details
    private var tournamentDetailsStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "Tournament Details",
                subtitle: "Let's start with the basics",
                icon: "info.circle.fill",
                color: .blue
            )
            
            VStack(spacing: 20) {
                FloatingTextField(
                    title: "Tournament Name",
                    text: $name,
                    placeholder: "Enter tournament name"
                )
                
                FloatingTextEditor(
                    title: "Description (Optional)",
                    text: $description,
                    placeholder: "Describe your tournament..."
                )
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // Step 2: Format Selection
    private var formatSelectionStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "Tournament Format",
                subtitle: "Choose how the tournament will be structured",
                icon: "list.bullet.circle.fill",
                color: .green
            )
            
            VStack(spacing: 20) {
                SelectionCard(
                    title: "Tournament Type",
                    options: TournamentType.allCases.map { $0.rawValue },
                    selectedIndex: TournamentType.allCases.firstIndex(of: tournamentType) ?? 0
                ) { index in
                    tournamentType = TournamentType.allCases[index]
                }
                
                SelectionCard(
                    title: "Match Format",
                    options: TournamentFormat.allCases.map { $0.rawValue },
                    selectedIndex: TournamentFormat.allCases.firstIndex(of: format) ?? 0
                ) { index in
                    format = TournamentFormat.allCases[index]
                }
                
                SelectionCard(
                    title: "Skill Level",
                    options: skillLevelOptions,
                    selectedIndex: skillLevelOptions.firstIndex(of: skillLevel) ?? 1
                ) { index in
                    skillLevel = skillLevelOptions[index]
                }
                
                SelectionCard(
                    title: "Max Participants",
                    options: participantOptions.map { "\($0) players" },
                    selectedIndex: participantOptions.firstIndex(of: maxParticipants) ?? 1
                ) { index in
                    maxParticipants = participantOptions[index]
                }
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // Step 3: Schedule
    private var scheduleStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "Schedule",
                subtitle: "When will the tournament take place?",
                icon: "calendar.circle.fill",
                color: .orange
            )
            
            VStack(spacing: 20) {
                DateSelectionCard(
                    title: "Start Date & Time",
                    date: $startDate
                )
                
                // Tournament duration estimate
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        
                        Text("Estimated Duration")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(estimatedDuration)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Duration depends on number of participants and match length")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // Step 4: Venue
    private var venueStep: some View {
        VStack(spacing: 24) {
            stepHeader(
                title: "Venue Information", 
                subtitle: "Where will the tournament be held?",
                icon: "location.circle.fill",
                color: .purple
            )
            
            VStack(spacing: 20) {
                FloatingTextField(
                    title: "Venue Name",
                    text: $venueName,
                    placeholder: "Enter venue name"
                )
                
                FloatingTextField(
                    title: "Address (Optional)",
                    text: $venueAddress,
                    placeholder: "Enter venue address"
                )
                
                // Tournament summary
                TournamentSummaryCard(
                    name: name,
                    type: tournamentType.rawValue,
                    format: format.rawValue,
                    participants: maxParticipants,
                    startDate: startDate,
                    venueName: venueName
                )
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
    }
    
    // MARK: - Navigation Footer
    
    private var navigationFooter: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            currentStep -= 1
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.caption)
                            Text("Back")
                        }
                        .foregroundColor(.brown)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(Capsule())
                    }
                    .transition(.move(edge: .leading))
                }
                
                Spacer()
                
                if currentStep < totalSteps - 1 {
                    Button {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            currentStep += 1
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text("Next")
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: canProceed ? [.brown, .brown.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .brown.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .disabled(!canProceed)
                    .scaleEffect(canProceed ? 1.0 : 0.95)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canProceed)
                } else {
                    Button {
                        createTournament()
                    } label: {
                        HStack(spacing: 12) {
                            if isCreating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                            }
                            
                            Text(isCreating ? "Creating..." : "Create Tournament")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: canProceed && !isCreating ? [.green, .green.opacity(0.8)] : [.gray, .gray.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(!canProceed || isCreating)
                    .scaleEffect(canProceed && !isCreating ? 1.05 : 0.95)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canProceed)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCreating)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Helper Views
    
    private func stepHeader(title: String, subtitle: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40, weight: .light))
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, 8)
    }
    
    private var estimatedDuration: String {
        let matchesCount = bracketEngine.calculateTotalMatches(participants: maxParticipants, type: tournamentType)
        let averageMatchTime = 30 // minutes
        let totalMinutes = matchesCount * averageMatchTime
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Create Tournament
    
    private func createTournament() {
        guard let service = tournamentService else { return }
        
        isCreating = true
        
        Task {
            do {
                _ = try await service.createTournament(
                    name: name,
                    description: description,
                    type: tournamentType.rawValue,
                    format: format.rawValue,
                    skillLevel: skillLevel,
                    maxParticipants: maxParticipants,
                    startDate: startDate,
                    organizerID: appState.currentUser?.id.uuidString ?? "unknown",
                    organizerName: appState.currentUser?.displayName ?? "Tournament Organizer"
                )
                
                await MainActor.run {
                    isCreating = false
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct FloatingTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(16)
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(uiColor: .quaternaryLabel).opacity(0.3), lineWidth: 1)
                )
        }
    }
}

struct FloatingTextEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                }
                
                TextEditor(text: $text)
                    .frame(minHeight: 80)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 12)
            }
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(uiColor: .quaternaryLabel).opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct SelectionCard: View {
    let title: String
    let options: [String]
    let selectedIndex: Int
    let onSelection: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                        Button {
                            onSelection(index)
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Text(option)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(index == selectedIndex ? .brown : Color(uiColor: .systemBackground))
                                )
                                .foregroundColor(index == selectedIndex ? .white : .primary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(index == selectedIndex ? .brown : .clear, lineWidth: 1)
                                )
                        }
                        .scaleEffect(index == selectedIndex ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

struct DateSelectionCard: View {
    let title: String
    @Binding var date: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            DatePicker(
                "",
                selection: $date,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .padding(16)
            .background(Color(uiColor: .systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct TournamentSummaryCard: View {
    let name: String
    let type: String
    let format: String
    let participants: Int
    let startDate: Date
    let venueName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.brown)
                
                Text("Tournament Summary")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            VStack(spacing: 8) {
                summaryRow(title: "Name", value: name.isEmpty ? "Tournament Name" : name)
                summaryRow(title: "Type", value: type)
                summaryRow(title: "Format", value: format)
                summaryRow(title: "Participants", value: "\(participants) players")
                summaryRow(title: "Date", value: startDate.formatted(date: .abbreviated, time: .shortened))
                summaryRow(title: "Venue", value: venueName.isEmpty ? "Venue Name" : venueName)
            }
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.brown.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Tournament Analytics View

struct TournamentAnalyticsView: View {
    let totalTournaments: Int
    let activeTournaments: Int
    let myTournaments: Int
    let completionRate: Double
    let tournaments: [Tournament]
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview Cards
                    overviewSection
                    
                    // Status Distribution
                    statusDistributionSection
                    
                    // Recent Activity
                    recentActivitySection
                    
                    // Performance Metrics
                    performanceSection
                }
                .padding()
            }
            .navigationTitle("Tournament Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var overviewSection: some View {
        VStack(spacing: 16) {
            Text("Overview")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                AnalyticsCard(
                    title: "Total Tournaments",
                    value: "\(totalTournaments)",
                    icon: "trophy.fill",
                    color: .blue
                )
                
                AnalyticsCard(
                    title: "Active Now",
                    value: "\(activeTournaments)",
                    icon: "play.circle.fill",
                    color: .green
                )
                
                AnalyticsCard(
                    title: "My Tournaments",
                    value: "\(myTournaments)",
                    icon: "person.circle.fill",
                    color: .purple
                )
                
                AnalyticsCard(
                    title: "Completion Rate",
                    value: "\(Int(completionRate * 100))%",
                    icon: "checkmark.circle.fill",
                    color: .orange
                )
            }
        }
    }
    
    private var statusDistributionSection: some View {
        VStack(spacing: 16) {
            Text("Status Distribution")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(statusCounts, id: \.status) { statusCount in
                    StatusBar(
                        status: statusCount.status,
                        count: statusCount.count,
                        total: totalTournaments,
                        color: statusCount.color
                    )
                }
            }
        }
    }
    
    private var recentActivitySection: some View {
        VStack(spacing: 16) {
            Text("Recent Activity")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(recentTournaments, id: \.id) { tournament in
                    RecentActivityCard(tournament: tournament)
                }
            }
        }
    }
    
    private var performanceSection: some View {
        VStack(spacing: 16) {
            Text("Performance Metrics")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 16) {
                MetricRow(
                    title: "Average Participants",
                    value: String(format: "%.1f", averageParticipants),
                    icon: "person.2.fill"
                )
                
                MetricRow(
                    title: "Most Popular Format",
                    value: mostPopularFormat,
                    icon: "sportscourt.fill"
                )
                
                MetricRow(
                    title: "Upcoming This Week",
                    value: "\(upcomingThisWeek)",
                    icon: "calendar.circle.fill"
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusCounts: [(status: String, count: Int, color: Color)] {
        let statuses = ["Registration Open", "In Progress", "Completed", "Upcoming", "Cancelled"]
        return statuses.map { status in
            let count = tournaments.filter { $0.status == status }.count
            let color: Color = {
                switch status {
                case "Registration Open": return .green
                case "In Progress": return .blue
                case "Completed": return .gray
                case "Upcoming": return .orange
                case "Cancelled": return .red
                default: return .gray
                }
            }()
            return (status, count, color)
        }.filter { $0.count > 0 }
    }
    
    private var recentTournaments: [Tournament] {
        tournaments
            .sorted { $0.startDate > $1.startDate }
            .prefix(5)
            .map { $0 }
    }
    
    private var averageParticipants: Double {
        guard !tournaments.isEmpty else { return 0 }
        let total = tournaments.reduce(0) { $0 + $1.participants.count }
        return Double(total) / Double(tournaments.count)
    }
    
    private var mostPopularFormat: String {
        let formatCounts = Dictionary(grouping: tournaments, by: \.format)
            .mapValues { $0.count }
        return formatCounts.max(by: { $0.value < $1.value })?.key ?? "N/A"
    }
    
    private var upcomingThisWeek: Int {
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        return tournaments.filter { tournament in
            tournament.startDate >= Date() && tournament.startDate <= weekFromNow
        }.count
    }
}

// MARK: - Analytics Supporting Views

struct AnalyticsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

struct StatusBar: View {
    let status: String
    let count: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(status)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 8)
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.8), value: percentage)
                }
            }
            .frame(height: 8)
        }
    }
}

struct RecentActivityCard: View {
    let tournament: Tournament
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(tournament.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(tournament.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(tournament.status)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(statusColor.opacity(0.2))
                    )
                    .foregroundColor(statusColor)
                
                Text("\(tournament.participants.count) players")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(0.05))
        )
    }
    
    private var statusColor: Color {
        switch tournament.status {
        case "Registration Open": return .green
        case "In Progress": return .blue
        case "Completed": return .gray
        case "Upcoming": return .orange
        case "Cancelled": return .red
        default: return .gray
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.blue.opacity(0.05))
        )
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, configurations: config)
    
    let appState = AppState()
    
    TournamentManagerView()
        .modelContainer(container)
        .environmentObject(appState)
} 