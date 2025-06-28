import Foundation
import SwiftData
import Firebase
import FirebaseAuth
import Combine

// MARK: - Analytics Service for Tournament v2

@MainActor
class AnalyticsService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var tournamentStats: TournamentAnalyticsData = TournamentAnalyticsData()
    @Published var userEngagement: UserEngagementData = UserEngagementData()
    @Published var performanceMetrics: PerformanceMetrics = PerformanceMetrics()
    
    // MARK: - Private Properties
    
    private let userDefaults = UserDefaults.standard
    private let analyticsPrefix = "analytics_"
    private var eventQueue: [AnalyticsEvent] = []
    private let db = Firestore.firestore()
    private var analyticsTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Firebase Analytics Properties
    @Published var realtimeMetrics: RealtimeMetrics = RealtimeMetrics()
    @Published var tournamentInsights: TournamentInsights = TournamentInsights()
    @Published var playerInsights: PlayerInsights = PlayerInsights()
    
    init() {
        loadLocalAnalytics()
        setupFirebaseAnalytics()
        startRealtimeUpdates()
    }
    
    deinit {
        Task { [weak self] in
            await self?.stopRealtimeUpdates()
        }
    }
    
    // MARK: - Tournament Analytics
    
    /// Track tournament creation
    func trackTournamentCreated(
        format: String,
        participantCount: Int,
        skillLevel: String,
        isPublic: Bool
    ) {
        // Update local stats
        tournamentStats.totalTournamentsCreated += 1
        tournamentStats.formatDistribution[format, default: 0] += 1
        saveTournamentStats()
        
        print("📊 Analytics: Tournament created - \(format), \(participantCount) participants")
    }
    
    /// Track tournament registration
    func trackTournamentRegistration(
        tournamentId: String,
        format: String,
        registrationMethod: String,
        timeToRegister: TimeInterval
    ) {
        // Update signup funnel
        tournamentStats.signupFunnel.completed += 1
        tournamentStats.signupFunnel.conversionRate = Double(tournamentStats.signupFunnel.completed) / Double(max(1, tournamentStats.signupFunnel.started))
        saveTournamentStats()
    }
    
    /// Track tournament completion
    func trackTournamentCompleted(
        tournamentId: String,
        format: String,
        participantCount: Int,
        duration: TimeInterval,
        matchCount: Int,
        upsetCount: Int,
        avgMatchDuration: TimeInterval
    ) {
        let upsetRate = Double(upsetCount) / Double(max(1, matchCount))
        
        // Update local metrics
        tournamentStats.totalTournamentsCompleted += 1
        tournamentStats.avgTournamentDuration = (tournamentStats.avgTournamentDuration + duration) / 2
        tournamentStats.avgMatchDuration = (tournamentStats.avgMatchDuration + avgMatchDuration) / 2
        tournamentStats.upsetRate = (tournamentStats.upsetRate + upsetRate) / 2
        saveTournamentStats()
    }
    
    /// Track match completion
    func trackMatchCompleted(
        tournamentId: String,
        matchId: String,
        format: String,
        duration: TimeInterval,
        score: String,
        wasUpset: Bool,
        rallyCount: Int? = nil,
        avgRallyLength: Double? = nil
    ) {
        // Update performance metrics
        performanceMetrics.totalMatches += 1
        performanceMetrics.avgMatchDuration = (performanceMetrics.avgMatchDuration + duration) / 2
        if wasUpset {
            performanceMetrics.upsetCount += 1
        }
        savePerformanceMetrics()
    }
    
    // MARK: - User Engagement Analytics
    
    /// Track screen views
    func trackScreenView(_ screenName: String, parameters: [String: Any] = [:]) {
        // Update engagement
        userEngagement.screenViews[screenName, default: 0] += 1
        userEngagement.totalScreenViews += 1
        saveUserEngagement()
    }
    
    /// Track user actions
    func trackUserAction(
        action: String,
        screen: String,
        parameters: [String: Any] = [:]
    ) {
        userEngagement.totalActions += 1
        saveUserEngagement()
    }
    
    /// Track feature usage
    func trackFeatureUsage(
        feature: String,
        action: String,
        success: Bool,
        parameters: [String: Any] = [:]
    ) {
        if success {
            userEngagement.featureSuccessCount[feature, default: 0] += 1
        } else {
            userEngagement.featureErrorCount[feature, default: 0] += 1
        }
        saveUserEngagement()
    }
    
    // MARK: - Data Retrieval
    
    /// Get tournament statistics
    func getTournamentStatistics() -> TournamentAnalyticsData {
        return tournamentStats
    }
    
    /// Get user engagement data
    func getUserEngagementData() -> UserEngagementData {
        return userEngagement
    }
    
    /// Get performance metrics
    func getPerformanceMetrics() -> PerformanceMetrics {
        return performanceMetrics
    }
    
    // MARK: - Local Storage
    
    private func loadLocalAnalytics() {
        if let tournamentData = userDefaults.data(forKey: analyticsPrefix + "tournament_stats"),
           let decoded = try? JSONDecoder().decode(TournamentAnalyticsData.self, from: tournamentData) {
            tournamentStats = decoded
        }
        
        if let engagementData = userDefaults.data(forKey: analyticsPrefix + "user_engagement"),
           let decoded = try? JSONDecoder().decode(UserEngagementData.self, from: engagementData) {
            userEngagement = decoded
        }
        
        if let performanceData = userDefaults.data(forKey: analyticsPrefix + "performance_metrics"),
           let decoded = try? JSONDecoder().decode(PerformanceMetrics.self, from: performanceData) {
            performanceMetrics = decoded
        }
    }
    
    private func saveTournamentStats() {
        if let encoded = try? JSONEncoder().encode(tournamentStats) {
            userDefaults.set(encoded, forKey: analyticsPrefix + "tournament_stats")
        }
    }
    
    private func saveUserEngagement() {
        if let encoded = try? JSONEncoder().encode(userEngagement) {
            userDefaults.set(encoded, forKey: analyticsPrefix + "user_engagement")
        }
    }
    
    private func savePerformanceMetrics() {
        if let encoded = try? JSONEncoder().encode(performanceMetrics) {
            userDefaults.set(encoded, forKey: analyticsPrefix + "performance_metrics")
        }
    }
    
    // MARK: - Firebase Analytics Integration
    
    private func setupFirebaseAnalytics() {
        // Configure Firebase Analytics
        #if !DEBUG
        Analytics.setAnalyticsCollectionEnabled(true)
        #endif
    }
    
    private func startRealtimeUpdates() {
        analyticsTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                await self.updateRealtimeMetrics()
                await self.syncWithFirebase()
            }
        }
    }
    
    private func stopRealtimeUpdates() {
        analyticsTimer?.invalidate()
        analyticsTimer = nil
    }
    
    /// Enhanced Firebase event tracking
    func trackFirebaseEvent(_ eventName: String, parameters: [String: Any] = [:]) {
        // Track in Firebase
        #if !DEBUG
        Analytics.logEvent(eventName, parameters: parameters)
        #endif
        
        // Store in Firestore for advanced analytics
        let eventData: [String: Any] = [
            "event_name": eventName,
            "parameters": parameters,
            "timestamp": Timestamp(date: Date()),
            "user_id": Auth.auth().currentUser?.uid ?? "anonymous"
        ]
        
        Task {
            do {
                try await db.collection("analytics_events").addDocument(data: eventData)
            } catch {
                print("Failed to store analytics event: \(error)")
            }
        }
        
        print("🔥 Firebase Analytics: \(eventName) - \(parameters)")
    }
    
    /// Generate advanced tournament report
    func generateAdvancedTournamentReport(tournamentId: String) async -> AdvancedTournamentReport? {
        do {
            // Fetch tournament data
            let tournamentDoc = try await db.collection("tournaments").document(tournamentId).getDocument()
            guard tournamentDoc.exists,
                  let tournamentData = tournamentDoc.data() else {
                return nil
            }
            
            // Fetch matches
            let matchesSnapshot = try await db.collection("tournaments")
                .document(tournamentId)
                .collection("matches")
                .getDocuments()
            
            // Fetch participants
            let participantsSnapshot = try await db.collection("tournaments")
                .document(tournamentId)
                .collection("participants")
                .getDocuments()
            
            // Fetch analytics events for this tournament
            let analyticsSnapshot = try await db.collection("analytics_events")
                .whereField("parameters.tournament_id", isEqualTo: tournamentId)
                .order(by: "timestamp")
                .getDocuments()
            
            return generateReport(
                tournamentData: tournamentData,
                matches: matchesSnapshot.documents,
                participants: participantsSnapshot.documents,
                events: analyticsSnapshot.documents
            )
            
        } catch {
            print("Error generating tournament report: \(error)")
            return nil
        }
    }
    
    /// Get player performance analytics
    func getPlayerPerformanceAnalytics(playerId: String, timeframe: AnalyticsTimeframe = .month) async -> PlayerPerformanceAnalytics? {
        let startDate = Date().addingTimeInterval(-timeframe.timeInterval)
        
        do {
            let snapshot = try await db.collection("analytics_events")
                .whereField("parameters.player_id", isEqualTo: playerId)
                .whereField("timestamp", isGreaterThan: Timestamp(date: startDate))
                .order(by: "timestamp")
                .getDocuments()
            
            return analyzePlayerPerformance(from: snapshot.documents)
            
        } catch {
            print("Error fetching player analytics: \(error)")
            return nil
        }
    }
    
    /// Get tournament trends
    func getTournamentTrends(timeframe: AnalyticsTimeframe = .month) async -> TournamentTrendsData {
        let startDate = Date().addingTimeInterval(-timeframe.timeInterval)
        
        do {
            let snapshot = try await db.collection("analytics_events")
                .whereField("event_name", isEqualTo: "tournament_created")
                .whereField("timestamp", isGreaterThan: Timestamp(date: startDate))
                .order(by: "timestamp")
                .getDocuments()
            
            return analyzeTournamentTrends(from: snapshot.documents, timeframe: timeframe)
            
        } catch {
            print("Error fetching tournament trends: \(error)")
            return TournamentTrendsData(
                totalTournaments: 0,
                formatDistribution: [:],
                dailyCreations: [:],
                timeframe: timeframe
            )
        }
    }
    
    /// Get real-time system metrics
    private func updateRealtimeMetrics() async {
        do {
            // Get active tournaments count
            let activeTournamentsSnapshot = try await db.collection("tournaments")
                .whereField("status", isEqualTo: "In Progress")
                .getDocuments()
            
            // Get active users (simplified - would need more sophisticated tracking)
            let recentUsersSnapshot = try await db.collection("analytics_events")
                .whereField("timestamp", isGreaterThan: Timestamp(date: Date().addingTimeInterval(-300))) // Last 5 minutes
                .getDocuments()
            
            let uniqueUsers = Set(recentUsersSnapshot.documents.compactMap { doc in
                doc.data()["user_id"] as? String
            }).count
            
            // Get live matches count
            let liveMatchesSnapshot = try await db.collectionGroup("matches")
                .whereField("status", isEqualTo: "In Progress")
                .getDocuments()
            
            await MainActor.run {
                self.realtimeMetrics = RealtimeMetrics(
                    activeUsers: uniqueUsers,
                    activeTournaments: activeTournamentsSnapshot.count,
                    liveMatches: liveMatchesSnapshot.count,
                    lastUpdated: Date()
                )
            }
            
        } catch {
            print("Error updating realtime metrics: \(error)")
        }
    }
    
    /// Sync local analytics with Firebase
    private func syncWithFirebase() async {
        // Sync tournament stats
        let tournamentStatsData: [String: Any] = [
            "total_tournaments_created": tournamentStats.totalTournamentsCreated,
            "total_tournaments_completed": tournamentStats.totalTournamentsCompleted,
            "format_distribution": tournamentStats.formatDistribution,
            "avg_tournament_duration": tournamentStats.avgTournamentDuration,
            "avg_match_duration": tournamentStats.avgMatchDuration,
            "upset_rate": tournamentStats.upsetRate,
            "completion_rate": tournamentStats.completionRate,
            "last_updated": Timestamp(date: Date())
        ]
        
        do {
            let userId = Auth.auth().currentUser?.uid ?? "anonymous"
            try await db.collection("user_analytics")
                .document(userId)
                .setData(["tournament_stats": tournamentStatsData], merge: true)
        } catch {
            print("Error syncing tournament stats: \(error)")
        }
    }
    
    // MARK: - Data Analysis Methods
    
    private func generateReport(
        tournamentData: [String: Any],
        matches: [QueryDocumentSnapshot],
        participants: [QueryDocumentSnapshot],
        events: [QueryDocumentSnapshot]
    ) -> AdvancedTournamentReport {
        
        let startTime = (tournamentData["startDate"] as? Timestamp)?.dateValue() ?? Date()
        let endTime = (tournamentData["endDate"] as? Timestamp)?.dateValue()
        
        // Analyze matches
        let completedMatches = matches.filter { match in
            (match.data()["status"] as? String) == "Completed"
        }
        
        let totalDuration = endTime?.timeIntervalSince(startTime) ?? 0
        let averageMatchDuration = calculateAverageMatchDuration(from: matches)
        
        // Analyze participation
        let totalParticipants = participants.count
        let maxParticipants = tournamentData["maxParticipants"] as? Int ?? 0
        let participationRate = Double(totalParticipants) / Double(max(1, maxParticipants))
        
        // Analyze engagement from events
        let engagementMetrics = analyzeEngagementMetrics(from: events)
        
        return AdvancedTournamentReport(
            tournamentId: tournamentData["id"] as? String ?? "",
            name: tournamentData["name"] as? String ?? "",
            format: tournamentData["format"] as? String ?? "",
            startDate: startTime,
            endDate: endTime,
            totalParticipants: totalParticipants,
            maxParticipants: maxParticipants,
            participationRate: participationRate,
            totalMatches: matches.count,
            completedMatches: completedMatches.count,
            totalDuration: totalDuration,
            averageMatchDuration: averageMatchDuration,
            engagementMetrics: engagementMetrics,
            generatedAt: Date()
        )
    }
    
    private func analyzePlayerPerformance(from documents: [QueryDocumentSnapshot]) -> PlayerPerformanceAnalytics {
        var wins = 0
        var losses = 0
        var totalMatches = 0
        var totalPoints = 0
        var tournamentCount = 0
        
        for doc in documents {
            let data = doc.data()
            let eventName = data["event_name"] as? String ?? ""
            let parameters = data["parameters"] as? [String: Any] ?? [:]
            
            switch eventName {
            case "match_completed":
                totalMatches += 1
                if let won = parameters["won"] as? Bool {
                    if won { wins += 1 } else { losses += 1 }
                }
                if let points = parameters["points_scored"] as? Int {
                    totalPoints += points
                }
            case "tournament_completed":
                tournamentCount += 1
            default:
                break
            }
        }
        
        let winRate = totalMatches > 0 ? Double(wins) / Double(totalMatches) : 0.0
        let averagePoints = totalMatches > 0 ? Double(totalPoints) / Double(totalMatches) : 0.0
        
        return PlayerPerformanceAnalytics(
            wins: wins,
            losses: losses,
            winRate: winRate,
            totalMatches: totalMatches,
            averagePointsPerMatch: averagePoints,
            tournamentsPlayed: tournamentCount
        )
    }
    
    private func analyzeTournamentTrends(from documents: [QueryDocumentSnapshot], timeframe: AnalyticsTimeframe) -> TournamentTrendsData {
        var formatCounts: [String: Int] = [:]
        var dailyCounts: [String: Int] = [:]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for doc in documents {
            let data = doc.data()
            let parameters = data["parameters"] as? [String: Any] ?? [:]
            let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
            
            // Count formats
            if let format = parameters["format"] as? String {
                formatCounts[format, default: 0] += 1
            }
            
            // Count by day
            let dateString = dateFormatter.string(from: timestamp)
            dailyCounts[dateString, default: 0] += 1
        }
        
        return TournamentTrendsData(
            totalTournaments: documents.count,
            formatDistribution: formatCounts,
            dailyCreations: dailyCounts,
            timeframe: timeframe
        )
    }
    
    private func calculateAverageMatchDuration(from matches: [QueryDocumentSnapshot]) -> TimeInterval {
        let durations = matches.compactMap { match -> TimeInterval? in
            let data = match.data()
            return data["duration"] as? TimeInterval
        }
        
        guard !durations.isEmpty else { return 0 }
        return durations.reduce(0, +) / Double(durations.count)
    }
    
    private func analyzeEngagementMetrics(from events: [QueryDocumentSnapshot]) -> EngagementMetrics {
        var screenViews = 0
        var userActions = 0
        var uniqueUsers = Set<String>()
        
        for doc in events {
            let data = doc.data()
            let eventName = data["event_name"] as? String ?? ""
            
            if let userId = data["user_id"] as? String {
                uniqueUsers.insert(userId)
            }
            
            switch eventName {
            case "screen_view":
                screenViews += 1
            case "user_action":
                userActions += 1
            default:
                break
            }
        }
        
        return EngagementMetrics(
            totalScreenViews: screenViews,
            totalUserActions: userActions,
            uniqueUsers: uniqueUsers.count
        )
    }
}

