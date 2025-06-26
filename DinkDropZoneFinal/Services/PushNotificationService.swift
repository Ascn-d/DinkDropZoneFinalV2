import Foundation
import UserNotifications
import UIKit
import Combine
import os.log

// MARK: - Simplified Push Notification Service (No Firebase Dependencies)
final class PushNotificationService: NSObject, ObservableObject {
    
    static let shared = PushNotificationService()
    
    // MARK: - Observable Properties
    @Published var isAuthorized: Bool = false
    @Published var deviceToken: String?
    @Published var lastNotification: LocalNotification?
    
    private let logger = Logger(subsystem: "DinkDropZone", category: "PushNotifications")
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Local Notification Model
    struct LocalNotification: Identifiable, Codable {
        let id: String
        let title: String
        let body: String
        let type: NotificationType
        let data: [String: String]?
        let timestamp: Date
        
        enum NotificationType: String, Codable, CaseIterable {
            case matchProposal = "match_proposal"
            case matchAccepted = "match_accepted"
            case matchDeclined = "match_declined"
            case queueUpdate = "queue_update"
            case achievement = "achievement"
            case general = "general"
            
            var icon: String {
                switch self {
                case .matchProposal: return "🏓"
                case .matchAccepted: return "✅"
                case .matchDeclined: return "❌"
                case .queueUpdate: return "⏰"
                case .achievement: return "🏆"
                case .general: return "📱"
                }
            }
        }
        
        init(title: String, body: String, type: NotificationType, data: [String: String]? = nil) {
            self.id = UUID().uuidString
            self.title = title
            self.body = body
            self.type = type
            self.data = data
            self.timestamp = Date()
        }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    
    /// Request notification permissions
    func requestPermissions() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .provisional]
        
        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            await MainActor.run {
                isAuthorized = granted
            }
            
            if granted {
                await registerForRemoteNotifications()
                logger.info("Push notification permissions granted")
            } else {
                logger.warning("Push notification permissions denied")
            }
        } catch {
            logger.error("Failed to request push notification permissions: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Register for remote notifications (simplified without Firebase)
    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    /// Send local notification for match proposals
    func sendMatchProposalNotification(from player: String, matchId: String) async {
        let notification = LocalNotification(
            title: "🏓 Match Proposal",
            body: "\(player) wants to play a match with you!",
            type: .matchProposal,
            data: ["matchId": matchId, "player": player]
        )
        
        await scheduleLocalNotification(notification, delay: 0)
        lastNotification = notification
        
        logger.info("Sent match proposal notification for player: \(player)")
    }
    
    /// Send queue position update notification
    func sendQueueUpdateNotification(position: Int, estimatedWait: Int) async {
        let notification = LocalNotification(
            title: "⏰ Queue Update",
            body: "You're #\(position) in queue. Estimated wait: \(estimatedWait) minutes",
            type: .queueUpdate,
            data: ["position": "\(position)", "estimatedWait": "\(estimatedWait)"]
        )
        
        await scheduleLocalNotification(notification, delay: 0)
        lastNotification = notification
        
        logger.info("Sent queue update notification: position \(position)")
    }
    
    /// Send achievement unlocked notification
    func sendAchievementNotification(title: String, description: String) async {
        let notification = LocalNotification(
            title: "🏆 Achievement Unlocked!",
            body: "\(title): \(description)",
            type: .achievement,
            data: ["achievementTitle": title, "description": description]
        )
        
        await scheduleLocalNotification(notification, delay: 0)
        lastNotification = notification
        
        logger.info("Sent achievement notification: \(title)")
    }
    
    /// Schedule a local notification
    private func scheduleLocalNotification(_ notification: LocalNotification, delay: TimeInterval) async {
        let content = UNMutableNotificationContent()
        content.title = notification.title
        content.body = notification.body
        content.sound = .default
        content.badge = NSNumber(value: await getApplicationBadgeCount() + 1)
        
        // Add custom data
        if let data = notification.data {
            for (key, value) in data {
                content.userInfo[key] = value
            }
        }
        content.userInfo["notificationType"] = notification.type.rawValue
        content.userInfo["notificationId"] = notification.id
        
        // Add action buttons for match proposals
        if notification.type == .matchProposal {
            let acceptAction = UNNotificationAction(
                identifier: "ACCEPT_MATCH",
                title: "Accept",
                options: [.foreground]
            )
            let declineAction = UNNotificationAction(
                identifier: "DECLINE_MATCH",
                title: "Decline",
                options: []
            )
            
            let category = UNNotificationCategory(
                identifier: "MATCH_PROPOSAL",
                actions: [acceptAction, declineAction],
                intentIdentifiers: [],
                options: []
            )
            
            notificationCenter.setNotificationCategories([category])
            content.categoryIdentifier = "MATCH_PROPOSAL"
        }
        
        // Create trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(0.1, delay), repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            logger.info("Scheduled local notification: \(notification.title)")
        } catch {
            logger.error("Failed to schedule notification: \(error.localizedDescription)")
        }
    }
    
    /// Remove all pending notifications
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        logger.info("Removed all pending notifications")
    }
    
    /// Remove specific notification
    func removeNotification(withId id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        logger.info("Removed notification with ID: \(id)")
    }
    
    /// Update application badge count
    func updateBadgeCount(_ count: Int) async {
        await MainActor.run {
            UNUserNotificationCenter.current().setBadgeCount(count) { _ in }
        }
    }
    
    /// Get current badge count
    private func getApplicationBadgeCount() async -> Int {
        return 0 // Simplified for compatibility
    }
    
    /// Check current authorization status
    private func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                isAuthorized = settings.authorizationStatus == .authorized || 
                              settings.authorizationStatus == .provisional
            }
        }
    }
    
    // MARK: - Device Token Handling (Simplified)
    
    /// Handle device token registration (simplified without Firebase)
    func handleDeviceTokenRegistration(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = tokenString
        
        logger.info("Device token registered: \(tokenString)")
        
        // In a real Firebase setup, you would send this token to Firebase
        // For now, we'll just store it locally
    }
    
    /// Handle remote notification registration failure
    func handleRegistrationError(_ error: Error) {
        logger.error("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension PushNotificationService: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        switch response.actionIdentifier {
        case "ACCEPT_MATCH":
            handleMatchResponse(userInfo: userInfo, accepted: true)
            
        case "DECLINE_MATCH":
            handleMatchResponse(userInfo: userInfo, accepted: false)
            
        case UNNotificationDefaultActionIdentifier:
            handleNotificationTap(userInfo: userInfo)
            
        default:
            break
        }
        
        completionHandler()
    }
    
    private func handleMatchResponse(userInfo: [AnyHashable: Any], accepted: Bool) {
        guard let matchId = userInfo["matchId"] as? String else { return }
        
        logger.info("User \(accepted ? "accepted" : "declined") match: \(matchId)")
        
        // Post notification for the app to handle
        NotificationCenter.default.post(
            name: .matchResponseFromNotification,
            object: nil,
            userInfo: ["matchId": matchId, "accepted": accepted]
        )
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let typeString = userInfo["notificationType"] as? String,
              let type = LocalNotification.NotificationType(rawValue: typeString) else {
            return
        }
        
        logger.info("User tapped notification of type: \(type.rawValue)")
        
        // Post notification for the app to handle
        NotificationCenter.default.post(
            name: .notificationTapped,
            object: nil,
            userInfo: userInfo
        )
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let matchResponseFromNotification = Notification.Name("matchResponseFromNotification")
    static let notificationTapped = Notification.Name("notificationTapped")
}