import SwiftUI

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let badge: String?
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        DSInteractiveCard(action: action) {
            VStack(spacing: 12) {
                // Icon with enhanced styling
                ZStack {
                    // Background circle with gradient
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                    
                    // Badge with improved styling
                    if let badge = badge, !badge.isEmpty {
                        Text(badge)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(
                                LinearGradient(
                                    colors: [.red, .red.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .red.opacity(0.3), radius: 2, x: 0, y: 1)
                            .offset(x: 25, y: -25)
                    }
                }
                
                // Text content with improved hierarchy
                VStack(spacing: 4) {
                    Text(title)
                        .font(DS.Font.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(DS.Color.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
        }
    }
}

/// Enhanced version with more options
struct EnhancedQuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let badge: String?
    let isEnabled: Bool
    let showChevron: Bool
    let action: () -> Void
    
    init(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        badge: String? = nil,
        isEnabled: Bool = true,
        showChevron: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.badge = badge
        self.isEnabled = isEnabled
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        DSModernCard(style: .prominent) {
            HStack(spacing: 16) {
                // Icon section
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(isEnabled ? 0.2 : 0.1), color.opacity(isEnabled ? 0.1 : 0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isEnabled ? color : color.opacity(0.5))
                    
                    if let badge = badge, !badge.isEmpty {
                        Text(badge)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .offset(x: 20, y: -20)
                    }
                }
                
                // Content section
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(DS.Font.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isEnabled ? DS.Color.primary : DS.Color.secondary)
                    
                    Text(subtitle)
                        .font(DS.Font.caption)
                        .foregroundColor(DS.Color.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Chevron if enabled
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DS.Color.secondary)
                }
            }
        }
        .opacity(isEnabled ? 1.0 : 0.6)
        .onTapGesture {
            if isEnabled {
                // Haptic feedback
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                action()
            }
        }
    }
}

/// Modern nearby player card
struct NearbyPlayerModernCard: View {
    let player: User
    @State private var distance: Double?
    
    var body: some View {
        DSModernCard(style: .minimal) {
            VStack(spacing: 8) {
                // Profile image with online indicator
                ZStack {
                    if let imageURL = player.profileImageURL, !imageURL.isEmpty {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(DS.Color.accent.opacity(0.2))
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: DS.Color.accent))
                                        .scaleEffect(0.7)
                                )
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DS.Color.accent.opacity(0.3), DS.Color.accent.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(DS.Color.accent)
                            )
                    }
                    
                    // Online indicator
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .offset(x: 20, y: -20)
                }
                
                // Player info
                VStack(spacing: 4) {
                    Text(player.displayName.isEmpty ? "Player" : player.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DS.Color.primary)
                        .lineLimit(1)
                    
                    // ELO rating
                    Text("ELO \(player.elo)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(DS.Color.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(DS.Color.accent.opacity(0.1))
                        .clipShape(Capsule())
                    
                    // Distance if available
                    if let distance = distance {
                        Text(String(format: "%.1f km", distance))
                            .font(.system(size: 10))
                            .foregroundColor(DS.Color.secondary)
                    }
                }
            }
            .frame(width: 80)
        }
        .onAppear {
            calculateDistance()
        }
    }
    
    private func calculateDistance() {
        // Simplified distance calculation - would use actual location services in real app
        distance = Double.random(in: 0.1...5.0)
    }
}

#Preview {
    VStack(spacing: 16) {
        // Original style
        HStack {
            QuickActionCard(
                title: "Find Match",
                subtitle: "Join queue",
                icon: "person.2.fill",
                color: .blue,
                badge: "15"
            ) {
                print("Find match tapped")
            }
            
            QuickActionCard(
                title: "Nearby Players",
                subtitle: "Find players nearby",
                icon: "location.fill",
                color: .green,
                badge: "5"
            ) {
                print("Nearby tapped")
            }
        }
        
        // Enhanced style
        VStack(spacing: 12) {
            EnhancedQuickActionCard(
                title: "Tournament Mode",
                subtitle: "Join competitive tournaments",
                icon: "trophy.fill",
                color: .orange,
                badge: "NEW",
                showChevron: true
            ) {
                print("Tournament tapped")
            }
            
            EnhancedQuickActionCard(
                title: "Practice Mode",
                subtitle: "Improve your skills",
                icon: "target",
                color: .purple,
                isEnabled: false
            ) {
                print("Practice tapped")
            }
        }
    }
    .padding()
} 