// MARK: - Analytics Data Models

struct AnalyticsEvent: Codable {
    let name: String
    let parameters: [String: String]
    let timestamp: Date
}

struct TournamentAnalyticsData: Codable {
    var totalTournamentsCreated: Int = 0
    var totalTournamentsCompleted: Int = 0
    var formatDistribution: [String: Int] = [:]
    var avgTournamentDuration: TimeInterval = 0
    var avgMatchDuration: TimeInterval = 0
    var upsetRate: Double = 0
    var signupFunnel: SignupFunnelData = SignupFunnelData()
    var participantSatisfaction: Double = 0
    var completionRate: Double = 0
    var peakConcurrentTournaments: Int = 0
}

struct SignupFunnelData: Codable {
    var viewed: Int = 0
    var started: Int = 0
    var completed: Int = 0
    var conversionRate: Double = 0
}

struct UserEngagementData: Codable {
    var totalScreenViews: Int = 0
    var totalActions: Int = 0
    var screenViews: [String: Int] = [:]
    var featureSuccessCount: [String: Int] = [:]
    var featureErrorCount: [String: Int] = [:]
    var sessionDuration: TimeInterval = 0
    var weeklyScreenViews: Int = 0
    var weeklyActions: Int = 0
}

struct PerformanceMetrics: Codable {
    var totalMatches: Int = 0
    var avgMatchDuration: TimeInterval = 0
    var upsetCount: Int = 0
    var errorCount: Int = 0
    var crashCount: Int = 0
    var metrics: [String: Double] = [:]
    var weeklyMatches: Int = 0
}

