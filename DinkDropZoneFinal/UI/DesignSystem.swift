import SwiftUI

/// A lightweight design-system holding colour, typography and layout constants used across the app.
/// Extend as the product grows – keep it focused on SINGLE-SOURCE-OF-TRUTH values.
enum DS {
    // MARK: Colours
    enum Color {
        /// Base background (adapts to light / dark automatically)
        static let background = SwiftUI.Color(UIColor.systemBackground)
        /// Secondary background used for cards and grouped cells
        static let surface = SwiftUI.Color(UIColor.secondarySystemBackground)
        /// Tertiary background for cells within cards
        static let surfaceAlt = SwiftUI.Color(UIColor.tertiarySystemBackground)
        /// Primary accent (brand colour)
        static let accent = SwiftUI.Color.purple
        /// Secondary accent color
        static let accentAlt = SwiftUI.Color.orange
        /// Subtle border / divider colour
        static let divider = SwiftUI.Color(UIColor.separator)
        /// Primary text color
        static let primary = SwiftUI.Color.primary
        /// Secondary text color
        static let secondary = SwiftUI.Color.secondary
        
        // Semantic colors
        static let success = SwiftUI.Color.green
        static let warning = SwiftUI.Color.orange
        static let error = SwiftUI.Color.red
        static let info = SwiftUI.Color.blue
        
        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [accent, accentAlt],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let headerGradient = LinearGradient(
            colors: [.blue.opacity(0.6), .purple.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: Typography
    enum Font {
        static let display = SwiftUI.Font.system(size: 32, weight: .bold, design: .rounded)
        static let title = SwiftUI.Font.system(size: 24, weight: .semibold, design: .rounded)
        static let title2 = SwiftUI.Font.system(size: 20, weight: .semibold, design: .rounded)
        static let title3 = SwiftUI.Font.system(size: 18, weight: .semibold, design: .rounded)
        static let headline = SwiftUI.Font.system(size: 17, weight: .semibold, design: .rounded)
        static let subheadline = SwiftUI.Font.system(size: 15, weight: .regular, design: .rounded)
        static let body = SwiftUI.Font.system(size: 16, weight: .regular, design: .rounded)
        static let caption = SwiftUI.Font.system(size: 13, weight: .regular, design: .rounded)
        static let caption2 = SwiftUI.Font.system(size: 11, weight: .regular, design: .rounded)
    }

    // MARK: Layout
    enum Layout {
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 12
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 16
        static let animationDuration: Double = 0.25
        
        // Standard edge insets
        static let edgeInsets = EdgeInsets(
            top: verticalPadding, 
            leading: horizontalPadding, 
            bottom: verticalPadding, 
            trailing: horizontalPadding
        )
    }
    
    // MARK: Shadows
    enum Shadow {
        static let small = shadow(color: SwiftUI.Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = shadow(color: SwiftUI.Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        static let large = shadow(color: SwiftUI.Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        
        // Helper function to create shadow view modifier
        static func shadow(color: SwiftUI.Color, radius: CGFloat, x: CGFloat, y: CGFloat) -> ShadowModifier {
            return ShadowModifier(color: color, radius: radius, x: x, y: y)
        }
    }
}

// Shadow modifier to apply consistent shadows
struct ShadowModifier: ViewModifier {
    let color: SwiftUI.Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    func body(content: Content) -> some View {
        content.shadow(color: color, radius: radius, x: x, y: y)
    }
}

// MARK: - View helpers

extension View {
    /// Applies the standard card appearance: surface background, rounded corners and subtle border.
    func dsCard() -> some View {
        self
            .padding(DS.Layout.cardPadding)
            .background(DS.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                    .stroke(DS.Color.divider.opacity(0.1))
            )
    }
    
    /// Applies a more prominent card style with optional shadow
    func dsProminentCard(withShadow: Bool = true) -> some View {
        self
            .padding(DS.Layout.cardPadding)
            .background(DS.Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                    .stroke(DS.Color.divider.opacity(0.1))
            )
            .shadow(color: withShadow ? SwiftUI.Color.black.opacity(0.1) : SwiftUI.Color.clear, radius: 8, x: 0, y: 4)
    }
    
    /// Applies the standard section spacing
    func dsSectionSpacing() -> some View {
        self.padding(.bottom, DS.Layout.sectionSpacing)
    }

    /// Standard animation wrapper so we can tweak globally later.
    func dsAnimated(_ value: some Equatable) -> some View {
        self.animation(.easeOut(duration: DS.Layout.animationDuration), value: value)
    }
    
    /// Applies standard item spacing
    func dsItemSpacing() -> some View {
        self.padding(.bottom, DS.Layout.itemSpacing)
    }
    
    /// Standard horizontal padding for content
    func dsHorizontalPadding() -> some View {
        self.padding(.horizontal, DS.Layout.horizontalPadding)
    }
    
    /// Apply small shadow
    func dsSmallShadow() -> some View {
        self.shadow(color: SwiftUI.Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    /// Apply medium shadow
    func dsMediumShadow() -> some View {
        self.shadow(color: SwiftUI.Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
    
    /// Apply large shadow
    func dsLargeShadow() -> some View {
        self.shadow(color: SwiftUI.Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Reusable Components

/// Standard section header with title and optional action button
struct DSSectionHeader: View {
    let title: String
    let action: (() -> Void)?
    let actionTitle: String
    
    init(title: String, actionTitle: String = "View All", action: (() -> Void)? = nil) {
        self.title = title
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(DS.Font.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            if let action = action {
                Button(actionTitle) {
                    action()
                }
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.accent)
            }
        }
        .padding(.bottom, 8)
    }
}

/// Progress bar with consistent styling
struct DSProgressBar: View {
    let value: Double
    let total: Double?
    let color: SwiftUI.Color
    
    init(value: Double, color: SwiftUI.Color) {
        self.value = value
        self.total = 1.0
        self.color = color
    }
    
    init(value: Double, total: Double, color: SwiftUI.Color) {
        self.value = value
        self.total = total
        self.color = color
    }
    
    var body: some View {
        ProgressView(value: value, total: total ?? 1.0)
            .progressViewStyle(LinearProgressViewStyle(tint: color))
            .scaleEffect(x: 1, y: 1.5, anchor: .center)
    }
}

/// A standard loading indicator with optional label
struct DSLoadingIndicator: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
            
            if let message = message {
                Text(message)
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

/// A standard empty state view
struct DSEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(DS.Color.secondary.opacity(0.6))
            
            Text(title)
                .font(DS.Font.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DS.Color.secondary)
            
            Text(message)
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

/// Achievement badge component
struct AchievementBadge: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [SwiftUI.Color.yellow, SwiftUI.Color.orange]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 40, height: 40)
                .shadow(color: SwiftUI.Color.yellow.opacity(0.3), radius: 4, x: 0, y: 2)
                .overlay(
                    Image(systemName: achievement.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(SwiftUI.Color.white)
                )
            
            Text(achievement.title)
                .font(DS.Font.caption2)
                .fontWeight(.medium)
                .foregroundColor(SwiftUI.Color.primary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 60)
    }
}

/// Profile recent match card
struct ProfileRecentMatchCard: View {
    let match: Match
    let currentUser: User
    
    var body: some View {
        HStack(spacing: 12) {
            // Result indicator
            Circle()
                .fill(match.result(for: currentUser) == "Win" ? SwiftUI.Color.green : SwiftUI.Color.red)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(match.opponent(for: currentUser))
                    .font(DS.Font.subheadline)
                    .fontWeight(.medium)
                Text(match.date, style: .date)
                    .font(DS.Font.caption2)
                    .foregroundColor(DS.Color.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(match.score)
                    .font(DS.Font.subheadline)
                    .fontWeight(.medium)
                Text(match.eloChange)
                    .font(DS.Font.caption2)
                    .foregroundColor(match.eloChange.hasPrefix("+") ? SwiftUI.Color.green : SwiftUI.Color.red)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(DS.Color.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
    }
}

/// Monthly performance card
struct MonthlyPerformanceCard: View {
    let data: MonthlyPerformanceData
    
    var body: some View {
        VStack(spacing: 6) {
            Text(data.month)
                .font(DS.Font.caption)
                .fontWeight(.semibold)
                .foregroundColor(DS.Color.secondary)
            
            Text("\(data.matches)")
                .font(DS.Font.title3)
                .fontWeight(.bold)
            
            Text("matches")
                .font(DS.Font.caption2)
                .foregroundColor(DS.Color.secondary)
            
            Divider()
                .padding(.vertical, 2)
            
            Text(String(format: "%.0f%%", data.winRate * 100))
                .font(DS.Font.caption)
                .fontWeight(.semibold)
                .foregroundColor(data.winRate > 0.5 ? SwiftUI.Color.green : SwiftUI.Color.red)
            
            Text("\(data.eloChange > 0 ? "+" : "")\(data.eloChange) ELO")
                .font(DS.Font.caption2)
                .foregroundColor(data.eloChange > 0 ? SwiftUI.Color.green : SwiftUI.Color.red)
        }
        .padding(8)
        .frame(width: 80)
        .background(DS.Color.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
    }
}

/// Detailed stat card
struct DetailedStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: SwiftUI.Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(DS.Font.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(DS.Font.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(DS.Font.caption)
                .foregroundColor(DS.Color.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
    }
}

/// Daily challenge card
struct ProfileDailyChallengeCard: View {
    let title: String
    let description: String
    let progress: Double
    let reward: String
    let isCompleted: Bool
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? SwiftUI.Color.green : SwiftUI.Color.orange.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(DS.Font.title3)
                        .fontWeight(.bold)
                        .foregroundColor(SwiftUI.Color.white)
                } else {
                    Image(systemName: icon)
                        .font(DS.Font.title3)
                        .foregroundColor(SwiftUI.Color.orange)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(DS.Font.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(reward)
                        .font(DS.Font.caption2)
                        .foregroundColor(SwiftUI.Color.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(SwiftUI.Color.orange.opacity(0.2)))
                }
                
                Text(description)
                    .font(DS.Font.caption)
                    .foregroundColor(DS.Color.secondary)
                
                if !isCompleted {
                    DSProgressBar(value: progress, color: SwiftUI.Color.orange)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                .fill(isCompleted ? SwiftUI.Color.green.opacity(0.1) : DS.Color.surfaceAlt)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                        .stroke(isCompleted ? SwiftUI.Color.green.opacity(0.3) : SwiftUI.Color.clear, lineWidth: 1)
                )
        )
    }
}

extension View {
    /// Add this to any ScrollView to get standard scrollable content
    func dsStandardScrollableContent<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        ScrollView {
            VStack(spacing: DS.Layout.sectionSpacing) {
                content()
            }
            .padding(.vertical, DS.Layout.verticalPadding)
        }
    }
}

// MARK: - Modern UI Components

/// Enhanced button styles for different use cases
struct DSPrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, isLoading: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(DS.Font.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(DS.Color.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
            .shadow(color: DS.Color.accent.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .disabled(isLoading)
        .scaleEffect(isLoading ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isLoading)
    }
}

/// Secondary button style
struct DSSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(DS.Font.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(DS.Color.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(DS.Color.accent.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Layout.cornerRadius)
                    .stroke(DS.Color.accent.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

/// Floating action button
struct DSFloatingActionButton: View {
    let icon: String
    let color: SwiftUI.Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: false)
    }
}

/// Enhanced card with modern styling
struct DSModernCard<Content: View>: View {
    let content: Content
    let style: CardStyle
    
    enum CardStyle {
        case standard
        case prominent
        case minimal
        case gradient
    }
    
    init(style: CardStyle = .standard, @ViewBuilder content: () -> Content) {
        self.style = style
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DS.Layout.cardPadding)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
            .overlay(overlayView)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowOffset)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .standard:
            DS.Color.surface
        case .prominent:
            DS.Color.surface
        case .minimal:
            DS.Color.surfaceAlt
        case .gradient:
            DS.Color.primaryGradient.opacity(0.1)
        }
    }
    
    @ViewBuilder
    private var overlayView: some View {
        switch style {
        case .standard, .minimal:
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                .stroke(DS.Color.divider.opacity(0.1), lineWidth: 1)
        case .prominent:
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                .stroke(DS.Color.accent.opacity(0.2), lineWidth: 1)
        case .gradient:
            RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                .stroke(DS.Color.accent.opacity(0.3), lineWidth: 1)
        }
    }
    
    private var shadowColor: SwiftUI.Color {
        switch style {
        case .standard, .minimal: return SwiftUI.Color.black.opacity(0.05)
        case .prominent: return SwiftUI.Color.black.opacity(0.1)
        case .gradient: return DS.Color.accent.opacity(0.2)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .minimal: return 2
        case .standard: return 4
        case .prominent, .gradient: return 8
        }
    }
    
    private var shadowOffset: CGFloat {
        switch style {
        case .minimal: return 1
        case .standard: return 2
        case .prominent, .gradient: return 4
        }
    }
}

/// Interactive card with press animations
struct DSInteractiveCard<Content: View>: View {
    let content: Content
    let action: () -> Void
    @State private var isPressed = false
    
    init(action: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: action) {
            content
                .padding(DS.Layout.cardPadding)
                .background(DS.Color.surface)
                .clipShape(RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Layout.cornerRadius, style: .continuous)
                        .stroke(DS.Color.divider.opacity(0.1), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .shadow(color: SwiftUI.Color.black.opacity(isPressed ? 0.05 : 0.1), radius: isPressed ? 2 : 4, x: 0, y: isPressed ? 1 : 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

/// Modern section container with enhanced styling
struct DSModernSectionContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionTitle: String
    let content: Content
    
    init(
        title: String,
        subtitle: String? = nil,
        actionTitle: String = "View All",
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionTitle = actionTitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Enhanced header
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(DS.Font.title3)
                            .fontWeight(.bold)
                            .foregroundColor(DS.Color.primary)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(DS.Font.caption)
                                .foregroundColor(DS.Color.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let action = action {
                        Button(action: action) {
                            HStack(spacing: 4) {
                                Text(actionTitle)
                                    .font(DS.Font.caption)
                                    .fontWeight(.medium)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(DS.Color.accent)
                        }
                    }
                }
                
                // Decorative line
                Rectangle()
                    .fill(DS.Color.accent.opacity(0.3))
                    .frame(width: 30, height: 2)
                    .clipShape(Capsule())
            }
            
            content
        }
        .padding(.bottom, DS.Layout.sectionSpacing)
    }
}

/// Animated counter component
struct DSAnimatedCounter: View {
    let value: Int
    let duration: Double
    @State private var animatedValue: Int = 0
    
    init(value: Int, duration: Double = 1.0) {
        self.value = value
        self.duration = duration
    }
    
    var body: some View {
        Text("\(animatedValue)")
            .font(DS.Font.title)
            .fontWeight(.bold)
            .contentTransition(.numericText())
            .onAppear {
                animateCounter()
            }
            .onChange(of: value) { _, _ in
                animateCounter()
            }
    }
    
    private func animateCounter() {
        let steps = 20
        let stepValue = value / steps
        let stepDuration = duration / Double(steps)
        
        animatedValue = 0
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                withAnimation(.easeOut(duration: 0.1)) {
                    animatedValue = min(stepValue * i, value)
                }
            }
        }
    }
}

/// Progress ring component
struct DSProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let color: SwiftUI.Color
    
    init(progress: Double, lineWidth: CGFloat = 8, size: CGFloat = 60, color: SwiftUI.Color = DS.Color.accent) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.color = color
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1.0), value: progress)
        }
        .frame(width: size, height: size)
    }
} 