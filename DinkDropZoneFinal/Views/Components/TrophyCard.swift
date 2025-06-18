import SwiftUI

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
                if trophy.rarity.sparkleCount > 0 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [rarityColor.opacity(0.3), rarityColor.opacity(0.1), Color.clear],
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
                            colors: [rarityColor.opacity(0.2), rarityColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(rarityColor.opacity(0.3), lineWidth: 2)
                    )
                
                // Trophy Icon
                Image(systemName: trophy.icon)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(rarityColor)
                
                // Sparkle Effects
                ForEach(0..<trophy.rarity.sparkleCount, id: \.self) { index in
                    SparkleView(
                        delay: Double(index) * 0.3,
                        color: rarityColor
                    )
                    .offset(
                        x: cos(Double(index) * 2 * .pi / Double(trophy.rarity.sparkleCount)) * 50,
                        y: sin(Double(index) * 2 * .pi / Double(trophy.rarity.sparkleCount)) * 50
                    )
                }
            }
            .frame(width: 120, height: 120)
            
            // Trophy Info
            VStack(spacing: 8) {
                // Rarity Badge
                Text(trophy.rarity.title.uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(rarityColor.opacity(0.2))
                    .foregroundColor(rarityColor)
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
                Text("Unlocked \(formatDate(trophy.unlockedAt))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                // XP Reward
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    
                    Text("\(trophy.rarity.xpReward) XP")
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
                .shadow(color: rarityColor.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [rarityColor.opacity(0.3), rarityColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .scaleEffect(trophy.isRecent ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: trophy.isRecent)
        .onAppear {
            glowAnimation = true
        }
    }
    
    private var rarityColor: Color {
        switch trophy.rarity.color {
        case "gray": return .gray
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        default: return .gray
        }
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Trophy Icon
            ZStack {
                Circle()
                    .fill(rarityColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: trophy.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(rarityColor)
                
                // New Badge
                if trophy.isRecent {
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
                
                Text(trophy.rarity.title)
                    .font(.caption)
                    .foregroundColor(rarityColor)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // XP Reward
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Text("\(trophy.rarity.xpReward)")
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
                .stroke(rarityColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var rarityColor: Color {
        switch trophy.rarity.color {
        case "gray": return .gray
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        default: return .gray
        }
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
    let allTrophyTypes: [TrophyType] = TrophyType.allCases
    
    var unlockedCount: Int { unlockedTrophies.count }
    var totalCount: Int { allTrophyTypes.count }
    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
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
                TrophyGridView(trophies: unlockedTrophies.sorted { $0.unlockedAt > $1.unlockedAt })
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
                                color: rarityColor
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
                        
                        Text("+\(trophy.rarity.xpReward) XP")
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
                .background(rarityColor)
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
    
    private var rarityColor: Color {
        switch trophy.rarity.color {
        case "gray": return .gray
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        default: return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            TrophyCollectionView(
                unlockedTrophies: [
                    Trophy(type: .firstWin, unlockedAt: Date()),
                    Trophy(type: .rookie, unlockedAt: Date().addingTimeInterval(-86400)),
                    Trophy(type: .perfectionist, unlockedAt: Date().addingTimeInterval(-172800))
                ]
            )
            
            CompactTrophyCard(trophy: Trophy(type: .legend, unlockedAt: Date()))
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}