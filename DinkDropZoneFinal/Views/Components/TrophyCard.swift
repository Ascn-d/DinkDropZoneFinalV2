import SwiftUI
import Combine

// MARK: - Trophy Card

struct TrophyCard: View {
    let trophy: Trophy
    @State private var sparkleAnimation = false
    @State private var glowAnimation = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Trophy Icon with Rarity Effects
            ZStack {
                // Glow Effect for Higher Rarities
                if trophy.tier == .legendary || trophy.tier == .platinum {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [trophy.tier.color.opacity(0.3), trophy.tier.color.opacity(0.1), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(glowAnimation ? 1.1 : 1.0)
                        .opacity(glowAnimation ? 0.8 : 0.4)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: glowAnimation)
                }
                
                // Main Trophy Background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [trophy.tier.color.opacity(0.2), trophy.tier.color.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(trophy.tier.color.opacity(0.3), lineWidth: 2)
                    )
                
                // Trophy Icon
                Image(systemName: trophy.icon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(trophy.tier.color)
                
                // Sparkle Effects
                let sparkleCount = trophy.tier == .legendary ? 8 : (trophy.tier == .platinum ? 6 : (trophy.tier == .gold ? 4 : 0))
                ForEach(0..<sparkleCount, id: \.self) { index in
                    SparkleView(
                        delay: Double(index) * 0.3,
                        color: trophy.tier.color
                    )
                    .offset(
                        x: cos(Double(index) * 2 * .pi / Double(sparkleCount)) * 50,
                        y: sin(Double(index) * 2 * .pi / Double(sparkleCount)) * 50
                    )
                }
            }
            .frame(width: 120, height: 120)
            
            // Trophy Info
            VStack(spacing: 8) {
                // Tier Badge
                Text(trophy.tier.rawValue.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(trophy.tier.color.opacity(0.2))
                    .foregroundColor(trophy.tier.color)
                    .clipShape(Capsule())
                
                // Trophy Title
                Text(trophy.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // Trophy Description
                Text(trophy.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                // Unlock Date
                if let unlockedAt = trophy.unlockedAt {
                    Text("Unlocked \(formatDate(unlockedAt))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // XP Reward
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("\(trophy.xpReward) XP")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: trophy.tier.color.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [trophy.tier.color.opacity(0.3), trophy.tier.color.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .scaleEffect(isRecentlyUnlocked ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRecentlyUnlocked)
        .onAppear {
            glowAnimation = true
        }
    }
    
    private var isRecentlyUnlocked: Bool {
        guard let unlockedAt = trophy.unlockedAt else { return false }
        return Date().timeIntervalSince(unlockedAt) < 86400 // 24 hours
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Compact Trophy Card

struct CompactTrophyCard: View {
    let trophy: Trophy
    
    private var isRecentlyUnlocked: Bool {
        guard let unlockedAt = trophy.unlockedAt else { return false }
        return Date().timeIntervalSince(unlockedAt) < 86400 // 24 hours
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Trophy Icon
            ZStack {
                Circle()
                    .fill(trophy.tier.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: trophy.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(trophy.tier.color)
                
                // New Badge
                if isRecentlyUnlocked {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Text("!")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .offset(x: 15, y: -15)
                }
            }
            
            // Trophy Info
            VStack(alignment: .leading, spacing: 2) {
                Text(trophy.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(trophy.tier.rawValue)
                    .font(.caption)
                    .foregroundColor(trophy.tier.color)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // XP Reward
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Text("\(trophy.xpReward)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(trophy.tier.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Trophy Grid View

struct TrophyGridView: View {
    let trophies: [Trophy]
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 2)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(trophies) { trophy in
                TrophyCard(trophy: trophy)
            }
        }
    }
}

// MARK: - Trophy Collection View

struct TrophyCollectionView: View {
    let unlockedTrophies: [Trophy]
    let allTrophyTypes: [AchievementCategory] = AchievementCategory.allCases
    
    var unlockedCount: Int { unlockedTrophies.count }
    var totalCount: Int { allTrophyTypes.count }
    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }
    
    private var sortedTrophies: [Trophy] {
        return unlockedTrophies.sorted { trophy1, trophy2 in
            let date1 = trophy1.unlockedAt ?? Date.distantPast
            let date2 = trophy2.unlockedAt ?? Date.distantPast
            return date1 > date2
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with Progress
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Trophy Collection")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(unlockedCount)/\(totalCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.8), .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: geometry.size.width * completionPercentage,
                                height: 12
                            )
                            .animation(.easeInOut(duration: 1.0), value: completionPercentage)
                    }
                }
                .frame(height: 12)
                
                Text("\(Int(completionPercentage * 100))% Complete")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            // Trophy Grid
            if unlockedTrophies.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trophy")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("No Trophies Yet")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Complete achievements to unlock your first trophy!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                TrophyGridView(trophies: sortedTrophies)
            }
        }
    }
}

// MARK: - Sparkle View

struct SparkleView: View {
    let delay: Double
    let color: Color
    @State private var animate = false
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(color)
            .scaleEffect(animate ? 1.2 : 0.8)
            .opacity(animate ? 1.0 : 0.3)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true)
                .delay(delay),
                value: animate
            )
            .onAppear {
                animate = true
            }
    }
}

// MARK: - Trophy Unlock Animation

struct TrophyUnlockView: View {
    let trophy: Trophy
    @State private var showTrophy = false
    @State private var showText = false
    @State private var showSparkles = false
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 30) {
                // Trophy with Animation
                ZStack {
                    // Sparkle Background
                    if showSparkles {
                        ForEach(0..<20, id: \.self) { index in
                            SparkleView(
                                delay: Double(index) * 0.1,
                                color: trophy.tier.color
                            )
                            .offset(
                                x: CGFloat.random(in: -100...100),
                                y: CGFloat.random(in: -100...100)
                            )
                        }
                    }
                    
                    // Trophy
                    if showTrophy {
                        TrophyCard(trophy: trophy)
                            .scaleEffect(showTrophy ? 1.0 : 0.1)
                            .animation(.spring(response: 0.6, dampingFraction: 0.6), value: showTrophy)
                    }
                }
                
                // Text
                if showText {
                    VStack(spacing: 12) {
                        Text("🎉 Trophy Unlocked! 🎉")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("You've earned the \(trophy.title) trophy!")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        
                        Text("+\(trophy.xpReward) XP")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                    }
                    .opacity(showText ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.5).delay(0.3), value: showText)
                }
                
                // Dismiss Button
                Button("Continue") {
                    isPresented = false
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(trophy.tier.color)
                .clipShape(Capsule())
                .opacity(showText ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5).delay(0.8), value: showText)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showSparkles = true
                showTrophy = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showText = true
            }
        }
    }
}

