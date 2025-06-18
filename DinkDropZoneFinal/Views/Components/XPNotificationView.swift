import SwiftUI

// MARK: - XP Notification Manager

@MainActor
@Observable
class XPNotificationManager {
    var activeNotifications: [XPNotification] = []
    var showLevelUpAnimation = false
    var levelUpData: LevelUpData?
    
    init() {
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: .showXPNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let reward = userInfo["reward"] as? XPManager.XPReward,
                  let amount = userInfo["amount"] as? Int else { return }
            
            Task { @MainActor in
                self.showXPReward(reward, amount: amount)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .showLevelUpNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let userInfo = notification.userInfo,
                  let newLevel = userInfo["newLevel"] as? Int,
                  let xpGained = userInfo["xpGained"] as? Int else { return }
            
            Task { @MainActor in
                self.showLevelUp(newLevel: newLevel, xpGained: xpGained)
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .showMissionCompleteNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let mission = notification.object as? Mission,
                  let userInfo = notification.userInfo,
                  let xpReward = userInfo["xpReward"] as? Int else { return }
            
            Task { @MainActor in
                self.showMissionComplete(mission, xpReward: xpReward)
            }
        }
    }
    
    func showXPReward(_ reward: XPManager.XPReward, amount: Int) {
        let notification = XPNotification(
            type: .xpGain,
            title: "+\(amount) XP",
            subtitle: reward.description,
            icon: reward.icon,
            color: .blue,
            duration: 3.0
        )
        
        activeNotifications.append(notification)
        
        // Auto-remove after duration
        Task {
            try? await Task.sleep(nanoseconds: UInt64(notification.duration * 1_000_000_000))
            removeNotification(notification)
        }
    }
    
    func showLevelUp(newLevel: Int, xpGained: Int) {
        levelUpData = LevelUpData(newLevel: newLevel, xpGained: xpGained)
        showLevelUpAnimation = true
        
        // Also show a notification
        let notification = XPNotification(
            type: .levelUp,
            title: "Level Up!",
            subtitle: "You reached level \(newLevel)",
            icon: "arrow.up.circle.fill",
            color: .orange,
            duration: 4.0
        )
        
        activeNotifications.append(notification)
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(notification.duration * 1_000_000_000))
            removeNotification(notification)
        }
    }
    
    func showMissionComplete(_ mission: Mission, xpReward: Int) {
        let notification = XPNotification(
            type: .missionComplete,
            title: "Mission Complete!",
            subtitle: "\(mission.type.title) (+\(xpReward) XP)",
            icon: "checkmark.circle.fill",
            color: .green,
            duration: 3.5
        )
        
        activeNotifications.append(notification)
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(notification.duration * 1_000_000_000))
            removeNotification(notification)
        }
    }
    
    private func removeNotification(_ notification: XPNotification) {
        activeNotifications.removeAll { $0.id == notification.id }
    }
    
    func dismissLevelUp() {
        showLevelUpAnimation = false
        levelUpData = nil
    }
}

// MARK: - XP Notification Model

struct XPNotification: Identifiable {
    let id = UUID()
    let type: NotificationType
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let duration: Double
    let timestamp = Date()
    
    enum NotificationType {
        case xpGain
        case levelUp
        case missionComplete
        case trophyUnlock
    }
}

struct LevelUpData {
    let newLevel: Int
    let xpGained: Int
}

// MARK: - XP Notification View

struct XPNotificationView: View {
    let notification: XPNotification
    @State private var isVisible = false
    @State private var offset: CGFloat = -100
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(notification.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: notification.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(notification.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(notification.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(notification.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Sparkle effect for special notifications
            if notification.type == .levelUp || notification.type == .trophyUnlock {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.yellow)
                    .scaleEffect(isVisible ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isVisible)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: notification.color.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(notification.color.opacity(0.3), lineWidth: 1)
        )
        .offset(y: offset)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isVisible)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: offset)
        .onAppear {
            withAnimation {
                isVisible = true
                offset = 0
            }
            
            // Start exit animation before removal
            DispatchQueue.main.asyncAfter(deadline: .now() + notification.duration - 0.5) {
                withAnimation {
                    offset = -100
                    isVisible = false
                }
            }
        }
    }
}