// MARK: - Enhanced Analytics Data Models

struct RealtimeMetrics: Codable {
    var activeUsers: Int = 0
    var activeTournaments: Int = 0
    var liveMatches: Int = 0
    var lastUpdated = Date()
}

struct TournamentInsights: Codable {
    var mostPopularFormat: String = ""
    var averageParticipation: Double = 0.0
    var peakHours: [Int] = []
    var weeklyGrowth: Double = 0.0
    var topVenues: [String] = []
}

struct PlayerInsights: Codable {
    var totalActivePlayers: Int = 0
    var averageSkillLevel: Double = 0.0
    var mostActivePlayer: String = ""
    var retentionRate: Double = 0.0
    var engagementScore: Double = 0.0
}

struct AdvancedTournamentReport: Codable {
    let tournamentId: String
    let name: String
    let format: String
    let startDate: Date
    let endDate: Date?
    let totalParticipants: Int
    let maxParticipants: Int
    let participationRate: Double
    let totalMatches: Int
    let completedMatches: Int
    let totalDuration: TimeInterval
    let averageMatchDuration: TimeInterval
    let engagementMetrics: EngagementMetrics
    let generatedAt: Date
}

struct PlayerPerformanceAnalytics: Codable {
    let wins: Int
    let losses: Int
    let winRate: Double
    let totalMatches: Int
    let averagePointsPerMatch: Double
    let tournamentsPlayed: Int
}

struct TournamentTrendsData: Codable {
    let totalTournaments: Int
    let formatDistribution: [String: Int]
    let dailyCreations: [String: Int]
    let timeframe: AnalyticsTimeframe
}

struct EngagementMetrics: Codable {
    let totalScreenViews: Int
    let totalUserActions: Int
    let uniqueUsers: Int
}

enum AnalyticsTimeframe: String, CaseIterable, Codable {
    case day = "24h"
    case week = "7d"
    case month = "30d"
    case quarter = "90d"
    case year = "365d"
    
    var timeInterval: TimeInterval {
        switch self {
        case .day: return 24 * 60 * 60
        case .week: return 7 * 24 * 60 * 60
        case .month: return 30 * 24 * 60 * 60
        case .quarter: return 90 * 24 * 60 * 60
        case .year: return 365 * 24 * 60 * 60
        }
    }
    
    var displayName: String {
        switch self {
        case .day: return "24 Hours"
        case .week: return "7 Days"
        case .month: return "30 Days"
        case .quarter: return "90 Days"
        case .year: return "1 Year"
        }
    }
}