// MARK: - Achievement Unlock Notification

struct AchievementUnlockNotification: View {
    let achievement: Trophy
    @State private var animationPhase: AnimationPhase = .hidden
    @State private var sparkleOffset: Double = 0
    @State private var glowIntensity: Double = 0
    @State private var bounceAmount: Double = 0
    let onDismiss: () -> Void
    
    enum AnimationPhase {
        case hidden
        case appearing
        case celebrating
        case displaying
        case dismissing
    }
    
    var body: some View {
        ZStack {
            // Background blur
            backgroundBlur
            
            // Main achievement card
            mainContent
        }
        .onAppear {
            startUnlockAnimation()
        }
        .onReceive(Timer.publish(every: 4.0, on: .main, in: .common).autoconnect()) { _ in
            if animationPhase == .displaying {
                dismissNotification()
            }
        }
    }
    
    private var backgroundBlur: some View {
        Color.black.opacity(0.6)
            .ignoresSafeArea()
            .opacity(animationPhase == .hidden ? 0 : 1)
            .animation(.easeInOut(duration: 0.3), value: animationPhase)
            .onTapGesture {
                dismissNotification()
            }
    }
    
    private var mainContent: some View {
        VStack(spacing: 20) {
            // Sparkle effects
            sparkleEffects
            
            // Achievement icon with glow
            achievementIcon
            
            // Achievement details
            achievementDetails
            
            // Dismiss instruction
            dismissInstruction
        }
        .padding(30)
        .background(cardBackground)
        .scaleEffect(animationPhase == .hidden ? 0.8 : 1)
        .offset(y: animationPhase == .hidden ? 50 : 0)
    }
    
    private var achievementIcon: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(achievement.tier.color.opacity(0.8))
                .frame(width: 120 + glowIntensity * 20, height: 120 + glowIntensity * 20)
                .blur(radius: 20)
                .opacity(glowIntensity)
            
