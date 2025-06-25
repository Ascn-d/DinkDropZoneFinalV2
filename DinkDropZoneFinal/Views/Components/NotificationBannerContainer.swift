import SwiftUI

struct NotificationBannerContainer: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(appState.unreadNotifications) { notification in
                NotificationBanner(
                    notification: notification,
                    onDismiss: { appState.markNotificationAsRead(notification) },
                    onTap: {
                        appState.markNotificationAsRead(notification)
                        // Further actions (navigate) could go here in the future
                    }
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 60)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
    }
} 