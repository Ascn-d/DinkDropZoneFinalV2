import Foundation
import UIKit
import UserNotifications
import ActivityKit

// MARK: - Tournament v2 Push Notification Service

@MainActor
class PushServiceV2: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAuthorized = false
    @Published var fcmToken: String?
    @Published var notificationHistory: [NotificationRecord] = []
    @Published var isLiveActivityEnabled = false
    
    // MARK: - Private Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let featureFlagService = FeatureFlagService()
    private var pendingNotifications: [PendingNotification] = []
    
    override init() {
        super.init()
        setupNotificationCategories()
        loadNotificationHistory()
        checkLiveActivitySupport()
    }
    
    // MARK: - Authorization & Setup
    
    func requestPermissions() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            
            isAuthorized = granted
            
            if granted {
                await registerForRemoteNotifications()
                print("🔔 Push notifications authorized")
            } else {
                print("❌ Push notifications denied")
            }
        } catch {
            print("❌ Failed to request notification permissions: \(error)")
        }
    }
    
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    func updateFCMToken(_ token: String) {
        fcmToken = token
        print("🔑 FCM Token updated: \(token.prefix(20))...")
    }
    
    // MARK: - Tournament Notifications
    
    /// Send tournament start notification
    func sendTournamentStartNotification(
        tournament: Tournament,
        to participants: [TournamentParticipant]
    ) async {
        guard featureFlagService.isEnabled(.pushNotifications) else { return }
        
        let title = "🏁 Tournament Starting!"
        let body = "\(tournament.name) is about to begin. Get ready to play!"
        
        let notification = TournamentNotification(
            id: UUID().uuidString,
            tournamentId: tournament.id.uuidString,
            type: .tournamentStart,
            title: title,
            body: body,
            data: [
                "tournament_id": tournament.id.uuidString,
                "tournament_name": tournament.name,
                "action": "view_tournament"
            ]
        )
        
        for participant in participants {
            await sendNotificationToUser(
                userId: participant.userID,
                notification: notification
            )
        }
        
        print("🔔 Tournament start notifications sent to \(participants.count) participants")
    }
    
    /// Send match ready notification
    func sendMatchReadyNotification(
        match: TournamentMatch,
        tournament: Tournament,
        to playerIds: [String]
    ) async {
        guard featureFlagService.isEnabled(.pushNotifications) else { return }
        
        let title = "⚡ Your Match is Ready!"
        let body = "It's time for your match in \(tournament.name). Tap to view details."
        
        let notification = TournamentNotification(
            id: UUID().uuidString,
            tournamentId: tournament.id.uuidString,
            type: .matchReady,
            title: title,
            body: body,
            data: [
                "tournament_id": tournament.id.uuidString,
                "match_id": match.id.uuidString,
                "action": "view_match"
            ]
        )
        
        for playerId in playerIds {
            await sendNotificationToUser(
                userId: playerId,
                notification: notification
            )
        }
        
        print("🔔 Match ready notifications sent to \(playerIds.count) players")
    }
    
    // MARK: - Local Notifications
    
    private func sendNotificationToUser(
        userId: String,
        notification: TournamentNotification
    ) async {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.userInfo = notification.data
        content.badge = 1
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            
            // Record notification
            let record = NotificationRecord(
                id: notification.id,
                userId: userId,
                type: notification.type,
                title: notification.title,
                body: notification.body,
                sentAt: Date(),
                isDelivered: true
            )
            notificationHistory.append(record)
            saveNotificationHistory()
            
            print("📤 Notification sent: \(notification.title)")
        } catch {
            print("❌ Failed to send notification: \(error)")
        }
    }
    
    // MARK: - Setup & Utilities
    
    private func setupNotificationCategories() {
        // Setup notification categories
    }
    
    private func loadNotificationHistory() {
        if let data = UserDefaults.standard.data(forKey: "notification_history"),
           let history = try? JSONDecoder().decode([NotificationRecord].self, from: data) {
            notificationHistory = history
        }
    }
    
    private func saveNotificationHistory() {
        if notificationHistory.count > 100 {
            notificationHistory = Array(notificationHistory.suffix(100))
        }
        
        if let data = try? JSONEncoder().encode(notificationHistory) {
            UserDefaults.standard.set(data, forKey: "notification_history")
        }
    }
    
    private func checkLiveActivitySupport() {
        if #available(iOS 16.1, *) {
            isLiveActivityEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        } else {
            isLiveActivityEnabled = false
        }
    }
    
    func updateBadgeCount(_ count: Int) {
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(count)
        }
    }
    
    func clearBadge() {
        updateBadgeCount(0)
    }
}

// MARK: - Data Models

struct TournamentNotification: Codable {
    let id: String
    let tournamentId: String
    let type: NotificationType
    let title: String
    let body: String
    let data: [String: String]
    let timestamp: Date
    
    init(id: String, tournamentId: String, type: NotificationType, title: String, body: String, data: [String: String]) {
        self.id = id
        self.tournamentId = tournamentId
        self.type = type
        self.title = title
        self.body = body
        self.data = data
        self.timestamp = Date()
    }
}

enum NotificationType: String, Codable, CaseIterable {
    case tournamentStart = "tournament_start"
    case tournamentCompleted = "tournament_completed"
    case matchReady = "match_ready"
    case matchCompleted = "match_completed"
    case registrationConfirmed = "registration_confirmed"
    case reminder = "reminder"
    case announcement = "announcement"
}

struct NotificationRecord: Codable, Identifiable {
    let id: String
    let userId: String
    let type: NotificationType
    let title: String
    let body: String
    let sentAt: Date
    let isDelivered: Bool
}

struct PendingNotification {
    let userId: String
    let notification: TournamentNotification
    var retryCount: Int
}