            // Main icon background
            Circle()
                .fill(achievement.tier.color.opacity(0.2))
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(achievement.tier.color, lineWidth: 3)
                )
            
            // Achievement icon
            Image(systemName: achievement.icon)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(achievement.tier.color)
                .scaleEffect(1 + bounceAmount * 0.2)
        }
        .scaleEffect(animationPhase == .hidden ? 0.3 : 1)
        .rotation3DEffect(
            .degrees(animationPhase == .celebrating ? 360 : 0),
            axis: (x: 0, y: 1, z: 0)
        )
    }
    
    private var achievementDetails: some View {
        VStack(spacing: 12) {
            // "Achievement Unlocked" text
            Text("🎉 ACHIEVEMENT UNLOCKED! 🎉")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(achievement.tier.color)
                .opacity(animationPhase == .hidden ? 0 : 1)
                .scaleEffect(animationPhase == .celebrating ? 1.1 : 1)
            
            // Tier badge
            tierBadge
            
            // Achievement title
            Text(achievement.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .opacity(animationPhase == .hidden ? 0 : 1)
                .offset(y: animationPhase == .hidden ? 20 : 0)
            
            // Achievement description
            Text(achievement.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .opacity(animationPhase == .hidden ? 0 : 1)
                .offset(y: animationPhase == .hidden ? 20 : 0)
            
            // XP reward
            xpRewardView
        }
    }
    
    private var tierBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: achievement.tier.icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(achievement.tier.color)
            
            Text(achievement.tier.rawValue.uppercased())
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(achievement.tier.color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(tierBadgeBackground)
        .opacity(animationPhase == .hidden ? 0 : 1)
        .offset(y: animationPhase == .hidden ? 20 : 0)
    }
    
    private var tierBadgeBackground: some View {
        Capsule()
            .fill(achievement.tier.color.opacity(0.2))
            .overlay(
                Capsule()
                    .stroke(achievement.tier.color, lineWidth: 1)
            )
    }
    
    private var xpRewardView: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.orange)
            
            Text("+\(achievement.xpReward) XP")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(xpRewardBackground)
        .opacity(animationPhase == .hidden ? 0 : 1)
        .offset(y: animationPhase == .hidden ? 20 : 0)
        .scaleEffect(animationPhase == .celebrating ? 1.1 : 1)
    }
    
    private var xpRewardBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.orange.opacity(0.2))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.orange, lineWidth: 1)
            )
    }
    
    private var dismissInstruction: some View {
        Text("Tap anywhere to continue")
            .font(.caption)
            .foregroundColor(.secondary)
            .opacity(animationPhase == .displaying ? 1 : 0)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(.ultraThickMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(achievement.tier.color.opacity(0.3), lineWidth: 2)
            )
    }
    
    private var sparkleEffects: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                sparkleView(for: index)
            }
        }
        .opacity(animationPhase == .celebrating ? 1 : 0)
    }
    
    private func sparkleView(for index: Int) -> some View {
        let angle = Double(index) * .pi / 6 + sparkleOffset
        let xOffset = cos(angle) * 60
        let yOffset = sin(angle) * 60
        
        return SparkleView(
            delay: Double(index) * 0.1,
            color: achievement.tier.color
        )
        .offset(x: xOffset, y: yOffset)
    }
    
    private func startUnlockAnimation() {
        // Phase 1: Appear
        withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
            animationPhase = .appearing
        }
        
        // Phase 2: Celebrate with effects
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.spring(duration: 0.8, bounce: 0.4)) {
                animationPhase = .celebrating
            }
            
            // Start continuous effects
            withAnimation(.easeInOut(duration: 1.0).repeatCount(3, autoreverses: true)) {
                glowIntensity = 1.0
            }
            
            withAnimation(.spring(duration: 0.3).repeatCount(6, autoreverses: true)) {
                bounceAmount = 1.0
            }
            
            withAnimation(.linear(duration: 2.0).repeatCount(3, autoreverses: false)) {
                sparkleOffset = .pi * 2
            }
        }
        
        // Phase 3: Display normally
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                animationPhase = .displaying
                glowIntensity = 0
                bounceAmount = 0
            }
        }
    }
    
    private func dismissNotification() {
        withAnimation(.easeInOut(duration: 0.3)) {
            animationPhase = .dismissing
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Modern Trophy Card

struct ModernTrophyCard: View {
    let trophy: Trophy
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Trophy icon with glow effect
            ZStack {
                Circle()
                    .fill(trophy.tier.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(trophy.tier.color.opacity(0.3), lineWidth: 2)
                    )
                
                Image(systemName: trophy.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(trophy.tier.color)
            }
            .scaleEffect(isPressed ? 0.95 : 1)
            
            VStack(spacing: 8) {
                // Tier badge
                HStack(spacing: 4) {
                    Image(systemName: trophy.tier.icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(trophy.tier.color)
                    
                    Text(trophy.tier.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(trophy.tier.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(trophy.tier.color.opacity(0.15))
                )
                
                // Trophy title
                Text(trophy.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Description
                Text(trophy.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                
                // XP reward
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    
                    Text("+\(trophy.xpReward)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.orange)
                }
                
                // Unlock date
                if let unlockedAt = trophy.unlockedAt {
                    Text("Unlocked \(unlockedAt, style: .date)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .frame(width: 160, height: 220)
        .background(modernTrophyCardBackground)
        .scaleEffect(isPressed ? 0.98 : 1)
        .shadow(
            color: trophy.tier.color.opacity(0.3),
            radius: isPressed ? 8 : 4,
            x: 0,
            y: isPressed ? 4 : 2
        )
        .onTapGesture {
            withAnimation(.spring(duration: 0.2)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(duration: 0.2)) {
                    isPressed = false
                }
            }
        }
    }
    
    private var modernTrophyCardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(trophy.tier.color.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Achievement Progress Notification

struct AchievementProgressNotification: View {
    let achievement: Trophy
    let previousProgress: Double
    @State private var animateProgress = false
    @State private var show = false
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Achievement icon
            ZStack {
                Circle()
                    .fill(achievement.category.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(achievement.category.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Progress: \(achievement.title)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    // Progress bar
                    progressBar
                    
                    Text("\(Int(achievement.currentProgress * 100))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(progressNotificationBackground)
        .offset(y: show ? 0 : -100)
        .opacity(show ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                show = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animateProgress = true
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    show = false
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onDismiss()
                }
            }
        }
    }
    
    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: 6)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(achievement.category.color)
                    .frame(
                        width: geometry.size.width * CGFloat(animateProgress ? achievement.currentProgress : previousProgress),
                        height: 6
                    )
            }
        }
        .frame(height: 6)
    }
    
    private var progressNotificationBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(achievement.category.color.opacity(0.3), lineWidth: 1)
            )
    }
}

// MARK: - Achievement Showcase View

struct AchievementShowcaseView: View {
    let achievements: [Trophy]
    @State private var currentIndex = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Recent Achievements")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            TabView(selection: $currentIndex) {
                ForEach(Array(achievements.enumerated()), id: \.element.id) { index, achievement in
                    ModernTrophyCard(trophy: achievement)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 240)
            
            // Achievement counter
            if achievements.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<achievements.count, id: \.self) { index in
                        Circle()
                            .fill(currentIndex == index ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentIndex == index ? 1.2 : 1)
                    }
                }
            }
        }
        .padding()
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let achievementProgress = Notification.Name("achievementProgress")
}

// MARK: - Achievement Notification Manager

@MainActor
class AchievementNotificationManager: ObservableObject {
    @Published var currentUnlockNotification: Trophy?
    @Published var currentProgressNotification: (achievement: Trophy, previousProgress: Double)?
    
    func showUnlockNotification(for achievement: Trophy) {
        currentUnlockNotification = achievement
    }
    
    func hideUnlockNotification() {
        currentUnlockNotification = nil
    }
    
    func showProgressNotification(for achievement: Trophy, previousProgress: Double) {
        currentProgressNotification = (achievement, previousProgress)
    }
    
    func hideProgressNotification() {
        currentProgressNotification = nil
    }
}

#Preview("Achievement Unlock") {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        AchievementUnlockNotification(
            achievement: AchievementDefinitions.allAchievements[0]
        ) {
            // Dismiss action
        }
    }
}

#Preview("Trophy Card") {
    ModernTrophyCard(trophy: AchievementDefinitions.allAchievements[0])
}
