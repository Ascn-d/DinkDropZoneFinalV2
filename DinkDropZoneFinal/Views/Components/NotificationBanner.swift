import SwiftUI

struct NotificationBanner: View {
    let notification: AppNotification
    let onDismiss: () -> Void
    let onTap: (() -> Void)?
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Notification icon
            ZStack {
                Circle()
                    .fill(notification.type.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: notification.type.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(notification.type.color)
            }
            
            // Notification content
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Dismiss button
            Button {
                dismissWithAnimation()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .offset(y: isVisible ? 0 : -100)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
        .onTapGesture {
            onTap?()
        }
        .onAppear {
            withAnimation {
                isVisible = true
            }
            
            // Auto dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + notification.duration) {
                dismissWithAnimation()
            }
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isVisible = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

struct ToastNotification: View {
    let message: String
    let type: ToastType
    let duration: TimeInterval
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    
    enum ToastType {
        case success, error, warning, info
        
        var color: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .warning: return .orange
            case .info: return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: type.icon)
                .font(.title3)
                .foregroundColor(type.color)
            
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(type.color.opacity(0.3), lineWidth: 1)
                )
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation {
                    isVisible = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
    }
}

struct MatchFoundBanner: View {
    let match: MatchProposal
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    @State private var timeRemaining: TimeInterval
    @State private var timer: Timer?
    @State private var isVisible = false
    
    init(match: MatchProposal, onAccept: @escaping () -> Void, onDecline: @escaping () -> Void) {
        self.match = match
        self.onAccept = onAccept
        self.onDecline = onDecline
        self._timeRemaining = State(initialValue: match.expiresAt.timeIntervalSinceNow)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    Text("Match Found!")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                // Countdown
                Text("\(Int(timeRemaining))s")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
            }
            
            // Match details
            VStack(spacing: 8) {
                Text(match.potentialMatch.matchType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(match.potentialMatch.matchType.color)
                
                HStack {
                    ForEach(match.potentialMatch.players, id: \.user.id) { player in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(player.user.displayName.isEmpty ? 
                                               player.user.email.prefix(1) : 
                                               player.user.displayName.prefix(1)))
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.blue)
                                )
                            
                            Text(player.user.displayName.isEmpty ? 
                                 player.user.email.components(separatedBy: "@").first ?? "Player" : 
                                 player.user.displayName)
                                .font(.caption2)
                                .lineLimit(1)
                            
                            Text("\(player.user.elo) ELO")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    onDecline()
                } label: {
                    Text("Decline")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Button {
                    onAccept()
                } label: {
                    Text("Accept")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
            
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeRemaining = match.expiresAt.timeIntervalSinceNow
            
            if timeRemaining <= 0 {
                timer?.invalidate()
                onDecline() // Auto-decline when time expires
            }
        }
    }
}

struct AchievementBanner: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    
    @State private var isVisible = false
    @State private var sparkleAnimation = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Achievement icon with sparkles
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.yellow, Color.orange]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                // Sparkle effects
                ForEach(0..<6, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                        .offset(
                            x: cos(Double(index) * .pi / 3) * 40,
                            y: sin(Double(index) * .pi / 3) * 40
                        )
                        .scaleEffect(sparkleAnimation ? 1.2 : 0.8)
                        .opacity(sparkleAnimation ? 1 : 0.6)
                        .animation(
                            .easeInOut(duration: 1)
                            .repeatForever()
                            .delay(Double(index) * 0.1),
                            value: sparkleAnimation
                        )
                }
            }
            
            // Achievement details
            VStack(alignment: .leading, spacing: 4) {
                Text("Achievement Unlocked!")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                
                Text(achievement.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Text("+\(achievement.xpReward) XP")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.yellow, Color.orange]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
        .scaleEffect(isVisible ? 1 : 0.8)
        .opacity(isVisible ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
                sparkleAnimation = true
            }
            
            // Auto dismiss after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation {
                    isVisible = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Data Models

// Achievement struct moved to User.swift to avoid duplication

#Preview {
    VStack(spacing: 20) {
        NotificationBanner(
            notification: AppNotification(
                type: .matchComplete,
                title: "Match Found!",
                message: "You've been matched with Sarah Chen"
            ),
            onDismiss: {},
            onTap: nil as (() -> Void)?
        )
        
        ToastNotification(
            message: "Successfully joined tournament!",
            type: .success,
            duration: 2.0,
            onDismiss: {}
        )
        
        AchievementBanner(
            achievement: Achievement(
                title: "First Victory",
                description: "Win your first match",
                icon: "trophy.fill",
                dateEarned: Date(),
                type: Achievement.AchievementType.milestone,
                xpReward: 100
            ),
            onDismiss: {}
        )
    }
    .padding()
} 
