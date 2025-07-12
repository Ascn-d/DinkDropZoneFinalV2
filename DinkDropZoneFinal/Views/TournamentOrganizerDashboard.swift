import SwiftUI
import Charts
import SwiftData

struct TournamentOrganizerDashboard: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    let tournament: Tournament
    
    // Dashboard State
    @State private var selectedTab: OrganizerTab = .overview
    @State private var tournamentStats = TournamentOrganizerStats()
    @State private var recentActivity: [OrganizerActivity] = []
    @State private var isLoading = false
    @State private var showingSettings = false
    @State private var showingParticipantManager = false
    @State private var showingMessageComposer = false
    @State private var showingPrizeManager = false
    @State private var showingAnalytics = false
    @State private var lastUpdateTime = Date()
    
    // Real-time Updates
    @State private var refreshTimer: Timer?
    @State private var tournamentListener: FirebaseService.ListenerHandle?
    
    // Notifications & Alerts
    @State private var pendingNotifications: [OrganizerNotification] = []
    @State private var showingNotificationCenter = false
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    // Quick Actions
    @State private var quickActionButtons: [QuickAction] = []
    @State private var showingQuickActionSheet = false
    @State private var selectedQuickAction: QuickAction?
    
    private let dashboardTabs: [OrganizerTab] = [.overview, .participants, .matches, .analytics, .settings]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tournament Header with Status
                    tournamentStatusHeader
                    
                    // Quick Action Bar
                    quickActionBar
                    
                    // Tab Selection
                    tabSelector
                    
                    // Main Content
                    TabView(selection: $selectedTab) {
                        // Overview Tab
                        overviewTab
                            .tag(OrganizerTab.overview)
                        
                        // Participants Tab
                        participantsTab
                            .tag(OrganizerTab.participants)
                        
                        // Matches Tab
                        matchesTab
                            .tag(OrganizerTab.matches)
                        
                        // Analytics Tab
                        analyticsTab
                            .tag(OrganizerTab.analytics)
                        
                        // Settings Tab
                        settingsTab
                            .tag(OrganizerTab.settings)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingActionButton
                            .padding(.trailing, 24)
                            .padding(.bottom, 24)
                    }
                }
                
                // Loading Overlay
                if isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("Tournament Control")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: backButton,
                trailing: HStack {
                    notificationButton
                    menuButton
                }
            )
            .onAppear {
                setupDashboard()
            }
            .onDisappear {
                cleanupDashboard()
            }
            .refreshable {
                await refreshDashboard()
            }
        }
        .sheet(isPresented: $showingSettings) {
            TournamentOrganizerSettings(tournament: tournament)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingParticipantManager) {
            TournamentParticipantManager(tournament: tournament)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingMessageComposer) {
            TournamentMessageComposer(tournament: tournament)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingPrizeManager) {
            TournamentPrizeManager(tournament: tournament)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingAnalytics) {
            TournamentAnalyticsView(tournament: tournament)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingNotificationCenter) {
            OrganizerNotificationCenter(notifications: $pendingNotifications)
        }
        .actionSheet(isPresented: $showingQuickActionSheet) {
            ActionSheet(
                title: Text("Quick Actions"),
                message: Text("Choose an action for your tournament"),
                buttons: quickActionButtons.map { action in
                    .default(Text(action.title)) {
                        executeQuickAction(action)
                    }
                } + [.cancel()]
            )
        }
        .alert("Tournament Update", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Tournament Status Header
    
    private var tournamentStatusHeader: some View {
        VStack(spacing: 12) {
            // Tournament Title & Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tournament.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        statusBadge
                        lastUpdateIndicator
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Next Action")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(getNextActionText())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.accentColor)
                }
            }
            
            // Key Metrics Row
            HStack(spacing: 20) {
                metricCard(
                    title: "Participants",
                    value: "\(tournament.participants.count)/\(tournament.maxParticipants)",
                    color: getParticipantColor(),
                    icon: "person.2.fill"
                )
                
                metricCard(
                    title: "Matches",
                    value: "\(tournamentStats.completedMatches)/\(tournamentStats.totalMatches)",
                    color: getMatchColor(),
                    icon: "gamecontroller.fill"
                )
                
                metricCard(
                    title: "Revenue",
                    value: "$\(Int(tournamentStats.totalRevenue))",
                    color: .green,
                    icon: "dollarsign.circle.fill"
                )
                
                metricCard(
                    title: "Duration",
                    value: formatDuration(tournamentStats.estimatedDuration),
                    color: .blue,
                    icon: "clock.fill"
                )
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(getStatusColor())
                .frame(width: 8, height: 8)
            
            Text(tournament.status.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(getStatusColor())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(getStatusColor().opacity(0.1))
        .cornerRadius(8)
    }
    
    private var lastUpdateIndicator: some View {
        Text("Updated \(formatRelativeTime(lastUpdateTime))")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    
    private func metricCard(title: String, value: String, color: Color, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Quick Action Bar
    
    private var quickActionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(getQuickActions(), id: \.id) { action in
                    quickActionButton(action)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private func quickActionButton(_ action: QuickAction) -> some View {
        Button(action: {
            executeQuickAction(action)
        }) {
            HStack(spacing: 8) {
                Image(systemName: action.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(action.title)
                    .font(.system(size: 14, weight: .medium))
                
                if let badge = action.badge {
                    Text(badge)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(action.color.opacity(0.1))
            .foregroundColor(action.color)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(dashboardTabs, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal)
        .background(.regularMaterial)
    }
    
    private func tabButton(for tab: OrganizerTab) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = tab
            }
        }) {
            tabButtonContent(for: tab)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func tabButtonContent(for tab: OrganizerTab) -> some View {
        VStack(spacing: 8) {
            tabHeaderView(for: tab)
            
            Rectangle()
                .fill(selectedTab == tab ? Color.accentColor : .clear)
                .frame(height: 2)
        }
    }
    
    private func tabHeaderView(for tab: OrganizerTab) -> some View {
        HStack(spacing: 4) {
            Image(systemName: tab.icon)
                .font(.system(size: 14, weight: .medium))
            
            Text(tab.title)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(selectedTab == tab ? Color.accentColor : .secondary)
    }
    
    // MARK: - Overview Tab
    
    private var overviewTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Tournament Progress Section
                tournamentProgressSection
                
                // Recent Activity Section
                recentActivitySection
                
                // Pending Actions Section
                pendingActionsSection
                
                // Tournament Health Section
                tournamentHealthSection
                
                // Quick Stats Section
                quickStatsSection
            }
            .padding()
        }
    }
    
    private var tournamentProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournament Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Progress Visualization
            VStack(spacing: 12) {
                // Registration Progress
                progressBar(
                    title: "Registration",
                    current: tournament.participants.count,
                    total: tournament.maxParticipants,
                    color: .blue
                )
                
                // Match Progress
                progressBar(
                    title: "Matches",
                    current: tournamentStats.completedMatches,
                    total: tournamentStats.totalMatches,
                    color: .green
                )
                
                // Timeline Progress
                progressBar(
                    title: "Timeline",
                    current: getCurrentTimelineProgress(),
                    total: 100,
                    color: .orange,
                    isPercentage: true
                )
            }
            
            // Tournament Timeline
            tournamentTimeline
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    private func progressBar(title: String, current: Int, total: Int, color: Color, isPercentage: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(isPercentage ? "\(current)%" : "\(current)/\(total)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            
            ProgressView(value: Double(current), total: Double(total))
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 1.5)
        }
    }
    
    private var tournamentTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tournament Timeline")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                timelineItem(
                    title: "Registration Opens",
                    date: tournament.startDate.addingTimeInterval(-86400 * 7), // 7 days before
                    isCompleted: true,
                    isCurrent: false
                )
                
                timelineItem(
                    title: "Tournament Starts",
                    date: tournament.startDate,
                    isCompleted: tournament.status == "In Progress" || tournament.status == "Completed",
                    isCurrent: tournament.status == "In Progress"
                )
                
                timelineItem(
                    title: "Finals",
                    date: tournament.endDate,
                    isCompleted: tournament.status == "Completed",
                    isCurrent: false
                )
            }
        }
    }
    
    private func timelineItem(title: String, date: Date, isCompleted: Bool, isCurrent: Bool) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(isCompleted ? .green : isCurrent ? .blue : .secondary)
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isCurrent {
                Text("NOW")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }
    
    // MARK: - Recent Activity Section
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("View All") {
                    // Show full activity log
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            if recentActivity.isEmpty {
                emptyActivityView
            } else {
                VStack(spacing: 12) {
                    ForEach(recentActivity.prefix(5), id: \.id) { activity in
                        activityRow(activity)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    private var emptyActivityView: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            Text("No recent activity")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private func activityRow(_ activity: OrganizerActivity) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activity.type.color)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(formatRelativeTime(activity.timestamp))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Remaining Tab Content (Placeholder for now)
    
    private var participantsTab: some View {
        Text("Participants Management")
            .font(.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
    
    private var matchesTab: some View {
        Text("Matches Management")
            .font(.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
    
    private var analyticsTab: some View {
        Text("Tournament Analytics")
            .font(.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
    
    private var settingsTab: some View {
        Text("Tournament Settings")
            .font(.title)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
    }
    
    // MARK: - Supporting Views
    
    private var pendingActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pending Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(getPendingActions(), id: \.id) { action in
                    pendingActionRow(action)
                }
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    private func pendingActionRow(_ action: PendingAction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: action.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(action.priority.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(action.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action.buttonTitle) {
                executePendingAction(action)
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(action.priority.color.opacity(0.1))
            .foregroundColor(action.priority.color)
            .cornerRadius(6)
        }
        .padding(.vertical, 8)
    }
    
    private var tournamentHealthSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tournament Health")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 20) {
                healthIndicator(
                    title: "Participation",
                    value: getParticipationHealth(),
                    color: getParticipationHealthColor()
                )
                
                healthIndicator(
                    title: "Engagement",
                    value: getEngagementHealth(),
                    color: getEngagementHealthColor()
                )
                
                healthIndicator(
                    title: "Schedule",
                    value: getScheduleHealth(),
                    color: getScheduleHealthColor()
                )
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    private func healthIndicator(title: String, value: Int, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: Double(value) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(value)%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                statCard(
                    title: "Average Rating",
                    value: String(format: "%.1f", tournamentStats.averageRating),
                    icon: "star.fill",
                    color: .yellow
                )
                
                statCard(
                    title: "Match Duration",
                    value: "\(tournamentStats.averageMatchDuration)min",
                    icon: "clock.fill",
                    color: .blue
                )
                
                statCard(
                    title: "No-Shows",
                    value: "\(tournamentStats.noShows)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
                
                statCard(
                    title: "Spectators",
                    value: "\(tournamentStats.spectators)",
                    icon: "eye.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(16)
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
                
                Spacer()
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Navigation & UI Elements
    
    private var backButton: some View {
        Button("Close") {
            dismiss()
        }
    }
    
    private var notificationButton: some View {
        Button(action: {
            showingNotificationCenter = true
        }) {
            ZStack {
                Image(systemName: "bell.fill")
                    .font(.system(size: 18))
                
                if pendingNotifications.count > 0 {
                    Text("\(pendingNotifications.count)")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(.red)
                        .clipShape(Circle())
                        .offset(x: 8, y: -8)
                }
            }
        }
    }
    
    private var menuButton: some View {
        Button(action: {
            showingQuickActionSheet = true
        }) {
            Image(systemName: "ellipsis.circle.fill")
                .font(.system(size: 18))
        }
    }
    
    private var floatingActionButton: some View {
        Button(action: {
            // Primary action based on tournament status
            executePrimaryAction()
        }) {
            Image(systemName: getPrimaryActionIcon())
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
    }
    
    private var loadingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    
                    Text("Updating Tournament...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            )
    }
    
    // MARK: - Helper Methods
    
    private func setupDashboard() {
        Task {
            await loadDashboardData()
            startRealTimeUpdates()
        }
    }
    
    private func cleanupDashboard() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        tournamentListener?.remove()
        tournamentListener = nil
    }
    
    private func loadDashboardData() async {
        isLoading = true
        
        // Load tournament stats
        await loadTournamentStats()
        
        // Load recent activity
        await loadRecentActivity()
        
        // Load notifications
        await loadNotifications()
        
        isLoading = false
    }
    
    private func loadTournamentStats() async {
        // Calculate tournament statistics
        let participants = tournament.participants
        let matches = tournament.matches
        
        tournamentStats = TournamentOrganizerStats(
            totalParticipants: participants.count,
            completedMatches: matches.filter { $0.status == "Completed" }.count,
            totalMatches: matches.count,
            totalRevenue: Double(participants.count) * tournament.entryFee,
            averageRating: participants.map { $0.elo }.reduce(0, +) / max(participants.count, 1),
            averageMatchDuration: 45, // Calculate from actual match data
            noShows: participants.filter { $0.status == "No Show" }.count,
            spectators: 0, // Would come from analytics
            estimatedDuration: calculateEstimatedDuration()
        )
    }
    
    private func loadRecentActivity() async {
        // Load recent tournament activity
        recentActivity = [
            OrganizerActivity(
                type: .registration,
                title: "New Registration",
                description: "John Doe joined the tournament",
                timestamp: Date().addingTimeInterval(-300)
            ),
            OrganizerActivity(
                type: .matchComplete,
                title: "Match Completed",
                description: "Quarter-final match finished",
                timestamp: Date().addingTimeInterval(-900)
            )
        ]
    }
    
    private func loadNotifications() async {
        // Load pending notifications
        pendingNotifications = [
            OrganizerNotification(
                type: .actionRequired,
                title: "Match Needs Referee",
                message: "Semi-final match requires a referee assignment",
                timestamp: Date().addingTimeInterval(-600)
            )
        ]
    }
    
    private func startRealTimeUpdates() {
        // Start real-time updates
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task {
                await refreshDashboard()
            }
        }
    }
    
    private func refreshDashboard() async {
        lastUpdateTime = Date()
        await loadDashboardData()
    }
    
    private func getQuickActions() -> [QuickAction] {
        var actions: [QuickAction] = []
        
        switch tournament.status {
        case "Registration Open":
            actions.append(QuickAction(
                id: "close-registration",
                title: "Close Registration",
                icon: "person.crop.circle.fill.badge.minus",
                color: .orange
            ))
            
        case "Registration Closed":
            actions.append(QuickAction(
                id: "start-tournament",
                title: "Start Tournament",
                icon: "play.fill",
                color: .green
            ))
            
        case "In Progress":
            actions.append(QuickAction(
                id: "manage-matches",
                title: "Manage Matches",
                icon: "gamecontroller.fill",
                color: .blue
            ))
            
        default:
            break
        }
        
        // Always available actions
        actions.append(contentsOf: [
            QuickAction(
                id: "message-participants",
                title: "Message All",
                icon: "message.fill",
                color: .blue,
                badge: pendingNotifications.count > 0 ? "\(pendingNotifications.count)" : nil
            ),
            QuickAction(
                id: "view-bracket",
                title: "View Bracket",
                icon: "list.bullet.rectangle",
                color: .purple
            ),
            QuickAction(
                id: "tournament-settings",
                title: "Settings",
                icon: "gear.circle.fill",
                color: .gray
            )
        ])
        
        return actions
    }
    
    private func executeQuickAction(_ action: QuickAction) {
        switch action.id {
        case "close-registration":
            closeRegistration()
        case "start-tournament":
            startTournament()
        case "manage-matches":
            selectedTab = .matches
        case "message-participants":
            showingMessageComposer = true
        case "view-bracket":
            // Navigate to bracket view
            break
        case "tournament-settings":
            showingSettings = true
        default:
            break
        }
    }
    
    private func executePrimaryAction() {
        switch tournament.status {
        case "Registration Open":
            closeRegistration()
        case "Registration Closed":
            startTournament()
        case "In Progress":
            selectedTab = .matches
        default:
            showingSettings = true
        }
    }
    
    private func closeRegistration() {
        // Implement registration closure
        alertMessage = "Registration has been closed for this tournament."
        showingAlert = true
    }
    
    private func startTournament() {
        // Implement tournament start
        alertMessage = "Tournament has been started!"
        showingAlert = true
    }
    
    private func getPendingActions() -> [PendingAction] {
        var actions: [PendingAction] = []
        
        if tournament.participants.count < 4 {
            actions.append(PendingAction(
                id: "need-participants",
                title: "Need More Participants",
                description: "Tournament needs at least 4 participants to start",
                priority: .high,
                buttonTitle: "Invite"
            ))
        }
        
        return actions
    }
    
    private func executePendingAction(_ action: PendingAction) {
        switch action.id {
        case "need-participants":
            // Open invitation flow
            break
        default:
            break
        }
    }
    
    // MARK: - Helper Functions
    
    private func getStatusColor() -> Color {
        switch tournament.status {
        case "Registration Open": return .blue
        case "Registration Closed": return .orange
        case "In Progress": return .green
        case "Completed": return .purple
        default: return .gray
        }
    }
    
    private func getParticipantColor() -> Color {
        let percentage = Double(tournament.participants.count) / Double(tournament.maxParticipants)
        if percentage < 0.3 { return .red }
        if percentage < 0.7 { return .orange }
        return .green
    }
    
    private func getMatchColor() -> Color {
        let percentage = Double(tournamentStats.completedMatches) / Double(max(tournamentStats.totalMatches, 1))
        if percentage < 0.3 { return .red }
        if percentage < 0.7 { return .orange }
        return .green
    }
    
    private func getNextActionText() -> String {
        switch tournament.status {
        case "Registration Open":
            return "Close Registration"
        case "Registration Closed":
            return "Start Tournament"
        case "In Progress":
            return "Manage Matches"
        case "Completed":
            return "View Results"
        default:
            return "Setup Tournament"
        }
    }
    
    private func getCurrentTimelineProgress() -> Int {
        let now = Date()
        let start = tournament.startDate
        let end = tournament.endDate
        
        let total = end.timeIntervalSince(start)
        let elapsed = now.timeIntervalSince(start)
        
        return Int((elapsed / total) * 100).clamped(to: 0...100)
    }
    
    private func calculateEstimatedDuration() -> TimeInterval {
        // Calculate based on tournament format and participants
        let baseTime = 2.0 // 2 hours base
        let additionalTime = Double(tournament.participants.count) * 0.1 // 0.1 hour per participant
        return baseTime + additionalTime
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration)
        let minutes = Int((duration - Double(hours)) * 60)
        return "\(hours)h \(minutes)m"
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func getParticipationHealth() -> Int {
        let percentage = Double(tournament.participants.count) / Double(tournament.maxParticipants)
        return Int(percentage * 100)
    }
    
    private func getParticipationHealthColor() -> Color {
        let health = getParticipationHealth()
        if health < 50 { return .red }
        if health < 80 { return .orange }
        return .green
    }
    
    private func getEngagementHealth() -> Int {
        // Calculate based on participant activity, match completion rate, etc.
        return 85 // Placeholder
    }
    
    private func getEngagementHealthColor() -> Color {
        let health = getEngagementHealth()
        if health < 50 { return .red }
        if health < 80 { return .orange }
        return .green
    }
    
    private func getScheduleHealth() -> Int {
        // Calculate based on match scheduling, delays, etc.
        return 92 // Placeholder
    }
    
    private func getScheduleHealthColor() -> Color {
        let health = getScheduleHealth()
        if health < 50 { return .red }
        if health < 80 { return .orange }
        return .green
    }
    
    private func getPrimaryActionIcon() -> String {
        switch tournament.status {
        case "Registration Open": return "person.crop.circle.fill.badge.minus"
        case "Registration Closed": return "play.fill"
        case "In Progress": return "gamecontroller.fill"
        default: return "gear.circle.fill"
        }
    }
}

// MARK: - Supporting Types

enum OrganizerTab: String, CaseIterable {
    case overview = "Overview"
    case participants = "Participants"
    case matches = "Matches"
    case analytics = "Analytics"
    case settings = "Settings"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "chart.bar.fill"
        case .participants: return "person.2.fill"
        case .matches: return "gamecontroller.fill"
        case .analytics: return "chart.line.uptrend.xyaxis"
        case .settings: return "gear.circle.fill"
        }
    }
}

struct TournamentOrganizerStats {
    var totalParticipants: Int = 0
    var completedMatches: Int = 0
    var totalMatches: Int = 0
    var totalRevenue: Double = 0
    var averageRating: Int = 0
    var averageMatchDuration: Int = 45
    var noShows: Int = 0
    var spectators: Int = 0
    var estimatedDuration: TimeInterval = 0
}

struct OrganizerActivity {
    let id = UUID()
    let type: ActivityType
    let title: String
    let description: String
    let timestamp: Date
    
    enum ActivityType {
        case registration, matchComplete, matchStart, announcement, settings
        
        var color: Color {
            switch self {
            case .registration: return .blue
            case .matchComplete: return .green
            case .matchStart: return .orange
            case .announcement: return .purple
            case .settings: return .gray
            }
        }
    }
}

struct OrganizerNotification {
    let id = UUID()
    let type: NotificationType
    let title: String
    let message: String
    let timestamp: Date
    
    enum NotificationType {
        case actionRequired, info, warning, error
        
        var color: Color {
            switch self {
            case .actionRequired: return .red
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            }
        }
    }
}

struct QuickAction {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let badge: String?
    
    init(id: String, title: String, icon: String, color: Color, badge: String? = nil) {
        self.id = id
        self.title = title
        self.icon = icon
        self.color = color
        self.badge = badge
    }
}

struct PendingAction {
    let id: String
    let title: String
    let description: String
    let priority: Priority
    let buttonTitle: String
    
    enum Priority {
        case low, medium, high, urgent
        
        var color: Color {
            switch self {
            case .low: return .gray
            case .medium: return .blue
            case .high: return .orange
            case .urgent: return .red
            }
        }
    }
    
    var icon: String {
        switch priority {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .urgent: return "exclamationmark.octagon.fill"
        }
    }
}

// MARK: - Extension for Clamping Values

extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Preview

struct TournamentOrganizerDashboard_Previews: PreviewProvider {
    static var previews: some View {
        TournamentOrganizerDashboard(tournament: Tournament.sampleTournament)
            .environmentObject(AppState())
    }
} 