// MARK: - Level Up Animation View

struct LevelUpAnimationView: View {
    let levelUpData: LevelUpData
    @Binding var isPresented: Bool
    @State private var showContent = false
    @State private var showParticles = false
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAnimation()
                }
            
            // Particle effects
            if showParticles {
                ForEach(0..<30, id: \.self) { index in
                    ParticleView(
                        delay: Double(index) * 0.05,
                        color: [.yellow, .orange, .blue, .purple].randomElement() ?? .yellow
                    )
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -300...300)
                    )
                }
            }
            
            // Main content
            VStack(spacing: 30) {
                // Level up icon with rotation
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.orange.opacity(0.3), .orange.opacity(0.1), .clear],
                                center: .center,
                                startRadius: 50,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(showContent ? 1.0 : 0.1)
                        .opacity(showContent ? 0.6 : 0)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.3), .yellow.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(showContent ? 1.0 : 0.1)
                    
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.orange)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(showContent ? 1.0 : 0.1)
                }
                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: showContent)
                
                // Text content
                if showContent {
                    VStack(spacing: 16) {
                        Text("🎉 LEVEL UP! 🎉")
                            .font(.title.bold())
                            .foregroundColor(.white)
                            .scaleEffect(showContent ? 1.0 : 0.1)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3), value: showContent)
                        
                        Text("You reached Level \(levelUpData.newLevel)!")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.9))
                            .scaleEffect(showContent ? 1.0 : 0.1)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: showContent)
                        
                        Text("+\(levelUpData.xpGained) XP Bonus")
                            .font(.headline)
                            .foregroundColor(.yellow)
                            .scaleEffect(showContent ? 1.0 : 0.1)
                            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: showContent)
                    }
                }
                
                // Continue button
                if showContent {
                    Button("Continue") {
                        dismissAnimation()
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .scaleEffect(showContent ? 1.0 : 0.1)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.8), value: showContent)
                }
            }
        }
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // Start particle effects
        showParticles = true
        
        // Start rotation animation
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Show content with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showContent = true
        }
    }
    
    private func dismissAnimation() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showContent = false
            showParticles = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Particle View

struct ParticleView: View {
    let delay: Double
    let color: Color
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: CGFloat.random(in: 4...12), height: CGFloat.random(in: 4...12))
            .scaleEffect(animate ? 1.5 : 0.1)
            .opacity(animate ? 0.0 : 1.0)
            .animation(
                .easeOut(duration: 2.0)
                .delay(delay),
                value: animate
            )
            .onAppear {
                animate = true
            }
    }
}

// MARK: - XP Notification Container

struct XPNotificationContainer: View {
    @Environment(XPNotificationManager.self) private var notificationManager
    
    var body: some View {
        @Bindable var bindableManager = notificationManager
        
        VStack(spacing: 8) {
            ForEach(notificationManager.activeNotifications) { notification in
                XPNotificationView(notification: notification)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 60) // Account for safe area
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(false)
        .fullScreenCover(isPresented: $bindableManager.showLevelUpAnimation) {
            if let levelUpData = notificationManager.levelUpData {
                LevelUpAnimationView(
                    levelUpData: levelUpData,
                    isPresented: $bindableManager.showLevelUpAnimation
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            XPNotificationView(
                notification: XPNotification(
                    type: .xpGain,
                    title: "+75 XP",
                    subtitle: "Win a match",
                    icon: "trophy.fill",
                    color: .blue,
                    duration: 3.0
                )
            )
            
            XPNotificationView(
                notification: XPNotification(
                    type: .levelUp,
                    title: "Level Up!",
                    subtitle: "You reached level 5",
                    icon: "arrow.up.circle.fill",
                    color: .orange,
                    duration: 4.0
                )
            )
            
            XPNotificationView(
                notification: XPNotification(
                    type: .missionComplete,
                    title: "Mission Complete!",
                    subtitle: "Play 3 matches (+100 XP)",
                    icon: "checkmark.circle.fill",
                    color: .green,
                    duration: 3.5
                )
            )
        }
        .padding()
    }
} 